import 'package:flutter/material.dart';

import '../core/core.dart';

/// One status vocabulary for the six booking sources.
///
/// A direct port of the web's `utils/bookingStatus.js`. Quotations, flights,
/// cabs, hotels, insurance and shop orders each report status in their own
/// casing and their own words — `pending` / `SUCCESS` / `on_hold` /
/// `BOOK_FAILED_AFTER_PAYMENT`. Every row runs through [normalizeStatus]
/// first, so one filter row and one status pill drive all six panels.
///
/// Keep this in step with the web file: they read the same API responses, and
/// a state handled there but not here shows up as a raw provider string.
enum StatusTone { ok, warn, info, stop, muted }

extension StatusToneStyle on StatusTone {
  Color get color => switch (this) {
    StatusTone.ok => AppColors.successDark,
    StatusTone.warn => AppColors.warning,
    StatusTone.info => AppColors.info,
    StatusTone.stop => AppColors.error,
    StatusTone.muted => AppColors.textTertiary,
  };

  IconData get icon => switch (this) {
    StatusTone.ok => Icons.check_circle_rounded,
    StatusTone.warn => Icons.schedule_rounded,
    StatusTone.info => Icons.hourglass_bottom_rounded,
    StatusTone.stop => Icons.block_rounded,
    StatusTone.muted => Icons.help_outline_rounded,
  };
}

@immutable
class BookingStatus {
  const BookingStatus({
    required this.key,
    required this.label,
    required this.tone,
    required this.raw,
  });

  final String key;
  final String label;
  final StatusTone tone;
  final String raw;
}

/// Which source's vocabulary a raw status should be read against.
enum StatusSource { quotation, flight, cab, hotel, insurance, shop }

/// Display states. `tone` picks the pill colour.
const Map<String, ({String label, StatusTone tone})> _statusMeta = {
  'confirmed': (label: 'Confirmed', tone: StatusTone.ok),
  'booked': (label: 'Booked', tone: StatusTone.ok),
  'replied': (label: 'Replied', tone: StatusTone.ok),
  // Shop orders move Pending → Processing → Delivered. Delivered is its own
  // state rather than "Confirmed": a confirmed order and one already in your
  // hands are not the same news.
  'delivered': (label: 'Delivered', tone: StatusTone.ok),
  'pending': (label: 'Pending', tone: StatusTone.warn),
  'processing': (label: 'Processing', tone: StatusTone.info),
  'hold': (label: 'On Hold', tone: StatusTone.info),
  'cancelled': (label: 'Cancelled', tone: StatusTone.stop),
  'failed': (label: 'Failed', tone: StatusTone.stop),
  'unknown': (label: 'Unknown', tone: StatusTone.muted),
};

/// Raw provider value (upper-cased) → display state.
const Map<StatusSource, Map<String, String>> _maps = {
  StatusSource.quotation: {
    'PENDING': 'pending',
    'REPLIED': 'replied',
    'BOOKED': 'booked',
    'ACCEPTED': 'booked',
    'CANCELLED': 'cancelled',
    'CANCELED': 'cancelled',
    'REJECTED': 'cancelled',
  },
  StatusSource.flight: {
    'CONFIRMED': 'confirmed',
    'SUCCESS': 'confirmed',
    'TICKETED': 'confirmed',
    'ON_HOLD': 'hold',
    'HOLD': 'hold',
    'PENDING': 'pending',
    'IN_PROGRESS': 'pending',
    'CANCELLED': 'cancelled',
    'CANCELED': 'cancelled',
    'FAILED': 'failed',
    'ABORTED': 'failed',
  },
  StatusSource.cab: {
    'SUCCESS': 'confirmed',
    'CONFIRMED': 'confirmed',
    'PENDING': 'pending',
    'IN_PROGRESS': 'pending',
    'CANCELLED': 'cancelled',
    'CANCELED': 'cancelled',
    'FAILED': 'failed',
  },
  StatusSource.hotel: {
    'SUCCESS': 'confirmed',
    'CONFIRMED': 'confirmed',
    'ON_HOLD': 'hold',
    'PAYMENT_SUCCESS': 'pending',
    'PAYMENT_PENDING': 'pending',
    'IN_PROGRESS': 'pending',
    'PENDING': 'pending',
    'CANCELLED': 'cancelled',
    'CANCELED': 'cancelled',
    'FAILED': 'failed',
    'ABORTED': 'failed',
    'PAYMENT_FAILED': 'failed',
    'BOOK_FAILED_AFTER_PAYMENT': 'failed',
  },
  StatusSource.insurance: {
    'SUCCESS': 'confirmed',
    'CONFIRMED': 'confirmed',
    'ISSUED': 'confirmed',
    'PENDING': 'pending',
    'PAYMENT_PENDING': 'pending',
    'IN_PROGRESS': 'pending',
    'CANCELLED': 'cancelled',
    'CANCELED': 'cancelled',
    'FAILED': 'failed',
  },
  // The store's Order.status enum is exactly ["Pending", "Processing",
  // "Delivered", "Cancel"] — note "Cancel", not "Cancelled". The other two
  // spellings are here so a later widening of that enum still lands somewhere
  // sensible rather than falling through to "unknown".
  StatusSource.shop: {
    'PENDING': 'pending',
    'PROCESSING': 'processing',
    'DELIVERED': 'delivered',
    'CANCEL': 'cancelled',
    'CANCELLED': 'cancelled',
    'CANCELED': 'cancelled',
  },
};

