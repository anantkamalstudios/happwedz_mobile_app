import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:happy_wedz/Bottombars/HomeScreen.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' show MultiProvider, ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'Wishlist/Wishlistscreen.dart';

import 'ai_chat_screen/ai_chat_screen.dart';

import 'guestlist/guestlist.dart';
import 'internetconnection.dart';


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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(
          create: (_) => ChatProvider()..setUserId(savedUserId),
        ),
      ],
      child: const MyApp(),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const ConnectivityOverlay(), // shows/hides automatically
          ],
        );
      },
      home: const AuthWrapper(),
    );
  }
}

/// ✅ AuthWrapper checks if user is already logged in
// ✅ AuthWrapper (decides if logged in or not)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Always start app for everyone (guest or logged in)
    return const BottomBars();
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // clientId:
    //   '5404414440-cpfrtjjfh6maga878im03li5lmpqga30.apps.googleusercontent.com'
  );

  Future<void> _signInWithGoogle() async {
    print('🟡 Starting Google Sign-In process...');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('🟢 Google User result: $googleUser');

      if (googleUser == null) {
        _showSnackBar('Google Sign-In cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      print('🌐 Sending POST request to API...');
      final response = await http.post(
        Uri.parse('https://happywedz.com/api/user/google-auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'name': googleUser.displayName ?? 'Guest User',
          'tokenId': googleAuth.idToken ?? '',
        }),
      );
      print('tokenId: ${googleAuth.idToken}');
      print('🟢 API Response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final user = data['user'];
          final token = data['token'];

          // ✅ Save data locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('user_id', user['id']);
          await prefs.setString('user_name', user['name']);
          await prefs.setString('user_email', user['email']);
          await prefs.setString('user_phone', user['phone'] ?? '');

          await prefs.setString('auth_token', token);
          await prefs.setString('user_photo', googleUser.photoUrl ?? '');

          // 👇 Save login time (for 2 days expiry)
          await prefs.setString('token_saved_at', DateTime.now().toIso8601String());
          _showSnackBar('Welcome ${user['name']}');
          print("user_id: ${user['id']}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomBars()),
          );
        } else {
          _showSnackBar('Login failed: ${data['message']}');
        }
      } else {
        _showSnackBar('Server Error: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('🚨 Google Sign-In failed: $e');
      print(stack);
      _showSnackBar('Google Sign-In failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFE91E63),
    ));
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign In / Sign Up',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 50),
                  OutlinedButton.icon(
                    onPressed: _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    icon: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                      width: 24,
                      height: 24,
                    ),
                    label: Text(
                      'Continue with Google',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF424242),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Looking for a Business Account?',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: const Color(0xFF00ACC1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}





// class TruecallerScreen extends StatelessWidget {
//   final Map<String, String> userData;
//
//   const TruecallerScreen({Key? key, required this.userData}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final String displayName = userData['name'] ?? '';
//     final String contact = userData['phone'] ?? userData['email'] ?? '';
//     final String method = userData['method'] ?? '';
//
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),
//               Color(0xFFFFB6C1),
//               Colors.white,
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Stack(
//             children: [
//               // Decorative bunting at top
//               Positioned(
//                 top: 0,
//                 right: 0,
//                 child: Image.network(
//                   'https://cdn-icons-png.flaticon.com/512/2917/2917995.png',
//                   width: MediaQuery.of(context).size.width * 0.8,
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) => const SizedBox(),
//                 ),
//               ),
//               // Dimmed background overlay
//               Container(
//                 color: Colors.black.withOpacity(0.4),
//               ),
//               // Bottom sheet
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(25),
//                       topRight: Radius.circular(25),
//                     ),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(30),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Dynamic user name
//                         Text(
//                           'Hi, $displayName',
//                           style: GoogleFonts.poppins(
//                             fontSize: 28,
//                             fontWeight: FontWeight.w600,
//                             color: const Color(0xFF424242),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           'To get started, please login/signup',
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                         const SizedBox(height: 30),
//                         // Continue button showing dynamic phone/email
//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const UserRoleScreen(),
//                               ),
//                             );
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFE91E63),
//                             minimumSize: const Size(double.infinity, 60),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(15),
//                             ),
//                             elevation: 0,
//                           ),
//                           child: Text(
//                             'CONTINUE WITH $contact',
//                             style: GoogleFonts.poppins(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         // "Use another method" button
//                         Center(
//                           child: TextButton(
//                             onPressed: () {
//                               // Navigate back to SignInScreen for alternate method
//                               Navigator.pop(context, false);
//                             },
//                             child: Text(
//                               'USE ANOTHER METHOD',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: Colors.grey.shade500,
//                                 fontWeight: FontWeight.w500,
//                                 letterSpacing: 0.5,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 15),
//                         // Info text
//                         RichText(
//                           text: TextSpan(
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               color: Colors.grey.shade500,
//                             ),
//                             children: const [
//                               TextSpan(
//                                 text: 'By continuing you consent to share your Truecaller profile information with ',
//                               ),
//                               TextSpan(
//                                 text: 'Happy Wedz',
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                               TextSpan(text: ', and agree to the '),
//                               TextSpan(
//                                 text: 'privacy policy',
//                                 style: TextStyle(
//                                   color: Color(0xFF00ACC1),
//                                   decoration: TextDecoration.underline,
//                                 ),
//                               ),
//                               TextSpan(text: ' and '),
//                               TextSpan(
//                                 text: 'terms of service',
//                                 style: TextStyle(
//                                   color: Color(0xFF00ACC1),
//                                   decoration: TextDecoration.underline,
//                                 ),
//                               ),
//                               TextSpan(text: ' of '),
//                               TextSpan(
//                                 text: 'Happy Wedz',
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                               TextSpan(text: '.'),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         // Instant verification info
//                         Center(
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 'Instant Verification by ',
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 13,
//                                   color: Colors.grey.shade600,
//                                 ),
//                               ),
//                               Image.network(
//                                 'https://cdn-icons-png.flaticon.com/512/732/732221.png',
//                                 height: 20,
//                                 errorBuilder: (context, error, stackTrace) => Text(
//                                   'Truecaller',
//                                   style: GoogleFonts.poppins(
//                                     fontSize: 13,
//                                     color: const Color(0xFF2196F3),
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

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
                  // Back button
                  // Padding(
                  //   padding: const EdgeInsets.all(20),
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       Navigator.pushAndRemoveUntil(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => const BottomBars(), // 👉 main screen
                  //         ),
                  //             (route) => false, // clear all previous routes
                  //       );
                  //     },
                  //     child: Container(
                  //       width: 50,
                  //       height: 50,
                  //       decoration: BoxDecoration(
                  //         color: Colors.white.withOpacity(0.9),
                  //         shape: BoxShape.circle,
                  //       ),
                  //       child: const Icon(
                  //         Icons.arrow_back_ios_new,
                  //         color: Color(0xFF424242),
                  //         size: 20,
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                      color: Colors.white.withOpacity(0.9),
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
              color: Colors.black.withOpacity(0.05),
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
                          color: Colors.white.withOpacity(0.9),
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
                      color: Colors.white.withOpacity(0.9),
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
                          color: Colors.white.withOpacity(0.9),
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
                      MaterialPageRoute(builder: (context) => const BottomBars()),
                          (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
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
            MaterialPageRoute(builder: (context) => const BottomBars()),
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
              color: Colors.black.withOpacity(0.05),
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































































// 👇 Don't import signin_screen.dart since it's already in main.dart

Future<bool> ensureLoggedIn(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token != null && token.isNotEmpty) {
    return true; // ✅ already logged in
  }

  // 🚫 not logged in → go to SignInScreen (which is defined below in main.dart)
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SignInScreen()),
  );

  return result == true; // ✅ if login succeeded
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







