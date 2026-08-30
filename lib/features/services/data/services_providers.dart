import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_repository.dart';
import 'service_repository.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository();
});

/// Joriy foydalanuvchi mahallasidagi barcha mahalliy xizmat
/// ko'rsatuvchilarni kuzatadi.
final mahallaServicesProvider =
    StreamProvider.autoDispose<List<LocalService>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);
      return ref.watch(serviceRepositoryProvider).watchServices(mahallaId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
