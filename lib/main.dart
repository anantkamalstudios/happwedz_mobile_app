import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:happy_wedz/Bottombars/HomeScreen.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'
    show MultiProvider, ChangeNotifierProvider;
// Aliased: `Provider` also exists in flutter_riverpod, which is imported above.
import 'package:provider/provider.dart' as legacy_provider show Provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai_chat_screen/ai_chat_screen.dart';
import 'authservice.dart';
import 'core/core.dart';
import 'internetconnection.dart';

/// Root navigator, so the session can tear down every pushed screen the
/// moment authentication is lost — from anywhere in the app.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Manual Firebase initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  FirebaseAuth.instance.setLanguageCode('en');

  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.playIntegrity,
  //   appleProvider: AppleProvider.deviceCheck,
  // );

  Connectivity().onConnectivityChanged.listen((status) async {
    final hasNet = await InternetService.hasInternet();
    debugPrint(hasNet ? "✅ Internet Connected" : "❌ No Internet");
  });

  await Hive.initFlutter();
  await _openBoxSafe('weddingBox');
  await _openBoxSafe('guestBox');

  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getInt('user_id') ?? 0;

  runApp(

    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
          ChangeNotifierProvider(
            create: (_) => ChatProvider()..setUserId(savedUserId),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

Future<void> _openBoxSafe(String boxName) async {
  if (!Hive.isBoxOpen(boxName)) {
    await Hive.openBox(boxName);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      title: 'HappyWedz',
      theme: AppTheme.light(),
      builder: (context, child) {
        // Clamp the OS text scale so accessibility settings can't overflow
        // fixed-height rows, and keep the connectivity overlay on top.
        final scaler = MediaQuery.textScalerOf(
          context,
        ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.2);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: Stack(
            children: [
              if (child != null) child,
              const ConnectivityOverlay(), // shows/hides automatically
            ],
          ),
        );
      },
      home: const AuthGate(),
    );
  }
}

/// The single entry point of the app.
///
/// It owns the answer to "is the user signed in?" and rebuilds the whole tree
/// whenever that changes:
///
/// ```
/// Splash → check session → authenticated ? BottomBars : SignInScreen
/// ```
///
/// Because it sits at the root of the navigator, an unauthenticated user is
/// never given a protected screen to begin with — there is nothing to reach by
/// back navigation, deep link or direct push.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final AuthSession _session = AuthSession.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_onSessionChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A token can expire while the app sits in the background.
    if (state == AppLifecycleState.resumed && _session.isReady) {
      _session.refresh();
    }
  }

  Future<void> _bootstrap() async {
    // Keep the brand moment on screen for the same beat as before.
    await Future.wait([
      _session.refresh(),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
  }

  /// The gate only rebuilds itself, so anything pushed on top of it has to be
  /// torn down explicitly — otherwise a protected screen would survive logout
  /// or a token expiring mid-session.
  void _onSessionChanged() {
    if (_session.isAuthenticated) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = rootNavigatorKey.currentState;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _session,
      builder: (context, _) {
        if (!_session.isReady) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: BrandSplash(),
          );
        }
        return _session.isAuthenticated
            ? const BottomBars()
            : const SignInScreen();
      },
    );
  }
}

class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int phoneLength;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.phoneLength,
  });
}

