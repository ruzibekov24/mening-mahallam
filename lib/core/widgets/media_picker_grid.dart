import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';

/// Rasm va video biriktirish uchun kvadrat kartochkalar grid'i —
/// tanlangan mediyalar ko'rsatiladi (video uchun play belgisi bilan),
/// har biriga o'chirish (x) belgisi, va oxirida "+" tugmasi bosilganda
/// rasm yoki video tanlash so'raladi.
class MediaPickerGrid extends StatelessWidget {
  final List<MediaFile> mediaFiles;
  final ValueChanged<List<MediaFile>> onChanged;
  final int maxItems;

  const MediaPickerGrid({
    super.key,
    required this.mediaFiles,
    required this.onChanged,
    this.maxItems = 5,
  });

  Future<void> _showPickerOptions(BuildContext context) async {
    final isDark = context.isDarkMode;
    final choice = await showModalBottomSheet<_PickChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
                  leading: const Icon(PhosphorIconsRegular.imagesSquare),
                  title: const Text('Rasm'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PickChoice.image),
                ),
                ListTile(
                  leading: const Icon(PhosphorIconsRegular.videoCamera),
                  title: const Text('Video'),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PickChoice.video),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;

    final picker = ImagePicker();
    if (choice == _PickChoice.image) {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked == null) return;
      onChanged([
        ...mediaFiles,
        MediaFile(file: File(picked.path), type: MediaType.image),
      ]);
    } else {
      final picked = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null) return;
      onChanged([
        ...mediaFiles,
        MediaFile(file: File(picked.path), type: MediaType.video),
      ]);
    }
  }

  void _removeAt(int index) {
    final updated = [...mediaFiles]..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...mediaFiles.asMap().entries.map((entry) {
          final index = entry.key;
          final media = entry.value;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: media.type == MediaType.image
                    ? Image.file(
                        media.file,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 84,
                        height: 84,
                        color: Colors.black87,
                        alignment: Alignment.center,
                        child: const Icon(
                          PhosphorIconsFill.playCircle,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeAt(index),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsBold.x,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        }),
        if (mediaFiles.length < maxItems)
          GestureDetector(
            onTap: () => _showPickerOptions(context),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Icon(
                PhosphorIconsRegular.imagesSquare,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

enum _PickChoice { image, video }
