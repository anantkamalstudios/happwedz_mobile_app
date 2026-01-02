import 'package:flutter/material.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
          Center(
            child: const Text(
              'More Options',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
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
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 15),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF69B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFFF69B4),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFBBBBBB),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, String menuTitle) async {
    switch (menuTitle) {
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Rate App"),
            content: const Text("Do you want to rate this app on the Play Store?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openPlayStore();
                },
                child: const Text("Rate Now"),
              ),
            ],
          ),
        );
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                SharedPreferences prefs = await SharedPreferences.getInstance();

                // 🔥 Clear only auth-related keys (safer)
                await prefs.remove('user_id');
                await prefs.remove('user_name');
                await prefs.remove('user_email');
                await prefs.remove('user_phone');
                await prefs.remove('auth_token');
                await prefs.remove('user_photo');

                // Google logout
                await GoogleSignIn().signOut();

                // Navigate to login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                      (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Color(0xFFFF69B4),
                  ),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}