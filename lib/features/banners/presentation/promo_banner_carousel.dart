import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/promo_banner_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// Bosh ekrandagi avtomatik aylanuvchi banner qatori — e'lon, boshqa
/// ilova havolasi, konkurs yoki reklama bo'lishi mumkin. Bosilganda
/// umumiy ma'lumot (sarlavha+tavsif+ixtiyoriy havola) pastdan chiqadi.
/// Banner bo'lmasa hech narsa ko'rsatmaydi (bo'sh joy qoldirmaydi).
class PromoBannerCarousel extends ConsumerWidget {
  const PromoBannerCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(activeBannersProvider);

    return bannersAsync.when(
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();
        return _Carousel(banners: banners);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Carousel extends StatefulWidget {
  final List<PromoBanner> banners;
  const _Carousel({required this.banners});

  @override
  State<_Carousel> createState() => _CarouselState();
}

/// Har bir banner ekranda necha soniya turishi — Instagram
/// "stories"dagidek, pastdagi chiziq shu davomiylikda chapdan o'ngga
/// to'lib boradi.
const _kBannerDuration = Duration(seconds: 7);

/// Joriy (markazdagi) bannerning balandligi — yon tomondagi oldingi/
/// keyingi bannerlar xuddi shu balandlikda, lekin pastroqqa "surilgan"
/// holda ko'rinadi (Play Market/App Store'dagi featured karusel kabi).
const _kCardHeight = 176.0;
const _kPeekOffset = 20.0;

class _CarouselState extends State<_Carousel>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _progressController;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.84);
    _progressController = AnimationController(
      vsync: this,
      duration: _kBannerDuration,
    )..addStatusListener(_onProgressStatusChanged);
    if (widget.banners.length > 1) _progressController.forward();
  }

  void _onProgressStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final next = (_page + 1) % widget.banners.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    if (widget.banners.length > 1) {
      _progressController
        ..reset()
        ..forward();
    }
  }

  void _showDetail(PromoBanner banner) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _BannerDetailSheet(banner: banner),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _kCardHeight + _kPeekOffset,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.banners.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  var page = _page.toDouble();
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    page = _pageController.page ?? page;
                  }
                  final delta = (page - index).abs().clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Transform.translate(
                      offset: Offset(0, delta * _kPeekOffset),
                      child: child,
                    ),
                  );
                },
                child: _BannerCard(
                  banner: banner,
                  onTap: () => _showDetail(banner),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(widget.banners.length, (index) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: context.textMuted.withValues(alpha: 0.25),
                    borderRadius: AppRadius.pillAll,
                  ),
                  child: index == _page
                      ? AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, _) => FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.pillAll,
                              ),
                            ),
                          ),
                        )
                      : (index < _page
                          ? const DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: AppRadius.pillAll,
                              ),
                            )
                          : null),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Bitta banner kartasi — belgilangan balandlikda (`_kCardHeight`),
/// tepasidan burchaklari yumaloq, pastida sarlavha + bosish belgisi.
class _BannerCard extends StatelessWidget {
  final PromoBanner banner;
  final VoidCallback onTap;
  const _BannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: _kCardHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(color: context.surfaceColor);
                },
                errorBuilder: (_, __, ___) =>
                    Container(color: context.surfaceColor),
              ),
              // Sarlavha o'qilishi uchun rasmning pastki qismini
              // yumshoq qorong'ilashtiruvchi gradient.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                      AppSpacing.xxl, AppSpacing.lg, AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.cardTitleStyle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Bosish mumkinligini bildiruvchi kichik belgi.
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsBold.arrowUpRight,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BannerDetailSheet extends StatelessWidget {
  final PromoBanner banner;
  const _BannerDetailSheet({required this.banner});

  Future<void> _openLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final url = banner.linkUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showAppAlert(context, l10n.linkOpenFailedMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasLink = banner.linkUrl != null && banner.linkUrl!.isNotEmpty;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              // Rasmning o'zi original nisbatida (crop qilinmasdan)
              // to'liq ko'rsatiladi — kenglikka moslab, balandligi
              // rasmning haqiqiy nisbatidan avtomatik hisoblanadi.
              child: Image.network(
                banner.imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: context.surfaceColor,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(banner.title, style: context.titleStyle),
            if (banner.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(banner.description,
                  style: context.bodyStyle.copyWith(height: 1.5)),
            ],
            if (hasLink) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _openLink(context),
                  icon: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 18),
                  label: Text(l10n.openLinkAction),
                ),
              ),
            ],
            if (banner.attribution != null &&
                banner.attribution!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                banner.attribution!,
                style: context.captionStyle.copyWith(color: context.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
