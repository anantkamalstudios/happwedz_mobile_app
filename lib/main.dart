import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/Bottombars/HomeScreen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
      theme: ThemeData(

        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  TravelPromoScreen(),
    );
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
        MaterialPageRoute(builder: (context) => const BottomBars()),
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
                  Image.network(
                    'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fc1b3759a213819470729c75cb198cc23ca254ad4image%204.png?alt=media&token=3f5e24ec-7683-4afe-94ee-f747b85c49b4',
                    height: screenHeight * 0.08,
                  ),
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
        child: Image.network(
          url,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}




//
//
//
// class WeddingPlanningScreen extends StatelessWidget {
//   const WeddingPlanningScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFE91E63), // Pink
//               Color(0xFFD81B60), // Slightly darker pink
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // Top overlapping images cluster
//               Positioned(
//                 top: 60,
//                 left: 0,
//                 right: 0,
//                 child: _buildTopImageCluster(),
//               ),
//
//               // Bottom overlapping images cluster
//               Positioned(
//                 bottom: 100,
//                 left: 0,
//                 right: 0,
//                 child: _buildBottomImageCluster(),
//               ),
//
//               // Center content
//               Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     // Logo with scissors/rings icon
//                     Container(
//                       width: 60,
//                       height: 60,
//                       decoration: BoxDecoration(
//                         color: Colors.transparent,
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Image.asset('assets/image 4.png')
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     // Brand name
//                     const Text(
//                       'HAPPY WED',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         letterSpacing: 1.5,
//                       ),
//                     ),
//
//                     const SizedBox(height: 40),
//
//                     // Main heading
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 40),
//                       child: Text(
//                         'We want to make your\nwedding planning\nprocess super easy!',
//                         style: TextStyle(
//                           color: Color(0xFF1A237E), // Dark blue
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           height: 1.3,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//
//                     const SizedBox(height: 25),
//
//                     // Services text
//                     const Padding(
//                       padding: EdgeInsets.symmetric(horizontal: 50),
//                       child: Text(
//                         'Wedding Photographers in India | Bridal Makeup Artists in India | Wedding Cards in India | Wedding Venues in India',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w400,
//                           height: 1.4,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTopImageCluster() {
//     return SizedBox(
//       height: 120,
//       child: Stack(
//         children: [
//           // First image (leftmost, behind)
//           Positioned(
//             left: 40,
//             top: 0,
//             child: _buildPhotoCard(
//               'assets/Rectangle 20.png',
//               width: 100,
//               height: 80,
//               rotation: -0.1,
//             ),
//           ),
//           // Second image (overlapping first, in front)
//           Positioned(
//             left: 110,
//             top: 10,
//             child: _buildPhotoCard(
//               'assets/Rectangle 22.png',
//               width: 100,
//               height: 80,
//               rotation: 0.05,
//             ),
//           ),
//           // Third image (separate, with space)
//           Positioned(
//             right: 110,
//             top: 10,
//             child: _buildPhotoCard(
//               'assets/Rectangle 23.png',
//               width: 100,
//               height: 80,
//               rotation: -0.05,
//             ),
//           ),
//           // Fourth image (overlapping third)
//           Positioned(
//             right: 40,
//             top: 0,
//             child: _buildPhotoCard(
//               'assets/Rectangle 24.png',
//               width: 100,
//               height: 80,
//               rotation: 0.1,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildBottomImageCluster() {
//     return SizedBox(
//       height: 120,
//       child: Stack(
//         children: [
//           // First image (leftmost, behind)
//           Positioned(
//             left: 40,
//             bottom: 0,
//             child: _buildPhotoCard(
//               'assets/image.png',
//               width: 100,
//               height: 80,
//               rotation: 0.1,
//             ),
//           ),
//           // Second image (overlapping first, in front)
//           Positioned(
//             left: 110,
//             bottom: 10,
//             child: _buildPhotoCard(
//               'assets/Rectangle 25.png',
//               width: 100,
//               height: 80,
//               rotation: -0.05,
//             ),
//           ),
//           // Third image (separate, with space)
//           Positioned(
//             right: 110,
//             bottom: 10,
//             child: _buildPhotoCard(
//               'assets/Rectangle 26.png',
//               width: 100,
//               height: 80,
//               rotation: 0.05,
//             ),
//           ),
//           // Fourth image (overlapping third)
//           Positioned(
//             right: 40,
//             bottom: 0,
//             child: _buildPhotoCard(
//               'assets/Rectangle 22.png',
//               width: 100,
//               height: 80,
//               rotation: -0.1,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPhotoCard(String imagePath, {
//     required double width,
//     required double height,
//     double rotation = 0,
//   }) {
//     return Transform.rotate(
//       angle: rotation,
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.3),
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//           border: Border.all(
//             color: Colors.white.withOpacity(0.3),
//             width: 2,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(10),
//           child: Container(
//             color: Colors.white,
//             child:  Center(
//               child: Image.asset(
//                 imagePath,
//                 fit: BoxFit.cover,)
//             ),
//             // Replace with actual images:
//             // Image.asset(
//             //   imagePath,
//             //   fit: BoxFit.cover,
//             // ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// Splash Screen with Animation (MakeMyTrip style)
// class AnimatedWeddingSplash extends StatefulWidget {
//   const AnimatedWeddingSplash({Key? key}) : super(key: key);
//
//   @override
//   State<AnimatedWeddingSplash> createState() => _AnimatedWeddingSplashState();
// }
//
// class _AnimatedWeddingSplashState extends State<AnimatedWeddingSplash>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late AnimationController _scaleController;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//
//     _scaleController = AnimationController(
//       duration: const Duration(milliseconds: 2000),
//       vsync: this,
//     );
//
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
//     );
//
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
//     );
//
//     // Start animations
//     _fadeController.forward();
//     _scaleController.forward();
//
//     // Navigate after the animation duration
//     // Future.delayed(const Duration(milliseconds: 2000), () {
//     //   Navigator.pushReplacement(
//     //     context,
//     //     MaterialPageRoute(builder: (context) => const BottomBars()),
//     //   );
//     // });
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     _scaleController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
//       builder: (context, child) {
//         return Transform.scale(
//           scale: _scaleAnimation.value,
//           child: Opacity(
//             opacity: _fadeAnimation.value,
//             child: const WeddingPlanningScreen(),
//           ),
//         );
//       },
//     );
//   }
// }









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
        MaterialPageRoute(builder: (context) => BottomBars()), // replace with your screen
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









