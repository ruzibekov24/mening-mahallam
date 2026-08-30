import '../../../l10n/app_localizations.dart';
import 'requests_repository.dart' show RequestPriority, RequestStatus, RequestType;

String statusLabel(AppLocalizations l10n, RequestStatus status) {
  switch (status) {
    case RequestStatus.yangi:
      return l10n.statusYangi;
    case RequestStatus.jarayonda:
      return l10n.statusJarayonda;
    case RequestStatus.yakunlandi:
      return l10n.statusYakunlandi;
  }
}

String typeLabel(AppLocalizations l10n, RequestType type) {
  switch (type) {
    case RequestType.maxfiy:
      return l10n.typeMaxfiy;
    case RequestType.ommaviy:
      return l10n.typeOmmaviy;
  }
}

String priorityLabel(AppLocalizations l10n, RequestPriority priority) {
  switch (priority) {
    case RequestPriority.past:
      return l10n.priorityPast;
    case RequestPriority.ortacha:
      return l10n.priorityOrtacha;
    case RequestPriority.yuqori:
      return l10n.priorityYuqori;
  }
}
