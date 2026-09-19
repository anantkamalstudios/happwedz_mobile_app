/// Travel-insurance search + results, backed by `POST tripsafe/search`
/// (or `tripsafe/search/embedded`).
///
/// A port of `InsuranceSearchPanel.jsx` and `TravelInsuranceResults.jsx`:
///
/// ```
/// International      Country (searchable) or Popular region · start/end
///                    · 1–6 travellers with ages · optional flight booking id
/// Student            flight booking id · country · start + coverage duration
///                    (1 month–2 years) ↔ end · 1–6 students, DOB or age 16–50
/// Annual Multi Trip  Worldwide / Worldwide excl US & Canada · longest trip
///                    30/45/60 days · start/end (≤ 179 days apart) · 1–6 travellers,
///                    DOB or age 1–80
///     ↓ search — a failure or no packages stays on the form, as on the web
/// Results            TripSafe <PLAN> · price inc. GST · 24/7 Assistance by
///                    <partner> · <cover> Travel Cover by <insurer> · all
///                    benefits · Select Plan → review → traveller details
/// ```
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../insurance_config.dart';
import '../models/honeymoon_models.dart';
import '../models/insurance_models.dart';
import 'booking/booking_widgets.dart'
    show InfoBanner, InfoTone, showOptionSheet;
import 'booking/insurance_booking_page.dart';
import 'widgets/honeymoon_widgets.dart';
import 'widgets/insurance_benefits_sheet.dart';

// ---------------------------------------------------------------------------
// Search form
// ---------------------------------------------------------------------------

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Age in whole years on [on] — the web's `calcAgeFromDOB`.
int _ageOn(DateTime dob, DateTime on) {
  var age = on.year - dob.year;
  if (on.month < dob.month || (on.month == dob.month && on.day < dob.day)) {
    age -= 1;
  }
  return age;
}

/// One traveller row on the Student / AMT forms: a date of birth or an age.
class _AgeOrDob {
  DateTime? dob;
  int? age;
}

class InsuranceSearchForm extends StatefulWidget {
  const InsuranceSearchForm({super.key, required this.api});

  final HoneymoonApi api;

  @override
  State<InsuranceSearchForm> createState() => _InsuranceSearchFormState();
}

class _InsuranceSearchFormState extends State<InsuranceSearchForm> {
  InsurancePlanType _type = InsurancePlanType.international;

  // --- International -------------------------------------------------------
  bool _byRegion = false;
  InsuranceDestination? _destination;
  late DateTime _start = _defaultStart();
  late DateTime _end = _start.add(
    const Duration(days: InsuranceLimits.defaultTripDays),
  );
  List<int> _ages = [InsuranceLimits.defaultAge];
  final _flightBookingId = TextEditingController();

  // --- Student ---------------------------------------------------------------
  InsuranceDestination? _studentDestination;
  late DateTime _studentStart = _defaultStart();
  int _coverageDays = InsuranceLimits.defaultStudentCoverageDays;
  late DateTime _studentEnd = _studentStart.add(Duration(days: _coverageDays));
  List<_AgeOrDob> _students = [_AgeOrDob()];
  final _studentFlightBookingId = TextEditingController();

  // --- Annual multi trip -------------------------------------------------------
  InsuranceDestination _amtDestination = kAmtDestinations[1];
  int _amtTripDays = InsuranceLimits.defaultAmtTripDays;
  late DateTime _amtStart = _defaultStart();
  late DateTime _amtEnd = _amtStart.add(
    const Duration(days: InsuranceLimits.amtMaxWindowDays),
  );
  List<_AgeOrDob> _amtTravellers = [_AgeOrDob()];

  bool _submitting = false;
  String? _error;

  static DateTime _defaultStart() => _day(
    DateTime.now(),
  ).add(const Duration(days: InsuranceLimits.defaultStartOffsetDays));

