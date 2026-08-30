import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../ads/data/service_ad_repository.dart';
import '../../ads/presentation/service_ad_card.dart';
import '../../home/data/home_repository.dart';
import '../../map/presentation/location_picker_screen.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../data/service_repository.dart';
import '../data/services_providers.dart';
import '../../../core/widgets/app_alert.dart';

String _categoryLabel(AppLocalizations l10n, ServiceCategory category) {
  switch (category) {
    case ServiceCategory.santexnik:
      return l10n.serviceCategorySantexnik;
    case ServiceCategory.elektrik:
      return l10n.serviceCategoryElektrik;
    case ServiceCategory.duradgor:
      return l10n.serviceCategoryDuradgor;
    case ServiceCategory.tozalash:
      return l10n.serviceCategoryTozalash;
    case ServiceCategory.qurilish:
      return l10n.serviceCategoryQurilish;
    case ServiceCategory.boshqa:
      return l10n.serviceCategoryBoshqa;
  }
}

Future<void> _launchCall(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

/// Mahalliy xizmatlar katalogi — rais/xodim tasdiqlagan santexnik,
/// elektrik va h.k. xizmat ko'rsatuvchilar ro'yxati. Aholi
/// to'g'ridan-to'g'ri qo'ng'iroq qiladi.
class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servicesAsync = ref.watch(mahallaServicesProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      // Bu ekran Navigator.push bilan ochiladi — orqasida
      // MainShell foni YO'Q. Shaffof qoldirilsa ekran qop-qora
      // bo'lib ko'rinardi. Rang berilmasa mavzudagi
      // `scaffoldBackgroundColor` ishlaydi (dark mode ham).
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppAccents.events,
              image: 'assets/images/patterns/abstract_orange.png',
              watermarkIcon: PhosphorIconsFill.toolbox,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: Colors.white),
                  ),
                  Expanded(
                    child: Text(l10n.servicesTitle,
                        style:
                            context.titleStyle.copyWith(color: Colors.white)),
                  ),
                  profileAsync.when(
                    data: (profile) {
                      final canPost = profile?.role.canPost == true &&
                          profile?.mahallaId != null;
                      if (!canPost) return const SizedBox.shrink();
                      return IconButton(
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _NewServiceSheet(
                            mahallaId: profile!.mahallaId!,
                          ),
                        ),
                        icon: const Icon(PhosphorIconsFill.plusCircle,
                            color: Colors.white),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.toolbox,
                      title: l10n.noServicesYet,
                      subtitle: l10n.noServicesHint,
                      accent: AppAccents.events,
                      scrollable: true,
                    );
                  }
                  // Reklama ro'yxat boshida BIR MARTA ko'rsatiladi
                  // (premium foydalanuvchida umuman chizilmaydi) —
                  // ro'yxat ichiga sochib yuborilmaydi.
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    // +1 reklama kartochkasi uchun, +1 esa ro'yxat
                    // oxiridagi "o'z xizmatingizni reklama qiling"
                    // taklifi uchun.
                    itemCount: services.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) return const ServiceAdCard();
                      if (index == services.length + 1) {
                        return const _AdvertiseYourServiceCard();
                      }
                      final i = index - 1;
                      return StaggeredEntrance(
                        index: i,
                        child: _ServiceCard(service: services[i]),
                      );
                    },
                  );
                },
                loading: () => ListView(
                  padding: AppSpacing.listPadding,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [ShimmerList(count: 5)],
                ),
                error: (error, _) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(mahallaServicesProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  final LocalService service;
  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canManage =
        profile?.role.canPost == true && profile?.mahallaId != null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final myRating = uid == null ? null : service.ratings[uid];

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppAccents.events.withValues(alpha: 0.14),
              borderRadius: AppRadius.smAll,
            ),
            child:
                Icon(service.category.icon, size: 20, color: AppAccents.events),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: context.cardTitleStyle),
                const SizedBox(height: AppSpacing.xxs),
                Text(_categoryLabel(l10n, service.category),
                    style: context.secondaryStyle),
                if (service.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(service.description, style: context.bodyStyle),
                ],
              ],
            ),
          ),
          Column(
            children: [
              TapScale(
                onTap: () => _launchCall(service.phone),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Icon(PhosphorIconsFill.phone,
                      size: 18, color: AppColors.primary),
                ),
              ),
              PopupMenuButton<void>(
                icon: Icon(PhosphorIconsBold.dotsThreeVertical,
                    size: 16, color: context.textMuted),
                padding: EdgeInsets.zero,
                iconSize: 16,
                tooltip: '',
                shape:
                    const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () async {
                      await Future.delayed(const Duration(milliseconds: 1));
                      if (!context.mounted) return;
                      showReportSheet(
                        context,
                        ref,
                        targetType: ReportTargetType.serviceAd,
                        targetId: service.id,
                        targetSnippet: service.name,
                        mahallaId: profile?.mahallaId,
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.flag,
                            size: 18, color: AppColors.danger),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.reportAction,
                            style: context.bodyStyle
                                .copyWith(color: AppColors.danger)),
                      ],
                    ),
                  ),
                  if (canManage)
                    PopupMenuItem(
                      onTap: () async {
                        await Future.delayed(const Duration(milliseconds: 1));
                        if (!context.mounted) return;
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _NewServiceSheet(
                            mahallaId: profile!.mahallaId!,
                            existing: service,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.pencilSimple,
                              size: 18, color: context.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.editButton, style: context.bodyStyle),
                        ],
                      ),
                    ),
                  if (canManage)
                    PopupMenuItem(
                      onTap: () async {
                        await Future.delayed(const Duration(milliseconds: 1));
                        if (!context.mounted) return;
                        final confirmed = await confirmDelete(
                          context,
                          itemTitle: service.name,
                        );
                        if (!confirmed || !context.mounted) return;
                        await ref.read(serviceRepositoryProvider).deleteService(
                              mahallaId: profile!.mahallaId!,
                              serviceId: service.id,
                            );
                        if (context.mounted) {
                          showAppAlert(context, l10n.itemDeletedMessage);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(PhosphorIconsRegular.trash,
                              size: 18, color: AppColors.danger),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.deleteButton,
                              style: context.bodyStyle
                                  .copyWith(color: AppColors.danger)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ServiceRatingRow(
            service: service,
            myRating: myRating,
            enabled: uid != null && profile?.mahallaId != null,
            onRate: (stars) {
              if (uid == null || profile?.mahallaId == null) return;
              ref.read(serviceRepositoryProvider).rateService(
                    mahallaId: profile!.mahallaId!,
                    serviceId: service.id,
                    uid: uid,
                    stars: stars,
                  );
            },
          ),
        ],
      ),
    );
  }
}

