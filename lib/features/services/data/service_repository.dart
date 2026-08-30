import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/material.dart';

/// Mahalliy xizmat toifasi — rais/xodim tomonidan tasdiqlangan
/// xizmat ko'rsatuvchilar (aholi ularga to'g'ridan-to'g'ri qo'ng'iroq
/// qiladi).
enum ServiceCategory { santexnik, elektrik, duradgor, tozalash, qurilish, boshqa }

extension ServiceCategoryX on ServiceCategory {
  String get firestoreValue {
    switch (this) {
      case ServiceCategory.santexnik:
        return 'santexnik';
      case ServiceCategory.elektrik:
        return 'elektrik';
      case ServiceCategory.duradgor:
        return 'duradgor';
      case ServiceCategory.tozalash:
        return 'tozalash';
      case ServiceCategory.qurilish:
        return 'qurilish';
      case ServiceCategory.boshqa:
        return 'boshqa';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.santexnik:
        return PhosphorIconsFill.wrench;
      case ServiceCategory.elektrik:
        return PhosphorIconsFill.lightning;
      case ServiceCategory.duradgor:
        return PhosphorIconsFill.hammer;
      case ServiceCategory.tozalash:
        return PhosphorIconsFill.broom;
      case ServiceCategory.qurilish:
        return PhosphorIconsFill.hardHat;
      case ServiceCategory.boshqa:
        return PhosphorIconsFill.toolbox;
    }
  }

  static ServiceCategory fromString(String value) {
    switch (value) {
      case 'elektrik':
        return ServiceCategory.elektrik;
      case 'duradgor':
        return ServiceCategory.duradgor;
      case 'tozalash':
        return ServiceCategory.tozalash;
      case 'qurilish':
        return ServiceCategory.qurilish;
      case 'boshqa':
        return ServiceCategory.boshqa;
      default:
        return ServiceCategory.santexnik;
    }
  }
}

class LocalService {
  final String id;
  final String name;
  final ServiceCategory category;
  final String phone;
  final String description;
  final String authorUid;
  final DateTime createdAt;

  LocalService({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.description,
    required this.authorUid,
    required this.createdAt,
  });

  factory LocalService.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return LocalService(
      id: id,
      name: data['name'] ?? '',
      category: ServiceCategoryX.fromString(data['category'] ?? 'santexnik'),
      phone: data['phone'] ?? '',
      description: data['description'] ?? '',
      authorUid: data['authorUid'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

class ServiceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ServiceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<LocalService>> watchServices(String mahallaId) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocalService.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi xizmat ko'rsatuvchi qo'shadi — faqat xodim/rais chaqirishi
  /// kerak (UI darajasida tekshiriladi, Firestore Rules bilan
  /// mustahkamlangan).
  Future<void> createService({
    required String mahallaId,
    required String name,
    required ServiceCategory category,
    required String phone,
    required String description,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .add({
      'name': name,
      'category': category.firestoreValue,
      'phone': phone,
      'description': description,
      'authorUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateService({
    required String mahallaId,
    required String serviceId,
    required String name,
    required ServiceCategory category,
    required String phone,
    required String description,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .doc(serviceId)
        .update({
      'name': name,
      'category': category.firestoreValue,
      'phone': phone,
      'description': description,
    });
  }

  Future<void> deleteService({
    required String mahallaId,
    required String serviceId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .doc(serviceId)
        .delete();
  }
}
