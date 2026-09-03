import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/offline_stream.dart';
import '../../announcements/data/announcements_providers.dart';
import '../../home/data/home_repository.dart';
import 'feed_item.dart';
import 'feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository();
});

/// Hozircha nechta post yuklanganini boshqaradi — "yana yuklash"
/// bosilganda [FeedScreen] shu qiymatni oshiradi, `myPostsProvider`
/// esa avtomatik qayta ulanadi (Firestore realtime stream, cheklov
/// oshganda faqat qo'shimcha hujjatlar yuklanadi).
final postsLimitProvider = StateProvider.autoDispose<int>((ref) => 20);

/// Joriy foydalanuvchi mahallasidagi postlarni (eng yangisidan
/// boshlab, `postsLimitProvider` chegarasigacha) kuzatadi.
final myPostsProvider = StreamProvider.autoDispose<List<Post>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final limit = ref.watch(postsLimitProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);
      return ref
          .watch(feedRepositoryProvider)
          .watchPosts(mahallaId, limit: limit)
          .withOfflineTimeout();
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Postlar soni joriy chegaraga yetgan bo'lsa (ya'ni ko'proq post
/// mavjud bo'lishi mumkin) — "yana yuklash" tugmasini ko'rsatish uchun.
/// Aniq umumiy son bilmasdan (bu qo'shimcha `count()` so'rovi talab
/// qiladi) eng oddiy ishonchli signal: qaytgan post soni = chegara.
final hasMorePostsProvider = Provider.autoDispose<bool>((ref) {
  final posts = ref.watch(myPostsProvider).valueOrNull;
  final limit = ref.watch(postsLimitProvider);
  return posts != null && posts.length >= limit;
});

/// Postlar + e'lonlar + tadbirlarni bitta xronologik ro'yxatga
/// birlashtiradi ([FeedScreen] uchun). Alohida stream merge o'rniga
/// oddiy Riverpod `Provider` — har uchala manba providerlari yangi
/// ma'lumot chiqarganda avtomatik qayta hisoblanadi.
final myFeedItemsProvider = Provider.autoDispose<List<FeedItem>>((ref) {
  final posts = ref.watch(myPostsProvider).valueOrNull ?? const [];
  final announcements =
      ref.watch(myAnnouncementsProvider).valueOrNull ?? const [];
  final events = ref.watch(myEventsProvider).valueOrNull ?? const [];

  final items = <FeedItem>[
    ...posts.map(FeedItem.post),
    ...announcements.map(FeedItem.announcement),
    ...events.map(FeedItem.event),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
});

/// Uch manbaning kamida bittasi hali birinchi marta yuklanmoqda —
/// birlashtirilgan ro'yxat bo'sh bo'lganda shimmer ko'rsatish uchun.
final myFeedLoadingProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(myPostsProvider).isLoading ||
      ref.watch(myAnnouncementsProvider).isLoading ||
      ref.watch(myEventsProvider).isLoading;
});

/// Bitta postning izohlarini kuzatadi — kalit `'$mahallaId:$postId'`
/// (`requestCommentsProvider`dagi bilan bir xil naqsh).
final postCommentsProvider =
    StreamProvider.autoDispose.family<List<PostComment>, String>((ref, key) {
  final parts = key.split(':');
  final mahallaId = parts[0];
  final postId = parts[1];
  return ref
      .watch(feedRepositoryProvider)
      .watchComments(mahallaId: mahallaId, postId: postId);
});