/// Xizmat kartochkasidagi baholash qatori: o'rtacha bahoni va baho
/// beruvchilar sonini ko'rsatadi, shuningdek joriy foydalanuvchi
/// bosib o'z bahosini yuborishi mumkin bo'lgan 5 ta yulduzcha.
class _ServiceRatingRow extends StatelessWidget {
  final LocalService service;
  final int? myRating;
  final bool enabled;
  final ValueChanged<int> onRate;

  const _ServiceRatingRow({
    required this.service,
    required this.myRating,
    required this.enabled,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasRatings = service.ratingCount > 0;

    return Row(
      children: [
        const Icon(PhosphorIconsFill.star, size: 16, color: Color(0xFFE0A526)),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          hasRatings
              ? '${service.averageRating.toStringAsFixed(1)} · ${l10n.serviceRatingCount(service.ratingCount)}'
              : l10n.serviceNoRatingsYet,
          style: context.captionStyle,
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final filled = myRating != null && starIndex <= myRating!;
            return TapScale(
              onTap: enabled ? () => onRate(starIndex) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  filled ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                  size: 18,
                  color: filled ? const Color(0xFFE0A526) : context.textMuted,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _NewServiceSheet extends ConsumerStatefulWidget {
  final String mahallaId;
  final LocalService? existing;
  const _NewServiceSheet({required this.mahallaId, this.existing});

  @override
  ConsumerState<_NewServiceSheet> createState() => _NewServiceSheetState();
}

class _NewServiceSheetState extends ConsumerState<_NewServiceSheet> {
  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _phoneController =
      TextEditingController(text: widget.existing?.phone ?? '');
  late final _descriptionController =
      TextEditingController(text: widget.existing?.description ?? '');
  late ServiceCategory _category =
      widget.existing?.category ?? ServiceCategory.santexnik;
  late LatLng? _location = widget.existing?.hasLocation == true
      ? LatLng(widget.existing!.latitude!, widget.existing!.longitude!)
      : null;
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<LatLng?>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: _location),
      ),
    );
    // `push` `null` ni ham "hech narsa tanlanmadi" (orqaga qaytish),
    // ham "joylashuv tozalandi" (tasdiqlash tugmasi `null` bilan)
    // ma'nosida qaytarishi mumkin — ikkalasini ham xavfsiz qabul
    // qilamiz, chunki natija har doim ekrandagi joriy holatni
    // aks ettiradi.
    if (!mounted) return;
    setState(() => _location = result);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      showAppAlert(context, l10n.fillServiceFields, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(serviceRepositoryProvider);
      if (_isEditing) {
        await repo.updateService(
          mahallaId: widget.mahallaId,
          serviceId: widget.existing!.id,
          name: name,
          category: _category,
          phone: phone,
          description: _descriptionController.text.trim(),
          latitude: _location?.latitude,
          longitude: _location?.longitude,
        );
      } else {
        await repo.createService(
          mahallaId: widget.mahallaId,
          name: name,
          category: _category,
          phone: phone,
          description: _descriptionController.text.trim(),
          latitude: _location?.latitude,
          longitude: _location?.longitude,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlert(context,
          _isEditing ? l10n.serviceUpdatedMessage : l10n.servicePostedMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.lgAll,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? l10n.editServiceTitle : l10n.newServiceTitle,
                    style: context.titleStyle),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.serviceCategoryLabel, style: context.captionStyle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ServiceCategory.values.map((cat) {
                    final isActive = cat == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppAccents.events
                              : AppAccents.events.withValues(alpha: 0.1),
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          _categoryLabel(l10n, cat),
                          style: context.captionStyle.copyWith(
                            color: isActive ? Colors.white : AppAccents.events,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.serviceNameLabel, style: context.captionStyle),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(hintText: l10n.serviceNameHint),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.servicePhoneLabel, style: context.captionStyle),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration:
                      const InputDecoration(hintText: '+998 90 123 45 67'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(l10n.locationFieldLabel, style: context.captionStyle),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l10n.optionalLabel, style: context.captionStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TapScale(
                  onTap: _pickLocation,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppAccents.events.withValues(alpha: 0.1),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _location != null
                              ? PhosphorIconsFill.mapPin
                              : PhosphorIconsRegular.mapPin,
                          size: 18,
                          color: AppAccents.events,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _location != null
                                ? l10n.locationSetLabel
                                : l10n.setLocationLabel,
                            style: context.bodyStyle
                                .copyWith(color: AppAccents.events),
                          ),
                        ),
                        if (_location != null)
                          TapScale(
                            onTap: () => setState(() => _location = null),
                            child: Icon(
                              PhosphorIconsBold.x,
                              size: 16,
                              color: context.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(l10n.serviceDescriptionLabel,
                        style: context.captionStyle),
                    const SizedBox(width: AppSpacing.xs),
                    Text(l10n.optionalLabel, style: context.captionStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration:
                      InputDecoration(hintText: l10n.serviceDescriptionHint),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(_isEditing ? l10n.saveButton : l10n.postButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ro'yxat oxiridagi taklif: "o'z xizmatingizni shu yerda reklama
/// qiling".
///
/// Ikki maqsadi bor: mahalladagi ustalar/do'konlar uchun arzon
/// e'lon kanali ochish va premium obunaning haqiqiy foydasini
/// ko'rsatish — obunachi uchun narx yarmiga tushadi va bu shu yerda
/// aniq ko'rinib turadi.
class _AdvertiseYourServiceCard extends ConsumerWidget {
  const _AdvertiseYourServiceCard();

  static String _money(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isPremium =
        ref.watch(currentUserProfileProvider).valueOrNull?.isPremiumActive ==
            true;
    final price = ServiceAdRepository.priceFor(isPremium: isPremium);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(PhosphorIconsFill.storefront,
                    size: 18, color: AppAccents.events),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child:
                      Text(l10n.advertiseTitle, style: context.cardTitleStyle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.advertisePrice(_money(price)),
              style: context.secondaryStyle,
            ),
            if (isPremium) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(PhosphorIconsFill.crown,
                      size: 14, color: Color(0xFFE0A526)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.advertisePremiumDiscount(
                        _money(ServiceAdRepository.weeklyPrice)),
                    style: context.captionStyle
                        .copyWith(color: const Color(0xFFE0A526)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.advertiseHowTo, style: context.captionStyle),
          ],
        ),
      ),
    );
  }
}