  @override
  void dispose() {
    _flightBookingId.dispose();
    _studentFlightBookingId.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Pickers
  // -------------------------------------------------------------------------

  Future<DateTime?> _pickDate(
    DateTime initial, {
    DateTime? first,
    DateTime? last,
  }) {
    final today = _day(DateTime.now());
    final lo = first ?? today;
    return showDatePicker(
      context: context,
      initialDate: initial.isBefore(lo) ? lo : initial,
      firstDate: lo,
      lastDate: last ?? today.add(const Duration(days: 730)),
    );
  }

  Future<InsuranceDestination?> _pickCountry() {
    return AppBottomSheet.show<InsuranceDestination>(
      context,
      title: 'Where are you travelling?',
      child: const _CountryPicker(),
    );
  }

  Future<void> _pickAgeOrDob(
    List<_AgeOrDob> rows,
    int index, {
    required int minAge,
    required int maxAge,
    required bool dob,
    required DateTime ageOn,
  }) async {
    if (dob) {
      final today = _day(DateTime.now());
      final picked = await showDatePicker(
        context: context,
        initialDate: rows[index].dob ?? DateTime(today.year - 25),
        firstDate: DateTime(today.year - 100),
        lastDate: today,
        helpText: 'Date of birth',
      );
      if (picked == null) return;
      setState(() {
        rows[index].dob = picked;
        // Student: a DOB fills the age as on the trip start (`updateDOB`).
        if (_type == InsurancePlanType.student) {
          final age = _ageOn(picked, ageOn);
          rows[index].age = age > 0 ? age : null;
        }
      });
      return;
    }
    final picked = await showOptionSheet<int>(
      context,
      title: 'Select age',
      options: [for (var a = minAge; a <= maxAge; a++) a],
      labelOf: (a) => '$a',
      selected: rows[index].age,
    );
    if (picked == null) return;
    setState(() {
      rows[index].age = picked;
      // Picking an age clears the DOB, as on the web.
      rows[index].dob = null;
    });
  }

  // -------------------------------------------------------------------------
  // Search
  // -------------------------------------------------------------------------

  /// Validation and the query, per plan type, with the web's messages.
  InsuranceSearchQuery? _buildQuery() {
    switch (_type) {
      case InsurancePlanType.international:
        if (_end.isBefore(_start)) {
          _error = 'End date must be on or after start date';
          return null;
        }
        if (_destination == null || _destination!.rkey.isEmpty) {
          _error = 'Please select a destination country or region';
          return null;
        }
        return InsuranceSearchQuery(
          planType: _type,
          destination: _destination!,
          start: _start,
          end: _end,
          ages: List<int>.from(_ages),
          flightBookingId: _flightBookingId.text.trim(),
        );

      case InsurancePlanType.student:
        if (_studentDestination == null || _studentDestination!.rkey.isEmpty) {
          _error = 'Please select a destination country';
          return null;
        }
        return InsuranceSearchQuery(
          planType: _type,
          destination: _studentDestination!,
          start: _studentStart,
          end: _studentEnd,
          coverageDays: _coverageDays,
          ages: [
            for (final s in _students)
              s.age ??
                  (s.dob != null && _ageOn(s.dob!, _studentStart) > 0
                      ? _ageOn(s.dob!, _studentStart)
                      : InsuranceLimits.defaultStudentAge),
          ],
          flightBookingId: _studentFlightBookingId.text.trim(),
        );

      case InsurancePlanType.annualMultiTrip:
        // The policy window is capped at TripJack's limit (start + 179).
        final maxEnd = _amtStart.add(
          const Duration(days: InsuranceLimits.amtMaxWindowDays),
        );
        final end = _amtEnd.isAfter(maxEnd) ? maxEnd : _amtEnd;
        if (end.isBefore(_amtStart)) {
          _error = 'End date must be on or after start date';
          return null;
        }
        final now = DateTime.now();
        return InsuranceSearchQuery(
          planType: _type,
          destination: _amtDestination,
          start: _amtStart,
          end: end,
          amtTripDays: _amtTripDays,
          ages: [
            for (final t in _amtTravellers)
              t.age ??
                  (t.dob != null
                      ? (now.difference(t.dob!).inDays / 365.25).floor()
                      : InsuranceLimits.defaultAge),
          ],
        );
    }
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final query = _buildQuery();
    if (query == null) {
      setState(() {});
      return;
    }

    setState(() => _submitting = true);
    try {
      final plans = await widget.api.searchInsurance(query);
      if (!mounted) return;
      // No packages: the web stays on the form with its message.
      if (plans.isEmpty) {
        setState(() => _error = query.emptyMessage);
        return;
      }
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: InsuranceResultsPage(
            api: widget.api,
            query: query,
            plans: plans,
          ),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final t in InsurancePlanType.values)
              ChoiceChip(
                label: Text(t.label),
                selected: _type == t,
                selectedColor: AppColors.pinkSurface,
                onSelected: (_) => setState(() {
                  _type = t;
                  _error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_type) {
          InsurancePlanType.international => _internationalFields(),
          InsurancePlanType.student => _studentFields(),
          InsurancePlanType.annualMultiTrip => _amtFields(),
        },
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _error!,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: _submitting ? 'Searching packages...' : 'View Packages',
          icon: Icons.shield_outlined,
          isLoading: _submitting,
          onPressed: _search,
        ),
      ],
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label),
        TapField(
          icon: Icons.calendar_today_rounded,
          value: formatTripDate(value),
          onTap: onTap,
        ),
      ],
    );
  }

  Widget _internationalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            ChoiceChip(
              label: const Text('Country'),
              selected: !_byRegion,
              selectedColor: AppColors.pinkSurface,
              onSelected: (_) => setState(() {
                _byRegion = false;
                _destination = null;
              }),
            ),
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: const Text('Popular region'),
              selected: _byRegion,
              selectedColor: AppColors.pinkSurface,
              onSelected: (_) => setState(() {
                _byRegion = true;
                _destination = kInsurancePopularRegions.first;
              }),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_byRegion) ...[
          Text('Popular regions', style: AppText.formLabel),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final r in kInsurancePopularRegions)
                ChoiceChip(
                  label: Text(r.label),
                  selected: _destination == r,
                  selectedColor: AppColors.pinkSurface,
                  onSelected: (_) => setState(() => _destination = r),
                ),
            ],
          ),
        ] else ...[
          const FieldLabel('Destination'),
          TapField(
            icon: Icons.public_rounded,
            value: _destination?.label ?? '',
            placeholder: 'Search a country',
            onTap: () async {
              final picked = await _pickCountry();
              if (picked != null) setState(() => _destination = picked);
            },
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _dateField('Start date', _start, () async {
                final picked = await _pickDate(_start);
                if (picked == null) return;
                setState(() {
                  _start = picked;
                  // A start after the end moves the end two days on.
                  if (picked.isAfter(_end)) {
                    _end = picked.add(
                      const Duration(days: InsuranceLimits.defaultTripDays),
                    );
                  }
                  // Keep the trip inside TripJack's policy window.
                  final maxEnd = picked.add(
                    const Duration(days: InsuranceLimits.maxPolicyWindowDays),
                  );
                  if (_end.isAfter(maxEnd)) _end = maxEnd;
                });
              }),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _dateField('End date', _end, () async {
                final picked = await _pickDate(
                  _end,
                  first: _start,
                  last: _start.add(
                    const Duration(days: InsuranceLimits.maxPolicyWindowDays),
                  ),
                );
                if (picked != null) setState(() => _end = picked);
              }),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        CounterRow(
          title: 'Travellers',
          subtitle: 'Up to ${InsuranceLimits.maxTravellers}',
          value: _ages.length,
          min: InsuranceLimits.minTravellers,
          max: InsuranceLimits.maxTravellers,
          onChanged: (n) => setState(() {
            final next = List<int>.from(_ages);
            while (next.length < n) {
              next.add(InsuranceLimits.defaultAge);
            }
            _ages = next.sublist(0, n);
          }),
        ),
        for (var i = 0; i < _ages.length; i++)
          CounterRow(
            title: 'Traveller ${i + 1} age',
            subtitle: 'Years',
            value: _ages[i],
            min: InsuranceLimits.minAge,
            max: InsuranceLimits.maxAge,
            onChanged: (v) => setState(() => _ages[i] = v),
          ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _flightBookingId,
          label: 'Flight booking ID (optional)',
          hint: 'TGS… from flight review',
          helperText: 'Links insurance to an existing flight booking',
        ),
      ],
    );
  }

  Widget _studentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _studentFlightBookingId,
          label: 'Have a Flight Booking?',
          hint: 'Flight booking ID (optional)',
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Where are you travelling?'),
        TapField(
          icon: Icons.public_rounded,
          value: _studentDestination?.label ?? '',
          placeholder: 'Search a country',
          onTap: () async {
            final picked = await _pickCountry();
            if (picked != null) setState(() => _studentDestination = picked);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _dateField('Start date', _studentStart, () async {
          final picked = await _pickDate(_studentStart);
          if (picked == null) return;
          setState(() {
            // Keep the duration: move the end, and re-age students by DOB.
            _studentStart = picked;
            _studentEnd = picked.add(Duration(days: _coverageDays));
            for (final s in _students) {
              if (s.dob != null) {
                final age = _ageOn(s.dob!, picked);
                s.age = age > 0 ? age : s.age;
              }
            }
          });
        }),
        const SizedBox(height: AppSpacing.md),
        const FieldLabel('Coverage duration'),
        TapField(
          icon: Icons.timelapse_rounded,
          value: kStudentCoverageDurations
              .firstWhere(
                (d) => d.days == _coverageDays,
                orElse: () => kStudentCoverageDurations[5],
              )
              .label,
          onTap: () async {
            final picked = await showOptionSheet<int>(
              context,
              title: 'Coverage duration',
              options: [for (final d in kStudentCoverageDurations) d.days],
              labelOf: (days) => kStudentCoverageDurations
                  .firstWhere((d) => d.days == days)
                  .label,
              selected: _coverageDays,
            );
            if (picked == null) return;
            setState(() {
              _coverageDays = picked;
              _studentEnd = _studentStart.add(Duration(days: picked));
            });
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _dateField('End date', _studentEnd, () async {
          final picked = await _pickDate(_studentEnd, first: _studentStart);
          if (picked == null) return;
          setState(() {
            _studentEnd = picked;
            // The closest listed duration to the chosen dates.
            final diff = picked.difference(_studentStart).inDays;
            _coverageDays = diff <= 0
                ? 30
                : kStudentCoverageDurations
                      .reduce(
                        (a, b) => (b.days - diff).abs() < (a.days - diff).abs()
                            ? b
                            : a,
                      )
                      .days;
          });
        }),
        const SizedBox(height: AppSpacing.lg),
        _ageRows(
          label: 'Student',
          rows: _students,
          minAge: InsuranceLimits.minStudentAge,
          maxAge: InsuranceLimits.maxStudentAge,
          ageOn: _studentStart,
          onCount: (n) => setState(() => _students = _resize(_students, n)),
          showAgeHint: true,
        ),
      ],
    );
  }

  Widget _amtFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('Where are you travelling?'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final d in kAmtDestinations)
              ChoiceChip(
                label: Text(d.label),
                selected: _amtDestination == d,
                selectedColor: AppColors.pinkSurface,
                onSelected: (_) => setState(() => _amtDestination = d),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('What would be the maximum duration of your trips?'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final d in kAmtTripDurations)
              ChoiceChip(
                label: Text(d.label),
                selected: _amtTripDays == d.days,
                selectedColor: AppColors.pinkSurface,
                onSelected: (_) => setState(() => _amtTripDays = d.days),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _dateField('Start date', _amtStart, () async {
                final picked = await _pickDate(_amtStart);
                if (picked == null) return;
                setState(() {
                  _amtStart = picked;
                  final maxEnd = picked.add(
                    const Duration(days: InsuranceLimits.amtMaxWindowDays),
                  );
                  if (_amtEnd.isAfter(maxEnd) || picked.isAfter(_amtEnd)) {
                    _amtEnd = maxEnd;
                  }
                });
              }),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _dateField('End date', _amtEnd, () async {
                final picked = await _pickDate(
                  _amtEnd,
                  first: _amtStart,
                  last: _amtStart.add(
                    const Duration(days: InsuranceLimits.amtMaxWindowDays),
                  ),
                );
                if (picked != null) setState(() => _amtEnd = picked);
              }),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ageRows(
          label: 'Traveller',
          rows: _amtTravellers,
          minAge: 1,
          maxAge: InsuranceLimits.maxAmtAge,
          ageOn: _amtStart,
          onCount: (n) =>
              setState(() => _amtTravellers = _resize(_amtTravellers, n)),
          showAgeHint: false,
        ),
      ],
    );
  }

  static List<_AgeOrDob> _resize(List<_AgeOrDob> rows, int n) {
    final next = List<_AgeOrDob>.from(rows);
    while (next.length < n) {
      next.add(_AgeOrDob());
    }
    return next.sublist(0, n);
  }

  Widget _ageRows({
    required String label,
    required List<_AgeOrDob> rows,
    required int minAge,
    required int maxAge,
    required DateTime ageOn,
    required ValueChanged<int> onCount,
    required bool showAgeHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CounterRow(
          title: '${rows.length} $label${rows.length > 1 ? 's' : ''}',
          subtitle: 'Up to ${InsuranceLimits.maxTravellers}',
          value: rows.length,
          min: InsuranceLimits.minTravellers,
          max: InsuranceLimits.maxTravellers,
          onChanged: onCount,
        ),
        for (var i = 0; i < rows.length; i++) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('$label ${i + 1}', style: AppText.labelSm),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: TapField(
                  icon: Icons.cake_outlined,
                  value: rows[i].dob == null ? '' : formatTripDate(rows[i].dob),
                  placeholder: 'Date of birth',
                  onTap: () => _pickAgeOrDob(
                    rows,
                    i,
                    minAge: minAge,
                    maxAge: maxAge,
                    dob: true,
                    ageOn: ageOn,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('OR', style: AppText.caption),
              ),
              SizedBox(
                width: 110,
                child: TapField(
                  icon: Icons.person_outline_rounded,
                  value: rows[i].age == null ? '' : '${rows[i].age}',
                  placeholder: 'Age',
                  onTap: () => _pickAgeOrDob(
                    rows,
                    i,
                    minAge: minAge,
                    maxAge: maxAge,
                    dob: false,
                    ageOn: ageOn,
                  ),
                ),
              ),
            ],
          ),
          if (showAgeHint && rows[i].dob != null && rows[i].age != null)
            Text(
              'Age: ${rows[i].age} yrs (as on trip start date)',
              style: AppText.caption,
            ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text('ℹ Age as on trip start date', style: AppText.caption),
        Text('✏ You can edit DOB at a later stage', style: AppText.caption),
      ],
    );
  }
}

