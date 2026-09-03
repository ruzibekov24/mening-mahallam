import '../../announcements/data/announcement_repository.dart';
import '../../announcements/data/event_repository.dart';
import 'feed_repository.dart';

/// Lentada ko'rsatiladigan bitta narsa — yangi foydalanuvchi posti,
/// rasmiy e'lon yoki tadbir bo'lishi mumkin. `announcements`/`events`
/// kolleksiyalari o'zgarishsiz qoladi (staff-only yozish huquqi,
/// mavjud push/deep-link oqimi buzilmasligi uchun) — bu faqat
/// [FeedScreen] uchun UI darajasidagi birlashtirilgan ko'rinish.
sealed class FeedItem {
  DateTime get createdAt;

  const FeedItem();

  factory FeedItem.post(Post post) = _PostFeedItem;
  factory FeedItem.announcement(Announcement announcement) =
      _AnnouncementFeedItem;
  factory FeedItem.event(MahallaEvent event) = _EventFeedItem;
}

class _PostFeedItem extends FeedItem {
  final Post post;
  const _PostFeedItem(this.post);
  @override
  DateTime get createdAt => post.createdAt;
}

class _AnnouncementFeedItem extends FeedItem {
  final Announcement announcement;
  const _AnnouncementFeedItem(this.announcement);
  @override
  DateTime get createdAt => announcement.createdAt;
}

class _EventFeedItem extends FeedItem {
  final MahallaEvent event;
  const _EventFeedItem(this.event);
  @override
  DateTime get createdAt => event.dateTime;
}

extension FeedItemMatch on FeedItem {
  T map<T>({
    required T Function(Post post) post,
    required T Function(Announcement announcement) announcement,
    required T Function(MahallaEvent event) event,
  }) {
    final self = this;
    if (self is _PostFeedItem) return post(self.post);
    if (self is _AnnouncementFeedItem) return announcement(self.announcement);
    if (self is _EventFeedItem) return event(self.event);
    throw StateError('Unknown FeedItem variant');
  }
}
