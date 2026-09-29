/// 360° view for a vendor service — a port of the website's
/// `src/utils/view360Helper.js` (asset detection) and
/// `src/components/pages/Vendor360View.jsx` (the viewer page, which renders
/// `components/ui/Image360Modal.jsx` for panoramas).
///
/// Two deliberate improvements over the web, both documented where they live:
///  - `media.view360.embedCode` is honoured: its iframe `src` (or the code
///    itself when it is a bare URL) becomes the tour URL when no pasted
///    `view360_url` exists. The web's `hasView360` shows the 360° button for
///    an embed code, but `get360Assets` ignores it, so the web page then says
///    "No 360° content available" for exactly those vendors.
///  - a failed fetch shows an error with retry instead of the web's
///    "No 360° content" message, which would misreport a network error as the
///    vendor having nothing.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/config/api_config.dart';
import '../core/core.dart';

// ---------------------------------------------------------------------------
// Helper (view360Helper.js)
// ---------------------------------------------------------------------------

final RegExp _edgeBackticks = RegExp(r'^\s*`|`\s*$');

String _cleanStr(String s) => s.replaceAll(_edgeBackticks, '').trim();

/// `isUsableUrl` (`view360Helper.js:15-23`).
bool _isUsable(Object? value) {
  if (value is! String || value.isEmpty) return false;
  final cleaned = _cleanStr(value);
  final lower = cleaned.toLowerCase();
  return cleaned.isNotEmpty && lower != 'null' && lower != 'undefined';
}

/// `getSafe360Url` (`view360Helper.js:32-42`): the value only when it is a
/// plain absolute http(s) URL, otherwise null (never `javascript:`/`data:`).
String? getSafe360Url(Object? value) {
  if (!_isUsable(value)) return null;
  final uri = Uri.tryParse(_cleanStr(value as String));
  if (uri == null || !uri.hasAuthority) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri.toString();
}

/// `normalizeEntry` (`view360Helper.js:44-49`).
String? _normalizeEntry(Object? entry) {
  if (entry == null) return null;
  Object? raw;
  if (entry is String) {
    raw = entry;
  } else if (entry is Map) {
    raw = _truthy(entry['url']) ?? _truthy(entry['path']) ?? _truthy(entry['location']);
  }
  if (!_isUsable(raw)) return null;
  return _cleanStr(raw as String);
}

Object? _truthy(Object? v) {
  if (v == null || v == false || v == '' || v == 0) return null;
  return v;
}

/// `toList` (`view360Helper.js:51-55`).
List<String> _toList(Object? value) {
  if (value == null || value == '' || value == false) return const [];
  final items = value is List ? value : [value];
  return items.map(_normalizeEntry).whereType<String>().toList();
}

Map _asMap(Object? v) => v is Map ? v : const {};

/// The sub-vendor media object (`item.media` when it is a map, not the
/// gallery array) — `view360Helper.js:66`.
Map _mediaObject(Map item) {
  final media = item['media'];
  return media is Map ? media : const {};
}

/// Extracts an http(s) URL from `media.view360.embedCode`: the `src` of an
/// `<iframe>` snippet, or the code itself when it is a bare URL. App-side
/// addition — the web never reads embedCode on the viewer page.
String? embedCodeSrc(Object? embedCode) {
  if (!_isUsable(embedCode)) return null;
  final code = _cleanStr(embedCode as String);
  final direct = getSafe360Url(code);
  if (direct != null) return direct;
  final m = RegExp(
    r'''<iframe\b[^>]*\bsrc\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))''',
    caseSensitive: false,
  ).firstMatch(code);
  if (m == null) return null;
  final src = (m.group(1) ?? m.group(2) ?? m.group(3) ?? '').replaceAll('&amp;', '&');
  return getSafe360Url(src);
}

/// Every 360° asset a vendor service carries (`get360Assets`,
/// `view360Helper.js:62-92`).
@immutable
class View360Assets {
  const View360Assets({this.images = const [], this.videos = const [], this.url});

  final List<String> images;
  final List<String> videos;

  /// Tour link: `attributes.view360_url ?? item.view360_url`, falling back to
  /// the embed-code iframe src (app fix, see [embedCodeSrc]).
  final String? url;

  bool get isEmpty => images.isEmpty && videos.isEmpty && url == null;
}

