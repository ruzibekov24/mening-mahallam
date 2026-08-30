import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shimmer.dart';
import '../../requests/data/requests_repository.dart';
import '../data/map_providers.dart';

/// Mahalla xaritasi — har doim sputnik (aerofoto) tasviri + joy
/// nomlari (Esri "hybrid" ikki qatlami: World_Imagery + Reference/
/// World_Boundaries_and_Places, ikkalasi ham API kalitisiz).
///
/// Avval ko'cha/sputnik almashtirish tugmasi bor edi — foydalanuvchi
/// buni olib tashlashni va doim sputnikda + nomlar bilan turishini
/// so'radi.
class MahallaMapView extends ConsumerStatefulWidget {
  final String mahallaId;
  final double height;
  final bool interactive;

  /// Xaritada murojaat markerlari ko'rsatilsinmi. Home ekranidagi
  /// kichik preview uchun `false` — u yerda faqat mahalla hududi va
  /// markazi ko'rsatiladi, to'liq murojaatlar ro'yxati emas.
  final bool showRequestMarkers;

  /// Joriy foydalanuvchi joylashuvini ko'rsatuvchi tugma (faqat
  /// interaktiv, to'liq ekranli xaritada mantiqiy).
  final bool showMyLocationButton;
  final void Function(RequestMapMarker marker)? onMarkerTap;

  const MahallaMapView({
    super.key,
    required this.mahallaId,
    this.height = 200,
    this.interactive = true,
    this.showRequestMarkers = true,
    this.showMyLocationButton = false,
    this.onMarkerTap,
  });

  @override
  ConsumerState<MahallaMapView> createState() => _MahallaMapViewState();
}

class _MahallaMapViewState extends ConsumerState<MahallaMapView> {
  final _mapController = MapController();
  LatLng? _myPosition;
  bool _locating = false;

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.yangi:
        return AppColors.danger;
      case RequestStatus.jarayonda:
        return AppAccents.events;
      case RequestStatus.yakunlandi:
        return AppAccents.requests;
    }
  }

  Future<void> _locateMe() async {
    setState(() => _locating = true);
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

      // Aniq sozlamalarsiz `getCurrentPosition()` ba'zi qurilmalarda
      // tarmoq/uyali aloqa operatorining ro'yxatdan o'tgan hududiga
      // asoslangan taxminiy (juda noaniq, ba'zan butunlay boshqa
      // shahar) joylashuvni qaytarishi mumkin — GPS chipini majburiy
      // ishlatish uchun aniq yuqori aniqlikni so'raymiz.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _myPosition = point);
      _mapController.move(point, 16);
    } catch (_) {
      // Jim inkor etiladi — bu ixtiyoriy qulaylik, xatolik bo'lsa
      // ham xarita o'zi (mahalla markazi bilan) ishlashda davom etadi.
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final centerAsync = ref.watch(mahallaMapCenterProvider(widget.mahallaId));
    final markersAsync =
        ref.watch(requestMapMarkersProvider(widget.mahallaId));
    final boundaryAsync = ref.watch(mahallaBoundaryProvider(widget.mahallaId));
    final mahallaName =
        ref.watch(mahallaMapNameProvider(widget.mahallaId)).valueOrNull;

    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        height: widget.height,
        child: centerAsync.when(
          data: (center) {
            final markers = widget.showRequestMarkers
                ? (markersAsync.valueOrNull ?? [])
                : const <RequestMapMarker>[];
            final boundary = boundaryAsync.valueOrNull;
            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                    interactionOptions: InteractionOptions(
                      flags: widget.interactive
                          ? InteractiveFlag.all
                          : InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'uz.meningmahallam.app',
                    ),
                    // Joy nomlari qatlami — shaffof fon, faqat
                    // yozuvlar/chegaralar. Shu qatlamsiz sof sputnik
                    // suratida hech qanday nom ko'rinmas edi.
                    TileLayer(
                      urlTemplate:
                          'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                      userAgentPackageName: 'uz.meningmahallam.app',
                    ),
                    // Mahalla chegarasi — ichi deyarli tiniq (oddiy),
                    // chegara chizig'i esa keskin ko'rinishi uchun oq
                    // "halo" + yorqin sariq chiziq (sputnik fonida eng
                    // yaxshi ko'rinadigan kontrast rang).
                    if (boundary != null) ...[
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: boundary,
                            color: Colors.black.withValues(alpha: 0.06),
                            borderColor: Colors.white,
                            borderStrokeWidth: 5,
                          ),
                        ],
                      ),
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: boundary,
                            color: Colors.transparent,
                            borderColor: const Color(0xFFFFD400),
                            borderStrokeWidth: 3,
                          ),
                        ],
                      ),
                    ],
                    MarkerLayer(
                      markers: [
                        // Mahalla markazi.
                        //
                        // Ilgari bu ham KO'K DOIRA edi — ya'ni "mening
                        // joylashuvim" belgisidan (pastda, 0xFF4285F4)
                        // deyarli farq qilmasdi va foydalanuvchi uni
                        // o'zining joylashuvi deb o'ylashi mumkin edi.
                        // Endi bu joy belgisi (pin) + mahalla nomi
                        // yozuvi: chalkashadigan joyi qolmadi va
                        // xaritada qaysi mahalla ekani ko'rinib turadi.
                        Marker(
                          point: center,
                          width: 200,
                          height: 62,
                          alignment: Alignment.topCenter,
                          child: _MahallaCenterMarker(
                            name: mahallaName,
                          ),
                        ),
                        if (_myPosition != null)
                          Marker(
                            point: _myPosition!,
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4285F4),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ...markers.map(
                          (marker) => Marker(
                            point: marker.position,
                            width: 34,
                            height: 34,
                            child: GestureDetector(
                              onTap: widget.onMarkerTap == null
                                  ? null
                                  : () => widget.onMarkerTap!(marker),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _statusColor(marker.status),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  PhosphorIconsBold.exclamationMark,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (widget.showMyLocationButton)
                  Positioned(
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Material(
                      color: context.surfaceColor,
                      shape: const CircleBorder(),
                      elevation: 3,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _locating ? null : _locateMe,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _locating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(PhosphorIconsFill.navigationArrow,
                                  size: 20, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => ShimmerBox(
            height: widget.height,
            width: double.infinity,
            borderRadius: BorderRadius.zero,
          ),
          error: (_, __) => Container(
            color: context.surfaceColor,
            alignment: Alignment.center,
            child: Icon(PhosphorIconsRegular.mapTrifold,
                color: context.textMuted),
          ),
        ),
      ),
    );
  }
}

/// Xaritadagi mahalla markazi belgisi: joy ignasi (pin) + nom yozuvi.
///
/// Sputnik surati ustida o'qilishi kerak, shuning uchun yozuv oq
/// yostiqcha ustida va yengil soya bilan chiziladi — sof matn qorong'u
/// yoki rang-barang fonda yo'qolib ketardi.
class _MahallaCenterMarker extends StatelessWidget {
  final String? name;

  const _MahallaCenterMarker({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Igna: oq halqa ichida to'q qizil-sariq joy belgisi. "Mening
        // joylashuvim" ko'k doirasi bilan aralashib ketmasligi uchun
        // rang ham, shakl ham ataylab boshqacha.
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFFD64545),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(PhosphorIconsFill.houseLine,
              size: 13, color: Colors.white),
        ),
        if (name != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Text(
              name!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1C1E),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
