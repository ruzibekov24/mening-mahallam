import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/tutorial_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Bitta qo'llanma bosqichi — nishonlanadigan element (`targetKey`),
/// unga oid qisqa matn, va bosqich qanday davom etishi.
class TutorialStep {
  final GlobalKey targetKey;
  final String title;
  final String description;

  /// Berilsa, bosqich "Keyingi" tugmasi bilan EMAS, balki nishonning
  /// o'ziga bosilganda davom etadi (masalan pastki navigatsiya
  /// tugmalari — haqiqiy bo'limga o'tish bilan bir vaqtda).
  final VoidCallback? onTargetTap;

  /// Faqat oxirgi bosqichda `true` — "Keyingi" o'rniga "Tugatish".
  final bool isLast;

  const TutorialStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.onTargetTap,
    this.isLast = false,
  });
}

/// Qo'llanma (tur) holatini boshqaradi: joriy bosqich, faolmi.
class TutorialController extends ChangeNotifier {
  int? _stepIndex;

  int? get stepIndex => _stepIndex;
  bool get isActive => _stepIndex != null;

  void start() {
    _stepIndex = 0;
    notifyListeners();
  }

  void next(int totalSteps) {
    if (_stepIndex == null) return;
    if (_stepIndex! + 1 >= totalSteps) {
      finish();
      return;
    }
    _stepIndex = _stepIndex! + 1;
    notifyListeners();
  }

  void finish() {
    if (_stepIndex == null) return;
    _stepIndex = null;
    notifyListeners();
    TutorialService.markTourCompleted();
  }
}

final tutorialControllerProvider =
    ChangeNotifierProvider<TutorialController>((ref) => TutorialController());

/// Nishonlangan element atrofida qorong'i parda + "teshik" + strelka +
/// qisqa tushuntirish matni ko'rsatadigan qatlam. `MainShell`ning
/// eng ustki qatlamida, `TutorialController` faol bo'lganda chiziladi.
class TutorialOverlay extends StatefulWidget {
  final TutorialController controller;
  final List<TutorialStep> steps;

  const TutorialOverlay({
    super.key,
    required this.controller,
    required this.steps,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStepChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStepChanged);
    super.dispose();
  }

  /// Bosqich almashganda (masalan tab almashib, yangi ekran chizilgach)
  /// nishon hali render bo'lmagan bo'lishi mumkin — bir necha kadr
  /// kutib, mavjud bo'lgach qayta chizadi.
  void _onStepChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Rect? _targetRect(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    final origin = box.localToGlobal(Offset.zero);
    return origin & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.controller.stepIndex;
    if (index == null || index >= widget.steps.length) {
      return const SizedBox.shrink();
    }
    final step = widget.steps[index];
    final rect = _targetRect(step.targetKey);
    final screenSize = MediaQuery.sizeOf(context);

    if (rect == null) {
      // Nishon hali qurilmagan (masalan tab hozirgina almashdi) —
      // keyingi kadrda qayta urinib ko'riladi (yuqoridagi listener).
      return const SizedBox.shrink();
    }

    final holeRect = rect.inflate(10);
    final holeAbove = holeRect.center.dy > screenSize.height * 0.5;

    return Positioned.fill(
      child: Stack(
        children: [
          // Qorong'ilashtirilgan fon + "teshik".
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightPainter(holeRect: holeRect),
              ),
            ),
          ),
          // Nishonning ustiga shaffof teginish qatlami — agar bosqich
          // "nishonga bosilganda davom etadi" turida bo'lsa.
          if (step.onTargetTap != null)
            Positioned(
              left: holeRect.left,
              top: holeRect.top,
              width: holeRect.width,
              height: holeRect.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  step.onTargetTap!();
                  widget.controller.next(widget.steps.length);
                },
                child: const SizedBox.expand(),
              ),
            ),
          // Nishon atrofida yumshoq porlash — "bu yerga bos" hissi.
          Positioned(
            left: holeRect.left - 6,
            top: holeRect.top - 6,
            width: holeRect.width + 12,
            height: holeRect.height + 12,
            child: IgnorePointer(
              child: _PulsingRing(borderRadius: 20),
            ),
          ),
          // Strelka + tushuntirish kartasi.
          _TutorialCard(
            step: step,
            holeRect: holeRect,
            holeAbove: holeAbove,
            screenSize: screenSize,
            onNext: () {
              if (step.isLast) {
                widget.controller.finish();
              } else {
                widget.controller.next(widget.steps.length);
              }
            },
            onSkip: widget.controller.finish,
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect holeRect;
  const _SpotlightPainter({required this.holeRect});

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(holeRect, const Radius.circular(20)));
    final combined = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(
        combined, Paint()..color = Colors.black.withValues(alpha: 0.78));
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.holeRect != holeRect;
}

class _PulsingRing extends StatefulWidget {
  final double borderRadius;
  const _PulsingRing({required this.borderRadius});

  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35 + 0.4 * t),
              width: 2 + 1.5 * t,
            ),
          ),
        );
      },
    );
  }
}

class _TutorialCard extends StatelessWidget {
  final TutorialStep step;
  final Rect holeRect;
  final bool holeAbove;
  final Size screenSize;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TutorialCard({
    required this.step,
    required this.holeRect,
    required this.holeAbove,
    required this.screenSize,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    // Nishon ekranning pastki yarmida bo'lsa (masalan pastki
    // navigatsiya) — karta va strelka nishon USTIDA turadi;
    // aks holda (masalan tepadagi xarita) — nishon OSTIDA.
    final cardBottom = holeAbove ? screenSize.height - holeRect.top + 14 : null;
    final cardTop = holeAbove ? null : holeRect.bottom + 14;

    return Positioned(
      left: AppSpacing.xl,
      right: AppSpacing.xl,
      top: cardTop,
      bottom: cardBottom,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!holeAbove)
            const Icon(PhosphorIconsFill.arrowUp,
                color: Colors.white, size: 26),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.lgAll,
              boxShadow: AppShadows.elevated(false),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(step.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightTextPrimary)),
                const SizedBox(height: AppSpacing.xs),
                Text(step.description,
                    style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.4,
                        color: AppColors.lightTextSecondary)),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: onSkip,
                      child: const Text("O'tkazib yuborish"),
                    ),
                    if (step.onTargetTap == null)
                      ElevatedButton(
                        onPressed: onNext,
                        child: Text(step.isLast ? 'Tugatish' : 'Keyingi'),
                      )
                    else
                      Text(
                        'Davom etish uchun yuqoriga bosing',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (holeAbove)
            const Icon(PhosphorIconsFill.arrowDown,
                color: Colors.white, size: 26),
        ],
      ),
    );
  }
}
