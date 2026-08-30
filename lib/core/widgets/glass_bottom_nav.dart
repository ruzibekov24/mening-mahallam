import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// iOS 26 "Liquid Glass" uslubidagi pastki navigatsiya — 5 ta tab.
///
/// v8: pill endi "sirg'alib yurgandek" tuyuladi — avval tap
/// qilinganda pill hamma masofani (masalan Asosiy'dan Profilgacha,
/// 4 ta item) bir xil qisqa vaqtda (260ms) bosib o'tar, tezligi
/// masofaga qarab keskin oshib ketgani uchun bu "otilib/teleport
/// bo'lib ketish" hissini bergan edi. Endi:
///   - Davomiylik bosib o'tiladigan masofaga (necha item) qarab
///     hisoblanadi: qo'shni tabga tez (220ms), uzoq tabga picha
///     uzoqroq (item boshiga +90ms, maks 480ms) — shu orqali pill
///     haqiqatan ham oraliq itemlar ustidan "yurib o'tayotgandek"
///     ko'rinadi.
///   - Curves.easeOutCubic -> Curves.easeInOutCubic: boshida ham,
///     oxirida ham yumshoq tezlanish/sekinlanish, o'rtada esa
///     barqaror harakat — "sakrash" emas, "sirg'alish".
///
/// Oldingi tuzatishlar (v7): ikonka+label bar balandligining aniq
/// o'rtasida (Center bilan), pill burchagi o'rtacha dumaloq
/// (borderRadius 22).
///
/// Ishlatish avvalgidek (Material Icons bilan):
/// ```dart
/// GlassBottomNav(
///   items: const [
///     GlassNavItem(icon: Icons.home_rounded, label: 'Asosiy'),
///     GlassNavItem(icon: Icons.newspaper_rounded, label: "E'lonlar"),
///     GlassNavItem(icon: Icons.chat_bubble_rounded, label: 'Murojaat'),
///     GlassNavItem(icon: Icons.people_alt_rounded, label: "Qo'shni"),
///     GlassNavItem(icon: Icons.person_rounded, label: 'Profil'),
///   ],
///   currentIndex: currentIndex,
///   onTap: onTap,
/// ),
/// ```
class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;

  /// Shu bo'lim tanlanganda ikonka/label rangi — berilmasa
  /// `GlassBottomNav.accentColor` ishlatiladi. Har bir tab o'zining
  /// brend rangini olib yurishi uchun (ekran sarlavhasidagi
  /// aksent rang bilan bir xil), premium va izchil ko'rinish beradi.
  final Color? color;
}

class GlassBottomNav extends StatefulWidget {
  const GlassBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.accentColor,
  });

  final List<GlassNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? accentColor;

  @override
  State<GlassBottomNav> createState() => _GlassBottomNavState();
}

