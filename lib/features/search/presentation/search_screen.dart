import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../polls/presentation/polls_screen.dart';
import '../../services/presentation/services_screen.dart';
import '../data/search_repository.dart';

extension on SearchResultKind {
  IconData get icon {
    switch (this) {
      case SearchResultKind.announcement:
        return PhosphorIconsFill.megaphone;
      case SearchResultKind.event:
        return PhosphorIconsFill.calendarCheck;
      case SearchResultKind.request:
        return PhosphorIconsFill.chatCircleDots;
      case SearchResultKind.service:
        return PhosphorIconsFill.toolbox;
      case SearchResultKind.poll:
        return PhosphorIconsFill.chartBar;
    }
  }

  Color get color {
    switch (this) {
      case SearchResultKind.announcement:
        return AppAccents.announcements;
      case SearchResultKind.event:
        return AppAccents.events;
      case SearchResultKind.request:
        return AppAccents.requests;
      case SearchResultKind.service:
        return AppAccents.neighbors;
      case SearchResultKind.poll:
        return AppAccents.neighbors;
    }
  }
}

/// Ilova bo'ylab qidiruv — e'lonlar, tadbirlar va (ruxsat doirasida)
/// murojaatlar bo'yicha. Firestore to'liq matnli qidiruvni
/// qo'llamagani uchun natijalar client darajasida filtrlanadi.
class SearchScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const SearchScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  SearchResultKind? _selectedKind; // null = hammasi

  @override
  void initState() {
    super.initState();
    // Ekran ochilganda klaviatura darhol chiqsin — foydalanuvchi
    // qidiruv maydonini alohida bosishi shart emas.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Har bosilgan harfda emas, 250ms kutib so'ng qidiruvni
    // ishga tushiramiz — Firestore stream'larni keraksiz qayta
    // ishlatmaslik uchun.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  String _kindLabel(AppLocalizations l10n, SearchResultKind kind) {
    switch (kind) {
      case SearchResultKind.announcement:
        return l10n.categoryAnnouncements;
      case SearchResultKind.event:
        return l10n.categoryEvents;
      case SearchResultKind.request:
        return l10n.categoryRequests;
      case SearchResultKind.service:
        return l10n.categoryServices;
      case SearchResultKind.poll:
        return l10n.categoryPolls;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final resultsAsync = _query.isEmpty
        ? null
        : ref.watch(searchResultsProvider(
            (mahallaId: widget.mahallaId, query: _query),
          ));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.sm),
              child: Row(
                children: [
                  const LiquidGlassBackButton(),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: AppShadows.card(context.isDarkMode),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsBold.magnifyingGlass,
                              size: 18, color: context.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              onChanged: _onChanged,
                              decoration: InputDecoration(
                                hintText: l10n.searchHint,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              style: context.bodyStyle,
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            TapScale(
                              onTap: () {
                                _controller.clear();
                                _debounce?.cancel();
                                setState(() => _query = '');
                              },
                              child: Icon(PhosphorIconsFill.xCircle,
                                  size: 18, color: context.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? AppEmptyView(
                      icon: PhosphorIconsFill.magnifyingGlass,
                      title: l10n.searchPromptText,
                    )
                  : resultsAsync!.when(
                      data: (allResults) {
                        if (allResults.isEmpty) {
                          return AppEmptyView(
                            icon: PhosphorIconsFill.magnifyingGlass,
                            title: l10n.searchNoResults,
                            scrollable: true,
                          );
                        }
                        final counts = <SearchResultKind?, int>{
                          null: allResults.length,
                          for (final kind in SearchResultKind.values)
                            kind: allResults.where((r) => r.kind == kind).length,
                        };
                        final results = _selectedKind == null
                            ? allResults
                            : allResults
                                .where((r) => r.kind == _selectedKind)
                                .toList();
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                                  0, AppSpacing.xl, AppSpacing.sm),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    AppFilterChip(
                                      label: l10n.allFilter,
                                      count: counts[null],
                                      isActive: _selectedKind == null,
                                      onTap: () =>
                                          setState(() => _selectedKind = null),
                                    ),
                                    for (final kind in SearchResultKind.values) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      AppFilterChip(
                                        label: _kindLabel(l10n, kind),
                                        count: counts[kind],
                                        isActive: _selectedKind == kind,
                                        onTap: () => setState(
                                            () => _selectedKind = kind),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: results.isEmpty
                                  ? AppEmptyView(
                                      icon: PhosphorIconsFill.magnifyingGlass,
                                      title: l10n.searchNoResults,
                                      scrollable: true,
                                    )
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          AppSpacing.xl,
                                          AppSpacing.xs,
                                          AppSpacing.xl,
                                          AppSpacing.xxl),
                                      itemCount: results.length,
                                      itemBuilder: (context, index) {
                                        final result = results[index];
                                        return StaggeredEntrance(
                                          index: index,
                                          child: _SearchResultTile(
                                            result: result,
                                            icon: result.kind.icon,
                                            color: result.kind.color,
                                            kindLabel:
                                                _kindLabel(l10n, result.kind),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                      loading: () => ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                            AppSpacing.xs, AppSpacing.xl, AppSpacing.xxl),
                        physics: const NeverScrollableScrollPhysics(),
                        children: const [
                          ShimmerListTile(),
                          ShimmerListTile(),
                          ShimmerListTile(),
                        ],
                      ),
                      error: (error, _) => AppErrorView.fromError(error),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final IconData icon;
  final Color color;
  final String kindLabel;

  const _SearchResultTile({
    required this.result,
    required this.icon,
    required this.color,
    required this.kindLabel,
  });

  VoidCallback? _onTap(BuildContext context) {
    switch (result.kind) {
      case SearchResultKind.service:
        return () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ServicesScreen()),
            );
      case SearchResultKind.poll:
        return () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PollsScreen()),
            );
      case SearchResultKind.announcement:
      case SearchResultKind.event:
      case SearchResultKind.request:
        // E'lon/tadbir/murojaat uchun hozircha aniq detail ekrani yo'q —
        // bu turlar tarixan bosilganda hech qayerga o'tmagan, shu bilan
        // izchillik saqlanadi.
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      icon: icon,
      accent: color,
      title: result.title,
      subtitle: result.subtitle.isNotEmpty ? result.subtitle : null,
      onTap: _onTap(context),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.xsAll,
        ),
        child: Text(kindLabel, style: context.captionStyle.copyWith(color: color)),
      ),
    );
  }
}
