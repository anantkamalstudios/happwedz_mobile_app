import '../core/config/api_config.dart';

// Field resolution for a raw `/vendor-services` row, following the website's
// `transformApiData` (src/hooks/useInfiniteScroll.js:62-227) so a card shows
// the same name, image and city on both platforms.

Map _mapOf(Object? v) => v is Map ? v : const {};

bool _usable(Object? v) {
  final s = (v ?? '').toString().trim();
  return s.isNotEmpty && s.toLowerCase() != 'null' && s.toLowerCase() != 'unknown';
}

/// `/uploads/...` and protocol-relative paths made absolute.
String vendorAbsoluteUrl(String url) {
  final u = url.trim();
  if (u.isEmpty) return '';
  if (u.startsWith('//')) return 'https:$u';
  if (u.startsWith('http')) return u;
  if (u.startsWith('/')) return '${ApiConfig.apiBase}$u';
  return '${ApiConfig.apiBase}/$u';
}

/// `attributes.vendor_name` → `Name` → `name` → `vendor.businessName`.
String vendorCardName(Map row) {
  final a = _mapOf(row['attributes']);
  final v = _mapOf(row['vendor']);
  for (final c in [a['vendor_name'], a['Name'], a['name'], v['businessName']]) {
    if (_usable(c)) return c.toString().trim();
  }
  return 'Unknown Vendor';
}

/// Every gallery image: `media[]` (strings or `{url}`), else
/// `attributes.Portfolio` split on `|`.
List<String> vendorCardGallery(Map row) {
  final out = <String>[];
  final media = row['media'];
  if (media is List) {
    for (final m in media) {
      final u = m is Map ? (m['url'] ?? m['original_url']) : m;
      if (_usable(u)) out.add(vendorAbsoluteUrl(u.toString()));
    }
  } else if (media is Map && _usable(media['coverImage'])) {
    out.add(vendorAbsoluteUrl(media['coverImage'].toString()));
  }
  if (out.isEmpty) {
    final a = _mapOf(row['attributes']);
    final p = a['Portfolio'] ?? a['portfolio_urls'] ?? a['portfolio'];
    if (p is String) {
      for (final part in p.split('|')) {
        if (_usable(part)) out.add(vendorAbsoluteUrl(part));
      }
    }
  }
  return out;
}

String vendorCardImage(Map row) {
  final g = vendorCardGallery(row);
  return g.isEmpty ? '' : g.first;
}

/// `attributes.city` → `vendor.city`; "unknown" dropped, like the website.
String vendorCardCity(Map row) {
  final a = _mapOf(row['attributes']);
  final v = _mapOf(row['vendor']);
  for (final c in [a['city'], v['city']]) {
    if (_usable(c)) return c.toString().trim();
  }
  return '';
}

/// `attributes.rating` (the website's card value), then `averageRating`.
double vendorCardRating(Map row) {
  final a = _mapOf(row['attributes']);
  for (final c in [a['rating'], a['averageRating']]) {
    final d = double.tryParse((c ?? '').toString().replaceAll(',', ''));
    if (d != null && d > 0) return d;
  }
  return 0;
}

int vendorCardReviewCount(Map row) {
  final a = _mapOf(row['attributes']);
  return int.tryParse('${a['review_count'] ?? a['review'] ?? a['totalReviews'] ?? 0}') ?? 0;
}

/// Vendor type name ("Venues", "Photographers" …).
String vendorCardType(Map row) {
  final a = _mapOf(row['attributes']);
  final v = _mapOf(row['vendor']);
  final t = a['vendor_type'] ?? _mapOf(v['vendorType'])['name'];
  return _usable(t) ? t.toString() : '';
}

/// The vendor account id (`vendor_id`), which request-pricing and chat use.
String vendorAccountId(Map row) =>
    (row['vendor_id'] ?? _mapOf(row['vendor'])['id'] ?? '').toString();

/// Phone for Call / WhatsApp: `vendor.phone`, then `attributes.Phone`.
String vendorCardPhone(Map row) {
  final a = _mapOf(row['attributes']);
  final v = _mapOf(row['vendor']);
  for (final c in [v['phone'], a['Phone'], a['phone']]) {
    final digits = (c ?? '').toString().replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length >= 10 && digits != '0000000000') return digits;
  }
  return '';
}
