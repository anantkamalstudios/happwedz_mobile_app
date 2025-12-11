
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/login.dart';
import 'package:happy_wedz/packages.dart';
import 'package:happy_wedz/shop.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../DecorationScreen.dart';
import '../LoadingLogo.dart';
import '../WedChecklist/ChecklistScreen.dart';
import '../Wishlist/Wishlistscreen.dart';
import '../ai_chat_screen/ai_chat_screen.dart';
import '../designstudio.dart';
import '../einvite1/einvite.dart';
import '../favscreen.dart';
import '../fetch_location.dart';
import '../ideas.dart';
import '../main.dart';
import '../mkp.dart';
import '../profile.dart';
import '../vendor/makeup.dart';
import '../vendor/photographer.dart';
import '../vendor/vendordetailsscreen.dart';
import '../venuedetails.dart';
import 'GenieScreen.dart';
import 'Vendor.dart';
import 'VenuesScreen.dart';
import 'VirtualStudio.dart';
import 'designstudio1.dart';
import 'morescreen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCity = "Nashik"; // default city

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  // ---- Data (provided by you) ----
  final List<Map<String, String>> categories = [
    {
      'label': 'Wedding Planners',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bEllipse%202.png?alt=media&token=126f43e7-fd80-4323-8f94-13f102b01688'
    },
    {
      'label': 'Photographer',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cEllipse%203.png?alt=media&token=50dae8bf-2c7d-4b69-a847-a88432b235b6'
    },
    {
      'label': 'Venues',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F138e7fc800113229c148bb8e1c42d934b661828bEllipse%204.png?alt=media&token=cdb01134-472d-448c-8530-ae7557a78233'
    },
    {
      'label': 'Bridal makeup',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Ellipse%205.png?alt=media&token=5c7554ea-e064-4a0e-9fac-9fe9a779da08'
    },
    {
      'label': 'All Categories',
      'image':
      'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F74d0bec9-682b-4ea0-8c61-f23d309a3de7.png'
    },
  ];

  final List<Map<String, String>> venueCards = [
    {
      'title': 'Fort Jadhavgadh, Pune',
      'sub': 'Saswad',
      'price': '₹ 2,899 per plate',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=e95fe0b1-9f12-41d3-b034-384776687509'
    },
    {
      'title': 'Gharkul Lawns',
      'sub': 'Erandwane',
      'price': '₹ 899 per plate',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F0601b946dc3b99b0aa992f4edf934ffc69ee254cRectangle%20266.png?alt=media&token=489fdb30-84e0-4f11-9a27-629eb6f5c2cc'
    },
  ];

  final List<Map<String, String>> photographerCards = [
    {
      'title': 'Fearless Pheras',
      'sub': 'Pune',
      'price': '₹ 55,000 per Day',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=b58eea4b-0ec1-4562-bdce-af7fd3a2dc96'
    },
    {
      'title': 'Firefly Photography',
      'sub': 'Pune',
      'price': '₹ 55,000 per Day',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F0601b946dc3b99b0aa992f4edf934ffc69ee254cRectangle%20266.png?alt=media&token=28367d39-ef9a-4d56-ada5-d49683b3d515'
    },
  ];

  final List<Map<String, String>> trendingCards = [
    {
      'title': 'Bridal busy we’re crushing on! outfits',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F34ea5a1fe5bd5adb6c68ba2f0e1fa6bcc8470ba0Rectangle%20268.png?alt=media&token=847a1794-95a5-4fb4-961d-e2642efc2a63'
    },
    {
      'title': 'A Beachside Wedding Dipped In Pastels',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=bd975947-2c06-40c6-8c0b-11482c43b783'
    },
  ];

  final List<Map<String, String>> readCards = [
    {
      'title': 'Bridal busy we’re crushing on! outfits & Accessories',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F34ea5a1fe5bd5adb6c68ba2f0e1fa6bcc8470ba0Rectangle%20266.png?alt=media&token=bd975947-2c06-40c6-8c0b-11482c43b783'
    },
    {
      'title':
      'A Beachside Wedding Dipped In Pastels, Sunshine & A Decade Of Love',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=cb4544a5-d80b-4d6b-807f-20024e958026'
    },
  ];
  final List<Map<String, String>> _navItems = [
    {"label": "Home", "icon": "assets/icons/home.png"},
    {"label": "Vendors", "icon": "assets/icons/vendor.png"},
    {"label": "Inspiration", "icon": "assets/icons/inspiration.png"},
    {"label": "Shop", "icon": "assets/icons/shop.png"},
    {"label": "Profile", "icon": "assets/icons/profile.png"},
  ];
  // ---- Helpers ----

  // clamp double between min and max (simple utility)
  double clampDouble(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  // Build circular category item (image + label)
  Widget buildCategoryItem(double circleSize, Map<String, String> item) {
    return SizedBox(
      width: circleSize + 20,
      child: Column(
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2, color: const Color(0xFFFBAA47)),
              image: DecorationImage(
                image: NetworkImage(item['image']!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              item['label'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  // Generic horizontal card used for venues / trending / photographer
  Widget buildCardItemHorizontal(
      Map<String, String> card,
      double cardWidth, {
        double? cardHeightOverride,
      }) {
    final double cardHeight = cardHeightOverride ?? 220;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0x11E83580)),
          boxShadow: const [
            BoxShadow(color: Color(0x3F000000), offset: Offset(0, 4), blurRadius: 4),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  card['image'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['title'] ?? '',
                    style: GoogleFonts.getFont(
                      'Poltawski Nowy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card['sub'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card['price'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _smallToolCard({
    required String title,
    required String subtitle,
    required String image,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x11E83580)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // 🔹 Main content
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 56, height: 56, child: Image.asset(image)),
              const SizedBox(height: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // 🔹 Arrow in top-right corner
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }


  Widget _readCardHorizontal({
    required String title,
    required String image,
    required double width,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), offset: Offset(0, 4), blurRadius: 4)
        ],
        color: Colors.white,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            child: Image.network(image, width: width * 0.36, height: 100, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(title,
                  style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          )
        ],
      ),
    );
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final circleSize = clampDouble(width * 0.14, 50, 80);
    final height = MediaQuery.of(context).size.height;
    final trendingCardW = clampDouble(width * 0.72, 200, 380);
    final readCardW = clampDouble(width * 0.72, 220, 380);
    final double screenWidth = width;
    final double smallCardW = (screenWidth * 0.62).clamp(180.0, 260.0);
    const double cardH = 220;

    return Scaffold(
      appBar: AppBar(
        title: Text('HappyWeds', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFE83580),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category horizontal list (circular images)
              SizedBox(
                height: circleSize + 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      buildCategoryItem(circleSize, categories[index]),
                ),
              ),
              const SizedBox(height: 16),

              // Tools section
              Text('Wedding Planning tools',
                  style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _smallToolCard(
                      title: 'Build your Digital E-invites',
                      subtitle: 'Let’s get started',
                      image:'assets/tool1.png',
                      // 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F0a9710d1-dcde-45a6-8b5e-35c944279b1f.png',
                      width: 140,
                    ),
                    const SizedBox(width: 12),
                    _smallToolCard(
                      title: 'Your shortlisted vendor',
                      subtitle: 'Browse vendors',
                      image:'assets/tool2.png',
                      // 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2Fa10c8360-0438-45ee-914b-52837cb3d480.png',
                      width: 140,
                    ),
                    const SizedBox(width: 12),
                    _smallToolCard(
                      title: 'Your Favourite ideas',
                      subtitle: 'Add a favourite',
                      image:'assets/tool3.png',
                      // 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F57c23620-f845-42ed-9092-416ab6f7859d.png',
                      width: 140,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Venues heading and 'View all' button
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Venues in your city',
                    style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                TextButton(
                  onPressed: () {

                  },
                  child: Text('View all',
                      style: GoogleFonts.inter(color: const Color(0xFFA60F93))),
                )
              ]),
              const SizedBox(height: 8),

              // Venues horizontal cards
              SizedBox(
                height: cardH,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: venueCards.length,
                  itemBuilder: (context, i) => buildCardItemHorizontal(
                    venueCards[i],
                    smallCardW,
                    cardHeightOverride: cardH,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Photographer section
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Photographer for you',
                    style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                TextButton(
                  onPressed: () {
                    // TODO: navigate
                  },
                  child: Text('View all',
                      style: GoogleFonts.inter(color: const Color(0xFFA60F93))),
                )
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: smallCardW * 0.9,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photographerCards.length,
                  itemBuilder: (context, i) =>
                      buildCardItemHorizontal(photographerCards[i], smallCardW),
                ),
              ),
              const SizedBox(height: 18),
// 🔹 Wrap in a Stack so white card overlaps pink card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient progress panel (Tasks)
                  Container(
                    width: double.infinity,
                    height: height * 0.20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFd8366f), Color(0xFFf97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "0/73",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.07,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Task done",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "0%",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upcoming tasks white card (overlapping bottom)
                  Positioned(
                    bottom: -80, // 🔹 adjust overlap
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Upcoming tasks",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Icon(Icons.circle, size: 12, color: Colors.pink),
                              SizedBox(width: 10),
                              Text(
                                "Browse and save outfit photos",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 10),
                              const Text(
                                "Research venue options",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),



              const SizedBox(height: 18),

              // Trending Today
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Trending Today',
                    style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                Text('#ivory-lehenga',
                    style: GoogleFonts.getFont('Poltawski Nowy',
                        color: const Color(0xFFE83580))),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: trendingCardW * 0.9,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: trendingCards.length,
                  itemBuilder: (context, i) =>
                      buildCardItemHorizontal(trendingCards[i], trendingCardW),
                ),
              ),
              const SizedBox(height: 18),

              // Promo image w/ text overlay
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Rectangle%20269.png?alt=media&token=ab82efe7-34cd-404b-9da2-01515f372f47'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HappyWeds Services',
                            style: GoogleFonts.getFont('Poltawski Nowy',
                                color: Colors.white, fontSize: 16)),
                        Text('plan your dream wedding in your budget',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      ]),
                ),
              ),
              const SizedBox(height: 18),

              // Two-column ideas section
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F1056d056a37e91a97da6758a70e2dada5d0a4f38Rectangle%20266.png?alt=media&token=36044e03-5eab-492d-8ed5-0e1fbf35dfd0',
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Wedding ideas',
                        style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Wedding day bridal portrait',
                        style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Romantic couple shot',
                        style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14)),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),

              // Interesting reads horizontal cards
              Text('Interesting reads', style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: readCards.length,
                  itemBuilder: (context, i) => _readCardHorizontal(
                      title: readCards[i]['title']!, image: readCards[i]['image']!, width: readCardW),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // ---- Bottom Navigation Bar (custom styled to match design) ----
      bottomNavigationBar: Container(
        height: 83,
        decoration: const BoxDecoration(
          color: Color(0xFFE83580),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 0)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/homeicon.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 0 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Home',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 0 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Venues
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const VenuesScreen()),
                    // );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 1)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/venue.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 1 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Venues',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 1 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer for FAB
                const SizedBox(width: 56),

                // Vendors
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const VendorsScreen()),
                    // );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 2)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/vendor.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 2 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vendors',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 2 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 2
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // More
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const MoreScreen()),
                    // );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 3)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/menuicon.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 3 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'More',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 3 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 3
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Center floating avatar
            Positioned(
              top: -18,
              left: MediaQuery.of(context).size.width / 2 - 28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/virtualstudio.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(width: 4, color: Color(0xFFE83580)),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}












































