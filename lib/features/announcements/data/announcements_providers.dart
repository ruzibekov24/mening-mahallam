import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_repository.dart';
import 'announcement_repository.dart';
import 'event_repository.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Joriy foydalanuvchi mahallasidagi barcha e'lonlarni kuzatadi.
final myAnnouncementsProvider =
    StreamProvider.autoDispose<List<Announcement>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);
      return ref
          .watch(announcementRepositoryProvider)
          .watchAnnouncements(mahallaId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Joriy foydalanuvchi mahallasidagi barcha tadbirlarni kuzatadi.
final myEventsProvider = StreamProvider.autoDispose<List<MahallaEvent>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);
      return ref.watch(eventRepositoryProvider).watchEvents(mahallaId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
