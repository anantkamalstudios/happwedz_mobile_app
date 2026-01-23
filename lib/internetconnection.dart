// language: dart
// File: `lib/internetconnection.dart`
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InternetService {
  /// Quick network type check + real internet lookup
  static Future<bool> hasInternet() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late StreamSubscription _sub; // avoid strict generic to prevent cast issues
  Timer? _debounce; // small debounce to avoid flicker

  ConnectivityProvider() {
    _init();
    // listen for connectivity changes (wifi/mobile/none)
    _sub = Connectivity().onConnectivityChanged.listen((_) => _handleChange());
  }

  Future<void> _init() async {
    final online = await InternetService.hasInternet();
    _updateState(online);
  }

  void _handleChange() {
    // debounce rapid flaps
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final online = await InternetService.hasInternet();
      _updateState(online);
    });
  }

  Future<void> retryNow() async {
    final online = await InternetService.hasInternet();
    _updateState(online);
  }

  void _updateState(bool online) {
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}

class ConnectivityOverlay extends StatefulWidget {
  const ConnectivityOverlay({super.key});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ConnectivityProvider>(context);
    final isOnline = provider.isOnline;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 350),
        offset: isOnline ? const Offset(0, -1) : Offset.zero,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: isOnline ? Colors.green[600] : Colors.red[600],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      isOnline ? Icons.wifi : Icons.wifi_off,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOnline ? 'Back online' : 'No internet connection',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isOnline
                                ? 'You are connected. Sync resumed.'
                                : 'Some features may be unavailable. Check your connection.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isOnline) ...[
                      TextButton(
                        onPressed: () async {
                          await provider.retryNow();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white24,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('RETRY'),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