class WeddingHomePage extends StatefulWidget {
  const WeddingHomePage({super.key});

  @override
  State<WeddingHomePage> createState() => _WeddingHomePageState();
}

class _WeddingHomePageState extends State<WeddingHomePage> {
  int _selectedIndex = 0;

  // global loading overlay toggled while initial data loads
  bool isLoading = true;

  // search / location
  bool _showSearch = false;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // city loader
  bool _isLoadingCities = false;
  List<String> _cities = [];

  // horizontal categories
  List<VendorCategory> horizontalCategories = [];
  bool isLoadingCategories = true;

  // venues & photographers (raw responses)
  List<dynamic> venues = [];
  List<dynamic> photographers = [];
  bool isLoadingVenues = true;
  bool isLoadingPhotographers = true;

  // real weddings & blogs
  List<dynamic> realWeddings = [];
  List<dynamic> blogPosts = [];
  bool isLoadingRealWeddings = true;
  bool isLoadingBlogPosts = true;

  // ✅ Checklist State Variables
  int completedCount = 0;
  int totalTasks = 0;
  List<String> upcomingTasks = [];
  DateTime? weddingDate;
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    loadStories();

  }
  Future<void> loadStories() async {
    final data = await fetchStories();

    setState(() {
      blogPosts = data;
      isLoadingBlogPosts = false;
    });
  }

  // ---- Data (provided by you) ----
  final List<Map<String, String>> categories = [
    {
      'label': 'Wedding Planners',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bEllipse%202.png?alt=media&token=126f43e7-fd80-4323-8f94-13f102b01688'
    },
    {
      'label': 'Photographer',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cEllipse%203.png?alt=media&token=50dae8bf-2c7d-4b69-a847-a88432b235b6'
    },
    {
      'label': 'Venues',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F138e7fc800113229c148bb8e1c42d934b661828bEllipse%204.png?alt=media&token=cdb01134-472d-448c-8530-ae7557a78233'
    },
    {
      'label': 'Bridal makeup',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Ellipse%205.png?alt=media&token=5c7554ea-e064-4a0e-9fac-9fe9a779da08'
    },
    {
      'label': 'All Categories',
      'image':
      'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F74d0bec9-682b-4ea0-8c61-f23d309a3de7.png'
    },
  ];
  // -------- INITIAL LOADING --------
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);

    // run in parallel and wait
    await Future.wait([
      fetchHorizontalCategories(),
      fetchVenues(), // no city -> default limited load for home
      fetchPhotographers(),
      fetchRealWeddings(),

    ]).catchError((e) {
      // individual fetches handle their own errors; this is fallback
      debugPrint('Initial load error: $e');
    });

    setState(() => isLoading = false);
  }

  // -------- CITIES (for selection) --------
  Future<void> _loadCities() async {
    setState(() => _isLoadingCities = true);

    try {
      final response = await http.get(Uri.parse(
          'https://countriesnow.space/api/v0.1/countries/state/cities/q?country=India&state=Maharashtra'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['data'] != null) {
          final List<String> loaded =
          List<String>.from(data['data'].map((e) => e.toString()));
          loaded.sort();
          setState(() {
            _cities = loaded;
            _isLoadingCities = false;
          });
          return;
        }
      }

      // fallback if anything wrong
      setState(() {
        _cities = ['No cities available'];
        _isLoadingCities = false;
      });
    } catch (e) {
      debugPrint('Error loading cities: $e');
      setState(() {
        _cities = ['Error loading cities'];
        _isLoadingCities = false;
      });
    }
  }

