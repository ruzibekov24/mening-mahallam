import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_repository.dart';
import 'poll_repository.dart';

final pollRepositoryProvider = Provider<PollRepository>((ref) {
  return PollRepository();
});

/// Joriy foydalanuvchi mahallasidagi barcha so'rovnomalarni kuzatadi.
final mahallaPollsProvider = StreamProvider.autoDispose<List<Poll>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);
      return ref.watch(pollRepositoryProvider).watchPolls(mahallaId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
