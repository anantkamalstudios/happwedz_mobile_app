import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'custome_theme.dart';

// import 'custome_theme.dart';

class Moment_plus_home extends StatefulWidget {
  const Moment_plus_home({super.key});

  // ===== THEME (SAME AS WISHLIST) =====
  static const Color pink = Color(0xFFFF69B4);
  static const Color lightPink = Color(0xFFFFB6C1);
  static const Color cardPink = Color(0xFFFFEFF5);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [pink, lightPink, Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0, 0.3, 0.6],
  );

  @override
  State<Moment_plus_home> createState() => _Moment_plus_homeState();

  BoxDecoration premiumCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Moment_plus_home.cardPink, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      // borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _Moment_plus_homeState extends State<Moment_plus_home> {
  int _currentIndex = 0;
  int _heroIndex = 0;

  BoxDecoration Card() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Moment_plus_home.cardPink, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget pinkGradientButton({
    required String text,
    required VoidCallback onPressed,
    bool showArrow = false, // 👈 default false
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFC31162), Color(0xFFE83580)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),

            /// 👇 Arrow only when needed
            if (showArrow) ...[
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/Arroww.png',
                width: 16,
                height: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
  late Future<CoupleData> _coupleFuture;

  @override
  void initState() {
    super.initState();
    _coupleFuture = fetchCoupleSays();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const cardWidth = 300;
    const separatorWidth = 35;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Moment_plus_home.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              /// ================= APP BAR (SAME AS WISHLIST) =================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Moments",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // balance space
                  ],
                ),
              ),

              /// ================= BODY =================
              Expanded(
                child: ListView(
                  children: [
                    /// -------- TOP MOMENT HEADER CARD --------
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        height: 90,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: MpTheme.premiumCard(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// CAMERA IMAGE
                            Image.asset(
                              "assets/images/cam_moment.png",
                              height: 78,
                              fit: BoxFit.contain,
                            ),

                            /// TEXT (EXACT LIKE DESIGN)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.center, // ✅ CENTER
                                children: [
                                  /// MOMENT (CENTER)
                                  const Text(
                                    "Moment+",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  /// SHARE YOUR PHOTOS (CENTER + HIGHLIGHT)
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      children: [
                                        const TextSpan(text: "Share your "),
                                        TextSpan(
                                          text: "photos",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            color: MpTheme
                                                .primaryColor, // #C31162
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SizedBox(height: 20,),
                    /// -------- HERO IMAGE --------
                    // Image.asset(
                    //   "assets/images/moment2.png",
                    //   height: 220,
                    //   width: double.infinity,
                    //   fit: BoxFit.cover,
                    // ),
                    CarouselSlider(
                      items: [
                        "assets/images/moment2.png",
                        "assets/images/moment2.png",
                        "assets/images/moment2.png",
                      ].map((image) {
                        return Image.asset(
                          image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }).toList(),

                      options: CarouselOptions(
                        height: 220,
                        viewportFraction: 1,
                        autoPlay: true,
                        onPageChanged: (index, _) {
                          setState(() => _heroIndex = index);
                        },
                      ),
                    ),
                    SizedBox(height: 5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        3,
                            (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: _heroIndex == index ? 18 : 6,
                          decoration: BoxDecoration(
                            color: _heroIndex == index
                                ? Colors.pink
                                : Colors.pinkAccent.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    /// -------- TITLE --------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            "Every Wedding Moment, Perfectly Delivered.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: MpTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "View photos shared by your photographer",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      "Received an invite ?",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    SizedBox(height: 6),

                    /// -------- ACCESS CODE BUTTON --------
                    Center(
                      child: pinkGradientButton(
                        text: "Have a private access code?",
                        onPressed: () {},
                        showArrow: true,
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// -------- RECENT MOMENTS --------
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Recent Wedding Moments",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
          SizedBox(
            height: 419 + 75,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,

              /// 👇 THIS IS THE KEY FIX
              padding: EdgeInsets.symmetric(
                horizontal: (screenWidth - cardWidth) / 2,
              ),

              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 35),
              itemBuilder: (context, index) {
                return const _RecentMomentCard(
                  imageUrl: "assets/images/moment_img.png",
                  title: "Smith Wedding",
                );
              },
            ),
          ),
                    const SizedBox(height: 40),

                    /// -------- INSTANT PHOTOS AI --------
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Instant photos, powered by AI",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          _StepsRow(),
                        ],
                      ),
                    ),
                    SizedBox(height: 10,),
                    /// -------- EVENT CREATION CARD --------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: Card(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Event Creation Made Easy",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _arrowText("Set up your main event"),
                            SizedBox(height: 18,),
                            _arrowText("Organize sub-events and schedules"),
                            SizedBox(height: 18,),
                            _arrowText(
                              "Invite co-hosts and assign admin access",
                            ),
                            const SizedBox(height: 22),
                            Center(
                              child: pinkGradientButton(
                                text: "Try Now",
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// -------- SMART SHARING --------
                    // Stack(
                    //   children: [
                    //     Image.asset(
                    //       "assets/images/moment3.png",
                    //       height: 260,
                    //       width: double.infinity,
                    //       fit: BoxFit.cover,
                    //     ),
                    //     Positioned.fill(
                    //       child: Align(
                    //         alignment: Alignment.center,
                    //         child: Container(
                    //           margin: const EdgeInsets.all(20),
                    //           padding: const EdgeInsets.all(16),
                    //           decoration: premiumCard().copyWith(
                    //             border: Border.all(color: pink),
                    //           ),
                    //           child: Column(
                    //             mainAxisSize: MainAxisSize.min,
                    //             children: [
                    //               const Text(
                    //                 "Smart photo sharing powered by AI",
                    //                 style: TextStyle(
                    //                   fontWeight: FontWeight.bold,
                    //                 ),
                    //               ),
                    //               const SizedBox(height: 8),
                    //               _starText("Get photos privately"),
                    //               _starText(
                    //                 "Get your photos on Email / WhatsApp",
                    //               ),
                    //               const SizedBox(height: 12),
                    //               pinkGradientButton(
                    //                 text: "Free Signup",
                    //                 onPressed: () {},
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
          Stack(
            children: [
              Image.asset(
                "assets/images/moment3.png",
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),

              /// CENTER CARD
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: premiumCard().copyWith(
                      border: Border.all(color: Moment_plus_home.pink),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Smart photo sharing powered by AI",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MpTheme.primaryColor
                          ),
                        ),
                        const SizedBox(height: 12),
                        _starText("Get photos privately"),
                        const SizedBox(height: 12),
                        _starText("Get your photos on Email / WhatsApp"),
                        const SizedBox(height: 16),
                        pinkGradientButton(
                          text: "Free Signup",
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// 📸 CAMERA FRAME CORNERS
              cameraCorner(top: true, left: true),
              cameraCorner(top: true, left: false),
              cameraCorner(top: false, left: true),
              cameraCorner(top: false, left: false),
            ],
          ),


          const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "What our Customer's Say",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    /// -------- CUSTOMER REVIEW --------
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Container(
          //     padding: const EdgeInsets.all(16),
          //     decoration: premiumCard(),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //
          //         /// 👤 USER + RATING ROW
          //         Row(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             const CircleAvatar(
          //               radius: 18,
          //               backgroundImage: NetworkImage(
          //                 "https://randomuser.me/api/portraits/women/44.jpg",
          //               ),
          //             ),
          //             const SizedBox(width: 10),
          //
          //             Expanded(
          //               child: Column(
          //                 crossAxisAlignment: CrossAxisAlignment.start,
          //                 children: const [
          //                   Text(
          //                     "Kristin Watson",
          //                     style: TextStyle(
          //                       fontWeight: FontWeight.w600,
          //                       fontSize: 14,
          //                     ),
          //                   ),
          //                   SizedBox(height: 2),
          //                   Text(
          //                     "Pune",
          //                     style: TextStyle(
          //                       fontSize: 12,
          //                       color: Colors.grey,
          //                     ),
          //                   ),
          //                 ],
          //               ),
          //             ),
          //
          //             /// ⭐ STARS
          //             Row(
          //               children: List.generate(
          //                 5,
          //                     (index) => Icon(
          //                   Icons.star,
          //                   size: 16,
          //                   color: index < 3 ? Colors.orange : Colors.grey.shade300,
          //                 ),
          //               ),
          //             ),
          //           ],
          //         ),
          //
          //         const SizedBox(height: 12),
          //
          //         /// 📝 TITLE
          //         const Text(
          //           "A Beachside Wedding Dipped In Pastels, Sunshine & A Decade Of Love!",
          //           style: TextStyle(
          //             fontSize: 15,
          //             fontWeight: FontWeight.w600,
          //           ),
          //         ),
          //
          //         const SizedBox(height: 8),
          //
          //         /// 📄 DESCRIPTION
          //         const Text(
          //           "Anisha & Harshits mehendi was nothing short of a heartwarming throwback. "
          //               "Taking inspiration from the warmth and joy of childhood summers spent "
          //               "at their Nani Ghar, the couple designed a celebration...",
          //           style: TextStyle(
          //             fontSize: 13,
          //             color: Colors.grey,
          //             height: 1.5,
          //           ),
          //         ),
          //
          //         const SizedBox(height: 12),
          //
          //         /// 👍 HELPFUL + DATE
          //         Row(
          //           children: const [
          //             Text(
          //               "Helpful?",
          //               style: TextStyle(fontSize: 12, color: Colors.grey),
          //             ),
          //             SizedBox(width: 8),
          //             Text(
          //               "Yes (2)",
          //               style: TextStyle(fontSize: 12),
          //             ),
          //             SizedBox(width: 12),
          //             Text(
          //               "NO (0)",
          //               style: TextStyle(fontSize: 12),
          //             ),
          //             Spacer(),
          //             Text(
          //               "Nov 12, 2022",
          //               style: TextStyle(fontSize: 12, color: Colors.grey),
          //             ),
          //           ],
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
                    FutureBuilder<CoupleData>(
                      future: _coupleFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return coupleShimmerCarousel(); // 👈 shimmer here
                        }

                        if (!snapshot.hasData) return const SizedBox();

                        final data = snapshot.data!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text(
                            //   data.heading,
                            //   style: const TextStyle(
                            //     fontSize: 20,
                            //     fontWeight: FontWeight.bold,
                            //   ),
                            // ),
                            // const SizedBox(height: 4),
                            // Text(
                            //   data.subHeading,
                            //   style: const TextStyle(color: Colors.grey),
                            // ),

                            // const SizedBox(height: 16),

                            // CarouselSlider(
                            //   items: data.sections
                            //       .map((section) => coupleSayCard(section))
                            //       .toList(),
                            //   options: CarouselOptions(
                            //     height: 210,
                            //     viewportFraction: 0.9,
                            //     enlargeCenterPage: true,
                            //     autoPlay: true,
                            //   ),
                            // ),
                        Column(
                        children: [
                        CarouselSlider(
                        items: data.sections
                            .map((section) => coupleSayCard(context, section))
                            .toList(),
                        options: CarouselOptions(
                        height: 210,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        onPageChanged: (index, _) {
                        setState(() => _currentIndex = index);
                        },
                        ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                        data.sections.length,
                        (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 18 : 8,
                        decoration: BoxDecoration(
                        color: _currentIndex == index
                        ? const Color(0xFFE91E63)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                        ),
                        ),
                        ),
                        ),
                        ],
                        ),

                        ],
                        );
                      },
                    ),

          const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget coupleSayCard(BuildContext context, CoupleSection section) {
    return GestureDetector(
      onTap: () => _showFullReview(context, section),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: premiumCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 👤 USER + RATING
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(section.img),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),

                Row(
                  children: List.generate(
                    5,
                        (index) => Icon(
                      Icons.star,
                      size: 16,
                      color: index < section.stars
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// 📝 DESCRIPTION (TRUNCATED)
            Text(
              section.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showFullReview(BuildContext context, CoupleSection section) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// 👤 USER HEADER
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(section.img),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// ⭐ RATING
                Row(
                  children: List.generate(
                    5,
                        (index) => Icon(
                      Icons.star,
                      size: 18,
                      color: index < section.stars
                          ? Colors.orange
                          : Colors.grey.shade300,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// 📝 FULL DESCRIPTION
                SingleChildScrollView(
                  child: Text(
                    section.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// ❌ CLOSE BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<CoupleData> fetchCoupleSays() async {
    final response = await http.get(
      Uri.parse("https://happywedz.com/api/what-couples-says-route"),
    );
    print(response);
    final jsonData = json.decode(response.body);
    print(response.body);
    return CoupleSayResponse.fromJson(jsonData).data;
  }

  BoxDecoration premiumCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Moment_plus_home.cardPink, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      // borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.pink.withOpacity(0.15),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Widget coupleShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// Avatar + name + stars
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  height: 14,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 10),

              Container(height: 14, width: 60, color: Colors.white),
            ],
          ),

          const SizedBox(height: 16),

          /// Description lines
          Container(height: 12, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 12, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 12, width: 150, color: Colors.white),
        ],
      ),
    );
  }
  Widget coupleShimmerCarousel() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CarouselSlider(
        items: List.generate(
          3,
              (_) => coupleShimmerCard(),
        ),
        options: CarouselOptions(
          height: 210,
          viewportFraction: 0.9,
          enlargeCenterPage: true,
          autoPlay: true,
        ),
      ),
    );
  }

}

/// ================= STEPS =================

class _StepsRow extends StatelessWidget {
  const _StepsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _StepItem("1", "Create Event", true),
        _StepLine(),
        _StepItem("2", "Share Event", true),
        _StepLine(),
        _StepItem("3", "Media Uploads", false),
        _StepLine(),
        _StepItem("4", "Upload Selfie", false),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number, title;
  final bool active;

  const _StepItem(this.number, this.title, this.active);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active
              ? Moment_plus_home.pink
              : Colors.grey.shade300,
          child: Text(
            number,
            style: TextStyle(color: active ? Colors.white : Colors.black),
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(height: 2, color: Moment_plus_home.pink));
  }
}

Widget _arrowText(String text) => Row(
  children: [
    const Text(">"),
    const SizedBox(width: 6),
    Expanded(child: Text(text)),
  ],
);

Widget _starText(String text) => Row(
  children: [
    const Icon(Icons.star, size: 14, color: Moment_plus_home.pink),
    const SizedBox(width: 6),
    Expanded(child: Text(text)),
  ],
);

class _RecentMomentCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _RecentMomentCard({required this.imageUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300, // exact width
      child: Container(
        decoration: Moment_plus_home().premiumCard(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE (exact height)
            SizedBox(
              height: 419,
              width: double.infinity,
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),

            /// TITLE CONTAINER (exact 99 height)
            SizedBox(
              height: 69,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
Widget cameraCorner({
  required bool top,
  required bool left,
  Color color = Colors.white,
}) {
  return Positioned(
    top: top ? 14 : null,
    bottom: top ? null : 14,
    left: left ? 50 : null,
    right: left ? null : 50,
    child: Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: 2) : BorderSide.none,
          bottom: top ? BorderSide.none : BorderSide(color: color, width: 2),
          left: left ? BorderSide(color: color, width: 2) : BorderSide.none,
          right: left ? BorderSide.none : BorderSide(color: color, width: 2),
        ),
      ),
    ),
  );
}
class CoupleSayResponse {
  final bool success;
  final CoupleData data;

  CoupleSayResponse({required this.success, required this.data});

  factory CoupleSayResponse.fromJson(Map<String, dynamic> json) {
    return CoupleSayResponse(
      success: json['success'],
      data: CoupleData.fromJson(json['data']),
    );
  }
}

class CoupleData {
  final String heading;
  final String subHeading;
  final List<CoupleSection> sections;

  CoupleData({
    required this.heading,
    required this.subHeading,
    required this.sections,
  });

  factory CoupleData.fromJson(Map<String, dynamic> json) {
    return CoupleData(
      heading: json['heading'],
      subHeading: json['subHeading'],
      sections: (json['sections'] as List)
          .map((e) => CoupleSection.fromJson(e))
          .toList(),
    );
  }
}

class CoupleSection {
  final String img;
  final String title;
  final int stars;
  final String description;

  CoupleSection({
    required this.img,
    required this.title,
    required this.stars,
    required this.description,
  });

  factory CoupleSection.fromJson(Map<String, dynamic> json) {
    return CoupleSection(
      img: json['img'],
      title: json['title'],
      stars: json['stars'],
      description: json['description'],
    );
  }
}
