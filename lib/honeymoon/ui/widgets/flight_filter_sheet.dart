/// The flight results filter sheet and its supporting rails.
///
/// Presents the same facets the website's `FlightFiltersSidebar` does — price,
/// stops, times, airlines, duration, layover, fare type, cancellation, baggage,
/// airports, terminals and flight number — re-laid out as a mobile sheet with a
/// sticky footer that previews how many flights the current draft would leave.
///
/// The draft is applied only on "Show N flights", so a half-built selection
/// never rearranges the list underneath the sheet.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/flight_filters.dart';
import '../../models/honeymoon_models.dart';
import 'honeymoon_widgets.dart';

/// Opens the filter sheet and resolves to the chosen filters, or null when the
/// user backs out without applying.
Future<FlightFilters?> showFlightFilterSheet(
  BuildContext context, {
  required FlightFacets facets,
  required FlightFilters current,
  required List<FlightResult> flights,
  required PaxCounts pax,
  String? searchFrom,
  String? searchTo,
}) {
  return showModalBottomSheet<FlightFilters>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
    builder: (_) => _FlightFilterSheet(
      facets: facets,
      current: current,
      flights: flights,
      pax: pax,
      searchFrom: searchFrom,
      searchTo: searchTo,
    ),
  );
}

class _FlightFilterSheet extends StatefulWidget {
  const _FlightFilterSheet({
    required this.facets,
    required this.current,
    required this.flights,
    required this.pax,
    this.searchFrom,
    this.searchTo,
  });

  final FlightFacets facets;
  final FlightFilters current;
  final List<FlightResult> flights;
  final PaxCounts pax;
  final String? searchFrom;
  final String? searchTo;

  @override
  State<_FlightFilterSheet> createState() => _FlightFilterSheetState();
}

class _FlightFilterSheetState extends State<_FlightFilterSheet> {
  late FlightFilters _draft = widget.current;
  late final TextEditingController _airlineQuery = TextEditingController();
  late final TextEditingController _flightNoQuery = TextEditingController(
    text: widget.current.flightNumbers.firstOrNull ?? '',
  );

  /// Sections start collapsed apart from the ones the portal opens by default,
  /// so the sheet is scannable rather than a wall of checkboxes.
  final Set<String> _expanded = {'price', 'stops', 'departureTime'};

  @override
  void dispose() {
    _airlineQuery.dispose();
    _flightNoQuery.dispose();
    super.dispose();
  }

  int get _matchCount => filterFlights(
    widget.flights,
    _draft,
    searchFrom: widget.searchFrom,
    searchTo: widget.searchTo,
    pax: widget.pax,
  ).length;

