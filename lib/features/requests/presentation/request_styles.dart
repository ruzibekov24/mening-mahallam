import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/requests_repository.dart';

/// Murojaat holati/muhimligi uchun vizual ranglar — bir necha ekranda
/// (ro'yxat, tafsilotlar, yangi murojaat oqimi) qayta ishlatiladi.
extension RequestStatusStyle on RequestStatus {
  Color badgeBg(bool isDark) {
    switch (this) {
      case RequestStatus.yangi:
        return isDark ? const Color(0xFF4A3B1A) : const Color(0xFFFFF8E1);
      case RequestStatus.jarayonda:
        return isDark ? const Color(0xFF1A3A4A) : const Color(0xFFE3F2FD);
      case RequestStatus.yakunlandi:
        return isDark ? const Color(0xFF1B3A22) : const Color(0xFFE8F5E9);
    }
  }

  Color get badgeText {
    switch (this) {
      case RequestStatus.yangi:
        return const Color(0xFFE65100);
      case RequestStatus.jarayonda:
        return const Color(0xFF1565C0);
      case RequestStatus.yakunlandi:
        return const Color(0xFF2E7D32);
    }
  }
}

extension RequestPriorityStyle on RequestPriority {
  Color get color {
    switch (this) {
      case RequestPriority.past:
        return AppAccents.requests;
      case RequestPriority.ortacha:
        return AppAccents.events;
      case RequestPriority.yuqori:
        return AppColors.danger;
    }
  }
}
