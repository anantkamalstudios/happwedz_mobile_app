/// Cab comparison table and the "Cab policies" sheet.
///
/// Both are ports of the website's `CabCompareTable` and `CabPolicyModal`.
/// The compare table is what makes a vehicle class with two vendors readable:
/// the class shows one card, and the sibling quotes line up here over a fixed
/// set of rows. The policy sheet covers the four tabs the portal offers over a
/// quote's `policies` block.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../models/honeymoon_models.dart';
import 'honeymoon_widgets.dart';

const String _supportPhone = '+91 77700 05377';
const String _supportEmail = 'support@happywedz.com';

// ---------------------------------------------------------------------------
// Policy readers
// ---------------------------------------------------------------------------

List<String> _stringList(dynamic value) => asList(
  value,
).map((e) => asString(e).trim()).where((e) => e.isNotEmpty).toList();

List<dynamic> _cancellationRules(CabQuote quote) =>
    asList(readKey(quote.policies, 'cancellationPolicy'));

/// "Upto 4 hours before departure", from the first fully-refundable rule.
String freeCancellationLabel(CabQuote quote) {
  for (final rule in _cancellationRules(quote)) {
    if (asDouble(readKey(rule, 'refundPercentage')) != 100) continue;
    final description = asString(readKey(rule, 'description'));
    if (description.isNotEmpty) return description;
    final hours = readKey(rule, 'minHours');
    if (hours != null) return 'Upto ${asInt(hours)} hours before departure';
    return 'As per policy';
  }
  return 'As per policy';
}

/// "Within 24 hours before departure" from a `{ minHours }` rule.
String _windowLabel(dynamic rule) {
  final description = asString(readKey(rule, 'description'));
  if (description.isNotEmpty) return description;
  final hours = readKey(rule, 'minHours');
  if (hours == null) return 'As per policy';
  final h = asInt(hours);
  return h == 0
      ? 'Within 24 hours before departure'
      : 'Upto $h hours before departure';
}

/// Meet and greet is listed among the inclusions rather than as its own flag.
bool _hasMeetAndGreet(CabQuote quote) =>
    _stringList(readKey(quote.policies, 'inclusions')).any(
      (i) =>
          RegExp(r'meet\s*(and|&)\s*greet', caseSensitive: false).hasMatch(i),
    );

// ---------------------------------------------------------------------------
// Compare table
// ---------------------------------------------------------------------------

typedef _RowValue = String Function(CabQuote quote);

class _CompareRow {
  const _CompareRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;

  /// Null for the meet-and-greet row, which renders a yes/no marker instead.
  final _RowValue? value;
}

final List<_CompareRow> _compareRows = [
  // The web's row labels and values (`CabCompareTable.jsx`): capacity is the
  // group's, else the quote's; the type is the model, else the similar type.
  _CompareRow(
    Icons.people_alt_rounded,
    'Passenger capacity',
    (q) => '${q.seats > 0 ? q.seats : '-'} pax',
  ),
  _CompareRow(
    Icons.luggage_rounded,
    'Luggage capacity',
    (q) => '${q.luggage > 0 ? q.luggage : '-'} bags',
  ),
  _CompareRow(
    Icons.directions_car_rounded,
    'Vehicle type',
    (q) => q.model.isNotEmpty
        ? q.model
        : (q.similarType.isNotEmpty ? q.similarType : '-'),
  ),
  _CompareRow(
    Icons.event_available_rounded,
    'Free cancellation',
    freeCancellationLabel,
  ),
  _CompareRow(Icons.schedule_rounded, 'Waiting time', (q) {
    final v = asString(readKey(q.policies, 'waitingTime'));
    return v.isEmpty ? '-' : v;
  }),
  const _CompareRow(Icons.sell_rounded, 'Meet and greet', null),
];

// Previous rows, kept for reference:
//   _CompareRow(
//     Icons.people_alt_rounded,
//     'Passengers',
//     (q) => '${q.seats > 0 ? q.seats : q.paxCount} pax',
//   ),
//   _CompareRow(
//     Icons.luggage_rounded,
//     'Luggage',
//     (q) => '${q.luggage > 0 ? q.luggage : q.luggageCount} bags',
//   ),
//   _CompareRow(
//     Icons.directions_car_rounded,
//     'Vehicle',
//     (q) => q.model.isNotEmpty
//         ? q.model
//         : (q.vehicleName.isEmpty ? '-' : q.vehicleName),
//   ),

/// The quotes that share a vehicle class, side by side over a fixed set of
/// rows. Scrolls horizontally: on a phone there is no room for three columns
/// of prose at a readable size.
class CabCompareTable extends StatelessWidget {
  const CabCompareTable({
    super.key,
    required this.quotes,
    required this.onSelect,
    required this.onPolicies,
  });

  final List<CabQuote> quotes;
  final ValueChanged<CabQuote> onSelect;
  final ValueChanged<CabQuote> onPolicies;

  static const double _labelWidth = 128;
  static const double _columnWidth = 168;

