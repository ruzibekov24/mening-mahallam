import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../language/data/language_repository.dart';
import '../../requests/data/requests_repository.dart';
import '../../requests/presentation/new_request_flow_screen.dart';
import '../data/assistant_chat_repository.dart';
import '../data/assistant_repository.dart';

/// Bitta ko'rsatiladigan xabar — foydalanuvchidan yoki AI'dan. Ekranda
/// xotirada tutiladi (tezkor render uchun); Firestore'ga yozish/o'qish
/// [AssistantChatRepository] orqali, shu ro'yxatga parallel ravishda
/// amalga oshiriladi — 'AI Yordamchi' endi bir martalik emas, har bir
/// suhbat `AssistantChatsListScreen`da saqlanadi.
class _DisplayMessage {
  final int id;
  final String text;
  final bool isUser;
  final _DraftRequestAction? action;
  const _DisplayMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.action,
  });
}

/// AI javobidagi ```mahallam-action``` blokidan chiqarilgan, "Yangi
/// murojaat" formasini oldindan to'ldirish uchun kerakli maydonlar —
/// faqat premium foydalanuvchilar uchun serverda yoqilgan imkoniyat
/// (`assistant-worker/lib/workersAi.js`dagi `ACTION_BLOCK_HINT_*`ga
/// qarang). Foydalanuvchi baribir formani ko'rib chiqib, o'zi yuborishi
/// kerak — AI hech qachon murojaatni to'g'ridan-to'g'ri yaratmaydi.
class _DraftRequestAction {
  final String title;
  final String description;
  final RequestType type;
  final RequestPriority priority;
  const _DraftRequestAction({
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
  });
}

final _actionBlockPattern =
    RegExp(r'```mahallam-action\s*\n([\s\S]*?)```', multiLine: true);

