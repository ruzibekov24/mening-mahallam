import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/feedback_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// "Ilovani baholash" o'rniga: foydalanuvchi 1-5 yulduz baho va
/// ixtiyoriy matn qoldiradi, bu fikr super adminga boradi.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_rating == 0) {
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
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(PhosphorIconsRegular.arrowLeft),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppAccents.events.withValues(alpha: 0.12),
                  borderRadius: AppRadius.lgAll,
                ),
                child: const Icon(PhosphorIconsFill.star,
                    color: AppAccents.events, size: 30),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.feedbackTitle, style: context.displayStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.feedbackSubtitle,
                  style: context.secondaryStyle.copyWith(height: 1.4)),
              const SizedBox(height: AppSpacing.xxl),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    final filled = starIndex <= _rating;
                    return IconButton(
                      onPressed: () => setState(() => _rating = starIndex),
                      icon: Icon(
                        filled ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        color: filled ? AppAccents.events : context.textMuted,
                        size: 34,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text(l10n.feedbackMessageLabel, style: context.captionStyle),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: l10n.feedbackMessageHint,
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
