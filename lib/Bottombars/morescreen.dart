import 'package:flutter/material.dart';

import '../core/core.dart';
import '../honeymoon/ui/honeymoon_home_page.dart';
import 'package:happy_wedz/guestlist/guestlist.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../InboxScreen.dart';
import '../RealWedding/share_ur_story.dart';
import '../Wishlist/Wishlistscreen.dart';

import '../budget/budget.dart';
import '../einvite1/einvite.dart';
import '../ideas.dart';
import '../main.dart';
import '../movment_plus/bottom_nav_bar.dart';
import '../my_bookings/my_bookings.dart';
import '../packages.dart';
import '../planning.dart';

class MoreOptionsScreen extends StatefulWidget {
  const MoreOptionsScreen({super.key});

  @override
  State<MoreOptionsScreen> createState() => _MoreOptionsScreenState();
}

class _MoreOptionsScreenState extends State<MoreOptionsScreen> {
  // AUDIT NOTE:
  // `isLoading` was never read or written — this screen is a static menu with
  // nothing to load. Kept intentionally and commented out as requested.
  // Do not remove without confirming with the project owner.
  // bool isLoading = true;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
               _buildAppBar(context),
              // Menu Items
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 30, bottom: 20),
                    children: [
                      _buildMenuItem(
                        icon: Icons.card_travel_rounded,
                        title: 'Honeymoon',
                        onTap: () => _handleMenuTap(context, 'Honeymoon'),
                      ),
                      _buildMenuItem(
                        icon: Icons.shopping_bag,
                        title: 'Budget',
                        onTap: () => _handleMenuTap(context, 'Budget'),
                      ),
                      _buildMenuItem(
                        icon: Icons.shopping_bag,
                        title: 'Movment Plus',
                        onTap: () => _handleMenuTap(context, 'Movment Plus'),
                      ),
                      _buildMenuItem(
                        icon: Icons.mail_outline,
                        title: 'E-Invites',
                        onTap: () => _handleMenuTap(context, 'E-Invites'),
                      ),
                      _buildMenuItem(
                        icon: Icons.person,
                        title: 'Guestlist',
                        onTap: () => _handleMenuTap(context, 'Guestlist')
                      ),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'Ideas',
                        onTap: () => _handleMenuTap(context, 'Ideas'),
                      ),
                      _buildMenuItem(
                        icon: Icons.favorite,
                        title: 'Wishlist',
                        onTap: () => _handleMenuTap(context, 'Wishlist'),
                      ),
                      // _buildMenuItem(
                      //   icon: Icons.favorite,
                      //   title: 'Real Wedding',
                      //   onTap: () => _handleMenuTap(context, 'Real Wedding'),
                      // ),
                      _buildMenuItem(
                        icon: Icons.inbox,
                        title: 'Inbox',
                        onTap: () => _handleMenuTap(context, 'Inbox'),
                      ),
                      _buildMenuItem(
                        icon: Icons.rate_review_outlined,
                        title: 'My Bookings',
                        onTap: () => _handleMenuTap(context, 'My Bookings'),
                      ),
                      // _buildMenuItem(
                      //   icon: Icons.rate_review_outlined,
                      //   title: 'Planning',
                      //   onTap: () => _handleMenuTap(context, 'Planning'),
                      // ),
                      // _buildMenuItem(
                      //   icon: Icons.rate_review_outlined,
                      //   title: 'Packages',
                      //   onTap: () => _handleMenuTap(context, 'Packages'),
                      // ),
                      // _buildMenuItem(
                      //   icon: Icons.rate_review_outlined,
                      //   title: 'Rate on Play Store',
                      //   onTap: () => _handleMenuTap(context, 'Rate on Play Store'),
                      // ),
                      // _buildMenuItem(
                      //   icon: Icons.help_outline,
                      //   title: 'Help & Support',
                      //   onTap: () => _handleMenuTap(context, 'Help & Support'),
                      // ),
                      _buildMenuItem(
                        icon: Icons.share,
                        title: 'Share App',
                        onTap: () => _handleMenuTap(context, 'Share App'),
                      ),


                      _buildMenuItem(
                        icon: Icons.logout,
                        title: 'Log out',
                        onTap: _handleLogout,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              // floating AI button (unchanged)

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // GestureDetector(
          //   onTap: () => Navigator.pop(context),
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: Colors.white.withValues(alpha: 0.2),
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //     child: const Icon(
          //       Icons.arrow_back_ios,
          //       color: Colors.white,
          //       size: 18,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 15),
          // const Text(
          //   'Nashik',
          //   style: TextStyle(
          //     color: Colors.white,
          //     fontSize: 16,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          // const Spacer(),
          Text(
            'More Options',
            style: AppText.pageTitle.copyWith(color: AppColors.textOnPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return AppCard(
      onTap: onTap,
      margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: AppColors.hotPink.withValues(alpha: 0.10),
              borderRadius: AppRadii.rMd,
            ),
            child: Icon(icon, color: AppColors.hotPink, size: 21),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(title, style: AppText.bodyLg)),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String menuTitle) async {
    switch (menuTitle) {
      case 'Honeymoon':
        Navigator.push(
          context,
          AnimatedPageRoute(
            page: const HoneymoonHomePage(),
            style: PageTransitionStyle.slideRight,
          ),
        );
        break;
      case 'Movment Plus':
        Navigator.push(context, MaterialPageRoute(builder: (_) => CustomBottomBar()));
        break;
      case 'E-Invites':
        Navigator.push(context, MaterialPageRoute(builder: (_) => EInvitationScreen()));
        break;
        case 'Budget':
        Navigator.push(context, MaterialPageRoute(builder: (_) => BudgetPage()));
        break;
        case 'Ideas':
        Navigator.push(context, MaterialPageRoute(builder: (_) => Ideas()));
        break;
        case 'My Bookings':
          Navigator.push(context, MaterialPageRoute(builder: (_) => MyBookingsScreen()));
        break;
        case 'Packages':
        Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesScreen()));
        break;
      case 'Inbox':
        Navigator.push(context, MaterialPageRoute(builder: (_) => Inboxscreen()));
        break;
      case 'Guestlist':
        Navigator.push(context, MaterialPageRoute(builder: (_) => GuestListDashboard()));
        break;

      case 'Planning':
        Navigator.push(context, MaterialPageRoute(builder: (_) => WeddingPlanningScreen()));
        break;
      case 'Wishlist':
        Navigator.push(context, MaterialPageRoute(builder: (_) => FavouritesPage()));
      break;
      // case 'Write a Review':
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (_) => RecommendVendorScreen(vendorId: 75077.toString())),
      //   );
      //   break;



      case 'Real Wedding':
        final loggedIn = await ensureLoggedIn(context);
        if (!loggedIn) return; // 🚫 not logged in → go to SignInScreen

        // AUDIT FIX (async context): `context` was used to push after an await
        // with no re-check, so a user who left this tab mid-check pushed onto a
        // dead element.
        if (!mounted) return;
        Navigator.push(
          this.context,
          MaterialPageRoute(builder: (_) => ShareWeddingStory()),
        );
        break;

      case 'Share App':
        _shareApp();
        break;


      case 'Rate on Play Store':
        final rate = await ConfirmPopup.show(
          context,
          title: 'Rate HappyWedz',
          message: 'Would you like to rate this app on the Play Store?',
          confirmLabel: 'Rate Now',
          icon: Icons.star_rounded,
        );
        if (rate) _openPlayStore();
        break;



    // case 'Matrimony':
      //   Navigator.push(context, MaterialPageRoute(builder: (_) => MatrimonyScreen()));
      //   break;
      // // Add more cases...
    }
  }

  /// AUDIT FIX: both actions below shipped with the template placeholder
  /// `com.yourcompany.yourapp`, so "Share App" sent friends a Play Store link
  /// to a listing that does not exist and "Rate on Play Store" opened the same
  /// dead page. This is the real application id — it matches
  /// `applicationId = "com.happy.happy_wedz"` in android/app/build.gradle.kts.
  static const String _packageName = 'com.happy.happy_wedz';

  static Uri get _playStoreUri => Uri.parse(
        'https://play.google.com/store/apps/details?id=$_packageName',
      );

  Future<void> _openPlayStore() async {
    // Prefer the Play Store app, fall back to the web listing — the same
    // pattern the sign-in screen uses for the vendor app.
    final market = Uri.parse('market://details?id=$_packageName');
    try {
      if (await canLaunchUrl(market) &&
          await launchUrl(market, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (await launchUrl(_playStoreUri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (e) {
      debugPrint('Could not open the Play Store listing: $e');
    }
    if (mounted) AppSnackbar.error(context, 'Could not open the Play Store.');
  }

  void _shareApp() {
    // AUDIT FIX (deprecation): `Share.share` is deprecated in share_plus 12.
    SharePlus.instance.share(
      ShareParams(
        text: "Hey! Check out this amazing app: $_playStoreUri",
        subject: "HappyWedz App",
      ),
    );
  }

  // AUDIT FIX (async context): this took a `BuildContext` parameter that
  // shadowed `State.context`, so the `mounted` check below could not be tied to
  // it and the awaits were crossed with an unverified context. Using the
  // State's own context makes each `mounted` guard meaningful.
  Future<void> _handleLogout() async {
    final confirmed = await ConfirmPopup.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your bookings.',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
      danger: true,
    );
    if (!confirmed || !mounted) return;

    // Clears the stored session and the Google/Firebase providers, then
    // unwinds the stack so AuthGate can show the login screen.
    await signOutToLogin(context);

    if (!mounted) return;
    AppSnackbar.success(context, 'You have been logged out.');
  }
}