/// Cancelling a flight booking — the dashboard's `flightBookings/
/// CancellationModal.jsx`, with the reason list of the honeymoon
/// `CancellationModal.jsx`.
///
/// ```
/// loading   booking-details — refuses a booking already CANCELLED
/// select    travellers per trip (all ticked) + a cancellation reason
/// charges   cancel-charges {trips, remarks}; 2512 "amendment in progress"
///           is a hard stop, any other refusal just means no refund preview
/// confirm   "Booking will be auto cancelled. Are you sure?"
/// done      cancel {trips, remarks, skipCharges, charges} → amendment id
/// ```
///
/// Pops with the `tj/oms/cancel` answer (`amendment_id`, `amendment_status`,
/// `cancelled`) once the traveller taps Done, or null if they backed out.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import '../booking/booking_widgets.dart';
import '../widgets/flight_widgets.dart';
import '../widgets/honeymoon_widgets.dart';

enum _Step {
  loading,
  select,
  gettingCharges,
  charges,
  confirm,
  submitting,
  done,
  error,
}

class FlightCancellationPage extends StatefulWidget {
  const FlightCancellationPage({
    super.key,
    required this.api,
    required this.orderId,
    this.provider = 'tripjack',
  });

  final HoneymoonApi api;
  final String orderId;
  final String provider;

  @override
  State<FlightCancellationPage> createState() => _FlightCancellationPageState();
}

class _FlightCancellationPageState extends State<FlightCancellationPage> {
  _Step _step = _Step.loading;
  String _error = '';

  List<Map<String, dynamic>> _trips = const [];
  List<BookedTraveller> _travellers = const [];

  /// Trip index → the traveller indexes being cancelled on it.
  final Map<int, Set<int>> _selected = {};
  String _reason = '';

