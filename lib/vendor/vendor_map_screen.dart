/// Full-screen map of listing results — a port of the website's
/// `src/components/layouts/Main/MapView.jsx` (react-leaflet + OSM tiles).
///
/// The map is a Leaflet page (unpkg, same 1.9.4 build the web references)
/// rendered in a WebView. Pins come from each item's own lat/lng, else from a
/// Nominatim lookup of its location done here in Dart — cached in memory,
/// sequential and throttled to one request per second per Nominatim's usage
/// policy (the web fires them all in parallel). "View Details" in a popup
/// posts back over a JavaScript channel and calls [VendorMapScreen.onOpen].
///
/// App-side differences: markers appear progressively as geocoding
/// resolves instead of all at once; the rating badge is hidden when the
/// rating is 0 (the web shows "0.00★" because `"0.00"` is truthy in JS).
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../core/core.dart';
import 'vendor_listing_utils.dart';

/// Web default centre (India) and zoom (`MapView.jsx:15-16`).
const double kMapDefaultLat = 22.3511148;
const double kMapDefaultLng = 78.6677428;
const int kMapDefaultZoom = 5;

// ---------------------------------------------------------------------------
// Candidate selection (MapView.jsx:78-131)
// ---------------------------------------------------------------------------

bool _isValidCity(String? city) {
  if (city == null) return false;
  final lower = city.toLowerCase().trim();
  if (lower.isEmpty ||
      lower == 'unknown' ||
      lower == 'unknown city' ||
      lower == 'null' ||
      lower == 'undefined' ||
      lower == 'n/a' ||
      lower == 'none' ||
      lower == 'all' ||
      lower.contains('location not available') ||
      lower.contains('not available') ||
      lower.contains('unknown')) {
    return false;
  }
  return true;
}

bool _hasRealImage(String image) {
  final s = image.toLowerCase().trim();
  return s.isNotEmpty &&
      s != 'null' &&
      s != 'undefined' &&
      !s.contains('placeholder') &&
      !s.contains('not_found') &&
      !s.contains('image_not_found') &&
      !s.contains('imagenotfound') &&
      !s.contains('no-image') &&
      !s.contains('no_image');
}

bool _matchesCity(VendorCardFields f, String selected) {
  if (selected.isEmpty || selected.toLowerCase() == 'all') return true;
  final loc = [f.city, f.address, f.area].firstWhere((s) => s.isNotEmpty, orElse: () => '').toLowerCase();
  final a = selected.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final b = loc.replaceAll(RegExp(r'[^a-z0-9]'), '');
  return b.contains(a) || a.contains(b);
}

/// An item the map can try to place.
class MapCandidate {
  MapCandidate({required this.item, required this.fields, required this.query});
  final Map<String, dynamic> item;
  final VendorCardFields fields;

  /// Geocoding query (the web's `v.location || v.address || v.city || v.name`).
  final String query;
}