/// AI javobidan (agar mavjud bo'lsa) `mahallam-action` blokini ajratib
/// oladi va qolgan matnni (blok o'chirilgan holda) qaytaradi. Format
/// noto'g'ri yoki kutilmagan bo'lsa, xatoni yutib yuboradi va shunchaki
/// blokni matndan olib tashlab, harakatsiz qaytaradi — buzuq JSON AI
/// javobining ko'rinishini butunlay yo'q qilib qo'ymasligi kerak.
({String displayText, _DraftRequestAction? action}) _extractDraftAction(
    String rawText) {
  final match = _actionBlockPattern.firstMatch(rawText);
  if (match == null) return (displayText: rawText.trim(), action: null);

  final withoutBlock =
      (rawText.substring(0, match.start) + rawText.substring(match.end))
          .trim();

  try {
    final data = jsonDecode(match.group(1)!.trim());
    if (data is! Map<String, dynamic> || data['action'] != 'create_request') {
      return (displayText: withoutBlock, action: null);
    }
    final title = (data['title'] as String?)?.trim();
    final description = (data['description'] as String?)?.trim();
    if (title == null || title.isEmpty || description == null || description.isEmpty) {
      return (displayText: withoutBlock, action: null);
    }
    final type =
        data['type'] == 'ommaviy' ? RequestType.ommaviy : RequestType.maxfiy;
    final priority = switch (data['priority']) {
      'past' => RequestPriority.past,
      'yuqori' => RequestPriority.yuqori,
      _ => RequestPriority.ortacha,
    };
    return (
      displayText: withoutBlock,
      action: _DraftRequestAction(
        title: title,
        description: description,
        type: type,
        priority: priority,
      ),
    );
  } catch (_) {
    return (displayText: withoutBlock, action: null);
  }
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
  /// `null` bo'lsa — yangi suhbat: birinchi xabar yuborilganda
  /// Firestore'da avtomatik yaratiladi. Mavjud suhbatni ochish uchun
  /// `AssistantChatsListScreen`dan chatId beriladi.
  final String? chatId;
  final String? initialTitle;

  const AssistantScreen({super.key, this.chatId, this.initialTitle});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_DisplayMessage> _messages = [];
  bool _isSending = false;
  bool _isLoadingHistory = false;
  String? _errorText;
  int _nextMessageId = 0;
  String? _chatId;

  // Faqat hozirgina kelgan AI javobini "yozayotgandek" animatsiya
  // qiladi — Firestore'dan yuklangan eski xabarlar darhol to'liq
  // ko'rinishi kerak.
  int? _freshReplyId;

  @override
  void initState() {
    super.initState();
    _chatId = widget.chatId;
    if (_chatId != null) _loadHistory(_chatId!);
  }

  Future<void> _loadHistory(String chatId) async {
    setState(() => _isLoadingHistory = true);
    try {
      final messages = await ref
          .read(assistantChatRepositoryProvider)
          .watchMessages(chatId)
          .first;
      if (!mounted) return;
      setState(() {
        _messages.addAll(messages.map((m) {
          if (m.isUser) {
            return _DisplayMessage(
                id: _nextMessageId++, text: m.text, isUser: true);
          }
          final parsed = _extractDraftAction(m.text);
          return _DisplayMessage(
            id: _nextMessageId++,
            text: parsed.displayText,
            isUser: false,
            action: parsed.action,
          );
        }));
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingHistory = false);
    }
  }

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
        .map((m) =>
            AssistantTurn(role: m.isUser ? 'user' : 'model', text: m.text))
        .toList();

    setState(() {
      _messages.add(
        _DisplayMessage(id: _nextMessageId++, text: text, isUser: true),
      );
      _isSending = true;
      _errorText = null;
    });
    _textController.clear();
    _scrollToBottom();

    final chatRepo = ref.read(assistantChatRepositoryProvider);
    // Suhbatni Firestore'da doim saqlaymiz (birinchi xabar bilan
    // avtomatik yaratiladi) — chat tarixi/xotira funksiyasi shu orqali
    // ishlaydi. Bu yozuv Gemini'dan javob kutish bilan bir vaqtda emas,
    // undan OLDIN qilinadi: agar tarmoq keyin uzilib qolsa ham,
    // foydalanuvchining savoli tarixda saqlanib qoladi.
    try {
      _chatId ??= await chatRepo.createChat(firstUserMessage: text);
      await chatRepo.addMessage(chatId: _chatId!, role: 'user', text: text);
    } catch (_) {
      // Tarix saqlanmasa ham suhbatning o'zi davom etaversin —
      // xotira ixtiyoriy qulaylik, AI javobini to'sib qo'ymasligi kerak.
    }

    try {
      final reply = await ref.read(assistantRepositoryProvider).sendMessage(
            message: text,
            history: history,
            locale: _localeCodeFor(language),
          );
      if (!mounted) return;
      final replyId = _nextMessageId++;
      final parsed = _extractDraftAction(reply);
      setState(() {
        _messages.add(_DisplayMessage(
          id: replyId,
          text: parsed.displayText,
          isUser: false,
          action: parsed.action,
        ));
        _isSending = false;
        _freshReplyId = replyId;
      });
      _scrollToBottom();
      if (_chatId != null) {
        unawaited(
          chatRepo.addMessage(chatId: _chatId!, role: 'model', text: reply),
        );
      }
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
                  Expanded(
                    child: Text(
                      widget.initialTitle ?? l10n.assistantScreenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.titleStyle,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _EmptyState(onSuggestionTap: (text) {
                          _textController.text = text;
                          _send();
                        })
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md),
                          itemCount: _messages.length + (_isSending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _messages.length) {
                              return const _TypingBubble();
                            }
                            final message = _messages[index];
                            return _MessageBubble(
                              key: ValueKey(message.id),
                              message: message,
                              animate: message.id == _freshReplyId,
                            );
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

class _MessageBubble extends ConsumerWidget {
  final _DisplayMessage message;
  final bool animate;
  const _MessageBubble({
    super.key,
    required this.message,
    this.animate = false,
  });

  void _openDraftRequest(BuildContext context, WidgetRef ref) {
    final action = message.action;
    if (action == null) return;
    final mahallaId =
        ref.read(currentUserProfileProvider).valueOrNull?.mahallaId;
    if (mahallaId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewRequestFlowScreen(
          mahallaId: mahallaId,
          initialTitle: action.title,
          initialDescription: action.description,
          initialType: action.type,
          initialPriority: action.priority,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = message.isUser;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
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
            child: isMine
                ? Text(
                    message.text,
                    style: context.bodyStyle.copyWith(color: Colors.white),
                  )
                : _TypewriterReveal(
                    text: message.text,
                    animate: animate,
                    baseStyle:
                        context.bodyStyle.copyWith(color: context.textPrimary),
                  ),
          ),
          if (message.action != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: OutlinedButton.icon(
                onPressed: () => _openDraftRequest(context, ref),
                icon: const Icon(PhosphorIconsFill.notePencil, size: 16),
                label: const Text("Murojaat formasini to'ldirish"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape:
                      const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// AI javobini birdaniga emas, "yozayotgandek" harflab ko'rsatadi
/// (`animate: false` bo'lsa, to'g'ridan-to'g'ri to'liq matn — masalan
/// eski xabarlarni qayta chizishda animatsiya kerak emas).
///
/// Server'dan javob bir martada, to'liq holda kelayotgani uchun (haqiqiy
/// token-streaming yo'q) bu klient tomonidagi taqlid — Gemini'ning
/// `streamGenerateContent`iga o'tish serverni ham, tarmoq javobini
/// oqim (SSE) sifatida o'qishni ham talab qilardi; bu yerda esa xuddi
/// shu vizual natija ancha oddiyroq yo'l bilan olinadi.
class _TypewriterReveal extends StatefulWidget {
  final String text;
  final bool animate;
  final TextStyle baseStyle;
  const _TypewriterReveal({
    required this.text,
    required this.animate,
    required this.baseStyle,
  });

  @override
  State<_TypewriterReveal> createState() => _TypewriterRevealState();
}

class _TypewriterRevealState extends State<_TypewriterReveal> {
  Timer? _timer;
  int _visibleChars = 0;

  /// Butun matnni ~900ms ichida tugatish uchun bir zarbada nechta
  /// belgi ochilishini hisoblaydi — juda uzun javoblar cheksiz sekin
  /// chiqavermasligi uchun.
  static const _targetDuration = Duration(milliseconds: 900);
  static const _tickInterval = Duration(milliseconds: 16);

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.text.isNotEmpty) {
      final totalTicks =
          _targetDuration.inMilliseconds / _tickInterval.inMilliseconds;
      final charsPerTick =
          (widget.text.length / totalTicks).ceil().clamp(1, 1000);
      _timer = Timer.periodic(_tickInterval, (timer) {
        setState(() {
          _visibleChars =
              (_visibleChars + charsPerTick).clamp(0, widget.text.length);
        });
        if (_visibleChars >= widget.text.length) {
          timer.cancel();
        }
      });
    } else {
      _visibleChars = widget.text.length;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText =
        widget.animate ? widget.text.substring(0, _visibleChars) : widget.text;
    return _MarkdownLiteText(text: visibleText, baseStyle: widget.baseStyle);
  }
}

/// AI javoblaridagi sodda markdown belgilarini (`**qalin**`, `* ` va
/// `1. ` ro'yxatlari) ko'rsatiladigan matnga aylantiradi.
///
/// To'liq markdown paketi (`flutter_markdown`) o'rniga qo'lda — chunki
/// AI Yordamchi faqat shu ikkita naqshni ishlatadi (Gemini javoblarida
/// kuzatilgan), qo'shimcha bog'liqlik shart emas.
class _MarkdownLiteText extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  const _MarkdownLiteText({required this.text, required this.baseStyle});

  static final _boldPattern = RegExp(r'\*\*(.+?)\*\*');
  static final _bulletPattern = RegExp(r'^[\*\-]\s+(.*)$');
  static final _numberedPattern = RegExp(r'^(\d+)\.\s+(.*)$');

  List<InlineSpan> _parseInline(String line, TextStyle style) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in _boldPattern.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) {
        if (i != lines.length - 1) {
          children.add(const SizedBox(height: AppSpacing.xs));
        }
        continue;
      }

      final bulletMatch = _bulletPattern.firstMatch(line);
      final numberedMatch = _numberedPattern.firstMatch(line);
      final String prefix;
      final String content;
      if (bulletMatch != null) {
        prefix = '•';
        content = bulletMatch.group(1)!;
      } else if (numberedMatch != null) {
        prefix = '${numberedMatch.group(1)}.';
        content = numberedMatch.group(2)!;
      } else {
        prefix = '';
        content = line;
      }

      final textWidget = RichText(
        text: TextSpan(
          style: baseStyle,
          children: _parseInline(content, baseStyle),
        ),
      );

      if (prefix.isEmpty) {
        children.add(textWidget);
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(prefix, style: baseStyle),
                ),
                Expanded(child: textWidget),
              ],
            ),
          ),
        );
      }
      if (i != lines.length - 1) {
        children.add(const SizedBox(height: AppSpacing.xxs));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