// ---------- BLOG CATEGORIES ----------
  List<dynamic> blogCategories = [];
  bool isLoadingBlogCategories = true;
  // Future<List<Map<String, dynamic>>> fetchStories() async {
  //   final response = await http.get(Uri.parse('https://happywedz.com/api/blog-categories/all'));
  // print(response);
  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> decodedJson = json.decode(response.body);
  //     final List<dynamic> dataList = decodedJson['data'];
  //     return dataList.cast<Map<String, dynamic>>().toList();
  //   } else {
  //     throw Exception('Failed to load stories');
  //   }
  //
  // }
  Future<List<Map<String, dynamic>>> fetchStories() async {
    try {
      final response = await http.get(
        Uri.parse('https://happywedz.com/api/blogs/all'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final List<dynamic> dataList = decoded['data'] ?? [];

        return dataList.map((item) {
          return {
            'title': item['title'] ?? 'No Title',
            'shortDescription': item['shortDescription'] ?? '',
            'image': item['image']?.toString() ?? '',
            'author': item['author'] ?? '',
            'date': item['postDate'] ?? '',
          };
        }).toList();
      } else {
        throw Exception('Failed to load stories');
      }
    } catch (e) {
      print("fetchBlogPosts error: $e");
      return [];
    }
  }

  // Future<void> fetchBlogCategories() async {
  //   setState(() => isLoadingBlogCategories = true);
  //
  //   try {
  //     final response = await http.get(
  //       Uri.parse("https://happywedz.com/api/blog-categories/all"),
  //       headers: {"Accept": "application/json"},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final decoded = json.decode(response.body);
  //
  //       final List<dynamic> data =
  //       decoded is Map && decoded['data'] is List
  //           ? decoded['data'] as List<dynamic>
  //           : [];
  //
  //       setState(() {
  //         blogCategories = data;
  //         isLoadingBlogCategories = false;
  //       });
  //     } else {
  //       setState(() => isLoadingBlogCategories = false);
  //     }
  //   } catch (e) {
  //     debugPrint("Blog Categories Error: $e");
  //     setState(() => isLoadingBlogCategories = false);
  //   }
  // }

  void _showLocationSelection(BuildContext context) async {
    if (_cities.isEmpty && !_isLoadingCities) {
      await _loadCities();
    }

    if (_cities.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No cities available.")));
      return;
    }

    final selected = await showSearch<String>(
      context: context,
      delegate: _CitySearchDelegate(_cities),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _selectedCity = selected;
      });

      // Fetch filtered venues and photographers — when city selected we request more items (to get "all" for that city)
      await Future.wait([
        fetchVenues(city: _selectedCity, limitWhenCity: 1000),
        fetchPhotographers(city: _selectedCity, limitWhenCity: 1000),
      ]);
    }
  }

  // -------- HORIZONTAL CATEGORIES --------
  Future<void> fetchHorizontalCategories() async {
    setState(() => isLoadingCategories = true);
    try {
      final response = await http.get(
        Uri.parse("https://happywedz.com/api/vendor-types/with-subcategories/all"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          horizontalCategories =
              data.map((e) => VendorCategory.fromJson(e)).toList();
          isLoadingCategories = false;
        });
      } else {
        setState(() => isLoadingCategories = false);
        debugPrint("Error fetching categories: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoadingCategories = false);
      debugPrint("API Error (categories): $e");
    }
  }

  // -------- VENUES & PHOTOGRAPHERS --------
  // Behavior:
  // - if city provided we include &city=... and set limit to `limitWhenCity` (default large)
  // - if no city provided we include &limit=limit (small default for homepage)
  Future<void> fetchVenues({String? city, int limit = 20, int limitWhenCity = 1000}) async {
    setState(() => isLoadingVenues = true);

    try {
      final effectiveLimit = city != null && city.isNotEmpty ? limitWhenCity : limit;
      final sb = StringBuffer('https://happywedz.com/api/vendor-services?subCategory=venue');
      sb.write('&limit=$effectiveLimit');
      if (city != null && city.isNotEmpty) {
        sb.write('&city=${Uri.encodeComponent(city)}');
      }

      final url = Uri.parse(sb.toString());
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // API shape might vary; try to get data reliably
        final data = (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List<dynamic>
            : (decoded is List ? decoded : []);

        setState(() {
          venues = data;
          isLoadingVenues = false;
        });
      } else {
        debugPrint('fetchVenues error: ${response.statusCode}');
        setState(() => isLoadingVenues = false);
      }
    } catch (e) {
      debugPrint('fetchVenues exception: $e');
      setState(() => isLoadingVenues = false);
    }
  }

  Future<void> fetchPhotographers({String? city, int limit = 20, int limitWhenCity = 1000}) async {
    setState(() => isLoadingPhotographers = true);

    try {
      final effectiveLimit = city != null && city.isNotEmpty ? limitWhenCity : limit;
      final sb = StringBuffer('https://happywedz.com/api/vendor-services?subCategory=photographer');
      sb.write('&limit=$effectiveLimit');
      if (city != null && city.isNotEmpty) {
        sb.write('&city=${Uri.encodeComponent(city)}');
      }

      final url = Uri.parse(sb.toString());
      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = (decoded is Map && decoded['data'] is List)
            ? decoded['data'] as List<dynamic>
            : (decoded is List ? decoded : []);

        setState(() {
          photographers = data;
          isLoadingPhotographers = false;
        });
      } else {
        debugPrint('fetchPhotographers error: ${response.statusCode}');
        setState(() => isLoadingPhotographers = false);
      }
    } catch (e) {
      debugPrint('fetchPhotographers exception: $e');
      setState(() => isLoadingPhotographers = false);
    }
  }

  // -------- REAL WEDDINGS & BLOGS --------
  Future<void> fetchRealWeddings() async {
    setState(() => isLoadingRealWeddings = true);
    try {
      final response = await http.get(Uri.parse("https://happywedz.com/api/realwedding/public"));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          realWeddings = decoded['weddings'] ?? [];
          isLoadingRealWeddings = false;
        });
      } else {
        debugPrint('fetchRealWeddings error: ${response.statusCode}');
        setState(() => isLoadingRealWeddings = false);
      }
    } catch (e) {
      debugPrint('fetchRealWeddings exception: $e');
      setState(() => isLoadingRealWeddings = false);
    }
  }

  // Future<void> fetchBlogPosts() async {
  //   setState(() => isLoadingBlogPosts = true);
  //   try {
  //     final response = await http.get(Uri.parse("https://happywedz.com/api/blog-deatils/all"));
  //     if (response.statusCode == 200) {
  //       final decoded = json.decode(response.body);
  //       // check shape — some APIs return {data: [...] } else root list
  //       final List<dynamic> data = decoded is Map && decoded['data'] is List
  //           ? decoded['data'] as List<dynamic>
  //           : (decoded is List ? decoded : []);
  //       setState(() {
  //         blogPosts = data;
  //         isLoadingBlogPosts = false;
  //       });
  //     } else {
  //       debugPrint('fetchBlogPosts error: ${response.statusCode}');
  //       setState(() => isLoadingBlogPosts = false);
  //     }
  //   } catch (e) {
  //     debugPrint('fetchBlogPosts exception: $e');
  //     setState(() => isLoadingBlogPosts = false);
  //   }
  // }
  Future<bool> checkUserHasFavourites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    if (token.isEmpty) return false;

    final url = Uri.parse('https://happywedz.com/api/wishlist');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['data'] ?? [];
        return items.isNotEmpty;
      }
    } catch (e) {
      debugPrint("Error checking favourites: $e");
    }

    return false;
  }

  // -------- UI BUILD --------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // background + main content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
                stops: [0.0, 0.3, 0.6],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildCategorySection(),
                          const SizedBox(height: 10),
                          _buildPlanningToolsSection(),
                          const SizedBox(height: 30),
                          _buildVenuesSection(),
                          const SizedBox(height: 20),
                          _buildViewAllVenuesButton(context),
                          const SizedBox(height: 30),
                          _buildPhotographerSection(),
                          const SizedBox(height: 20),
                          _buildViewAllPhotographersButton(),
                          const SizedBox(height: 30),
                          _buildWeddingChecklistSection(
                            completedCount: completedCount,
                            totalTasks: totalTasks,
                            upcomingTasks: upcomingTasks,
                            onTap: () {
                              Navigator.of(context).push(PageRouteBuilder(
                                transitionDuration: const Duration(milliseconds: 600),
                                pageBuilder: (_, __, ___) => const WeddingTimelinePage(),
                                transitionsBuilder: (_, animation, __, child) {
                                  final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
                                  return FadeTransition(
                                    opacity: curved,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(curved),
                                      child: child,
                                    ),
                                  );
                                },
                              ));
                            },
                          ),
                          // const SizedBox(height: 30),
                          // _buildTrendingTodaySection(),
                          // const SizedBox(height: 20),
                          // _buildViewAllTrendingButton(),
                          // const SizedBox(height: 30),
                          // _buildHappyWedsServicesSection(),
                          // const SizedBox(height: 30),
                          // _buildWeddingIdeasSection(),
                          // const SizedBox(height: 20),
                          // _buildViewAllWeddingIdeasButton(),
                          // const SizedBox(height: 30),
                          // _buildFeaturedVideoSection(),
                          const SizedBox(height: 30),
                          _buildInterestingReadsSection(),
                          const SizedBox(height: 20),
                          _buildViewAllInterestingReadsButton(),
                          const SizedBox(height: 30),
                          _buildRealWeddingsSection(),
                          const SizedBox(height: 20),
                          _buildViewAllRealWeddingsButton(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // floating AI button (unchanged)
          // Positioned(
          //   bottom: 20,
          //   right: 20,
          //   child: GestureDetector(
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (_) => const AiChatScreen()),
          //       );
          //     },
          //     child: AnimatedContainer(
          //       duration: const Duration(milliseconds: 600),
          //       curve: Curves.easeInOut,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         gradient: const LinearGradient(
          //           colors: [Color(0xFF6A5AE0), Color(0xFFB26BF2)],
          //           begin: Alignment.topLeft,
          //           end: Alignment.bottomRight,
          //         ),
          //         boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.5), blurRadius: 20, spreadRadius: 5)],
          //       ),
          //       padding: const EdgeInsets.all(18),
          //       // child: const VideoIcon(),
          //       child: SizedBox(
          //         height: 35,
          //         width: 35,
          //         child: Image.asset('assets/shadiai-unscreen.gif'),
          //       ),
          //
          //       // child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          //     ),
          //   ),
          // ),
    Positioned(
    bottom: 20,
    right: 20,
    child: GestureDetector(
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AiChatScreen()),
    );
    },
    child: AnimatedContainer(
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeInOut,

    decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.pink,   // Pink background
    boxShadow: [
    BoxShadow(
    color: Colors.pink.withOpacity(0.4),
    blurRadius: 25,
    spreadRadius: 5,
    ),
    ],
    ),

    // Bigger button
    // padding: const EdgeInsets.all(20),

    // ⭐ Directly increase the image size
    child: Image.asset(
    'assets/shadiai-unscreen.gif',
    height: 70,     // 🔥 Increase image height
    width: 70,      // 🔥 Increase image width
    fit: BoxFit.contain,
    ),
    ),
    ),
    ),

          // global loading overlay that only hides after initial loads complete
          if (isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white.withOpacity(0.9),
              child: const Center(
                child: CircularProgressIndicator(),
                // Replace with LoadingLogo(size: 130) if you have it
              ),
            ),
        ],
      ),
    );
  }

  // -------- HEADER & UI helper widgets (kept similar, trimmed where not needed) --------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          if (_showSearch)
            Container(
              width: 200,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: const InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            )
          else
            Row(children: [
              Text(
                _getLocationDisplayText(),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 5),
              InkWell(
                onTap: () => _showLocationSelection(context),
                child: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ),
            ]),
        ]),
        Row(children: [
          InkWell(
            onTap: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            child: Container(padding: const EdgeInsets.all(8)),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ])
      ]),
    );
  }
  Widget _buildCategorySection() {
    if (isLoadingCategories) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: horizontalCategories.length + 1, // +1 for "All Categories"
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final isLast = index == horizontalCategories.length;

          if (isLast) {
            // "All Categories" button
            return Container(
              margin: const EdgeInsets.only(right: 0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VendorCategoriesScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.pink, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.pink,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All\nCategories',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }

          final category = horizontalCategories[index];

// Fix hero image URL
          String imageUrl = '';
          if (category.heroImage.isNotEmpty) {
            imageUrl =
            "https://happywedzbackend.happywedz.com${category.heroImage}";
          }
        print(imageUrl);
          return Container(
            margin: const EdgeInsets.only(right: 15),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    if (category.subcategories.isNotEmpty) {
                      final subcategory = category.subcategories.first;

                      final subcategoryName = subcategory["name"] ?? "";
                      // final subcategoryName = category.subcategories.first.name;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorServicesScreen(
                            subcategoryName: subcategoryName,
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 70,
                        height: 70,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.pink.shade100,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white),
                        ),
                      )
                          : Container(
                        color: Colors.pink.shade100,
                        child:
                        const Icon(Icons.image, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );

        },
      ),
    );
  }

  // Widget _buildCategorySection() {
  //   if (isLoadingCategories) {
  //     return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
  //   }
  //   return SizedBox(
  //     height: 120,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: horizontalCategories.length + 1,
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       itemBuilder: (context, index) {
  //         final isLast = index == horizontalCategories.length;
  //         if (isLast) {
  //           return Container(
  //             margin: const EdgeInsets.only(right: 0),
  //             child: Column(children: [
  //               InkWell(
  //                 onTap: () {
  //                   // navigate to all categories
  //                    Navigator.push(context, MaterialPageRoute(builder: (context) => VendorCategoriesScreen()));
  //                 },
  //                 borderRadius: BorderRadius.circular(50),
  //                 child: Container(
  //                   width: 70,
  //                   height: 70,
  //                   decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.pink, width: 2)),
  //                   child: const Icon(Icons.add, color: Colors.pink, size: 30),
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               const Text('All\nCategories', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87)),
  //             ]),
  //           );
  //         }
  //
  //         final category = horizontalCategories[index];
  //         final imageUrl = category.heroImage.isNotEmpty ? "https://happywedzbackend.happywedz.com/${category.heroImage}" : '';
  //
  //         return Container(
  //           margin: const EdgeInsets.only(right: 15),
  //           child: Column(children: [
  //             InkWell(
  //               onTap: () {
  //                 if (category.subcategories.isNotEmpty) {
  //                   final subcategoryName = category.subcategories.first.name;
  //                   // Navigator.push to VendorServicesScreen(subcategoryName)
  //                 }
  //               },
  //               borderRadius: BorderRadius.circular(50),
  //               child: Container(
  //                 width: 70,
  //                 height: 70,
  //                 decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
  //                 child: ClipOval(
  //                   child: imageUrl.isNotEmpty
  //                       ? Image.network(imageUrl, fit: BoxFit.cover, width: 70, height: 70, errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white))
  //                       : const Icon(Icons.image, color: Colors.white),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             SizedBox(width: 70, child: Text(category.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black87))),
  //           ]),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildPlanningToolsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Wedding Planning tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WeddingInvitesScreen1(),
                ),
              );
            },
            child: _buildPlanningToolCard('Build your\nDigital E-invites', 'on app launch', Colors.purple[100]!, Icons.card_giftcard, Colors.purple),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () async {
              bool hasFavourites = await checkUserHasFavourites();

              if (hasFavourites) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavouritesPage()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>  VendorCategoriesScreen()),
                );
              }
            },
            child: _buildPlanningToolCard(
              'Your shortlisted\nvendor',
              'Venue vendors',
              Colors.orange[100]!,
              Icons.favorite,
              Colors.orange,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Ideas(initialSubTabIndex: 1),
                ),
              );
            },
            child: _buildPlanningToolCard('Your Favourite\nblog', 'will it favourite', Colors.pink[100]!, Icons.bookmark, Colors.pink),
          ),
        ),
      ])
    ]);
  }

  Widget _buildPlanningToolCard(String title, String subtitle, Color bgColor, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 15),
        Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: iconColor, size: 20))),
      ]),
    );
  }

  Widget _buildVenuesSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_selectedCity != null ? 'Venues in $_selectedCity' : 'Venues in your city', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 15),
      isLoadingVenues
          ? const Center(child: CircularProgressIndicator())
          : venues.isEmpty
          ? const Text("No venues found")
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: venues.map<Widget>((venue) {
          final vendor = (venue is Map && venue['vendor'] is Map) ? venue['vendor'] as Map<String, dynamic> : <String, dynamic>{};
          final attributes = (venue is Map && venue['attributes'] is Map) ? venue['attributes'] as Map<String, dynamic> : <String, dynamic>{};
          final media = (venue is Map && venue['media'] is Map) ? venue['media'] as Map<String, dynamic> : <String, dynamic>{};

          String imageUrl = 'https://via.placeholder.com/200x120';
          if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
            final cover = media['coverImage'].toString();
            imageUrl = cover.startsWith('/uploads/') ? "https://happywedzbackend.happywedz.com$cover" : cover;
          } else if (media['gallery'] != null && media['gallery'] is List) {
            for (var item in media['gallery']) {
              if (item is String && item.isNotEmpty) {
                imageUrl = item.startsWith('/uploads/') ? "https://happywedzbackend.happywedz.com$item" : item;
                break;
              } else if (item is Map && item['url'] != null) {
                final url = item['url'].toString();
                imageUrl = url.startsWith('/uploads/') ? "https://happywedzbackend.happywedz.com$url" : url;
                break;
              }
            }
          } else if (attributes['url'] != null && attributes['url'].toString().isNotEmpty) {
            imageUrl = 'https://api.thumbnail.ws/api/.../generate/thumbnail?url=${Uri.encodeComponent(attributes['url'])}&width=400';
          }

          final String name = (vendor['businessName'] ?? attributes['vendor_name'] ?? attributes['name'] ?? "No Name").toString();
          final String location = (attributes['city'] ?? attributes['address'] ?? vendor['city'] ?? 'Unknown Location').toString();
          String price = "--";
          final veg = attributes['veg_price']?.toString() ?? "";
          final nonVeg = attributes['non_veg_price']?.toString() ?? "";
          if (veg.isNotEmpty || nonVeg.isNotEmpty) {
            if (veg.isNotEmpty && nonVeg.isNotEmpty) {
              price = "₹$veg - ₹$nonVeg";
            } else {
              price = "₹${veg.isNotEmpty ? veg : nonVeg}";
            }
            price = "Starting from $price";
          }

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorDetailsScreen(
                    service: venue,
                    ),
                  ),
                );
              },

              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 120, width: 200, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(height: 120, width: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                  }, errorBuilder: (context, error, stackTrace) {
                    return Container(height: 120, width: 200, color: Colors.grey[300], child: const Icon(Icons.image, size: 40, color: Colors.white));
                  }),
                ),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }).toList()),
      ),
    ]);
  }

  Widget _buildViewAllVenuesButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorServicesScreen(
              subcategoryName: "venues",   // 👈 pass category name
            ),
          ),
        );
      },

      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.pink), borderRadius: BorderRadius.circular(25)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View all venues', style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 16),
        ]),
      ),
    );
  }

  Widget _buildPhotographerSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_selectedCity != null ? 'Photographers in $_selectedCity' : 'Photographers for you', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 15),
      isLoadingPhotographers
          ? const Center(child: CircularProgressIndicator())
          : photographers.isEmpty
          ? const Text("No photographers found")
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: photographers.map<Widget>((photo) {
          final vendor = (photo is Map && photo['vendor'] is Map)
              ? photo['vendor'] as Map<String, dynamic>
              : {};

          final attributes = (photo is Map && photo['attributes'] is Map)
              ? photo['attributes'] as Map<String, dynamic>
              : {};

          final media = photo['media'];
          String imageUrl = 'https://via.placeholder.com/200x120';

// FIX: media is actually a List of URLs
          if (media != null && media is List) {
            for (var item in media) {
              if (item is String && item.isNotEmpty) {
                imageUrl = item;
                break;
              }
            }
          }
// Try Portfolio field
          else if (attributes['Portfolio'] != null &&
              attributes['Portfolio'].toString().isNotEmpty) {
            final portfolioString = attributes['Portfolio'].toString();
            final list = portfolioString.split("|");
            if (list.isNotEmpty) imageUrl = list.first;
          }
// Thumbnail fallback
          else if (attributes['URL'] != null &&
              attributes['URL'].toString().isNotEmpty) {
            imageUrl =
            'https://api.thumbnail.ws/api/.../generate/thumbnail?url=${Uri.encodeComponent(attributes['URL'])}&width=400';
          }


          final String name = (vendor['businessName'] ?? attributes['vendor_name'] ?? attributes['name'] ?? "No Name").toString();
          final String location = (attributes['city'] ?? attributes['address'] ?? vendor['city'] ?? 'Unknown Location').toString();
          String price = "--";
          final startPrice = attributes['PriceRange']?.toString() ?? "";
          if (startPrice.isNotEmpty) price = "Price Range ₹$startPrice";

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorDetailsScreen(
                      service: photo,
                    ),
                  ),
                );
              },
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, height: 120, width: 200, fit: BoxFit.cover, loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(height: 120, width: 200, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                }, errorBuilder: (context, error, stackTrace) {
                  return Container(height: 120, width: 200, color: Colors.grey[300], child: const Icon(Icons.image, size: 40, color: Colors.white));
                })),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }).toList()),
      ),
    ]);
  }

  Widget _buildViewAllPhotographersButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VendorServicesScreen(
              subcategoryName: "photographer",   // 👈 pass category name
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.pink), borderRadius: BorderRadius.circular(25)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View all photographers', style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 16),
        ]),
      ),
    );
  }

  Widget _buildWeddingChecklistSection({required int completedCount, required int totalTasks, required List<String> upcomingTasks, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Wedding checklist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF6B35)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
          child: Stack(children: [
            Positioned(top: -20, right: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
            Positioned(bottom: -10, right: 30, child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1)))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$completedCount/$totalTasks', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const Text('Tasks done', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  ]),
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 20)),
                ]),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8), // reduced padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming tasks',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4), // reduced spacing
                      ...upcomingTasks.map(
                            (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 2), // reduced spacing
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 6),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6), // slightly smaller
                              Expanded(
                                child: Text(
                                  task,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                    height: 1.1, // reduce line height
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
                // Container(
                //   padding: const EdgeInsets.all(14),
                //   decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                //   child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                //     const Text('Upcoming tasks', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                //     const SizedBox(height: 8),
                //     ...upcomingTasks.map((task) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                //       Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                //       const SizedBox(width: 8),
                //       Expanded(child: Text(task, style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3))),
                //     ]))),
                //   ]),
                // ),
              ]),
            )
          ]),
        )
      ]),
    );
  }

  Widget _buildTrendingTodaySection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Trending Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text('Trendy themes', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ]),
      const SizedBox(height: 15),
      Row(children: [
        Expanded(child: _buildTrendingCard('assets/1.webp', Colors.pink[50]!)),
        const SizedBox(width: 12),
        Expanded(child: _buildTrendingCard('assets/12.webp', Colors.orange[50]!)),
      ]),
    ]);
  }

  Widget _buildTrendingCard(String imagePath, Color bgColor) {
    return Container(
      height: 120,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imagePath.startsWith("http")
            ? Image.network(imagePath, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 40))
            : Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 40)),
      ),
    );
  }

  Widget _buildViewAllTrendingButton() {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.pink), borderRadius: BorderRadius.circular(25)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View all trending today', style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 16),
        ]),
      ),
    );
  }

  Widget _buildHappyWedsServicesSection() {
    return InkWell(
      onTap: () {},
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HappyWeds Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))]),
          child: Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: double.infinity, color: Colors.brown[200], child: const Center(child: Icon(Icons.image, color: Colors.brown, size: 40)))),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.3)], begin: Alignment.centerLeft, end: Alignment.centerRight)),
              child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Myshrä', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), Text('Find your perfect match in seconds', style: TextStyle(color: Colors.white, fontSize: 12))])),
            )
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildServiceCard('Couple Services', 'Book your perfect shoot', 'assets/25.webp', Colors.green[100]!)),
          const SizedBox(width: 12),
          Expanded(child: _buildServiceCard('Couple Services', 'Book your perfect shoot', 'assets/26.webp', Colors.orange[100]!)),
        ]),
      ]),
    );
  }

  Widget _buildServiceCard(String title, String subtitle, String imagePath, Color bgColor) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))]),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: double.infinity, color: bgColor, child: Image.asset(imagePath, fit: BoxFit.cover))),
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withOpacity(0.4), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
          padding: const EdgeInsets.all(8),
          child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            if (subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 10))],
          ]),
        )
      ]),
    );
  }

  Widget _buildWeddingIdeasSection() {
    return InkWell(
      onTap: () {},
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Wedding Ideas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: _buildWeddingIdeaCard('Wedding day bridal portrait', 'assets/23.webp')),
          const SizedBox(width: 12),
          Expanded(child: _buildWeddingIdeaCard('Romantic couple shot', 'assets/24.webp')),
        ]),
      ]),
    );
  }

  Widget _buildWeddingIdeaCard(String title, String imagePath) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 140, decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(12))), child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity))),
        Padding(padding: const EdgeInsets.all(12), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))),
      ]),
    );
  }

  Widget _buildViewAllWeddingIdeasButton() {
    return InkWell(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.pink), borderRadius: BorderRadius.circular(25)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View all Wedding ideas', style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 16),
        ]),
      ),
    );
  }

  Widget _buildFeaturedVideoSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Featured video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      const SizedBox(height: 15),
      Container(width: double.infinity, height: 180, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 2))]), child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: double.infinity, color: Colors.green[200], child: const Center(child: Icon(Icons.image, color: Colors.green, size: 50)))),
        Container(width: double.infinity, height: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black.withOpacity(0.3)), child: Center(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.pink, size: 30))))
      ]))
    ]);
  }

  // -------- INTERESTING READS (blogs) --------
  // Widget _buildInterestingReadsSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       const Text(
  //         'Interesting reads',
  //         style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87),
  //       ),
  //       const SizedBox(height: 15),
  //
  //       isLoadingBlogPosts
  //           ? const Center(child: CircularProgressIndicator())
  //           : blogPosts.isEmpty
  //           ? const Text('No blog posts found')
  //           : Column(
  //         children: [
  //           SingleChildScrollView(
  //             scrollDirection: Axis.horizontal,
  //             child: Row(
  //               children: blogPosts.take(5).map<Widget>((post) {
  //                 final title = post['name'] ?? 'No title';
  //                 final imageUrl = (post['image'] != null &&
  //                     post['image'].toString().isNotEmpty)
  //                     ? post['image'].toString()
  //                     : 'https://via.placeholder.com/300x200';
  //
  //                 return Container(
  //                   height: 120,
  //                   width: 160,
  //                   margin: const EdgeInsets.only(right: 12),
  //                   decoration: BoxDecoration(
  //                       borderRadius: BorderRadius.circular(8)),
  //                   child: ClipRRect(
  //                     borderRadius: BorderRadius.circular(8),
  //                     child: Stack(
  //                       children: [
  //                         Image.network(
  //                           imageUrl,
  //                           fit: BoxFit.cover,
  //                           width: double.infinity,
  //                           height: double.infinity,
  //                           errorBuilder: (_, __, ___) =>
  //                               Container(color: Colors.grey[300]),
  //                         ),
  //                         Container(
  //                           padding: const EdgeInsets.all(8),
  //                           alignment: Alignment.bottomLeft,
  //                           decoration: BoxDecoration(
  //                             gradient: LinearGradient(
  //                               colors: [
  //                                 Colors.black.withOpacity(0.4),
  //                                 Colors.transparent
  //                               ],
  //                               begin: Alignment.bottomCenter,
  //                               end: Alignment.topCenter,
  //                             ),
  //                           ),
  //                           child: Text(
  //                             title,
  //                             style: const TextStyle(
  //                                 color: Colors.white, fontSize: 12),
  //                             maxLines: 2,
  //                             overflow: TextOverflow.ellipsis,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 );
  //               }).toList(),
  //             ),
  //           ),
  //           //
  //           // const SizedBox(height: 8),
  //           //
  //           // // ✅ NO 'post' HERE
  //           // Text(
  //           //   blogPosts.isNotEmpty
  //           //       ? (blogPosts.first['description'] ?? '')
  //           //       : '',
  //           //   style: const TextStyle(
  //           //       fontSize: 14,
  //           //       color: Colors.black87,
  //           //       height: 1.4),
  //           // ),
  //           //
  //           // const SizedBox(height: 16),
  //           //
  //           // InkWell(
  //           //   onTap: () {},
  //           //   child: Container(
  //           //     width: double.infinity,
  //           //     padding:
  //           //     const EdgeInsets.symmetric(vertical: 12),
  //           //     decoration: BoxDecoration(
  //           //         border:
  //           //         Border.all(color: Color(0xFFE91E63)),
  //           //         borderRadius: BorderRadius.circular(25)),
  //           //     child: const Text(
  //           //       'View all interesting reads >',
  //           //       textAlign: TextAlign.center,
  //           //       style: TextStyle(
  //           //           color: Color(0xFFE91E63),
  //           //           fontSize: 14,
  //           //           fontWeight: FontWeight.w500),
  //           //     ),
  //           //   ),
  //           // )
  //         ],
  //       ),
  //     ],
  //   );
  // }
  Widget _buildInterestingReadsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interesting reads',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 18),

        isLoadingBlogPosts
            ? const Center(child: CircularProgressIndicator())
            : blogPosts.isEmpty
            ? const Text('No blog posts found')
            : SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: blogPosts.length,
            padding: const EdgeInsets.only(left: 4),
            itemBuilder: (context, index) {
              final post = blogPosts[index];
              final img = post['image'] ?? "";
              final title = post['title'] ?? "";
              final shortDesc = post['shortDescription'] ?? "";
              final author = post['author'] ?? "";
              final date = post['date']?.toString().split("T")[0] ?? "";

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlogDetailPage(
                        title: post['title'] ?? '',
                        date: post['postDate']?.toString().split("T")[0] ?? '',
                        author: post['author'] ?? '',
                        image: post['image'] ?? '',
                        content: post['shortDescription'] ?? '',
                        category: post['category']?['name'] ?? '',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: Image.network(
                            img.isNotEmpty
                                ? img
                                : "https://via.placeholder.com/600x400",
                            fit: BoxFit.cover,
                          ),
                        ),

                        // Title
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Short Description
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            shortDesc,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        const Spacer(),

                        // Author + Date
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                author,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blueGrey,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                date,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildViewAllInterestingReadsButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Ideas(initialSubTabIndex: 1),
          ),
        );

      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.pink), borderRadius: BorderRadius.circular(25)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View all Interesting reads', style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 16),
        ]),
      ),
    );
  }
  // -------- REAL WEDDINGS --------
  // Widget _buildRealWeddingsSection() {
  //   return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //     const Text('Real weddings we love', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
  //     const SizedBox(height: 16),
  //     isLoadingRealWeddings
  //         ? const Center(child: CircularProgressIndicator())
  //         : realWeddings.isEmpty
  //         ? const Text("No real weddings found")
  //         : SingleChildScrollView(
  //       scrollDirection: Axis.horizontal,
  //       child: Row(children: realWeddings.map<Widget>((wedding) {
  //         final cover = (wedding is Map) ? (wedding['cover_photo'] ?? '') : '';
  //         final title = (wedding is Map) ? (wedding['title'] ?? 'No title') : wedding.toString();
  //         final imageUrl = cover.toString().isNotEmpty ? cover.toString() : 'https://via.placeholder.com/300x200';
  //         final city = (wedding is Map) ? (wedding['city'] ?? '') : '';
  //         return Container(
  //           width: 200,
  //           margin: const EdgeInsets.only(right: 12),
  //           child: InkWell(
  //             onTap: () {
  //               // open wedding details screen
  //             },
  //             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //               ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, height: 120, width: 200, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 120, width: 200, color: Colors.grey[300], child: const Icon(Icons.image)))),
  //               const SizedBox(height: 8),
  //               Text(title.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
  //               const SizedBox(height: 4),
  //               Text(city.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
  //             ]),
  //           ),
  //         );
  //       }).toList()),
  //     ),
  //   ]);
  // }
  Widget _buildRealWeddingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Real weddings we love',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        isLoadingRealWeddings
            ? const Center(child: CircularProgressIndicator())
            : realWeddings.isEmpty
            ? const Text("No real weddings found")
            : SizedBox(
          height: 230,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: realWeddings.length,
            itemBuilder: (context, index) {
              final wedding = realWeddings[index];
              final String imageUrl = wedding['cover_photo'] ?? "";
              final String title = wedding['title'] ?? "";
              final String city = wedding['city'] ?? "";
              final String date = wedding['wedding_date'] ?? "";

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RealWeddingDetailPage(
                        wedding: RealWedding.fromJson(wedding),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  margin: EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Wedding cover image
                        Positioned.fill(
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey.shade200,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[300]),
                          ),
                        ),

                        // Gradient overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Text bottom area
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on,
                                      size: 12, color: Colors.white70),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      city,
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                date,
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllRealWeddingsButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Ideas(initialSubTabIndex: 2),
          ),
        );

      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border.all(color: Colors.pink), borderRadius: BorderRadius.circular(25)),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('View all Real Wedding', style: TextStyle(color: Colors.pink, fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios, color: Colors.pink, size: 16),
        ]),
      ),
    );
  }

  // Helper
  String _getLocationDisplayText() {
    if (_selectedCity != null) return _selectedCity!;
    if (_selectedState != null) return _selectedState!;
    if (_selectedCountry != null) return _selectedCountry!;
    return "Select Location";
  }
}

