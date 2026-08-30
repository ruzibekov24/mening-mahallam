import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../announcements/data/announcement_repository.dart';
import '../../announcements/data/announcements_providers.dart';
import '../../home/data/home_repository.dart';
import '../../requests/data/requests_repository.dart';

/// Joriy foydalanuvchi shaxsan o'zi yuborgan murojaatlar (authorUid
/// bo'yicha filtrlangan) — mahalladagi barcha murojaatlar emas.
final myOwnRequestsProvider =
    StreamProvider.autoDispose<List<MahallaRequest>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty || myUid == null) {
        return Stream.value([]);
      }
      return ref
          .watch(requestsRepositoryProvider)
          .watchRequests(mahallaId)
          .map((requests) =>
              requests.where((r) => r.authorUid == myUid).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Joriy foydalanuvchi shaxsan o'zi joylagan e'lonlar.
final myOwnAnnouncementsProvider =
    StreamProvider.autoDispose<List<Announcement>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty || myUid == null) {
        return Stream.value([]);
      }
      return ref
          .watch(announcementRepositoryProvider)
          .watchAnnouncements(mahallaId)
          .map((items) =>
              items.where((a) => a.authorUid == myUid).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Joriy foydalanuvchi qo'shilgan (ommaviy murojaatlarga "Men ham"
/// degan) yozuvlar soni — faollik statistikasi uchun.
final myJoinedRequestsCountProvider = Provider.autoDispose<int>((ref) {
  final requestsAsync = ref.watch(myRequestsProvider);
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return 0;
  return requestsAsync.valueOrNull
          ?.where((r) => r.joinedUids.contains(myUid))
          .length ??
      0;
});