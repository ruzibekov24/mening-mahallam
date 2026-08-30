import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/media_picker_grid.dart';
import '../../../core/widgets/rich_text_editor_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../premium/data/premium_repository.dart';
import '../data/requests_labels.dart';
import '../data/requests_repository.dart';
import 'request_styles.dart';
import 'requests_screen.dart';
import '../../../core/widgets/app_alert.dart';

String _typeDescription(AppLocalizations l10n, RequestType type) {
  switch (type) {
    case RequestType.maxfiy:
      return l10n.typeMaxfiyDescription;
    case RequestType.ommaviy:
      return l10n.typeOmmaviyDescription;
  }
}

/// Yangi murojaat yaratishning 5 bosqichli oqimi:
/// 1. Turi → 2. Tafsilotlar → 3. Joylashuv → 4. Ko'rib chiqish → 5. Yuborildi
class NewRequestFlowScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const NewRequestFlowScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<NewRequestFlowScreen> createState() =>
      _NewRequestFlowScreenState();
}

class _NewRequestFlowScreenState extends ConsumerState<NewRequestFlowScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  RequestType _type = RequestType.maxfiy;
  RequestPriority _priority = RequestPriority.ortacha;
  final _titleController = TextEditingController();
  final QuillController _descriptionController = QuillController.basic();
  List<MediaFile> _images = [];
  LatLng? _location;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canGoNextFromDetails =>
      _titleController.text.trim().isNotEmpty &&
      !_descriptionController.document.isEmpty();

  void _goNext() {
    final l10n = AppLocalizations.of(context);
    if (_currentStep == 1 && !_canGoNextFromDetails) {
      showAppAlert(context, l10n.fillTitleAndDescription, kind: AppAlertKind.error);
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      _submit();
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);
    try {
      List<String> imageUrls = [];
      if (_images.isNotEmpty) {
        imageUrls = await ImageUploadService().uploadMediaFiles(
          files: _images,
          storagePathPrefix:
              'mahallas/${widget.mahallaId}/requests/${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      await ref.read(requestsRepositoryProvider).createRequest(
            mahallaId: widget.mahallaId,
            title: _titleController.text.trim(),
            description: jsonEncode(
                _descriptionController.document.toDelta().toJson()),
            type: _type,
            priority: _priority,
            imageUrls: imageUrls,
            latitude: _location?.latitude,
            longitude: _location?.longitude,
          );
      if (!mounted) return;
      setState(() {
        _currentStep = 4;
        _isSubmitting = false;
      });
    } on ImageUploadException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, e.message, kind: AppAlertKind.error);
    } on DailyRequestLimitReachedException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.dailyRequestLimitReached(e.limit), kind: AppAlertKind.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;
    final stepLabels = [
      l10n.stepType,
      l10n.stepDetails,
      l10n.stepLocation,
      l10n.stepReview,
      l10n.stepDone,
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  if (_currentStep < 4)
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(PhosphorIconsRegular.arrowLeft),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      l10n.newRequestTitle,
                      textAlign: TextAlign.center,
                      style: context.sectionStyle,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            if (_currentStep < 4) ...[
              const SizedBox(height: AppSpacing.sm),
              _StepIndicator(currentStep: _currentStep, labels: stepLabels),
              const SizedBox(height: AppSpacing.xl),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _buildStepContent(l10n),
              ),
            ),
            if (_currentStep < 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _goNext,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Icon(
                            _currentStep == 3
                                ? PhosphorIconsFill.paperPlaneTilt
                                : PhosphorIconsBold.arrowRight,
                            size: 18,
                          ),
                    label: Text(
                      _currentStep == 3 ? l10n.sendButton : l10n.continueButton,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(AppLocalizations l10n) {
    switch (_currentStep) {
      case 0:
        return _TypeStep(
          key: const ValueKey('step0'),
          selected: _type,
          onSelect: (type) => setState(() => _type = type),
        );
      case 1:
        return _DetailsStep(
          key: const ValueKey('step1'),
          titleController: _titleController,
          descriptionController: _descriptionController,
          priority: _priority,
          onPriorityChanged: (p) => setState(() => _priority = p),
          images: _images,
          onImagesChanged: (imgs) => setState(() => _images = imgs),
          // Premium foydalanuvchi ko'proq rasm qo'sha oladi.
          maxImages: ref
                      .watch(currentUserProfileProvider)
                      .valueOrNull
                      ?.isPremiumActive ==
                  true
              ? PremiumRepository.premiumImageLimit
              : PremiumRepository.freeImageLimit,
        );
      case 2:
        return _LocationStep(
          key: const ValueKey('step2'),
          mahallaId: widget.mahallaId,
          location: _location,
          onLocationChanged: (loc) => setState(() => _location = loc),
        );
      case 3:
        return _ReviewStep(
          key: const ValueKey('step3'),
          type: _type,
          priority: _priority,
          title: _titleController.text.trim(),
          descriptionController: _descriptionController,
          images: _images,
          hasLocation: _location != null,
        );
      default:
        return const _SuccessStep(key: ValueKey('step4'));
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  const _StepIndicator({required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    final secondaryColor = context.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Row(
        children: List.generate(labels.length, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;
          final isLast = index == labels.length - 1;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: index == 0
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: isCompleted || isActive
                                  ? AppColors.primary
                                  : context.borderColor,
                            ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppColors.primary
                            : context.surfaceColor,
                        border: Border.all(
                          color: isCompleted || isActive
                              ? AppColors.primary
                              : context.borderColor,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isCompleted
                          ? const Icon(PhosphorIconsBold.check,
                              size: 15, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: context.captionStyle.copyWith(
                                color: isActive ? Colors.white : secondaryColor,
                              ),
                            ),
                    ),
                    Expanded(
                      child: isLast
                          ? const SizedBox()
                          : Container(
                              height: 2,
                              color: isCompleted
                                  ? AppColors.primary
                                  : context.borderColor,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: context.captionStyle.copyWith(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? AppColors.primary : secondaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TypeStep extends StatelessWidget {
  final RequestType selected;
  final ValueChanged<RequestType> onSelect;
  const _TypeStep({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.chooseRequestType, style: context.sectionStyle),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.requestTypeExplain, style: context.secondaryStyle),
        const SizedBox(height: AppSpacing.xl),
        _TypeCard(
          type: RequestType.maxfiy,
          icon: PhosphorIconsFill.lockSimple,
          isSelected: selected == RequestType.maxfiy,
          onTap: () => onSelect(RequestType.maxfiy),
        ),
        const SizedBox(height: AppSpacing.md),
        _TypeCard(
          type: RequestType.ommaviy,
          icon: PhosphorIconsFill.globe,
          isSelected: selected == RequestType.ommaviy,
          onTap: () => onSelect(RequestType.ommaviy),
        ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  final RequestType type;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.type,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : null,
      elevated: false,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeLabel(l10n, type), style: context.cardTitleStyle),
                const SizedBox(height: AppSpacing.xxs),
                Text(_typeDescription(l10n, type), style: context.captionStyle),
              ],
            ),
          ),
          Radio<RequestType>(
            value: type,
            groupValue: isSelected ? type : null,
            onChanged: (_) => onTap(),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _DetailsStep extends StatefulWidget {
  final TextEditingController titleController;
  final QuillController descriptionController;
  final RequestPriority priority;
  final ValueChanged<RequestPriority> onPriorityChanged;
  final List<MediaFile> images;
  final ValueChanged<List<MediaFile>> onImagesChanged;
  final int maxImages;

  const _DetailsStep({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.priority,
    required this.onPriorityChanged,
    required this.images,
    required this.onImagesChanged,
    required this.maxImages,
  });

  @override
  State<_DetailsStep> createState() => _DetailsStepState();
}

class _DetailsStepState extends State<_DetailsStep> {
  @override
  void initState() {
    super.initState();
    widget.descriptionController.document.changes.listen((_) => _onChanged());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final charCount = widget.descriptionController.document.toPlainText().length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.titleFieldLabel, style: context.captionStyle),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.titleController,
          decoration: InputDecoration(
            hintText: l10n.titleFieldHint,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.descriptionLabel, style: context.captionStyle),
        const SizedBox(height: AppSpacing.sm),
        RichTextEditorField(
          controller: widget.descriptionController,
          hintText: l10n.descriptionHint,
          minHeight: 130,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('$charCount/500', style: context.captionStyle),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Text(l10n.attachPhotoLabel, style: context.captionStyle),
            const SizedBox(width: AppSpacing.xs),
            Text(l10n.optionalLabel, style: context.captionStyle),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        MediaPickerGrid(
          mediaFiles: widget.images,
          onChanged: widget.onImagesChanged,
          maxItems: widget.maxImages,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.priorityLevelLabel, style: context.captionStyle),
        const SizedBox(height: AppSpacing.xs),
        _PrioritySlider(
          value: widget.priority,
          onChanged: widget.onPriorityChanged,
        ),
      ],
    );
  }
}

class _PrioritySlider extends StatelessWidget {
  final RequestPriority value;
  final ValueChanged<RequestPriority> onChanged;
  const _PrioritySlider({required this.value, required this.onChanged});

  static const _order = [
    RequestPriority.past,
    RequestPriority.ortacha,
    RequestPriority.yuqori,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trackColor = value.color;

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: trackColor,
            inactiveTrackColor: trackColor.withValues(alpha: 0.2),
            thumbColor: trackColor,
            overlayColor: trackColor.withValues(alpha: 0.15),
            trackHeight: 5,
          ),
          child: Slider(
            value: _order.indexOf(value).toDouble(),
            min: 0,
            max: 2,
            divisions: 2,
            onChanged: (v) => onChanged(_order[v.round()]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _order.map((p) {
              final isActive = p == value;
              return Text(
                priorityLabel(l10n, p),
                style: context.captionStyle.copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? p.color : context.textSecondary,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Murojaat joylashuvini belgilash bosqichi — xaritani bosib nuqta
/// qo'yish yoki "Joriy joylashuv" tugmasi orqali GPS'dan olish.
/// Ixtiyoriy qadam — joylashuv belgilanmasa ham davom etish mumkin.
class _LocationStep extends ConsumerStatefulWidget {
  final String mahallaId;
  final LatLng? location;
  final ValueChanged<LatLng?> onLocationChanged;

  const _LocationStep({
    super.key,
    required this.mahallaId,
    required this.location,
    required this.onLocationChanged,
  });

  @override
  ConsumerState<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<_LocationStep> {
  final MapController _mapController = MapController();
  bool _isLocating = false;

  Future<void> _useCurrentLocation() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('service disabled');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('permission denied');
      }

      // Aniq sozlamalarsiz `getCurrentPosition()` ba'zi qurilmalarda
      // tarmoq/uyali aloqa operatorining ro'yxatdan o'tgan hududiga
      // asoslangan taxminiy (juda noaniq, ba'zan butunlay boshqa
      // shahar) joylashuvni qaytarishi mumkin — GPS chipini majburiy
      // ishlatish uchun aniq yuqori aniqlikni so'raymiz.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      widget.onLocationChanged(point);
      _mapController.move(point, 16);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.locationPermissionError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.locationStepTitle, style: context.sectionStyle),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.locationStepSubtitle, style: context.secondaryStyle),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter:
                          widget.location ?? const LatLng(41.311081, 69.240562),
                      initialZoom: 15,
                      onTap: (tapPosition, point) =>
                          widget.onLocationChanged(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'uz.meningmahallam.app',
                      ),
                      if (widget.location != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: widget.location!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                PhosphorIconsFill.mapPin,
                                color: AppColors.danger,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: FloatingActionButton.small(
                    heroTag: 'use_current_location',
                    onPressed: _isLocating ? null : _useCurrentLocation,
                    backgroundColor: AppColors.primary,
                    child: _isLocating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(PhosphorIconsFill.crosshair,
                            color: Colors.white, size: 20),
                  ),
                ),
                if (widget.location != null)
                  Positioned(
                    left: AppSpacing.md,
                    top: AppSpacing.md,
                    child: Material(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: AppRadius.xsAll,
                      child: InkWell(
                        borderRadius: AppRadius.xsAll,
                        onTap: () => widget.onLocationChanged(null),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsBold.x,
                                  size: 14, color: AppColors.danger),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                l10n.clearLocationAction,
                                style: context.captionStyle.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final RequestType type;
  final RequestPriority priority;
  final String title;
  final QuillController descriptionController;
  final List<MediaFile> images;
  final bool hasLocation;

  const _ReviewStep({
    super.key,
    required this.type,
    required this.priority,
    required this.title,
    required this.descriptionController,
    required this.images,
    required this.hasLocation,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(l10n.reviewDataTitle, style: context.sectionStyle),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: AppSpacing.card,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: context.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewRow(label: l10n.reviewType, value: typeLabel(l10n, type)),
              const Divider(height: AppSpacing.xxl),
              _ReviewRow(
                  label: l10n.reviewPriority,
                  value: priorityLabel(l10n, priority)),
              const Divider(height: AppSpacing.xxl),
              _ReviewRow(
                  label: l10n.reviewLocation,
                  value: hasLocation
                      ? l10n.reviewLocationSet
                      : l10n.reviewLocationNotSet),
              const Divider(height: AppSpacing.xxl),
              Text(l10n.titleFieldLabel, style: context.captionStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(title, style: context.cardTitleStyle),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.descriptionLabel, style: context.captionStyle),
              const SizedBox(height: AppSpacing.xs),
              IgnorePointer(
                child: Localizations.override(
                  context: context,
                  locale: const Locale('ru'),
                  child: QuillEditor.basic(
                    controller: descriptionController,
                    config: const QuillEditorConfig(
                      padding: EdgeInsets.zero,
                      expands: false,
                      scrollable: false,
                      showCursor: false,
                    ),
                  ),
                ),
              ),
              if (images.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.reviewPhotos(images.length),
                    style: context.captionStyle),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final media = images[index];
                      return ClipRRect(
                        borderRadius: AppRadius.xsAll,
                        child: media.type == MediaType.image
                            ? Image.file(
                                media.file,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.black87,
                                alignment: Alignment.center,
                                child: const Icon(
                                  PhosphorIconsFill.playCircle,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.secondaryStyle),
        Text(value, style: context.cardTitleStyle),
      ],
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: AppShadows.accent(AppColors.success, context.isDarkMode),
            ),
            child: const Icon(PhosphorIconsBold.check,
                color: Colors.white, size: 44),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(l10n.requestSentTitle, style: context.titleStyle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.requestSentMessage,
            textAlign: TextAlign.center,
            style: context.secondaryStyle,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.backToListButton),
            ),
          ),
        ],
      ),
    );
  }
}