import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/data/home_repository.dart';
import '../data/profile_banners.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// "Mening ma'lumotlarim" — ism, familiya, profil rasmi, tug'ilgan
/// sana, manzil va jinsni tahrirlash ekrani.
class EditProfileScreen extends ConsumerStatefulWidget {
  /// AI Yordamchi orqali oldindan to'ldirish uchun — berilgan bo'lsa,
  /// profildagi qiymat o'rniga shu ishlatiladi. Foydalanuvchi baribir
  /// ko'rib chiqib, o'zi "Saqlash"ni bosishi kerak.
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialStreet;
  final String? initialHouseNumber;

  const EditProfileScreen({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialStreet,
    this.initialHouseNumber,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  DateTime? _birthDate;
  UserGender? _gender;
  String? _photoUrl;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    super.dispose();
  }

  void _fillFromProfile(UserProfile profile) {
    if (_initialized) return;
    _firstNameController.text = widget.initialFirstName ?? profile.firstName;
    _lastNameController.text = widget.initialLastName ?? profile.lastName;
    _streetController.text =
        widget.initialStreet ?? profile.street ?? '';
    _houseNumberController.text =
        widget.initialHouseNumber ?? profile.houseNumber ?? '';
    _birthDate = profile.birthDate;
    _gender = profile.gender;
    _photoUrl = profile.photoUrl;
    _initialized = true;
  }

  /// Jonli (GIF) avatar uchun eng katta ruxsat etilgan hajm.
  ///
  /// GIF qayta kodlanmagani uchun galereyadagi hajmi qanday bo'lsa
  /// shundayligicha yuklanadi — cheklovsiz qoldirilsa 20-30 MB fayl
  /// ham tushib, ro'yxatlar sekinlashib ketardi.
  static const int _maxAnimatedBytes = 5 * 1024 * 1024;

  bool get _isPremium =>
      ref.read(currentUserProfileProvider).valueOrNull?.isPremiumActive ==
      true;

  /// Kamera belgisi bosilganda chaqiriladi. Premium bo'lmagan
  /// foydalanuvchida to'g'ridan-to'g'ri rasm tanlash oynasi ochiladi
  /// (oldingi xatti-harakat o'zgarmagan). Premium obunachida esa —
  /// `MediaPickerGrid`dagi rasm/video tanlash varag'i bilan bir xil
  /// uslubda — "Rasm" yoki "Video" tanlash varag'i chiqadi, video
  /// tanlansa avtomatik jonli GIF avatarga aylantiriladi.
  Future<void> _onAvatarTap() async {
    if (!_isPremium) {
      await _pickAndUploadPhoto();
      return;
    }

    final choice = await showModalBottomSheet<_AvatarSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = sheetContext.isDarkMode;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(PhosphorIconsFill.image),
                  title: Text(AppLocalizations.of(sheetContext).avatarSourceImage),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_AvatarSource.image),
                ),
                ListTile(
                  leading: const Icon(PhosphorIconsFill.videoCamera),
                  title: Text(AppLocalizations.of(sheetContext).avatarSourceVideo),
                  subtitle:
                      Text(AppLocalizations.of(sheetContext).avatarSourceVideoHint),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_AvatarSource.video),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (choice == null || !mounted) return;

    if (choice == _AvatarSource.image) {
      await _pickAndUploadPhoto();
    } else {
      await _pickAndUploadVideoAsGif();
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final l10n = AppLocalizations.of(context);
    final isPremium = _isPremium;
    final picker = ImagePicker();

    // Oddiy foydalanuvchida rasm siqiladi (80% sifat, 800px) — bu
    // trafikni tejaydi, lekin ANIMATSIYANI YO'Q QILADI: GIF bitta
    // qimirlamaydigan kadrga aylanadi.
    //
    // Premium obunachida esa fayl qanday bo'lsa shundayligicha
    // olinadi, shuning uchun jonli GIF avatar ishlaydi
    // (`premiumBenefitAnimatedAvatar`).
    final picked = isPremium
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
            maxWidth: 800,
          );
    if (picked == null) return;