/// Items worth mapping: a real image and a valid city, optionally matching
/// [currentCity] (`MapView.jsx:109-131`).
List<MapCandidate> mapCandidates(List<Map<String, dynamic>> items, {String? currentCity}) {
  final out = <MapCandidate>[];
  for (final item in items) {
    final f = VendorCardFields.of(item);
    if (!_hasRealImage(f.image)) continue;
    final cityVal = [f.city, f.address].firstWhere((s) => s.isNotEmpty, orElse: () => '');
    if (!_isValidCity(cityVal)) continue;
    if (currentCity != null && currentCity.isNotEmpty && currentCity.toLowerCase() != 'all') {
      if (!_matchesCity(f, currentCity)) continue;
    }
    final query = [f.city, f.address, f.name].firstWhere((s) => s.isNotEmpty, orElse: () => '');
    out.add(MapCandidate(item: item, fields: f, query: query));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Geocoding
// ---------------------------------------------------------------------------

/// Nominatim geocoder with an in-memory cache shared by every map screen and
/// a global one-request-per-second throttle.
class NominatimGeocoder {
  NominatimGeocoder({http.Client? client}) : _client = client;
  final http.Client? _client;

  static final Map<String, ({double lat, double lng})?> _cache = {};
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  static Future<void> _queue = Future.value();

  /// Nominatim requires an identifying User-Agent. The web sends a
  /// placeholder contact on an `.example` domain; the app identifies itself
  /// with the real site instead.
  static const String userAgent = 'HappyWedz/1.0 (https://happywedz.com)';

  Future<({double lat, double lng})?> geocode(String query) {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return Future.value(null);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);

    final completer = Completer<({double lat, double lng})?>();
    _queue = _queue.then((_) async {
      if (_cache.containsKey(key)) {
        completer.complete(_cache[key]);
        return;
      }
      final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_last);
      if (!wait.isNegative) await Future<void>.delayed(wait);
      _last = DateTime.now();
      final client = _client ?? http.Client();
      try {
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(key)}',
        );
        final res = await client
            .get(uri, headers: {'User-Agent': userAgent, 'Accept': 'application/json'})
            .timeout(const Duration(seconds: 15));
        ({double lat, double lng})? result;
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data is List && data.isNotEmpty && data.first is Map) {
            final lat = double.tryParse('${data.first['lat']}');
            final lng = double.tryParse('${data.first['lon']}');
            if (lat != null && lng != null) result = (lat: lat, lng: lng);
          }
          _cache[key] = result; // only cache real answers, not transient failures
        }
        completer.complete(result);
      } catch (_) {
        completer.complete(null);
      } finally {
        if (_client == null) client.close();
      }
    });
    return completer.future;
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class VendorMapScreen extends StatefulWidget {
  const VendorMapScreen({
    super.key,
    required this.items,
    required this.priceLabel,
    required this.onOpen,
    this.currentCity,
    this.geocoder,
  });

  /// Raw vendor-service maps from `/vendor-services`.
  final List<Map<String, dynamic>> items;

  /// Price badge text for an item; return null/empty to hide the badge.
  final String? Function(Map<String, dynamic> item) priceLabel;

  /// Called with the raw item when "View Details" is tapped.
  final void Function(Map<String, dynamic> item) onOpen;

  /// Selected city; items elsewhere are skipped like the web. Null/"all" = any.
  final String? currentCity;

  final NominatimGeocoder? geocoder;

  @override
  State<VendorMapScreen> createState() => _VendorMapScreenState();
}

class _VendorMapScreenState extends State<VendorMapScreen> {
  late final WebViewController _web;
  final Completer<void> _pageReady = Completer<void>();
  final List<Map<String, dynamic>> _placed = [];
  bool _loading = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel('HWMap', onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (!_pageReady.isCompleted) _pageReady.complete();
        },
      ))
      ..loadHtmlString(_html, baseUrl: 'https://happywedz.com/');
    _run();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _onMessage(JavaScriptMessage m) {
    final index = int.tryParse(m.message);
    if (index == null || index < 0 || index >= _placed.length) return;
    widget.onOpen(_placed[index]);
  }

  Map<String, dynamic> _pin(MapCandidate c, double lat, double lng, int index) {
    final rating = double.tryParse('${c.fields.rating}') ?? 0;
    return {
      'i': index,
      'lat': lat,
      'lng': lng,
      'name': c.fields.name,
      'image': c.fields.image,
      'address': [c.fields.address, c.fields.city].firstWhere((s) => s.isNotEmpty, orElse: () => ''),
      'rating': rating > 0 ? '${c.fields.rating}' : '',
      'price': widget.priceLabel(c.item) ?? '',
    };
  }

  Future<void> _addPins(List<Map<String, dynamic>> pins) async {
    if (pins.isEmpty || _disposed) return;
    await _pageReady.future;
    if (_disposed) return;
    try {
      await _web.runJavaScript('window.hwAddPins(${jsonEncode(pins)});');
    } catch (e) {
      debugPrint('[Map] addPins failed: $e');
    }
  }

  Future<void> _run() async {
    final candidates = mapCandidates(widget.items, currentCity: widget.currentCity);
    final geocoder = widget.geocoder ?? NominatimGeocoder();

    // Items with their own coordinates go on first, in one batch.
    final direct = <Map<String, dynamic>>[];
    final pending = <MapCandidate>[];
    for (final c in candidates) {
      final lat = c.fields.lat;
      final lng = c.fields.lng;
      // Web: `if (v.lat && v.lng)` — 0 counts as missing.
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        direct.add(_pin(c, lat, lng, _placed.length));
        _placed.add(c.item);
      } else {
        pending.add(c);
      }
    }
    await _addPins(direct);

    for (final c in pending) {
      if (_disposed) return;
      final coords = await geocoder.geocode(c.query);
      if (_disposed) return;
      if (coords == null) continue;
      final pin = _pin(c, coords.lat, coords.lng, _placed.length);
      _placed.add(c.item);
      await _addPins([pin]);
    }
    if (!_disposed && mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _web)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: _loading ? const _Chip(text: 'Loading map…') : const SizedBox.shrink(),
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    elevation: 2,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                        child: Text('Close Map', style: AppText.label),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_loading && _placed.isEmpty)
            const Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: SafeArea(child: _Chip(text: 'No mappable venues for this selection.')),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: AppText.caption),
    );
  }
}

