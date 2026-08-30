import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/neighbors_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/requests/presentation/requests_screen.dart';
import '../../features/announcements/presentation/announcements_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_feedback.dart';
import 'glass_bottom_nav.dart';
import 'no_mahalla_view.dart';
import 'offline_banner.dart';

/// Joriy faol tab indeksi.
final mainTabIndexProvider = StateProvider<int>((ref) => 0);

class _NeighborsTab extends ConsumerWidget {
  const _NeighborsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    return profileAsync.when(
      data: (profile) {
        final mahallaId = profile?.mahallaId;
        // Ilgari bu yerda `SizedBox.shrink()` turardi — mahallaga
        // qo'shilmagan foydalanuvchi hech qanday tushuntirishsiz
        // butunlay oq ekran ko'rardi.
        if (mahallaId == null) return const NoMahallaView();
        return NeighborsScreen(mahallaId: mahallaId);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AppErrorView.fromError(error),
    );
  }
}

/// Mockupdagi pastki navigatsiya (5 bo'lim): Asosiy, E'lonlar,
/// Murojaat, Qo'shnilar, Profil.
///
/// Phosphor Fill ikonalari bilan — ilovaning qolgan qismida
/// ishlatiladigan ikonka tili bilan bir xil (avval generic Material
/// "_rounded" ikonalar edi, "default" ko'rinishga sabab bo'lgan).
/// Har bir bo'lim o'zining ekran sarlavhasidagi aksent rangini olib
/// yuradi — tanlanganda pastki bar rangi shu ekranning brend rangi
/// bilan mos keladi.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    AnnouncementsScreen(),
    RequestsScreen(),
    _NeighborsTab(),
    ProfileScreen(),
  ];

  static const _items = [
    GlassNavItem(
      icon: PhosphorIconsFill.houseLine,
      label: 'Asosiy',
      color: AppColors.primary,
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.megaphone,
      label: "E'lonlar",
      color: AppAccents.events,
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.chatCircleDots,
      label: 'Murojaat',
      color: AppAccents.requests,
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.usersThree,
      label: "Qo'shni",
      color: AppAccents.neighbors,
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.userCircle,
      label: 'Profil',
      color: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    void selectIndex(int index) {
      if (index == currentIndex) return;
      ref.read(mainTabIndexProvider.notifier).state = index;
    }

    return Scaffold(
      // "Bo'sh fon" muammosi endi umumiy naqsh/gradient bilan emas —
      // har bir ekranning o'zida (Home sarlavhasi, Onboarding orqa
      // foni) haqiqiy, litsenziyalangan (CC0) o'zbek to'qimachilik
      // suratlari bilan hal qilinadi (pastga qarang: HomeScreen,
      // OnboardingScreen). Shu yerda umumiy soxta tekstura kerak emas.
      body: Column(
        children: [
          // Barcha bo'limlar ustida, ekranlar almashsa ham doim
          // ko'rinadigan joyda — foydalanuvchi qaysi tabda bo'lishidan
          // qat'iy nazar oflayn holatini bilib turishi kerak.
          const OfflineBanner(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(currentIndex),
                      child: _screens[currentIndex],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: GlassBottomNav(
                    items: _items,
                    currentIndex: currentIndex,
                    onTap: selectIndex,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}