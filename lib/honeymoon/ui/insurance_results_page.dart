/// Travel-insurance search + results, backed by `POST tripsafe/search`.
///
/// The payload mirrors the international single-trip `isq` envelope used by
/// InsuranceSearchPanel.jsx. Student and annual-multi-trip variants exist in
/// the web client but are not exposed here — see the handover notes.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../honeymoon_config.dart';
import '../models/honeymoon_models.dart';
import 'widgets/honeymoon_widgets.dart';

/// Region keys accepted by the TripSafe `isc.iri[].rkey` field.
class InsuranceRegion {
  const InsuranceRegion(this.key, this.label, {this.type = 'COUNTRY'});

  final String key;
  final String label;
  final String type;
}

/// The web panel populates this from a static country select, so the same
/// approach is used here. There is no destinations endpoint to drive it.
const List<InsuranceRegion> kInsuranceRegions = [
  InsuranceRegion('WORLDWIDE', 'Worldwide', type: 'POPULARREGION'),
  InsuranceRegion('SCHENGEN', 'Schengen', type: 'POPULARREGION'),
  InsuranceRegion('ASIA', 'Asia', type: 'POPULARREGION'),
  InsuranceRegion('USA', 'United States'),
  InsuranceRegion('THAILAND', 'Thailand'),
  InsuranceRegion('SINGAPORE', 'Singapore'),
  InsuranceRegion('MALDIVES', 'Maldives'),
  InsuranceRegion('INDONESIA', 'Indonesia'),
  InsuranceRegion('UAE', 'United Arab Emirates'),
  InsuranceRegion('MAURITIUS', 'Mauritius'),
];

// ---------------------------------------------------------------------------
// Search form
// ---------------------------------------------------------------------------

class InsuranceSearchForm extends StatefulWidget {
  const InsuranceSearchForm({super.key, required this.api});

  final HoneymoonApi api;

  @override
  State<InsuranceSearchForm> createState() => _InsuranceSearchFormState();
}

class _InsuranceSearchFormState extends State<InsuranceSearchForm> {
  InsuranceRegion? _region;
  DateTime? _start;
  DateTime? _end;

  /// One age per traveller — TripSafe prices on age, not head count.
  List<int> _ages = List.filled(HoneymoonConfig.defaultAdults, 30);

  bool _submitting = false;
  String? _regionError;
  String? _dateError;

  Future<void> _pickRegion() async {
    final picked = await AppBottomSheet.show<InsuranceRegion>(
      context,
      title: 'Where are you travelling?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in kInsuranceRegions)
            Pressable(
              onTap: () => Navigator.pop(context, r),
              borderRadius: AppRadii.rMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(r.label, style: AppText.body)),
                    if (r.key == _region?.key)
                      const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      _region = picked;
      _regionError = null;
    });
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(
        const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
      ),
      initialDateRange: _start != null && _end != null
          ? DateTimeRange(start: _start!, end: _end!)
          : null,
      helpText: 'Select trip dates',
    );
    if (range == null) return;
    setState(() {
      _start = range.start;
      _end = range.end;
      _dateError = null;
    });
  }

  Future<void> _openTravellerSheet() async {
    await AppBottomSheet.show(
      context,
      title: 'Travellers',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Insurance is priced per traveller age.',
                style: AppText.bodySm,
              ),
              const SizedBox(height: AppSpacing.lg),

              for (var i = 0; i < _ages.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: CounterRow(
                    title: 'Traveller ${i + 1}',
                    subtitle: 'Age in years',
                    value: _ages[i],
                    min: 1,
                    max: 99,
                    onChanged: (v) {
                      setSheetState(() => _ages[i] = v);
                      setState(() {});
                    },
                  ),
                ),

              Row(
                children: [
                  Expanded(
                    child: PremiumButton.outlined(
                      label: 'Remove',
                      size: PremiumButtonSize.medium,
                      enabled: _ages.length > 1,
                      onPressed: () {
                        setSheetState(() => _ages.removeLast());
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumButton.outlined(
                      label: 'Add',
                      size: PremiumButtonSize.medium,
                      enabled: _ages.length < HoneymoonConfig.maxTravellers,
                      onPressed: () {
                        setSheetState(() => _ages = [..._ages, 30]);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumButton(
                label: 'Done',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _validate() {
    setState(() {
      _regionError = _region == null ? 'Choose your destination' : null;
      _dateError = (_start == null || _end == null)
          ? 'Select your trip dates'
          : (!_end!.isAfter(_start!)
                ? 'Return date must be after departure'
                : null);
    });
    return _regionError == null && _dateError == null;
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      final plans = await widget.api.searchInsurance(
        regionKey: _region!.key,
        regionType: _region!.type,
        start: _start!,
        end: _end!,
        travellerAges: _ages,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: InsuranceResultsPage(
            region: _region!,
            start: _start!,
            end: _end!,
            plans: plans,
          ),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('Destination'),
        TapField(
          icon: Icons.public_rounded,
          value: _region?.label ?? '',
          placeholder: 'Where are you travelling?',
          onTap: _pickRegion,
          errorText: _regionError,
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Trip dates'),
        TapField(
          icon: Icons.calendar_today_rounded,
          value: _start == null
              ? ''
              : '${formatTripDate(_start)} – ${formatTripDate(_end)}',
          placeholder: 'Add dates',
          onTap: _pickDates,
          errorText: _dateError,
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Travellers'),
        TapField(
          icon: Icons.favorite_rounded,
          value:
              '${_ages.length} Traveller${_ages.length == 1 ? '' : 's'}'
              ' · Ages ${_ages.join(", ")}',
          onTap: _openTravellerSheet,
        ),

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: 'Find Travel Cover',
          icon: Icons.shield_outlined,
          isLoading: _submitting,
          onPressed: _search,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

class InsuranceResultsPage extends StatelessWidget {
  const InsuranceResultsPage({
    super.key,
    required this.region,
    required this.start,
    required this.end,
    required this.plans,
  });

  final InsuranceRegion region;
  final DateTime start;
  final DateTime end;
  final List<InsurancePlan> plans;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Travel cover · ${region.label}',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatTripDate(start)} – ${formatTripDate(end)}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: plans.isEmpty
          ? const EmptyState(
              title: 'No plans available',
              message: 'Try different dates or another destination.',
              icon: Icons.shield_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              itemCount: plans.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => FadeSlideIn(
                delay: AppMotion.staggerFor(i),
                child: _PlanCard(plan: plans[i]),
              ),
            ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final InsurancePlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(plan.name, style: AppText.cardTitle),
          if (plan.insurer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(plan.insurer, style: AppText.cardSubtitle),
          ],

          if (plan.coverage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final c in plan.coverage.take(4)) MetaChip(label: c),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: plan.price > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Premium', style: AppText.caption),
                          Text(formatPrice(plan.price), style: AppText.price),
                        ],
                      )
                    : Text('Price on review', style: AppText.bodySm),
              ),
              PremiumButton(
                label: 'Select',
                size: PremiumButtonSize.small,
                onPressed: () => AppSnackbar.info(
                  context,
                  'Insurance checkout is not connected in the app yet.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}