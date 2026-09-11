import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../l10n/app_localizations.dart';

/// Umumiy joylashuv tanlash ekrani — xaritani bosib nuqta qo'yish yoki
/// "Joriy joylashuv" tugmasi orqali GPS'dan olish, so'ng tasdiqlash.
///
/// `requests` moduli ichida xuddi shu vazifani bajaradigan
/// `_LocationStep` bor, lekin u o'sha faylga xos (private) va
/// murojaat yaratish oqimining bir bosqichi sifatida qurilgan
/// (l10n, wizard state va h.k.ga bog'liq). Bu yerda uni qayta
/// ishlatib bo'lmagani uchun `map` modulida mustaqil, umumiy
/// versiyasi qurildi — kelajakda boshqa ekranlar ham (masalan shu
/// xizmat ko'rsatuvchi joylashuvi) ishlatishi mumkin.
///
/// Natija sifatida tanlangan `LatLng` (yoki joylashuv tozalansa
/// `null`) `Navigator.pop` orqali qaytariladi.
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selected;
  bool _isLocating = false;

  static const _fallbackCenter = LatLng(41.311081, 69.240562);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialLocation;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('service disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selected = point);
      _mapController.move(point, 16);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(
        context,
        AppLocalizations.of(context).locationDetectError,
        kind: AppAlertKind.error,
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selected ?? _fallbackCenter,
              initialZoom: 15,
              onTap: (tapPosition, point) =>
                  setState(() => _selected = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'uz.meningmahallam.app',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        PhosphorIconsFill.mapPin,
                        color: AppColors.danger,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  LiquidGlassBackButton(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  LiquidPillButton(
                    label: l10n.confirmButton,
                    icon: PhosphorIconsFill.check,
                    onTap: () => Navigator.of(context).pop(_selected),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md + 60,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurface : Colors.white)
                    .withValues(alpha: 0.95),
                borderRadius: AppRadius.smAll,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                l10n.tapMapHint,
                textAlign: TextAlign.center,
                style: context.captionStyle,
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: FloatingActionButton.small(
              heroTag: 'location_picker_current',
              onPressed: _isLocating ? null : _useCurrentLocation,
              backgroundColor: AppColors.primary,
              child: _isLocating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(PhosphorIconsFill.crosshair,
                      color: Colors.white, size: 20),
            ),
          ),
          if (_selected != null)
            Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Material(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: AppRadius.xsAll,
                child: InkWell(
                  borderRadius: AppRadius.xsAll,
                  onTap: () => setState(() => _selected = null),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsBold.x,
                            size: 14, color: AppColors.danger),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          l10n.clearLocationAction,
                          style: context.captionStyle.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