class CountryData {
  static List<Country> countries = [
    Country(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳', phoneLength: 10),
    Country(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸', phoneLength: 10),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧', phoneLength: 10),
    Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦', phoneLength: 10),
    Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺', phoneLength: 9),
    Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪', phoneLength: 10),
    Country(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷', phoneLength: 9),
    Country(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹', phoneLength: 10),
    Country(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸', phoneLength: 9),
    Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳', phoneLength: 11),
    Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵', phoneLength: 10),
    Country(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷', phoneLength: 10),
    Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷', phoneLength: 11),
    Country(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽', phoneLength: 10),
    Country(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺', phoneLength: 10),
    Country(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦', phoneLength: 9),
    Country(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬', phoneLength: 8),
    Country(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾', phoneLength: 9),
    Country(name: 'Thailand', code: 'TH', dialCode: '+66', flag: '🇹🇭', phoneLength: 9),
    Country(name: 'Indonesia', code: 'ID', dialCode: '+62', flag: '🇮🇩', phoneLength: 10),
    Country(name: 'Philippines', code: 'PH', dialCode: '+63', flag: '🇵🇭', phoneLength: 10),
    Country(name: 'Vietnam', code: 'VN', dialCode: '+84', flag: '🇻🇳', phoneLength: 9),
    Country(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰', phoneLength: 10),
    Country(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩', phoneLength: 10),
    Country(name: 'Sri Lanka', code: 'LK', dialCode: '+94', flag: '🇱🇰', phoneLength: 9),
    Country(name: 'Nepal', code: 'NP', dialCode: '+977', flag: '🇳🇵', phoneLength: 10),
    Country(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪', phoneLength: 9),
    Country(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦', phoneLength: 9),
    Country(name: 'Turkey', code: 'TR', dialCode: '+90', flag: '🇹🇷', phoneLength: 10),
    Country(name: 'Egypt', code: 'EG', dialCode: '+20', flag: '🇪🇬', phoneLength: 10),
  ];
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  /// OAuth **web** client id (`client_type: 3`) from
  /// `android/app/google-services.json`.
  ///
  /// Android only returns a non-null `idToken` when this is supplied — and the
  /// backend's `/api/user/google-auth` verifies exactly that token, so without
  /// it every sign-in fails no matter how well Google Sign-In is configured.
  /// It must stay the *web* client id; an Android client id here makes Play
  /// Services fail with `ApiException: 10 (DEVELOPER_ERROR)`.
  static const String _serverClientId =
      '5404414440-02ttfd1mvhk62e5bubrkcipdjhdrrabv.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: _serverClientId,
  );

  /// True while a Google sign-in is in flight — drives the button's loading
  /// state and blocks duplicate taps.
  bool _isSigningIn = false;

  Future<void> fetchAndSaveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final userId = prefs.getInt("user_id");
    if (userId == null) return;

    final url = 'https://happywedz.com/api/user/$userId';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final user = data['user'];

          // 🔐 SAVE EVERYTHING YOU NEED
          prefs.setString('user_name', user['name'] ?? '');
          prefs.setString('user_email', user['email'] ?? '');
          prefs.setString('user_mobile', user['phone'] ?? '');
          prefs.setString('wedding_venue', user['weddingVenue'] ?? '');
          prefs.setString('wedding_date', user['weddingDate'] ?? '');
          prefs.setString('user_photo', user['profileImage'] ?? '');

          debugPrint('✅ Profile fetched & saved');
        }
      }
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');
    }
  }

















  /// The only way into the app.
  ///
  /// Signs in with Google, hands the id token to the existing
  /// `/api/user/google-auth` endpoint, persists the returned session through
  /// [UserPrefs] and then lets [AuthSession] re-read it — the `AuthGate` swaps
  /// to the dashboard on its own, so no login route is left on the stack.
  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) return; // ignore repeat taps while a sign-in is running
    setState(() => _isSigningIn = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // The user backed out of the Google sheet.
      if (googleUser == null) {
        _showSnackBar('Google Sign-In cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      // Google returned an account but no usable credential.
      if (idToken == null || idToken.isEmpty) {
        await _googleSignIn.signOut();
        await _showError(
          title: 'Sign-in failed',
          message:
              "We couldn't verify your Google account. Please try signing in again.",
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse('https://happywedz.com/api/user/google-auth'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': googleUser.email,
              'name': googleUser.displayName ?? 'HappyWedz User',
              'tokenId': idToken,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        await _showError(
          title: AppErrorMessage.titleFor('${response.statusCode}'),
          message:
              'We could not sign you in right now (${response.statusCode}). Please try again.',
        );
        return;
      }

      final data = jsonDecode(response.body);
      if (data is! Map || data['success'] != true) {
        await _showError(
          title: 'Sign-in failed',
          message:
              (data is Map ? data['message']?.toString() : null) ??
              'Please try signing in again.',
        );
        return;
      }

      final user = data['user'];
      final token = data['token']?.toString();
      final userId = user is Map ? int.tryParse('${user['id']}') : null;

      // Invalid / incomplete authentication response — never persist it.
      if (user is! Map ||
          userId == null ||
          userId <= 0 ||
          token == null ||
          token.isEmpty) {
        await _showError(
          title: 'Sign-in failed',
          message:
              'The sign-in response was incomplete. Please try again in a moment.',
        );
        return;
      }

      // 1️⃣ Persist the session through the existing storage layer.
      await UserPrefs.saveUser(
        id: userId,
        name: (user['name'] ?? googleUser.displayName ?? '').toString(),
        email: (user['email'] ?? googleUser.email).toString(),
        token: token,
        phone: user['phone']?.toString(),
        photo: googleUser.photoUrl,
      );

      // 2️⃣ Refresh the authenticated user's profile before the app opens.
      await fetchAndSaveUserProfile();

      if (mounted) {
        // Keep the chat session bound to the user who just signed in.
        legacy_provider.Provider.of<ChatProvider>(
          context,
          listen: false,
        ).setUserId(userId);
        _showSnackBar('Welcome ${user['name'] ?? ''}'.trim());
      }

      // 3️⃣ Publish the session — AuthGate rebuilds straight into BottomBars.
      await AuthSession.instance.refresh();
    } on SocketException catch (e) {
      await _showError(
        title: AppErrorMessage.offlineTitle,
        message: AppErrorMessage.bodyFor(e),
      );
    } on TimeoutException {
      await _showError(
        title: AppErrorMessage.timeoutTitle,
        message: AppErrorMessage.timeoutBody,
      );
    } on PlatformException catch (e, stack) {
      debugPrint('🚨 Google Sign-In platform error: ${e.code} ${e.message}\n$stack');

      // `sign_in_failed … ApiException: 10` is DEVELOPER_ERROR: Play Services
      // could not match this build to an OAuth client (signing certificate,
      // package name or client id mismatch). Nothing the user can fix by
      // retrying, so say so plainly rather than showing a generic failure.
      final bool misconfigured =
          e.code == 'sign_in_failed' && '${e.message}'.contains('10:');

      await _showError(
        title: misconfigured ? 'Sign-in unavailable' : 'Sign-in failed',
        message: misconfigured
            ? 'Google Sign-In is not configured for this build of the app. '
                  'Please update to the latest version or contact support.'
            : AppErrorMessage.bodyFor(e),
      );
    } catch (e, stack) {
      debugPrint('🚨 Google Sign-In failed: $e\n$stack');
      await _showError(
        title: AppErrorMessage.titleFor(e),
        message: AppErrorMessage.bodyFor(e),
      );
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    AppSnackbar.info(context, message);
  }

  /// Opens the HappyWedz Vendors app on the Play Store.
  ///
  /// Tries the `market:` scheme first so the Play Store app handles it
  /// directly; falls back to the https listing (browser / Play web) when the
  /// store app is unavailable, e.g. on a device without Play Services.
  Future<void> _openVendorApp() async {
    const packageName = 'com.happy.happy_weds_vendors';
    final market = Uri.parse('market://details?id=$packageName');
    final web = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      if (await canLaunchUrl(market)) {
        final opened = await launchUrl(
          market,
          mode: LaunchMode.externalApplication,
        );
        if (opened) return;
      }

      final opened = await launchUrl(
        web,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        _showSnackBar('Could not open the Play Store.');
      }
    } catch (e) {
      debugPrint('Could not open vendor app listing: $e');
      _showSnackBar('Could not open the Play Store.');
    }
  }

  /// Error feedback with a one-tap retry, using the shared popup.
  Future<void> _showError({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await ErrorPopup.show(
      context,
      title: title,
      message: message,
      retryLabel: 'Try Again',
      // Deferred by a frame so the in-flight attempt finishes releasing the
      // re-entrancy guard before the retry starts.
      onRetry: () => WidgetsBinding.instance.addPostFrameCallback(
        (_) => _signInWithGoogle(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: height * 0.07),

                          // Brand mark
                          FadeSlideIn(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: AppColors.shadowMd,
                                ),
                                child: Image.asset(
                                  'assets/logo.png',
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.favorite_rounded,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xxl),

                          FadeSlideIn(
                            delay: const Duration(milliseconds: 60),
                            child: Column(
                              children: [
                                Text(
                                  'Welcome to HappyWedz',
                                  textAlign: TextAlign.center,
                                  style: AppText.display.copyWith(
                                    color: AppColors.textDark,
                                    fontSize: height < 700 ? 26 : 30,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Sign in to plan, book and manage your\nbig day — all in one place.',
                                  textAlign: TextAlign.center,
                                  style: AppText.bodySm.copyWith(
                                    color: AppColors.textDark.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Sign-in card
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 120),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              radius: AppRadii.xl,
                              shadow: AppColors.shadowLg,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Sign In / Sign Up',
                                    style: AppText.sectionTitle,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  _GoogleButton(
                                    onPressed: _signInWithGoogle,
                                    isLoading: _isSigningIn,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          PremiumButton.text(
                            label: 'Looking for a Business Account?',
                            expanded: true,
                            onPressed: _openVendorApp,
                          ),

                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// White Google button matching the platform guidelines, with press feedback.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed, this.isLoading = false});

  final VoidCallback onPressed;

  /// While true the button shows a spinner and stops accepting taps.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      onTap: isLoading ? null : onPressed,
      withRipple: true,
      borderRadius: AppRadii.rMd,
      rippleColor: AppColors.primary.withValues(alpha: 0.08),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: AppColors.divider),
          boxShadow: AppColors.shadowSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              Image.asset(
                'assets/google.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.g_mobiledata_rounded,
                  size: 24,
                  color: AppColors.textDark,
                ),
              ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                isLoading ? 'Signing you in…' : 'Continue with Google',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.button.copyWith(color: AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class UserRoleScreen extends StatelessWidget {
  const UserRoleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 130),

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Tell us who you are',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Role buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: [
                        _buildRoleButton(context, 'Bride'),
                        _buildRoleButton(context, 'Groom'),
                        _buildRoleButton(context, 'Other'),
                      ],
                    ),
                  ),
                ],
              ),

              // Skip button (cross on top right)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeddingDateScreen(), // main screen
                      ),
                          (route) => false, // clear all previous routes
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Skip',
                      style: const TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeddingDateScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: const Color(0xFF424242),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class WeddingDateScreen extends StatefulWidget {
  const WeddingDateScreen({Key? key}) : super(key: key);

  @override
  _WeddingDateScreenState createState() => _WeddingDateScreenState();
}

class _WeddingDateScreenState extends State<WeddingDateScreen> {
  DateTime? selectedDate;
  final TextEditingController _dateController = TextEditingController();

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _dateController.text =
        '${picked.day}/${picked.month}/${picked.year}';
      });

      // Navigate automatically after picking date
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const WeddingCityScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (left)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserRoleScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF424242),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Do you have a wedding\ndate?',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: InputDecoration(
                        hintText: 'Select Date',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300, width: 1),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              // Skip button (top right cross)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeddingCityScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20), // pill-shaped
                    ),
                    child: Text(
                      'Skip',
                      style: const TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class WeddingCityScreen extends StatefulWidget {
  const WeddingCityScreen({Key? key}) : super(key: key);

  @override
  State<WeddingCityScreen> createState() => _WeddingCityScreenState();
}

class _WeddingCityScreenState extends State<WeddingCityScreen> {
  String? selectedCity; // keep track of selected city

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button (left)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF424242),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Progress indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      children: [
                        _progressBar(30, true),
                        const SizedBox(width: 8),
                        _progressBar(30, true),
                        const SizedBox(width: 8),
                        _progressBar(60, true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Which city is your\nwedding in?',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // City buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      children: [
                        _buildCityButton(context, 'Delhi NCR'),
                        _buildCityButton(context, 'Mumbai'),
                        _buildCityButton(context, 'Bangalore'),
                        _buildCityButton(context, 'Hyderabad'),
                        _buildCityButton(context, 'Chennai'),
                        _buildCityButton(context, 'Pune'),
                        _buildCityButton(context, 'Lucknow'),
                        _buildCityButton(context, 'Jaipur'),
                        _buildCityButton(context, 'Other'),
                      ],
                    ),
                  ),
                ],
              ),

              // Skip button (cross on top right)
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const AuthGate()),
                          (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20), // pill-shaped for text
                    ),
                    child: Text(
                      'Skip',
                      style: const TextStyle(
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityButton(BuildContext context, String label) {
    final bool isSelected = selectedCity == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCity = label;
        });

        // Navigate after short delay so color shows before navigation
        Future.delayed(const Duration(milliseconds: 100), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthGate()),
                (route) => false,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE91E63) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 17,
            color: isSelected ? Colors.white : const Color(0xFF424242),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _progressBar(double width, bool active) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE91E63) : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}



/// Re-checks the stored session before a protected action runs.
///
/// The app is gated at the root by [AuthGate], so this is a second line of
/// defence for tokens that expire while the user is inside the app: when the
/// session is gone, [AuthSession] notifies the gate, which tears the stack
/// down and shows the login screen. Callers only need the boolean.
Future<bool> ensureLoggedIn(BuildContext context) async {
  return AuthSession.instance.refresh();
}

/// Logout entry point used everywhere: clears the session, then unwinds the
/// navigator so no protected screen is left behind [AuthGate].
Future<void> signOutToLogin(BuildContext context) async {
  // AUDIT FIX (async context): the navigator was resolved *after* the await,
  // and `Navigator.maybeOf(context)` on a context whose element has since been
  // unmounted throws. Capturing it first means the fallback is looked up while
  // the caller's context is still guaranteed valid; `rootNavigatorKey` is a
  // GlobalKey and stays safe to read at any time.
  final NavigatorState? fallback = Navigator.maybeOf(context);

  await AuthSession.instance.signOut();

  final navigator = rootNavigatorKey.currentState ?? fallback;
  if (navigator != null && navigator.mounted && navigator.canPop()) {
    navigator.popUntil((route) => route.isFirst);
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
    void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    });
  }
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE83580),
      body: SafeArea(
        child: Stack(
          children: [
            /// 🔹 Top Overlapping Images
            Positioned(
              top: screenHeight * 0.05,
              left: screenWidth * 0.05,
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2012.png?alt=media&token=1939ca1e-2736-4229-9a01-8672ef867f55',
                -0.1,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),
            Positioned(
              top: screenHeight * 0.03, // slightly higher for overlap
              left: screenWidth * 0.14, // overlap with first
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2013.png?alt=media&token=f2bcafb7-30c5-440b-8212-1e5aea6420bc',
                0.1,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),

// right side pair
            Positioned(
              top: screenHeight * 0.05,
              right: screenWidth * 0.05,
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2012.png?alt=media&token=1939ca1e-2736-4229-9a01-8672ef867f55',
                -0.1,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.14, // overlap inside right group
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2013.png?alt=media&token=f2bcafb7-30c5-440b-8212-1e5aea6420bc',
                0.08,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),


            /// 🔹 Bottom Overlapping Images
            Positioned(
              bottom: screenHeight * 0.05,
              left: screenWidth * 0.05,
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2012.png?alt=media&token=1939ca1e-2736-4229-9a01-8672ef867f55',
                0.1,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.03,
              left: screenWidth * 0.14,
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2013.png?alt=media&token=f2bcafb7-30c5-440b-8212-1e5aea6420bc',
                -0.1,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.05,
              right: screenWidth * 0.28,
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2012.png?alt=media&token=1939ca1e-2736-4229-9a01-8672ef867f55',
                0.1,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.02,
              right: screenWidth * 0.05,
              child: _tiltedImage(
                'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2013.png?alt=media&token=f2bcafb7-30c5-440b-8212-1e5aea6420bc',
                -0.08,
                screenWidth * 0.28,
                screenHeight * 0.20,
              ),
            ),

            /// 🔹 Center Logo + Text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NetworkImageWidget(url: 'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fc1b3759a213819470729c75cb198cc23ca254ad4image%204.png?alt=media&token=3f5e24ec-7683-4afe-94ee-f747b85c49b4', height: screenHeight * 0.08),
                  const SizedBox(height: 12),
                  Text(
                    "We want to make your\nwedding planning\nprocess super easy!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5A2072),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: Text(
                      "Wedding Photographers in India | Bridal Makeup Artists in India | "
                          "Wedding Cards in India | Wedding Venues in India",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
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

  /// 🔹 Helper widget for tilted image
  /// 🔹 Helper widget for tilted image
  Widget _tiltedImage(String url, double angle, double width, double height) {
    return Transform.rotate(
      angle: angle,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: NetworkImageWidget(url: url, width: width, height: height, fit: BoxFit.cover),
      ),
    );
  }
}




class TravelPromoScreen extends StatefulWidget {
  @override
  _TravelPromoScreenState createState() => _TravelPromoScreenState();
}

class _TravelPromoScreenState extends State<TravelPromoScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to next screen after 5 seconds
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()), // replace with your screen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[800],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 30),

              // Top image row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  travelImage('assets/Rectangle 20.png'),
                  travelImage('assets/Rectangle 22.png'),
                  travelImage('assets/Rectangle 23.png'),
                  travelImage('assets/Rectangle 24.png'),
                ],
              ),

              Spacer(),

              // Center content
              Column(
                children: [
                  // App logo
                  Image.asset(
                    'assets/image 4.png', // replace with your logo path
                    height: 150,
                    width: 150,
                  ),
                  SizedBox(height: 5),

                  // Headline text
                  Text(
                    'We want to make your\n wedding planning \nprocess super easy!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[300],
                    ),
                  ),
                  SizedBox(height: 15),

                  // Subheading text
                  Text(
                    'Wedding Photographers in India | \nBridal Makeup Artists in India | \nWedding Cards in India | \nWedding Venues in India',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ],
              ),

              Spacer(),

              // Bottom image row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  travelImage('assets/Rectangle 20.png'),
                  travelImage('assets/Rectangle 22.png'),
                  travelImage('assets/Rectangle 23.png'),
                  travelImage('assets/Rectangle 24.png'),
                ],
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Widget for rounded travel images
  Widget travelImage(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          path,
          width: 76,
          height: 90,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class MakeMyTripHomePage extends StatelessWidget {
  const MakeMyTripHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section with floating destination cards
            Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey[100]!,
                    Colors.white,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background destination cards
                  _buildFloatingDestinationCards(),
                ],
              ),
            ),