View360Assets get360Assets(Object? item) {
  if (item is! Map) return const View360Assets();
  final attributes = _asMap(item['attributes']);
  final view360 = _asMap(_mediaObject(item)['view360']);

  List<String> dedupe(List<String> l) => l.toSet().toList();

  final images = dedupe([
    ..._toList(item['view360_image']),
    ..._toList(item['view360_images']),
    ..._toList(item['view360Images']),
    ..._toList(attributes['view360_image']),
    ..._toList(attributes['view360_images']),
    ..._toList(view360['panoImage']),
    ..._toList(view360['modelUrl']),
  ]);
  final videos = dedupe([
    ..._toList(item['view360_video']),
    ..._toList(item['view360_videos']),
    ..._toList(item['view360Videos']),
    ..._toList(attributes['view360_video']),
    ..._toList(attributes['view360_videos']),
  ]);

  // JS `attributes.view360_url ?? item.view360_url` — `??` only skips null.
  final pasted = attributes['view360_url'] ?? item['view360_url'];
  final url = getSafe360Url(pasted) ?? embedCodeSrc(view360['embedCode']);

  return View360Assets(images: images, videos: videos, url: url);
}

/// True only when the vendor uploaded 360° content (`hasView360`,
/// `view360Helper.js:99-110`). A precomputed boolean `has360` wins.
bool hasView360(Object? item) {
  if (item is! Map) return false;
  final pre = item['has360'];
  if (pre is bool) return pre;
  if (_isUsable(_asMap(_mediaObject(item)['view360'])['embedCode'])) return true;
  return !get360Assets(item).isEmpty;
}

/// Title the web page uses (`Vendor360View.jsx:39-44`).
String view360Title(Map? service) {
  final attrs = _asMap(service?['attributes']);
  final vendor = _asMap(service?['vendor']);
  final name = _truthy(attrs['name']) ?? _truthy(vendor['vendor_name']) ?? _truthy(attrs['vendor_name']) ?? 'Vendor';
  return '$name • 360°';
}

/// Relative upload paths are served off the API host (web `resolveMediaUrl`).
String _absolute(String url) {
  if (RegExp(r'^https?://', caseSensitive: false).hasMatch(url)) return url;
  final path = url.startsWith('/') ? url : '/uploads/$url';
  return '${ApiConfig.apiBase}$path';
}

// ---------------------------------------------------------------------------
// Screen (Vendor360View.jsx)
// ---------------------------------------------------------------------------

/// Full-screen 360° viewer for one vendor service.
///
/// [serviceId] is the vendor-service id (int or numeric string); anything
/// that is not a positive number shows the web's invalid-id state. When
/// [service] (the raw vendor-service map) is supplied it is used as-is and
/// no request is made.
class Vendor360Screen extends StatefulWidget {
  const Vendor360Screen({super.key, required this.serviceId, this.service, this.client});

  final Object? serviceId;
  final Map<String, dynamic>? service;

  /// Injectable for tests.
  final http.Client? client;

  @override
  State<Vendor360Screen> createState() => _Vendor360ScreenState();
}

class _Vendor360ScreenState extends State<Vendor360Screen> {
  late final int _id = _parseId(widget.serviceId);
  String _title = '360° View';
  View360Assets _assets = const View360Assets();
  bool _loading = true;
  Object? _error;

  static int _parseId(Object? v) {
    if (v is int) return v > 0 ? v : 0;
    if (v is num) return v > 0 ? v.toInt() : 0;
    final n = num.tryParse('${v ?? ''}'.trim());
    return n != null && n > 0 ? n.toInt() : 0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _apply(widget.service!);
      _loading = false;
    } else if (_id == 0) {
      _loading = false;
    } else {
      _fetch();
    }
  }

  void _apply(Map data) {
    _assets = get360Assets(data);
    _title = view360Title(data);
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = widget.client ?? http.Client();
    try {
      final res = await client
          .get(Uri.parse('${ApiConfig.apiBase}/vendor-services/$_id'))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final decoded = jsonDecode(res.body);
      final data = decoded is Map && decoded['data'] is Map && decoded['id'] == null
          ? decoded['data'] as Map
          : decoded;
      if (data is! Map) throw const FormatException('Unexpected response');
      if (!mounted) return;
      setState(() {
        _apply(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    } finally {
      if (widget.client == null) client.close();
    }
  }

  void _back() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    if (_id == 0 && widget.service == null) {
      return _MessagePage(message: 'Invalid or missing vendor service id.', onBack: _back);
    }
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Loading 360° view…')),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: ErrorState(error: _error, onRetry: _fetch),
      );
    }
    if (_assets.images.isNotEmpty) {
      return _PanoramaPage(
        images: _assets.images.map(_absolute).toList(),
        title: _title,
        onClose: _back,
      );
    }
    if (_assets.url != null) {
      return _TourPage(url: _assets.url!, title: _title, onClose: _back);
    }
    if (_assets.videos.isNotEmpty) {
      return _VideoPage(url: _absolute(_assets.videos.first), title: _title, onClose: _back);
    }
    return _MessagePage(message: 'No 360° content available for this vendor.', onBack: _back);
  }
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: AppText.body),
              const SizedBox(height: AppSpacing.md),
              PremiumButton.outlined(label: 'Go Back', expanded: false, onPressed: onBack),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark header bar shared by the three viewer variants.
