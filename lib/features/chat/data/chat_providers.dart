import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_repository.dart';
import 'chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final myConversationsProvider =
    StreamProvider.autoDispose<List<Conversation>>((ref) {
  return ref.watch(chatRepositoryProvider).watchMyConversations();
});

final conversationMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, conversationId) {
  return ref.watch(chatRepositoryProvider).watchMessages(conversationId);
});

final totalUnreadMessagesProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(chatRepositoryProvider).watchTotalUnreadCount();
});

/// Bitta uid bo'yicha qisqa profil (ism, rasm) — suhbat ro'yxati va
/// sarlavhasi uchun. Individual `.get()` orqali, "list" cheklovidan
/// mustasno (`fetchMembersByUids`dagi kabi naqsh).
final chatUserBriefProvider =
    FutureProvider.autoDispose.family<MahallaMember?, String>((ref, uid) async {
  final members =
      await ref.watch(homeRepositoryProvider).fetchMembersByUids([uid]);
  return members.isEmpty ? null : members.first;
});
