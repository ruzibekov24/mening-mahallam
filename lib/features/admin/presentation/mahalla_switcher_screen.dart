import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../qr/data/mahalla_repository.dart';

/// Faqat super admin uchun — istalgan mahallani "boshqarish rejimi"ga
/// o'tish ekrani. Tanlangan mahalla `activeMahallaOverrideProvider`ga
/// yoziladi, shu bilan butun ilova (E'lonlar, Murojaatlar, Qo'shnilar
/// va h.k.) o'sha mahallani ko'rsata boshlaydi — qayta tizimga kirish
/// shart emas.
class MahallaSwitcherScreen extends ConsumerStatefulWidget {
  const MahallaSwitcherScreen({super.key});

  @override
  ConsumerState<MahallaSwitcherScreen> createState() =>
      _MahallaSwitcherScreenState();
}

class _MahallaSwitcherScreenState
    extends ConsumerState<MahallaSwitcherScreen> {
  late Future<List<MahallaInfo>> _mahallasFuture;

  @override
  void initState() {
    super.initState();
    _mahallasFuture =
        ref.read(mahallaRepositoryProvider).fetchAllMahallas();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeOverride = ref.watch(activeMahallaOverrideProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.switchMahallaTitle, style: context.titleStyle),
                ],
              ),
            ),
            if (activeOverride != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                child: AppCard(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  onTap: () {
                    ref.read(activeMahallaOverrideProvider.notifier).state =
                        null;
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsFill.arrowUUpLeft,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(l10n.exitMahallaModeAction,
                            style: context.bodyStyle
                                .copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: FutureBuilder<List<MahallaInfo>>(
                future: _mahallasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return AppErrorView.fromError(
                      snapshot.error!,
                      onRetry: () => setState(() {
                        _mahallasFuture = ref
                            .read(mahallaRepositoryProvider)
                            .fetchAllMahallas();
                      }),
                    );
                  }
                  final mahallas = snapshot.data ?? [];
                  if (mahallas.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.buildings,
                      title: l10n.noMahallasFound,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: mahallas.length,
                    itemBuilder: (context, index) {
                      final mahalla = mahallas[index];
                      final isActive = mahalla.id == activeOverride;
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        borderColor: isActive ? AppColors.primary : null,
                        onTap: () {
                          ref
                              .read(activeMahallaOverrideProvider.notifier)
                              .state = mahalla.id;
                          Navigator.of(context).pop();
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: const Icon(PhosphorIconsFill.buildings,
                                  size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(mahalla.name,
                                      style: context.cardTitleStyle),
                                  if (mahalla.district.isNotEmpty)
                                    Text(mahalla.district,
                                        style: context.secondaryStyle),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(PhosphorIconsFill.checkCircle,
                                  color: AppColors.primary),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
