/// The mandatory-update wall.
///
/// [MandatoryUpdateGate] sits in the same overlay stack as the connectivity
/// banner, so the check lives in exactly one place for the whole app and no
/// screen has to know about it. When the store has a newer release it pushes
/// [MandatoryUpdateDialog] on the root navigator as a barrier-locked route:
/// the route is topmost and non-poppable, so nothing underneath can be
/// reached or interacted with until the app is updated.
///
/// There is deliberately no Later, Cancel, Skip or close affordance, no
/// barrier dismissal and no back-button escape. The only control is
/// "Update Now".
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'premium_button.dart';

class MandatoryUpdateGate extends StatefulWidget {
  const MandatoryUpdateGate({
    super.key,
    required this.navigatorKey,
    this.service = const UpdateService(),
  });

  /// The root navigator the blocking route is pushed onto. Passed in rather
  /// than read from a global so the gate can be driven in tests.
  final GlobalKey<NavigatorState> navigatorKey;

  final UpdateService service;

  @override
  State<MandatoryUpdateGate> createState() => _MandatoryUpdateGateState();
}

class _MandatoryUpdateGateState extends State<MandatoryUpdateGate>
    with WidgetsBindingObserver {
  /// True while the blocking route is on screen, so a resume or a reconnect
  /// cannot stack a second copy of it.
  bool _isBlocking = false;

  /// Guards against overlapping checks (resume and reconnect can land
  /// together).
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // After the first frame: the root navigator has to exist before a route
    // can be pushed onto it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());

    // A check that failed while offline is retried the moment a transport
    // comes back, rather than waiting for the next cold start.
    Connectivity().onConnectivityChanged.listen((results) {
      final hasTransport =
          results.any((result) => result != ConnectivityResult.none);
      if (hasTransport) _check();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check on return to the foreground — including the return from the
    // store itself, so a completed update clears the wall.
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_isBlocking || _isChecking || !mounted) return;
    _isChecking = true;
    try {
      final status = await widget.service.check();
      if (!mounted || _isBlocking) return;
      if (status.updateRequired) {
        _showBlockingDialog(status);
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _showBlockingDialog(UpdateStatus status) async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return;

    _isBlocking = true;
    await showGeneralDialog<void>(
      context: navigatorContext,
      // Tapping the scrim does nothing.
      barrierDismissible: false,
      barrierLabel: 'Update required',
      // Near-opaque: the app behind is neither usable nor legible.
      barrierColor: Colors.black.withValues(alpha: 0.82),
      transitionDuration: const Duration(milliseconds: 220),
      useRootNavigator: true,
      pageBuilder: (_, __, ___) => MandatoryUpdateDialog(status: status),
      transitionBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
    // Only reached if the route is ever popped programmatically; the dialog
    // itself offers no way to do so.
    _isBlocking = false;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The update wall itself. Public so widget tests can pump it directly.
class MandatoryUpdateDialog extends StatefulWidget {
  const MandatoryUpdateDialog({super.key, required this.status, this.onLaunch});

  final UpdateStatus status;

  /// Injection point for tests; production uses [launchUrl].
  final Future<bool> Function(Uri uri)? onLaunch;

  @override
  State<MandatoryUpdateDialog> createState() => _MandatoryUpdateDialogState();
}

class _MandatoryUpdateDialogState extends State<MandatoryUpdateDialog> {
  bool _isOpening = false;
  String? _error;

  Future<void> _openStore() async {
    final url = widget.status.storeUrl;
    if (url == null || _isOpening) return;

    setState(() {
      _isOpening = true;
      _error = null;
    });

    var opened = false;
    try {
      final launcher = widget.onLaunch ??
          (Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
      opened = await launcher(Uri.parse(url));
    } catch (_) {
      opened = false;
    }

    if (!mounted) return;
    setState(() {
      _isOpening = false;
      // The wall stays up either way: a store that will not open is a reason
      // to retry, never a reason to let the user past.
      _error = opened
          ? null
          : 'Could not open the store. Please check your connection and try '
              'again, or update HappyWedz manually from the store.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final installed = widget.status.installedVersion;
    final store = widget.status.storeVersion;

    return PopScope(
      // The Android back button (and predictive back) cannot dismiss this.
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.xxl,
              ),
              child: ConstrainedBox(
                // Caps the card on tablets and large phones; the scroll view
                // above absorbs anything taller than a short screen, so the
                // layout cannot overflow.
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadii.rXl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.blush,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Update Available',
                        textAlign: TextAlign.center,
                        style: AppText.sectionTitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'A new version of HappyWedz is available. Please '
                        'update to continue using the app.',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (installed != null && store != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: AppRadii.rMd,
                          ),
                          child: Column(
                            children: [
                              _VersionRow(
                                label: 'Current version',
                                value: installed,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _VersionRow(
                                label: 'Latest version',
                                value: store,
                                highlight: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppText.caption.copyWith(
                            color: AppColors.errorDark,
                          ),
                        ),
                      ],
                      SizedBox(
                        height: media.size.height < 600
                            ? AppSpacing.lg
                            : AppSpacing.xl,
                      ),
                      PremiumButton(
                        label: 'UPDATE NOW',
                        icon: Icons.download_rounded,
                        isLoading: _isOpening,
                        onPressed: _openStore,
                      ),
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

class _VersionRow extends StatelessWidget {
  const _VersionRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppText.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.md),
        // A long version string shrinks rather than overflowing the row.
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