/// Leaflet page. `hwAddPins` adds markers and refits bounds with the web's
/// 32px padding; popup layout follows `MapView.jsx:193-234`.
const String _html = '''
<!DOCTYPE html>
<html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
<style>
  html, body, #map { height: 100%; width: 100%; margin: 0; padding: 0; }
  body { font-family: -apple-system, Roboto, "Segoe UI", sans-serif; }
  .hw-pop { display: flex; gap: 12px; min-width: 220px; font-size: 13px; }
  .hw-pop img { width: 80px; height: 80px; object-fit: cover; border-radius: 8px; flex-shrink: 0; background: #fafafa; }
  .hw-name { font-weight: 600; margin-bottom: 4px; }
  .hw-addr { color: #6c757d; margin-bottom: 4px; line-height: 1.2; }
  .hw-badges { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 8px; }
  .hw-rating { background: #198754; color: #fff; border-radius: 4px; padding: 1px 6px; font-weight: 600; font-size: 11px; }
  .hw-price { background: #f8f9fa; color: #6c757d; border: 1px solid #dee2e6; border-radius: 4px; padding: 1px 6px; font-size: 11px; }
  .hw-btn { background: #E91E63; color: #fff; border: 0; border-radius: 999px; padding: 5px 14px; font-size: 12px; }
</style>
</head><body>
<div id="map"></div>
<script>
  var map = L.map('map', { zoomControl: true }).setView([$kMapDefaultLat, $kMapDefaultLng], $kMapDefaultZoom);
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);
  var all = [];
  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }
  function hwOpen(i) { if (window.HWMap) HWMap.postMessage(String(i)); }
  window.hwAddPins = function (pins) {
    pins.forEach(function (p) {
      var html = '<div class="hw-pop">' +
        '<img src="' + esc(p.image) + '" alt="' + esc(p.name) + '" onerror="this.style.objectFit=\\'contain\\';this.removeAttribute(\\'src\\');">' +
        '<div><div class="hw-name">' + esc(p.name) + '</div>' +
        (p.address ? '<div class="hw-addr">' + esc(p.address) + '</div>' : '') +
        '<div class="hw-badges">' +
        (p.rating ? '<span class="hw-rating">' + esc(p.rating) + '&#9733;</span>' : '') +
        (p.price ? '<span class="hw-price">' + esc(p.price) + '</span>' : '') +
        '</div>' +
        '<button class="hw-btn" onclick="hwOpen(' + Number(p.i) + ')">View Details</button>' +
        '</div></div>';
      L.marker([p.lat, p.lng]).addTo(map).bindPopup(html, { maxWidth: 320 });
      all.push([p.lat, p.lng]);
    });
    if (all.length > 0) {
      var b = L.latLngBounds(all);
      if (b.isValid()) map.fitBounds(b, { padding: [32, 32], maxZoom: 15 }); // maxZoom: app-only, keeps a single pin from zooming to street level
    }
  };
</script>
</body></html>
''';
