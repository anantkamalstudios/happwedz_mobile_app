import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:happy_wedz/Bottombars/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'authservice.dart';
import 'core/config/api_config.dart';
import 'core/core.dart';
import 'guestlist/guestlist.dart';
import 'main.dart';


class ProfileSettingsScreen extends StatefulWidget {
  const  ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  TextEditingController mobileController = TextEditingController();
  TextEditingController weddingVenueController = TextEditingController();
  TextEditingController weddingDateController = TextEditingController();

  String userName = '';
  String userEmail = '';
  String userPhoto = '';
  int? userId;

  List<String> _cities = [];
  bool _isLoadingCities = false;
  bool _isSaving = false;

  // Validation Errors
  String? mobileError;
  String? venueError;
  String? weddingDateError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  Future<bool> _isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();

    final mobile = prefs.getString('user_mobile');
    final venue = prefs.getString('wedding_venue');
    final date = prefs.getString('wedding_date');

    return mobile != null && mobile.isNotEmpty &&
        venue != null && venue.isNotEmpty &&
        date != null && date.isNotEmpty;
  }
  // -----------------------------------------------------
  // LOGIN CHECK
  // -----------------------------------------------------
  /// Re-checks the session before saving. The app-wide gate sends the user
  /// back to login on its own when this comes back false.
  Future<bool> ensureLoggedIn(BuildContext context) => AuthSession.instance.refresh();

  // -----------------------------------------------------
  // LOAD USER DATA
  // -----------------------------------------------------
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    userName = prefs.getString("user_name") ?? "";
    userEmail = prefs.getString("user_email") ?? "";
    userPhoto = prefs.getString("user_photo") ?? "";
    userId = prefs.getInt("user_id");

    mobileController.text = prefs.getString("user_mobile") ?? "";
    weddingVenueController.text = prefs.getString("wedding_venue") ?? "";
    weddingDateController.text = prefs.getString("wedding_date") ?? "";

    // Guarded: reading preferences is async, so the screen may already be gone.
    if (!mounted) return;
    setState(() {});
  }

  // -----------------------------------------------------
  // VALIDATIONS
  // -----------------------------------------------------
  String? validateMobile(String m) {
    if (m.isEmpty) return "Mobile number is required";
    if (!RegExp(r'^[0-9]{10}$').hasMatch(m)) return "Enter a valid 10-digit number";
    if (!RegExp(r'^[6-9]').hasMatch(m)) return "Must start with 6, 7, 8, or 9";
    return null;
  }

  String? validateVenue(String v) {
    if (v.isEmpty) return "Wedding venue is required";
    return null;
  }

  String? validateWeddingDate(String date) {
    if (date.isEmpty) return "Wedding date is required";

    DateTime today = DateTime.now();
    DateTime selected = DateTime.tryParse(date) ?? today;

    DateTime minDate = DateTime(today.year - 1);
    DateTime maxDate = DateTime(today.year + 5);

    if (selected.isBefore(minDate)) return "Wedding date is too old";
    if (selected.isAfter(maxDate)) return "Wedding date is too far in the future";

    return null;
  }

  // -----------------------------------------------------
  // LOAD CITIES
  // -----------------------------------------------------
  /// AUDIT FIX: this used to call
  /// `.../countries/state/cities/q?country=India&state=Maharashtra`, so the
  /// "Wedding Venue (City)" picker could only ever offer Maharashtra cities —
  /// a user marrying in Delhi, Bengaluru or Jaipur had no selectable value.
  /// The home screen already solved this with [LocationService.fetchCities],
  /// which asks for every Indian city; reusing it keeps one implementation
  /// instead of two divergent ones.
  Future<void> _loadCities() async {
    setState(() => _isLoadingCities = true);
    try {
      final loaded = await LocationService.fetchCities('India');

      final cities = loaded
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() => _cities = cities);
    } catch (e) {
      // Never surface the raw exception to the user; the picker simply stays
      // empty and the next tap retries.
      debugPrint('City loading error: $e');
    } finally {
      // Guarded: the user can leave Profile while the request is in flight.
      if (mounted) setState(() => _isLoadingCities = false);
    }
  }

  // -----------------------------------------------------
  // CITY SEARCH
  // -----------------------------------------------------
  Future<void> _showCityPicker() async {
    if (_isLoadingCities) return;
    if (_cities.isEmpty) await _loadCities();
    if (!mounted) return;

    final selected = await showSearch<String>(
      context: context,
      delegate: _CitySearchDelegate(_cities),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        weddingVenueController.text = selected;
      });
    }
  }

  // -----------------------------------------------------
  // DATE PICKER
  // -----------------------------------------------------
  Future<void> _pickWeddingDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select Wedding Date',
    );

    if (picked != null) {
      String formatted = picked.toIso8601String().split('T')[0];
      weddingDateController.text = formatted;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wedding_date', formatted);
    }
  }



  // AUDIT NOTE:
  // This is a byte-for-byte duplicate of `fetchAndSaveUserProfile()` in
  // lib/main.dart, which runs once right after a successful Google sign-in.
  // Nothing in this file ever called this copy, so it was dead code that could
  // silently drift away from the version that actually runs.
  // Kept intentionally and commented out as requested.
  // Do not remove without confirming with the project owner.
  //
  // Future<void> fetchAndSaveUserProfile() async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   final userId = prefs.getInt("user_id");
  //   if (userId == null) return;
  //
  //   final url = 'https://happywedz.com/api/user/$userId';
  //
  //   try {
  //     final response = await http.get(Uri.parse(url));
  //
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //
  //       if (data['success'] == true) {
  //         final user = data['user'];
  //
  //         // 🔐 SAVE EVERYTHING YOU NEED
  //         prefs.setString('user_name', user['name'] ?? '');
  //         prefs.setString('user_email', user['email'] ?? '');
  //         prefs.setString('user_mobile', user['phone'] ?? '');
  //         prefs.setString('wedding_venue', user['weddingVenue'] ?? '');
  //         prefs.setString('wedding_date', user['weddingDate'] ?? '');
  //         prefs.setString('user_photo', user['profileImage'] ?? '');
  //
  //         print('✅ Profile fetched & saved');
  //       }
  //     }
  //   } catch (e) {
  //     print('❌ Profile fetch error: $e');
  //   }
  // }
  // -----------------------------------------------------
  // UPDATE PROFILE
  // -----------------------------------------------------
  Future<void> _updateUserProfile() async {
    // RUN VALIDATIONS
    setState(() {
      mobileError = validateMobile(mobileController.text.trim());
      venueError = validateVenue(weddingVenueController.text.trim());
      weddingDateError = validateWeddingDate(weddingDateController.text.trim());
    });

    if (mobileError != null || venueError != null || weddingDateError != null) {
      AppSnackbar.warning(context, 'Please fix the highlighted fields.');
      return;
    }

    FocusScope.of(context).unfocus();

    final loggedIn = await ensureLoggedIn(context);
    if (!loggedIn) return;

    if (userId == null) return _showSnackBar('User ID missing');

    setState(() => _isSaving = true);

    final url = '${ApiConfig.apiBase}/user/$userId';

    // AUDIT FIX (security): this PUT identified the account purely by the id in
    // the URL and sent no credentials, so the request carried nothing proving
    // it came from the signed-in user. Every other authenticated call in the
    // app sends the stored JWT; this one now does too.
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(UserPrefs.tokenKey) ?? '';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phone': mobileController.text.trim(),
          'weddingVenue': weddingVenueController.text.trim(),
          'weddingDate': weddingDateController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // if (data['success'] == true) {
        //   final prefs = await SharedPreferences.getInstance();
        //   final user = data['user'];
        //
        //   prefs.setString('user_mobile', user['phone'] ?? '');
        //   prefs.setString('wedding_venue', user['weddingVenue'] ?? '');
        //   prefs.setString('wedding_date', user['weddingDate'] ?? '');
        //
        //   _showSnackBar('Profile updated successfully ✔️');
        // }
        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final user = data['user'];

          await prefs.setString('user_mobile', user['phone'] ?? '');
          await prefs.setString('wedding_venue', user['weddingVenue'] ?? '');
          await prefs.setString('wedding_date', user['weddingDate'] ?? '');

          if (!mounted) return;
          await SuccessPopup.show(
            context,
            title: 'Profile updated',
            message: 'Your wedding details have been saved.',
          );

          // ✅ CHECK PROFILE COMPLETION
          final complete = await _isProfileComplete();

          if (complete && mounted) {
            // AUDIT FIX (authentication bypass): this used to be
            // `pushAndRemoveUntil(..., (route) => false)`, which wiped the
            // *first* route as well — and the first route is `AuthGate`, the
            // widget that owns the signed-in/signed-out decision. Once it was
            // gone, `signOutToLogin()`'s `popUntil(isFirst)` had nothing to
            // unwind, so logging out left the user sitting inside a protected
            // screen. Pushing normally keeps AuthGate at the root of the stack.
            Navigator.push(
              context,
              AnimatedPageRoute(
                page: const GuestListDashboard(),
                style: PageTransitionStyle.fade,
              ),
            );
          }
        } else {
          if (!mounted) return;
          await ErrorPopup.show(
            context,
            title: 'Update failed',
            message:
                "We couldn't save your changes. Please check your details and try again.",
            onRetry: _updateUserProfile,
          );
        }
      } else {
        if (!mounted) return;
        await ErrorPopup.show(
          context,
          title: AppErrorMessage.serverTitle,
          message: AppErrorMessage.serverBody,
          onRetry: _updateUserProfile,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await ErrorPopup.show(
        context,
        title: AppErrorMessage.titleFor(e),
        message: AppErrorMessage.bodyFor(e),
        onRetry: _updateUserProfile,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // -----------------------------------------------------
  // LOGOUT
  // -----------------------------------------------------
  Future<void> _logout() async {
    // Session teardown (prefs + Google + Firebase) lives in one place; this
    // also unwinds the stack so no protected screen survives the logout.
    await signOutToLogin(context);
  }

  void _showSnackBar(String msg) {
    if (mounted) AppSnackbar.info(context, msg);
  }

  // -----------------------------------------------------
  // FULL PROFESSIONAL UI
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Let the scroll view handle the keyboard rather than resizing the stack.
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Brand wash behind the header (existing gradient colors).
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.rose, AppColors.lightPink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      // AUDIT FIX (authentication bypass + wrong back
                      // behaviour): Back used to `pushAndRemoveUntil(…,
                      // (route) => false)` onto a *fresh* WeddingHomePage,
                      // which destroyed `AuthGate` (the root route) and left a
                      // home page outside the session gate — after that,
                      // logging out could not return the user to the login
                      // screen. Profile is always pushed on top of the
                      // dashboard, so popping is both correct and safe.
                      AppBackButton(
                        color: AppColors.textOnPrimary,
                        background: Colors.white.withValues(alpha: 0.25),
                        onTap: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Profile',
                          textAlign: TextAlign.center,
                          style: AppText.pageTitle.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl +
                          MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        // PROFILE CARD
                        FadeSlideIn(
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Row(
                              children: [
                                AppAvatar(
                                  url: userPhoto,
                                  name: userName,
                                  size: 78,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        userName.isNotEmpty
                                            ? userName
                                            : 'Your Name',
                                        style: AppText.sectionTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        userEmail.isNotEmpty
                                            ? userEmail
                                            : 'example@mail.com',
                                        style: AppText.cardSubtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // WEDDING DETAILS
                        FadeSlideIn(
                          delay: AppMotion.stagger,
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Wedding details',
                                  style: AppText.sectionTitle,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                AppTextField(
                                  label: 'Mobile Number',
                                  hint: '10-digit mobile number',
                                  controller: mobileController,
                                  prefixIcon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  errorText: mobileError,
                                  required: true,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                AppTextField(
                                  label: 'Wedding Venue (City)',
                                  hint: 'Select a city',
                                  controller: weddingVenueController,
                                  prefixIcon: Icons.location_on_outlined,
                                  suffixIcon: Icons.search_rounded,
                                  readOnly: true,
                                  onTap: _showCityPicker,
                                  onSuffixTap: _showCityPicker,
                                  errorText: venueError,
                                  required: true,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                AppTextField(
                                  label: 'Wedding Date',
                                  hint: 'Pick your date',
                                  controller: weddingDateController,
                                  prefixIcon: Icons.calendar_today_outlined,
                                  suffixIcon: Icons.edit_calendar_outlined,
                                  readOnly: true,
                                  onTap: _pickWeddingDate,
                                  onSuffixTap: _pickWeddingDate,
                                  errorText: weddingDateError,
                                  required: true,
                                ),

                                const SizedBox(height: AppSpacing.xxl),

                                PremiumButton(
                                  label: 'Save Changes',
                                  icon: Icons.check_rounded,
                                  isLoading: _isSaving,
                                  onPressed: _updateUserProfile,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // LOGOUT
                        FadeSlideIn(
                          delay: AppMotion.stagger * 2,
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            onTap: _confirmLogout,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.lg,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.error.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.error,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      'Logout',
                                      style: AppText.bodyStrong.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textTertiary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Asks before signing out, then runs the unchanged [_logout] flow.
  Future<void> _confirmLogout() async {
    final confirmed = await ConfirmPopup.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your bookings.',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
      danger: true,
    );
    if (confirmed) await _logout();
  }
}


class _CitySearchDelegate extends SearchDelegate<String> {
  final List<String> cities;
  _CitySearchDelegate(this.cities);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    final results = cities
        .where((city) => city.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(results[i]),
        onTap: () => close(context, results[i]),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
