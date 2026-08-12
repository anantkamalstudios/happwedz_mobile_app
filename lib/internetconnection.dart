// language: dart
// File: `lib/internetconnection.dart`
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/core.dart';

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
        duration: AppMotion.normal,
        curve: AppMotion.emphasized,
        offset: isOnline ? const Offset(0, -1) : Offset.zero,
        child: AnimatedOpacity(
          duration: AppMotion.normal,
          opacity: isOnline ? 0 : 1,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Material(
                elevation: 6,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: AppRadii.rLg,
                color: isOnline ? AppColors.successDark : AppColors.errorDark,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          color: AppColors.textOnPrimary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOnline
                                  ? 'Back online'
                                  : AppErrorMessage.offlineTitle,
                              style: AppText.cardTitle.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              isOnline
                                  ? 'You are connected. Sync resumed.'
                                  : 'Some features may be unavailable.',
                              style: AppText.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isOnline) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Pressable(
                          onTap: provider.retryNow,
                          borderRadius: AppRadii.rSm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: AppRadii.rSm,
                            ),
                            child: Text(
                              'Retry',
                              style: AppText.buttonSm.copyWith(
                                color: AppColors.textOnPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