            // Logo section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'make',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'my',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'trip',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),

            // Main content section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Title section
                  Column(
                    children: [
                      Text(
                        'Book India',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        '&',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'International Travel',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Flights, Stays, Visa, Forex & Attractions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  // Bottom destination cards
                  _buildBottomDestinationCards(),

                  const SizedBox(height: 40),

                  // Footer text
                  Text(
                    'Powering magical trips for 25 years',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
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

  Widget _buildFloatingDestinationCards() {
    return Stack(
      children: [
        // Statue of Unity (India)
        Positioned(
          left: -20,
          top: 80,
          child: _buildDestinationCard(
            'assets/statue_of_unity.jpg',
            width: 160,
            height: 200,
            borderRadius: 20,
          ),
        ),

        // Taj Mahal
        Positioned(
          left: 80,
          top: 20,
          child: _buildDestinationCard(
            'assets/taj_mahal.jpg',
            width: 200,
            height: 240,
            borderRadius: 25,
          ),
        ),

        // Eiffel Tower
        Positioned(
          right: 120,
          top: 60,
          child: _buildDestinationCard(
            'assets/eiffel_tower.jpg',
            width: 180,
            height: 220,
            borderRadius: 22,
          ),
        ),

        // Golden Gate Bridge
        Positioned(
          right: -30,
          top: 100,
          child: _buildDestinationCard(
            'assets/golden_gate.jpg',
            width: 170,
            height: 200,
            borderRadius: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomDestinationCards() {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          // London Bridge
          Positioned(
            left: -40,
            bottom: 0,
            child: _buildDestinationCard(
              'assets/london_bridge.jpg',
              width: 180,
              height: 160,
              borderRadius: 20,
            ),
          ),

          // Santorini
          Positioned(
            left: 100,
            bottom: 40,
            child: _buildDestinationCard(
              'assets/santorini.jpg',
              width: 200,
              height: 180,
              borderRadius: 22,
            ),
          ),

          // Golden Gate at sunset
          Positioned(
            right: 80,
            bottom: 20,
            child: _buildDestinationCard(
              'assets/golden_gate_sunset.jpg',
              width: 190,
              height: 170,
              borderRadius: 20,
            ),
          ),

          // Mountain landscape
          Positioned(
            right: -50,
            bottom: 60,
            child: _buildDestinationCard(
              'assets/mountain_landscape.jpg',
              width: 160,
              height: 140,
              borderRadius: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(String imagePath, {
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[300]!,
                Colors.teal[400]!,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.location_on,
              color: Colors.white.withValues(alpha: 0.7),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin wrapper kept for call sites — [AuthSession] owns the actual rules so
/// expiry and logout can't diverge between here and the gate.
class AuthUtils {
  static const int tokenExpiryDays = AuthSession.tokenExpiryDays;

  /// True when there is no usable session (missing, invalid or expired token).
  static Future<bool> isTokenExpired() async {
    return !await AuthSession.instance.refresh();
  }

  // Logout function
  static Future<void> logout() => AuthSession.instance.signOut();
}