/// The web's searchable country select (`InsuranceCountrySelect.jsx`).
class _CountryPicker extends StatefulWidget {
  const _CountryPicker();

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final matches = [
      for (final c in kInsuranceCountries)
        if (q.isEmpty ||
            c.label.toLowerCase().contains(q) ||
            c.rkey.toLowerCase() == q)
          c,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          hint: 'Search country',
          prefixIcon: Icons.search_rounded,
          autofocus: true,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 360,
          child: matches.isEmpty
              ? Center(child: Text('No country found', style: AppText.bodySm))
              : ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (context, i) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.public_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: Text(matches[i].label),
                    trailing: Text(matches[i].rkey, style: AppText.caption),
                    onTap: () => Navigator.pop(context, matches[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

/// `₹1,234` — the web's results price (no paise).
String _rupees(double v) => v <= 0 ? '—' : formatPrice(v);

class InsuranceResultsPage extends StatefulWidget {
  const InsuranceResultsPage({
    super.key,
    required this.api,
    required this.query,
    required this.plans,
  });

  final HoneymoonApi api;
  final InsuranceSearchQuery query;
  final List<InsurancePlan> plans;

  @override
  State<InsuranceResultsPage> createState() => _InsuranceResultsPageState();
}

class _InsuranceResultsPageState extends State<InsuranceResultsPage> {
  String? _selecting;
  String? _selectError;

  /// "Select Plan": reviews with the insurer first, as the web does, and
  /// only then opens the traveller form on the booking id the review
  /// returned.
  Future<void> _select(InsurancePlan plan) async {
    final key = '${plan.planId}-${plan.productId}';
    setState(() {
      _selecting = key;
      _selectError = null;
    });
    try {
      final review = await widget.api.reviewInsurancePlan(plan);
      if (!mounted) return;
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: InsuranceBookingPage(
            api: widget.api,
            plan: plan.withPrice(review.price),
            regionLabel: widget.query.destination.label,
            start: widget.query.start,
            end: widget.query.end,
            travellerAges: widget.query.ages,
            bookingId: review.bookingId,
            reviewedPrice: review.price,
          ),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (mounted) setState(() => _selectError = e.message);
    } catch (_) {
      if (mounted) setState(() => _selectError = 'Review failed');
    } finally {
      if (mounted) setState(() => _selecting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final n = q.travellerCount;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Travel Insurance Packages',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${q.destination.label} · ${formatTripDate(q.start)} – '
              '${formatTripDate(q.end)} · $n traveller${n == 1 ? '' : 's'} · '
              '${q.planType.label}',
              style: AppText.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: widget.plans.isEmpty
          ? const EmptyState(
              title: 'No insurance packages found',
              message: 'Try different dates or destination.',
              icon: Icons.shield_outlined,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                if (_selectError != null) ...[
                  InfoBanner(
                    tone: InfoTone.error,
                    icon: Icons.error_outline_rounded,
                    message: _selectError!,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                for (var i = 0; i < widget.plans.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  FadeSlideIn(
                    delay: AppMotion.staggerFor(i),
                    child: _PlanCard(
                      plan: widget.plans[i],
                      busy:
                          _selecting ==
                          '${widget.plans[i].planId}-${widget.plans[i].productId}',
                      enabled: _selecting == null,
                      onSelect: () => _select(widget.plans[i]),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// The web's plan card: brand and price, then the Assistance and Coverage
/// columns (stacked on a phone), all benefits, and the master-policy line.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onSelect,
    required this.busy,
    required this.enabled,
  });

  final InsurancePlan plan;
  final VoidCallback onSelect;
  final bool busy;
  final bool enabled;

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: AppRadii.rMd,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, size: 14, color: AppColors.successDark),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(text, style: AppText.caption)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final partner = plan.assistancePartner;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: AppRadii.rMd,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.body,
                    children: [
                      const TextSpan(text: 'TripSafe '),
                      TextSpan(
                        text: plan.name.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_rupees(plan.price), style: AppText.price),
                  Text('Inc. GST', style: AppText.caption),
                ],
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.divider),
          Text('24/7 Assistance', style: AppText.labelSm),
          Text(
            'Assistance by ${partner.isEmpty ? 'TripSafe partners' : partner}',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final t in plan.assistanceTags) _tag(t)],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            plan.coverageAmount.isEmpty
                ? 'Travel Cover'
                : '${plan.coverageAmount} Travel Cover',
            style: AppText.labelSm,
          ),
          Text('Insurance by ${plan.insurerLabel}', style: AppText.caption),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final t in plan.coverageTags) _tag(t)],
          ),
          if (plan.benefits.isNotEmpty)
            PremiumButton.text(
              label: 'View all ${plan.benefits.length} benefits',
              size: PremiumButtonSize.small,
              onPressed: () => showInsuranceBenefitsSheet(context, plan),
            ),
          Text(
            'Insurance is through a group master policy with '
            '${plan.insurer.isEmpty ? 'the insurer' : plan.insurerLabel}.',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          PremiumButton(
            label: 'Select Plan',
            icon: Icons.add_rounded,
            isLoading: busy,
            onPressed: enabled ? onSelect : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Previous implementation, kept for reference.
//
// Replaced to match InsuranceSearchPanel.jsx / TravelInsuranceResults.jsx: it
// searched International only, with invented region keys (WORLDWIDE, USA, …)
// that TripSafe does not recognise, allowed 12 travellers (web: 6), required
// the end after the start (web: on or after), and reviewed only on the
// booking page.
// ---------------------------------------------------------------------------

// import 'package:flutter/material.dart';
//
// import '../../core/core.dart';
// import '../data/honeymoon_api.dart';
// import '../honeymoon_config.dart';
// import '../models/honeymoon_models.dart';
// import 'booking/insurance_booking_page.dart';
// import 'widgets/honeymoon_widgets.dart';
// import 'widgets/insurance_benefits_sheet.dart';
//
// /// Region keys accepted by the TripSafe `isc.iri[].rkey` field.
// class InsuranceRegion {
//   const InsuranceRegion(this.key, this.label, {this.type = 'COUNTRY'});
//
//   final String key;
//   final String label;
//   final String type;
// }
//
// /// The web panel populates this from a static country select, so the same
// /// approach is used here. There is no destinations endpoint to drive it.
// const List<InsuranceRegion> kInsuranceRegions = [
//   InsuranceRegion('WORLDWIDE', 'Worldwide', type: 'POPULARREGION'),
//   InsuranceRegion('SCHENGEN', 'Schengen', type: 'POPULARREGION'),
//   InsuranceRegion('ASIA', 'Asia', type: 'POPULARREGION'),
//   InsuranceRegion('USA', 'United States'),
//   InsuranceRegion('THAILAND', 'Thailand'),
//   InsuranceRegion('SINGAPORE', 'Singapore'),
//   InsuranceRegion('MALDIVES', 'Maldives'),
//   InsuranceRegion('INDONESIA', 'Indonesia'),
//   InsuranceRegion('UAE', 'United Arab Emirates'),
//   InsuranceRegion('MAURITIUS', 'Mauritius'),
// ];
//
// // ---------------------------------------------------------------------------
// // Search form
// // ---------------------------------------------------------------------------
//
// class InsuranceSearchForm extends StatefulWidget {
//   const InsuranceSearchForm({super.key, required this.api});
//
//   final HoneymoonApi api;
//
//   @override
//   State<InsuranceSearchForm> createState() => _InsuranceSearchFormState();
// }
//
// class _InsuranceSearchFormState extends State<InsuranceSearchForm> {
//   InsuranceRegion? _region;
//   DateTime? _start;
//   DateTime? _end;
//
//   /// One age per traveller — TripSafe prices on age, not head count.
//   List<int> _ages = List.filled(HoneymoonConfig.defaultAdults, 30);
//
//   bool _submitting = false;
//   String? _regionError;
//   String? _dateError;
//
//   Future<void> _pickRegion() async {
//     final picked = await AppBottomSheet.show<InsuranceRegion>(
//       context,
//       title: 'Where are you travelling?',
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           for (final r in kInsuranceRegions)
//             Pressable(
//               onTap: () => Navigator.pop(context, r),
//               borderRadius: AppRadii.rMd,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: AppSpacing.md,
//                   horizontal: AppSpacing.sm,
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.public_rounded,
//                       size: 18,
//                       color: AppColors.primary,
//                     ),
//                     const SizedBox(width: AppSpacing.md),
//                     Expanded(child: Text(r.label, style: AppText.body)),
//                     if (r.key == _region?.key)
//                       const Icon(
//                         Icons.check_rounded,
//                         size: 20,
//                         color: AppColors.primary,
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//     if (picked == null) return;
//     setState(() {
//       _region = picked;
//       _regionError = null;
//     });
//   }
//
//   Future<void> _pickDates() async {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final range = await showDateRangePicker(
//       context: context,
//       firstDate: today,
//       lastDate: today.add(
//         const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
//       ),
//       initialDateRange: _start != null && _end != null
//           ? DateTimeRange(start: _start!, end: _end!)
//           : null,
//       helpText: 'Select trip dates',
//     );
//     if (range == null) return;
//     setState(() {
//       _start = range.start;
//       _end = range.end;
//       _dateError = null;
//     });
//   }
//
//   Future<void> _openTravellerSheet() async {
//     await AppBottomSheet.show(
//       context,
//       title: 'Travellers',
//       child: StatefulBuilder(
//         builder: (sheetContext, setSheetState) {
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text(
//                 'Insurance is priced per traveller age.',
//                 style: AppText.bodySm,
//               ),
//               const SizedBox(height: AppSpacing.lg),
//
//               for (var i = 0; i < _ages.length; i++)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: AppSpacing.md),
//                   child: CounterRow(
//                     title: 'Traveller ${i + 1}',
//                     subtitle: 'Age in years',
//                     value: _ages[i],
//                     min: 1,
//                     max: 99,
//                     onChanged: (v) {
//                       setSheetState(() => _ages[i] = v);
//                       setState(() {});
//                     },
//                   ),
//                 ),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: PremiumButton.outlined(
//                       label: 'Remove',
//                       size: PremiumButtonSize.medium,
//                       enabled: _ages.length > 1,
//                       onPressed: () {
//                         setSheetState(() => _ages.removeLast());
//                         setState(() {});
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: AppSpacing.md),
//                   Expanded(
//                     child: PremiumButton.outlined(
//                       label: 'Add',
//                       size: PremiumButtonSize.medium,
//                       enabled: _ages.length < HoneymoonConfig.maxTravellers,
//                       onPressed: () {
//                         setSheetState(() => _ages = [..._ages, 30]);
//                         setState(() {});
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: AppSpacing.md),
//               PremiumButton(
//                 label: 'Done',
//                 onPressed: () => Navigator.pop(sheetContext),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
//
//   bool _validate() {
//     setState(() {
//       _regionError = _region == null ? 'Choose your destination' : null;
//       _dateError = (_start == null || _end == null)
//           ? 'Select your trip dates'
//           : (!_end!.isAfter(_start!)
//                 ? 'Return date must be after departure'
//                 : null);
//     });
//     return _regionError == null && _dateError == null;
//   }
//
//   Future<void> _search() async {
//     if (_submitting) return;
//     FocusScope.of(context).unfocus();
//     if (!_validate()) return;
//
//     setState(() => _submitting = true);
//     try {
//       final plans = await widget.api.searchInsurance(
//         regionKey: _region!.key,
//         regionType: _region!.type,
//         start: _start!,
//         end: _end!,
//         travellerAges: _ages,
//       );
//
//       if (!mounted) return;
//       Navigator.push(
//         context,
//         AnimatedPageRoute(
//           page: InsuranceResultsPage(
//             api: widget.api,
//             region: _region!,
//             start: _start!,
//             end: _end!,
//             ages: List<int>.from(_ages),
//             plans: plans,
//           ),
//           style: PageTransitionStyle.slideRight,
//         ),
//       );
//     } on HoneymoonApiException catch (e) {
//       if (!mounted) return;
//       AppSnackbar.error(context, e.message);
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const FieldLabel('Destination'),
//         TapField(
//           icon: Icons.public_rounded,
//           value: _region?.label ?? '',
//           placeholder: 'Where are you travelling?',
//           onTap: _pickRegion,
//           errorText: _regionError,
//         ),
//         const SizedBox(height: AppSpacing.lg),
//
//         const FieldLabel('Trip dates'),
//         TapField(
//           icon: Icons.calendar_today_rounded,
//           value: _start == null
//               ? ''
//               : '${formatTripDate(_start)} – ${formatTripDate(_end)}',
//           placeholder: 'Add dates',
//           onTap: _pickDates,
//           errorText: _dateError,
//         ),
//         const SizedBox(height: AppSpacing.lg),
//
//         const FieldLabel('Travellers'),
//         TapField(
//           icon: Icons.favorite_rounded,
//           value:
//               '${_ages.length} Traveller${_ages.length == 1 ? '' : 's'}'
//               ' · Ages ${_ages.join(", ")}',
//           onTap: _openTravellerSheet,
//         ),
//
//         const SizedBox(height: AppSpacing.xl),
//         PremiumButton(
//           label: 'Find Travel Cover',
//           icon: Icons.shield_outlined,
//           isLoading: _submitting,
//           onPressed: _search,
//         ),
//       ],
//     );
//   }
// }
//
// // ---------------------------------------------------------------------------
// // Results
// // ---------------------------------------------------------------------------
//
// class InsuranceResultsPage extends StatelessWidget {
//   const InsuranceResultsPage({
//     super.key,
//     required this.api,
//     required this.region,
//     required this.start,
//     required this.end,
//     required this.ages,
//     required this.plans,
//   });
//
//   final HoneymoonApi api;
//   final InsuranceRegion region;
//   final DateTime start;
//   final DateTime end;
//
//   /// Carried through from the search: the booking form needs one row per
//   /// insured person, and the insurer prices on age rather than head count.
//   final List<int> ages;
//
//   final List<InsurancePlan> plans;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppTopBar(
//         elevated: true,
//         titleWidget: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Travel cover · ${region.label}',
//               style: AppText.cardTitle,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             Text(
//               '${formatTripDate(start)} – ${formatTripDate(end)}',
//               style: AppText.caption,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//       body: plans.isEmpty
//           ? const EmptyState(
//               title: 'No plans available',
//               message: 'Try different dates or another destination.',
//               icon: Icons.shield_outlined,
//             )
//           : ListView.separated(
//               padding: const EdgeInsets.fromLTRB(
//                 AppSpacing.lg,
//                 AppSpacing.lg,
//                 AppSpacing.lg,
//                 AppSpacing.xxxl,
//               ),
//               itemCount: plans.length,
//               separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
//               itemBuilder: (context, i) => FadeSlideIn(
//                 delay: AppMotion.staggerFor(i),
//                 child: _PlanCard(
//                   plan: plans[i],
//                   onSelect: () => Navigator.push(
//                     context,
//                     AnimatedPageRoute(
//                       page: InsuranceBookingPage(
//                         api: api,
//                         plan: plans[i],
//                         regionLabel: region.label,
//                         start: start,
//                         end: end,
//                         travellerAges: ages,
//                       ),
//                       style: PageTransitionStyle.slideRight,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//     );
//   }
// }
//
// class _PlanCard extends StatelessWidget {
//   const _PlanCard({required this.plan, required this.onSelect});
//
//   final InsurancePlan plan;
//   final VoidCallback onSelect;
//
//   @override
//   Widget build(BuildContext context) {
//     return AppCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(plan.name, style: AppText.cardTitle),
//           const SizedBox(height: AppSpacing.xxs),
//           Text(plan.insurerLabel, style: AppText.cardSubtitle),
//
//           if (plan.coverageAmount.isNotEmpty) ...[
//             const SizedBox(height: AppSpacing.sm),
//             Row(
//               children: [
//                 const Icon(
//                   Icons.shield_outlined,
//                   size: 15,
//                   color: AppColors.successDark,
//                 ),
//                 const SizedBox(width: AppSpacing.xs),
//                 Expanded(
//                   child: Text(
//                     'Cover up to ${plan.coverageAmount}',
//                     style: AppText.bodySm,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//
//           if (plan.coverageTags.isNotEmpty) ...[
//             const SizedBox(height: AppSpacing.md),
//             Wrap(
//               spacing: AppSpacing.xs,
//               runSpacing: AppSpacing.xs,
//               children: [
//                 for (final c in plan.coverageTags) MetaChip(label: c),
//               ],
//             ),
//           ],
//
//           // The card can only carry a few highlights; the full schedule of
//           // benefits is what a traveller actually compares policies on.
//           if (plan.benefits.isNotEmpty) ...[
//             const SizedBox(height: AppSpacing.sm),
//             Align(
//               alignment: Alignment.centerLeft,
//               child: PremiumButton.text(
//                 label: 'View all ${plan.benefits.length} benefits',
//                 size: PremiumButtonSize.small,
//                 onPressed: () => showInsuranceBenefitsSheet(context, plan),
//               ),
//             ),
//           ],
//
//           const SizedBox(height: AppSpacing.md),
//           Row(
//             children: [
//               Expanded(
//                 child: plan.price > 0
//                     ? Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text('Premium', style: AppText.caption),
//                           Text(formatPrice(plan.price), style: AppText.price),
//                         ],
//                       )
//                     : Text('Price on review', style: AppText.bodySm),
//               ),
//               PremiumButton(
//                 label: 'Select',
//                 size: PremiumButtonSize.small,
//                 expanded: false,
//                 onPressed: onSelect,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
