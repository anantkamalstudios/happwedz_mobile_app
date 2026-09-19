/// Advanced search — ports `src/components/pages/matrimonial/Search.jsx`.
///
/// Both the "Search by Profile ID" and "Search by Category" modes are built
/// with the exact same fields/sections as the source. Neither submit path
/// exists in the source (no fetch/axios call anywhere in `Search.jsx`), so
/// both show an honest gated message instead of empty/fake results dressed
/// up as real ones. See MIGRATION_NOTES.md.
///
/// The mother-tongue list drops the source's two junk placeholder entries
/// ("hdhgjhs", "dfeff") — see `kMotherTongues` in `matrimonial_profile.dart`.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../models/matrimonial_profile.dart';
import 'matrimonial_landing_page.dart' show showMatrimonialGate;

class MatrimonialSearchPage extends StatelessWidget {
  const MatrimonialSearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Advanced Search'),
      body: const MatrimonialSearchForm(),
    );
  }
}

/// The form content on its own (no Scaffold/AppBar), so the dashboard's
/// "Advanced Search" tab can embed it directly — mirroring how the source's
/// `dashboard/sections/AdvancedSearch.jsx` renders `<Search />` in place.
class MatrimonialSearchForm extends StatefulWidget {
  const MatrimonialSearchForm({super.key});

  @override
  State<MatrimonialSearchForm> createState() => _MatrimonialSearchFormState();
}

class _MatrimonialSearchFormState extends State<MatrimonialSearchForm> {
  bool _byProfileId = false;
  final _profileIdController = TextEditingController();
  final _filters = MatrimonialSearchFilters();

  @override
  void dispose() {
    _profileIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Search by Profile ID'),
                selected: _byProfileId,
                onSelected: (_) => setState(() => _byProfileId = true),
                selectedColor: AppColors.primary,
                labelStyle: AppText.labelSm.copyWith(
                  color: _byProfileId ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            AppSpacing.w8,
            Expanded(
              child: ChoiceChip(
                label: const Text('Search by Category'),
                selected: !_byProfileId,
                onSelected: (_) => setState(() => _byProfileId = false),
                selectedColor: AppColors.primary,
                labelStyle: AppText.labelSm.copyWith(
                  color: !_byProfileId ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.h20,
        if (_byProfileId) _profileIdSearch() else _categorySearch(),
      ],
    );
  }

  Widget _profileIdSearch() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Profile ID',
            hint: 'Enter Profile ID',
            controller: _profileIdController,
          ),
          AppSpacing.h16,
          PremiumButton(
            label: 'Find Profile',
            onPressed: () => showMatrimonialGate(context, "Search isn't available yet."),
          ),
        ],
      ),
    );
  }

  Widget _categorySearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Basic Information', [
          _ageRangeRow(),
          _dropdown('Marital Status', ['Any', ...kMaritalStatuses], _filters.maritalStatus,
              (v) => setState(() => _filters.maritalStatus = v!)),
          _dropdown('Religion', ['Any', ...kReligions], _filters.religion,
              (v) => setState(() => _filters.religion = v!)),
          _dropdown('Caste', kCasteFilterOptions, _filters.caste,
              (v) => setState(() => _filters.caste = v!)),
          _dropdown('Mother Tongue', ['Any', ...kMotherTongues], _filters.motherTongue,
              (v) => setState(() => _filters.motherTongue = v!)),
          _dropdown('Country', kCountries, _filters.country,
              (v) => setState(() => _filters.country = v!)),
          _dropdown('State', ['Any', ...kStates], _filters.state,
              (v) => setState(() => _filters.state = v!)),
          _dropdown('City', ['Any', ...kCities], _filters.city,
              (v) => setState(() => _filters.city = v!)),
        ]),
        AppSpacing.h20,
        _section('Education & Career', [
          _dropdown('Education', ['Any', ...kEducations], _filters.education,
              (v) => setState(() => _filters.education = v!)),
          _dropdown('Education Field', ['Any', ...kEducationFields], _filters.educationField,
              (v) => setState(() => _filters.educationField = v!)),
          _dropdown('Profession', ['Any', ...kProfessions], _filters.profession,
              (v) => setState(() => _filters.profession = v!)),
          _dropdown('Income', ['Any', ...kIncomes], _filters.income,
              (v) => setState(() => _filters.income = v!)),
        ]),
        AppSpacing.h20,
        _section('Lifestyle', [
          _dropdown('Diet', ['Any', ...kDiets], _filters.diet,
              (v) => setState(() => _filters.diet = v!)),
          _dropdown('Smoke', ['Any', ...kYesNoSometimes], _filters.smoke,
              (v) => setState(() => _filters.smoke = v!)),
          _dropdown('Drink', ['Any', ...kYesNoSometimes], _filters.drink,
              (v) => setState(() => _filters.drink = v!)),
          _dropdown('Body Type', ['Any', ...kBodyTypes], _filters.bodyType,
              (v) => setState(() => _filters.bodyType = v!)),
        ]),
        AppSpacing.h24,
        Row(
          children: [
            Expanded(
              child: PremiumButton.outlined(
                label: 'Reset',
                onPressed: () => setState(_filters.reset),
              ),
            ),
            AppSpacing.w12,
            Expanded(
              child: PremiumButton(
                label: 'Search',
                onPressed: () => showMatrimonialGate(context, "Search isn't available yet."),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _ageRangeRow() {
    final ages = List.generate(48, (i) => (i + 18).toString());
    return Row(
      children: [
        Expanded(
          child: _dropdown('Min Age', ages, _filters.minAge, (v) => setState(() => _filters.minAge = v!)),
        ),
        AppSpacing.w12,
        Expanded(
          child: _dropdown('Max Age', ages, _filters.maxAge, (v) => setState(() => _filters.maxAge = v!)),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> fields) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle),
          AppSpacing.h12,
          for (final f in fields) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: f),
        ],
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    final safeValue = items.contains(value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.formLabel),
        AppSpacing.h8,
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: AppText.body))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
            border: OutlineInputBorder(borderRadius: AppRadii.rMd, borderSide: const BorderSide(color: AppColors.divider)),
          ),
        ),
      ],
    );
  }
}
