import 'package:flutter/material.dart';

import 'custome_theme.dart';
import 'movment_plus_dashboard.dart';
class GuestTokenScreen extends StatelessWidget {
  const GuestTokenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
        const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [

              /// ================= APP BAR (WISHLIST STYLE) =================
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Movment Plus",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              /// ================= MOMENT HEADER =================
              Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  height: 90,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppTheme.premiumCard(),
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
                          crossAxisAlignment: CrossAxisAlignment.center, // ✅ CENTER
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
                                      color: AppTheme.primaryColor, // #C31162
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

              const SizedBox(height: 10),

              /// ================= MAIN CARD =================
              Expanded(
                child: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      height: 450,
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 22),
                      decoration: AppTheme.premiumCard(
                        border:
                        Border.all(color: AppTheme.pink, width: 1),
                      ),
                      child: Column(
                        children: [

                          /// LOCK ICON
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.cardPink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.lock,
                                color: AppTheme.pink, size: 32),
                          ),

                          const SizedBox(height: 14),

                          const Text(
                            "Access Private Gallery",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            "Enter your unique access code to view your private wedding photos",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.black54),
                          ),

                          const SizedBox(height: 22),

                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Access Token",
                              style:
                              TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),

                          const SizedBox(height: 6),

                          TextField(
                            decoration: InputDecoration(
                              hintText:
                              "Enter Token (eg. ABCD5U89)",
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: AppTheme.pinkButton(),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const MomentGalleryHome(),
                                  ),
                                );
                              },
                              child: const Text("View Gallery", style: TextStyle(color: Colors.white),),
                            ),
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            "Your access token code was provided by your photographer",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.black45),
                          ),

                          const SizedBox(height: 30),

                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: const [
                              Icon(Icons.info_outline,
                                  size: 16,
                                  color: Colors.grey),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Token are case-sensitive and typically contain letters and numbers",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45),
                                ),
                              ),
                            ],
                          ),
                        ],
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

/// =======================================================
/// MOMENT GALLERY HOME

class _RecentMomentCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const _RecentMomentCard({
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: Moment_plus_home().premiumCard(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),

            /// TITLE
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class MomentGalleryHome extends StatelessWidget {
  const MomentGalleryHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
        const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Movment Plus",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [

                    /// ================= MOMENT HEADER =================
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        height: 90,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: AppTheme.premiumCard(),
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
                                            color: AppTheme
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

                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        "Smith & Johnson Wedding",
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "August 15, 2024",
                        style:
                        TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ================= VERTICAL MOMENT CARDS =================
                    const _RecentMomentCard(
                      imageUrl: "assets/images/moment_img.png",
                      title: "Ceremony Detail",
                    ),
                    const _RecentMomentCard(
                      imageUrl: "assets/images/moment_img.png",
                      title: "Guest Celebration",
                    ),
                    const _RecentMomentCard(
                      imageUrl: "assets/images/moment_img.png",
                      title: "Venue View",
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
}

