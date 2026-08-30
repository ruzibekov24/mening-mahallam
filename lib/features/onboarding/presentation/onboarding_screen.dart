import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../l10n/app_localizations.dart';
import '../data/onboarding_page_data.dart';

/// 2. ONBOARDING ekrani.
/// Har bir bosqich — qo'l bilan tepaga/pastga surib almashtiriladigan
/// to'liq ekranli "karta" (haqiqiy `PageView` surish fizikasi bilan —
/// avvalgi qo'lda hisoblangan drag-chegara o'rniga). Yuqoridagi
/// glass-effektli preview ro'yxati va pastdagi tugmalar sahifalar
/// ustida qo'zg'almas turadi, faqat highlight/kontent almashadi.
/// 4-marta "Davom etish" bosilgach, Kirish/Ro'yxatdan o'tish tanlovi
/// ko'rsatiladi.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _showAuthChoice = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onContinue(int pageCount) {
    if (_showAuthChoice) return;
    if (_currentIndex == pageCount - 1) {
      setState(() => _showAuthChoice = true);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToIndex(int index) {
    if (_showAuthChoice) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSkip() => context.go(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final pages = onboardingPages(context);
    final page = pages[_currentIndex];
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Har bir bosqich — surat + rangli parda + sarlavha/tavsif —
          // qo'l bilan surib o'tiladigan haqiqiy PageView sahifasi.
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: _showAuthChoice
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: pages.length,
            itemBuilder: (context, index) => _OnboardingPageCard(
              page: pages[index],
              topReserve: topInset + 252,
              bottomReserve: bottomInset + 176,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _GlassPreviewStack(
                    highlightedIndex: _currentIndex,
                    onSelectIndex: _goToIndex,
                  ),
                  const Spacer(),
                  _StepDots(
                    count: pages.length,
                    currentIndex: _currentIndex,
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showAuthChoice
                        ? _AuthChoiceButtons(
                            key: const ValueKey('auth-choice'),
                            accentColor: page.tint,
                          )
                        : _ContinueFooter(
                            key: const ValueKey('continue'),
                            accentColor: page.tint,
                            onContinue: () => _onContinue(pages.length),
                            onSkip: _onSkip,
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bitta bosqichning to'liq ekranli "kartasi" — fon surati, rangli
/// parda va sarlavha/tavsif. `topReserve`/`bottomReserve` — tepadagi
/// glass preview va pastdagi nuqta+tugmalar bilan qoplanmasligi uchun
/// matnni markazga siquvchi bo'sh joy.
class _OnboardingPageCard extends StatelessWidget {
  final OnboardingPageData page;
  final double topReserve;
  final double bottomReserve;

  const _OnboardingPageCard({
    required this.page,
    required this.topReserve,
    required this.bottomReserve,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(page.image),
          fit: BoxFit.cover,
          alignment: page.imageAlignment,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              page.tint.withValues(alpha: 0.55),
              page.tint.withValues(alpha: 0.35),
              Colors.black.withValues(alpha: 0.72),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, topReserve, 24, bottomReserve),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                page.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pastdagi "Davom etish" tugmasi + "O'tkazib yuborish" havolasi.
class _ContinueFooter extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const _ContinueFooter({
    super.key,
    required this.accentColor,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.continueButton),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onSkip,
          child: Text(
            l10n.skipButton,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }
}

/// 4-bosqichdan keyin ko'rsatiladigan Kirish/Ro'yxatdan o'tish tanlovi.
class _AuthChoiceButtons extends StatelessWidget {
  final Color accentColor;
  const _AuthChoiceButtons({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.register),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.registerButton),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () => context.go(AppRoutes.login),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(l10n.loginButton),
          ),
        ),
      ],
    );
  }
}

/// Bosqichlarni ko'rsatuvchi nuqtalar (PageView o'rniga qo'lda boshqariladi).
class _StepDots extends StatelessWidget {
  final int count;
  final int currentIndex;
  const _StepDots({required this.count, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Yuqoridagi shisha (glassmorphism) effektli preview kartasi.
/// Highlight indikatori "Davom etish" bosilganda, biror qator ustiga
/// bosilganda, yoki ro'yxat tepaga/pastga surilganda navbatdagi
/// qatorga silliq animatsiya bilan o'tadi.
class _GlassPreviewStack extends StatelessWidget {
  final int highlightedIndex;
  final ValueChanged<int> onSelectIndex;
  const _GlassPreviewStack({
    required this.highlightedIndex,
    required this.onSelectIndex,
  });

  static const double _rowHeight = 44;
  static const double _rowSpacing = 8;

  @override
  Widget build(BuildContext context) {
    final items = onboardingPreviewItems(context);
    final itemCount = items.length;
    final stackHeight = itemCount * _rowHeight + (itemCount - 1) * _rowSpacing;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: SizedBox(
            height: stackHeight,
            child: Stack(
              children: [
                // Sirg'aluvchi highlight foni — navbatdagi qatorga
                // silliq animatsiya bilan o'tadi.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  top: highlightedIndex * (_rowHeight + _rowSpacing),
                  left: 0,
                  right: 0,
                  height: _rowHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Column(
                  children: List.generate(itemCount, (index) {
                    final item = items[index];
                    final isHighlighted = index == highlightedIndex;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == itemCount - 1 ? 0 : _rowSpacing,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelectIndex(index),
                        child: SizedBox(
                          height: _rowHeight,
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              if (item.imagePath != null)
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: isHighlighted ? 1 : 0.55,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      item.imagePath!,
                                      width: 28,
                                      height: 28,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              else
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isHighlighted
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    item.icon,
                                    size: 15,
                                    color: isHighlighted
                                        ? Colors.black87
                                        : Colors.white,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isHighlighted ? 15.5 : 13.5,
                                  fontWeight: isHighlighted
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                                child: Text(item.label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}