import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/feedback_repository.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// "Ilovani baholash" o'rniga: foydalanuvchi 1-5 yulduz baho va
/// ixtiyoriy matn qoldiradi, bu fikr super adminga boradi.
///
/// Ikkinchi rejimi ham bor — "Savol/Murojaat": bu yerda yulduz baho
/// shart emas, foydalanuvchi shunchaki superadminga savol/murojaat
/// yozadi (masalan AI Yordamchining "rais bilan bog'lanish" taklifi
/// orqali kelganda, [startInQuestionMode] bilan darhol shu rejimda
/// ochiladi).
class FeedbackScreen extends ConsumerStatefulWidget {
  final bool startInQuestionMode;
  const FeedbackScreen({super.key, this.startInQuestionMode = false});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  late bool _isQuestionMode = widget.startInQuestionMode;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_isQuestionMode && _rating == 0) {
      showAppAlert(context, l10n.feedbackRatingRequiredError, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final authorName = profile == null
        ? ''
        : '${profile.firstName} ${profile.lastName}'.trim();

    try {
      await ref.read(feedbackRepositoryProvider).submitFeedback(
            rating: _rating,
            message: _messageController.text.trim(),
            authorName: authorName,
            isPremium: profile?.isPremiumActive == true,
            isQuestion: _isQuestionMode,
          );
      if (!mounted) return;
      showAppAlert(context, l10n.feedbackSubmittedMessage);
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xs),
              const LiquidGlassBackButton(),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppAccents.events.withValues(alpha: 0.12),
                  borderRadius: AppRadius.lgAll,
                ),
                child: Icon(
                    _isQuestionMode
                        ? PhosphorIconsFill.chatCircleText
                        : PhosphorIconsFill.star,
                    color: AppAccents.events,
                    size: 30),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                  _isQuestionMode
                      ? l10n.feedbackQuestionTitle
                      : l10n.feedbackTitle,
                  style: context.displayStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  _isQuestionMode
                      ? l10n.feedbackQuestionSubtitle
                      : l10n.feedbackSubtitle,
                  style: context.secondaryStyle.copyWith(height: 1.4)),
              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightBorder,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _FeedbackModeButton(
                        label: l10n.feedbackModeRatingTab,
                        isActive: !_isQuestionMode,
                        onTap: () => setState(() => _isQuestionMode = false),
                      ),
                    ),
                    Expanded(
                      child: _FeedbackModeButton(
                        label: l10n.feedbackModeQuestionTab,
                        isActive: _isQuestionMode,
                        onTap: () => setState(() => _isQuestionMode = true),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              if (!_isQuestionMode) ...[
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final filled = starIndex <= _rating;
                      return IconButton(
                        onPressed: () => setState(() => _rating = starIndex),
                        icon: Icon(
                          filled
                              ? PhosphorIconsFill.star
                              : PhosphorIconsRegular.star,
                          color:
                              filled ? AppAccents.events : context.textMuted,
                          size: 34,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              Text(l10n.feedbackMessageLabel, style: context.captionStyle),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: _isQuestionMode
                      ? l10n.feedbackQuestionMessageHint
                      : l10n.feedbackMessageHint,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              SizedBox(
                height: 54,
                width: double.infinity,
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
                      : Text(l10n.feedbackSubmitButton),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Baho qoldirish" / "Savol-Murojaat" segmentlashtirilgan almashtirgichi
/// tugmasi — `announcements_screen.dart`dagi `_SegmentButton` vizual
/// naqshiga mos (bu yerda alohida fayl bo'lgani uchun nusxa ko'chirilgan).
class _FeedbackModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FeedbackModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.xsAll,
          boxShadow: isActive
              ? AppShadows.accent(AppColors.primary, context.isDarkMode)
              : null,
        ),
        child: Text(
          label,
          style: context.secondaryStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
