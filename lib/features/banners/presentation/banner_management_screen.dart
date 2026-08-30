import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../data/promo_banner_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// Super admin uchun: bosh ekrandagi aylanuvchi bannerlarni
/// qo'shish/o'chirish.
class BannerManagementScreen extends ConsumerWidget {
  const BannerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bannersAsync = ref.watch(activeBannersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(l10n.bannerManagementTitle,
                        style: context.titleStyle),
                  ),
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg)),
                      ),
                      builder: (_) => _NewBannerSheet(
                          nextOrder: bannersAsync.valueOrNull?.length ?? 0),
                    ),
                    icon: const Icon(PhosphorIconsFill.plusCircle,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: bannersAsync.when(
                data: (banners) {
                  if (banners.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.image,
                      title: l10n.noBannersFound,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final banner = banners[index];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(AppRadius.md)),
                              child: Image.network(
                                banner.imageUrl,
                                width: 84,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 84,
                                  height: 68,
                                  color: context.surfaceColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                banner.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.cardTitleStyle,
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed = await confirmDelete(context,
                                    itemTitle: banner.title);
                                if (!confirmed) return;
                                await ref
                                    .read(promoBannerRepositoryProvider)
                                    .deleteBanner(banner.id);
                              },
                              icon: const Icon(PhosphorIconsRegular.trash,
                                  color: AppColors.danger, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView(
                  padding: AppSpacing.listPadding,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [ShimmerList(count: 4)],
                ),
                error: (error, _) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(activeBannersProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewBannerSheet extends ConsumerStatefulWidget {
  final int nextOrder;
  const _NewBannerSheet({required this.nextOrder});

  @override
  ConsumerState<_NewBannerSheet> createState() => _NewBannerSheetState();
}

class _NewBannerSheetState extends ConsumerState<_NewBannerSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  final _attributionController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _attributionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_imageFile == null) {
      showAppAlert(context, l10n.bannerImageRequiredError, kind: AppAlertKind.error);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      showAppAlert(context, l10n.bannerTitleRequiredError, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final imageUrl = await ImageUploadService().uploadImage(
        file: _imageFile!,
        // Supabase Storage bucket qoidalari faqan 'users/' va
        // 'mahallas/' prefikslariga ruxsat beradi — shuning uchun
        // super admin uid ostiga, xuddi profil rasmi kabi yuklaymiz.
        storagePath:
            'users/$uid/banners/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.read(promoBannerRepositoryProvider).createBanner(
            imageUrl: imageUrl,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            linkUrl: _linkController.text.trim(),
            attribution: _attributionController.text.trim(),
            order: widget.nextOrder,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ImageUploadException catch (e) {
      if (!mounted) return;
      showAppAlert(context, e.message, kind: AppAlertKind.error);
    } catch (e) {
      if (!mounted) return;
      showAppAlert(context, '${l10n.unexpectedError}\n$e', kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.addBannerTitle, style: context.sectionStyle),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                        color: context.borderColor, style: BorderStyle.solid),
                  ),
                  child: _imageFile == null
                      ? Center(
                          child: Icon(PhosphorIconsRegular.imageSquare,
                              size: 36, color: context.textSecondary),
                        )
                      : ClipRRect(
                          borderRadius: AppRadius.mdAll,
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(hintText: l10n.bannerTitleLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration:
                    InputDecoration(hintText: l10n.bannerDescriptionLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(hintText: l10n.bannerLinkLabel),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _attributionController,
                decoration:
                    InputDecoration(hintText: l10n.bannerAttributionLabel),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(l10n.saveButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
