import '../../../l10n/app_localizations.dart';
import 'requests_repository.dart' show RequestStatus, RequestType;

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