    if (isPremium) {
      final size = await File(picked.path).length();
      if (size > _maxAnimatedBytes) {
        if (!mounted) return;
        showAppAlert(context, l10n.photoTooLarge);
        return;
      }
    }

    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref
          .read(authRepositoryProvider)
          .updateProfilePhoto(File(picked.path));
      if (!mounted) return;
      setState(() => _photoUrl = url);
      ref.invalidate(currentUserProfileProvider);
    } on ImageUploadException catch (e) {
      if (mounted) {
        showAppAlert(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showAppAlert(context, l10n.photoUploadError);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  /// Premium — galereyadan video tanlab, BIRINCHI 4 soniyasini
  /// avtomatik jonli GIF avatarga aylantiradi (`ffmpeg_kit_flutter_new`
  /// orqali mahalliy, qurilmaning o'zida konvertatsiya qilinadi —
  /// serverga video umuman yuborilmaydi, faqat tayyor GIF yuklanadi).
  Future<void> _pickAndUploadVideoAsGif() async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedVideo == null) return;

    setState(() => _uploadingPhoto = true);
    final outputPath =
        '${Directory.systemTemp.path}/mahallam_avatar_${DateTime.now().millisecondsSinceEpoch}.gif';
    File? outputFile;
    try {
      // -t 4: faqat birinchi 4 soniya. fps=12/scale=320: avatar
      // hajmida ortiqcha katta/silliq bo'lishning hojati yo'q — fayl
      // hajmini (va shu bilan yuklash vaqtini) kamaytiradi.
      final session = await FFmpegKit.execute(
        '-y -i "${pickedVideo.path}" -t 4 '
        '-vf "fps=12,scale=320:-1:flags=lanczos" -loop 0 "$outputPath"',
      );
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        if (mounted) showAppAlert(context, l10n.videoToGifError);
        return;
      }

      outputFile = File(outputPath);
      if (!await outputFile.exists()) {
        if (mounted) showAppAlert(context, l10n.videoToGifError);
        return;
      }

      final size = await outputFile.length();
      if (size > _maxAnimatedBytes) {
        if (mounted) showAppAlert(context, l10n.photoTooLarge);
        return;
      }

      final url = await ref
          .read(authRepositoryProvider)
          .updateProfilePhoto(outputFile);
      if (!mounted) return;
      setState(() => _photoUrl = url);
      ref.invalidate(currentUserProfileProvider);
    } on ImageUploadException catch (e) {
      if (mounted) showAppAlert(context, e.message);
    } catch (_) {
      if (mounted) showAppAlert(context, l10n.videoToGifError);
    } finally {
      // Vaqtinchalik GIF fayli yuklangandan (yoki xato bo'lgandan)
      // keyin endi kerak emas — qurilma xotirasida to'planib
      // qolmasligi uchun tozalanadi.
      if (outputFile != null && await outputFile.exists()) {
        await outputFile.delete();
      }
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            street: _streetController.text.trim(),
            houseNumber: _houseNumberController.text.trim(),
            birthDate: _birthDate,
            gender: _gender,
          );
      if (mounted) {
        ref.invalidate(currentUserProfileProvider);
        showAppAlert(context, l10n.profileSaved);
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      if (mounted) {
        showAppAlert(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showAppAlert(context, l10n.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      // AppBar ataylab yo'q: sarlavha va avatar profil bannerining
      // USTIDA turadi — Profil ekrani bilan bir xil ko'rinish, ya'ni
      // "Mening ma'lumotlarim" o'sha profilning davomi bo'lib
      // his qilinadi, butunlay boshqa ekran emas.
      body: profileAsync.when(
          data: (profile) {
            if (profile != null) _fillFromProfile(profile);
            final banner = bannerById(profile?.profileBannerId);

            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                _BannerHeader(
                  banner: banner,
                  title: l10n.myInfoMenuItem,
                  child: Stack(
                    children: [
                      UserAvatar(
                        size: 96,
                        firstName: _firstNameController.text,
                        lastName: _lastNameController.text,
                        photoUrl: _photoUrl,
                        seed: profile?.phone,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: TapScale(
                          onTap: _uploadingPhoto ? null : _onAvatarTap,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.isDarkMode
                                    ? AppColors.darkBg
                                    : AppColors.lightBg,
                                width: 2.5,
                              ),
                            ),
                            child: _uploadingPhoto
                                ? const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Icon(PhosphorIconsFill.camera,
                                    size: 15, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(l10n.personalInfoSection),
                      // Maydonlar endi bitta kartochka ichida
                      // guruhlanadi va yorliq maydonning O'ZIDA
                      // (floating label) turadi — ilgari har bir
                      // maydon ustida alohida kulrang matn bor edi va
                      // ekran uzun, tarqoq ro'yxatga o'xshardi.
                      AppCard(
                        child: Column(
                          children: [
                      TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.firstNameLabel,
                          prefixIcon:
                              const Icon(PhosphorIconsRegular.user, size: 18),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? l10n.firstNameValidationError
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.lastNameLabel,
                          prefixIcon: const Icon(PhosphorIconsRegular.identificationCard,
                              size: 18),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? l10n.lastNameValidationError
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: AppRadius.smAll,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.birthDateLabel,
                            prefixIcon: const Icon(PhosphorIconsRegular.cake,
                                size: 18),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _birthDate != null
                                    ? _formatDate(_birthDate!)
                                    : l10n.selectDate,
                                style: TextStyle(
                                  color: _birthDate != null
                                      ? null
                                      : context.textSecondary,
                                ),
                              ),
                              Icon(PhosphorIconsRegular.calendar,
                                  size: 18, color: context.textSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(l10n.genderLabel,
                          style: context.captionStyle),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _GenderChip(
                              label: l10n.genderMale,
                              isSelected: _gender == UserGender.male,
                              onTap: () =>
                                  setState(() => _gender = UserGender.male),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _GenderChip(
                              label: l10n.genderFemale,
                              isSelected: _gender == UserGender.female,
                              onTap: () =>
                                  setState(() => _gender = UserGender.female),
                            ),
                          ),
                        ],
                      ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      _SectionLabel(l10n.addressSection),
                      AppCard(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: l10n.streetLabel,
                                hintText: l10n.streetHint,
                                prefixIcon: const Icon(
                                    PhosphorIconsRegular.roadHorizon,
                                    size: 18),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _houseNumberController,
                              decoration: InputDecoration(
                                labelText: l10n.houseNumberLabel,
                                hintText: l10n.houseNumberHint,
                                prefixIcon: const Icon(
                                    PhosphorIconsRegular.houseLine,
                                    size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),

                      ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.saveButton),
                      ),
                    ],
                  ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              l10n.profileLoadError,
              style: context.secondaryStyle,
            ),
          ),
        ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (context.isDarkMode
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightBorder),
          borderRadius: AppRadius.smAll,
        ),
        child: Text(
          label,
          style: context.cardTitleStyle.copyWith(
            color: isSelected ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
/// Forma ichidagi bo'lim sarlavhasi ("Shaxsiy ma'lumotlar", "Manzil").
///
/// Ilgari bu ekran 6 ta maydonning uzluksiz ro'yxati edi — qaysi
/// maydon nimaga tegishli ekani ko'rinmasdi.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text.toUpperCase(),
        style: context.captionStyle.copyWith(
          color: context.textMuted,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Profil banneri fon sifatida turadigan ekran sarlavhasi.
///
/// Profil ekranidagi qopqoq bilan bir xil banner ishlatiladi, shuning
/// uchun "Mening ma'lumotlarim" o'sha profilning davomi bo'lib
/// ko'rinadi — ilgari bu yerda oddiy kulrang AppBar turardi va ekran
/// butunlay boshqa ilovadan kelgandek his qilinardi.
class _BannerHeader extends StatelessWidget {
  final ProfileBanner banner;
  final String title;

  /// Banner ustida, markazda turadigan widget (avatar).
  final Widget child;

  const _BannerHeader({
    required this.banner,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: banner.decoration().copyWith(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          // Profil ekranidagi bilan bir xil qorong'ulashtirish —
          // bannerdan qat'i nazar oq matn o'qiladi.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            child: Column(
              children: [
                Row(
                  children: [
                    LiquidGlassBackButton(iconColor: Colors.white),
                    Expanded(
                      child: Text(
                        title,
                        style: context.titleStyle.copyWith(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxl),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _AvatarSource { image, video }
