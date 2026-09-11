import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../features/home/data/home_repository.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/neighbors_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/requests/presentation/requests_screen.dart';
import '../../features/feed/presentation/feed_screen.dart';
import '../services/tutorial_service.dart';
import 'app_feedback.dart';
import 'app_alert.dart';
import 'glass_bottom_nav.dart';
import 'no_mahalla_view.dart';
import 'tutorial_keys.dart';
import 'tutorial_overlay.dart';

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

/// Pastki navigatsiya (5 bo'lim): Asosiy, Lenta, Murojaat, Qo'shnilar,
/// Profil. "Lenta" avvalgi "E'lonlar" o'rnida — postlar, e'lonlar va
/// tadbirlarni birlashtiradi (`FeedScreen`ga qarang).
///
/// Phosphor Fill ikonalari bilan — ilovaning qolgan qismida
/// ishlatiladigan ikonka tili bilan bir xil (avval generic Material
/// "_rounded" ikonalar edi, "default" ko'rinishga sabab bo'lgan).
/// Har bir bo'lim o'zining ekran sarlavhasidagi aksent rangini olib
/// yuradi — tanlanganda pastki bar rangi shu ekranning brend rangi
/// bilan mos keladi.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    FeedScreen(),
    RequestsScreen(),
    _NeighborsTab(),
    ProfileScreen(),
  ];

  // Har bir bo'lim ilgari o'z aksent rangini olib yurardi (ko'k/
  // yashil/binafsha) — pastki navigatsiyada tab bosilganda rang
  // "sakrab" turgandek, izchil bo'lmagan tuyulardi. Endi barchasi
  // bitta brend rangida (`GlassBottomNav.accentColor`, standart
  // holatda `AppColors.primary`) — bo'lim ranglari ekran sarlavha
  // lentalarida saqlanadi, faqat navigatsiya birlashtiriladi.
  static const _items = [
    GlassNavItem(
      icon: PhosphorIconsFill.houseLine,
      label: 'Asosiy',
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.rows,
      label: 'Lenta',
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.chatCircleDots,
      label: 'Murojaat',
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.usersThree,
      label: "Qo'shni",
    ),
    GlassNavItem(
      icon: PhosphorIconsFill.userCircle,
      label: 'Profil',
    ),
  ];

  static final _itemKeys = <GlobalKey?>[
    null, // Asosiy — qo'llanmada nishonlanmaydi (foydalanuvchi so'rovi).
    TutorialKeys.navFeed,
    TutorialKeys.navRequests,
    TutorialKeys.navNeighbors,
    TutorialKeys.navProfile,
  ];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    _maybeStartTour();
  }

  /// Birinchi marta MainShell ochilganda (login/QR-skanerlashdan
  /// keyin) — "Xush kelibsiz" xabari, so'ng qisqa qo'llanma. Faqat
  /// hali ko'rilmagan bo'lsa (`TutorialService`), va faqat BIR MARTA
  /// shu sessiyada.
  Future<void> _maybeStartTour() async {
    final completed = await TutorialService.hasCompletedTour();
    if (completed || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    showAppAlert(
        context, "Xush kelibsiz! Keling, ilova bilan qisqacha tanishtiraman.",
        kind: AppAlertKind.success);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    ref.read(tutorialControllerProvider).start();
  }

  List<TutorialStep> _tutorialSteps(void Function(int) selectIndex) {
    return [
      TutorialStep(
        targetKey: TutorialKeys.map,
        title: 'Mahallangiz xaritasi',
        description:
            "Bu yerda mahallangiz chegarasi va joylashuvi ko'rsatiladi.",
      ),
      TutorialStep(
        targetKey: TutorialKeys.navFeed,
        title: 'Lenta',
        description:
            "E'lonlar, tadbirlar va postlar shu yerda — davom etish uchun bosing.",
        onTargetTap: () => selectIndex(1),
      ),
      TutorialStep(
        targetKey: TutorialKeys.navRequests,
        title: 'Murojaatlar',
        description: "Muammo haqida murojaat yuborish uchun shu yerga bosing.",
        onTargetTap: () => selectIndex(2),
      ),
      TutorialStep(
        targetKey: TutorialKeys.navNeighbors,
        title: "Qo'shnilar",
        description: "Ko'changizdagi va mahalladagi qo'shnilaringiz shu yerda.",
        onTargetTap: () => selectIndex(3),
      ),
      TutorialStep(
        targetKey: TutorialKeys.navProfile,
        title: 'Profil',
        description: "Ma'lumotlaringiz va sozlamalar shu yerda — bosing.",
        onTargetTap: () => selectIndex(4),
      ),
      TutorialStep(
        targetKey: TutorialKeys.settingsMenuItem,
        title: 'Sozlamalar',
        description:
            "\"Qulaylik\" bo'limida til, ko'rinish (yorug'/qorong'u) va "
            "matn o'lchamini o'zgartirasiz.",
        isLast: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
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
                child: MainShell._screens[currentIndex],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassBottomNav(
              items: MainShell._items,
              currentIndex: currentIndex,
              onTap: selectIndex,
              itemKeys: MainShell._itemKeys,
            ),
          ),
          Consumer(builder: (context, ref, _) {
            final controller = ref.watch(tutorialControllerProvider);
            if (!controller.isActive) return const SizedBox.shrink();
            return TutorialOverlay(
              controller: controller,
              steps: _tutorialSteps(selectIndex),
            );
          }),
        ],
      ),
    );
  }
}
