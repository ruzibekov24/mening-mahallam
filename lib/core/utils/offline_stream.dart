import 'dart:async';

/// Real qurilmada avvalroq (v1.4.1, native `connectivity_plus` paketi
/// sabab bo'lgan degan gumon bilan, hech qachon aniq tasdiqlanmagan
/// holda) bosh ekranlarda ishga tushmaslik muammosiga olib kelgan
/// holatning oldini olish uchun ataylab **hech qanday native plugin
/// ishlatilmaydi** — faqat `dart:async`dagi `Stream.timeout()`.
///
/// Firestore'ning offline keshi (`main.dart`da yoqilgan) tufayli,
/// internet uzilganda `.snapshots()` odatda XATO tashlamaydi — u
/// shunchaqa jim qoladi (agar kesh bo'lsa, oxirgi ma'lumotni ko'rsatib
/// turadi; kesh umuman bo'lmasa — masalan ilova birinchi marta
/// oflaynda ochilganda — abadiy "yuklanmoqda" holatida qolib ketadi).
/// Foydalanuvchiga cheksiz shimmer ko'rsatish o'rniga, belgilangan
/// vaqt ichida hech qanday ma'lumot kelmasa, aniq "internet yo'q"
/// xatosi bilan almashtiramiz — bu xato `AppErrorView.fromError`
/// tomonidan avtomatik tanib olinadi (matnida "network" so'zi bor).
class NoInternetStreamException implements Exception {
  @override
  String toString() =>
      'NoInternetStreamException: network unavailable (stream timeout)';
}

extension OfflineStreamTimeout<T> on Stream<T> {
  /// Agar ushbu oqimdan BIRINCHI hodisa (ma'lumot yoki xato) `duration`
  /// ichida kelmasa, `NoInternetStreamException` bilan xato qo'shadi.
  ///
  /// MUHIM: faqat DASTLABKI kutishni cheklaydi, keyingi har bir
  /// hodisadan keyin qayta ishga tushmaydi. Firestore'ning
  /// `.snapshots()` oqimi ma'lumot o'zgarmaguncha umuman yangi hodisa
  /// bermaydi — agar taymer har hodisadan keyin qayta boshlansa (oddiy
  /// `Stream.timeout()` kabi), foydalanuvchi ekranda `duration`dan
  /// ko'proq turgani (masalan xotirjam suhbat ro'yxati) internet
  /// uzilgan deb noto'g'ri ko'rsatilardi — ulanish butunlay yaxshi
  /// bo'lsa ham. Bu faqat "birinchi ma'lumot umuman kelmayapti"
  /// holatini (masalan ilova birinchi marta oflaynda, keshsiz
  /// ochilganda) ushlaydi.
  Stream<T> withOfflineTimeout([
    Duration duration = const Duration(seconds: 12),
  ]) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? timer;
    var firstEventReceived = false;

    void cancelTimer() {
      timer?.cancel();
      timer = null;
    }

    controller = StreamController<T>(
      onListen: () {
        timer = Timer(duration, () {
          if (!firstEventReceived) {
            controller.addError(NoInternetStreamException());
          }
        });
        subscription = listen(
          (event) {
            firstEventReceived = true;
            cancelTimer();
            controller.add(event);
          },
          onError: (Object error, StackTrace stackTrace) {
            firstEventReceived = true;
            cancelTimer();
            controller.addError(error, stackTrace);
          },
          onDone: () {
            cancelTimer();
            controller.close();
          },
        );
      },
      onCancel: () {
        cancelTimer();
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
