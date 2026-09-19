/// Browse grooms/brides — ports `src/components/pages/matrimonial/
/// ProfileMatrimonial.jsx` (route `/ProfileMatrimonial/:matchType`).
///
/// The source hardcodes a grid of fake profiles (stock Unsplash photos,
/// invented names like "Rajesh Sharma" / "Priya Sharma") behind a real
/// "Refine Search" filter panel. The filter panel is ported faithfully
/// below — it is real UI structure — but there is no profile directory
/// anywhere in the source to back the grid, so this shows an honest empty
/// state instead of the fabricated cards. See MIGRATION_NOTES.md.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../models/matrimonial_profile.dart';
import 'matrimonial_landing_page.dart' show showMatrimonialGate;

class MatrimonialProfilePage extends StatefulWidget {
  const MatrimonialProfilePage({super.key});

  @override
  State<MatrimonialProfilePage> createState() => _MatrimonialProfilePageState();
}

class _MatrimonialProfilePageState extends State<MatrimonialProfilePage> {
  bool _grooms = true;
  final _filters = MatrimonialBrowseFilters();
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'Matrimony',
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Grooms'),
                    selected: _grooms,
                    onSelected: (_) => setState(() => _grooms = true),
                    selectedColor: AppColors.primary,
                    labelStyle: AppText.labelSm.copyWith(color: _grooms ? Colors.white : AppColors.textSecondary),
                  ),
                ),
                AppSpacing.w8,
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Brides'),
                    selected: !_grooms,
                    onSelected: (_) => setState(() => _grooms = false),
                    selectedColor: AppColors.primary,
                    labelStyle: AppText.labelSm.copyWith(color: !_grooms ? Colors.white : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          if (_showFilters)
            SizedBox(
              height: 340,
              child: _FilterPanel(
                filters: _filters,
                onReset: () => setState(_filters.reset),
                onApply: () => showMatrimonialGate(context, "Search isn't available yet."),
              ),
            ),
          Expanded(
            child: EmptyState(
              icon: Icons.diversity_3_outlined,
              title: 'No profiles available yet',
              message: 'Matrimonial profile matching isn\'t connected to a live directory yet — '
                  'please check back soon.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({required this.filters, required this.onReset, required this.onApply});

  final MatrimonialBrowseFilters filters;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  @override
  Widget build(BuildContext context) {
    final f = widget.filters;
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(child: Text('Refine Search', style: AppText.cardTitle)),
              TextButton.icon(
                onPressed: () => setState(widget.onReset),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reset All'),
              ),
            ],
          ),
          AppSpacing.h12,
          Text('Age: ${f.ageRange.min.round()} – ${f.ageRange.max.round()} yrs', style: AppText.formLabel),
          RangeSlider(
            values: RangeValues(f.ageRange.min, f.ageRange.max),
            min: 16,
            max: 60,
            divisions: 44,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => f.ageRange = AgeRange(v.start, v.end)),
          ),
          AppSpacing.h8,
          Text('Marital Status', style: AppText.formLabel),
          AppSpacing.h8,
          Wrap(
            spacing: AppSpacing.sm,
            children: kMaritalStatuses.map((status) {
              final selected = f.maritalStatuses.contains(status);
              return FilterChip(
                label: Text(status),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    f.maritalStatuses.add(status);
                  } else {
                    f.maritalStatuses.remove(status);
                  }
                }),
                selectedColor: AppColors.pinkSurface,
              );
            }).toList(),
          ),
          AppSpacing.h12,
          Text('Diet', style: AppText.formLabel),
          AppSpacing.h8,
          Wrap(
            spacing: AppSpacing.sm,
            children: kDiets.map((d) {
              final selected = f.diets.contains(d);
              return FilterChip(
                label: Text(d),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    f.diets.add(d);
                  } else {
                    f.diets.remove(d);
                  }
                }),
                selectedColor: AppColors.pinkSurface,
              );
            }).toList(),
          ),
          AppSpacing.h16,
          PremiumButton(label: 'Apply Filters', onPressed: widget.onApply),
        ],
      ),
    );
  }
}