  @override
  Widget build(BuildContext context) {
    if (quotes.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The label rail stays put while the quote columns scroll, so a row
          // never loses the label that explains it.
          SizedBox(
            width: _labelWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: _headerHeight),
                for (final row in _compareRows)
                  Container(
                    height: _rowHeight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(row.icon, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            row.label,
                            style: AppText.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: _actionHeight),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.divider),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final quote in quotes)
                    SizedBox(width: _columnWidth, child: _column(quote)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _headerHeight = 56;
  static const double _rowHeight = 44;
  static const double _actionHeight = 52;

  Widget _column(CabQuote quote) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _headerHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // One line each, so the fixed-height header never overflows.
                Text(
                  formatPrice(quote.price),
                  style: AppText.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // PremiumButton.text(
                //   label: 'View policies',
                //   size: PremiumButtonSize.small,
                //   onPressed: () => onPolicies(quote),
                // ),
                // A compact link: the button's padding pushed the fixed-height
                // header over its bottom edge at large text.
                InkWell(
                  onTap: () => onPolicies(quote),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'View policies',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final row in _compareRows)
          Container(
            height: _rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            alignment: Alignment.centerLeft,
            child: row.value == null
                ? (_hasMeetAndGreet(quote)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text('Included', style: AppText.caption),
                          ],
                        )
                      : Text('Not included', style: AppText.caption))
                : Text(
                    row.value!(quote),
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        SizedBox(
          height: _actionHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: PremiumButton(
              label: 'Book cab',
              size: PremiumButtonSize.small,
              onPressed: () => onSelect(quote),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Policy sheet
// ---------------------------------------------------------------------------

/// The "Cab policies" sheet: four tabs over the quote's `policies` block.
Future<void> showCabPolicySheet(BuildContext context, CabQuote quote) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
    builder: (_) => _CabPolicySheet(quote: quote),
  );
}

class _CabPolicySheet extends StatefulWidget {
  const _CabPolicySheet({required this.quote});

  final CabQuote quote;

  @override
  State<_CabPolicySheet> createState() => _CabPolicySheetState();
}

class _CabPolicySheetState extends State<_CabPolicySheet> {
  int _tab = 0;

  static const List<String> _tabs = [
    'Inclusions',
    'Cancellation',
    'Amendment',
    'Baggage',
  ];

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Cab policies', style: AppText.sectionTitle),
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                itemCount: _tabs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) => Center(
                  child: Pressable(
                    onTap: () => setState(() => _tab = i),
                    borderRadius: AppRadii.rPill,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: _tab == i
                            ? AppColors.pinkSurface
                            : AppColors.surface,
                        borderRadius: AppRadii.rPill,
                        border: Border.all(
                          color: _tab == i
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        _tabs[i],
                        style: AppText.labelSm.copyWith(
                          color: _tab == i
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: switch (_tab) {
                  0 => _inclusions(),
                  1 => _cancellation(),
                  2 => _note(
                    asString(readKey(widget.quote.policies, 'amendmentPolicy')),
                    // The fallback names our own contact details, not the
                    // supplier's — amendments are handled by us.
                    'Please contact us at $_supportPhone or $_supportEmail for '
                    'any amendments or modifications to the booking. Extra '
                    'charges may apply.',
                  ),
                  _ => _note(
                    asString(readKey(widget.quote.policies, 'baggagePolicy')),
                    'Excess luggage requires guests to either arrange a '
                    'separate vehicle or upgrade the vehicle in advance.',
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inclusions() {
    final inclusions = _stringList(
      readKey(widget.quote.policies, 'inclusions'),
    );
    final exclusions = _stringList(
      readKey(widget.quote.policies, 'exclusions'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _list(
          title: 'Inclusions',
          icon: Icons.check_circle_rounded,
          tint: AppColors.success,
          items: inclusions,
          emptyText: 'No inclusions listed for this vehicle.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _list(
          title: 'Exclusions',
          icon: Icons.cancel_rounded,
          tint: AppColors.error,
          items: exclusions,
          emptyText: 'No exclusions listed for this vehicle.',
        ),
      ],
    );
  }

  Widget _list({
    required String title,
    required IconData icon,
    required Color tint,
    required List<String> items,
    required String emptyText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: AppSpacing.xs),
            Text(title, style: AppText.bodyStrong),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (items.isEmpty)
          Text(emptyText, style: AppText.caption)
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 6,
                      right: AppSpacing.sm,
                    ),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Expanded(child: Text(item, style: AppText.body)),
                ],
              ),
            ),
      ],
    );
  }

  Widget _cancellation() {
    final rules = _cancellationRules(widget.quote);
    if (rules.isEmpty) {
      return Text(
        'Cancellation terms are confirmed by the operator at booking.',
        style: AppText.body,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text('Cancellation time', style: AppText.overline),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Refund',
                style: AppText.overline,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const Divider(height: 1, color: AppColors.divider),
        for (final rule in rules) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(_windowLabel(rule), style: AppText.body),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${asInt(readKey(rule, 'refundPercentage'))}% refund',
                    style: AppText.bodyStrong,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }

  Widget _note(String supplied, String fallback) =>
      Text(supplied.isNotEmpty ? supplied : fallback, style: AppText.body);
}
