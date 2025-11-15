import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:happy_wedz/Bottombars/HomeScreen.dart';

import 'package:hive_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' show MultiProvider, ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'LoadingLogo.dart';
import 'SplashScreen.dart';
import 'Wishlist/Wishlistscreen.dart';

import 'firebase_options.dart';
import 'guestlist/guestlist.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final status = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
  print('Google Play Services Status: $status');
  try {
    // Test Firestore
    await FirebaseFirestore.instance.collection('test').add({'timestamp': DateTime.now()});
    print('✅ Firestore write success');

    // Test Auth (anonymous sign in)
    await FirebaseAuth.instance.signInAnonymously();
    print('✅ Firebase Auth success');
  } catch (e) {
    print('❌ Firebase error: $e');
  }
  // // ✅ Initialize Firebase
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  FirebaseAuth.instance.setLanguageCode('en');

  // ✅ Enable Firebase App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );

  // ✅ Initialize Hive
  await Hive.initFlutter();

  // ✅ Open all boxes safely
  await _openBoxSafe('weddingBox');
  await _openBoxSafe('guestBox');

  // ✅ Run App with Providers
  runApp(const MyApp());

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
      home: const SplashScreen(),

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
    scopes: ["email", "profile"],
    clientId: "83829632051-pgn25ipst5lf3bv7pcihooha5o91pe9o.apps.googleusercontent.com",
  );

  bool isLoading = false;

  Future<void> _signInWithGoogle() async {
    print("🟡 Starting Google Sign-In...");

    setState(() => isLoading = true);

    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        _showSnackBar("Google Sign-In cancelled");
        return;
      }

      final googleAuth = await googleUser.authentication;

      print("🌐 Sending data to backend...");
      final response = await http.post(
        Uri.parse("https://happywedz.com/api/user/google-auth"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": googleUser.email,
          "name": googleUser.displayName ?? "Guest User",
          "tokenId": googleAuth.idToken,
        }),
      );

      print("📥 Response Code: ${response.statusCode}");
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final user = data["user"];
        final token = data["token"];

        final prefs = await SharedPreferences.getInstance();

        /// SAVE ALL USER FIELDS
        await prefs.setBool("is_logged_in", true);
        await prefs.setInt("user_id", user["id"]);
        await prefs.setString("user_name", user["name"] ?? "");
        await prefs.setString("user_email", user["email"] ?? "");
        await prefs.setString("auth_token", token);
        await prefs.setString("user_photo", googleUser.photoUrl ?? "");

        /// ADD NEW FIELDS
        await prefs.setString("user_mobile", user["phone"] ?? "");
        await prefs.setString("wedding_venue", user["weddingVenue"] ?? "");
        await prefs.setString("wedding_date", user["weddingDate"] ?? "");

        print("✅ User session saved completely!");

        _showSnackBar("Welcome ${user['name']}");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomBars()),
        );
      } else {
        _showSnackBar("Login failed: ${data["message"]}");
      }
    } catch (e) {
      print("🚨 ERROR: $e");
      _showSnackBar("Google Sign-In failed: $e");
    }

    setState(() => isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE91E63),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Gradient Background
          Container(
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
          ),

          /// Main Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sign In / Sign Up",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 50),

                    /// Google Button
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _signInWithGoogle,
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
                        "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                        width: 24,
                      ),
                      label: Text(
                        isLoading ? "Signing in..." : "Continue with Google",
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
                        "Looking for a Business Account?",
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

          /// Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.25),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


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