  void _update(FlightFilters next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final f = widget.facets;
    final count = _matchCount;

    return SafeArea(
      top: false,
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
                  if (f.popular.isNotEmpty) _popularSection(f),

                  if (f.hasPriceBand)
                    _section(
                      id: 'price',
                      title: 'Price',
                      activeCount:
                          _draft.priceMin != null || _draft.priceMax != null
                          ? 1
                          : 0,
                      onClear: () => _update(_draft.clearGroup('price')),
                      child: _priceSlider(f),
                    ),

                  if (f.stops.isNotEmpty)
                    _section(
                      id: 'stops',
                      title: 'Stops',
                      activeCount: _draft.stops.length,
                      onClear: () => _update(_draft.clearGroup('stops')),
                      child: Column(
                        children: [
                          for (final s in f.stops)
                            _checkRow(
                              label: s.label,
                              count: s.count,
                              minPrice: s.minPrice,
                              checked: _draft.stops.contains(
                                int.tryParse(s.value) ?? -1,
                              ),
                              onChanged: () => _update(
                                _draft.toggle(
                                  'stops',
                                  int.tryParse(s.value) ?? 0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (f.departureSlots.isNotEmpty)
                    _section(
                      id: 'departureTime',
                      title: 'Departure time',
                      activeCount: _draft.departureTime.length,
                      onClear: () => _update(_draft.clearGroup('departureTime')),
                      child: _slotGrid(
                        slots: f.departureSlots,
                        selected: _draft.departureTime,
                        onTap: (v) => _update(_draft.toggle('departureTime', v)),
                      ),
                    ),

                  if (f.arrivalSlots.isNotEmpty)
                    _section(
                      id: 'arrivalTime',
                      title: 'Arrival time',
                      activeCount: _draft.arrivalTime.length,
                      onClear: () => _update(_draft.clearGroup('arrivalTime')),
                      child: _slotGrid(
                        slots: f.arrivalSlots,
                        selected: _draft.arrivalTime,
                        onTap: (v) => _update(_draft.toggle('arrivalTime', v)),
                      ),
                    ),

                  if (f.airlines.isNotEmpty)
                    _section(
                      id: 'airlines',
                      title: 'Airlines',
                      activeCount: _draft.airlines.length,
                      onClear: () => _update(_draft.clearGroup('airlines')),
                      child: _airlinesSection(f),
                    ),

                  if (f.hasDurationBand)
                    _section(
                      id: 'durationMax',
                      title: 'Journey duration',
                      activeCount: _draft.durationMax != null ? 1 : 0,
                      onClear: () => _update(_draft.clearGroup('durationMax')),
                      child: _minutesSlider(
                        min: f.durationMin,
                        max: f.durationMax,
                        value: _draft.durationMax,
                        onChanged: (v) => _update(_draft.copyWith(durationMax: v)),
                      ),
                    ),

                  if (f.hasLayoverBand)
                    _section(
                      id: 'layoverMax',
                      title: 'Layover duration',
                      activeCount: _draft.layoverMax != null ? 1 : 0,
                      onClear: () => _update(_draft.clearGroup('layoverMax')),
                      child: _minutesSlider(
                        min: f.layoverMin,
                        max: f.layoverMax,
                        value: _draft.layoverMax,
                        onChanged: (v) => _update(_draft.copyWith(layoverMax: v)),
                      ),
                    ),

                  if (f.layoverAirports.isNotEmpty)
                    _section(
                      id: 'layoverAirports',
                      title: 'Layover airport',
                      activeCount: _draft.layoverAirports.length,
                      onClear: () =>
                          _update(_draft.clearGroup('layoverAirports')),
                      child: Column(
                        children: [
                          for (final a in f.layoverAirports)
                            _checkRow(
                              label: a.label,
                              count: a.count,
                              minPrice: a.minPrice,
                              checked: _draft.layoverAirports.contains(a.value),
                              onChanged: () => _update(
                                _draft.toggle('layoverAirports', a.value),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (f.fareTypes.length > 1)
                    _section(
                      id: 'fareTypes',
                      title: 'Fare type',
                      activeCount: _draft.fareTypes.length,
                      onClear: () => _update(_draft.clearGroup('fareTypes')),
                      child: Column(
                        children: [
                          for (final t in f.fareTypes)
                            _checkRow(
                              label: t.label,
                              count: t.count,
                              checked: _draft.fareTypes.contains(t.value),
                              onChanged: () =>
                                  _update(_draft.toggle('fareTypes', t.value)),
                            ),
                        ],
                      ),
                    ),

                  if (f.cancellationTypes.isNotEmpty)
                    _section(
                      id: 'cancellationTypes',
                      title: 'Cancellation',
                      activeCount: _draft.cancellationTypes.length,
                      onClear: () =>
                          _update(_draft.clearGroup('cancellationTypes')),
                      child: Column(
                        children: [
                          for (final c in f.cancellationTypes)
                            _checkRow(
                              label: c.label,
                              count: c.count,
                              checked: _draft.cancellationTypes.contains(
                                c.value,
                              ),
                              onChanged: () => _update(
                                _draft.toggle('cancellationTypes', c.value),
                              ),
                            ),
                        ],
                      ),
                    ),

                  _section(
                    id: 'more',
                    title: 'More filters',
                    activeCount:
                        (_draft.baggageOnly ? 1 : 0) +
                        (_draft.hideNearbyAirports ? 1 : 0),
                    onClear: () => _update(
                      _draft.copyWith(
                        baggageOnly: false,
                        hideNearbyAirports: false,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (f.baggageCount > 0)
                          _checkRow(
                            label: 'Check-in baggage included',
                            count: f.baggageCount,
                            checked: _draft.baggageOnly,
                            onChanged: () => _update(
                              _draft.copyWith(baggageOnly: !_draft.baggageOnly),
                            ),
                          ),
                        _checkRow(
                          label: 'Hide nearby airports',
                          checked: _draft.hideNearbyAirports,
                          onChanged: () => _update(
                            _draft.copyWith(
                              hideNearbyAirports: !_draft.hideNearbyAirports,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (f.departureAirports.length > 1 ||
                      f.arrivalAirports.length > 1)
                    _section(
                      id: 'airports',
                      title: 'Airports',
                      activeCount: _draft.airports.length,
                      onClear: () => _update(_draft.clearGroup('airports')),
                      child: Column(
                        children: [
                          if (f.departureAirports.length > 1) ...[
                            _groupHeading('Departure from'),
                            for (final a in f.departureAirports)
                              _checkRow(
                                label: a.label,
                                count: a.count,
                                minPrice: a.minPrice,
                                checked: _draft.airports.contains(a.value),
                                onChanged: () =>
                                    _update(_draft.toggle('airports', a.value)),
                              ),
                          ],
                          if (f.arrivalAirports.length > 1) ...[
                            _groupHeading('Arrival at'),
                            for (final a in f.arrivalAirports)
                              _checkRow(
                                label: a.label,
                                count: a.count,
                                minPrice: a.minPrice,
                                checked: _draft.airports.contains(a.value),
                                onChanged: () =>
                                    _update(_draft.toggle('airports', a.value)),
                              ),
                          ],
                        ],
                      ),
                    ),

                  if (f.departureTerminals.length > 1 ||
                      f.arrivalTerminals.length > 1)
                    _section(
                      id: 'terminals',
                      title: 'Terminals',
                      activeCount: _draft.terminals.length,
                      onClear: () => _update(_draft.clearGroup('terminals')),
                      child: Column(
                        children: [
                          if (f.departureTerminals.length > 1) ...[
                            _groupHeading('Departure'),
                            for (final t in f.departureTerminals)
                              _checkRow(
                                label: t.label,
                                count: t.count,
                                checked: _draft.terminals.contains(t.value),
                                onChanged: () => _update(
                                  _draft.toggle('terminals', t.value),
                                ),
                              ),
                          ],
                          if (f.arrivalTerminals.length > 1) ...[
                            _groupHeading('Arrival'),
                            for (final t in f.arrivalTerminals)
                              _checkRow(
                                label: t.label,
                                count: t.count,
                                checked: _draft.terminals.contains(t.value),
                                onChanged: () => _update(
                                  _draft.toggle('terminals', t.value),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),

                  _section(
                    id: 'timeframe',
                    title: 'Specific timeframe',
                    activeCount:
                        (_draft.departureFrom != null ||
                                _draft.departureTo != null
                            ? 1
                            : 0) +
                        (_draft.arrivalFrom != null || _draft.arrivalTo != null
                            ? 1
                            : 0),
                    onClear: () => _update(_draft.clearGroup('timeframe')),
                    child: Column(
                      children: [
                        _timeWindowRow(
                          label: 'Departs between',
                          from: _draft.departureFrom,
                          to: _draft.departureTo,
                          onFrom: (v) =>
                              _update(_draft.copyWith(departureFrom: v)),
                          onTo: (v) => _update(_draft.copyWith(departureTo: v)),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _timeWindowRow(
                          label: 'Arrives between',
                          from: _draft.arrivalFrom,
                          to: _draft.arrivalTo,
                          onFrom: (v) =>
                              _update(_draft.copyWith(arrivalFrom: v)),
                          onTo: (v) => _update(_draft.copyWith(arrivalTo: v)),
                        ),
                      ],
                    ),
                  ),

                  _section(
                    id: 'flightNumbers',
                    title: 'Flight number',
                    activeCount: _draft.flightNumbers
                        .where((n) => n.trim().isNotEmpty)
                        .length,
                    onClear: () {
                      _flightNoQuery.clear();
                      _update(_draft.clearGroup('flightNumbers'));
                    },
                    child: AppTextField(
                      controller: _flightNoQuery,
                      hint: 'e.g. 6E-2134 or 2134',
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (v) => _update(
                        _draft.copyWith(
                          flightNumbers: v.trim().isEmpty ? const [] : [v.trim()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _footer(count),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Chrome
  // -------------------------------------------------------------------------

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
                _flightNoQuery.clear();
                _airlineQuery.clear();
                _update(FlightFilters.empty);
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
        // A draft that matches nothing is not applied — the button says so
        // rather than dropping the user onto an empty list.
        label: count == 0
            ? 'No flights match'
            : 'Show $count flight${count == 1 ? '' : 's'}',
        onPressed: count == 0
            ? null
            : () => Navigator.of(context).pop(_draft),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Sections
  // -------------------------------------------------------------------------

  Widget _section({
    required String id,
    required String title,
    required Widget child,
    int activeCount = 0,
    VoidCallback? onClear,
  }) {
    final open = _expanded.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: () => setState(() {
            if (!_expanded.remove(id)) _expanded.add(id);
          }),
          borderRadius: AppRadii.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    activeCount > 0 ? '$title ($activeCount)' : title,
                    style: AppText.bodyStrong.copyWith(
                      color: activeCount > 0
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (activeCount > 0 && onClear != null)
                  PremiumButton.text(
                    label: 'Clear',
                    size: PremiumButtonSize.small,
                    onPressed: onClear,
                  ),
                Icon(
                  open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppMotion.fast,
          crossFadeState: open
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: child,
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
        const Divider(height: 1, color: AppColors.divider),
      ],
    );
  }

  Widget _groupHeading(String text) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.sm,
      bottom: AppSpacing.xxs,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: AppText.overline),
    ),
  );

  Widget _popularSection(FlightFacets f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Text('Popular filters', style: AppText.overline),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final p in f.popular)
                _pill(
                  label: p.label,
                  selected: p.key == 'stops'
                      ? _draft.stops.contains(int.tryParse(p.value) ?? -1)
                      : _draft.isSelected(p.key, p.value),
                  onTap: () => _update(
                    p.key == 'stops'
                        ? _draft.toggle('stops', int.tryParse(p.value) ?? 0)
                        : _draft.toggle(p.key, p.value),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ),
    );
  }

  Widget _airlinesSection(FlightFacets f) {
    final query = _airlineQuery.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? f.airlines
        : f.airlines
              .where(
                (a) =>
                    a.name.toLowerCase().contains(query) ||
                    a.value.toLowerCase().contains(query),
              )
              .toList();

    return Column(
      children: [
        if (f.airlines.length > 6)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppTextField(
              controller: _airlineQuery,
              hint: 'Search airlines',
              prefixIcon: Icons.search_rounded,
              onChanged: (_) => setState(() {}),
            ),
          ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('No airlines match', style: AppText.caption),
          ),
        for (final a in visible)
          _checkRow(
            label: a.name.isEmpty ? a.value : a.name,
            count: a.count,
            minPrice: a.minPrice,
            leading: AirlineLogo(code: a.value),
            checked: _draft.airlines.contains(a.value),
            onChanged: () => _update(_draft.toggle('airlines', a.value)),
          ),
      ],
    );
  }

  Widget _priceSlider(FlightFacets f) {
    final lo = _draft.priceMin ?? f.priceMin;
    final hi = _draft.priceMax ?? f.priceMax;
    // A band with no spread would make RangeSlider throw; the caller only shows
    // this section when hasPriceBand is true, and this keeps it safe anyway.
    final safeLo = lo.clamp(f.priceMin, f.priceMax);
    final safeHi = hi.clamp(safeLo, f.priceMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${formatPrice(safeLo)} – ${formatPrice(safeHi)}',
          style: AppText.bodyStrong,
          textAlign: TextAlign.center,
        ),
        RangeSlider(
          min: f.priceMin,
          max: f.priceMax,
          values: RangeValues(safeLo, safeHi),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.divider,
          labels: RangeLabels(formatPrice(safeLo), formatPrice(safeHi)),
          onChanged: (v) => _update(
            _draft.copyWith(
              priceMin: v.start <= f.priceMin ? null : v.start,
              priceMax: v.end >= f.priceMax ? null : v.end,
            ),
          ),
        ),
      ],
    );
  }

  Widget _minutesSlider({
    required int min,
    required int max,
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    final current = (value ?? max).clamp(min, max).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          value == null
              ? 'Any (up to ${formatFilterMinutes(max)})'
              : 'Under ${formatFilterMinutes(value)}',
          style: AppText.bodyStrong,
          textAlign: TextAlign.center,
        ),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          value: current,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.divider,
          label: formatFilterMinutes(current.round()),
          onChanged: (v) =>
              onChanged(v.round() >= max ? null : v.round()),
        ),
      ],
    );
  }

  Widget _slotGrid({
    required List<FacetItem> slots,
    required Set<String> selected,
    required ValueChanged<String> onTap,
  }) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final s in slots)
          _pill(
            label: '${s.label}  ·  ${s.count}',
            selected: selected.contains(s.value),
            onTap: () => onTap(s.value),
          ),
      ],
    );
  }

  Widget _timeWindowRow({
    required String label,
    required String? from,
    required String? to,
    required ValueChanged<String?> onFrom,
    required ValueChanged<String?> onTo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.formLabel),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _timeDropdown(
                value: from,
                hint: 'From',
                onChanged: onFrom,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _timeDropdown(value: to, hint: 'To', onChanged: onTo),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeDropdown({
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: AppText.body),
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Any', style: AppText.body),
            ),
            for (final t in kTimeOptions)
              DropdownMenuItem<String?>(
                value: t,
                child: Text(t, style: AppText.body),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Rows
  // -------------------------------------------------------------------------

  Widget _checkRow({
    required String label,
    required bool checked,
    required VoidCallback onChanged,
    int? count,
    double? minPrice,
    Widget? leading,
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
            if (leading != null) ...[
              leading,
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                label,
                style: AppText.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (minPrice != null && minPrice > 0)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text(formatPrice(minPrice), style: AppText.labelSm),
              ),
            if (count != null)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Text('$count', style: AppText.caption),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill({
    required String label,
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
        child: Text(
          label,
          style: AppText.labelSm.copyWith(
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Applied-filter rail
// ---------------------------------------------------------------------------

/// Horizontal rail of removable chips for whatever is currently applied.
class AppliedFiltersRail extends StatelessWidget {
  const AppliedFiltersRail({
    super.key,
    required this.chips,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<AppliedFilterChip> chips;
  final ValueChanged<AppliedFilterChip> onRemove;
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
                      style: AppText.labelSm.copyWith(
                        color: AppColors.primary,
                      ),
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