// Simple SearchDelegate for city selection
class _CitySearchDelegate extends SearchDelegate<String> {
  final List<String> cities;
  _CitySearchDelegate(this.cities);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    final results = cities.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(itemCount: results.length, itemBuilder: (_, i) => ListTile(title: Text(results[i]), onTap: () => close(context, results[i])));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty ? cities : cities.where((c) => c.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(itemCount: suggestions.length, itemBuilder: (_, i) => ListTile(title: Text(suggestions[i]), onTap: () => close(context, suggestions[i])));
  }
}

// Placeholder VendorCategory model - replace with your actual model
class VendorCategory {
  final String name;
  final String heroImage;
  final List<dynamic> subcategories;

  VendorCategory({required this.name, required this.heroImage, required this.subcategories});

  factory VendorCategory.fromJson(Map<String, dynamic> json) {
    return VendorCategory(
      name: json['name'] ?? '',
      heroImage: json['hero_image'] ?? '',
      subcategories: json['subcategories'] ?? [],
    );
  }
}













// class _CitySearchDelegate extends SearchDelegate<String> {
//   final List<String> cities;
//
//   _CitySearchDelegate(this.cities) : super(searchFieldLabel: "Search City");
//
//   @override
//   List<Widget>? buildActions(BuildContext context) {
//     return [
//       if (query.isNotEmpty)
//         IconButton(
//           icon: const Icon(Icons.clear),
//           onPressed: () => query = '',
//         ),
//     ];
//   }
//
//   @override
//   Widget? buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back),
//       onPressed: () => close(context, ''),
//     );
//   }
//
//   @override
//   Widget buildResults(BuildContext context) {
//     final results = cities
//         .where((city) => city.toLowerCase().contains(query.toLowerCase()))
//         .toList();
//
//     return ListView.builder(
//       itemCount: results.length,
//       itemBuilder: (_, i) => ListTile(
//         title: Text(results[i]),
//         onTap: () => close(context, results[i]),
//       ),
//     );
//   }
//
//   @override
//   Widget buildSuggestions(BuildContext context) {
//     final suggestions = cities
//         .where((city) => city.toLowerCase().contains(query.toLowerCase()))
//         .toList();
//
//     return ListView.builder(
//       itemCount: suggestions.length,
//       itemBuilder: (_, i) => ListTile(
//         title: Text(suggestions[i]),
//         onTap: () => close(context, suggestions[i]),
//       ),
//     );
//   }
// }



























