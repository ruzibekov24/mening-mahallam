import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../requests/presentation/request_detail_screen.dart';
import 'boundary_editor_screen.dart';
import 'mahalla_map_view.dart';

/// To'liq ekranli, interaktiv mahalla xaritasi — markerni bosganda
/// tegishli murojaat tafsilotiga o'tadi. Rais uchun chegarani
/// tahrirlash tugmasi ham shu yerda.
class MahallaMapScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const MahallaMapScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<MahallaMapScreen> createState() => _MahallaMapScreenState();
}

class _MahallaMapScreenState extends ConsumerState<MahallaMapScreen> {
  @override
  Widget build(BuildContext context) {
    final mahallaId = widget.mahallaId;
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final canEditBoundary =
        profileAsync.valueOrNull?.role.canManageMembers == true;

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
                  Expanded(
                    child: Text(l10n.mahallaMapTitle, style: context.titleStyle),
                  ),
                  if (canEditBoundary)
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              BoundaryEditorScreen(mahallaId: mahallaId),
                        ),
                      ),
                      icon: const Icon(PhosphorIconsRegular.mapPinLine),
                      tooltip: l10n.editBoundaryAction,
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return MahallaMapView(
                        mahallaId: mahallaId,
                        height: constraints.maxHeight,
                        interactive: true,
                        showMyLocationButton: true,
                        onMarkerTap: (marker) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestDetailScreen(
                                mahallaId: mahallaId,
                                requestId: marker.requestId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _LegendDot(color: AppColors.danger, label: l10n.statusYangi),
                  _LegendDot(
                      color: AppAccents.events, label: l10n.statusJarayonda),
                  _LegendDot(
                      color: AppAccents.requests, label: l10n.statusYakunlandi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: context.secondaryStyle),
      ],
    );
  }
}