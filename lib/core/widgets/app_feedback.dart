import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Bo'sh va xato holatlari uchun chizilgan illyustratsiya.
///
/// Auditdan oldin bu holatlar "rangli doira + ikonka + matn" edi —
/// texnik jihatdan to'g'ri, lekin quruq va "shablon" ko'rinardi.
/// Bu widget o'sha ikonka atrofida yumshoq halqalar, sochilgan
/// nuqtalar va yengil kirish animatsiyasi bilan sahnа yaratadi.
///
/// Rasm fayli ishlatilmaydi — hammasi `CustomPainter` bilan chiziladi,
/// shuning uchun har qanday ekran zichligida aniq qoladi, ilova
/// hajmiga ta'sir qilmaydi va tema rangiga avtomatik moslashadi.
class _StateIllustration extends StatefulWidget {
  final IconData icon;
  final Color accent;

  /// Berilsa, gradient doira+ikonka o'rniga shu rasm (masalan
  /// `assets/images/empty_states/search.png`) markazda ko'rsatiladi —
  /// atrofdagi halqa/nuqta animatsiyasi saqlanadi, faqat markaziy
  /// element almashadi.
  final String? imageAsset;

  const _StateIllustration({
    required this.icon,
    required this.accent,
    this.imageAsset,
  });

  @override
  State<_StateIllustration> createState() => _StateIllustrationState();
}

