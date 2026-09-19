/// Building blocks the hotel detail, booking and booking-detail screens share:
/// the cancellation-slab table, the fare breakup and the policy notes.
///
/// The web shows these as modals (`RoomPolicyModal`, `RoomFareInfoModal`) and
/// as panels on its review page (`TripJackBookingReview`); on a phone the
/// modals become bottom sheets and the panels become cards, with the same
/// content and wording.
library;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/honeymoon_models.dart';
import '../../models/hotel_models.dart';
import '../honeymoon_home_page.dart';
import 'honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

/// `₹10,971.17` — a payment figure keeps its paise so a breakup reconciles,
/// where [formatPrice] rounds for display (the web's `formatFare`).
String formatHotelFare(double amount, {String currency = 'INR'}) {
  final symbol = currency == 'INR' ? '₹' : '$currency ';
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final whole = fixed.split('.').first;
  final paise = fixed.split('.').last;
  final grouped = formatPrice(double.parse(whole), symbol: '');
  return '${negative ? '-' : ''}$symbol$grouped.$paise';
}

/// `16-10-2026` — TripJack's cancellation table format.
String formatPolicyDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}-${two(date.month)}-${date.year}';
}

/// `16-10-2026 11:59 PM` — the slab boundaries on the policy sheet.
String formatPolicyDateTime(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minutes = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${formatPolicyDate(value)} $hour12:$minutes $period';
}

// ---------------------------------------------------------------------------
// Cancellation policy
// ---------------------------------------------------------------------------

/// The slab table: "On or after · On or before · Charges", followed by the
/// no-show and early check-out notes TripJack prints under every table.
class HotelPenaltyTable extends StatelessWidget {
  const HotelPenaltyTable({
    super.key,
    required this.penalties,
    this.currency = 'INR',
    this.showTime = false,
  });

  final List<HotelPenalty> penalties;
  final String currency;

  /// The web's room policy modal shows the time; the review page does not.
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    String date(String v) => v.isEmpty
        ? 'Hotel policy'
        : (showTime ? formatPolicyDateTime(v) : formatPolicyDate(v));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (penalties.isEmpty)
          Text(
            'Detailed cancellation slabs are not available for this room.',
            style: AppText.bodySm,
          )
        else
          // Stacked rows rather than a three-column table: dates with times
          // do not fit three abreast at 320 px.
          for (var i = 0; i < penalties.length; i++) ...[
            if (i > 0)
              const Divider(height: AppSpacing.lg, color: AppColors.divider),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('On or after', style: AppText.caption),
                      Text(date(penalties[i].from), style: AppText.bodySm),
                      const SizedBox(height: AppSpacing.xxs),
                      Text('On or before', style: AppText.caption),
                      Text(date(penalties[i].to), style: AppText.bodySm),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Charges', style: AppText.caption),
                    Text(
                      penalties[i].amount == null
                          ? 'As per hotel policy'
                          : penalties[i].amount == 0
                          ? 'Free'
                          : formatHotelFare(
                              penalties[i].amount!,
                              currency: currency,
                            ),
                      style: AppText.bodyStrong.copyWith(
                        color: penalties[i].amount == 0
                            ? AppColors.successDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        const SizedBox(height: AppSpacing.md),
        Text(
          '• No show will attract full cancellation charge unless otherwise '
          'specified.',
          style: AppText.caption,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '• Early check out will attract full cancellation charge unless '
          'otherwise specified.',
          style: AppText.caption,
        ),
      ],
    );
  }
}

