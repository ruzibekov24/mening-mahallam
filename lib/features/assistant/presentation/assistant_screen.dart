import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../language/data/language_repository.dart';
import '../data/assistant_repository.dart';

/// Bitta ko'rsatiladigan xabar — foydalanuvchidan yoki AI'dan.
/// Faqat shu ekran ichida, xotirada yashaydi: Firestore'ga
/// yozilmaydi, ekran yopilganda yo'qoladi (bu saqlanadigan chat emas,
/// bir martalik AI yordamchi suhbati).
class _DisplayMessage {
  final String text;
  final bool isUser;
  const _DisplayMessage({required this.text, required this.isUser});
}

/// [AppLanguage]ni Worker'ning `locale` parametriga ("uz" | "ru" | "en")
/// aylantiradi. Lotin va Кирилл o'zbekchasi ikkalasi ham "uz" —
/// Gemini'ga skript emas, til muhim.
String _localeCodeFor(AppLanguage language) {
  switch (language) {
    case AppLanguage.uzbekLatin:
    case AppLanguage.uzbekCyrillic:
      return 'uz';
    case AppLanguage.russian:
      return 'ru';
    case AppLanguage.english:
      return 'en';
  }
}

/// AI Yordamchi ekrani — oddiy, bir martalik suhbat: xabarlar ro'yxati
/// (foydalanuvchi o'ngda, AI chapda) + matn kiritish maydoni.
///
/// `lib/features/chat/presentation/chat_screen.dart`dagi `_MessageBubble`
/// vizual naqshidan foydalanilgan, lekin bu yerda Firestore oqimi yo'q —
/// hammasi shu widget'ning `State`ida, oddiy `List` sifatida.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_DisplayMessage> _messages = [];
  bool _isSending = false;
  String? _errorText;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    final language = ref.read(languageProvider);
    // Server-tomonidagi "so'nggi ~10 burilish" cheklovi bilan mos —
    // mijoz tomonida cheklash shart emas, lekin juda uzun bo'lib
    // ketmasligi uchun oxirgi 20 tasini yuboramiz (10 juftlik).
    final history = _messages
        .skip(_messages.length > 20 ? _messages.length - 20 : 0)
        .map((m) => AssistantTurn(role: m.isUser ? 'user' : 'model', text: m.text))
        .toList();

    setState(() {
      _messages.add(_DisplayMessage(text: text, isUser: true));
      _isSending = true;
      _errorText = null;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final reply = await ref.read(assistantRepositoryProvider).sendMessage(
            message: text,
            history: history,
            locale: _localeCodeFor(language),
          );
      if (!mounted) return;
      setState(() {
        _messages.add(_DisplayMessage(text: reply, isUser: false));
        _isSending = false;
      });
      _scrollToBottom();
    } on AssistantException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorText = "Kutilmagan xatolik yuz berdi. Qayta urinib ko'ring";
      });
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsFill.sparkle,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(l10n.assistantScreenTitle, style: context.titleStyle),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _messages.isEmpty
                  ? _EmptyState(onSuggestionTap: (text) {
                      _textController.text = text;
                      _send();
                    })
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                      itemCount: _messages.length + (_isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _messages.length) {
                          return const _TypingBubble();
                        }
                        return _MessageBubble(message: _messages[index]);
                      },
                    ),
            ),
            if (_errorText != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.warningCircle,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: context.captionStyle
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.darkSurface
                              : AppColors.lightBorder,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: l10n.assistantInputHint,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: context.bodyStyle,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isSending ? null : _send,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(PhosphorIconsFill.paperPlaneRight,
                                  size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ekran birinchi ochilganda — hali xabar yo'qligida ko'rsatiladigan
/// salomlashuv + tez savol takliflari.
class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;
  const _EmptyState({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggestions = [
      l10n.assistantSuggestion1,
      l10n.assistantSuggestion2,
      l10n.assistantSuggestion3,
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.sparkle,
                  color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.assistantGreetingTitle,
              style: context.cardTitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.assistantGreetingSubtitle,
              style: context.secondaryStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TapScale(
                  onTap: () => onSuggestionTap(s),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: AppRadius.mdAll,
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(s, style: context.bodyStyle),
                        ),
                        Icon(PhosphorIconsRegular.arrowRight,
                            size: 16, color: context.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// AI javob yozayotganini bildiruvchi "yozmoqda..." pufakchasi.
class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? AppColors.darkSurface
              : AppColors.lightBorder,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.textMuted,
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _DisplayMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isUser;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primary
              : (context.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: context.bodyStyle.copyWith(
            color: isMine ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }
}
