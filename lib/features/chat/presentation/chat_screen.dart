import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../home/presentation/neighbor_profile_screen.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';

/// Xabar uzatilgach yozayotganlik belgisini qanchagacha "jonli" deb
/// hisoblash — yozuvchi tomon shu muddatdan ko'p harakatsiz qolsa,
/// o'zi maydonni tozalaydi (`ChatScreen._typingIdleTimeout`).
const _typingIdleTimeout = Duration(seconds: 5);

/// Xabar bosilganda tanlanadigan qisqa, keng tarqalgan emoji
/// to'plami — to'liq emoji klaviaturasi shart emas (spetsifikatsiya
/// bo'yicha).
const _chatReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

/// Ikkita foydalanuvchi orasidagi suhbat ekrani — real-vaqtli xabar
/// oqimi, pastda matn kiritish maydoni.
class ChatScreen extends ConsumerStatefulWidget {
  final String otherUid;
  const ChatScreen({super.key, required this.otherUid});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  bool _isSending = false;

  /// Tahrirlanayotgan xabar — `null` bo'lsa yozish maydoni oddiy yangi
  /// xabar yozish rejimida. Berilgan bo'lsa, [_send] yangi xabar
  /// yaratish o'rniga shu xabarni tahrirlaydi.
  ChatMessage? _editingMessage;

  // Faqat ekran birinchi ochilganda ko'ringan xabarlarga kirish
  // animatsiyasi beriladi — har yangi xabar kelganda ro'yxat qayta
  // animatsiya qilinsa, suhbat chalg'ituvchi bo'lib qolardi.
  Set<String>? _initialMessageIds;

