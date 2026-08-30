import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../qr/data/mahalla_repository.dart';
import '../data/map_providers.dart';
import '../../../core/widgets/app_alert.dart';

/// Rais uchun — mahalla chegarasini xaritada nuqta-baqadam bosib
/// belgilash ekrani. Kamida 3 ta nuqta qo'yilgach saqlash mumkin.
class BoundaryEditorScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const BoundaryEditorScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<BoundaryEditorScreen> createState() =>
      _BoundaryEditorScreenState();
}

class _BoundaryEditorScreenState extends ConsumerState<BoundaryEditorScreen> {
  final List<LatLng> _points = [];
  bool _isSaving = false;
  bool _isLoaded = false;

  /// `true` bo'lsa xaritaga bosish chegara nuqtasi emas, MAHALLA
  /// MARKAZINI belgilaydi.
  ///
  /// Markaz belgilanmagan mahallada xarita joylashuvi bor birinchi
  /// murojaatga, u ham bo'lmasa umumiy standart nuqtaga tushib
  /// qoladi — ya'ni butunlay boshqa joy ko'rsatiladi. Ilgari uni
  /// ilova ichida o'zgartirishning HECH QANDAY yo'li yo'q edi.
  bool _centerMode = false;
  LatLng? _center;

  void _onMapTap(LatLng point) {
    if (_centerMode) {
      setState(() => _center = point);
      return;
    }
    setState(() => _points.add(point));
  }

  /// Koordinatani qo'lda kiritish — masalan Google Maps'dan
  /// nusxalangan "40.203328, 68.840926" ko'rinishidagi matn.
  Future<void> _enterCoordinates() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _center == null
          ? ''
          : '${_center!.latitude}, ${_center!.longitude}',
    );

    final result = await showDialog<LatLng>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.mahallaCenterTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mahallaCenterCoordsHint,
                style: context.secondaryStyle),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '40.203328, 68.840926',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () {
              // Vergul ham, bo'sh joy ham ajratgich bo'lishi mumkin.
              final parts = controller.text
                  .split(RegExp(r'[,\s]+'))
                  .where((p) => p.isNotEmpty)
                  .toList();
              if (parts.length != 2) return;
              final lat = double.tryParse(parts[0]);
              final lng = double.tryParse(parts[1]);
              if (lat == null || lng == null) return;
              if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
              Navigator.of(dialogContext).pop(LatLng(lat, lng));
            },
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _center = result;
        _centerMode = true;
      });
    }
  }

  Future<void> _saveCenter() async {
    final l10n = AppLocalizations.of(context)!;
    final center = _center;
    if (center == null) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(mahallaRepositoryProvider).saveCenter(
            widget.mahallaId,
            center.latitude,
            center.longitude,
          );
      if (!mounted) return;
      ref.invalidate(mahallaMapCenterProvider(widget.mahallaId));
      showAppAlert(context, l10n.mahallaCenterSaved);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _undo() {
    if (_points.isEmpty) return;
    setState(() => _points.removeLast());
  }

  void _clear() {
    setState(() => _points.clear());
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_points.length < 3) {
      showAppAlert(context, l10n.boundaryMinPointsError, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(mahallaRepositoryProvider).saveBoundary(
            widget.mahallaId,
            _points.map((p) => [p.latitude, p.longitude]).toList(),
          );
      if (!mounted) return;
      ref.invalidate(mahallaBoundaryProvider(widget.mahallaId));
      Navigator.of(context).pop();
      showAppAlert(context, l10n.boundarySavedMessage);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final centerAsync = ref.watch(mahallaMapCenterProvider(widget.mahallaId));

    // Mavjud chegara bo'lsa, birinchi ochilishda tahrirlash uchun
    // oldindan yuklaymiz.
    if (!_isLoaded) {
      final existingBoundary =
          ref.watch(mahallaBoundaryProvider(widget.mahallaId)).valueOrNull;
      if (existingBoundary != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _points.isEmpty) {
            setState(() {
              _points.addAll(existingBoundary);
              _isLoaded = true;
            });
          }
        });
      } else {
        _isLoaded = true;
      }
    }

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
                    child: Text(l10n.boundaryEditorTitle,
                        style: context.titleStyle),
                  ),
                  // Markazni koordinata bilan kiritish — Google
                  // Maps'dan nusxalab qo'yish eng aniq yo'l.
                  IconButton(
                    tooltip: l10n.mahallaCenterTitle,
                    onPressed: _enterCoordinates,
                    icon: const Icon(PhosphorIconsRegular.crosshair),
                  ),
                  IconButton(
                    onPressed: _points.isEmpty ? null : _undo,
                    icon: const Icon(PhosphorIconsRegular.arrowUUpLeft),
                  ),
                  IconButton(
                    onPressed: _points.isEmpty ? null : _clear,
                    icon: const Icon(PhosphorIconsRegular.trash),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _centerMode
                    ? l10n.mahallaCenterHint
                    : l10n.boundaryEditorHint,
                style: context.secondaryStyle,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Rejim almashtirgich: xaritaga bosish chegara nuqtasi
            // qo'yadimi yoki markazni belgilaydimi.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.boundaryModeLabel),
                    icon: const Icon(PhosphorIconsRegular.polygon, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.centerModeLabel),
                    icon: const Icon(PhosphorIconsRegular.crosshair, size: 16),
                  ),
                ],
                selected: {_centerMode},
                onSelectionChanged: (v) =>
                    setState(() => _centerMode = v.first),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: centerAsync.when(
                    data: (center) => FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15,
                        onTap: (tapPosition, point) => _onMapTap(point),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'uz.meningmahallam.app',
                        ),
                        if (_points.length >= 3)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: _points,
                                color:
                                    AppColors.primary.withValues(alpha: 0.15),
                                borderColor: AppColors.primary,
                                borderStrokeWidth: 2.5,
                              ),
                            ],
                          ),
                        if (_points.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: _points,
                                color: AppColors.primary,
                                strokeWidth: 2.5,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: _points
                              .asMap()
                              .entries
                              .map(
                                (entry) => Marker(
                                  point: entry.value,
                                  width: 22,
                                  height: 22,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        // Tanlangan markaz — qizil nishon. Chegara
                        // nuqtalari ko'k, shuning uchun aralashmaydi.
                        if (_center != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _center!,
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD64545),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                      PhosphorIconsFill.crosshair,
                                      size: 14,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Icon(PhosphorIconsRegular.mapTrifold,
                          color: context.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  // Tugma qaysi rejimda ekaniga qarab chegarani yoki
                  // markazni saqlaydi — ikkita alohida tugma qo'yilsa
                  // ekran pastki qismi band bo'lib ketardi.
                  onPressed: _isSaving
                      ? null
                      : (_centerMode
                          ? (_center == null ? null : _saveCenter)
                          : _save),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(_centerMode
                          ? l10n.saveCenterAction
                          : l10n.saveBoundaryAction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}