// SizedBox(height: 40),
// // Logo
// Center(
//   child: Row(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Text(
//         'make',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           fontSize: 20,
//           color: Colors.blue[900],
//         ),
//       ),
//       Container(
//         padding:
//         EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//         decoration: BoxDecoration(
//           color: Colors.red[400],
//           borderRadius: BorderRadius.circular(7),
//         ),
//         child: Text(
//           'my',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//       ),
//       Text(
//         'trip',
//         style: TextStyle(
//           fontWeight: FontWeight.w500,
//           fontSize: 20,
//           color: Colors.blue[900],
//         ),
//       ),
//     ],
//   ),
// ),
// SizedBox(height: 25),
// // Title and subtitle
// Center(
//   child: Text(
//     'Book India\n&',
//     textAlign: TextAlign.center,
//     style: TextStyle(
//         fontSize: 28,
//         fontWeight: FontWeight.w600,
//         color: Colors.grey[900]),
//   ),
// ),
// SizedBox(height: 8),
// Center(
//   child: Text(
//     'International Travel',
//     textAlign: TextAlign.center,
//     style: TextStyle(
//       fontSize: 26,
//       fontWeight: FontWeight.w700,
//       color: secondaryBlue,
//       fontStyle: FontStyle.italic,
//     ),
//   ),
// ),
// SizedBox(height: 10),
// Center(
//   child: Text(
//     "Flights, Stays, Visa, Forex & Attractions",
//     textAlign: TextAlign.center,
//     style: TextStyle(
//       fontSize: 18,
//       color: Colors.grey[900],
//     ),
//   ),
// ),


























































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
            color: Colors.black.withOpacity(0.1),
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
              color: Colors.white.withOpacity(0.7),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

// Main app widget


