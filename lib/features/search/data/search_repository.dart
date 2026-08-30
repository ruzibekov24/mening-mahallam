import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../announcements/data/announcements_providers.dart';
import '../../home/data/home_repository.dart';
import '../../requests/data/requests_repository.dart';

/// Qidiruv natijasi turi — natijalarni bosilganda qaysi ekranga
/// o'tishni aniqlash uchun.
enum SearchResultKind { announcement, event, request }

class SearchResult {
  final SearchResultKind kind;
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;

  SearchResult({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

/// Firestore'da to'liq matnli qidiruv yo'q (Algolia kabi tashqi
/// xizmat kerak bo'lardi) — mahalla hajmi kichik bo'lgani uchun
/// client darajasida filtrlaymiz: barcha e'lon/tadbir/murojaatlarni
/// stream orqali olib, so'rov matniga mos kelganlarini ajratamiz.
String _normalize(String text) => text.toLowerCase().trim();

bool _matches(String query, List<String> fields) {
  final q = _normalize(query);
  if (q.isEmpty) return false;
  return fields.any((f) => _normalize(f).contains(q));
}

/// Berilgan mahalla va qidiruv so'zi bo'yicha barcha turdagi
/// natijalarni birlashtirib qaytaradi. [canSeeAllRequests] false
/// bo'lsa, faqat [myUid] ga tegishli murojaatlar ko'rsatiladi.
final searchResultsProvider = StreamProvider.autoDispose
    .family<List<SearchResult>, ({String mahallaId, String query})>(
        (ref, params) {
  final query = params.query.trim();
  if (query.isEmpty) return Stream.value([]);

  final announcementsStream =
      ref.watch(announcementRepositoryProvider).watchAnnouncements(params.mahallaId);
  final eventsStream =
      ref.watch(eventRepositoryProvider).watchEvents(params.mahallaId);
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.valueOrNull;
  final canSeeAllRequests = profile?.role.canManageRequests == true;
  final myUid = FirebaseAuth.instance.currentUser?.uid;

  // MUHIM: oddiy fuqaro uchun `watchRequests` (filtrisiz "list"
  // so'rovi) Firestore Rules tomonidan butunlay rad etiladi — sababi
  // `requests_repository.dart`dagi `watchVisibleRequests` izohida.
  // Xodim/rais uchun cheklovsiz, oddiy fuqaro uchun faqat ko'rishga
  // ruxsat etilgan oqim tanlanadi.
  final requestsRepo = ref.watch(requestsRepositoryProvider);
  final requestsStream = canSeeAllRequests
      ? requestsRepo.watchRequests(params.mahallaId)
      : (myUid == null
          ? Stream<List<MahallaRequest>>.value(const [])
          : requestsRepo.watchVisibleRequests(params.mahallaId, myUid));

  return announcementsStream.asyncExpand((announcements) {
    return eventsStream.asyncExpand((events) {
      return requestsStream.map((requests) {
        final results = <SearchResult>[];

        for (final a in announcements) {
          // `body` — Quill Delta JSON. Qidirishda ham, ko'rsatishda
          // ham TEKIS matn ishlatiladi: aks holda natijada
          // `[{"insert":"..."}]` ko'rinardi va JSON ichidagi
          // `insert` kabi kalit so'zlar qidiruvga tushib qolardi.
          final aPreview = a.plainTextPreview;
          if (_matches(query, [a.title, aPreview])) {
            results.add(SearchResult(
              kind: SearchResultKind.announcement,
              id: a.id,
              title: a.title,
              subtitle: aPreview,
              date: a.createdAt,
            ));
          }
        }

        for (final e in events) {
          if (_matches(query, [e.title, e.location])) {
            results.add(SearchResult(
              kind: SearchResultKind.event,
              id: e.id,
              title: e.title,
              subtitle: e.location,
              date: e.dateTime,
            ));
          }
        }

        for (final r in requests) {
          final visible = canSeeAllRequests || r.authorUid == myUid;
          if (!visible) continue;
          final rPreview = r.plainTextDescription;
          if (_matches(query, [r.title, rPreview])) {
            results.add(SearchResult(
              kind: SearchResultKind.request,
              id: r.id,
              title: r.title,
              subtitle: rPreview,
              date: r.createdAt,
            ));
          }
        }

        results.sort((a, b) => b.date.compareTo(a.date));
        return results;
      });
    });
  });
});
