/// The hotel results filter sheet and its applied-filter rail.
///
/// Mirrors the website's hotel sidebar: a name search, then Star rating, Price
/// range, Property type, Meal plan, Cancellation and Amenities, each option
/// carrying the number of hotels it would leave. The footer previews the match
/// count live, so a narrow combination is visible before it is applied.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/hotel_filters.dart';
import '../../models/honeymoon_models.dart';

/// Opens the sheet and resolves to the chosen filters, or null when dismissed.
Future<HotelFilters?> showHotelFilterSheet(
  BuildContext context, {
  required List<HotelFacetGroup> facets,
  required HotelFilters current,
  required List<HotelResult> hotels,
}) {
  return showModalBottomSheet<HotelFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
    builder: (_) =>
        _HotelFilterSheet(facets: facets, current: current, hotels: hotels),
  );
}

class _HotelFilterSheet extends StatefulWidget {
  const _HotelFilterSheet({
    required this.facets,
    required this.current,
    required this.hotels,
  });

  final List<HotelFacetGroup> facets;
  final HotelFilters current;
  final List<HotelResult> hotels;

  @override
  State<_HotelFilterSheet> createState() => _HotelFilterSheetState();
}

class _HotelFilterSheetState extends State<_HotelFilterSheet> {
  late HotelFilters _draft = widget.current;
  late final TextEditingController _name = TextEditingController(
    text: widget.current.nameQuery,
  );

  /// Long option lists collapse to the first few, with a "show all" toggle —
  /// amenities in particular can run to dozens of entries.
  final Set<HotelFilterGroup> _expandedGroups = {};
  static const int _collapsedLimit = 6;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _matchCount => filterHotels(widget.hotels, _draft).length;

  void _update(HotelFilters next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final count = _matchCount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(),
              const Divider(height: 1, color: AppColors.divider),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  children: [
                    AppTextField(
                      controller: _name,
                      hint: 'Search by hotel name',
                      prefixIcon: Icons.search_rounded,
                      onChanged: (v) => _update(_draft.withName(v)),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final group in widget.facets) _group(group),
                  ],
                ),
              ),
              _footer(count),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final active = _draft.activeCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text('Filters', style: AppText.sectionTitle),
                if (active > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadii.rPill,
                    ),
                    child: Text(
                      '$active',
                      style: AppText.labelSm.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (active > 0)
            PremiumButton.text(
              label: 'Reset all',
              size: PremiumButtonSize.small,
              onPressed: () {
                _name.clear();
                _update(HotelFilters.empty);
              },
            ),
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _footer(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: PremiumButton(
        label: count == 0
            ? 'No stays match'
            : 'Show $count stay${count == 1 ? '' : 's'}',
        onPressed: count == 0 ? null : () => Navigator.of(context).pop(_draft),
      ),
    );
  }

  Widget _group(HotelFacetGroup group) {
    final expanded = _expandedGroups.contains(group.group);
    final options = expanded
        ? group.options
        : group.options.take(_collapsedLimit).toList();
    final hidden = group.options.length - options.length;
    final selected = _draft.of(group.group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selected.isEmpty
                      ? group.group.label
                      : '${group.group.label} (${selected.length})',
                  style: AppText.bodyStrong.copyWith(
                    color: selected.isEmpty
                        ? AppColors.textPrimary
                        : AppColors.primary,
                  ),
                ),
              ),
              if (selected.isNotEmpty)
                PremiumButton.text(
                  label: 'Clear',
                  size: PremiumButtonSize.small,
                  onPressed: () => _update(_draft.clearGroup(group.group)),
                ),
            ],
          ),
        ),

        // Star ratings read better as a row of compact pills than as a
        // checkbox list; everything else stays a list so long labels wrap.
        if (group.group == HotelFilterGroup.ratings)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final o in group.options)
                _starPill(
                  option: o,
                  selected: selected.contains(o.value),
                  onTap: () => _update(_draft.toggle(group.group, o.value)),
                ),
            ],
          )
        else
          Column(
            children: [
              for (final o in options)
                _checkRow(
                  label: o.label,
                  count: o.count,
                  checked: selected.contains(o.value),
                  onChanged: () => _update(_draft.toggle(group.group, o.value)),
                ),
              if (hidden > 0 || expanded)
                Align(
                  alignment: Alignment.centerLeft,
                  child: PremiumButton.text(
                    label: expanded ? 'Show less' : 'Show $hidden more',
                    size: PremiumButtonSize.small,
                    onPressed: () => setState(() {
                      if (!_expandedGroups.remove(group.group)) {
                        _expandedGroups.add(group.group);
                      }
                    }),
                  ),
                ),
            ],
          ),

        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _starPill({
    required HotelFacetItem option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.pinkSurface : AppColors.surface,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
            const SizedBox(width: AppSpacing.xxs),
            Text(option.value, style: AppText.labelSm),
            const SizedBox(width: AppSpacing.xs),
            Text('(${option.count})', style: AppText.caption),
          ],
        ),
      ),
    );
  }

  Widget _checkRow({
    required String label,
    required int count,
    required bool checked,
    required VoidCallback onChanged,
  }) {
    return Pressable(
      onTap: onChanged,
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: AppColors.primary,
                side: const BorderSide(color: AppColors.divider, width: 1.5),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppText.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('$count', style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Applied-filter rail
// ---------------------------------------------------------------------------

/// Horizontal rail of removable chips for whatever hotel filters are applied.
class HotelAppliedFiltersRail extends StatelessWidget {
  const HotelAppliedFiltersRail({
    super.key,
    required this.chips,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<HotelFilterChip> chips;
  final ValueChanged<HotelFilterChip> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: chips.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i == chips.length) {
            return Center(
              child: PremiumButton.text(
                label: 'Clear all',
                size: PremiumButtonSize.small,
                onPressed: onClearAll,
              ),
            );
          }
          final chip = chips[i];
          return Center(
            child: Pressable(
              onTap: () => onRemove(chip),
              borderRadius: AppRadii.rPill,
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pinkSurface,
                  borderRadius: AppRadii.rPill,
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chip.label,
                      style: AppText.labelSm.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
