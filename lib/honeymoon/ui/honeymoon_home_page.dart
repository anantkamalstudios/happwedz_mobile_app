/// Honeymoon landing: hero, service tabs and the search card.
///
/// The page owns search state only. Every network call goes through
/// [HoneymoonApi]; no HTTP or JSON parsing happens in this file.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../honeymoon_config.dart';
import '../models/honeymoon_models.dart';
import 'cab_results_page.dart';
import 'flight_results_page.dart';
import 'hotel_results_page.dart';
import 'insurance_results_page.dart';
import 'widgets/honeymoon_widgets.dart';

class HoneymoonHomePage extends StatefulWidget {
  const HoneymoonHomePage({super.key});

  @override
  State<HoneymoonHomePage> createState() => _HoneymoonHomePageState();
}

class _HoneymoonHomePageState extends State<HoneymoonHomePage> {
  final HoneymoonApi _api = HoneymoonApi();
  HoneymoonService _service = HoneymoonService.hotels;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HoneymoonHero(
              child: HoneymoonServiceTabs(
                selected: _service,
                onSelected: (s) => setState(() => _service = s),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: HoneymoonSearchCard(
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(
                        sizeFactor: anim,
                        axisAlignment: -1,
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_service),
                      child: switch (_service) {
                        HoneymoonService.hotels => HotelSearchForm(api: _api),
                        HoneymoonService.flights => FlightSearchForm(api: _api),
                        HoneymoonService.insurance =>
                          InsuranceSearchForm(api: _api),
                        HoneymoonService.carRental =>
                          CabSearchForm(api: _api),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: _WhyBookWithUs()),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxxl),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hotels
// ---------------------------------------------------------------------------

class HotelSearchForm extends StatefulWidget {
  const HotelSearchForm({super.key, required this.api});

  final HoneymoonApi api;

  @override
  State<HotelSearchForm> createState() => _HotelSearchFormState();
}

class _HotelSearchFormState extends State<HotelSearchForm> {
  final TextEditingController _destinationController = TextEditingController();

  HoneymoonDestination? _destination;
  DateTime? _checkIn;
  DateTime? _checkOut;
  final List<RoomOccupancy> _rooms = [
    RoomOccupancy(adults: HoneymoonConfig.defaultAdults),
  ];

  bool _submitting = false;
  String? _destinationError;
  String? _dateError;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  int get _travellerCount =>
      _rooms.fold(0, (sum, r) => sum + r.adults + r.children);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final range = await showDateRangePicker(
      context: context,
      // Start date can never be in the past.
      firstDate: today,
      lastDate: today.add(
        const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
      ),
      initialDateRange: _checkIn != null && _checkOut != null
          ? DateTimeRange(start: _checkIn!, end: _checkOut!)
          : null,
      helpText: 'Select your travel dates',
      saveText: 'Done',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (range == null) return;
    setState(() {
      _checkIn = range.start;
      _checkOut = range.end;
      _dateError = null;
    });
  }

  Future<void> _openTravellerSheet() async {
    await AppBottomSheet.show(
      context,
      title: 'Rooms & travellers',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _rooms.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text('Room ${i + 1}', style: AppText.sectionTitle),
                    ),
                    if (_rooms.length > 1)
                      PremiumButton.text(
                        label: 'Remove',
                        size: PremiumButtonSize.small,
                        onPressed: () {
                          setSheetState(() => _rooms.removeAt(i));
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                CounterRow(
                  title: 'Adults',
                  subtitle: 'Age 12+',
                  value: _rooms[i].adults,
                  min: 1,
                  max: HoneymoonConfig.maxTravellers,
                  onChanged: (v) {
                    setSheetState(() => _rooms[i].adults = v);
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CounterRow(
                  title: 'Children',
                  subtitle: 'Age 0–11',
                  value: _rooms[i].children,
                  max: 6,
                  onChanged: (v) {
                    setSheetState(() {
                      final ages = _rooms[i].childAges;
                      if (v > ages.length) {
                        ages.add(8);
                      } else if (ages.isNotEmpty) {
                        ages.removeLast();
                      }
                    });
                    setState(() {});
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              if (_rooms.length < 4)
                PremiumButton.outlined(
                  label: 'Add another room',
                  icon: Icons.add_rounded,
                  size: PremiumButtonSize.medium,
                  onPressed: () {
                    setSheetState(() => _rooms.add(RoomOccupancy(adults: 2)));
                    setState(() {});
                  },
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
      _destinationError = _destination == null
          ? 'Choose where you would like to go'
          : null;
      _dateError = (_checkIn == null || _checkOut == null)
          ? 'Select your travel dates'
          : (!_checkOut!.isAfter(_checkIn!)
                ? 'Check-out must be after check-in'
                : null);
    });
    return _destinationError == null && _dateError == null;
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      final result = await widget.api.searchHotels(
        destination: _destination!,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        rooms: _rooms,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: HotelResultsPage(
            api: widget.api,
            destination: _destination!,
            checkIn: _checkIn!,
            checkOut: _checkOut!,
            rooms: _rooms,
            initialResult: result,
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
        DestinationField(
          api: widget.api,
          controller: _destinationController,
          selected: _destination,
          errorText: _destinationError,
          onSelected: (d) => setState(() {
            _destination = d;
            _destinationError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Dates side by side, but they wrap on very narrow screens.
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 320;
            final checkIn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldLabel('Check-in'),
                TapField(
                  icon: Icons.calendar_today_rounded,
                  value: formatTripDate(_checkIn),
                  placeholder: 'Add date',
                  onTap: _pickDates,
                ),
              ],
            );
            final checkOut = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldLabel('Check-out'),
                TapField(
                  icon: Icons.event_available_rounded,
                  value: formatTripDate(_checkOut),
                  placeholder: 'Add date',
                  onTap: _pickDates,
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  checkIn,
                  const SizedBox(height: AppSpacing.md),
                  checkOut,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: checkIn),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: checkOut),
              ],
            );
          },
        ),
        if ((_dateError ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs, left: 2),
            child: Text(_dateError!, style: AppText.error),
          ),

        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Travellers'),
        TapField(
          icon: Icons.favorite_rounded,
          value:
              '$_travellerCount Traveller${_travellerCount == 1 ? '' : 's'}'
              ' · ${_rooms.length} Room${_rooms.length == 1 ? '' : 's'}',
          onTap: _openTravellerSheet,
        ),

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: 'Search Honeymoon Stays',
          icon: Icons.search_rounded,
          isLoading: _submitting,
          onPressed: _search,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Destination autocomplete
// ---------------------------------------------------------------------------

/// Debounced destination picker backed by `hotels/city-regions` and
/// `hotels/static-hotels/search`. There is no honeymoon-destination catalogue
/// endpoint, so suggestions come from the live hotel geography.
class DestinationField extends StatefulWidget {
  const DestinationField({
    super.key,
    required this.api,
    required this.controller,
    required this.onSelected,
    this.selected,
    this.errorText,
  });

  final HoneymoonApi api;
  final TextEditingController controller;
  final ValueChanged<HoneymoonDestination> onSelected;
  final HoneymoonDestination? selected;
  final String? errorText;

  @override
  State<DestinationField> createState() => _DestinationFieldState();
}

class _DestinationFieldState extends State<DestinationField> {
  Timer? _debounce;
  List<HoneymoonDestination> _results = const [];
  bool _loading = false;
  bool _open = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _open = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _lookup(value));
  }

  Future<void> _lookup(String keyword) async {
    setState(() {
      _loading = true;
      _open = true;
      _error = null;
    });

    try {
      // Cities/regions first, then specific properties.
      final results = await Future.wait([
        widget.api.searchCityRegions(keyword),
        widget.api.searchStaticHotels(keyword),
      ]);

      if (!mounted) return;
      setState(() {
        _results = [...results[0], ...results[1]].take(24).toList();
        _loading = false;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = const [];
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: widget.controller,
          hint: 'Search destination, city or romantic getaway',
          prefixIcon: Icons.place_outlined,
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : Icons.close_rounded,
          onSuffixTap: () {
            widget.controller.clear();
            setState(() {
              _results = const [];
              _open = false;
            });
          },
          errorText: widget.errorText,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
        ),

        if (_open)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: AppColors.divider),
              boxShadow: AppColors.shadowSm,
            ),
            child: _buildSuggestions(),
          ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppLoader(size: 22),
      );
    }

    if ((_error ?? '').isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(_error!, style: AppText.bodySm)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No destinations matched that search.',
          style: AppText.bodySm,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, i) {
        final d = _results[i];
        return Pressable(
          onTap: () {
            widget.controller.text = d.displayName;
            setState(() => _open = false);
            FocusScope.of(context).unfocus();
            widget.onSelected(d);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  d.isHotel ? Icons.hotel_rounded : Icons.location_city_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        d.displayName,
                        style: AppText.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (d.subtitle.isNotEmpty)
                        Text(
                          d.subtitle,
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Trust strip
// ---------------------------------------------------------------------------

class _WhyBookWithUs extends StatelessWidget {
  const _WhyBookWithUs();

  static const _items = [
    (Icons.verified_rounded, 'Handpicked stays', 'Curated romantic properties'),
    (Icons.support_agent_rounded, 'Real support', 'Help before and during travel'),
    (Icons.lock_rounded, 'Secure booking', 'Protected payments end to end'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Why book with HappyWedz', accent: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _items.length - 1 ? 0 : AppSpacing.md,
                    ),
                    child: FadeSlideIn(
                      delay: AppMotion.staggerFor(i),
                      child: AppCard.outlined(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.pinkSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _items[i].$1,
                                size: 19,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_items[i].$2, style: AppText.cardTitle),
                                  Text(
                                    _items[i].$3,
                                    style: AppText.cardSubtitle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}