/// Where the generic display label loses information the user needs.
const Map<StatusSource, Map<String, String>> _labelOverrides = {
  StatusSource.hotel: {
    'PAYMENT_SUCCESS': 'Awaiting Voucher',
    'BOOK_FAILED_AFTER_PAYMENT': 'Failed After Payment',
    'PAYMENT_FAILED': 'Payment Failed',
  },
  StatusSource.insurance: {
    'SUCCESS': 'Policy Issued',
    'ISSUED': 'Policy Issued',
  },
  StatusSource.flight: {'ON_HOLD': 'Seat Held'},
};

String _titleCase(String value) => value
    .toLowerCase()
    .split(RegExp(r'[\s_-]+'))
    .where((w) => w.isNotEmpty)
    .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Normalises one provider status into the shared vocabulary.
///
/// An empty status reads as `pending` (the row exists but the provider has
/// said nothing yet); an unrecognised one keeps its own text, title-cased,
/// rather than being flattened to "Unknown".
BookingStatus normalizeStatus(Object? raw, StatusSource source) {
  final value = (raw?.toString() ?? '').trim().toUpperCase();
  final key = _maps[source]?[value] ?? (value.isEmpty ? 'pending' : 'unknown');
  final meta = _statusMeta[key] ?? _statusMeta['unknown']!;
  final label =
      _labelOverrides[source]?[value] ??
      (key == 'unknown' && value.isNotEmpty ? _titleCase(value) : meta.label);

  return BookingStatus(key: key, label: label, tone: meta.tone, raw: value);
}

@immutable
class StatusFilter {
  const StatusFilter({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;
}

/// Which pills a panel shows even at zero, so the row does not jump around as
/// data loads.
enum FilterSet { quotation, travel, shop }

const Map<FilterSet, List<String>> _canonicalFilters = {
  FilterSet.quotation: ['pending', 'replied', 'booked', 'cancelled'],
  FilterSet.travel: ['confirmed', 'pending', 'hold', 'cancelled'],
  FilterSet.shop: ['pending', 'processing', 'delivered', 'cancelled'],
};

/// Builds the status filter row for a panel: the canonical pills for that set
/// plus any extra state the data actually contains (a failed hotel booking,
/// say), each with its count.
List<StatusFilter> buildStatusFilters<T>(
  FilterSet set,
  List<T> items,
  String Function(T) getKey,
) {
  final counts = <String, int>{};
  for (final item in items) {
    final key = getKey(item);
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final canonical = _canonicalFilters[set] ?? _canonicalFilters[FilterSet.travel]!;
  final extra = counts.keys.where((k) => !canonical.contains(k));

  return [
    StatusFilter(key: 'all', label: 'All', count: items.length),
    for (final key in [...canonical, ...extra])
      StatusFilter(
        key: key,
        label: _statusMeta[key]?.label ?? _titleCase(key),
        count: counts[key] ?? 0,
      ),
  ];
}
