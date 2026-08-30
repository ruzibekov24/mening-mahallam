import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qurilmaning tarmoqqa ulanish holati.
///
/// `PresenceService` (`lib/core/services/presence_service.dart`) bilan
/// ADASHTIRMASLIK KERAK: u Firebase Realtime Database'ga serverga
/// ulanishni kuzatadi (boshqa foydalanuvchilar "online/offline"ni
/// ko'rishi uchun). Bu sinf esa QURILMANING o'zi internetga ulanganmi
/// yo'qmi — shunchaki mahalliy tarmoq holati, hech qanday serverga
/// yubormaydi. Ikkisi butunlay boshqa narsani anglatadi va biri
/// ikkinchisining o'rnini bosa olmaydi.
enum DeviceConnectivity {
  online,
  offline;

  bool get isOnline => this == DeviceConnectivity.online;
}

DeviceConnectivity _fromResults(List<ConnectivityResult> results) {
  // `connectivity_plus` 6.x+ versiyasida oqim bittadan emas, RO'YXAT
  // qaytaradi (qurilma bir vaqtda Wi-Fi + mobil tarmoqqa ulangan
  // bo'lishi mumkin). `none` bo'lmagan har qanday natija — onlayn.
  final hasConnection =
      results.any((r) => r != ConnectivityResult.none);
  return hasConnection ? DeviceConnectivity.online : DeviceConnectivity.offline;
}

/// `connectivity_plus`ning xom oqimini bitta soddalashtirilgan holatga
/// aylantiradi. `keepAlive` — ilova butun umri davomida oflayn
/// bannerni tinglashi kerak, shuning uchun provider oxirgi tinglovchi
/// yo'qolganda o'chirilmasligi lozim.
final connectivityStatusProvider =
    StreamProvider<DeviceConnectivity>((ref) async* {
  final connectivity = Connectivity();

  // Boshlang'ich holatni darhol beramiz — oqim faqat O'ZGARISHDA
  // hodisa chiqaradi, ilova ochilgan zahoti hech narsa demaydi.
  yield _fromResults(await connectivity.checkConnectivity());

  yield* connectivity.onConnectivityChanged.map(_fromResults);
});

/// UI uchun qulay qisqartma: hozircha onlaynmi (ma'lumot kelmagunicha
/// yoki xato bo'lsa — "onlayn" deb hisoblanadi, ya'ni banner shubhali
/// holatda ko'rsatilmaydi, faqat ANIQ oflayn bo'lganda ko'rinadi).
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityStatusProvider);
  return status.when(
    data: (value) => value.isOnline,
    loading: () => true,
    error: (_, __) => true,
  );
});
