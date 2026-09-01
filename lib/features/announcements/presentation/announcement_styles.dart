import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/announcement_repository.dart';

/// E'lon kategoriyasining ko'rsatiladigan nomi — ro'yxat kartochkasi va
/// tafsilot ekrani bir xil funksiyadan foydalanadi.
String categoryLabel(AppLocalizations l10n, AnnouncementCategory category) {
  switch (category) {
    case AnnouncementCategory.kommunal:
      return l10n.categoryKommunal;
    case AnnouncementCategory.xavfsizlik:
      return l10n.categoryXavfsizlik;
    case AnnouncementCategory.umumiy:
      return l10n.categoryUmumiy;
  }
}

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
