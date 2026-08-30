import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../qr/data/mahalla_repository.dart';
import '../data/announcements_providers.dart';
import '../data/event_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// Yangi tadbir yaratish (yoki mavjudini tahrirlash) ekrani — faqat
/// xodim/rais uchun ochiladi (announcements_screen.dart'da
/// role.canPost orqali tekshiriladi).
class NewEventScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  final MahallaEvent? existing;
  const NewEventScreen({super.key, required this.mahallaId, this.existing});

  @override
  ConsumerState<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends ConsumerState<NewEventScreen> {
  late final _titleController =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _locationController =
      TextEditingController(text: widget.existing?.location ?? '');
  late DateTime? _selectedDate = widget.existing?.dateTime;
  late TimeOfDay? _selectedTime = widget.existing == null
      ? null
      : TimeOfDay.fromDateTime(widget.existing!.dateTime);
  bool _isSubmitting = false;
  bool _broadcastToAll = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime? get _combinedDateTime {
    if (_selectedDate == null || _selectedTime == null) return null;
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate =
        _selectedDate != null && _selectedDate!.isBefore(now) ? _selectedDate! : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final dateTime = _combinedDateTime;

    if (title.isEmpty || dateTime == null) {
      showAppAlert(context, l10n.fillEventFields, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      if (_isEditing) {
        await repo.updateEvent(
          mahallaId: widget.mahallaId,
          eventId: widget.existing!.id,
          title: title,
          dateTime: dateTime,
          location: location,
        );
      } else if (_broadcastToAll) {
        final mahallas =
            await ref.read(mahallaRepositoryProvider).fetchAllMahallas();
        for (final mahalla in mahallas) {
          await repo.createEvent(
            mahallaId: mahalla.id,
            title: title,
            dateTime: dateTime,
            location: location,
          );
        }
      } else {
        await repo.createEvent(
          mahallaId: widget.mahallaId,
          title: title,
          dateTime: dateTime,
          location: location,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlert(context, _isEditing ? l10n.eventUpdated : l10n.eventPosted);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(_isEditing ? l10n.editEventTitle : l10n.newEventTitle,
                      style: context.titleStyle),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                children: [
                  Text(l10n.titleLabel, style: context.captionStyle),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(hintText: l10n.eventTitleHint),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Text(l10n.dateLabel, style: context.captionStyle),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerField(
                          icon: PhosphorIconsRegular.calendar,
                          label: _selectedDate == null
                              ? l10n.selectDate
                              : _formatDate(_selectedDate!),
                          isPlaceholder: _selectedDate == null,
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PickerField(
                          icon: PhosphorIconsRegular.clock,
                          label: _selectedTime == null
                              ? l10n.selectTime
                              : _formatTime(_selectedTime!),
                          isPlaceholder: _selectedTime == null,
                          onTap: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    children: [
                      Text(l10n.locationLabel, style: context.captionStyle),
                      const SizedBox(width: AppSpacing.xs),
                      Text(l10n.optionalLabel, style: context.captionStyle),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _locationController,
                    decoration:
                        InputDecoration(hintText: l10n.locationHint),
                  ),

                  if (!_isEditing)
                    Consumer(
                      builder: (context, ref, _) {
                        final isSuperAdmin = ref
                                .watch(currentUserProfileProvider)
                                .valueOrNull
                                ?.role
                                .isSuperAdmin ==
                            true;
                        if (!isSuperAdmin) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: InkWell(
                            borderRadius: AppRadius.smAll,
                            onTap: () => setState(
                                () => _broadcastToAll = !_broadcastToAll),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.06),
                                borderRadius: AppRadius.smAll,
                                border: Border.all(
                                    color:
                                        AppColors.danger.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _broadcastToAll,
                                    activeColor: AppColors.danger,
                                    onChanged: (v) => setState(
                                        () => _broadcastToAll = v ?? false),
                                  ),
                                  Expanded(
                                    child: Text(
                                      l10n.broadcastToAllMahallasLabel,
                                      style: context.bodyStyle
                                          .copyWith(color: AppColors.danger),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(_isEditing ? l10n.saveButton : l10n.postButton),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _PickerField({
    required this.icon,
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.smAll,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: context.borderColor),
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: context.bodyStyle.copyWith(
                  fontSize: 13,
                  color: isPlaceholder ? context.textSecondary : context.textPrimary,
                  fontWeight:
                      isPlaceholder ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
