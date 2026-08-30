import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../theme/app_theme.dart';

/// Bold, italic, heading, quote va ro'yxat kabi formatlashni
/// qo'llab-quvvatlaydigan matn muharriri. E'lon va murojaat
/// yaratishda ishlatiladi. Natija Quill Delta JSON ko'rinishida
/// [controller.document.toDelta().toJson()] orqali olinadi.
class RichTextEditorField extends StatefulWidget {
  final QuillController controller;
  final String hintText;
  final double minHeight;

  const RichTextEditorField({
    super.key,
    required this.controller,
    required this.hintText,
    this.minHeight = 160,
  });

  @override
  State<RichTextEditorField> createState() => _RichTextEditorFieldState();
}

class _RichTextEditorFieldState extends State<RichTextEditorField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final borderColor = isDark
        ? AppColors.darkTextSecondary.withValues(alpha: 0.2)
        : AppColors.lightTextSecondary.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      // flutter_quill o'zbek tilini (uz) tarjima sifatida qo'llab-
      // quvvatlamaydi, shuning uchun Quill widgetlari ichida ruscha
      // locale bilan ishlaymiz — bu ilovaning umumiy tiliga
      // ta'sir qilmaydi, faqat editor/toolbar ichki matnlariga
      // (masalan tugma tooltiplariga) tegadi.
      child: Localizations.override(
        context: context,
        locale: const Locale('ru'),
        child: Column(
          children: [
            QuillSimpleToolbar(
              controller: widget.controller,
              config: const QuillSimpleToolbarConfig(
                showFontFamily: false,
                showFontSize: false,
                showColorButton: false,
                showBackgroundColorButton: false,
                showClearFormat: false,
                showAlignmentButtons: false,
                showLeftAlignment: false,
                showCenterAlignment: false,
                showRightAlignment: false,
                showJustifyAlignment: false,
                showDirection: false,
                showSearchButton: false,
                showSubscript: false,
                showSuperscript: false,
                showIndent: false,
                showLink: false,
                showUndo: false,
                showRedo: false,
                multiRowsDisplay: false,
                toolbarSize: 38,
              ),
            ),
            Container(
              height: 1,
              color: borderColor,
            ),
            Container(
              constraints: BoxConstraints(minHeight: widget.minHeight),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: QuillEditor.basic(
                controller: widget.controller,
                focusNode: _focusNode,
                config: QuillEditorConfig(
                  placeholder: widget.hintText,
                  padding: EdgeInsets.zero,
                  expands: false,
                  scrollable: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faqat o'qish uchun — Quill Delta JSON matnini formatlangan
/// holda ko'rsatadi. Agar matn Delta formatida bo'lmasa (eski,
/// oddiy String sifatida saqlangan yozuvlar), oddiy Text sifatida
/// ko'rsatiladi — orqaga moslik uchun.
class RichTextViewer extends StatelessWidget {
  final String rawContent;
  final TextStyle? plainStyle;

  const RichTextViewer({
    super.key,
    required this.rawContent,
    this.plainStyle,
  });

  @override
  Widget build(BuildContext context) {
    final document = _tryParseDelta(rawContent);
    if (document == null) {
      // Eski yozuvlar — oddiy matn sifatida ko'rsatiladi.
      return Text(rawContent, style: plainStyle);
    }

    final controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );

    return Localizations.override(
      context: context,
      locale: const Locale('ru'),
      child: QuillEditor.basic(
        controller: controller,
        config: const QuillEditorConfig(
          padding: EdgeInsets.zero,
          expands: false,
          scrollable: false,
          showCursor: false,
        ),
      ),
    );
  }

  Document? _tryParseDelta(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return Document.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}