//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 5), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const SplashScreen2()),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       body: Container(
//         width: screenWidth,
//         height: screenHeight,
//         decoration: const BoxDecoration(
//           color: Color(0xFFE83580),
//         ),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             // Center logo
//             Positioned(
//               left: screenWidth * 0.26,
//               top: screenHeight * 0.33,
//               child: Image.network(
//                 'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fc1b3759a213819470729c75cb198cc23ca254ad4image%204.png?alt=media&token=3f5e24ec-7683-4afe-94ee-f747b85c49b4',
//                 width: screenWidth * 0.5,
//                 height: screenWidth * 0.5,
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             // Top-left image
//             Positioned(
//               left: 0,
//               top: screenHeight * 0.1,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2012.png?alt=media&token=1939ca1e-2736-4229-9a01-8672ef867f55',
//                   width: screenWidth * 0.23,
//                   height: screenHeight * 0.15,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             // Top-center left
//             Positioned(
//               left: screenWidth * 0.18,
//               top: screenHeight * 0.065,
//               child: Container(
//                 width: screenWidth * 0.28,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2013.png?alt=media&token=f2bcafb7-30c5-440b-8212-1e5aea6420bc',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             // Top-center right
//             Positioned(
//               left: screenWidth * 0.49,
//               top: screenHeight * 0.075,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F4855dbc515174bb64ccc4415740197965630aa87Rectangle%2014.png?alt=media&token=aae6fe19-6c3c-4a5d-b74a-fc9e578c5f79',
//                   width: screenWidth * 0.31,
//                   height: screenHeight * 0.18,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             // Top-right
//             Positioned(
//               left: screenWidth * 0.66,
//               top: screenHeight * 0.07,
//               child: Container(
//                 width: screenWidth * 0.28,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bRectangle%2015.png?alt=media&token=3b85bdf7-465a-4a11-b63b-1b87c4d73c0b',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             // Bottom-left small
//             Positioned(
//               left: -screenWidth * 0.03,
//               top: screenHeight * 0.77,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2016.png?alt=media&token=78af332f-b3a8-46ab-b567-67e6356d11bf',
//                   width: screenWidth * 0.28,
//                   height: screenHeight * 0.16,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             // Bottom-center left
//             Positioned(
//               left: screenWidth * 0.17,
//               top: screenHeight * 0.74,
//               child: Container(
//                 width: screenWidth * 0.29,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cRectangle%2017.png?alt=media&token=da23ed98-6571-412f-b82a-c48ef0e1a16a',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             // Bottom-center right
//             Positioned(
//               left: screenWidth * 0.5,
//               top: screenHeight * 0.75,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fdd166484d026f1e3e0d9d5d7393243d6ec850f54Rectangle%2018.png?alt=media&token=b77dc731-8674-4a1e-a093-75d5a5ef205b',
//                   width: screenWidth * 0.28,
//                   height: screenHeight * 0.16,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             // Bottom-right
//             Positioned(
//               left: screenWidth * 0.71,
//               top: screenHeight * 0.75,
//               child: Container(
//                 width: screenWidth * 0.28,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bRectangle%2019.png?alt=media&token=b9d064e0-e6bd-42e2-9a86-d043e0e4cdc4',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
// //
// //
// //
// // class SplashScreen2 extends StatelessWidget {
// //   const SplashScreen2({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: Container(
// //         width: MediaQuery.of(context).size.width,
// //         height: MediaQuery.of(context).size.height,
// //         clipBehavior: Clip.hardEdge,
// //         decoration: BoxDecoration(
// //           color: const Color(0xFFE83580),
// //           border: Border.all(),
// //         ),
// //         child: Stack(
// //           clipBehavior: Clip.none,
// //           children: [
// //             Positioned(
// //               left: -11,
// //               top: 715,
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(20),
// //                 child: Image.network(
// //                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F6f737faf306ed62da03bc66b0dbea6022f58d4a4Rectangle%2016.png?alt=media&token=76e1709c-6424-437d-93bb-d4bc580125d5',
// //                   width: 123,
// //                   height: 147,
// //                   fit: BoxFit.none,
// //                   alignment: const Alignment(0.232, 0),
// //                   scale: 21.008,
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 0,
// //               top: 94,
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(20),
// //                 child: Image.network(
// //                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2020.png?alt=media&token=3cfc6340-4ff8-4c13-b2b3-7df89845769c',
// //                   width: 100,
// //                   height: 130,
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 76,
// //               top: 61,
// //               child: Container(
// //                 width: 119,
// //                 height: 144,
// //                 decoration: BoxDecoration(
// //                   image: const DecorationImage(
// //                     image: NetworkImage(
// //                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2021.png?alt=media&token=319f7637-14a6-4a06-afd5-7b754ef63582',
// //                     ),
// //                     fit: BoxFit.cover,
// //                   ),
// //                   border: Border.all(width: 3, color: Colors.white),
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 209,
// //               top: 71,
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(20),
// //                 child: Image.network(
// //                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F4855dbc515174bb64ccc4415740197965630aa87Rectangle%2022.png?alt=media&token=4c27d685-7c86-4bee-b16b-32de454456a6',
// //                   width: 132,
// //                   height: 153,
// //                   fit: BoxFit.cover,
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 285,
// //               top: 66,
// //               child: Container(
// //                 width: 119,
// //                 height: 144,
// //                 decoration: BoxDecoration(
// //                   image: const DecorationImage(
// //                     image: NetworkImage(
// //                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bRectangle%2023.png?alt=media&token=bce49bb4-4daa-4242-a0dc-aa1d66dcf4b9',
// //                     ),
// //                     fit: BoxFit.cover,
// //                   ),
// //                   border: Border.all(width: 3, color: Colors.white),
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 73,
// //               top: 689,
// //               child: Container(
// //                 width: 125,
// //                 height: 148,
// //                 decoration: BoxDecoration(
// //                   image: const DecorationImage(
// //                     image: NetworkImage(
// //                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cRectangle%2025.png?alt=media&token=b99d4f7d-01ba-4ee6-bb6f-235ba45c7a41',
// //                     ),
// //                     fit: BoxFit.cover,
// //                   ),
// //                   border: Border.all(width: 3, color: Colors.white),
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 215,
// //               top: 698,
// //               child: ClipRRect(
// //                 borderRadius: BorderRadius.circular(20),
// //                 child: Image.network(
// //                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fdd166484d026f1e3e0d9d5d7393243d6ec850f54Rectangle%2026.png?alt=media&token=e342464e-5c61-45af-8369-5bdc5cec8cab',
// //                   width: 121,
// //                   height: 145,
// //                   fit: BoxFit.none,
// //                   alignment: const Alignment(0.139, 0),
// //                   scale: 11.108,
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 305,
// //               top: 696,
// //               child: Container(
// //                 width: 119,
// //                 height: 144,
// //                 decoration: BoxDecoration(
// //                   image: const DecorationImage(
// //                     image: NetworkImage(
// //                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bRectangle%2027.png?alt=media&token=cb23d679-90b2-4c26-b715-88044ce32579',
// //                     ),
// //                     fit: BoxFit.cover,
// //                   ),
// //                   border: Border.all(width: 3, color: Colors.white),
// //                   borderRadius: BorderRadius.circular(20),
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 32,
// //               top: 552,
// //               child: SizedBox(
// //                 width: 365,
// //                 child: Text(
// //                   'Wedding Photographers in India | Bridal Makeup Artists in India | Wedding Cards in India | Wedding Venues in India',
// //                   style: GoogleFonts.inter(
// //                     color: Colors.white,
// //                     fontSize: 10,
// //                     fontWeight: FontWeight.w300,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 40,
// //               top: 394,
// //               child: SizedBox(
// //                 width: 367,
// //                 child: Text(
// //                   'We want to make your wedding planning process super easy!',
// //                   style: GoogleFonts.poltawskiNowy(
// //                     fontSize: 33,
// //                     fontWeight: FontWeight.bold,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //             Positioned(
// //               left: 151,
// //               top: 264,
// //               child: Image.network(
// //                 'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fc1b3759a213819470729c75cb198cc23ca254ad4image%204.png?alt=media&token=48c623f1-9e0b-4a9f-aa34-a5c4e959624a',
// //                 width: 128,
// //                 height: 128,
// //                 fit: BoxFit.cover,
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
//
// class SplashScreen2 extends StatefulWidget {
//   const SplashScreen2({super.key});
//
//   @override
//   State<SplashScreen2> createState() => _SplashScreen2State();
// }
//
// class _SplashScreen2State extends State<SplashScreen2> {
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(const Duration(seconds: 5), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const SplashScreen2()),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//
//     return Scaffold(
//       body: Container(
//         width: screenWidth,
//         height: screenHeight,
//         decoration: const BoxDecoration(
//           color: Color(0xFFE83580),
//         ),
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             /// ---------------------------
//             /// Center logo
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.26,
//               top: screenHeight * 0.33,
//               child: Image.network(
//                 'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fc1b3759a213819470729c75cb198cc23ca254ad4image%204.png?alt=media&token=3f5e24ec-7683-4afe-94ee-f747b85c49b4',
//                 width: screenWidth * 0.5,
//                 height: screenWidth * 0.5,
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             /// ---------------------------
//             /// Top-left image
//             /// ---------------------------
//             Positioned(
//               left: 0,
//               top: screenHeight * 0.1,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2012.png?alt=media&token=1939ca1e-2736-4229-9a01-8672ef867f55',
//                   width: screenWidth * 0.23,
//                   height: screenHeight * 0.15,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Top-center left
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.18,
//               top: screenHeight * 0.065,
//               child: Container(
//                 width: screenWidth * 0.28,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F9c1e472683db909626bf6f5ae08a18d7fefd155bRectangle%2013.png?alt=media&token=f2bcafb7-30c5-440b-8212-1e5aea6420bc',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Top-center right
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.49,
//               top: screenHeight * 0.075,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F4855dbc515174bb64ccc4415740197965630aa87Rectangle%2014.png?alt=media&token=aae6fe19-6c3c-4a5d-b74a-fc9e578c5f79',
//                   width: screenWidth * 0.31,
//                   height: screenHeight * 0.18,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Top-right
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.66,
//               top: screenHeight * 0.07,
//               child: Container(
//                 width: screenWidth * 0.28,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bRectangle%2015.png?alt=media&token=3b85bdf7-465a-4a11-b63b-1b87c4d73c0b',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Bottom-left small
//             /// ---------------------------
//             Positioned(
//               left: -screenWidth * 0.03,
//               top: screenHeight * 0.77,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%2016.png?alt=media&token=78af332f-b3a8-46ab-b567-67e6356d11bf',
//                   width: screenWidth * 0.28,
//                   height: screenHeight * 0.16,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Bottom-center left
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.17,
//               top: screenHeight * 0.74,
//               child: Container(
//                 width: screenWidth * 0.29,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cRectangle%2017.png?alt=media&token=da23ed98-6571-412f-b82a-c48ef0e1a16a',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Bottom-center right
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.5,
//               top: screenHeight * 0.75,
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fdd166484d026f1e3e0d9d5d7393243d6ec850f54Rectangle%2018.png?alt=media&token=b77dc731-8674-4a1e-a093-75d5a5ef205b',
//                   width: screenWidth * 0.28,
//                   height: screenHeight * 0.16,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Bottom-right
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.71,
//               top: screenHeight * 0.75,
//               child: Container(
//                 width: screenWidth * 0.28,
//                 height: screenHeight * 0.17,
//                 decoration: BoxDecoration(
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bRectangle%2019.png?alt=media&token=b9d064e0-e6bd-42e2-9a86-d043e0e4cdc4',
//                     ),
//                     fit: BoxFit.cover,
//                   ),
//                   border: Border.all(width: 3, color: Colors.white),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Main Heading Text
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.1,
//               top: screenHeight * 0.55,
//               child: SizedBox(
//                 width: screenWidth * 0.8,
//                 child: Text(
//                   "We want to make your wedding\nplanning process super easy!",
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                     fontSize: screenWidth * 0.05,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//
//             /// ---------------------------
//             /// Bottom Info Text
//             /// ---------------------------
//             Positioned(
//               left: screenWidth * 0.08,
//               bottom: screenHeight * 0.30,
//               child: SizedBox(
//                 width: screenWidth * 0.85,
//                 child: Text(
//                   "Wedding Photographers in India | \nBridal Makeup Artists in India | \nWedding Cards in India | \nWedding Venues in India",
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.inter(
//                     fontSize: screenWidth * 0.03,
//                     fontWeight: FontWeight.w300,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
