import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../announcements/data/announcements_providers.dart';
import '../../requests/data/requests_repository.dart';
import 'home_repository.dart';

/// Home ekranidagi statistika kartochkalari uchun bitta joyga
/// yig'ilgan qiymatlar.
class HomeStats {
  final int activeRequests;
  final int newAnnouncements;
  final int upcomingEvents;
  final int totalMembers;

  const HomeStats({
    required this.activeRequests,
    required this.newAnnouncements,
    required this.upcomingEvents,
    required this.totalMembers,
  });
}

/// Uchta mavjud oqim (murojaatlar, e'lonlar, tadbirlar)ni birlashtirib,
/// statistika kartochkalari uchun hisoblab beradi. Qo'shimcha Firestore
/// so'rovi qilmaydi — allaqachon boshqa joyda ishlatilayotgan
/// provider'larning natijasidan foydalanadi.
final homeStatsProvider = Provider.autoDispose<AsyncValue<HomeStats>>((ref) {
  final requestsAsync = ref.watch(myRequestsProvider);
  final announcementsAsync = ref.watch(myAnnouncementsProvider);
  final eventsAsync = ref.watch(upcomingEventsProvider);
  final profileAsync = ref.watch(currentUserProfileProvider);
  final mahallaId = profileAsync.valueOrNull?.mahallaId;
  final membersAsync = mahallaId == null
      ? const AsyncValue<List<MahallaMember>>.data([])
      : ref.watch(mahallaMembersProvider(mahallaId));

  if (requestsAsync.isLoading ||
      announcementsAsync.isLoading ||
      eventsAsync.isLoading ||
      membersAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final requestsError = requestsAsync.error;
  final announcementsError = announcementsAsync.error;
  final eventsError = eventsAsync.error;
  if (requestsError != null || announcementsError != null || eventsError != null) {
    return AsyncValue.error(
      requestsError ?? announcementsError ?? eventsError!,
      StackTrace.current,
    );
  }

  final requests = requestsAsync.value ?? [];
  final announcements = announcementsAsync.value ?? [];
  final events = eventsAsync.value ?? [];
  final members = membersAsync.value ?? [];

  final activeRequests = requests
      .where((r) =>
          r.status == RequestStatus.yangi || r.status == RequestStatus.jarayonda)
      .length;

  final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
  final newAnnouncements =
      announcements.where((a) => a.createdAt.isAfter(sevenDaysAgo)).length;

  return AsyncValue.data(
    HomeStats(
      activeRequests: activeRequests,
      newAnnouncements: newAnnouncements,
      upcomingEvents: events.length,
      totalMembers: members.length,
    ),
  );
});

/// So'nggi faoliyat — e'lonlar, murojaatlar va tadbirlarni bitta
/// xronologik (eng yangisidan) ro'yxatga birlashtirib, so'nggi 5 tasini
/// qaytaradi. Qo'shimcha Firestore so'rovi qilmaydi.
final recentActivityProvider =
    Provider.autoDispose<AsyncValue<List<ActivityItem>>>((ref) {
  final requestsAsync = ref.watch(myRequestsProvider);
  final announcementsAsync = ref.watch(myAnnouncementsProvider);
  final eventsAsync = ref.watch(myEventsProvider);

  if (requestsAsync.isLoading ||
      announcementsAsync.isLoading ||
      eventsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final requestsError = requestsAsync.error;
  final announcementsError = announcementsAsync.error;
  final eventsError = eventsAsync.error;
  if (requestsError != null || announcementsError != null || eventsError != null) {
    return AsyncValue.error(
      requestsError ?? announcementsError ?? eventsError!,
      StackTrace.current,
    );
  }

  final requests = requestsAsync.value ?? [];
  final announcements = announcementsAsync.value ?? [];
  final events = eventsAsync.value ?? [];

  final items = <ActivityItem>[
    ...announcements.map((a) => ActivityItem(
          kind: ActivityKind.announcement,
          title: a.title,
          createdAt: a.createdAt,
        )),
    ...requests.map((r) => ActivityItem(
          kind: ActivityKind.request,
          title: r.title,
          createdAt: r.createdAt,
        )),
    ...events.map((e) => ActivityItem(
          kind: ActivityKind.event,
          title: e.title,
          createdAt: e.dateTime,
        )),
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return AsyncValue.data(items.take(5).toList());
});