import 'package:flutter/material.dart';

import '../core/core.dart';
import 'package:happy_wedz/guestlist/guestlist.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../InboxScreen.dart';
import '../RealWedding/share_ur_story.dart';
import '../Review.dart';
import '../Wishlist/Wishlistscreen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai_chat_screen/ai_chat_screen.dart';
import '../budget/budget.dart';
import '../einvite/einvite.dart';
import '../einvite1/einvite.dart';
import '../einvite1/template_listscreen.dart';
import '../ideas.dart';
import '../login.dart';
import '../main.dart';
import '../movment_plus/bottom_nav_bar.dart';
import '../movment_plus/movment_plus_dashboard.dart';
import '../my_bookings/my_bookings.dart';
import '../packages.dart';
import '../planning.dart';
import '../shop.dart';

class MoreOptionsScreen extends StatefulWidget {
  const MoreOptionsScreen({super.key});

  @override
  State<MoreOptionsScreen> createState() => _MoreOptionsScreenState();
}

class _MoreOptionsScreenState extends State<MoreOptionsScreen> {
  bool isLoading = true;


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
                        onTap: () => _handleLogout(context),
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
          //       color: Colors.white.withOpacity(0.2),
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

        Navigator.push(
          context,
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

  void _openPlayStore() async {
    const packageName = "com.yourcompany.yourapp"; // <-- Replace with your app's package name
    final url = Uri.parse("https://play.google.com/store/apps/details?id=$packageName");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print("Could not launch Play Store URL");
    }
  }

  void _shareApp() {
    const packageName = "com.yourcompany.yourapp"; // <-- Replace with your app's package name
    final appUrl = "https://play.google.com/store/apps/details?id=$packageName";

    Share.share(
      "Hey! Check out this amazing app: $appUrl",
      subject: "HappyWedz App",
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmPopup.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your bookings.',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
      danger: true,
    );
    if (!confirmed) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clear only auth-related keys (safer)
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('auth_token');
    await prefs.remove('user_photo');

    // Google logout
    await GoogleSignIn().signOut();

    if (!mounted) return;

    // Navigate to login screen
    Navigator.pushAndRemoveUntil(
      context,
      AnimatedPageRoute(
        page: const SignInScreen(),
        style: PageTransitionStyle.fade,
      ),
      (route) => false,
    );

    AppSnackbar.success(context, 'You have been logged out.');
  }
}