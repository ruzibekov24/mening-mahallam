import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/utils/post_cooldown.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../core/widgets/media_picker_grid.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/feed_providers.dart';

/// Yozilayotgan post matnini eslab qolish uchun — ekrandan tasodifan
/// chiqib ketilsa (masalan qo'ng'iroq kelsa) matn yo'qolmasligi uchun.
/// Faqat matn saqlanadi, rasm emas — tanlangan rasmlarning vaqtinchalik
/// fayl yo'llari ilova qayta ishga tushirilganda haqiqiy bo'lmasligi
/// mumkin.
const _kDraftKey = 'feed_new_post_draft';

/// Yangi post yozish ekrani — e'lon/tadbirdan farqli, mahallaning
/// istalgan a'zosi (fuqaro ham) chaqira oladi.
class NewPostScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const NewPostScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _textController = TextEditingController();
  List<MediaFile> _media = [];
  bool _isSubmitting = false;
  bool _posted = false;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString(_kDraftKey);
    if (draft != null && draft.isNotEmpty && mounted) {
      setState(() => _textController.text = draft);
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final text = _textController.text.trim();
    if (text.isEmpty) {
      await prefs.remove(_kDraftKey);
    } else {
      await prefs.setString(_kDraftKey, text);
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
  }

  @override
  void dispose() {
    if (!_posted) {
      // Qoralamani saqlash — natijani kutmasdan ("fire and forget"),
      // ekran allaqachon yopilayotgani uchun UI'ni bloklash shart emas.
      _saveDraft();
    }
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final text = _textController.text.trim();
    if (text.isEmpty && _media.isEmpty) {
      showAppAlert(context, l10n.writePostOrImageError,
          kind: AppAlertKind.error);
      return;
    }
    if (containsBannedWords(text)) {
      showAppAlert(context, l10n.inappropriateContentError,
          kind: AppAlertKind.error);
      return;
    }
    final cooldown = await remainingPostCooldown();
    if (!mounted) return;
    if (cooldown != null) {
      showAppAlert(context, l10n.postingTooFastError, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final authorName =
          '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim();

      List<String> imageUrls = const [];
      if (_media.isNotEmpty) {
        imageUrls = await ImageUploadService().uploadMediaFiles(
          files: _media,
          storagePathPrefix: 'posts/${widget.mahallaId}',
        );
      }

      await ref.read(feedRepositoryProvider).createPost(
            mahallaId: widget.mahallaId,
            authorName: authorName.isEmpty ? 'Qo\'shni' : authorName,
            authorPhotoUrl: profile?.photoUrl,
            text: text,
            imageUrls: imageUrls,
          );
      await markPostedNow();
      _posted = true;
      await _clearDraft();

      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlert(context, l10n.postCreatedMessage);
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
                  Text(l10n.feedTitle, style: context.titleStyle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                children: [
                  TextField(
                    controller: _textController,
                    minLines: 4,
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(hintText: l10n.writePostHint),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MediaPickerGrid(
                    mediaFiles: _media,
                    onChanged: (updated) => setState(() => _media = updated),
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
                          : Text(l10n.postButton),
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
