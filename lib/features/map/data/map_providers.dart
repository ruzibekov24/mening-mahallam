import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../home/data/home_repository.dart';
import '../../qr/data/mahalla_repository.dart';
import '../../requests/data/requests_repository.dart';
import '../../services/data/service_repository.dart';
import '../../services/data/services_providers.dart';

/// Xaritada ko'rsatish uchun bitta murojaat markeri.
class RequestMapMarker {
  final String requestId;
  final LatLng position;
  final RequestStatus status;
  final String title;

  RequestMapMarker({
    required this.requestId,
    required this.position,
    required this.status,
    required this.title,
  });
}

/// Toshkent markazi — mahalla koordinatasi hali kiritilmagan yoki
/// birorta murojaat joylashuvi bo'lmaganda ishlatiladigan zaxira
/// (fallback) markaz.
const _defaultCenter = LatLng(41.311081, 69.240562);

/// Joriy foydalanuvchining roliga qarab, u ko'rishga haqli murojaatlar
/// oqimini tanlaydi — xodim/rais uchun cheklovsiz, oddiy fuqaro uchun
/// faqat ommaviy + o'zi yozgan (batafsili izoh: `requests_repository.dart`
/// dagi `watchVisibleRequests`).
Stream<List<RequestMapMarker>> _visibleRequestMarkers(
  Ref ref,
  String mahallaId,
) async* {
  final profile = await ref.watch(currentUserProfileProvider.future);
  final repo = ref.watch(requestsRepositoryProvider);
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  final requestsStream = (profile?.role.canManageRequests == true)
      ? repo.watchRequests(mahallaId)
      : (myUid == null
          ? Stream<List<MahallaRequest>>.value(const [])
          : repo.watchVisibleRequests(mahallaId, myUid));

  yield* requestsStream.map((requests) => requests
      .where((r) => r.hasLocation)
      .map((r) => RequestMapMarker(
            requestId: r.id,
            position: LatLng(r.latitude!, r.longitude!),
            status: r.status,
            title: r.title,
          ))
      .toList());
}

/// Mahalla xarita markazini aniqlaydi: avval mahalla hujjatidagi
/// koordinatani, u bo'lmasa joylashuvi bor birinchi (ko'rishga ruxsat
/// etilgan) murojaatni, aks holda standart markazni ishlatadi.
final mahallaMapCenterProvider =
    FutureProvider.autoDispose.family<LatLng, String>((ref, mahallaId) async {
  final mahallaInfo =
      await ref.watch(mahallaRepositoryProvider).fetchMahallaInfo(mahallaId);
  if (mahallaInfo?.latitude != null && mahallaInfo?.longitude != null) {
    return LatLng(mahallaInfo!.latitude!, mahallaInfo.longitude!);
  }

  final markers = await _visibleRequestMarkers(ref, mahallaId).first;
  if (markers.isNotEmpty) {
    return markers.first.position;
  }

  return _defaultCenter;
});

/// Xaritadagi markaz belgisi yonida ko'rsatiladigan mahalla nomi.
///
/// `currentMahallaNameProvider`dan farqi — bu YO'L ORQALI (`mahallaId`)
/// ishlaydi, ya'ni xarita boshqa mahallani ko'rsatayotgan bo'lsa ham
/// (masalan super admin mahallalar orasida almashganda) to'g'ri nomni
/// beradi.
final mahallaMapNameProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, mahallaId) async {
  final info =
      await ref.watch(mahallaRepositoryProvider).fetchMahallaInfo(mahallaId);
  final name = info?.name.trim();
  return (name == null || name.isEmpty) ? null : name;
});

/// Mahalla chegarasi (agar rais tomonidan belgilangan bo'lsa) —
/// xaritada Polygon sifatida chizish uchun.
final mahallaBoundaryProvider =
    FutureProvider.autoDispose.family<List<LatLng>?, String>(
        (ref, mahallaId) async {
  final mahallaInfo =
      await ref.watch(mahallaRepositoryProvider).fetchMahallaInfo(mahallaId);
  final boundary = mahallaInfo?.boundary;
  if (boundary == null || boundary.length < 3) return null;
  return boundary.map((p) => LatLng(p[0], p[1])).toList();
});

/// Joylashuvi belgilangan, joriy foydalanuvchi ko'rishga haqli
/// murojaatlarni xarita markerlariga aylantirib beradi. Oddiy fuqaro
/// uchun boshqalarning maxfiy murojaatlari xaritada ham ko'rinmaydi.
final requestMapMarkersProvider = StreamProvider.autoDispose
    .family<List<RequestMapMarker>, String>((ref, mahallaId) {
  return _visibleRequestMarkers(ref, mahallaId);
});

/// Xaritada ko'rsatish uchun bitta xizmat ko'rsatuvchi markeri.
class ServiceMapMarker {
  final String serviceId;
  final LatLng position;
  final String name;
  final String phone;
  final ServiceCategory category;

  ServiceMapMarker({
    required this.serviceId,
    required this.position,
    required this.name,
    required this.phone,
    required this.category,
  });
}

/// Joylashuvi belgilangan mahalliy xizmat ko'rsatuvchilarni xarita
/// markerlariga aylantirib beradi — `_visibleRequestMarkers` bilan bir
/// xil naqsh, faqat xizmatlar hamma uchun ochiq (murojaatlardan farqli
/// o'laroq maxfiylik cheklovi yo'q).
final serviceMapMarkersProvider = StreamProvider.autoDispose
    .family<List<ServiceMapMarker>, String>((ref, mahallaId) {
  final repo = ref.watch(serviceRepositoryProvider);
  return repo.watchServices(mahallaId).map((services) => services
      .where((s) => s.hasLocation)
      .map((s) => ServiceMapMarker(
            serviceId: s.id,
            position: LatLng(s.latitude!, s.longitude!),
            name: s.name,
            phone: s.phone,
            category: s.category,
          ))
      .toList());
});