class AuthUtils {
  static const int tokenExpiryDays = 2;

  // Check if token expired
  static Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAt = prefs.getString('token_saved_at');

    if (savedAt == null) return true; // No token saved

    final savedTime = DateTime.parse(savedAt);
    final now = DateTime.now();

    final difference = now.difference(savedTime).inDays;

    return difference >= tokenExpiryDays;
  }

  // Logout function
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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



//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   bool _isLoading = false;       // For showing a loading spinner
//   User? _user;                   // Stores the logged-in user
//   String? _errorMessage;         // Stores login errors
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _login() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(
//           email: _emailController.text,
//           password: _passwordController.text);
//
//       if (!mounted) return;
//
//       setState(() {
//         _isLoading = false;
//         _user = userCredential.user;
//       });
//
//       // Navigate to home
//       Navigator.pushReplacement(
//           context, MaterialPageRoute(builder: (_) => HomeScreen()));
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _isLoading = false;
//         _errorMessage = e.toString();
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Login")),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(
//               controller: _emailController,
//               decoration: const InputDecoration(labelText: "Email"),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               decoration: const InputDecoration(labelText: "Password"),
//             ),
//             const SizedBox(height: 24),
//             if (_errorMessage != null)
//               Text(
//                 _errorMessage!,
//                 style: const TextStyle(color: Colors.red),
//               ),
//             const SizedBox(height: 24),
//             _isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//               onPressed: _login,
//               child: const Text("Login"),
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
// rules_version = '2';
//
// service cloud.firestore {
// match /databases/{database}/documents {
// match /{document=**} {
// allow read, write: if
// request.time < timestamp.date(2025, 11, 6);
// }
// }
// }





// gt7crz05tgi0o3mk10wimjig0irao0fr7xgsljqdfh8