  // "Yozmoqda..." signalini har harfda emas, kamida 2 soniyada bir
  // marta yozamiz — Firestore yozuvlarini keraksiz ko'paytirmaslik
  // uchun. 5 soniya harakatsizlikdan keyin esa avtomatik tozalanadi.
  DateTime? _lastTypingWriteAt;
  Timer? _typingIdleTimer;
  bool _typingActive = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _conversationId => ref
      .read(chatRepositoryProvider)
      .conversationIdFor(_myUid, widget.otherUid);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markConversationRead(_conversationId);
    });
  }

  @override
  void dispose() {
    _typingIdleTimer?.cancel();
    // Ekrandan chiqishda yozayotganlik belgisini tozalash — "best
    // effort", javobni kutmaymiz.
    if (_typingActive) {
      ref.read(chatRepositoryProvider).setTyping(_conversationId, isTyping: false);
    }
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    final repo = ref.read(chatRepositoryProvider);
    if (text.trim().isEmpty) {
      _typingIdleTimer?.cancel();
      if (_typingActive) {
        _typingActive = false;
        _lastTypingWriteAt = null;
        repo.setTyping(_conversationId, isTyping: false);
      }
      return;
    }

    final now = DateTime.now();
    if (_lastTypingWriteAt == null ||
        now.difference(_lastTypingWriteAt!) > const Duration(seconds: 2)) {
      _lastTypingWriteAt = now;
      _typingActive = true;
      repo.setTyping(_conversationId, isTyping: true);
    }

    _typingIdleTimer?.cancel();
    _typingIdleTimer = Timer(_typingIdleTimeout, () {
      _typingActive = false;
      _lastTypingWriteAt = null;
      ref.read(chatRepositoryProvider).setTyping(_conversationId, isTyping: false);
    });
  }

  void _clearTypingImmediately() {
    _typingIdleTimer?.cancel();
    if (_typingActive) {
      _typingActive = false;
      _lastTypingWriteAt = null;
      ref.read(chatRepositoryProvider).setTyping(_conversationId, isTyping: false);
    }
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    if (_editingMessage != null) {
      final editing = _editingMessage!;
      setState(() {
        _isSending = true;
        _editingMessage = null;
      });
      _textController.clear();
      try {
        await ref.read(chatRepositoryProvider).editMessage(
              conversationId: _conversationId,
              messageId: editing.id,
              newText: text,
            );
      } catch (_) {
        if (mounted) {
          setState(() {
            _editingMessage = editing;
            _textController.text = text;
          });
        }
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
      return;
    }

    final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
    final myName = myProfile == null
        ? ''
        : '${myProfile.firstName} ${myProfile.lastName}'.trim();

    setState(() => _isSending = true);
    _textController.clear();
    _clearTypingImmediately();
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            otherUid: widget.otherUid,
            text: text,
            senderFullName: myName,
          );
    } catch (_) {
      _textController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startEdit(ChatMessage message) {
    setState(() {
      _editingMessage = message;
      _textController.text = message.text;
      _textController.selection =
          TextSelection.collapsed(offset: message.text.length);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _textController.clear();
    });
  }

  Future<void> _confirmAndDeleteMessage(ChatMessage message) async {
    final confirmed = await confirmDelete(
      context,
      itemTitle: message.text.isEmpty ? '' : message.text,
    );
    if (!confirmed || !mounted) return;
    await ref.read(chatRepositoryProvider).deleteMessage(
          conversationId: _conversationId,
          messageId: message.id,
        );
  }

  Future<void> _pickAndSendImage() async {
    final l10n = AppLocalizations.of(context);
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;

    final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
    final myName = myProfile == null
        ? ''
        : '${myProfile.firstName} ${myProfile.lastName}'.trim();

    setState(() => _isSending = true);
    try {
      final conversationId = _conversationId;
      final extension = picked.path.split('.').last;
      final url = await ImageUploadService().uploadImage(
        file: File(picked.path),
        storagePath:
            'chat/$conversationId/${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (!mounted) return;
      await ref.read(chatRepositoryProvider).sendMessage(
            otherUid: widget.otherUid,
            text: '',
            senderFullName: myName,
            imageUrl: url,
          );
    } on ImageUploadException catch (e) {
      if (mounted) showAppAlert(context, e.message, kind: AppAlertKind.error);
    } catch (_) {
      if (mounted) {
        showAppAlert(context, l10n.imageUploadFailed, kind: AppAlertKind.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Xabarni uzoq bosganda ochiladigan menyu — emoji reaksiya
  /// tanlagich, va agar [onReport] berilgan bo'lsa (boshqa
  /// foydalanuvchining xabari) pastida "Shikoyat qilish" qatori.
  void _showReactionPicker(
    ChatMessage message, {
    VoidCallback? onReport,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    final l10n = AppLocalizations.of(context);
    final myUid = _myUid;
    final currentEmoji = message.reactions[myUid];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = sheetContext.isDarkMode;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final emoji in _chatReactionEmojis)
                      TapScale(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(chatRepositoryProvider).toggleMessageReaction(
                                conversationId: _conversationId,
                                messageId: message.id,
                                emoji: emoji,
                                currentEmoji: currentEmoji,
                              );
                        },
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 150),
                          scale: currentEmoji == emoji ? 1.25 : 1.0,
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                  ],
                ),
                if (onReport != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.flag),
                    title: Text(l10n.reportAction),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onReport();
                    },
                  ),
                ],
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  if (onEdit != null)
                    ListTile(
                      leading: const Icon(PhosphorIconsRegular.pencilSimple),
                      title: Text(l10n.editMessageAction),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onEdit();
                      },
                    ),
                  if (onDelete != null)
                    ListTile(
                      leading: const Icon(PhosphorIconsRegular.trash,
                          color: AppColors.danger),
                      title: Text(l10n.deleteButton,
                          style: const TextStyle(color: AppColors.danger)),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onDelete();
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFullscreenImage(String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  /// Ikki sana bir xil kalendar kunidami — sana ajratkichlarini
  /// qo'yish uchun.
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateSeparatorLabel(AppLocalizations l10n, DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return l10n.today;
    final yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(date, yesterday)) return l10n.yesterdayLabel;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final otherBriefAsync = ref.watch(chatUserBriefProvider(widget.otherUid));
    final messagesAsync =
        ref.watch(conversationMessagesProvider(_conversationId));
    final conversationAsync =
        ref.watch(conversationDocProvider(_conversationId));

    final conversation = conversationAsync.valueOrNull;
    final otherLastRead = conversation?.lastReadAt[widget.otherUid];
    final otherTypingAt = conversation?.typing[widget.otherUid];
    final isOtherTyping = otherTypingAt != null &&
        DateTime.now().difference(otherTypingAt) < _typingIdleTimeout;

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
                  Expanded(
                    child: otherBriefAsync.when(
                      data: (member) => InkWell(
                        borderRadius: AppRadius.smAll,
                        onTap: member == null
                            ? null
                            : () => AppPageRoute.push(
                                  context,
                                  NeighborProfileScreen(member: member),
                                ),
                        child: Row(
                          children: [
                            UserAvatar(
                              size: 36,
                              firstName: member?.firstName ?? '',
                              lastName: member?.lastName ?? '',
                              photoUrl: member?.photoUrl,
                              seed: widget.otherUid,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    member == null
                                        ? l10n.defaultUserName
                                        : '${member.firstName} ${member.lastName}'
                                            .trim(),
                                    style: context.titleStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: isOtherTyping
                                        ? Row(
                                            key: const ValueKey('typing'),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                l10n.typingIndicator,
                                                style: context.captionStyle
                                                    .copyWith(
                                                        color:
                                                            AppColors.primary),
                                              ),
                                              const SizedBox(width: AppSpacing.xxs),
                                              const _TypingDots(),
                                            ],
                                          )
                                        : const SizedBox.shrink(
                                            key: ValueKey('idle')),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const Row(
                        children: [
                          SizedBox(width: 36, height: 36),
                          SizedBox(width: AppSpacing.sm),
                        ],
                      ),
                      error: (_, __) => const Row(
                        children: [
                          SizedBox(width: 36, height: 36),
                          SizedBox(width: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noMessagesYet,
                        style: context.secondaryStyle,
                      ),
                    );
                  }
                  _initialMessageIds ??= messages.map((m) => m.id).toSet();
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderUid == myUid;
                      final isRead = isMine &&
                          otherLastRead != null &&
                          !otherLastRead.isBefore(message.createdAt);

                      // `reverse: true` bo'lgani uchun ro'yxatda
                      // index 0 — ENG SO'NGGI xabar. Sana ajratkichi
                      // shu xabar bilan undan "keyingi" (vaqt bo'yicha
                      // oldingi, ro'yxatda index+1) xabar orasida
                      // kun farqi bo'lsa ko'rsatiladi.
                      final olderMessage =
                          index + 1 < messages.length ? messages[index + 1] : null;
                      final showDateSeparator = olderMessage == null ||
                          !_isSameDay(
                              message.createdAt, olderMessage.createdAt);

                      final bubble = _MessageBubble(
                        message: message,
                        isMine: isMine,
                        isRead: isRead,
                        onLongPress: message.deleted
                            ? null
                            : () => _showReactionPicker(
                                  message,
                                  onReport: isMine
                                      ? null
                                      : () {
                                          final mahallaId = ref
                                              .read(currentUserProfileProvider)
                                              .valueOrNull
                                              ?.mahallaId;
                                          showReportSheet(
                                            context,
                                            ref,
                                            targetType:
                                                ReportTargetType.chatMessage,
                                            targetId: message.id,
                                            targetSnippet: message.text,
                                            mahallaId: mahallaId,
                                          );
                                        },
                                  onEdit: isMine && !message.isImage
                                      ? () => _startEdit(message)
                                      : null,
                                  onDelete: isMine
                                      ? () => _confirmAndDeleteMessage(message)
                                      : null,
                                ),
                        onImageTap: message.isImage
                            ? () => _openFullscreenImage(message.imageUrl!)
                            : null,
                        onReactionTap: (emoji) => ref
                            .read(chatRepositoryProvider)
                            .toggleMessageReaction(
                              conversationId: _conversationId,
                              messageId: message.id,
                              emoji: emoji,
                              currentEmoji: message.reactions[_myUid],
                            ),
                        myUid: _myUid,
                      );

                      Widget item = bubble;
                      if (showDateSeparator) {
                        item = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            bubble,
                            _DateSeparator(
                              label: _dateSeparatorLabel(
                                  l10n, message.createdAt),
                            ),
                          ],
                        );
                      }

                      if (_initialMessageIds!.contains(message.id)) {
                        return StaggeredEntrance(index: index, child: item);
                      }
                      return item;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child:
                      Text(l10n.unexpectedError, style: context.secondaryStyle),
                ),
              ),
            ),
            if (_editingMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.xs),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.pencilSimple,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(l10n.editMessageAction,
                          style: context.captionStyle
                              .copyWith(color: AppColors.primary)),
                    ),
                    TapScale(
                      onTap: _cancelEdit,
                      child: Icon(PhosphorIconsRegular.xCircle,
                          size: 16, color: AppColors.primary),
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
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: l10n.attachImageAction,
                        onPressed: _editingMessage != null || _isSending
                            ? null
                            : _pickAndSendImage,
                        icon: Icon(PhosphorIconsRegular.imageSquare,
                            color: context.textSecondary),
                      ),
                    ),
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
                          onChanged: _onTextChanged,
                          decoration: InputDecoration(
                            hintText: l10n.messageHint,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: context.bodyStyle,
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

/// Sana ajratkichi — "Bugun", "Kecha" yoki `kk.oo.yyyy` — kunlar
/// almashganda xabarlar orasiga qo'yiladi.
class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? AppColors.darkSurface
                : AppColors.lightBorder,
            borderRadius: AppRadius.pillAll,
          ),
          child: Text(
            label,
            style: context.captionStyle.copyWith(color: context.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Boshqa ishtirokchi hozir yozayotganida ko'rsatiladigan uchta
/// nuqtali animatsiya — `StaggeredEntrance` bilan bir xil yumshoq
/// (easeOut) animatsiya uslubida.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value - i * 0.2) % 1.0;
              final opacity = t < 0.5 ? (0.3 + t) : (1.3 - t);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Opacity(
                  opacity: opacity.clamp(0.3, 1.0),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// Xabar rasmini to'liq ekranda ko'rish — pinch-to-zoom bilan.
/// Ilovada boshqa joyda tayyor to'liq ekran rasm ko'ruvchi yo'q edi,
/// shuning uchun shu yerda yengil versiyasi yozildi.
class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  const _FullscreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(),
                errorWidget: (_, __, ___) => const Icon(
                  PhosphorIconsRegular.imageBroken,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool isRead;
  final String myUid;

  /// Har qanday xabarni (o'zingizniki ham) uzoq bosganda emoji
  /// reaksiya tanlagichini ochadi — agar xabar boshqa foydalanuvchiga
  /// tegishli bo'lsa, o'sha menyuda "Shikoyat qilish" bandi ham
  /// chiqadi (mantiq chaqiruvchi tomonda — `ChatScreen._showReactionPicker`).
  /// O'chirilgan xabarlar uchun `null` — endi hech qanday amal yo'q.
  final VoidCallback? onLongPress;

  /// Rasm xabari bosilganda to'liq ekranda ochish uchun — matn
  /// xabarlarida `null`.
  final VoidCallback? onImageTap;

  final ValueChanged<String> onReactionTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.isRead,
    required this.onLongPress,
    required this.onReactionTap,
    required this.myUid,
    this.onImageTap,
  });

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final reactionEntries = message.reactions.entries.toList();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
                borderRadius: AppRadius.mdAll,
                onLongPress: onLongPress,
                onTap: message.isImage ? onImageTap : null,
                child: Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                  padding: message.isImage
                      ? const EdgeInsets.all(4)
                      : const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isMine
                        ? AppColors.primary
                        : (context.isDarkMode
                            ? AppColors.darkSurface
                            : AppColors.lightBorder),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.deleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIconsRegular.prohibit,
                                size: 14,
                                color: (isMine
                                        ? Colors.white
                                        : context.textSecondary)
                                    .withValues(alpha: 0.75)),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)
                                  .messageDeletedPlaceholder,
                              style: context.bodyStyle.copyWith(
                                fontStyle: FontStyle.italic,
                                color: (isMine
                                        ? Colors.white
                                        : context.textSecondary)
                                    .withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        )
                      else ...[
                      if (message.isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: message.imageUrl!,
                            width: 220,
                            height: 220,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 220,
                              height: 220,
                              color: context.surfaceColor,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 220,
                              height: 220,
                              color: context.surfaceColor,
                              alignment: Alignment.center,
                              child: Icon(PhosphorIconsRegular.imageBroken,
                                  color: context.textSecondary),
                            ),
                          ),
                        ),
                      if (message.text.isNotEmpty) ...[
                        if (message.isImage)
                          const SizedBox(height: AppSpacing.xs),
                        Padding(
                          padding: message.isImage
                              ? const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs)
                              : EdgeInsets.zero,
                          child: Text(
                            message.text,
                            style: context.bodyStyle.copyWith(
                              color:
                                  isMine ? Colors.white : context.textPrimary,
                            ),
                          ),
                        ),
                      ],
                      ],
                      const SizedBox(height: 2),
                      Padding(
                        padding: message.isImage
                            ? const EdgeInsets.fromLTRB(0, 0, AppSpacing.xs, 2)
                            : EdgeInsets.zero,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.editedAt != null && !message.deleted) ...[
                              Text(
                                AppLocalizations.of(context).editedLabel,
                                style: context.captionStyle.copyWith(
                                  color: isMine
                                      ? Colors.white.withValues(alpha: 0.65)
                                      : context.textMuted,
                                ),
                              ),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              _formatTime(message.createdAt),
                              style: context.captionStyle.copyWith(
                                color: isMine
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : context.textMuted,
                              ),
                            ),
                            if (isMine) ...[
                              const SizedBox(width: 3),
                              Icon(
                                isRead
                                    ? PhosphorIconsRegular.checks
                                    : PhosphorIconsRegular.check,
                                size: 13,
                                color: isRead
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.75),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (reactionEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: _ReactionsChipRow(
                reactions: message.reactions,
                myUid: myUid,
                onTap: onReactionTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Xabar ostidagi qo'yilgan reaksiyalar — bir xil emoji uchun
/// hisoblagich bilan bittalashtirilgan chip'lar sifatida ko'rsatiladi.
class _ReactionsChipRow extends StatelessWidget {
  final Map<String, String> reactions;
  final String myUid;
  final ValueChanged<String> onTap;

  const _ReactionsChipRow({
    required this.reactions,
    required this.myUid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final emoji in reactions.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    final myEmoji = reactions[myUid];

    return Wrap(
      spacing: AppSpacing.xxs,
      children: [
        for (final entry in counts.entries)
          TapScale(
            onTap: () => onTap(entry.key),
            haptic: true,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: myEmoji == entry.key
                    ? AppColors.primary.withValues(alpha: 0.14)
                    : context.surfaceColor,
                borderRadius: AppRadius.pillAll,
                border: Border.all(
                  color: myEmoji == entry.key
                      ? AppColors.primary
                      : context.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 12)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${entry.value}',
                      style: context.captionStyle.copyWith(
                        color: myEmoji == entry.key
                            ? AppColors.primary
                            : context.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