class BottomBars extends StatefulWidget {
  const  BottomBars({super.key});

  @override
  State<BottomBars> createState() => _BottomBarsState();
}

class _BottomBarsState extends State<BottomBars> {
  int _selectedIndex = 0;

  // All screens for bottom nav
  final List<Widget> _screens = [
    const WeddingHomePage(),
    const VenuesScreen(),
     VirtualTryOnScreennnnnnn(),
    // LancomeMakeupTryOnScreen(),
    // FinalLookResultScreen(),
    const VendorCategoriesScreen(),
    MoreOptionsScreen()
    // VenueDetailsScreen()
    // const MoreScreen(),
  ];


  Future<void> _onItemTapped(int index) async {
    // ✅ If user taps on VirtualStudio (index = 2)
    if (index == 2) {
      final loggedIn = await ensureLoggedIn(context);
      if (!loggedIn) return; // 🚫 not logged in → SignInScreen opened automatically
    }

    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        // currentIndex: 0,
        currentIndex: _selectedIndex,
        // ✅ dynamic index
        onTap: _onItemTapped,
        // ✅ tap handler
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Venues',
          ),
          BottomNavigationBarItem(
            icon: Container(
              // padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/tryimg.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),

            ),
            label: 'DesignStudio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Vendors',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }

}





