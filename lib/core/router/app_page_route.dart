import 'package:flutter/material.dart';

/// Butun ilova bo'ylab bir xil, silliq sahifa o'tishi — yengil fade +
/// o'ngdan chapga siljish. `app_router.dart`dagi GoRouter'ning 9 ta
/// asosiy yo'li (splash/login/home kabi) uchun ishlatiladigan
/// `_buildPageWithTransition`bilan **bir xil** uslub, shu yerdan import
/// qilib ishlatiladi — ikkalasi orasida uslub farqlanib ketmasligi uchun.
///
/// Ilova ichidagi navigatsiya (`Navigator.push`) uchun esa oddiy
/// `MaterialPageRoute` o'rniga shu yordamchi ishlatiladi:
/// ```dart
/// Navigator.of(context).push(AppPageRoute(builder: (_) => const FooScreen()));
/// ```
/// yoki qisqa yozuv uchun:
/// ```dart
/// AppPageRoute.push(context, const FooScreen());
/// ```
const Duration appPageTransitionDuration = Duration(milliseconds: 320);
const Duration appPageReverseTransitionDuration = Duration(milliseconds: 260);

Widget appPageTransitionsBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: appPageTransitionsBuilder,
          transitionDuration: appPageTransitionDuration,
          reverseTransitionDuration: appPageReverseTransitionDuration,
        );

  /// `Navigator.push(context, MaterialPageRoute(builder: (_) => screen))`ga
  /// bir qatorlik almashtirish — deyarli hamma joyda screen o'zgarmas
  /// bo'lgani uchun eng ko'p ishlatiladigan holat.
  static Future<T?> push<T>(BuildContext context, Widget screen) {
    return Navigator.of(context)
        .push<T>(AppPageRoute<T>(builder: (_) => screen));
  }
}
