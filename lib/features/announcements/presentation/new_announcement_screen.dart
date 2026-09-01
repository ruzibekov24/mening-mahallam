import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/rich_text_editor_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../qr/data/mahalla_repository.dart';
import '../data/announcement_repository.dart';
import '../data/announcements_providers.dart';
import 'announcement_styles.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

String _categoryLabel(AppLocalizations l10n, AnnouncementCategory category) {
  switch (category) {
    case AnnouncementCategory.kommunal:
      return l10n.categoryKommunal;
    case AnnouncementCategory.xavfsizlik:
      return l10n.categoryXavfsizlik;
    case AnnouncementCategory.umumiy:
      return l10n.categoryUmumiy;
  }
}

/// Yangi e'lon yaratish (yoki mavjudini tahrirlash) ekrani — faqat
/// tasdiqlangan (verifiedBadge) foydalanuvchilar uchun ochiladi.
class NewAnnouncementScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  final Announcement? existing;
  const NewAnnouncementScreen({
    super.key,
    required this.mahallaId,
    this.existing,
  });

  @override
  ConsumerState<NewAnnouncementScreen> createState() =>
      _NewAnnouncementScreenState();
}

class _NewAnnouncementScreenState
    extends ConsumerState<NewAnnouncementScreen> {
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final QuillController _bodyController = _initialBodyController();
  late AnnouncementCategory _category =
      widget.existing?.category ?? AnnouncementCategory.kommunal;
  File? _image;
  late String? _existingImageUrl = widget.existing?.imageUrl;
  bool _isSubmitting = false;
  bool _broadcastToAll = false;

  bool get _isEditing => widget.existing != null;

  QuillController _initialBodyController() {
    final existing = widget.existing;
    if (existing == null) return QuillController.basic();
    try {
      final decoded = jsonDecode(existing.body);
      if (decoded is List) {
        return QuillController(
          document: Document.fromJson(decoded),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (_) {}
    return QuillController.basic()
      ..document.insert(0, existing.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;
    setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final isBodyEmpty = _bodyController.document.isEmpty();
    final bodyJson = jsonEncode(_bodyController.document.toDelta().toJson());

    if (title.isEmpty || isBodyEmpty) {
      showAppAlert(context, l10n.fillTitleAndBody, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_image != null) {
        imageUrl = await ImageUploadService().uploadImage(
          file: _image!,
          storagePath:
              'mahallas/${widget.mahallaId}/announcements/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }

      final repo = ref.read(announcementRepositoryProvider);
      if (_isEditing) {
        await repo.updateAnnouncement(
          mahallaId: widget.mahallaId,
          announcementId: widget.existing!.id,
          title: title,
          body: bodyJson,
          category: _category,
          imageUrl: imageUrl,
        );
      } else if (_broadcastToAll) {
        // Super admin: barcha mahallalarga alohida-alohida yozadi —
        // har bir mahalla o'zining mustaqil e'lon hujjatiga ega
        // bo'ladi, shunda mavjud "bitta mahalla" o'qish modeli hech
        // qanday o'zgarishsiz ishlayveradi.
        final mahallas =
            await ref.read(mahallaRepositoryProvider).fetchAllMahallas();
        for (final mahalla in mahallas) {
          await repo.createAnnouncement(
            mahallaId: mahalla.id,
            title: title,
            body: bodyJson,
            category: _category,
            imageUrl: imageUrl,
          );
        }
      } else {
        await repo.createAnnouncement(
          mahallaId: widget.mahallaId,
          title: title,
          body: bodyJson,
          category: _category,
          imageUrl: imageUrl,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlert(context, _isEditing ? l10n.announcementUpdated : l10n.announcementPosted);
    } on ImageUploadException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, e.message, kind: AppAlertKind.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  const LiquidGlassBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                      _isEditing
                          ? l10n.editAnnouncementTitle
                          : l10n.newAnnouncementTitle,
                      style: context.titleStyle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                children: [
                  Text(l10n.categoryLabel, style: context.captionStyle),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: AnnouncementCategory.values.map((cat) {
                      final isActive = cat == _category;
                      final color = cat.color;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color
                                : color.withValues(alpha: 0.1),
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            _categoryLabel(l10n, cat),
                            style: context.captionStyle.copyWith(
                              color: isActive ? Colors.white : color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.titleLabel, style: context.captionStyle),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: l10n.titleHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.bodyLabel, style: context.captionStyle),
                  const SizedBox(height: AppSpacing.sm),
                  RichTextEditorField(
                    controller: _bodyController,
                    hintText: l10n.bodyHint,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Text(l10n.photoLabel, style: context.captionStyle),
                      const SizedBox(width: AppSpacing.xs),
                      Text(l10n.optionalLabel, style: context.captionStyle),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_image != null || _existingImageUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: AppRadius.smAll,
                          child: _image != null
                              ? Image.file(
                                  _image!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: _existingImageUrl!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: AppSpacing.xs,
                          right: AppSpacing.xs,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _image = null;
                              _existingImageUrl = null;
                            }),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsBold.x,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: context.borderColor,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(PhosphorIconsRegular.imageSquare,
                            color: context.textSecondary),
                      ),
                    ),
                  if (!_isEditing)
                    Consumer(
                      builder: (context, ref, _) {
                        final isSuperAdmin = ref
                                .watch(currentUserProfileProvider)
                                .valueOrNull
                                ?.role
                                .isSuperAdmin ==
                            true;
                        if (!isSuperAdmin) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: InkWell(
                            borderRadius: AppRadius.smAll,
                            onTap: () => setState(
                                () => _broadcastToAll = !_broadcastToAll),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.06),
                                borderRadius: AppRadius.smAll,
                                border: Border.all(
                                    color:
                                        AppColors.danger.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _broadcastToAll,
                                    activeColor: AppColors.danger,
                                    onChanged: (v) => setState(
                                        () => _broadcastToAll = v ?? false),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.broadcastToAllMahallasLabel,
                                      style: context.bodyStyle
                                          .copyWith(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? l10n.saveButton : l10n.postButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}