class _DarkHeader extends StatelessWidget {
  const _DarkHeader({required this.title, required this.onClose, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final VoidCallback onClose;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sectionTitle.copyWith(color: Colors.white),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppText.caption.copyWith(color: const Color(0xFFD1D5DB))),
              ],
            ),
          ),
          ...actions,
          IconButton(
            tooltip: 'Close 360° view',
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// Panorama viewer (`Image360Modal.jsx`): prev/next, "Image n of N",
/// reset / zoom out / zoom in. Pannellum's hfov zoom maps onto
/// panorama_viewer's zoom factor (1 = default view, up to 5).
class _PanoramaPage extends StatefulWidget {
  const _PanoramaPage({required this.images, required this.title, required this.onClose});
  final List<String> images;
  final String title;
  final VoidCallback onClose;

  @override
  State<_PanoramaPage> createState() => _PanoramaPageState();
}

class _PanoramaPageState extends State<_PanoramaPage> {
  int _index = 0;
  double _zoom = 1;
  final PanoramaController _controller = PanoramaController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setZoom(double z) {
    _zoom = z.clamp(1.0, 5.0);
    _controller.setZoom(_zoom);
  }

  void _reset() {
    _controller.setView(0, 0);
    _setZoom(1);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.images.length;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: PanoramaViewer(
              key: ValueKey(widget.images[_index]),
              panoramaController: _controller,
              animSpeed: 1.0, // web: autoRotate -2
              maxZoom: 5.0,
              child: Image.network(
                widget.images[_index],
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          SafeArea(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
              child: _DarkHeader(
                title: widget.title,
                subtitle: n > 1 ? 'Image ${_index + 1} of $n' : null,
                onClose: widget.onClose,
              ),
            ),
          ),
          if (n > 1) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _RoundButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous',
                onTap: _index > 0 ? () => setState(() { _index--; _zoom = 1; }) : null,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _RoundButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next',
                onTap: _index < n - 1 ? () => setState(() { _index++; _zoom = 1; }) : null,
              ),
            ),
          ],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundButton(icon: Icons.refresh_rounded, tooltip: 'Reset View', onTap: _reset),
                    _RoundButton(icon: Icons.zoom_out_rounded, tooltip: 'Zoom Out', onTap: () => _setZoom(_zoom - 0.5)),
                    _RoundButton(icon: Icons.zoom_in_rounded, tooltip: 'Zoom In', onTap: () => _setZoom(_zoom + 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Material(
        color: Colors.white.withValues(alpha: onTap == null ? 0.08 : 0.18),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: onTap == null ? Colors.white38 : Colors.white),
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// Pasted tour link in a WebView (`Vendor360View.jsx:88-141`).
class _TourPage extends StatefulWidget {
  const _TourPage({required this.url, required this.title, required this.onClose});
  final String url;
  final String title;
  final VoidCallback onClose;

  @override
  State<_TourPage> createState() => _TourPageState();
}

class _TourPageState extends State<_TourPage> {
  late final WebViewController _web = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.white)
    ..loadRequest(Uri.parse(widget.url));

  Future<void> _openInBrowser() async {
    final ok = await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) AppSnackbar.error(context, 'Could not open the link.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _DarkHeader(
              title: widget.title,
              onClose: widget.onClose,
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _openInBrowser,
                  child: const Text('Open in browser'),
                ),
              ],
            ),
            Expanded(child: WebViewWidget(controller: _web)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Text(
                "If this stays blank, the site doesn't allow being shown here. "
                'Use "Open in browser".',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: const Color(0xFFBBBBBB)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// First 360° video, autoplaying with controls (`Vendor360View.jsx:143-181`).
class _VideoPage extends StatefulWidget {
  const _VideoPage({required this.url, required this.title, required this.onClose});
  final String url;
  final String title;
  final VoidCallback onClose;

  @override
  State<_VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<_VideoPage> {
  late final VideoPlayerController _video = VideoPlayerController.networkUrl(Uri.parse(widget.url));
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _video.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _video.play();
    }).catchError((Object _) {
      if (mounted) setState(() => _failed = true);
    });
    _video.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video.removeListener(_onTick);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _video.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _DarkHeader(title: widget.title, onClose: widget.onClose),
            Expanded(
              child: Center(
                child: _failed
                    ? Text('This video could not be played.',
                        style: AppText.body.copyWith(color: Colors.white70))
                    : !ready
                        ? const CircularProgressIndicator(color: Colors.white)
                        : AspectRatio(
                            aspectRatio: _video.value.aspectRatio,
                            child: GestureDetector(
                              onTap: () => _video.value.isPlaying ? _video.pause() : _video.play(),
                              child: VideoPlayer(_video),
                            ),
                          ),
              ),
            ),
            if (ready && !_failed)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _video.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _video.value.isPlaying ? _video.pause() : _video.play(),
                    ),
                    Expanded(
                      child: VideoProgressIndicator(
                        _video,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(playedColor: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