  FlightCancelQuote? _quote;
  Map<String, dynamic> _result = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _step = _Step.loading;
      _error = '';
    });
    try {
      final details = await widget.api.fetchFlightBooking(widget.orderId);
      if (!mounted) return;
      if (details.status == 'CANCELLED') {
        setState(() {
          _error = 'This booking is already cancelled.';
          _step = _Step.error;
        });
        return;
      }
      final trips = details.trips;
      final travellers = details.travellers;
      if (trips.isEmpty || travellers.isEmpty) {
        setState(() {
          _error = 'Could not load booking details. Please try again.';
          _step = _Step.error;
        });
        return;
      }
      setState(() {
        _trips = trips;
        _travellers = travellers;
        _selected
          ..clear()
          ..addAll({
            for (var t = 0; t < trips.length; t++)
              t: {for (var p = 0; p < travellers.length; p++) p},
          });
        _step = _Step.select;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = firstNonEmpty([
          readKey(e.data, 'message'),
        ], fallback: e.message.isEmpty ? 'Failed to load booking.' : e.message);
        _step = _Step.error;
      });
    }
  }

  /// `[{src, dest, departureDate, travellers: [{fn, ln}]}]` — only trips with
  /// someone ticked.
  List<Map<String, dynamic>> _buildTrips() {
    final out = <Map<String, dynamic>>[];
    for (var t = 0; t < _trips.length; t++) {
      final segs = asList(readKey(_trips[t], 'sI'));
      if (segs.isEmpty) continue;
      final src = asString(digPath(segs.first, ['da', 'code']));
      final dest = asString(digPath(segs.last, ['aa', 'code']));
      final date = asString(readKey(segs.first, 'dt')).split('T').first;
      final picked = _selected[t] ?? const <int>{};
      final travellers = [
        for (var p = 0; p < _travellers.length; p++)
          if (picked.contains(p))
            {'fn': _travellers[p].firstName, 'ln': _travellers[p].lastName},
      ];
      if (src.isEmpty || dest.isEmpty || date.isEmpty || travellers.isEmpty) {
        continue;
      }
      out.add({
        'src': src,
        'dest': dest,
        'departureDate': date,
        'travellers': travellers,
      });
    }
    return out;
  }

  bool get _canProceed =>
      _selected.values.any((s) => s.isNotEmpty) && _reason.trim().isNotEmpty;

  Future<void> _getCharges() async {
    setState(() => _step = _Step.gettingCharges);
    try {
      final quote = await widget.api.fetchFlightCancelQuote(
        widget.orderId,
        provider: widget.provider,
        trips: _buildTrips(),
        remarks: _reason,
      );
      if (!mounted) return;
      if (quote.amendmentInProgress) {
        setState(() {
          _error =
              'A cancellation for this booking is already in progress. Please '
              'check back later or contact support.';
          _step = _Step.error;
        });
        return;
      }
      // Any other refusal (e.g. 2563 "charges not available") only means no
      // refund preview; the cancellation itself still goes through.
      setState(() {
        _quote = quote;
        _step = _Step.charges;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = firstNonEmpty([
          readKey(e.data, 'message'),
        ], fallback: 'Failed to get cancellation charges.');
        _step = _Step.error;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _step = _Step.submitting);
    try {
      final result = await widget.api.cancelFlightBooking(
        widget.orderId,
        provider: widget.provider,
        remarks: _reason,
        trips: _buildTrips(),
        charges: _quote?.raw,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _step = _Step.done;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message.isEmpty
            ? 'Cancellation failed. Please try again.'
            : e.message;
        _step = _Step.error;
      });
    }
  }

  bool get _busy => const {
    _Step.loading,
    _Step.gettingCharges,
    _Step.submitting,
  }.contains(_step);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy && _step != _Step.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == _Step.done) Navigator.pop(context, _result);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          elevated: true,
          title: switch (_step) {
            _Step.charges => 'CANCELLATION & REFUND DETAILS',
            _Step.done => 'THANK YOU',
            _ => 'Cancel booking',
          },
          onBack: _busy
              ? () {}
              : () => _step == _Step.done
                    ? Navigator.pop(context, _result)
                    : Navigator.pop(context),
        ),
        body: switch (_step) {
          _Step.loading ||
          _Step.gettingCharges ||
          _Step.submitting => const Center(child: AppLoader()),
          _Step.select => _selectView(),
          _Step.charges => _chargesView(),
          _Step.confirm => _confirmView(),
          _Step.done => _doneView(),
          _Step.error => _errorView(),
        },
        bottomNavigationBar: _footer(),
      ),
    );
  }

  Widget? _footer() {
    Widget bar(List<Widget> children) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: children[i]),
            ],
          ],
        ),
      ),
    );

    return switch (_step) {
      _Step.select => bar([
        PremiumButton.outlined(
          label: 'Go Back',
          size: PremiumButtonSize.medium,
          onPressed: () => Navigator.pop(context),
        ),
        PremiumButton(
          label: 'PROCEED TO CANCELLATION',
          size: PremiumButtonSize.medium,
          onPressed: _canProceed ? _getCharges : null,
        ),
      ]),
      _Step.charges => bar([
        PremiumButton.outlined(
          label: 'CLOSE',
          size: PremiumButtonSize.medium,
          onPressed: () => setState(() => _step = _Step.select),
        ),
        PremiumButton(
          label: 'PROCEED TO REFUND',
          size: PremiumButtonSize.medium,
          onPressed: () => setState(() => _step = _Step.confirm),
        ),
      ]),
      _Step.confirm => bar([
        PremiumButton.outlined(
          label: 'Back',
          size: PremiumButtonSize.medium,
          onPressed: () => setState(() => _step = _Step.charges),
        ),
        PremiumButton(
          label: 'Proceed',
          size: PremiumButtonSize.medium,
          onPressed: _submit,
        ),
      ]),
      _Step.done => bar([
        PremiumButton(
          label: 'Done',
          size: PremiumButtonSize.medium,
          onPressed: () => Navigator.pop(context, _result),
        ),
      ]),
      _Step.error => bar([
        PremiumButton.outlined(
          label: 'Close',
          size: PremiumButtonSize.medium,
          onPressed: () => Navigator.pop(context),
        ),
        if (!_error.contains('already cancelled') &&
            !_error.contains('already in progress'))
          PremiumButton(
            label: 'Try Again',
            size: PremiumButtonSize.medium,
            onPressed: _load,
          ),
      ]),
      _ => null,
    };
  }

  // -------------------------------------------------------------------------
  // Steps
  // -------------------------------------------------------------------------

  Widget _selectView() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text('01. Flight Details', style: AppText.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        for (var t = 0; t < _trips.length; t++) ...[
          _tripCard(t),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.sm),
        Text('02. Select Cancellation Reason', style: AppText.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        for (final group in kFlightCancelReasons) ...[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(group.group, style: AppText.labelSm),
          ),
          for (final item in group.items)
            Pressable(
              onTap: () => setState(() => _reason = item.id),
              borderRadius: AppRadii.rMd,
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _reason == item.id
                      ? AppColors.pinkSurface
                      : AppColors.surface,
                  borderRadius: AppRadii.rMd,
                  border: Border.all(
                    color: _reason == item.id
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _reason == item.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      size: 18,
                      color: _reason == item.id
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.id, style: AppText.bodyStrong),
                          if (item.desc.isNotEmpty)
                            Text(item.desc, style: AppText.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _tripCard(int t) {
    final segs = asList(readKey(_trips[t], 'sI'));
    final first = segs.firstOrNull;
    final last = segs.lastOrNull;
    final code = asString(digPath(first, ['fD', 'aI', 'code']));
    final name = asString(digPath(first, ['fD', 'aI', 'name']));
    final numbers = [
      for (final s in segs)
        '${asString(digPath(s, ['fD', 'aI', 'code']))}-'
            '${asString(digPath(s, ['fD', 'fN']))}',
    ].join(', ');
    final minutes = segs.fold<int>(
      0,
      (n, s) => n + asInt(readKey(s, 'duration')) + asInt(readKey(s, 'cT')),
    );
    final stops = segs.length - 1;
    String time(Object? v) {
      final d = DateTime.tryParse(asString(v));
      return d == null
          ? '--:--'
          : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }

    final picked = _selected[t] ??= <int>{};

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AirlineLogo(code: code, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$name · $numbers', style: AppText.bodyStrong),
                    Text(
                      '${asString(digPath(first, ['da', 'code']))} '
                      '(${time(readKey(first, 'dt'))}) → '
                      '${asString(digPath(last, ['aa', 'code']))} '
                      '(${time(readKey(last, 'at'))})  '
                      '${flightMinutes(minutes)} · '
                      '${stops == 0 ? 'Non-Stop' : '$stops Stop${stops > 1 ? 's' : ''}'}',
                      style: AppText.caption,
                    ),
                    Text(
                      flightLongDate(
                        DateTime.tryParse(asString(readKey(first, 'dt'))),
                      ),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text('Passenger Details :', style: AppText.labelSm),
              ),
              TextButton(
                onPressed: () => setState(
                  () => picked
                    ..clear()
                    ..addAll([for (var p = 0; p < _travellers.length; p++) p]),
                ),
                child: const Text('Select All Passenger'),
              ),
            ],
          ),
          for (var p = 0; p < _travellers.length; p++)
            CheckboxListTile.adaptive(
              value: picked.contains(p),
              onChanged: (_) => setState(() {
                if (!picked.remove(p)) picked.add(p);
              }),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                '${_travellers[p].displayName.toUpperCase()} '
                '(${_travellers[p].initial})',
                style: AppText.bodySm,
              ),
            ),
        ],
      ),
    );
  }

  Widget _chargesView() {
    final quote = _quote;
    final refund = quote?.refundAmount;
    final charge = quote?.amendmentCharges ?? 0;
    final available = quote != null && quote.available && refund != null;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (available) ...[
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Approximate Refund Amount:',
                    style: AppText.bodyStrong,
                  ),
                ),
                Text(
                  formatFlightFare(refund),
                  style: AppText.price.copyWith(color: AppColors.successDark),
                ),
              ],
            ),
          ),
          if (charge > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cancellation charges:',
                      style: AppText.caption,
                    ),
                  ),
                  Text(formatFlightFare(charge), style: AppText.caption),
                ],
              ),
            ),
        ] else
          InfoBanner(
            icon: Icons.info_outline_rounded,
            message:
                'Refund charges not available right now.\n'
                '${quote?.message.isNotEmpty == true ? quote!.message : 'The refund amount will be confirmed after cancellation. TripJack support will process it as per the airline policy.'}',
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "• Once cancelled, we'll coordinate with the airline and process the "
          'refund as per their policy.',
          style: AppText.bodySm,
        ),
        Text(
          '• Until the refund is received, the request will remain in '
          '"Pending with supplier" status.',
          style: AppText.bodySm,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Do you want to cancel the booking and proceed?',
          style: AppText.bodyStrong,
        ),
      ],
    );
  }

  Widget _confirmView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Booking will be auto cancelled.', style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          Text('Are you sure?', style: AppText.bodySm),
        ],
      ),
    );
  }

  Widget _doneView() {
    final id = asString(readKey(_result, 'amendment_id'));
    final cancelled = readKey(_result, 'cancelled') == true;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppCard(
              child: Column(
                children: [
                  Text('Your Amendment ID:', style: AppText.caption),
                  SelectableText(
                    id.isEmpty ? '—' : id,
                    style: AppText.sectionTitle.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              cancelled
                  ? 'Your Booking has been cancelled Successfully.'
                  : firstNonEmpty(
                      [readKey(_result, 'message')],
                      fallback: 'Your cancellation request has been submitted.',
                    ),
              style: AppText.bodyStrong.copyWith(color: AppColors.successDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          _error,
          style: AppText.body.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
