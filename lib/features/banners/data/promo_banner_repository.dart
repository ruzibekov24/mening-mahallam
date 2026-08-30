import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bosh ekrandagi aylanuvchi banner — e'lon, tashqi havola, konkurs
/// yoki reklama bo'lishi mumkin. Mahallaga bog'lanmagan (butun
/// ilova bo'ylab bir xil), faqat super admin qo'shadi/o'chiradi.
class PromoBanner {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final String? linkUrl;
  final int order;
  final DateTime createdAt;

  /// Rasm muallifi/litsenziyasi kredit qatori (masalan CC BY-SA ostida
  /// olingan Wikimedia Commons suratlari uchun shart) — berilsa,
  /// tafsilotlar oynasida kichik matn sifatida ko'rsatiladi.
  final String? attribution;

  PromoBanner({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.linkUrl,
    required this.order,
    required this.createdAt,
    this.attribution,
  });

  factory PromoBanner.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return PromoBanner(
      id: id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      linkUrl: data['linkUrl'] as String?,
      order: (data['order'] ?? 0) as int,
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      attribution: data['attribution'] as String?,
    );
  }
}

class PromoBannerRepository {
  final FirebaseFirestore _firestore;

  PromoBannerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<PromoBanner>> watchActiveBanners() {
    return _firestore
        .collection('promoBanners')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PromoBanner.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Faqat super admin chaqirishi kerak — Firestore Rules ham shuni
  /// mustahkamlaydi.
  Future<void> createBanner({
    required String imageUrl,
    required String title,
    required String description,
    String? linkUrl,
    required int order,
    String? attribution,
  }) async {
    await _firestore.collection('promoBanners').add({
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      if (linkUrl != null && linkUrl.isNotEmpty) 'linkUrl': linkUrl,
      if (attribution != null && attribution.isNotEmpty)
        'attribution': attribution,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteBanner(String id) async {
    await _firestore.collection('promoBanners').doc(id).delete();
  }
}

final promoBannerRepositoryProvider = Provider<PromoBannerRepository>((ref) {
  return PromoBannerRepository();
});

final activeBannersProvider =
    StreamProvider.autoDispose<List<PromoBanner>>((ref) {
  return ref.watch(promoBannerRepositoryProvider).watchActiveBanners();
});