class _GlassBottomNavState extends State<GlassBottomNav>
    with SingleTickerProviderStateMixin {
  int? _dragIndex;
  bool _dragging = false;

  /// Barmoqning qatordagi joriy X koordinatasi (drag paytida).
  double? _dragDx;
  double _dragVelocity = 0;
  double _lastDragDx = 0;

  /// Qatorning eni — drag tugaganda pufakchaning barmoq ostidagi
  /// joyini indeksga aylantirish uchun kerak.
  double _rowWidth = 0;

  // ---------------------------------------------------------------
  // SUYUQ PUFAKCHA (liquid blob) animatsiyasi.
  //
  // Ilgari pill oddiy `AnimatedPositioned` bilan bir butun holda
  // surilardi — o'lchami o'zgarmasdi, ya'ni qattiq kapsula bir
  // joydan ikkinchisiga ko'chardi. iOS 26 dagi ta'sir esa boshqacha:
  // pufakcha harakat boshida OLDINGI cheti bilan oldinga otiladi,
  // orqa cheti kechikib ergashadi — natijada u yo'l o'rtasida
  // cho'zilib, ikki tabni qamrab oladi, keyin oldinga yetib olib
  // yana yig'iladi.
  //
  // Buni bitta pozitsiya qiymati bilan qilib bo'lmaydi. Shuning
  // uchun pillning CHAP va O'NG chetlari alohida hisoblanadi va
  // ularga BOSHQA-BOSHQA egri chiziqlar beriladi: yetakchi chet tez
  // (easeOutQuart), ergashuvchi chet sekin (easeInOutCubic). Ikkalasi
  // ham t=1 da bir xil joyga keladi, shuning uchun oxirida pill aniq
  // o'z katagida to'xtaydi.
  // ---------------------------------------------------------------
  late final AnimationController _blob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// Animatsiya boshlangan va tugaydigan nuqtalar — item indeksi
  /// ko'rinishida (kasr bo'lishi mumkin: drag'dan keyin).
  late double _fromIndex = widget.currentIndex.toDouble();
  late double _toIndex = widget.currentIndex.toDouble();

  static const _outerHPad = 18.0;
  static const _innerHPad = 6.0;
  static const _barHeight = 66.0;
  static const _pillHeight = 54.0;

  /// Masofaga qarab davomiylik: qo'shni tabga tez, uzoqqa sekinroq —
  /// lekin cheksiz emas.
  Duration _travelDuration(double distance) {
    final ms = (200 + distance.abs() * 85).clamp(200.0, 460.0);
    return Duration(milliseconds: ms.round());
  }

  @override
  void dispose() {
    _blob.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GlassBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      // Harakat DAVOM ETAYOTGAN joyidan boshlanadi, eski indeksdan
      // emas — aks holda tez-tez bosilganda pill orqaga sakrardi.
      _fromIndex = _currentBlobIndex();
      _toIndex = widget.currentIndex.toDouble();
      _blob
        ..duration = _travelDuration(_toIndex - _fromIndex)
        ..forward(from: 0);
    }
  }

  /// Pillning shu lahzadagi "o'rtacha" joylashuvi (indeks bo'yicha).
  double _currentBlobIndex() {
    if (!_blob.isAnimating) return _toIndex;
    return _fromIndex + (_toIndex - _fromIndex) * _blob.value;
  }

  /// Pillning chap va o'ng chetlari — indeks birligida.
  ///
  /// Qaytadigan qiymat: (chap, o'ng). Masalan (1.0, 2.0) — pill aynan
  /// 2-katakni egallagan; (1.0, 2.6) — cho'zilgan holat.
  (double, double) _blobEdges() {
    // Drag paytida pufakcha barmoqni kuzatadi va tezlikka qarab
    // cho'ziladi — bu yerda ham bir xil mantiq: harakat yo'nalishi
    // bo'yicha yetakchi chet uzoqroqqa chiqadi.
    if (_dragging && _dragDx != null) {
      return (0, 0); // haqiqiy qiymat build ichida hisoblanadi
    }

    final t = _blob.value;
    final forward = _toIndex >= _fromIndex;

    // Yetakchi chet — tez, ergashuvchi — sekin.
    final lead = Curves.easeOutQuart.transform(t);
    final trail = Curves.easeInOutCubic.transform(t);

    if (forward) {
      // O'ngga: o'ng chet yetakchi.
      final left = _fromIndex + (_toIndex - _fromIndex) * trail;
      final right =
          (_fromIndex + 1) + ((_toIndex + 1) - (_fromIndex + 1)) * lead;
      return (left, right);
    } else {
      // Chapga: chap chet yetakchi.
      final left = _fromIndex + (_toIndex - _fromIndex) * lead;
      final right =
          (_fromIndex + 1) + ((_toIndex + 1) - (_fromIndex + 1)) * trail;
      return (left, right);
    }
  }

  int _indexFromLocalDx(double dx, double rowWidth) {
    final itemWidth = rowWidth / widget.items.length;
    final index = (dx / itemWidth).floor();
    return index.clamp(0, widget.items.length - 1);
  }

  void _handleUpdate(double localDx, double rowWidth) {
    _rowWidth = rowWidth;
    final index = _indexFromLocalDx(localDx, rowWidth);
    setState(() {
      // Tezlik — oxirgi ikki kadr orasidagi farq. Pillni harakat
      // yo'nalishi bo'ylab biroz cho'zish uchun ishlatiladi: aynan
      // shu cho'zilish "suyuq pufakcha" hissini beradi, qattiq
      // to'rtburchakning surilishi emas.
      _dragVelocity = localDx - _lastDragDx;
      _lastDragDx = localDx;
      _dragDx = localDx;
      if (index != _dragIndex) {
        _dragIndex = index;
        HapticFeedback.selectionClick();
      }
    });
  }

  void _handleEnd() {
    final finalIndex = _dragIndex;
    final releaseDx = _dragDx;

    // Pufakcha barmoq QO'YIB YUBORILGAN joydan cho'kishi kerak.
    //
    // Ilgari drag tugashi bilan `_dragging` false bo'lardi va pill
    // darhol eski katagiga qaytib, keyin yangisiga uchardi — ya'ni
    // ko'z oldida sakrardi. Endi animatsiya aynan barmoq turgan
    // nuqtadan boshlanadi.
    if (releaseDx != null && _rowWidth > 0 && finalIndex != null) {
      final itemWidth = _rowWidth / widget.items.length;
      final centerIdx = releaseDx / itemWidth;
      _fromIndex = (centerIdx - 0.5)
          .clamp(0.0, widget.items.length - 1.0);
      _toIndex = finalIndex.toDouble();
      _blob
        ..duration = const Duration(milliseconds: 260)
        ..forward(from: 0);
    }

    setState(() {
      _dragging = false;
      _dragIndex = null;
      _dragDx = null;
      _dragVelocity = 0;
    });

    if (finalIndex != null && finalIndex != widget.currentIndex) {
      widget.onTap(finalIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final inactiveColor =
        isDark ? const Color(0xFFB8B8BE) : const Color(0xFF57575C);

    // Auditdan keyingi tuzatish: blur 30 -> 14 va oq overlay shaffofligi
    // pasaytirildi. sigma 30'da orqadagi kontent butunlay yo'qolib,
    // panel tiniq shisha emas, "oq tunuka" bo'lib ko'rinardi — bu
    // "liquid glass" emas, "muzlatilgan plastinka" edi. Endi orqadagi
    // ranglar/shakllar xira bo'lsa ham ilg'ab bo'ladi.
    final glassGradient = isDark
        ? [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.06),
          ]
        : [
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0.16),
          ];

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.75);

    final selectedPillColor = isDark
        ? Colors.white.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.55);

    final visualIndex =
        _dragging ? (_dragIndex ?? widget.currentIndex) : widget.currentIndex;

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: bottomInset > 0 ? 4 : 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _outerHPad),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: glassGradient,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: borderColor, width: 1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: _innerHPad,
                  vertical: 6,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final rowWidth = constraints.maxWidth;
                    final itemWidth = rowWidth / widget.items.length;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        final index = _indexFromLocalDx(
                          details.localPosition.dx,
                          rowWidth,
                        );
                        if (index != widget.currentIndex) {
                          HapticFeedback.selectionClick();
                          widget.onTap(index);
                        }
                      },
                      onPanStart: (details) {
                        _rowWidth = rowWidth;
                        _lastDragDx = details.localPosition.dx;
                        setState(() {
                          _dragging = true;
                          _dragDx = details.localPosition.dx;
                          _dragIndex = _indexFromLocalDx(
                            details.localPosition.dx,
                            rowWidth,
                          );
                        });
                      },
                      onPanUpdate: (details) {
                        _handleUpdate(details.localPosition.dx, rowWidth);
                      },
                      onPanEnd: (_) => _handleEnd(),
                      onPanCancel: () {
                        setState(() {
                          _dragging = false;
                          _dragIndex = null;
                        });
                      },
                      child: Stack(
                        // Bolalarni default holatda ham markazda
                        // ushlab turadi — Row/pill hisoblashda
                        // xato bo'lsa ham fallback sifatida foydali.
                        alignment: Alignment.center,
                        children: [
                          // SUYUQ PUFAKCHA.
                          //
                          // Chap va o'ng chetlar alohida hisoblanadi:
                          // harakat yo'nalishidagi yetakchi chet tez
                          // egri chiziq bilan (easeOutQuart) oldinga
                          // otiladi, ergashuvchi chet sekinroq
                          // (easeInOutCubic) ergashadi. Natijada
                          // pufakcha yo'l o'rtasida cho'ziladi va
                          // manzilga yetganda yana yig'iladi — iOS 26
                          // dagi "liquid glass" ta'siri shu.
                          AnimatedBuilder(
                            animation: _blob,
                            builder: (context, _) {
                              double leftIdx;
                              double rightIdx;

                              if (_dragging && _dragDx != null) {
                                // Drag: pufakcha markazi barmoqda,
                                // tezlikka qarab yo'nalish bo'ylab
                                // cho'ziladi.
                                final centerIdx = (_dragDx! / itemWidth)
                                    .clamp(0.0, widget.items.length.toDouble());
                                final stretch = (_dragVelocity / itemWidth)
                                    .clamp(-0.55, 0.55);
                                leftIdx = centerIdx - 0.5 +
                                    (stretch < 0 ? stretch : 0);
                                rightIdx = centerIdx + 0.5 +
                                    (stretch > 0 ? stretch : 0);
                              } else {
                                final edges = _blobEdges();
                                leftIdx = edges.$1;
                                rightIdx = edges.$2;
                              }

                              // Chegaradan chiqib ketmasin.
                              final maxIdx = widget.items.length.toDouble();
                              leftIdx = leftIdx.clamp(0.0, maxIdx - 0.35);
                              rightIdx = rightIdx.clamp(leftIdx + 0.35, maxIdx);

                              final left = leftIdx * itemWidth;
                              final width = (rightIdx - leftIdx) * itemWidth;

                              // Cho'zilgan sari pufakcha biroz
                              // yupqalashadi — haqiqiy tomchi ham
                              // cho'zilganda ingichkalashadi. Bu
                              // "qattiq kapsula" hissini yo'qotadi.
                              final stretchRatio =
                                  ((rightIdx - leftIdx) - 1).clamp(0.0, 1.2);
                              final height =
                                  _pillHeight - stretchRatio * 5 +
                                      (_dragging ? 4 : 0);

                              return Positioned(
                                left: left,
                                top: 0,
                                bottom: 0,
                                width: width,
                                child: Center(
                                  child: Container(
                                    height: height,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: _dragging
                                          ? selectedPillColor
                                              .withValues(alpha: 0.85)
                                          : selectedPillColor,
                                      // Burchak radiusi balandlikning
                                      // yarmi — cho'zilganda ham
                                      // chetlari doim to'liq yumaloq
                                      // qoladi, ya'ni tomchiga
                                      // o'xshaydi, cho'zilgan
                                      // to'rtburchakka emas.
                                      borderRadius:
                                          BorderRadius.circular(height / 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: _dragging ? 0.18 : 0.08),
                                          blurRadius: _dragging ? 14 : 6,
                                          offset:
                                              Offset(0, _dragging ? 5 : 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Ikonka + label qatlami — endi Center
                          // orqali bar balandligining aniq o'rtasida
                          // joylashadi (avvalgi versiyada Row to'g'ridan
                          // -to'g'ri Stack ichida edi va tepaga surilib
                          // ko'rinar edi).
                          Center(
                            child: SizedBox(
                              height: _barHeight - 12,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: List.generate(widget.items.length,
                                    (index) {
                                  final item = widget.items[index];
                                  final selected = index == visualIndex;
                                  final color = selected
                                      ? (item.color ?? accent)
                                      : inactiveColor;
                                  return SizedBox(
                                    width: itemWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(item.icon,
                                            size: 24, color: color),
                                        const SizedBox(height: 3),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item.label,
                                            maxLines: 1,
                                            softWrap: false,
                                            style: GoogleFonts.ibmPlexSans(
                                              fontSize: 9,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: color,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}