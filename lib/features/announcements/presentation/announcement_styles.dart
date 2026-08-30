import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/announcement_repository.dart';

/// E'lon kategoriyasi uchun vizual rang — bir necha ekranda (ro'yxat
/// kartochkasi, yangi e'lon yaratish formasi) qayta ishlatiladi.
extension AnnouncementCategoryStyle on AnnouncementCategory {
  Color get color {
    switch (this) {
      case AnnouncementCategory.kommunal:
        return AppAccents.announcements;
      case AnnouncementCategory.xavfsizlik:
        return AppColors.danger;
      case AnnouncementCategory.umumiy:
        return AppAccents.requests;
    }
  }
}