/// The web's `RoomPolicyModal`: refundability, a "Now → Check-in" bar and
/// the slab table.
Future<void> showHotelCancellationSheet(
  BuildContext context, {
  required HotelRoomOption option,
  DateTime? checkIn,
}) {
  final refundable = option.refundable == true;
  final tint = refundable ? AppColors.successDark : AppColors.error;

  return AppBottomSheet.show<void>(
    context,
    title: 'Cancellation policy',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(option.name, style: AppText.cardTitle),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.10),
            borderRadius: AppRadii.rSm,
          ),
          child: Text(
            refundable ? 'Refundable' : 'Non-refundable',
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(color: tint),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Text('Now', style: AppText.caption),
            const Spacer(),
            Text(
              checkIn == null
                  ? 'Check-in'
                  : 'Check-in · ${formatTripDate(checkIn)}',
              style: AppText.caption,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (option.penalties.isNotEmpty) ...[
          Text(
            'Cancellation post that will be subject to a fee as follows',
            style: AppText.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        HotelPenaltyTable(
          penalties: option.penalties,
          currency: option.pricing.currency,
          showTime: true,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Fare breakup
// ---------------------------------------------------------------------------

/// The web's `RoomFareInfoModal`: room id and type, then only the fare
/// components the partner API actually returned.
Future<void> showHotelFareInfoSheet(
  BuildContext context, {
  required HotelRoomOption option,
}) {
  final p = option.pricing;
  String money(double v) => formatHotelFare(v, currency: p.currency);
  final rows = <(String, double)>[
    ('Base price', p.base),
    if (p.discount > 0) ('Discount', p.discount),
    if (p.taxes > 0) ('Taxes', p.taxes),
    if (p.managementFee > 0) ('Management fee', p.managementFee),
    if (p.managementFeeTax > 0) ('Management fee tax', p.managementFeeTax),
    if (p.gstClaimable > 0) ('GST claimable', p.gstClaimable),
    if (p.commission > 0) ('Commission', p.commission),
  ];

  return AppBottomSheet.show<void>(
    context,
    title: 'Fare breakup',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _FareRow(
          label: 'Room id',
          value: option.roomId.isEmpty ? '—' : option.roomId,
        ),
        _FareRow(label: 'Room type', value: option.name),
        const Divider(height: AppSpacing.xl, color: AppColors.divider),
        if ((p.strikethrough ?? 0) > 0)
          _FareRow(
            label: 'Gross price',
            value: money(p.strikethrough!),
            strike: true,
          ),
        for (final (label, value) in rows)
          _FareRow(label: label, value: money(value)),
        const Divider(height: AppSpacing.xl, color: AppColors.divider),
        _FareRow(
          label: 'Total price',
          value: money(p.total > 0 ? p.total : option.price),
          emphasise: true,
        ),
        if (p.commissionType.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Rate plan: ${p.commissionType}', style: AppText.caption),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    ),
  );
}

class _FareRow extends StatelessWidget {
  const _FareRow({
    required this.label,
    required this.value,
    this.emphasise = false,
    this.strike = false,
  });

  final String label;
  final String value;
  final bool emphasise;
  final bool strike;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasise ? AppText.bodyStrong : AppText.bodySm,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: (emphasise ? AppText.price : AppText.bodyStrong).copyWith(
                decoration: strike ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Policy notes
// ---------------------------------------------------------------------------

/// "Label: text" lines — policies from `option.inclusions` or the static
/// `policies` block.
class HotelPolicyNotes extends StatelessWidget {
  const HotelPolicyNotes({super.key, required this.notes});

  final List<HotelPolicyNote> notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text.rich(
              TextSpan(
                children: [
                  if (note.label.isNotEmpty)
                    TextSpan(
                      text: '${_sentenceCase(note.label)}: ',
                      style: AppText.bodyStrong,
                    ),
                  TextSpan(text: note.text, style: AppText.bodySm),
                ],
              ),
            ),
          ),
      ],
    );
  }

  static String _sentenceCase(String value) => value
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

// ---------------------------------------------------------------------------
// Editable search
// ---------------------------------------------------------------------------

/// The search already run, as one tappable line — the mobile form of the
/// web's compact, prefilled `HotelSearchForm` on the results and detail
/// pages. Tapping it opens the full form ([showHotelSearchSheet]).
class HotelSearchSummaryBar extends StatelessWidget {
  const HotelSearchSummaryBar({
    super.key,
    required this.query,
    required this.onEdit,
  });

  final HotelSearchQuery query;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final rooms = query.rooms.length;
    final guests = query.guests;
    return Pressable(
      onTap: onEdit,
      borderRadius: AppRadii.rMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    query.destination.title,
                    style: AppText.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${formatTripDate(query.checkIn)} – '
                    '${formatTripDate(query.checkOut)} · '
                    '$rooms room${rooms == 1 ? '' : 's'} · '
                    '$guests guest${guests == 1 ? '' : 's'}',
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Edit',
              style: AppText.label.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the full hotel search form, prefilled with [initial], in a sheet.
/// A successful search closes the sheet and is handed to [onSearch] — the
/// web's `HotelSearchForm onSearch` on its results and detail pages.
Future<void> showHotelSearchSheet(
  BuildContext context, {
  required HoneymoonApi api,
  required HotelSearchQuery initial,
  required void Function(HotelSearchQuery query, HotelSearchResult result)
  onSearch,
}) {
  return AppBottomSheet.show<void>(
    context,
    title: 'Modify search',
    child: Builder(
      builder: (sheetContext) => HotelSearchForm(
        api: api,
        initialQuery: initial,
        submitLabel: 'Search',
        onSearch: (query, result) {
          Navigator.pop(sheetContext);
          onSearch(query, result);
        },
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Map
// ---------------------------------------------------------------------------

/// The embedded Google Maps view the web's detail model builds
/// (`mapInfo.mapSrc` — `maps.google.com/maps?q=…&output=embed`), shown as a
/// preview. It ignores touches so it never fights the page scroll; tapping
/// opens the full map, the web's "Show on map" link.
class HotelMapPreview extends StatefulWidget {
  const HotelMapPreview({
    super.key,
    required this.target,
    required this.onOpen,
    this.height = 180,
  });

  /// `lat,long` when known, otherwise the address or the hotel's name.
  final String target;
  final VoidCallback onOpen;
  final double height;

  @override
  State<HotelMapPreview> createState() => _HotelMapPreviewState();
}

class _HotelMapPreviewState extends State<HotelMapPreview> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(AppColors.background)
    ..setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onWebResourceError: (_) {
          if (mounted) setState(() => _failed = true);
        },
      ),
    )
    ..loadRequest(
      Uri.parse(
        'https://maps.google.com/maps?q=${Uri.encodeComponent(widget.target)}'
        '&t=&z=13&ie=UTF8&iwloc=&output=embed',
      ),
    );

  bool _loaded = false;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.rMd,
      child: SizedBox(
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!_failed)
              IgnorePointer(child: WebViewWidget(controller: _controller)),
            if (!_loaded || _failed)
              Container(
                color: AppColors.blush,
                alignment: Alignment.center,
                child: _failed
                    ? const Icon(
                        Icons.map_outlined,
                        size: 36,
                        color: AppColors.primary,
                      )
                    : const AppLoader(size: 22, padding: EdgeInsets.zero),
              ),
            // The whole preview is the "Show on map" link.
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: widget.onOpen),
              ),
            ),
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.rPill,
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Show on map',
                        style: AppText.labelSm.copyWith(
                          color: AppColors.primary,
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
    );
  }
}
