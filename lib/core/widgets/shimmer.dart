import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ma'lumot yuklanayotganda ko'rsatiladigan, chapdan o'ngga
/// suzib o'tuvchi yorug'lik effekti (shimmer) bilan bezalgan
/// joy egallovchi (placeholder) qutича. Oddiy `CircularProgressIndicator`
/// o'rniga ishlatilib, kontent shaklini oldindan taxmin qildiradi
/// — bu foydalanuvchiga yuklanish jarayonini yumshoqroq his qildiradi.
class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final baseColor =
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFEDEDF0);
    final highlightColor =
        isDark ? AppColors.darkBorder : const Color(0xFFF7F7F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.5 + 3 * t, 0),
              end: Alignment(0.5 + 3 * t, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// Ro'yxat elementi shaklidagi karta skeleton'i — ikonka/avatar
/// o'rni + ikki qatorli matn o'rni. Murojaatlar, e'lonlar, qo'shnilar
/// kabi ro'yxatlarda yuklanish paytida ishlatiladi.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ShimmerBox(
            width: 42,
            height: 42,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: double.infinity, height: 13),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bir nechta ShimmerListTile'ni ketma-ket ko'rsatadigan qulaylik
/// widget'i — `count` marta takrorlaydi.
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const ShimmerListTile()),
    );
  }
}

/// Statistika/kategoriya kartasi shaklidagi skeleton — kvadratsimon
/// grid elementlar uchun (masalan Asosiy sahifadagi statistika).
class ShimmerStatCard extends StatelessWidget {
  const ShimmerStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ShimmerBox(
            width: 34,
            height: 34,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 8),
          const ShimmerBox(width: 40, height: 18),
          const SizedBox(height: 6),
          const ShimmerBox(width: 60, height: 10),
        ],
      ),
    );
  }
}
