import 'dart:io';

import 'package:http/http.dart' as http;

/// Rasm/video yuklashda yuz beradigan, foydalanuvchiga ko'rsatsa
/// bo'ladigan xatolik.
class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);
}

/// Yuklanadigan fayl turi — video uchun boshqacha extension/MIME
/// tanlanadi.
enum MediaType { image, video }

class MediaFile {
  final File file;
  final MediaType type;
  MediaFile({required this.file, required this.type});
}

/// E'lonlar, tadbirlar va murojaatlar uchun rasm/videolarni
/// Supabase Storage'ga yuklaydigan umumiy xizmat.
///
/// Firebase Storage o'rniga Supabase ishlatiladi, chunki Firebase
/// Storage O'zbekistonda (va boshqa ba'zi mamlakatlarda) Spark
/// (bepul) rejada ishlamaydi — Blaze (pullik) rejaga o'tishni talab
/// qiladi. Supabase'ning bepul rejasi cheklovsiz ishlaydi.
class ImageUploadService {
  // TODO: Bular hozircha kodda qattiq yozilgan (hardcoded). Agar
  // kelajakda boshqa Supabase loyihasiga o'tish kerak bo'lsa, shu
  // ikki qiymatni yangilash kifoya.
  static const String _supabaseUrl =
      'https://dsbnguwyokxcxfcbeaym.supabase.co';
  static const String _supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzYm5ndXd5b2t4Y3hmY2JlYXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODYzNDk3ODksImV4cCI6MjEwMTkyNTc4OX0.H56khBA8cHnvEQ5nJvOjqdRc4kHHN4y4K9cCuXFSzhk';
  static const String _bucketName = 'mahallam-media';

  /// Bitta faylni (rasm yoki video) yuklaydi va uning ochiq
  /// (public) URL'ini qaytaradi. [storagePath] masalan:
  /// "requests/yettiguzar/abc123_0.jpg"
  Future<String> uploadFile({
    required File file,
    required String storagePath,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final contentType = _guessContentType(file.path);

      final uploadUri = Uri.parse(
        '$_supabaseUrl/storage/v1/object/$_bucketName/$storagePath',
      );

      final headers = {
        'Authorization': 'Bearer $_supabaseAnonKey',
        'apikey': _supabaseAnonKey,
        'Content-Type': contentType,
        'x-upsert': 'true',
      };

      var response = await http.post(uploadUri, headers: headers, body: bytes);

      // MAVJUD FAYL USTIGA YOZISH.
      //
      // Supabase'da POST — "yangi obyekt yaratish". Shu manzilda fayl
      // allaqachon bo'lsa, `x-upsert` sarlavhasiga qaramay 400/409
      // qaytarishi mumkin. Ilgari bu xato "Fayl formati
      // qo'llab-quvvatlanmaydi" deb ko'rsatilardi va foydalanuvchi
      // rasm formatida muammo bor deb o'ylardi — aslida sabab
      // butunlay boshqa edi.
      //
      // Ustiga yozish uchun to'g'ri usul — PUT. Shuning uchun
      // takroriy fayl belgisi ko'rinsa PUT bilan qayta urinamiz.
      final looksDuplicate = response.statusCode == 409 ||
          (response.statusCode == 400 &&
              response.body.toLowerCase().contains('exist'));
      if (looksDuplicate) {
        response = await http.put(uploadUri, headers: headers, body: bytes);
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ImageUploadException(
          _mapStatusCodeToMessage(response.statusCode, response.body),
        );
      }

      // Public bucket bo'lgani uchun ochiq URL shu shablon bo'yicha
      // to'g'ridan-to'g'ri hosil qilinadi (alohida so'rov shart emas).
      return '$_supabaseUrl/storage/v1/object/public/$_bucketName/$storagePath';
    } on ImageUploadException {
      rethrow;
    } catch (_) {
      throw ImageUploadException(
        "Fayl yuklanmadi. Internet aloqangizni tekshiring",
      );
    }
  }

  /// Bitta rasmni yuklaydi (eski chaqiruvlar bilan moslik uchun).
  Future<String> uploadImage({
    required File file,
    required String storagePath,
  }) {
    return uploadFile(file: file, storagePath: storagePath);
  }

  /// Bir nechta rasm/videoni ketma-ket yuklaydi va havolalar
  /// ro'yxatini qaytaradi.
  Future<List<String>> uploadImages({
    required List<File> files,
    required String storagePathPrefix,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final extension = files[i].path.split('.').last;
      final url = await uploadFile(
        file: files[i],
        storagePath:
            '$storagePathPrefix/${DateTime.now().millisecondsSinceEpoch}_$i.$extension',
      );
      urls.add(url);
    }
    return urls;
  }

  /// Bir nechta aralash media (rasm+video) faylni ketma-ket
  /// yuklaydi.
  Future<List<String>> uploadMediaFiles({
    required List<MediaFile> files,
    required String storagePathPrefix,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final extension = files[i].file.path.split('.').last;
      final url = await uploadFile(
        file: files[i].file,
        storagePath:
            '$storagePathPrefix/${DateTime.now().millisecondsSinceEpoch}_$i.$extension',
      );
      urls.add(url);
    }
    return urls;
  }

  String _guessContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case '3gp':
        return 'video/3gpp';
      default:
        return 'application/octet-stream';
    }
  }

  String _mapStatusCodeToMessage(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        // 400 faqat "noto'g'ri format" degani EMAS — Supabase uni
        // takroriy fayl, noto'g'ri yo'l va boshqa sabablarga ham
        // qaytaradi. Ilgari hammasi "format qo'llab-quvvatlanmaydi"
        // deb ko'rsatilardi va bu foydalanuvchini butunlay noto'g'ri
        // tomonga yo'naltirardi.
        if (body.toLowerCase().contains('mime') ||
            body.toLowerCase().contains('content type')) {
          return "Bu fayl turi qo'llab-quvvatlanmaydi. JPG yoki PNG tanlang";
        }
        return "Fayl yuklanmadi. Boshqa rasm bilan urinib ko'ring";
      case 401:
      case 403:
        return "Yuklashga ruxsat yo'q. Administratorga murojaat qiling "
            "(Supabase Storage qoidalarini tekshiring)";
      case 413:
        return "Fayl hajmi juda katta";
      default:
        return "Fayl yuklashda xatolik ($statusCode)";
    }
  }
}