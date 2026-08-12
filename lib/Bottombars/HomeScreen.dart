
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';
import '../WedChecklist/ChecklistScreen.dart';
import '../Wishlist/Wishlistscreen.dart';
import '../ai_chat_screen/ai_chat_screen.dart';
import '../einvite1/einvite.dart';
import '../ideas.dart';
import '../main.dart';
import '../profile.dart';
import '../vendor/vendordetailsscreen.dart';
import 'Vendor.dart';
import 'VenuesScreen.dart';
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
                child: NetworkImageWidget(url: card['image'] ?? '', fit: BoxFit.cover),
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
            child: NetworkImageWidget(url: image, width: width * 0.36, height: 100, fit: BoxFit.cover),
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
                                  color: Colors.white.withValues(alpha: 0.8),
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
                            color: Colors.black.withValues(alpha: 0.08),
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
                      colors: [Colors.black.withValues(alpha: 0.35), Colors.transparent],
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
                    child: NetworkImageWidget(url: 'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F1056d056a37e91a97da6758a70e2dada5d0a4f38Rectangle%20266.png?alt=media&token=36044e03-5eab-492d-8ed5-0e1fbf35dfd0', height: 140, fit: BoxFit.cover),
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
  bool checklistLoading = false;

  DateTime? weddingDate;
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    loadStories();
    _loadChecklistSummary();

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

  //  checklist
  Future<void> _loadChecklistSummary() async {
    try {
      setState(() => checklistLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final userId = prefs.getInt('user_id');

      if (userId == null || token.isEmpty) return;

      final url =
      Uri.parse("https://happywedz.com/api/new-checklist/newChecklist/user/$userId");

      final res = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      final List list = body["data"] ?? [];

      int completed = 0;
      final List<String> upcoming = [];

      for (final item in list) {
        final status = item["status"]?.toString() ?? "pending";
        final title = item["text"]?.toString() ?? "";

        if (status == "completed") {
          completed++;
        } else if (title.isNotEmpty) {
          upcoming.add(title);
        }
      }

      setState(() {
        totalTasks = list.length;
        completedCount = completed;
        upcomingTasks = upcoming.take(3).toList(); // show max 3
      });
    } catch (e) {
      debugPrint("❌ Checklist summary error: $e");
    } finally {
      setState(() => checklistLoading = false);
    }
  }

  // -------- UI BUILD --------

  /// Pull-to-refresh: re-runs exactly the same fetches as the initial load.
  Future<void> _refreshAll() async {
    await Future.wait([
      _loadInitialData(),
      loadStories(),
      _loadChecklistSummary(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        _buildCategorySection(),
                        const SizedBox(height: AppSpacing.sm),
                        _buildPlanningToolsSection(),
                        _buildVenuesSection(),
                        Padding(
                          padding: AppSpacing.page,
                          child: _buildViewAllVenuesButton(context),
                        ),
                        _buildPhotographerSection(),
                        Padding(
                          padding: AppSpacing.page,
                          child: _buildViewAllPhotographersButton(),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        _buildWeddingChecklistSection(
                          completedCount: completedCount,
                          totalTasks: totalTasks,
                          upcomingTasks: upcomingTasks,
                          onTap: () async {
                            await Navigator.of(context).push(
                              AnimatedPageRoute(
                                page: const WeddingTimelinePage(),
                              ),
                            );

                            // 🔥 refresh summary after coming back
                            await _loadChecklistSummary();
                          },
                        ),
                        _buildInterestingReadsSection(),
                        Padding(
                          padding: AppSpacing.page,
                          child: _buildViewAllInterestingReadsButton(),
                        ),
                        _buildRealWeddingsSection(),
                        Padding(
                          padding: AppSpacing.page,
                          child: _buildViewAllRealWeddingsButton(),
                        ),
                        // Clears the floating AI button and the bottom nav.
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating "Shadi AI" assistant
          Positioned(
            bottom: 20,
            right: 20,
            child: Pressable(
              scale: 0.9,
              onTap: () {
                Navigator.push(
                  context,
                  AnimatedPageRoute(
                    page: const AiChatScreen(),
                    style: PageTransitionStyle.scaleFade,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 25,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/shadiai-unscreen.gif',
                  height: 70,
                  width: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 70,
                    width: 70,
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shared "View all …" pill used at the end of each section.
  Widget _viewAllButton(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: PremiumButton.outlined(
        label: label,
        trailingIcon: Icons.arrow_forward_rounded,
        size: PremiumButtonSize.medium,
        onPressed: onTap,
      ),
    );
  }

  /// Horizontal media card used by the venue and photographer rails.
  Widget _railCard({
    required String imageUrl,
    required String name,
    required String location,
    required String price,
    required VoidCallback onTap,
    required int index,
  }) {
    return FadeSlideIn.staggered(
      index: index,
      offset: const Offset(0.08, 0),
      child: SizedBox(
        width: 210,
        child: AppCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          radius: AppRadii.lg,
          shadow: AppColors.shadowSm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              NetworkImageWidget(
                url: imageUrl,
                width: 210,
                height: 128,
                memCacheWidth: 520,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppText.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location,
                            style: AppText.cardSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      price,
                      style: AppText.priceSm,
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
    );
  }

  /// Wraps a horizontal rail with its loading / empty states.
  Widget _rail({
    required bool loading,
    required bool isEmpty,
    required String emptyTitle,
    required String emptyMessage,
    required double height,
    required List<Widget> children,
  }) {
    if (loading) {
      return Skeletons.cardRail(height: height, itemWidth: 210);
    }
    if (isEmpty) {
      return EmptyState(
        compact: true,
        icon: Icons.storefront_outlined,
        title: emptyTitle,
        message: emptyMessage,
      );
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSpacing.page,
        clipBehavior: Clip.none,
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }

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
  //         boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)],
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
  // -------- HEADER & UI helper widgets (kept similar, trimmed where not needed) --------
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
  Widget _buildHeader() {
    return GradientHeader(
      gradient: AppColors.brandGradient,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Location selector
              Expanded(
                child: Pressable(
                  scale: 0.97,
                  onTap: () => _showLocationSelection(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your city',
                        style: AppText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _getLocationDisplayText(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sectionTitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _headerIcon(
                icon: _showSearch
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                tooltip: _showSearch ? 'Close search' : 'Search',
                onTap: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              _headerIcon(
                icon: Icons.person_outline_rounded,
                tooltip: 'Profile',
                onTap: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  bool isLoggedIn = prefs.getBool("isLoggedIn") ?? false;

                  if (!mounted) return;
                  if (!isLoggedIn) {
                    // User NOT logged in → go to SignInScreen
                    Navigator.push(
                      context,
                      AnimatedPageRoute(page: const SignInScreen()),
                    );
                  } else {
                    // User logged in → go to Profile Settings
                    Navigator.push(
                      context,
                      AnimatedPageRoute(page: const ProfileSettingsScreen()),
                    );
                  }
                },
              ),
            ],
          ),

          // Inline search field, animated open/closed.
          AppExpandable(
            expanded: _showSearch,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: AppText.body,
                decoration: InputDecoration(
                  hintText: 'Search venues, vendors, ideas…',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: const OutlineInputBorder(
                    borderRadius: AppRadii.rPill,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.rPill,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadii.rPill,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Pressable(
      scale: 0.88,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
  Widget _buildCategorySection() {
    const double avatar = 68;
    const double itemWidth = 76;
    // Height is derived from the content, not guessed, so two-line labels can
    // never overflow the rail.
    const double railHeight = avatar + 8 + 32;

    if (isLoadingCategories) {
      return SizedBox(
        height: railHeight,
        child: LoadingShimmer(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: AppSpacing.page,
            itemCount: 5,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, __) => const SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  SkeletonBox.circle(size: avatar),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 54, height: 10),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: railHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: horizontalCategories.length + 1, // +1 for "All Categories"
        padding: AppSpacing.page,
        clipBehavior: Clip.none,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final isLast = index == horizontalCategories.length;

          if (isLast) {
            // "All Categories" button
            return FadeSlideIn.staggered(
              index: index,
              offset: const Offset(0.1, 0),
              child: _categoryTile(
                width: itemWidth,
                label: 'All\nCategories',
                onTap: () {
                  Navigator.push(
                    context,
                    AnimatedPageRoute(page: const VendorCategoriesScreen()),
                  );
                },
                avatar: Container(
                  width: avatar,
                  height: avatar,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 1.6),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
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

          return FadeSlideIn.staggered(
            index: index,
            offset: const Offset(0.1, 0),
            child: _categoryTile(
              width: itemWidth,
              label: category.name,
              onTap: () {
                if (category.subcategories.isNotEmpty) {
                  final subcategory = category.subcategories.first;

                  final subcategoryName = subcategory["name"] ?? "";
                  Navigator.push(
                    context,
                    AnimatedPageRoute(
                      page: VendorServicesScreen(
                        subcategoryName: subcategoryName,
                      ),
                    ),
                  );
                }
              },
              avatar: Container(
                width: avatar,
                height: avatar,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                  boxShadow: AppColors.shadowSm,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: NetworkImageWidget(
                      url: imageUrl,
                      width: avatar,
                      height: avatar,
                      memCacheWidth: 180,
                      placeholderIcon: Icons.category_outlined,
                      errorIcon: Icons.category_outlined,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryTile({
    required double width,
    required String label,
    required Widget avatar,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: Pressable(
        scale: 0.93,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ],
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Wedding Planning Tools',
          subtitle: 'Everything you need, in one place',
          accent: true,
        ),
        Padding(
          padding: AppSpacing.page,
          child: IntrinsicHeight(
            // Keeps the three cards the same height whatever their text length,
            // instead of letting the tallest stretch the row unevenly.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: FadeSlideIn.staggered(
                    index: 0,
                    child: _buildPlanningToolCard(
                      'Build your\nDigital E-invites',
                      'Design & share',
                      AppColors.blushDeep,
                      Icons.insert_invitation_rounded,
                      AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          AnimatedPageRoute(page: const EInvitationScreen()),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FadeSlideIn.staggered(
                    index: 1,
                    child: _buildPlanningToolCard(
                      'Your shortlisted\nvendors',
                      'Saved for later',
                      const Color(0xFFFFF3E0),
                      Icons.favorite_rounded,
                      Colors.orange,
                      onTap: () async {
                        bool hasFavourites = await checkUserHasFavourites();

                        if (!mounted) return;
                        if (hasFavourites) {
                          Navigator.push(
                            context,
                            AnimatedPageRoute(page: const FavouritesPage()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            AnimatedPageRoute(page: VendorCategoriesScreen()),
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FadeSlideIn.staggered(
                    index: 2,
                    child: _buildPlanningToolCard(
                      'Your favourite\nblogs',
                      'Reads you saved',
                      AppColors.pinkSurface,
                      Icons.bookmark_rounded,
                      AppColors.primaryDeep,
                      onTap: () {
                        Navigator.push(
                          context,
                          AnimatedPageRoute(
                            page: Ideas(initialSubTabIndex: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanningToolCard(
    String title,
    String subtitle,
    Color bgColor,
    IconData icon,
    Color iconColor, {
    VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      color: bgColor,
      radius: AppRadii.md,
      elevated: false,
      border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadii.rSm,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget  _buildVenuesSection() {
    final cards = <Widget>[];
    for (var i = 0; i < venues.length; i++) {
      final venue = venues[i];
      final vendor = (venue is Map && venue['vendor'] is Map) ? venue['vendor'] as Map<String, dynamic> : <String, dynamic>{};
      final attributes = (venue is Map && venue['attributes'] is Map) ? venue['attributes'] as Map<String, dynamic> : <String, dynamic>{};
      final media = (venue is Map && venue['media'] is Map) ? venue['media'] as Map<String, dynamic> : <String, dynamic>{};

      String imageUrl = '';
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

      cards.add(
        _railCard(
          index: i,
          imageUrl: imageUrl,
          name: name,
          location: location,
          price: price,
          onTap: () {
            Navigator.push(
              context,
              AnimatedPageRoute(page: VendorDetailsScreen(service: venue)),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _selectedCity != null
              ? 'Venues in $_selectedCity'
              : 'Venues in your city',
          subtitle: 'Handpicked spaces for your celebration',
          accent: true,
        ),
        _rail(
          loading: isLoadingVenues,
          isEmpty: venues.isEmpty,
          emptyTitle: 'No venues found',
          emptyMessage: 'Try changing your city or check back soon.',
          height: 246,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildViewAllVenuesButton(BuildContext context) {
    return _viewAllButton('View all Venues', () {
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: VendorServicesScreen(
            subcategoryName: "venues",   // 👈 pass category name
          ),
        ),
      );
    });
  }

  Widget _buildPhotographerSection() {
    final cards = <Widget>[];
    for (var i = 0; i < photographers.length; i++) {
      final photo = photographers[i];
      final vendor = (photo is Map && photo['vendor'] is Map)
          ? photo['vendor'] as Map<String, dynamic>
          : {};

      final attributes = (photo is Map && photo['attributes'] is Map)
          ? photo['attributes'] as Map<String, dynamic>
          : {};

      final media = photo['media'];
      String imageUrl = '';

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

      cards.add(
        _railCard(
          index: i,
          imageUrl: imageUrl,
          name: name,
          location: location,
          price: price,
          onTap: () {
            Navigator.push(
              context,
              AnimatedPageRoute(page: VendorDetailsScreen(service: photo)),
            );
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: _selectedCity != null
              ? 'Photographers in $_selectedCity'
              : 'Photographers for you',
          subtitle: 'Storytellers who capture every moment',
          accent: true,
        ),
        _rail(
          loading: isLoadingPhotographers,
          isEmpty: photographers.isEmpty,
          emptyTitle: 'No photographers found',
          emptyMessage: 'Try changing your city or check back soon.',
          height: 246,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildViewAllPhotographersButton() {
    return _viewAllButton('View all Photographers', () {
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: VendorServicesScreen(
            subcategoryName: "photographer",   // 👈 pass category name
          ),
        ),
      );
    });
  }

  Widget _buildWeddingChecklistSection({required int completedCount, required int totalTasks, required List<String> upcomingTasks, required VoidCallback onTap}) {
    final progress = totalTasks == 0 ? 0.0 : completedCount / totalTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Wedding Checklist',
          subtitle: 'Stay on top of every task',
          accent: true,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
        ),
        Padding(
          padding: AppSpacing.page,
          child: AppCard(
            onTap: onTap,
            padding: EdgeInsets.zero,
            radius: AppRadii.lg,
            shadow: AppColors.shadowMd,
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFFFF6B35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Stack(children: [
            Positioned(top: -20, right: -20, child: Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
            Positioned(bottom: -10, right: 30, child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)))),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      checklistLoading
                          ? const SizedBox(
                              height: 34,
                              width: 90,
                              child: LoadingShimmer(
                                child: SkeletonBox(
                                  width: 90,
                                  height: 26,
                                  radius: AppRadii.sm,
                                ),
                              ),
                            )
                          : Text('$completedCount/$totalTasks', style: AppText.display.copyWith(color: Colors.white)),
                      Text('Tasks done', style: AppText.bodyStrong.copyWith(color: Colors.white)),
                    ]),
                  ),
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 20)),
                ]),
                const SizedBox(height: AppSpacing.md),
                // Progress bar
                ClipRRect(
                  borderRadius: AppRadii.rPill,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                    duration: AppMotion.slow,
                    curve: AppMotion.standard,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.28),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Upcoming tasks', style: AppText.label),
                      const SizedBox(height: AppSpacing.sm),
                      if (upcomingTasks.isEmpty)
                        Text(
                          checklistLoading
                              ? 'Loading your checklist…'
                              : 'Nothing pending — you are all caught up!',
                          style: AppText.caption,
                        )
                      else
                        ...upcomingTasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    task,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodySm.copyWith(
                                      color: AppColors.textPrimary,
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
              ]),
            )
          ]),
          ),
        ),
      ],
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
            ? NetworkImageWidget(url: imagePath, fit: BoxFit.cover, width: double.infinity)
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: Offset(0, 2))]),
          child: Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: double.infinity, color: Colors.brown[200], child: const Center(child: Icon(Icons.image, color: Colors.brown, size: 40)))),
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.3)], begin: Alignment.centerLeft, end: Alignment.centerRight)),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: Offset(0, 2))]),
      child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: double.infinity, color: bgColor, child: Image.asset(imagePath, fit: BoxFit.cover))),
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 2))]),
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
      Container(width: double.infinity, height: 180, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: Offset(0, 2))]), child: Stack(children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(width: double.infinity, height: double.infinity, color: Colors.green[200], child: const Center(child: Icon(Icons.image, color: Colors.green, size: 50)))),
        Container(width: double.infinity, height: double.infinity, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black.withValues(alpha: 0.3)), child: Center(child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: Colors.pink, size: 30))))
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
  //                                 Colors.black.withValues(alpha: 0.4),
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
    final cards = <Widget>[];
    for (var index = 0; index < blogPosts.length; index++) {
      final post = blogPosts[index];
      final img = post['image'] ?? "";
      final title = post['title'] ?? "";
      final shortDesc = post['shortDescription'] ?? "";
      final author = post['author'] ?? "";
      final date = post['date']?.toString().split("T").first ?? "";

      cards.add(
        FadeSlideIn.staggered(
          index: index,
          offset: const Offset(0.08, 0),
          child: SizedBox(
            width: 264,
            child: AppCard(
              padding: EdgeInsets.zero,
              radius: AppRadii.lg,
              shadow: AppColors.shadowSm,
              onTap: () {
                Navigator.push(
                  context,
                  AnimatedPageRoute(
                    page: BlogDetailPage(
                      title: post['title'] ?? '',
                      date: post['postDate']?.toString().split("T").first ?? '',
                      author: post['author'] ?? '',
                      image: post['image'] ?? '',
                      content: post['shortDescription'] ?? '',
                      category: post['category']?['name'] ?? '',
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  NetworkImageWidget(
                    url: img,
                    width: 264,
                    height: 132,
                    memCacheWidth: 640,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 38,
                          child: Text(
                            title,
                            style: AppText.cardTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 34,
                          child: Text(
                            shortDesc,
                            style: AppText.cardSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(date, style: AppText.caption),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Interesting Reads',
          subtitle: 'Ideas, tips and real stories',
          accent: true,
        ),
        _rail(
          loading: isLoadingBlogPosts,
          isEmpty: blogPosts.isEmpty,
          emptyTitle: 'No stories yet',
          emptyMessage: 'New reads are published regularly — check back soon.',
          height: 282,
          children: cards,
        ),
      ],
    );
  }


  Widget _buildViewAllInterestingReadsButton() {
    return _viewAllButton('View all Interesting reads', () {
      Navigator.push(
        context,
        AnimatedPageRoute(page: Ideas(initialSubTabIndex: 1)),
      );
    });
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
    final cards = <Widget>[];
    for (var index = 0; index < realWeddings.length; index++) {
      final wedding = realWeddings[index];
      final String imageUrl = wedding['cover_photo'] ?? "";
      final String title = wedding['title'] ?? "";
      final String city = wedding['city'] ?? "";
      final String date = wedding['wedding_date'] ?? "";

      cards.add(
        FadeSlideIn.staggered(
          index: index,
          offset: const Offset(0.08, 0),
          child: SizedBox(
            width: 200,
            child: AppCard(
              padding: EdgeInsets.zero,
              radius: AppRadii.lg,
              shadow: AppColors.shadowMd,
              onTap: () {
                Navigator.push(
                  context,
                  AnimatedPageRoute(
                    page: RealWeddingDetailPage(
                      wedding: RealWedding.fromJson(wedding),
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Wedding cover image + readability scrim
                  NetworkImageWidget(
                    url: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 520,
                    scrim: true,
                    placeholderIcon: Icons.photo_camera_back_outlined,
                  ),

                  // Text bottom area
                  Positioned(
                    bottom: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppText.cardTitle.copyWith(
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city,
                                style: AppText.caption.copyWith(
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (date.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            date,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Real Weddings We Love',
          subtitle: 'Inspiration from couples like you',
          accent: true,
        ),
        _rail(
          loading: isLoadingRealWeddings,
          isEmpty: realWeddings.isEmpty,
          emptyTitle: 'No real weddings yet',
          emptyMessage: 'Beautiful stories are on their way.',
          height: 230,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildViewAllRealWeddingsButton() {
    return _viewAllButton('View all Real Weddings', () {
      Navigator.push(
        context,
        AnimatedPageRoute(page: Ideas(initialSubTabIndex: 2)),
      );
    });
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

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on_rounded,
      label: 'Venues',
    ),
    _NavItem(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'Studio',
      isCenter: true,
    ),
    _NavItem(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Vendors',
    ),
    _NavItem(
      icon: Icons.menu_rounded,
      activeIcon: Icons.menu_open_rounded,
      label: 'More',
    ),
  ];

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),






        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final selected = _selectedIndex == index;

              return Expanded(
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.label,
                  child: InkWell(
                    onTap: () => _onItemTapped(index),
                    splashColor: Colors.white24,
                    highlightColor: Colors.white10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item.isCenter)
                          // Raised centre action keeps the Design Studio
                          // prominent, as before.
                          AnimatedScale(
                            scale: selected ? 1.06 : 1,
                            duration: AppMotion.fast,
                            curve: AppMotion.standard,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: AppColors.shadowSm,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/tryimg.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.auto_awesome,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: Icon(
                              selected ? item.activeIcon : item.icon,
                              key: ValueKey(selected),
                              size: 23,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.66),
                            ),
                          ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: AppMotion.fast,
                          style: AppText.caption.copyWith(
                            fontSize: 10.5,
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.66),
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Active indicator
                        AnimatedContainer(
                          duration: AppMotion.fast,
                          curve: AppMotion.standard,
                          margin: const EdgeInsets.only(top: 3),
                          height: 2.5,
                          width: selected ? 18 : 0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCenter = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isCenter;
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
                            color: Colors.black.withValues(alpha: 0.1),
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
                            child: NetworkImageWidget(url: image, height: 200, width: double.infinity, fit: BoxFit.cover),
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
class HomeShimmerOverlay extends StatelessWidget {
  const HomeShimmerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white.withValues(alpha: 0.95),
      child: SafeArea(
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 🔹 Header placeholder
                Container(
                  height: 60,
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔹 Category cards
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        height: 90,
                        margin: EdgeInsets.only(
                          right: index == 2 ? 0 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 30),

                /// 🔹 Section title
                Container(height: 16, width: 180, color: Colors.white),

                const SizedBox(height: 16),

                /// 🔹 Horizontal list shimmer
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, __) => Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: 16),
                    itemCount: 4,
                  ),
                ),

                const SizedBox(height: 30),

                /// 🔹 Large card
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