class LocationService {
  static const String _baseUrl = "https://www.countriesnow.space/api/v0.1/countries/cities";

  static Future<List<String>> fetchCities(String country) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"country": country}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] == false) {
        return List<String>.from(data['data']); // returns list of city names
      } else {
        throw Exception(data['msg'] ?? "Failed to fetch cities");
      }
    } else {
      throw Exception("HTTP Error: ${response.statusCode}");
    }
  }
}






class CategoryItemsScreen extends StatefulWidget {
  final VendorCategory category;

  const CategoryItemsScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  List<dynamic> _services = [];
  bool _loading = false;

  Future<void> fetchServices(String subcategoryName) async {
    setState(() => _loading = true);
    try {
      final url =
          "https://happywedz.com/api/vendor-services?subCategory=${Uri.encodeComponent(subcategoryName)}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _services = data;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar style header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Subcategory selector
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: category.subcategories.length,
                  itemBuilder: (context, index) {
                    final sub = category.subcategories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () => fetchServices(sub.name),
                        child: Text(sub.name,
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    );
                  },
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                    : _services.isEmpty
                    ? const Center(child: Text("Select a subcategory to view vendors"))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final item = _services[index];
                    final image = item['hero_image'] != null
                        ? "https://happywedz.com${item['hero_image']}"
                        : "https://via.placeholder.com/400x300?text=No+Image";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              image,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              item['name'] ?? 'No name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





class VideoIcon extends StatefulWidget {
  const VideoIcon({super.key});

  @override
  State<VideoIcon> createState() => _VideoIconState();
}

class _VideoIconState extends State<VideoIcon> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/shadiai.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: _controller.value.isInitialized
          ? VideoPlayer(_controller)
          : const SizedBox(),
    );
  }
}