class _StateIllustrationState extends State<_StateIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Halqalar va nuqtalar markazdan tashqariga "ochiladi",
        // ikonka esa biroz kechroq paydo bo'ladi — bu sahnaga
        // chuqurlik hissini beradi.
        final ringsT = Curves.easeOutCubic.transform(
          (_controller.value / 0.7).clamp(0.0, 1.0),
        );
        final iconT = Curves.easeOutBack.transform(
          ((_controller.value - 0.25) / 0.75).clamp(0.0, 1.0),
        );

        return SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(
            painter: _IllustrationPainter(
              accent: widget.accent,
              isDark: isDark,
              progress: ringsT,
            ),
            child: Center(
              child: Transform.scale(
                scale: 0.6 + 0.4 * iconT,
                child: Opacity(
                  opacity: iconT.clamp(0.0, 1.0),
                  child: widget.imageAsset != null
                      ? Image.asset(
                          widget.imageAsset!,
                          width: 92,
                          height: 92,
                          fit: BoxFit.contain,
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                widget.accent,
                                Color.lerp(
                                    widget.accent, Colors.white, 0.35)!,
                              ],
                            ),
                            boxShadow: AppShadows.accent(widget.accent, isDark),
                          ),
                          child:
                              Icon(widget.icon, size: 28, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final Color accent;
  final bool isDark;
  final double progress;

  _IllustrationPainter({
    required this.accent,
    required this.isDark,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Ikki qatlamli yumshoq halqa — ikonka "havoda turgandek"
    // ko'rinishi uchun.
    for (var i = 2; i >= 1; i--) {
      final radius = (32.0 + i * 17) * progress;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = accent.withValues(
            alpha: (isDark ? 0.10 : 0.07) / i * progress,
          ),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(
            alpha: (isDark ? 0.16 : 0.12) / i * progress,
          ),
      );
    }

    // Atrofdagi mayda nuqtalar — sahnani "jonli" qiladi. Burchaklari
    // qat'iy belgilangan, ya'ni har safar bir xil chiziladi
    // (tasodifiy emas — titrash bo'lmaydi).
    const dots = [
      (angle: -0.5, distance: 58.0, radius: 4.0),
      (angle: 0.9, distance: 52.0, radius: 2.5),
      (angle: 2.1, distance: 60.0, radius: 3.5),
      (angle: 3.4, distance: 50.0, radius: 2.0),
      (angle: 4.3, distance: 62.0, radius: 3.0),
      (angle: 5.5, distance: 54.0, radius: 2.5),
    ];

    for (final dot in dots) {
      final offset = Offset(
        center.dx + math.cos(dot.angle) * dot.distance * progress,
        center.dy + math.sin(dot.angle) * dot.distance * progress,
      );
      canvas.drawCircle(
        offset,
        dot.radius * progress,
        Paint()
          ..color = accent.withValues(alpha: (isDark ? 0.5 : 0.35) * progress),
      );
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter old) =>
      old.progress != progress ||
      old.accent != accent ||
      old.isDark != isDark;
}

/// Tarmoq/server xatosi bo'lganda ko'rsatiladigan, "Qayta urinish"
/// tugmasi bilan birga keladigan standart widget. Barcha ekranlarda
/// bir xil ko'rinish va xatti-harakat uchun ishlatiladi — alohida
/// har bir joyda Text(error.toString()) yozish o'rniga.
class AppErrorView extends StatelessWidget {
  /// Foydalanuvchiga ko'rsatiladigan asosiy xabar. Berilmasa,
  /// standart "Nimadir xato ketdi" matni ishlatiladi.
  final String? message;

  /// Qo'shimcha tushuntirish (ixtiyoriy) — masalan aniq sabab.
  final String? subtitle;

  /// Texnik xato kodi (masalan `permission-denied`), kichik va xira
  /// matn sifatida pastda ko'rsatiladi — foydalanuvchi buni ekran
  /// suratini olib yuborsa, sababni logga kirmasdan aniqlash mumkin.
  final String? debugCode;

  /// Bosilganda qayta urinish uchun chaqiriladi. Berilmasa,
  /// "Qayta urinish" tugmasi ko'rsatilmaydi.
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    this.message,
    this.subtitle,
    this.debugCode,
    this.onRetry,
  });

  /// Xato matnidan tarmoq bilan bog'liqligini taxmin qiladi va
  /// mos sarlavha/tavsif tanlaydi. Aniq bo'lmasa umumiy xato
  /// ko'rinishiga tushadi.
  factory AppErrorView.fromError(
    Object error, {
    VoidCallback? onRetry,
  }) {
    // Xato kodi darhol foydalanuvchiga ko'rsatilmaydi (matn tushunarsiz
    // bo'lardi), lekin log orqali chiqadi — shu tufayli "Nimadir xato
    // ketdi" chiqqanda, uning haqiqiy sababi (masalan
    // `permission-denied` va `unavailable`/`deadline-exceeded` orasidagi
    // farq — biri qoidalar xatosi, ikkinchisi tarmoq muammosi) logdan
    // ko'rinadi.
    final code = error is FirebaseException ? error.code : null;
    debugPrint(
      'AppErrorView.fromError: ${error.runtimeType}'
      '${code != null ? ' code=$code' : ''} — $error',
    );
    final text = error.toString().toLowerCase();
    final isNetwork = code == 'unavailable' ||
        code == 'deadline-exceeded' ||
        text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('connection');
    return AppErrorView(
      message: isNetwork ? "Internet aloqasi yo'q" : null,
      subtitle:
          isNetwork ? "Tarmoqni tekshirib, qayta urinib ko'ring" : null,
      debugCode: code,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _StateIllustration(
              icon: PhosphorIconsFill.warningCircle,
              accent: AppColors.danger,
              imageAsset: 'assets/images/empty_states/generic.png',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? "Nimadir xato ketdi",
              textAlign: TextAlign.center,
              style: context.cardTitleStyle,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: context.secondaryStyle,
              ),
            ],
            if (debugCode != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Texnik kod: $debugCode',
                textAlign: TextAlign.center,
                style: context.secondaryStyle.copyWith(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: context.secondaryStyle.color?.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(PhosphorIconsFill.arrowClockwise, size: 16),
                label: const Text("Qayta urinish"),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  backgroundColor:
                      AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.smAll,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ro'yxat bo'sh bo'lganda ko'rsatiladigan standart widget —
/// illyustratsiya + sarlavha + ixtiyoriy tavsif va amal tugmasi.
///
/// Auditdan oldin ilovada bo'sh holatning **uchta parallel dizayni**
/// bor edi: bu widget, `announcements_screen`dagi `_EmptyState`,
/// `search_screen`dagi boshqa `_EmptyState` va `home_screen`dagi
/// `_EmptyEventsCard`. Endi hammasi shu yerga birlashtirilgan.
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Illyustratsiya rangi — bo'lim mavzusiga mos ranglash uchun
  /// (masalan tadbirlar uchun to'q sariq). Berilmasa brend ko'ki.
  final Color? accent;

  /// `RefreshIndicator` ichida ishlatilganda `true` bering — shunda
  /// widget ro'yxatga aylanadi va bo'sh holatda ham pastga tortib
  /// yangilash ishlaydi.
  final bool scrollable;

  /// Berilsa, chizilgan ikonka o'rniga shu rasm ko'rsatiladi (masalan
  /// `assets/images/empty_states/search.png`).
  final String? imageAsset;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accent,
    this.scrollable = false,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.primary;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StateIllustration(icon: icon, accent: color, imageAsset: imageAsset),
        const SizedBox(height: AppSpacing.lg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: context.cardTitleStyle,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: context.secondaryStyle,
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    );

    if (!scrollable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxxl,
            vertical: AppSpacing.xxl,
          ),
          child: content,
        ),
      );
    }

    // Bo'sh bo'lsa ham pastga tortib yangilash ishlashi uchun —
    // ekran balandligini to'ldiradigan ro'yxat sifatida quramiz.
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxxl,
                  vertical: AppSpacing.xxl,
                ),
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
