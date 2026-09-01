import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mahalla_repository.dart';
import '../../../core/widgets/liquid_glass.dart';

/// 7. QR SKANERLASH ekrani.
/// Mockupga mos: to'liq ekran kamera, markazda skanerlash freymi
/// (to'rtta burchak), pastda holat matni.
class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  /// Kirish tushuntirishi bir marta ko'rsatilgani.
  static const _introSeenKey = 'qr_intro_seen';

  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  String? _errorText;

  /// `null` — hali `SharedPreferences` o'qilmagan; `true` — kamerani
  /// ochishdan oldin tushuntirish ko'rsatiladi.
  ///
  /// Kamera ruxsati birinchi marta so'ralganda foydalanuvchi nima
  /// uchun kerakligini bilmasa, ko'pincha "Rad etish"ni bosadi — va
  /// shundan keyin mahallaga umuman qo'shila olmaydi. Shuning uchun
  /// tizim so'rovidan OLDIN qisqa izoh beriladi.
  bool? _showIntro;

  @override
  void initState() {
    super.initState();
    _loadIntroState();
  }

  Future<void> _loadIntroState() async {
    bool seen = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(_introSeenKey) ?? false;
    } catch (_) {
      // Saqlash ishlamasa ham skanerni to'sib qo'ymaymiz.
      seen = true;
    }
    if (mounted) setState(() => _showIntro = !seen);
  }

  Future<void> _dismissIntro() async {
    setState(() => _showIntro = false);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introSeenKey, true);
    } catch (_) {
      // Ahamiyatsiz — eng yomoni izoh keyingi safar yana chiqadi.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Kamera xatosidan keyin qayta urinish.
  ///
  /// Ilgari bunday tugma umuman yo'q edi: ruxsat bir marta rad
  /// etilsa yoki kamera band bo'lsa, ekran o'lik qolardi va
  /// foydalanuvchi ilovadan butunlay chiqib ketishga majbur bo'lardi.
  Future<void> _retryCamera() async {
    setState(() => _errorText = null);
    try {
      await _controller.stop();
    } catch (_) {
      // Kamera allaqachon to'xtagan bo'lishi mumkin — muhim emas.
    }
    try {
      await _controller.start();
    } catch (_) {
      // Xato bo'lsa `errorBuilder` uni o'zi ko'rsatadi.
    }
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    final rawValue = barcode?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorText = null;
    });

    // Qayta skanerlashning oldini olish uchun kamerani to'xtatamiz —
    // natija ekrani ("8. QR natija") qaytishda kerak bo'lsa qayta yoqiladi.
    await _controller.stop();

    try {
      final mahalla =
          await ref.read(mahallaRepositoryProvider).lookupByQrCode(rawValue);
      if (!mounted) return;
      context.go(AppRoutes.qrResult, extra: mahalla);
    } on MahallaNotFoundException catch (e) {
      setState(() => _errorText = e.message);
      await _controller.start();
    } catch (_) {
      setState(() => _errorText =
          AppLocalizations.of(context).qrGenericError);
      await _controller.start();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _goToManualEntry() {
    // Ekranning o'zining (tashqi) context'ini alohida saqlab olamiz —
    // sheet yopilgandan keyin uning ichki context'i "eskiradi"
    // (deactivated) va navigatsiya uchun ishlatib bo'lmaydi.
    final screenContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _ManualCodeSheet(
        onSubmit: (code) async {
          Navigator.of(sheetContext).pop();
          setState(() => _isProcessing = true);
          try {
            final mahalla = await ref
                .read(mahallaRepositoryProvider)
                .lookupByManualCode(code);
            if (!mounted) return;
            screenContext.go(AppRoutes.qrResult, extra: mahalla);
          } on MahallaNotFoundException catch (e) {
            setState(() => _errorText = e.message);
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Tushuntirish ko'rsatilayotgan paytda `MobileScanner`
          // umuman qurilmaydi — shuning uchun tizimning kamera
          // ruxsati so'rovi ham hali chiqmaydi.
          if (_showIntro == false)
            MobileScanner(
              controller: _controller,
              onDetect: _handleDetection,
              // mobile_scanner o'zining standart xato ekranida HAR
              // QANDAY xato uchun inglizcha "An unexpected error
              // occurred" ko'rsatadi — foydalanuvchi ham, biz ham
              // sababni bilmay qolamiz. Shuning uchun o'zimizniki.
              errorBuilder: (context, error, _) => _CameraErrorView(
                error: error,
                onRetry: _retryCamera,
                onManualEntry: _goToManualEntry,
              ),
            ),

          // Qorong'ulashtirilgan overlay + markazdagi skanerlash freymi
          if (_showIntro == false)
            _ScannerOverlay(hasError: _errorText != null),

          if (_showIntro == true)
            _CameraIntroView(onContinue: _dismissIntro),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Row(
                    children: [
                      LiquidGlassBackButton(onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.login);
                          }
                        }, iconColor: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                // Tushuntirish paneli ochiq turganda pastdagi
                // ko'rsatmalarni chizmaymiz — aks holda ikkita matn
                // ustma-ust tushib, ekran chalkash bo'lib qoladi.
                // Orqaga tugmasi esa har doim qoladi.
                if (_showIntro != true) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                  child: Text(
                    AppLocalizations.of(context).qrScanInstruction,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 260),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
                    child: Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.dangerDarkMode,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Text(
                    _isProcessing
                        ? AppLocalizations.of(context).checkingStatus
                        : AppLocalizations.of(context).scanningStatus,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                const SizedBox(height: 24),
                // Qo'lda kiritish — kamera ishlamaganda mahallaga
                // qo'shilishning yagona zaxira yo'li. Ilgari bu oddiy
                // matnli tugma edi va qora fonda deyarli ko'rinmasdi;
                // endi ramkali tugma sifatida ajralib turadi.
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _goToManualEntry,
                  icon: const Icon(PhosphorIconsRegular.keyboard,
                      size: 18, color: Colors.white),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.pillAll,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  ),
                  label: Text(
                    AppLocalizations.of(context).enterCodeManually,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kamera ochilishidan OLDIN ko'rsatiladigan qisqa izoh.
///
/// Bir marta ko'rsatiladi (`SharedPreferences`). Maqsadi — tizimning
/// kamera ruxsati so'rovi chiqqanda foydalanuvchi nima uchun so'ralayotganini
/// bilishi. Bilmasa "Rad etish"ni bosadi va mahallaga qo'shila olmay
/// qoladi.
class _CameraIntroView extends StatelessWidget {
  final VoidCallback onContinue;

  const _CameraIntroView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsFill.camera,
                size: 44, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            l10n.cameraIntroTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.cameraIntroBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.smAll,
                ),
              ),
              child: Text(l10n.cameraIntroButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kamera ochilmaganda ko'rsatiladigan tushunarli xato ekrani.
///
/// `mobile_scanner` o'zining standart xato ko'rinishida har qanday
/// sabab uchun bitta inglizcha jumla chiqaradi ("An unexpected error
/// occurred"). Bu foydalanuvchiga ham, bizga ham hech narsa aytmaydi.
/// Shu yerda xato KODIGA qarab aniq sabab va aniq harakat beriladi.
class _CameraErrorView extends StatelessWidget {
  final MobileScannerException error;
  final Future<void> Function() onRetry;
  final VoidCallback onManualEntry;

  const _CameraErrorView({
    required this.error,
    required this.onRetry,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = l10n.cameraErrorPermission;
        break;
      case MobileScannerErrorCode.unsupported:
        message = l10n.cameraErrorUnsupported;
        break;
      default:
        message = l10n.cameraErrorGeneric;
    }

    // Ruxsat rad etilgan bo'lsa, "Qayta urinish" tugmasi foyda
    // bermaydi — Android ikkinchi marta so'ramaydi. Bunday holatda
    // qo'lda kiritish yagona ishlaydigan yo'l, shuning uchun u
    // asosiy tugma bo'ladi.
    final permissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsFill.videoCameraSlash,
              size: 56, color: Colors.white54),
          const SizedBox(height: AppSpacing.xl),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: permissionDenied ? onManualEntry : () => onRetry(),
              icon: Icon(
                permissionDenied
                    ? PhosphorIconsRegular.keyboard
                    : PhosphorIconsRegular.arrowClockwise,
                size: 18,
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.smAll,
                ),
              ),
              label: Text(permissionDenied
                  ? l10n.enterCodeManually
                  : l10n.retryButton),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: permissionDenied ? () => onRetry() : onManualEntry,
            child: Text(
              permissionDenied ? l10n.retryButton : l10n.enterCodeManually,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

/// Qorong'u fon ustida markazda shaffof kvadrat teshik + burchak chiziqlari.
class _ScannerOverlay extends StatelessWidget {
  final bool hasError;
  const _ScannerOverlay({required this.hasError});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.redAccent : Colors.white70,
              width: 1.5,
            ),
            borderRadius: AppRadius.lgAll,
          ),
          child: CustomPaint(
            painter: _CornerPainter(
              color: hasError ? Colors.redAccent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const length = 28.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    void corner(Offset start, Offset h, Offset v) {
      canvas.drawLine(start, h, paint);
      canvas.drawLine(start, v, paint);
    }

    corner(const Offset(0, 0), const Offset(length, 0), const Offset(0, length));
    corner(Offset(size.width, 0), Offset(size.width - length, 0),
        Offset(size.width, length));
    corner(Offset(0, size.height), Offset(length, size.height),
        Offset(0, size.height - length));
    corner(Offset(size.width, size.height),
        Offset(size.width - length, size.height),
        Offset(size.width, size.height - length));
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// "Kodni qo'lda kiritish" uchun oddiy bottom sheet.
class _ManualCodeSheet extends StatefulWidget {
  final void Function(String code) onSubmit;
  const _ManualCodeSheet({required this.onSubmit});

  @override
  State<_ManualCodeSheet> createState() => _ManualCodeSheetState();
}

class _ManualCodeSheetState extends State<_ManualCodeSheet> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.enterMahallaCodeTitle, style: context.sectionStyle),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.mahallaCodeHint),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () {
              final code = _controller.text.trim();
              if (code.isNotEmpty) widget.onSubmit(code);
            },
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
  }
}