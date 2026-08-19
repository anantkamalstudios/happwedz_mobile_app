// // import 'dart:convert';
// //
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:flutter_gcaptcha_v3/recaptca_config.dart';
// // import 'package:g_recaptcha_v3/g_recaptcha_v3.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:mailer/mailer.dart';
// // import 'package:mailer/smtp_server/gmail.dart';
// //
// // import 'authservice.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'package:mailer/mailer.dart';
// // import 'package:mailer/smtp_server/gmail.dart';
// // import 'package:google_sign_in/google_sign_in.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // // // RecaptchaHandler class - Add this to a separate file or at the top
// // // class RecaptchaHandler {
// // //   static Future<String?> executeV3({required String action}) async {
// // //     try {
// // //       // This is a placeholder - you need to implement actual reCAPTCHA v3
// // //       // For Flutter web, use the reCAPTCHA JavaScript API
// // //       // For mobile, use flutter_recaptcha_v2 package or similar
// // //
// // //       // Simulate reCAPTCHA token generation
// // //       await Future.delayed(Duration(seconds: 1));
// // //       return "03AGdBq25SiXT-Q9FvT6xX7Q9QGCJNjf4TnJJ8JgY8vXoV9x3fJ_example_token";
// // //     } catch (e) {
// // //       print('reCAPTCHA error: $e');
// // //       return null;
// // //     }
// // //   }
// // // }
// // //
// // // // AuthService class for Google Sign-In
// // // class AuthService {
// // //   final GoogleSignIn _googleSignIn = GoogleSignIn();
// // //   final FirebaseAuth _auth = FirebaseAuth.instance;
// // //
// // //   Future<User?> signInWithGoogle() async {
// // //     try {
// // //       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
// // //       if (googleUser == null) return null;
// // //
// // //       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
// // //
// // //       final credential = GoogleAuthProvider.credential(
// // //         accessToken: googleAuth.accessToken,
// // //         idToken: googleAuth.idToken,
// // //       );
// // //
// // //       final UserCredential userCredential = await _auth.signInWithCredential(credential);
// // //       return userCredential.user;
// // //     } catch (e) {
// // //       print('Google sign in error: $e');
// // //       return null;
// // //     }
// // //   }
// // // }
// // //
// // // class SignUpScreen extends StatefulWidget {
// // //   @override
// // //   _SignUpScreenState createState() => _SignUpScreenState();
// // // }
// // //
// // // class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final TextEditingController _mobileController = TextEditingController();
// // //   final TextEditingController _nameController = TextEditingController();
// // //   final TextEditingController _dateController = TextEditingController();
// // //   final TextEditingController _emailController = TextEditingController();
// // //   final TextEditingController _passwordController = TextEditingController();
// // //   final TextEditingController _venueController = TextEditingController();
// // //
// // //   late AnimationController _fadeController;
// // //   late AnimationController _slideController;
// // //   late Animation<double> _fadeAnimation;
// // //   late Animation<Offset> _slideAnimation;
// // //
// // //   String? _selectedRole;
// // //   DateTime? _selectedDate;
// // //   String? _captchaToken;
// // //   String? _selectedCountryDropdown;
// // //   String? _selectedCityDropdown;
// // //   bool _isGoogleSignUp = false;
// // //
// // //   final List<String> roles = [
// // //     'Bride',
// // //     'Groom',
// // //     'Parent of Bride',
// // //     'Parent of Groom',
// // //     'Friend/Relative',
// // //     'Wedding Planner',
// // //     'Vendor'
// // //   ];
// // //
// // //   final Map<String, List<String>> countryCityMap = {
// // //     'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Nashik', 'Pune', 'Hyderabad', 'Kolkata'],
// // //     'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'],
// // //     'UK': ['London', 'Manchester', 'Liverpool', 'Birmingham'],
// // //     'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary'],
// // //     'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
// // //   };
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _initializeAnimations();
// // //     _preVerifyCaptcha(); // Auto-verify captcha on init
// // //   }
// // //
// // //   void _initializeAnimations() {
// // //     _fadeController = AnimationController(
// // //       duration: Duration(milliseconds: 800),
// // //       vsync: this,
// // //     );
// // //     _slideController = AnimationController(
// // //       duration: Duration(milliseconds: 600),
// // //       vsync: this,
// // //     );
// // //
// // //     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
// // //       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
// // //     );
// // //     _slideAnimation = Tween<Offset>(
// // //       begin: Offset(0.0, 0.3),
// // //       end: Offset.zero,
// // //     ).animate(CurvedAnimation(
// // //       parent: _slideController,
// // //       curve: Curves.easeOutCubic,
// // //     ));
// // //
// // //     _fadeController.forward();
// // //     _slideController.forward();
// // //   }
// // //
// // //   void _preVerifyCaptcha() async {
// // //     await _verifyCaptcha();
// // //   }
// // //
// // //    _verifyCaptcha() async {
// // //     try {
// // //       String? token = await RecaptchaHandler.executeV3(action: 'signup');
// // //
// // //       if (token != null && token.isNotEmpty) {
// // //         setState(() {
// // //           _captchaToken = token;
// // //         });
// // //         print('✅ CAPTCHA verified: ${token.substring(0, 20)}...');
// // //
// // //         _showSnackBar('CAPTCHA verified successfully', Colors.green);
// // //       } else {
// // //         _showSnackBar('CAPTCHA verification failed', Colors.red);
// // //       }
// // //     } catch (e) {
// // //       print('❌ CAPTCHA error: $e');
// // //       _showSnackBar('CAPTCHA error: $e', Colors.red);
// // //     }
// // //   }
// // //
// // //   // Enhanced location fetching with better error handling
// // //   Future<void> _fetchLocationDetails(String venue) async {
// // //     if (venue.trim().isEmpty) return;
// // //
// // //     try {
// // //       final encodedVenue = Uri.encodeComponent(venue.trim());
// // //       final url = Uri.parse(
// // //           "https://nominatim.openstreetmap.org/search?q=$encodedVenue&format=json&addressdetails=1&limit=1"
// // //       );
// // //
// // //       final response = await http.get(url, headers: {
// // //         "User-Agent": "HappyWedsApp/1.0"
// // //       });
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         if (data != null && data.isNotEmpty) {
// // //           final address = data[0]["address"] ?? {};
// // //
// // //           final city = address["city"] ??
// // //               address["town"] ??
// // //               address["village"] ??
// // //               address["municipality"] ?? "";
// // //
// // //           final country = address["country"] ?? "";
// // //
// // //           setState(() {
// // //             if (countryCityMap.containsKey(country)) {
// // //               _selectedCountryDropdown = country;
// // //               final cities = countryCityMap[country]!;
// // //               if (cities.any((c) => c.toLowerCase() == city.toLowerCase())) {
// // //                 _selectedCityDropdown = cities.firstWhere(
// // //                         (c) => c.toLowerCase() == city.toLowerCase()
// // //                 );
// // //               }
// // //             }
// // //           });
// // //
// // //           print('📍 Location found: $city, $country');
// // //         }
// // //       }
// // //     } catch (e) {
// // //       print("❌ Location fetch error: $e");
// // //     }
// // //   }
// // //
// // //   void _handleRegistration() async {
// // //     if (!_validateForm()) return;
// // //
// // //     if (_captchaToken == null || _captchaToken!.isEmpty) {
// // //       _showSnackBar('Please wait for CAPTCHA verification', Colors.orange);
// // //       await _verifyCaptcha();
// // //       if (_captchaToken == null) return;
// // //     }
// // //
// // //     // Verify CAPTCHA server-side
// // //     bool captchaVerified = false;
// // //     try {
// // //       captchaVerified = await _verifyCaptchaServerSide(_captchaToken!);
// // //     } catch (e) {
// // //       _showSnackBar('CAPTCHA verification failed', Colors.red);
// // //       return;
// // //     }
// // //
// // //     if (!captchaVerified) {
// // //       _showSnackBar('CAPTCHA verification failed. Please try again.', Colors.red);
// // //       await _verifyCaptcha(); // Re-verify
// // //       return;
// // //     }
// // //
// // //     await _performRegistration();
// // //   }
// // //
// // //   bool _validateForm() {
// // //     if (!(_formKey.currentState?.validate() ?? false)) {
// // //       _showSnackBar('Please fill all required fields correctly', Colors.red);
// // //       return false;
// // //     }
// // //
// // //     if (_selectedCountryDropdown == null) {
// // //       _showSnackBar('Please select a country', Colors.red);
// // //       return false;
// // //     }
// // //
// // //     if (_selectedCityDropdown == null) {
// // //       _showSnackBar('Please select a city', Colors.red);
// // //       return false;
// // //     }
// // //
// // //     return true;
// // //   }
// // //
// // //   Future<void> _performRegistration() async {
// // //     final payload = {
// // //       "name": _nameController.text.trim(),
// // //       "email": _emailController.text.trim().toLowerCase(),
// // //       "password": _passwordController.text.trim(),
// // //       "phone": _mobileController.text.trim(),
// // //       "role": _selectedRole ?? "user",
// // //       "weddingVenue": _venueController.text.trim(),
// // //       "country": _selectedCountryDropdown ?? "",
// // //       "city": _selectedCityDropdown ?? "",
// // //       "weddingDate": _selectedDate != null
// // //           ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
// // //           : "",
// // //       "captchaToken": _captchaToken,
// // //       "signupMethod": _isGoogleSignUp ? "google" : "email",
// // //       "timestamp": DateTime.now().toIso8601String(),
// // //     };
// // //
// // //     try {
// // //       _showLoadingDialog();
// // //
// // //       final url = Uri.parse("https://happywedz.com/api/user/register");
// // //       final response = await http.post(
// // //         url,
// // //         headers: {
// // //           "Content-Type": "application/json",
// // //           "Accept": "application/json",
// // //         },
// // //         body: jsonEncode(payload),
// // //       );
// // //
// // //       Navigator.pop(context); // Close loading dialog
// // //
// // //       if (response.statusCode == 200 || response.statusCode == 201) {
// // //         print('✅ Registration successful');
// // //
// // //         // Send welcome email
// // //         await _sendWelcomeEmail(
// // //           toEmail: _emailController.text.trim(),
// // //           userName: _nameController.text.trim(),
// // //           userPassword: _isGoogleSignUp ? "Google Account" : _passwordController.text.trim(),
// // //         );
// // //
// // //         _showSuccessDialog();
// // //       } else {
// // //         final respBody = jsonDecode(response.body);
// // //         final message = respBody["message"] ?? respBody["error"] ?? "Registration failed";
// // //         _showSnackBar(message, Colors.red);
// // //         print('❌ Registration failed: ${response.statusCode} - $message');
// // //       }
// // //     } catch (e) {
// // //       Navigator.pop(context);
// // //       _showSnackBar("Registration error: $e", Colors.red);
// // //       print('❌ Registration error: $e');
// // //     }
// // //   }
// // //
// // //   Future<void> _handleGoogleSignUp() async {
// // //     try {
// // //       _showLoadingDialog();
// // //
// // //       final user = await AuthService().signInWithGoogle();
// // //       Navigator.pop(context); // Close loading
// // //
// // //       if (user != null) {
// // //         setState(() {
// // //           _isGoogleSignUp = true;
// // //           _nameController.text = user.displayName ?? "";
// // //           _emailController.text = user.email ?? "";
// // //           _passwordController.text = "google_auth_${DateTime.now().millisecondsSinceEpoch}";
// // //         });
// // //
// // //         _showSnackBar("Google account connected! Please complete your profile.", Colors.green);
// // //         print("✅ Google Sign-In: ${user.displayName}, ${user.email}");
// // //       } else {
// // //         _showSnackBar("Google sign-in was cancelled", Colors.orange);
// // //       }
// // //     } catch (e) {
// // //       Navigator.pop(context);
// // //       _showSnackBar("Google sign-in failed: $e", Colors.red);
// // //       print("❌ Google sign-in error: $e");
// // //     }
// // //   }
// // //
// // //   Future<void> _sendWelcomeEmail({
// // //     required String toEmail,
// // //     required String userName,
// // //     required String userPassword,
// // //   }) async {
// // //     try {
// // //       // Using Gmail SMTP - Replace with your credentials
// // //       final smtpServer = gmail("your-email@gmail.com", "your-app-password");
// // //
// // //       final message = Message()
// // //         ..from = Address("your-email@gmail.com", "HappyWeds Team")
// // //         ..recipients.add(toEmail)
// // //         ..subject = "🎉 Welcome to HappyWeds - Your Wedding Journey Begins!"
// // //         ..html = _buildWelcomeEmailTemplate(userName, toEmail, userPassword);
// // //
// // //       await send(message, smtpServer);
// // //       print("✅ Welcome email sent to $toEmail");
// // //     } catch (e) {
// // //       print("❌ Email send failed: $e");
// // //       // Don't show error to user as registration was successful
// // //     }
// // //   }
// // //
// // //   String _buildWelcomeEmailTemplate(String userName, String email, String password) {
// // //     return '''
// // //     <!DOCTYPE html>
// // //     <html>
// // //     <head>
// // //         <meta charset="UTF-8">
// // //         <style>
// // //             body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
// // //             .container { max-width: 600px; margin: 0 auto; padding: 20px; }
// // //             .header { background: linear-gradient(135deg, #E91E63, #AD1457); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
// // //             .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
// // //             .credentials { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #E91E63; }
// // //             .button { display: inline-block; background: #E91E63; color: white; padding: 12px 25px; text-decoration: none; border-radius: 25px; margin: 20px 0; }
// // //             .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
// // //         </style>
// // //     </head>
// // //     <body>
// // //         <div class="container">
// // //             <div class="header">
// // //                 <h1>🎉 Welcome to HappyWeds!</h1>
// // //                 <p>Your perfect wedding planning journey starts here</p>
// // //             </div>
// // //             <div class="content">
// // //                 <h2>Hello $userName! 👋</h2>
// // //                 <p>Congratulations on joining HappyWeds! We're thrilled to have you as part of our wedding community.</p>
// // //
// // //                 <div class="credentials">
// // //                     <h3>Your Account Details:</h3>
// // //                     <p><strong>📧 Email:</strong> $email</p>
// // //                     <p><strong>🔐 Password:</strong> ${password != "Google Account" ? password : "Secured with Google Account"}</p>
// // //                 </div>
// // //
// // //                 <p>With HappyWeds, you can:</p>
// // //                 <ul>
// // //                     <li>🎯 Plan your dream wedding</li>
// // //                     <li>📋 Manage your guest list</li>
// // //                     <li>💰 Track your budget</li>
// // //                     <li>📅 Organize your timeline</li>
// // //                     <li>🤝 Connect with trusted vendors</li>
// // //                 </ul>
// // //
// // //                 <center>
// // //                     <a href="https://happywedz.com/login" class="button">Start Planning Now</a>
// // //                 </center>
// // //
// // //                 <p>If you have any questions, our support team is always here to help!</p>
// // //
// // //                 <p>Best wishes for your special day! 💕</p>
// // //                 <p><strong>The HappyWeds Team</strong></p>
// // //             </div>
// // //             <div class="footer">
// // //                 <p>© 2024 HappyWeds. Making your wedding dreams come true.</p>
// // //                 <p>Need help? Contact us at support@happywedz.com</p>
// // //             </div>
// // //         </div>
// // //     </body>
// // //     </html>
// // //     ''';
// // //   }
// // //
// // //   Future<bool> _verifyCaptchaServerSide(String token) async {
// // //     try {
// // //       final response = await http.post(
// // //         Uri.parse('https://www.google.com/recaptcha/api/siteverify'),
// // //         headers: {"Content-Type": "application/x-www-form-urlencoded"},
// // //         body: {
// // //           'secret': '6Lfh29UrAAAAAELnNO3hztAwReacEmVjtz8XVSZm', // Your secret key
// // //           'response': token,
// // //         },
// // //       );
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = jsonDecode(response.body);
// // //         final success = data['success'] == true;
// // //         final score = data['score'] ?? 0.0;
// // //
// // //         print('CAPTCHA verification: success=$success, score=$score');
// // //         return success && score >= 0.5; // Minimum score threshold
// // //       }
// // //       return false;
// // //     } catch (e) {
// // //       print('CAPTCHA verification error: $e');
// // //       return false;
// // //     }
// // //   }
// // //
// // //   void _showLoadingDialog() {
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (context) => Dialog(
// // //         backgroundColor: Colors.transparent,
// // //         child: Container(
// // //           padding: EdgeInsets.all(20),
// // //           decoration: BoxDecoration(
// // //             color: Colors.white,
// // //             borderRadius: BorderRadius.circular(15),
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               CircularProgressIndicator(
// // //                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
// // //               ),
// // //               SizedBox(height: 20),
// // //               Text(
// // //                 'Creating your account...',
// // //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showSnackBar(String message, Color color) {
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message),
// // //         backgroundColor: color,
// // //         behavior: SnackBarBehavior.floating,
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// // //         action: SnackBarAction(
// // //           label: 'OK',
// // //           textColor: Colors.white,
// // //           onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showSuccessDialog() {
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (context) => Dialog(
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// // //         child: Container(
// // //           padding: EdgeInsets.all(24),
// // //           decoration: BoxDecoration(
// // //             gradient: LinearGradient(
// // //               begin: Alignment.topLeft,
// // //               end: Alignment.bottomRight,
// // //               colors: [Colors.white, Color(0xFFFFF3F8)],
// // //             ),
// // //             borderRadius: BorderRadius.circular(20),
// // //           ),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Container(
// // //                 width: 80,
// // //                 height: 80,
// // //                 decoration: BoxDecoration(
// // //                   gradient: LinearGradient(
// // //                     colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
// // //                   ),
// // //                   shape: BoxShape.circle,
// // //                 ),
// // //                 child: Icon(
// // //                   Icons.check_circle_outline,
// // //                   size: 40,
// // //                   color: Colors.white,
// // //                 ),
// // //               ),
// // //               SizedBox(height: 24),
// // //               Text(
// // //                 '🎉 Registration Successful!',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(
// // //                   fontSize: 22,
// // //                   fontWeight: FontWeight.bold,
// // //                   color: Colors.black87,
// // //                 ),
// // //               ),
// // //               SizedBox(height: 12),
// // //               Text(
// // //                 'Welcome to HappyWeds! Your account has been created successfully. Check your email for login details.',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(
// // //                   fontSize: 14,
// // //                   color: Colors.grey[600],
// // //                   height: 1.4,
// // //                 ),
// // //               ),
// // //               SizedBox(height: 32),
// // //               Row(
// // //                 children: [
// // //                   Expanded(
// // //                     child: OutlinedButton(
// // //                       onPressed: () {
// // //                         Navigator.pop(context);
// // //                         Navigator.pop(context);
// // //                       },
// // //                       style: OutlinedButton.styleFrom(
// // //                         side: BorderSide(color: Color(0xFFE91E63)),
// // //                         padding: EdgeInsets.symmetric(vertical: 14),
// // //                         shape: RoundedRectangleBorder(
// // //                           borderRadius: BorderRadius.circular(25),
// // //                         ),
// // //                       ),
// // //                       child: Text(
// // //                         'Back to Login',
// // //                         style: TextStyle(
// // //                           color: Color(0xFFE91E63),
// // //                           fontWeight: FontWeight.w600,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                   SizedBox(width: 12),
// // //                   Expanded(
// // //                     child: ElevatedButton(
// // //                       onPressed: () {
// // //                         Navigator.pop(context);
// // //                         // Navigate to main app or profile completion
// // //                       },
// // //                       style: ElevatedButton.styleFrom(
// // //                         backgroundColor: Color(0xFFE91E63),
// // //                         padding: EdgeInsets.symmetric(vertical: 14),
// // //                         shape: RoundedRectangleBorder(
// // //                           borderRadius: BorderRadius.circular(25),
// // //                         ),
// // //                       ),
// // //                       child: Text(
// // //                         'Get Started',
// // //                         style: TextStyle(
// // //                           fontSize: 16,
// // //                           fontWeight: FontWeight.w600,
// // //                           color: Colors.white,
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   @override
// // //   void dispose() {
// // //     _fadeController.dispose();
// // //     _slideController.dispose();
// // //     _mobileController.dispose();
// // //     _nameController.dispose();
// // //     _dateController.dispose();
// // //     _emailController.dispose();
// // //     _passwordController.dispose();
// // //     _venueController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       appBar: _buildAppBar(),
// // //       body: FadeTransition(
// // //         opacity: _fadeAnimation,
// // //         child: SlideTransition(
// // //           position: _slideAnimation,
// // //           child: SingleChildScrollView(
// // //             padding: EdgeInsets.all(24),
// // //             child: Form(
// // //               key: _formKey,
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   SizedBox(height: 20),
// // //                   _buildSignUpTitle(),
// // //                   SizedBox(height: 40),
// // //                   _buildFullNameField(),
// // //                   SizedBox(height: 20),
// // //                   _buildEmailField(),
// // //                   if (!_isGoogleSignUp) ...[
// // //                     SizedBox(height: 20),
// // //                     _buildPasswordField(),
// // //                   ],
// // //                   SizedBox(height: 20),
// // //                   _buildMobileNumberField(),
// // //                   SizedBox(height: 20),
// // //                   _buildVenueField(),
// // //                   SizedBox(height: 20),
// // //                   _buildCountryDropdown(),
// // //                   SizedBox(height: 20),
// // //                   _buildCityDropdown(),
// // //                   SizedBox(height: 20),
// // //                   _buildWeddingDateField(),
// // //                   SizedBox(height: 20),
// // //                   _buildRoleField(),
// // //                   SizedBox(height: 20),
// // //                   _buildCaptchaField(),
// // //                   SizedBox(height: 30),
// // //                   _buildCompleteRegistrationButton(),
// // //                   SizedBox(height: 20),
// // //                   _buildDivider(),
// // //                   SizedBox(height: 20),
// // //                   _buildGoogleButton(),
// // //                 ],
// // //               ),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   PreferredSizeWidget _buildAppBar() {
// // //     return AppBar(
// // //       elevation: 0,
// // //       backgroundColor: Color(0xFFE91E63),
// // //       systemOverlayStyle: SystemUiOverlayStyle.light,
// // //       leading: IconButton(
// // //         icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
// // //         onPressed: () => Navigator.pop(context),
// // //       ),
// // //       title: Text(
// // //         'Create Account',
// // //         style: TextStyle(
// // //           color: Colors.white,
// // //           fontSize: 18,
// // //           fontWeight: FontWeight.w600,
// // //         ),
// // //       ),
// // //       centerTitle: true,
// // //     );
// // //   }
// // //
// // //   Widget _buildSignUpTitle() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.center,
// // //       children: [
// // //         Center(
// // //           child: Text(
// // //             'Join HappyWeds',
// // //             style: TextStyle(
// // //               fontSize: 32,
// // //               fontWeight: FontWeight.bold,
// // //               color: Colors.black87,
// // //             ),
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Center(
// // //           child: Text(
// // //             'Plan your perfect wedding journey',
// // //             style: TextStyle(
// // //               fontSize: 16,
// // //               color: Colors.grey[600],
// // //             ),
// // //           ),
// // //         ),
// // //         SizedBox(height: 16),
// // //         Center(
// // //           child: Row(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               Text(
// // //                 "Already have an account?",
// // //                 style: TextStyle(
// // //                   fontSize: 14,
// // //                   color: Colors.grey[600],
// // //                 ),
// // //               ),
// // //               SizedBox(width: 4),
// // //               GestureDetector(
// // //                 onTap: () => Navigator.pop(context),
// // //                 child: Text(
// // //                   'Login',
// // //                   style: TextStyle(
// // //                     fontSize: 14,
// // //                     color: Color(0xFFE91E63),
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildInputField({
// // //     required String label,
// // //     required TextEditingController controller,
// // //     TextInputType keyboardType = TextInputType.text,
// // //     String? Function(String?)? validator,
// // //     Widget? suffixIcon,
// // //     bool readOnly = false,
// // //     VoidCallback? onTap,
// // //     VoidCallback? onEditingComplete,
// // //     String? hintText,
// // //     bool obscureText = false,
// // //   }) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           label,
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: TextFormField(
// // //             controller: controller,
// // //             keyboardType: keyboardType,
// // //             readOnly: readOnly,
// // //             obscureText: obscureText,
// // //             onTap: onTap,
// // //             onEditingComplete: onEditingComplete,
// // //             validator: validator,
// // //             decoration: InputDecoration(
// // //               border: InputBorder.none,
// // //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// // //               hintText: hintText ?? 'Enter $label',
// // //               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
// // //               suffixIcon: suffixIcon,
// // //             ),
// // //             style: TextStyle(fontSize: 16),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildFullNameField() {
// // //     return _buildInputField(
// // //       label: 'Full Name *',
// // //       controller: _nameController,
// // //       keyboardType: TextInputType.name,
// // //       hintText: 'Enter your full name',
// // //       validator: (value) {
// // //         if (value?.trim().isEmpty ?? true) return 'Full name is required';
// // //         if (value!.trim().length < 2) return 'Name must be at least 2 characters';
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildEmailField() {
// // //     return _buildInputField(
// // //       label: 'Email Address *',
// // //       controller: _emailController,
// // //       keyboardType: TextInputType.emailAddress,
// // //       hintText: 'Enter your email address',
// // //       readOnly: _isGoogleSignUp,
// // //       validator: (value) {
// // //         if (value?.trim().isEmpty ?? true) return 'Email is required';
// // //         if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value!)) {
// // //           return 'Enter a valid email address';
// // //         }
// // //         return null;
// // //       },
// // //       suffixIcon: _isGoogleSignUp
// // //           ? Icon(Icons.verified, color: Colors.green)
// // //           : Icon(Icons.email_outlined, color: Colors.grey[400]),
// // //     );
// // //   }
// // //
// // //   Widget _buildPasswordField() {
// // //     return _buildInputField(
// // //       label: 'Password *',
// // //       controller: _passwordController,
// // //       hintText: 'Create a strong password',
// // //       obscureText: true,
// // //       validator: (value) {
// // //         if (value?.isEmpty ?? true) return 'Password is required';
// // //         if (value!.length < 8) return 'Password must be at least 8 characters';
// // //         if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
// // //           return 'Password must contain uppercase, lowercase and number';
// // //         }
// // //         return null;
// // //       },
// // //       suffixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
// // //     );
// // //   }
// // //
// // //   Widget _buildMobileNumberField() {
// // //     return _buildInputField(
// // //       label: 'Mobile Number *',
// // //       controller: _mobileController,
// // //       keyboardType: TextInputType.phone,
// // //       hintText: '+91 XXXXX XXXXX',
// // //       validator: (value) {
// // //         if (value?.trim().isEmpty ?? true) return 'Mobile number is required';
// // //         String cleaned = value!.replaceAll(RegExp(r'[^\d]'), '');
// // //         if (cleaned.length < 10) return 'Enter a valid mobile number';
// // //         return null;
// // //       },
// // //       suffixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),
// // //     );
// // //   }
// // //
// // //   Widget _buildVenueField() {
// // //     return _buildInputField(
// // //       label: 'Wedding Venue',
// // //       controller: _venueController,
// // //       hintText: 'Enter wedding venue or location',
// // //       onEditingComplete: () {
// // //         if (_venueController.text.trim().isNotEmpty) {
// // //           _fetchLocationDetails(_venueController.text.trim());
// // //         }
// // //       },
// // //       suffixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[400]),
// // //     );
// // //   }
// // //
// // //   Widget _buildCountryDropdown() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Country *',
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: DropdownButtonFormField<String>(
// // //             value: _selectedCountryDropdown,
// // //             decoration: InputDecoration(
// // //               border: InputBorder.none,
// // //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// // //               hintText: 'Select your country',
// // //               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
// // //             ),
// // //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
// // //             items: countryCityMap.keys.map((country) =>
// // //                 DropdownMenuItem(
// // //                   value: country,
// // //                   child: Text(country, style: TextStyle(fontSize: 16)),
// // //                 )
// // //             ).toList(),
// // //             onChanged: (value) {
// // //               setState(() {
// // //                 _selectedCountryDropdown = value;
// // //                 _selectedCityDropdown = null; // Reset city when country changes
// // //               });
// // //             },
// // //             validator: (value) => value == null ? 'Please select a country' : null,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildCityDropdown() {
// // //     final cities = _selectedCountryDropdown != null
// // //         ? countryCityMap[_selectedCountryDropdown]!
// // //         : <String>[];
// // //
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'City *',
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: _selectedCountryDropdown == null
// // //                 ? Color(0xFFF0F0F0)
// // //                 : Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: DropdownButtonFormField<String>(
// // //             value: _selectedCityDropdown,
// // //             decoration: InputDecoration(
// // //               border: InputBorder.none,
// // //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// // //               hintText: _selectedCountryDropdown == null
// // //                   ? 'Select country first'
// // //                   : 'Select your city',
// // //               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
// // //             ),
// // //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
// // //             items: cities.map((city) =>
// // //                 DropdownMenuItem(
// // //                   value: city,
// // //                   child: Text(city, style: TextStyle(fontSize: 16)),
// // //                 )
// // //             ).toList(),
// // //             onChanged: _selectedCountryDropdown == null
// // //                 ? null
// // //                 : (value) {
// // //               setState(() {
// // //                 _selectedCityDropdown = value;
// // //               });
// // //             },
// // //             validator: (value) => value == null ? 'Please select a city' : null,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildWeddingDateField() {
// // //     return _buildInputField(
// // //       label: 'Wedding Date (Optional)',
// // //       controller: _dateController,
// // //       readOnly: true,
// // //       hintText: 'Select your wedding date',
// // //       onTap: _selectDate,
// // //       suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
// // //     );
// // //   }
// // //
// // //   Widget _buildRoleField() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Your Role',
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: DropdownButtonFormField<String>(
// // //             value: _selectedRole,
// // //             decoration: InputDecoration(
// // //               border: InputBorder.none,
// // //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// // //               hintText: 'Tell us who you are',
// // //               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
// // //             ),
// // //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
// // //             items: roles.map((role) => DropdownMenuItem(
// // //               value: role,
// // //               child: Text(role, style: TextStyle(fontSize: 16)),
// // //             )).toList(),
// // //             onChanged: (value) {
// // //               setState(() {
// // //                 _selectedRole = value;
// // //               });
// // //             },
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildCaptchaField() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Security Verification',
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           padding: EdgeInsets.all(16),
// // //           decoration: BoxDecoration(
// // //             color: _captchaToken != null ? Color(0xFFF0F8F0) : Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(
// // //               color: _captchaToken != null ? Colors.green : Color(0xFFE9ECEF),
// // //             ),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: Row(
// // //             children: [
// // //               Icon(
// // //                 _captchaToken != null ? Icons.verified_user : Icons.security,
// // //                 color: _captchaToken != null ? Colors.green : Colors.grey[400],
// // //               ),
// // //               SizedBox(width: 12),
// // //               Expanded(
// // //                 child: Text(
// // //                   _captchaToken != null
// // //                       ? '✅ Security verification completed'
// // //                       : '🔄 Verifying security...',
// // //                   style: TextStyle(
// // //                     fontSize: 14,
// // //                     color: _captchaToken != null ? Colors.green[700] : Colors.grey[600],
// // //                     fontWeight: FontWeight.w500,
// // //                   ),
// // //                 ),
// // //               ),
// // //               if (_captchaToken == null)
// // //                 SizedBox(
// // //                   width: 20,
// // //                   height: 20,
// // //                   child: CircularProgressIndicator(
// // //                     strokeWidth: 2,
// // //                     valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
// // //                   ),
// // //                 ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildCompleteRegistrationButton() {
// // //     return Container(
// // //       width: double.infinity,
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //         ),
// // //         borderRadius: BorderRadius.circular(25),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Color(0xFFE91E63).withValues(alpha: 0.3),
// // //             blurRadius: 15,
// // //             offset: Offset(0, 8),
// // //           ),
// // //         ],
// // //       ),
// // //       child: ElevatedButton(
// // //         onPressed: _handleRegistration,
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: Colors.transparent,
// // //           shadowColor: Colors.transparent,
// // //           padding: EdgeInsets.symmetric(vertical: 18),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(25),
// // //           ),
// // //         ),
// // //         child: Text(
// // //           _isGoogleSignUp ? 'Complete Google Registration' : 'Create Account',
// // //           style: TextStyle(
// // //             fontSize: 16,
// // //             fontWeight: FontWeight.w600,
// // //             color: Colors.white,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   Widget _buildDivider() {
// // //     return Row(
// // //       children: [
// // //         Expanded(
// // //           child: Container(
// // //             height: 1,
// // //             color: Colors.grey[300],
// // //           ),
// // //         ),
// // //         Padding(
// // //           padding: EdgeInsets.symmetric(horizontal: 16),
// // //           child: Text(
// // //             'OR',
// // //             style: TextStyle(
// // //               color: Colors.grey[500],
// // //               fontWeight: FontWeight.w500,
// // //             ),
// // //           ),
// // //         ),
// // //         Expanded(
// // //           child: Container(
// // //             height: 1,
// // //             color: Colors.grey[300],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildGoogleButton() {
// // //     return Container(
// // //       width: double.infinity,
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(25),
// // //         border: Border.all(color: Color(0xFFE9ECEF)),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withValues(alpha: 0.05),
// // //             blurRadius: 10,
// // //             offset: Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: ElevatedButton.icon(
// // //         onPressed: _isGoogleSignUp ? null : _handleGoogleSignUp,
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: Colors.white,
// // //           foregroundColor: Colors.black87,
// // //           shadowColor: Colors.transparent,
// // //           padding: EdgeInsets.symmetric(vertical: 16),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(25),
// // //           ),
// // //         ),
// // //         icon: Container(
// // //           width: 20,
// // //           height: 20,
// // //           decoration: BoxDecoration(
// // //             image: DecorationImage(
// // //               image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
// // //               fit: BoxFit.contain,
// // //             ),
// // //           ),
// // //         ),
// // //         label: Text(
// // //           _isGoogleSignUp ? '✅ Connected with Google' : 'Continue with Google',
// // //           style: TextStyle(
// // //             fontSize: 16,
// // //             fontWeight: FontWeight.w500,
// // //             color: _isGoogleSignUp ? Colors.green[700] : Colors.black87,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _selectDate() async {
// // //     final DateTime? picked = await showDatePicker(
// // //       context: context,
// // //       initialDate: DateTime.now().add(Duration(days: 30)),
// // //       firstDate: DateTime.now(),
// // //       lastDate: DateTime.now().add(Duration(days: 365 * 3)),
// // //       builder: (context, child) {
// // //         return Theme(
// // //           data: Theme.of(context).copyWith(
// // //             colorScheme: ColorScheme.light(
// // //               primary: Color(0xFFE91E63),
// // //               onPrimary: Colors.white,
// // //               surface: Colors.white,
// // //               onSurface: Colors.black,
// // //             ),
// // //             dialogBackgroundColor: Colors.white,
// // //           ),
// // //           child: child!,
// // //         );
// // //       },
// // //     );
// // //
// // //     if (picked != null) {
// // //       setState(() {
// // //         _selectedDate = picked;
// // //         _dateController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
// // //       });
// // //     }
// // //   }
// // // }
// // //
// //
// //
// //
// //
// //
// //
// //
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:google_sign_in/google_sign_in.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:mailer/mailer.dart';
// // import 'package:mailer/smtp_server.dart';
// //
// // // --- RecaptchaHandler placeholder (keeps your original idea) ---
// // // class RecaptchaHandler {
// // //   // NOTE: For production you must use real reCAPTCHA v3 on web and a server-side
// // //   // verification flow. This is a local placeholder to keep UI flow intact.
// // //   static Future<String?> executeV3({required String action}) async {
// // //     await Future.delayed(Duration(milliseconds: 700));
// // //     return "03AGdBq-example-token-for-dev-only";
// // //   }
// // // }
// // //
// // // // --- AuthService: Google Sign-In WITHOUT Firebase ---
// // // class AuthService {
// // //   final GoogleSignIn _googleSignIn = GoogleSignIn(
// // //     scopes: [
// // //       'email',
// // //       'profile',
// // //       // add other scopes if you need them
// // //     ],
// // //   );
// // //
// // //   /// Returns a map containing useful user info and tokens, or null if cancelled/fails.
// // //   Future<Map<String, dynamic>?> signInWithGoogle() async {
// // //     try {
// // //       final GoogleSignInAccount? account = await _googleSignIn.signIn();
// // //       if (account == null) return null; // user cancelled
// // //
// // //       final GoogleSignInAuthentication auth = await account.authentication;
// // //
// // //       return {
// // //         'displayName': account.displayName,
// // //         'email': account.email,
// // //         'photoUrl': account.photoUrl,
// // //         'id': account.id,
// // //         'idToken': auth.idToken,         // send to your server to verify
// // //         'accessToken': auth.accessToken, // optional, short lived
// // //       };
// // //     } catch (e, st) {
// // //       debugPrint('AuthService.signInWithGoogle error: $e\n$st');
// // //       return null;
// // //     }
// // //   }
// // //
// // //   Future<void> signOut() async {
// // //     await _googleSignIn.signOut();
// // //   }
// // // }
// // //
// // // // --- Main app + SignUpScreen (adapted from your original) ---
// // //
// // //
// // // class SignUpScreen extends StatefulWidget {
// // //   const SignUpScreen({super.key});
// // //   @override
// // //   _SignUpScreenState createState() => _SignUpScreenState();
// // // }
// // //
// // // class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final TextEditingController _mobileController = TextEditingController();
// // //   final TextEditingController _nameController = TextEditingController();
// // //   final TextEditingController _dateController = TextEditingController();
// // //   final TextEditingController _emailController = TextEditingController();
// // //   final TextEditingController _passwordController = TextEditingController();
// // //   final TextEditingController _venueController = TextEditingController();
// // //
// // //   late AnimationController _fadeController;
// // //   late AnimationController _slideController;
// // //   late Animation<double> _fadeAnimation;
// // //   late Animation<Offset> _slideAnimation;
// // //
// // //   bool _isGoogleSignUp = false;
// // //   String? _captchaToken;
// // //   DateTime? _selectedDate;
// // //
// // //   final AuthService _authService = AuthService();
// // //
// // //   // Country/city sample (kept from your original)
// // //   String? _selectedCountryDropdown;
// // //   String? _selectedCityDropdown;
// // //   final Map<String, List<String>> countryCityMap = {
// // //     'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Nashik', 'Pune', 'Hyderabad', 'Kolkata'],
// // //     'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'],
// // //     'UK': ['London', 'Manchester', 'Liverpool', 'Birmingham'],
// // //     'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary'],
// // //     'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
// // //   };
// // //
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _initializeAnimations();
// // //     _preVerifyCaptcha();
// // //   }
// // //
// // //   void _initializeAnimations() {
// // //     _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
// // //     _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
// // //
// // //     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
// // //       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
// // //     );
// // //     _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.3), end: Offset.zero).animate(
// // //       CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
// // //     );
// // //
// // //     _fadeController.forward();
// // //     _slideController.forward();
// // //   }
// // //
// // //   void _preVerifyCaptcha() async {
// // //     await _verifyCaptcha();
// // //   }
// // //
// // //   Future<void> _verifyCaptcha() async {
// // //     try {
// // //       final token = await RecaptchaHandler.executeV3(action: 'signup');
// // //       setState(() => _captchaToken = token);
// // //       if (token != null) {
// // //         _showSnackBar('CAPTCHA verified (dev token)', Colors.green);
// // //       } else {
// // //         _showSnackBar('CAPTCHA failed', Colors.orange);
// // //       }
// // //     } catch (e) {
// // //       _showSnackBar('CAPTCHA error: $e', Colors.red);
// // //     }
// // //   }
// // //
// // //   Future<void> _handleGoogleSignUp() async {
// // //     try {
// // //       _showLoadingDialog();
// // //       final result = await _authService.signInWithGoogle();
// // //       Navigator.pop(context); // close loading
// // //
// // //       if (result == null) {
// // //         _showSnackBar('Google sign-in cancelled or failed', Colors.orange);
// // //         return;
// // //       }
// // //
// // //       setState(() {
// // //         _isGoogleSignUp = true;
// // //         _nameController.text = (result['displayName'] as String?) ?? '';
// // //         _emailController.text = (result['email'] as String?) ?? '';
// // //         // We create a random local password placeholder — server should handle real auth via idToken.
// // //         _passwordController.text = 'google_auth_${DateTime.now().millisecondsSinceEpoch}';
// // //       });
// // //
// // //       // Send token to your backend for verification / registration.
// // //       // Example: await _sendGoogleTokenToServer(idToken: result['idToken']);
// // //       debugPrint('Google sign-in successful: ${result['email']}');
// // //       _showSnackBar('Google connected. Please complete profile.', Colors.green);
// // //     } catch (e) {
// // //       Navigator.pop(context);
// // //       _showSnackBar('Google sign-in error: $e', Colors.red);
// // //     }
// // //   }
// // //
// // //   Future<void> _handleRegistration() async {
// // //     if (!(_formKey.currentState?.validate() ?? false)) {
// // //       _showSnackBar('Please complete required fields', Colors.red);
// // //       return;
// // //     }
// // //
// // //     if (_captchaToken == null || _captchaToken!.isEmpty) {
// // //       _showSnackBar('Waiting for CAPTCHA verification', Colors.orange);
// // //       await _verifyCaptcha();
// // //       if (_captchaToken == null) return;
// // //     }
// // //
// // //     // Example: server-side captcha verification (recommended).
// // //     final verified = await _verifyCaptchaServerSide(_captchaToken!);
// // //     if (!verified) {
// // //       _showSnackBar('CAPTCHA server verification failed', Colors.red);
// // //       return;
// // //     }
// // //
// // //     // Build payload and post to your server
// // //     final payload = {
// // //       'name': _nameController.text.trim(),
// // //       'email': _emailController.text.trim().toLowerCase(),
// // //       'password': _isGoogleSignUp ? null : _passwordController.text.trim(),
// // //       'phone': _mobileController.text.trim(),
// // //       'weddingVenue': _venueController.text.trim(),
// // //       'country': _selectedCountryDropdown ?? '',
// // //       'city': _selectedCityDropdown ?? '',
// // //       'weddingDate': _selectedDate != null ? _selectedDate!.toIso8601String() : '',
// // //       'captchaToken': _captchaToken,
// // //       'signupMethod': _isGoogleSignUp ? 'google' : 'email',
// // //       'timestamp': DateTime.now().toIso8601String(),
// // //     };
// // //
// // //     try {
// // //       _showLoadingDialog();
// // //       final url = Uri.parse('https://happywedz.com/api/user/register'); // your endpoint
// // //       final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
// // //       Navigator.pop(context);
// // //
// // //       if (resp.statusCode == 200 || resp.statusCode == 201) {
// // //         _showSuccessDialog();
// // //       } else {
// // //         String msg = 'Registration failed';
// // //         try {
// // //           final body = jsonDecode(resp.body);
// // //           msg = body['message'] ?? body['error'] ?? msg;
// // //         } catch (_) {}
// // //         _showSnackBar(msg, Colors.red);
// // //       }
// // //     } catch (e) {
// // //       Navigator.pop(context);
// // //       _showSnackBar('Registration error: $e', Colors.red);
// // //     }
// // //   }
// // //
// // //   // Replace with server-side reCAPTCHA verification (this just mirrors your earlier flow)
// // //   Future<bool> _verifyCaptchaServerSide(String token) async {
// // //     try {
// // //       final res = await http.post(
// // //         Uri.parse('https://www.google.com/recaptcha/api/siteverify'),
// // //         headers: {'Content-Type': 'application/x-www-form-urlencoded'},
// // //         body: {'secret': '6Lfh29UrAAAAAELnNO3hztAwReacEmVjtz8XVSZm', 'response': token},
// // //       );
// // //       if (res.statusCode == 200) {
// // //         final map = jsonDecode(res.body);
// // //         final success = map['success'] == true;
// // //         final score = (map['score'] ?? 0.0) as num;
// // //         debugPrint('recaptcha verify: success=$success score=$score');
// // //         return success && score >= 0.5;
// // //       }
// // //       return false;
// // //     } catch (e) {
// // //       debugPrint('recaptcha verify error: $e');
// // //       return false;
// // //     }
// // //   }
// // //
// // //   // Optional example for sending email (not recommended from mobile: keep credentials on server)
// // //   Future<void> _sendWelcomeEmail({
// // //     required String toEmail,
// // //     required String userName,
// // //     required String userPassword,
// // //   }) async {
// // //     try {
// // //       // WARNING: Hardcoding credentials in app is insecure. Keep SMTP server on the backend.
// // //       final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
// // //       final message = Message()
// // //         ..from = Address('your-email@gmail.com', 'HappyWeds Team')
// // //         ..recipients.add(toEmail)
// // //         ..subject = 'Welcome to HappyWeds'
// // //         ..text = 'Hello $userName,\nYour account is ready.';
// // //       await send(message, smtpServer);
// // //     } catch (e) {
// // //       debugPrint('Email send failed (ignored): $e');
// // //     }
// // //   }
// // //
// // //   // UI helpers
// // //   void _showLoadingDialog() {
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (_) => const Dialog(
// // //         backgroundColor: Colors.transparent,
// // //         child: Padding(
// // //           padding: EdgeInsets.all(24),
// // //           child: Center(child: CircularProgressIndicator()),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showSnackBar(String message, Color color) {
// // //     if (!mounted) return;
// // //     ScaffoldMessenger.of(context).showSnackBar(
// // //       SnackBar(
// // //         content: Text(message),
// // //         backgroundColor: color,
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _showSuccessDialog() {
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (_) => Dialog(
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // //         child: Padding(
// // //           padding: const EdgeInsets.all(20),
// // //           child: Column(mainAxisSize: MainAxisSize.min, children: [
// // //             const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFFE91E63)),
// // //             const SizedBox(height: 12),
// // //             const Text('Registration Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
// // //             const SizedBox(height: 8),
// // //             const Text('Welcome to HappyWeds. Check your email for details.'),
// // //             const SizedBox(height: 16),
// // //             ElevatedButton(
// // //               onPressed: () {
// // //                 Navigator.pop(context); // close dialog
// // //                 Navigator.pop(context); // back
// // //               },
// // //               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
// // //               child: const Text('Back to Login'),
// // //             )
// // //           ]),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   // --- UI builder methods (kept compact) ---
// // //   @override
// // //   void dispose() {
// // //     _fadeController.dispose();
// // //     _slideController.dispose();
// // //     _mobileController.dispose();
// // //     _nameController.dispose();
// // //     _dateController.dispose();
// // //     _emailController.dispose();
// // //     _passwordController.dispose();
// // //     _venueController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Create Account'),
// // //         backgroundColor: const Color(0xFFE91E63),
// // //       ),
// // //       body: FadeTransition(
// // //         opacity: _fadeAnimation,
// // //         child: SlideTransition(
// // //           position: _slideAnimation,
// // //           child: SingleChildScrollView(
// // //             padding: const EdgeInsets.all(20),
// // //             child: Form(
// // //               key: _formKey,
// // //               child: Column(children: [
// // //                 const SizedBox(height: 12),
// // //                 TextFormField(
// // //                   controller: _nameController,
// // //                   decoration: const InputDecoration(labelText: 'Full Name *'),
// // //                   validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name required' : null,
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 TextFormField(
// // //                   controller: _emailController,
// // //                   readOnly: _isGoogleSignUp,
// // //                   decoration: const InputDecoration(labelText: 'Email *'),
// // //                   validator: (v) {
// // //                     if (v == null || v.trim().isEmpty) return 'Email required';
// // //                     final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
// // //                     return re.hasMatch(v) ? null : 'Enter valid email';
// // //                   },
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 if (!_isGoogleSignUp)
// // //                   TextFormField(
// // //                     controller: _passwordController,
// // //                     decoration: const InputDecoration(labelText: 'Password *'),
// // //                     obscureText: true,
// // //                     validator: (v) {
// // //                       if (v == null || v.isEmpty) return 'Password required';
// // //                       if (v.length < 8) return 'Min 8 chars';
// // //                       return null;
// // //                     },
// // //                   ),
// // //                 const SizedBox(height: 12),
// // //                 TextFormField(
// // //                   controller: _mobileController,
// // //                   decoration: const InputDecoration(labelText: 'Mobile Number *'),
// // //                   keyboardType: TextInputType.phone,
// // //                   validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid mobile' : null,
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 TextFormField(
// // //                   controller: _venueController,
// // //                   decoration: const InputDecoration(labelText: 'Wedding Venue'),
// // //                 ),
// // //                 const SizedBox(height: 18),
// // //                 ElevatedButton(
// // //                   onPressed: _handleRegistration,
// // //                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
// // //                   child: const SizedBox(width: double.infinity, height: 48, child: Center(child: Text('Create Account'))),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR')), Expanded(child: Divider())]),
// // //                 const SizedBox(height: 12),
// // //                 OutlinedButton.icon(
// // //                   onPressed: _isGoogleSignUp ? null : _handleGoogleSignUp,
// // //                   icon: Image.network('https://developers.google.com/identity/images/g-logo.png', width: 20, height: 20),
// // //                   label: Text(_isGoogleSignUp ? '✅ Connected with Google' : 'Continue with Google'),
// // //                   style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Colors.grey)),
// // //                 ),
// // //                 const SizedBox(height: 20),
// // //                 Container(
// // //                   padding: const EdgeInsets.symmetric(vertical: 8),
// // //                   child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
// // //                     Icon(_captchaToken != null ? Icons.verified : Icons.security, color: _captchaToken != null ? Colors.green : Colors.grey),
// // //                     const SizedBox(width: 8),
// // //                     Text(_captchaToken != null ? 'Security verified' : 'Verifying security...', style: const TextStyle(fontWeight: FontWeight.w500))
// // //                   ]),
// // //                 )
// // //               ]),
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart';
// // import 'package:google_sign_in/google_sign_in.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';
// // import 'package:mailer/mailer.dart';
// // import 'package:mailer/smtp_server.dart';
// //
// // class RecaptchaHandler {
// //   /// Executes Google reCAPTCHA v3
// //   static Future<String?> executeV3({required String action}) async {
// //     try {
// //       // For Web: call JS reCAPTCHA API via `js` interop
// //       // For mobile: use server-side verification
// //       // Here we simulate token for demonstration
// //       await Future.delayed(Duration(seconds: 1));
// //       return "03AGdBq25SiXT-Q9FvT6xX7Q9QGCJNjf4TnJJ8JgY8vXoV9x3fJ_example_token";
// //     } catch (e) {
// //       print('reCAPTCHA error: $e');
// //       return null;
// //     }
// //   }
// // }
// //
// // class AuthService {
// //   final GoogleSignIn _googleSignIn = GoogleSignIn(
// //     scopes: ['email', 'profile'],
// //     clientId:
// //     '27907630225-7ej3amekq30agtsk4qfft344ths43uk1.apps.googleusercontent.com', // only needed for web
// //   );
// //
// //   Future<GoogleSignInAccount?> signInWithGoogle() async {
// //     try {
// //       final account = await _googleSignIn.signIn();
// //       if (account != null) {
// //         print('Google sign-in successful: ${account.email}');
// //       } else {
// //         print('Sign-in cancelled by user');
// //       }
// //       return account;
// //     } catch (e) {
// //       print('Google sign-in error: $e');
// //       return null;
// //     }
// //   }
// // }
// //
// // class SignUpScreen extends StatefulWidget {
// //   const SignUpScreen({super.key});
// //
// //   @override
// //   State<SignUpScreen> createState() => _SignUpScreenState();
// // }
// //
// // class _SignUpScreenState extends State<SignUpScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //
// //   final TextEditingController _nameController = TextEditingController();
// //   final TextEditingController _emailController = TextEditingController();
// //   final TextEditingController _passwordController = TextEditingController();
// //   final TextEditingController _phoneController = TextEditingController();
// //   final TextEditingController _venueController = TextEditingController();
// //   final TextEditingController _dateController = TextEditingController();
// //
// //   String? _selectedCountry;
// //   String? _selectedCity;
// //   DateTime? _selectedDate;
// //   String? _captchaToken;
// //   bool _isGoogleSignUp = false;
// //
// //   final List<String> _countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];
// //   final Map<String, List<String>> _cities = {
// //     'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune'],
// //     'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston'],
// //     'UK': ['London', 'Manchester', 'Liverpool', 'Birmingham'],
// //     'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary'],
// //     'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
// //   };
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     _preVerifyCaptcha();
// //   }
// //
// //   Future<void> _preVerifyCaptcha() async {
// //     _captchaToken = await RecaptchaHandler.executeV3(action: 'signup');
// //     if (_captchaToken != null) {
// //       print('Captcha token: ${_captchaToken!.substring(0, 20)}...');
// //     }
// //   }
// //
// //   void _selectDate() async {
// //     final picked = await showDatePicker(
// //       context: context,
// //       initialDate: DateTime.now().add(Duration(days: 30)),
// //       firstDate: DateTime.now(),
// //       lastDate: DateTime.now().add(Duration(days: 365 * 3)),
// //     );
// //     if (picked != null) {
// //       setState(() {
// //         _selectedDate = picked;
// //         _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
// //       });
// //     }
// //   }
// //
// //   Future<void> _handleGoogleSignUp() async {
// //     final user = await AuthService().signInWithGoogle();
// //     if (user != null) {
// //       setState(() {
// //         _isGoogleSignUp = true;
// //         _nameController.text = user.displayName ?? '';
// //         _emailController.text = user.email;
// //         _passwordController.text = "google_auth_${DateTime.now().millisecondsSinceEpoch}";
// //       });
// //     }
// //   }
// //
// //   Future<void> _sendWelcomeEmail(
// //       {required String toEmail,
// //         required String userName,
// //         required String userPassword}) async {
// //     try {
// //       final smtpServer = gmail("harshada.anantkamalstudios@gmail.com", "Pass@123");
// //       final message = Message()
// //         ..from = Address("harshada.anantkamalstudios@gmail.com", "HappyWeds Team")
// //         ..recipients.add(toEmail)
// //         ..subject = "Welcome to HappyWeds"
// //         ..html = """
// //           <h2>Hello $userName!</h2>
// //           <p>Your account has been created.</p>
// //           <p>Email: $toEmail</p>
// //           <p>Password: ${userPassword != "Google Account" ? userPassword : "Secured with Google"}</p>
// //           """;
// //
// //       await send(message, smtpServer);
// //       print("Email sent to $toEmail");
// //     } catch (e) {
// //       print("Email send failed: $e");
// //     }
// //   }
// //
// //   Future<void> _handleSignUp() async {
// //     if (!(_formKey.currentState?.validate() ?? false)) return;
// //     if (_captchaToken == null) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Captcha verification failed")),
// //       );
// //       return;
// //     }
// //
// //     final payload = {
// //       "name": _nameController.text.trim(),
// //       "email": _emailController.text.trim(),
// //       "password": _passwordController.text.trim(),
// //       "phone": _phoneController.text.trim(),
// //       "weddingVenue": _venueController.text.trim(),
// //       "country": _selectedCountry,
// //       "city": _selectedCity,
// //       "weddingDate": _selectedDate != null
// //           ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
// //           : null,
// //       "captchaToken": _captchaToken,
// //       "signupMethod": _isGoogleSignUp ? "google" : "email",
// //     };
// //
// //     print('Payload: $payload');
// //
// //     // Example: send POST to your server
// //     try {
// //       final response = await http.post(
// //         Uri.parse("https://happywedz.com/api/user/register"),
// //         headers: {"Content-Type": "application/json"},
// //         body: jsonEncode(payload),
// //       );
// //
// //       if (response.statusCode == 200 || response.statusCode == 201) {
// //         await _sendWelcomeEmail(
// //           toEmail: _emailController.text,
// //           userName: _nameController.text,
// //           userPassword: _isGoogleSignUp ? "Google Account" : _passwordController.text,
// //         );
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Registration successful!")),
// //         );
// //       } else {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("Registration failed")),
// //         );
// //       }
// //     } catch (e) {
// //       print(e);
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(content: Text("Error: $e")),
// //       );
// //     }
// //   }
// //
// //   Widget _buildInputField(String label, TextEditingController controller,
// //       {bool isPassword = false,
// //         TextInputType type = TextInputType.text,
// //         bool readOnly = false,
// //         VoidCallback? onTap,
// //         String? Function(String?)? validator}) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
// //         SizedBox(height: 6),
// //         TextFormField(
// //           controller: controller,
// //           obscureText: isPassword,
// //           keyboardType: type,
// //           readOnly: readOnly,
// //           onTap: onTap,
// //           validator: validator,
// //           decoration: InputDecoration(
// //             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// //             contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text("Sign Up"), backgroundColor: Colors.pink),
// //       body: SingleChildScrollView(
// //         padding: EdgeInsets.all(16),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             children: [
// //               _buildInputField(
// //                 "Full Name *",
// //                 _nameController,
// //                 validator: (v) => v!.isEmpty ? "Required" : null,
// //               ),
// //               SizedBox(height: 12),
// //               _buildInputField(
// //                 "Email *",
// //                 _emailController,
// //                 type: TextInputType.emailAddress,
// //                 readOnly: _isGoogleSignUp,
// //                 validator: (v) {
// //                   if (v!.isEmpty) return "Required";
// //                   if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return "Invalid email";
// //                   return null;
// //                 },
// //               ),
// //               SizedBox(height: 12),
// //               if (!_isGoogleSignUp)
// //                 _buildInputField(
// //                   "Password *",
// //                   _passwordController,
// //                   isPassword: true,
// //                   validator: (v) {
// //                     if (v!.length < 8) return "Min 8 characters";
// //                     return null;
// //                   },
// //                 ),
// //               SizedBox(height: 12),
// //               _buildInputField(
// //                 "Phone *",
// //                 _phoneController,
// //                 type: TextInputType.phone,
// //                 validator: (v) => v!.isEmpty ? "Required" : null,
// //               ),
// //               SizedBox(height: 12),
// //               _buildInputField(
// //                 "Wedding Venue",
// //                 _venueController,
// //               ),
// //               SizedBox(height: 12),
// //               DropdownButtonFormField<String>(
// //                 value: _selectedCountry,
// //                 items: _countries
// //                     .map((c) => DropdownMenuItem(value: c, child: Text(c)))
// //                     .toList(),
// //                 onChanged: (v) {
// //                   setState(() {
// //                     _selectedCountry = v;
// //                     _selectedCity = null;
// //                   });
// //                 },
// //                 decoration: InputDecoration(
// //                   labelText: "Country *",
// //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// //                 ),
// //                 validator: (v) => v == null ? "Select country" : null,
// //               ),
// //               SizedBox(height: 12),
// //               DropdownButtonFormField<String>(
// //                 value: _selectedCity,
// //                 items: (_selectedCountry != null
// //                     ? (_cities[_selectedCountry!] as List<String>)
// //                     : <String>[])
// //                     .map((c) => DropdownMenuItem<String>(
// //                   value: c,
// //                   child: Text(c),
// //                 ))
// //                     .toList(),
// //                 onChanged: (v) {
// //                   setState(() {
// //                     _selectedCity = v;
// //                   });
// //                 },
// //                 decoration: InputDecoration(
// //                   labelText: "City *",
// //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
// //                 ),
// //                 validator: (v) => v == null ? "Select city" : null,
// //               ),
// //               SizedBox(height: 12),
// //               _buildInputField(
// //                 "Wedding Date",
// //                 _dateController,
// //                 readOnly: true,
// //                 onTap: _selectDate,
// //                 validator: (v) => v!.isEmpty ? "Select date" : null,
// //               ),
// //               SizedBox(height: 20),
// //               ElevatedButton.icon(
// //                 onPressed: _handleGoogleSignUp,
// //                 icon: Icon(Icons.login, color: Colors.white),
// //                 label: Text("Continue with Gmail"),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.redAccent,
// //                   minimumSize: Size(double.infinity, 48),
// //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                 ),
// //               ),
// //               SizedBox(height: 12),
// //               ElevatedButton(
// //                 onPressed: _handleSignUp,
// //                 child: Text("Sign Up"),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: Colors.pink,
// //                   minimumSize: Size(double.infinity, 48),
// //                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //                 ),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // class SignUpScreen extends StatefulWidget {
// // //   @override
// // //   _SignUpScreenState createState() => _SignUpScreenState();
// // // }
// // //
// // // class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
// // //   final _formKey = GlobalKey<FormState>();
// // //   final TextEditingController _mobileController = TextEditingController();
// // //   final TextEditingController _phoneController = TextEditingController();
// // //   final TextEditingController _nameController = TextEditingController();
// // //   final TextEditingController _dateController = TextEditingController();
// // //   final TextEditingController _cityController = TextEditingController();
// // //   late AnimationController _fadeController;
// // //   late AnimationController _slideController;
// // //   late Animation<double> _fadeAnimation;
// // //   late Animation<Offset> _slideAnimation;
// // //   final TextEditingController _emailController = TextEditingController();
// // //   final TextEditingController _passwordController = TextEditingController();
// // //   final TextEditingController _venueController = TextEditingController();
// // //   final TextEditingController _countryController = TextEditingController();
// // //
// // //   String? _selectedRole;
// // //   DateTime? _selectedDate;
// // //   String? _captchaToken;
// // //   final List<String> roles = [
// // //     'Bride',
// // //     'Groom',
// // //     'Parent of Bride',
// // //     'Parent of Groom',
// // //     'Friend/Relative',
// // //     'Wedding Planner',
// // //     'Vendor'
// // //   ];
// // //   // String? _captchaToken; // NEW
// // //   // bool _captchaVerified = false; // NEW
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //
// // //     _fadeController = AnimationController(
// // //       duration: Duration(milliseconds: 800),
// // //       vsync: this,
// // //     );
// // //     _slideController = AnimationController(
// // //       duration: Duration(milliseconds: 600),
// // //       vsync: this,
// // //     );
// // //
// // //     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
// // //       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
// // //     );
// // //     _slideAnimation = Tween<Offset>(
// // //       begin: Offset(0.0, 0.3),
// // //       end: Offset.zero,
// // //     ).animate(CurvedAnimation(
// // //       parent: _slideController,
// // //       curve: Curves.easeOutCubic,
// // //     ));
// // //
// // //     // Start animations
// // //     _fadeController.forward();
// // //     _slideController.forward();
// // //   }
// // //
// // //
// // //   void _verifyCaptcha() async {
// // //     try {
// // //       // Await the execution, result can be null
// // //       String? token = await RecaptchaHandler.executeV3(action: 'signup');
// // //
// // //       if (token != null && token.isNotEmpty) {
// // //         setState(() {
// // //           _captchaToken = token; // safe assignment
// // //         });
// // //         print('CAPTCHA token: $token');
// // //       } else {
// // //         print('CAPTCHA verification failed: token is null or empty');
// // //       }
// // //     } catch (e) {
// // //       print('Error during CAPTCHA verification: $e');
// // //     }
// // //   }
// // //
// // //   void _handleRegistration() async {
// // //     if (!(_formKey.currentState?.validate() ?? false)) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Please fill all required fields'),
// // //           backgroundColor: Colors.red[400],
// // //           behavior: SnackBarBehavior.floating,
// // //         ),
// // //       );
// // //       return;
// // //     }
// // //
// // //     if (_captchaToken == null || _captchaToken!.isEmpty) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Please verify captcha first'),
// // //           backgroundColor: Colors.red[400],
// // //           behavior: SnackBarBehavior.floating,
// // //         ),
// // //       );
// // //       return;
// // //     }
// // //
// // //     // ✅ Verify CAPTCHA token server-side before sending registration
// // //     bool captchaVerified = false;
// // //     try {
// // //       captchaVerified = await verifyCaptcha(_captchaToken!);
// // //     } catch (e) {
// // //       print('Captcha server verification error: $e');
// // //     }
// // //
// // //     if (!captchaVerified) {
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text('Captcha verification failed. Try again.'),
// // //           backgroundColor: Colors.red[400],
// // //           behavior: SnackBarBehavior.floating,
// // //         ),
// // //       );
// // //       return;
// // //     }
// // //
// // //     // ✅ CAPTCHA verified → send registration payload
// // //     final payload = {
// // //       "name": _nameController.text.trim(),
// // //       "email": _emailController.text.trim(),
// // //       "password": _passwordController.text.trim(),
// // //       "phone": _mobileController.text.trim(),
// // //       "role": "user",
// // //       "weddingVenue": _venueController.text.trim(),
// // //       "country": _selectedCountryDropdown ?? "",
// // //       "city": _selectedCityDropdown ?? "",
// // //       "weddingDate": _selectedDate != null
// // //           ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
// // //           : "",
// // //       "captchaToken": _captchaToken,
// // //     };
// // //
// // //     try {
// // //       showDialog(
// // //         context: context,
// // //         barrierDismissible: false,
// // //         builder: (context) => Center(
// // //           child: CircularProgressIndicator(
// // //             valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
// // //           ),
// // //         ),
// // //       );
// // //
// // //       final url = Uri.parse("https://happywedz.com/api/user/register");
// // //       final response = await http.post(
// // //         url,
// // //         headers: {"Content-Type": "application/json"},
// // //         body: jsonEncode(payload),
// // //       );
// // //
// // //       Navigator.pop(context); // close loading
// // //
// // //       if (response.statusCode == 200 || response.statusCode == 201) {
// // //         await _sendWelcomeEmail(
// // //           toEmail: _emailController.text.trim(),
// // //           userName: _nameController.text.trim(),
// // //           userPassword: _passwordController.text.trim(),
// // //         );
// // //         _showSuccessDialog();
// // //       } else {
// // //         final respBody = jsonDecode(response.body);
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(
// // //             content: Text(respBody["message"] ?? "Server error"),
// // //             backgroundColor: Colors.red[400],
// // //             behavior: SnackBarBehavior.floating,
// // //           ),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       Navigator.pop(context);
// // //       ScaffoldMessenger.of(context).showSnackBar(
// // //         SnackBar(
// // //           content: Text("Error: $e"),
// // //           backgroundColor: Colors.red[400],
// // //           behavior: SnackBarBehavior.floating,
// // //         ),
// // //       );
// // //     }
// // //   }
// // //
// // //
// // //   Future<void> _sendWelcomeEmail({
// // //     required String toEmail,
// // //     required String userName,
// // //     required String userPassword,
// // //   }) async {
// // //     // Replace with your Gmail + App Password
// // //     final smtpServer = gmail("harshada.anantkamalstudios@gmail.com", "Pass@123");
// // //
// // //     final message = Message()
// // //       ..from = Address("harshada.anantkamalstudios@gmail.com", "HappyWeds")
// // //       ..recipients.add(toEmail)
// // //       ..subject = "Welcome to HappyWeds 🎉"
// // //       ..text = "Hello $userName,\n\n"
// // //           "Welcome to HappyWeds! 🎊\n\n"
// // //           "Your account has been created successfully.\n\n"
// // //           "Here are your login details:\n"
// // //           "Email: $toEmail\n"
// // //           "Password: $userPassword\n\n"
// // //           "Best wishes,\nTeam HappyWeds";
// // //
// // //     try {
// // //       await send(message, smtpServer);
// // //       print("✅ Email sent to $toEmail");
// // //     } catch (e) {
// // //       print("❌ Email send failed: $e");
// // //     }
// // //   }
// // //
// // //   Widget _buildEmailField() {
// // //     return _buildInputField(
// // //       label: 'Email',
// // //       controller: _emailController,
// // //       keyboardType: TextInputType.emailAddress,
// // //       hintText: 'Enter your email',
// // //       validator: (value) {
// // //         if (value?.isEmpty ?? true) return 'Email is required';
// // //         if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
// // //           return 'Enter valid email';
// // //         }
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildPasswordField() {
// // //     return _buildInputField(
// // //       label: 'Password',
// // //       controller: _passwordController,
// // //       hintText: 'Enter your password',
// // //       validator: (value) {
// // //         if (value?.isEmpty ?? true) return 'Password is required';
// // //         if (value!.length < 6) return 'Password must be at least 6 chars';
// // //         return null;
// // //       },
// // //       suffixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
// // //     );
// // //   }
// // //
// // //   _buildVenueField() {
// // //     return _buildInputField(
// // //       label: 'Wedding Venue',
// // //       controller: _venueController,
// // //       hintText: 'Enter wedding venue / location',
// // //       onTap: () {},
// // //       // Call fetch on editing complete
// // //       // OR use onChanged if you want live fetch
// // //       onEditingComplete: () {
// // //         _fetchLocationDetails(_venueController.text);
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildCountryField() {
// // //     return _buildInputField(
// // //       label: 'Country',
// // //       controller: _countryController,
// // //       hintText: 'Enter country',
// // //     );
// // //   }
// // //   String? _selectedCountryDropdown;
// // //   String? _selectedCityDropdown;
// // //
// // //   final Map<String, List<String>> countryCityMap = {
// // //     'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai'],
// // //     'USA': ['New York', 'Los Angeles', 'Chicago'],
// // //     'UK': ['London', 'Manchester', 'Liverpool'],
// // //   };
// // //
// // //   // 🔹 Fetch Country & City from Venue using OpenStreetMap
// // //   Future<void> _fetchLocationDetails(String venue) async {
// // //     if (venue.isEmpty) return;
// // //     final url = Uri.parse(
// // //         "https://nominatim.openstreetmap.org/search?q=$venue&format=json&addressdetails=1");
// // //
// // //     try {
// // //       final response = await http.get(url, headers: {
// // //         "User-Agent": "HappyWedsApp/1.0" // required by Nominatim
// // //       });
// // //
// // //       if (response.statusCode == 200) {
// // //         final data = json.decode(response.body);
// // //         if (data != null && data.isNotEmpty) {
// // //           final address = data[0]["address"];
// // //
// // //           final city = address["city"] ?? address["town"] ?? address["village"] ?? "";
// // //           final country = address["country"] ?? "";
// // //
// // //           setState(() {
// // //             _cityController.text = city;  // optional, if you want text also
// // //             _venueController.text = venue;
// // //
// // //             // Update dropdown selections if country exists in our map
// // //             if (countryCityMap.containsKey(country)) {
// // //               _selectedCountryDropdown = country;
// // //               final cities = countryCityMap[country]!;
// // //               if (cities.contains(city)) {
// // //                 _selectedCityDropdown = city;
// // //               } else {
// // //                 _selectedCityDropdown = null;
// // //               }
// // //             }
// // //           });
// // //         }
// // //       }
// // //     } catch (e) {
// // //       print("Error fetching location: $e");
// // //     }
// // //   }
// // //   Widget _buildCountryDropdown() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text('Country', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //           ),
// // //           child: DropdownButtonFormField<String>(
// // //             value: _selectedCountryDropdown,
// // //             decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
// // //             hint: Text('Select country'),
// // //             items: countryCityMap.keys.map((country) => DropdownMenuItem(value: country, child: Text(country))).toList(),
// // //             onChanged: (value) {
// // //               setState(() {
// // //                 _selectedCountryDropdown = value;
// // //                 _selectedCityDropdown = null;
// // //               });
// // //             },
// // //             validator: (value) => value == null ? 'Please select a country' : null,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildCityDropdown() {
// // //     final cities = _selectedCountryDropdown != null
// // //         ? countryCityMap[_selectedCountryDropdown]!
// // //         : <String>[];
// // //
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text('City', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //           ),
// // //           child: DropdownButtonFormField<String>(
// // //             value: _selectedCityDropdown,
// // //             decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
// // //             hint: Text('Select city'),
// // //             items: cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
// // //             onChanged: (value) {
// // //               setState(() {
// // //                 _selectedCityDropdown = value;
// // //               });
// // //             },
// // //             validator: (value) => value == null ? 'Please select a city' : null,
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //
// // //
// // //   @override
// // //   void dispose() {
// // //     _fadeController.dispose();
// // //     _slideController.dispose();
// // //     _mobileController.dispose();
// // //     _phoneController.dispose();
// // //     _nameController.dispose();
// // //     _dateController.dispose();
// // //     _cityController.dispose();
// // //     _emailController.dispose();
// // //     _passwordController.dispose();
// // //     _venueController.dispose();
// // //     _countryController.dispose();
// // //     super.dispose();
// // //   }
// // //
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       backgroundColor: Colors.white,
// // //       appBar: _buildAppBar(),
// // //       body: FadeTransition(
// // //         opacity: _fadeAnimation,
// // //         child: SlideTransition(
// // //           position: _slideAnimation,
// // //           child: SingleChildScrollView(
// // //             padding: EdgeInsets.all(24),
// // //             child: Form(
// // //               key: _formKey,
// // //               child: Column(
// // //                 crossAxisAlignment: CrossAxisAlignment.start,
// // //                 children: [
// // //                   SizedBox(height: 20),
// // //                   _buildSignUpTitle(),
// // //                   SizedBox(height: 40),
// // //                   _buildFullNameField(),
// // //                   SizedBox(height: 20),
// // //                   _buildEmailField(),
// // //                   SizedBox(height: 20),
// // //                   _buildPasswordField(),
// // //                   SizedBox(height: 20),
// // //                   _buildMobileNumberField(),
// // //                   // SizedBox(height: 20),
// // //                   // _buildPhoneNumberField(),
// // //                   SizedBox(height: 20),
// // //                   _buildVenueField(),
// // //                   SizedBox(height: 20),
// // //                   _buildCountryDropdown(),
// // //                   SizedBox(height: 20),
// // //                   _buildCityDropdown(),
// // //
// // //                   // _buildCountryField(),
// // //                   // SizedBox(height: 20),
// // //                   // _buildCityField(),
// // //                   SizedBox(height: 20),
// // //                   _buildWeddingDateField(),
// // //                   SizedBox(height: 20),
// // //                   _buildCaptchaField(),
// // //                   // SizedBox(height: 20),
// // //                   // _buildRoleField(),
// // //                   SizedBox(height: 20),
// // //                   _buildCompleteRegistrationButton(),
// // //                   SizedBox(height: 20),
// // //                   _buildGoogleButton()
// // //                 ],
// // //               ),
// // //
// // //             ),
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //   Widget _buildCaptchaField() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Captcha Verification',
// // //           style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
// // //         ),
// // //         SizedBox(height: 8),
// // //         ElevatedButton(
// // //           onPressed: _verifyCaptcha,
// // //           style: ElevatedButton.styleFrom(
// // //             backgroundColor: Color(0xFFE91E63),
// // //             padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
// // //             shape: RoundedRectangleBorder(
// // //               borderRadius: BorderRadius.circular(12),
// // //             ),
// // //           ),
// // //           child: Text(
// // //             _captchaToken != null ? "Captcha Verified ✅" : "Verify Captcha",
// // //             style: TextStyle(color: Colors.white),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   PreferredSizeWidget _buildAppBar() {
// // //     return AppBar(
// // //       elevation: 0,
// // //       backgroundColor: Color(0xFFE91E63),
// // //       systemOverlayStyle: SystemUiOverlayStyle.light,
// // //       leading: IconButton(
// // //         icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
// // //         onPressed: () => Navigator.pop(context),
// // //       ),
// // //       title: Text(
// // //         'Profile',
// // //         style: TextStyle(
// // //           color: Colors.white,
// // //           fontSize: 18,
// // //           fontWeight: FontWeight.w600,
// // //         ),
// // //       ),
// // //       centerTitle: true,
// // //     );
// // //   }
// // //
// // //   Widget _buildSignUpTitle() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.center,
// // //       children: [
// // //         Center(
// // //           child: Text(
// // //             'Sign up',
// // //             style: TextStyle(
// // //               fontSize: 32,
// // //               fontWeight: FontWeight.bold,
// // //               color: Colors.black87,
// // //             ),
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Center(
// // //           child: Row(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               Text(
// // //                 "Already have an account?",
// // //                 style: TextStyle(
// // //                   fontSize: 14,
// // //                   color: Colors.grey[600],
// // //                 ),
// // //               ),
// // //               SizedBox(width: 4),
// // //               GestureDetector(
// // //                 onTap: () => Navigator.pop(context),
// // //                 child: Text(
// // //                   'Login',
// // //                   style: TextStyle(
// // //                     fontSize: 14,
// // //                     color: Color(0xFFE91E63),
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildInputField({
// // //     required String label,
// // //     required TextEditingController controller,
// // //     TextInputType keyboardType = TextInputType.text,
// // //     String? Function(String?)? validator,
// // //     Widget? suffixIcon,
// // //     bool readOnly = false,
// // //     VoidCallback? onTap,
// // //     VoidCallback? onEditingComplete, // ✅ Added this
// // //     String? hintText,
// // //   }) {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           label,
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: TextFormField(
// // //             controller: controller,
// // //             keyboardType: keyboardType,
// // //             readOnly: readOnly,
// // //             onTap: onTap,
// // //             onEditingComplete: onEditingComplete, // ✅ Pass it here
// // //             validator: validator,
// // //             decoration: InputDecoration(
// // //               border: InputBorder.none,
// // //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// // //               hintText: hintText ?? 'Enter $label',
// // //               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
// // //               suffixIcon: suffixIcon,
// // //             ),
// // //             style: TextStyle(fontSize: 16),
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildMobileNumberField() {
// // //     return _buildInputField(
// // //       label: 'Mobile Number',
// // //       controller: _mobileController,
// // //       keyboardType: TextInputType.phone,
// // //       hintText: '+91 XXXXX XXXXX',
// // //       validator: (value) {
// // //         if (value?.isEmpty ?? true) return 'Mobile number is required';
// // //         if (value!.length < 10) return 'Enter valid mobile number';
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildPhoneNumberField() {
// // //     return _buildInputField(
// // //       label: 'Phone Number',
// // //       controller: _phoneController,
// // //       keyboardType: TextInputType.phone,
// // //       hintText: 'Alternative phone number',
// // //     );
// // //   }
// // //
// // //   Widget _buildFullNameField() {
// // //     return _buildInputField(
// // //       label: 'Full Name',
// // //       controller: _nameController,
// // //       keyboardType: TextInputType.name,
// // //       hintText: 'Enter your full name',
// // //       validator: (value) {
// // //         if (value?.isEmpty ?? true) return 'Full name is required';
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildWeddingDateField() {
// // //     return _buildInputField(
// // //       label: 'Do you have a wedding date',
// // //       controller: _dateController,
// // //       readOnly: true,
// // //       hintText: 'mm/dd/yyyy',
// // //       onTap: () => _selectDate(),
// // //       suffixIcon: Icon(Icons.calendar_today_outlined, color: Colors.grey[400], size: 20),
// // //     );
// // //   }
// // //
// // //   Widget _buildCityField() {
// // //     return _buildInputField(
// // //       label: 'City',
// // //       controller: _cityController,
// // //       hintText: 'Enter your city',
// // //       validator: (value) {
// // //         if (value?.isEmpty ?? true) return 'City is required';
// // //         return null;
// // //       },
// // //     );
// // //   }
// // //
// // //   Widget _buildRoleField() {
// // //     return Column(
// // //       crossAxisAlignment: CrossAxisAlignment.start,
// // //       children: [
// // //         Text(
// // //           'Tell us who you are',
// // //           style: TextStyle(
// // //             fontSize: 14,
// // //             color: Colors.grey[700],
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //         SizedBox(height: 8),
// // //         Container(
// // //           decoration: BoxDecoration(
// // //             color: Color(0xFFF8F9FA),
// // //             borderRadius: BorderRadius.circular(12),
// // //             border: Border.all(color: Color(0xFFE9ECEF)),
// // //             boxShadow: [
// // //               BoxShadow(
// // //                 color: Colors.black.withValues(alpha: 0.02),
// // //                 blurRadius: 4,
// // //                 offset: Offset(0, 2),
// // //               ),
// // //             ],
// // //           ),
// // //           child: DropdownButtonFormField<String>(
// // //             value: _selectedRole,
// // //             decoration: InputDecoration(
// // //               border: InputBorder.none,
// // //               contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
// // //               hintText: 'Select your role',
// // //               hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
// // //             ),
// // //             icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
// // //             items: roles.map((role) => DropdownMenuItem(
// // //               value: role,
// // //               child: Text(role, style: TextStyle(fontSize: 16)),
// // //             )).toList(),
// // //             onChanged: (value) {
// // //               setState(() {
// // //                 _selectedRole = value;
// // //               });
// // //             },
// // //             validator: (value) {
// // //               if (value?.isEmpty ?? true) return 'Please select your role';
// // //               return null;
// // //             },
// // //           ),
// // //         ),
// // //       ],
// // //     );
// // //   }
// // //
// // //   Widget _buildCompleteRegistrationButton() {
// // //     return Container(
// // //       width: double.infinity,
// // //       decoration: BoxDecoration(
// // //         gradient: LinearGradient(
// // //           colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
// // //           begin: Alignment.topLeft,
// // //           end: Alignment.bottomRight,
// // //         ),
// // //         borderRadius: BorderRadius.circular(25),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Color(0xFFE91E63).withValues(alpha: 0.3),
// // //             blurRadius: 15,
// // //             offset: Offset(0, 8),
// // //           ),
// // //         ],
// // //       ),
// // //       child: ElevatedButton(
// // //         onPressed: _handleRegistration,
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: Colors.transparent,
// // //           shadowColor: Colors.transparent,
// // //           padding: EdgeInsets.symmetric(vertical: 18),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(25),
// // //           ),
// // //         ),
// // //         child: Text(
// // //           'Complete Registration',
// // //           style: TextStyle(
// // //             fontSize: 16,
// // //             fontWeight: FontWeight.w600,
// // //             color: Colors.white,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //   void _selectDate() async {
// // //     final DateTime? picked = await showDatePicker(
// // //       context: context,
// // //       initialDate: DateTime.now().add(Duration(days: 30)),
// // //       firstDate: DateTime.now(),
// // //       lastDate: DateTime.now().add(Duration(days: 365 * 2)),
// // //       builder: (context, child) {
// // //         return Theme(
// // //           data: Theme.of(context).copyWith(
// // //             colorScheme: ColorScheme.light(
// // //               primary: Color(0xFFE91E63),
// // //               onPrimary: Colors.white,
// // //               onSurface: Colors.black,
// // //             ),
// // //           ),
// // //           child: child!,
// // //         );
// // //       },
// // //     );
// // //
// // //     if (picked != null) {
// // //       setState(() {
// // //         _selectedDate = picked;
// // //         // When setting _dateController
// // //         _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}";
// // //
// // //         // _dateController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
// // //       });
// // //     }
// // //   }
// // //
// // //   Widget _buildGoogleButton() {
// // //     return Container(
// // //       width: double.infinity,
// // //       decoration: BoxDecoration(
// // //         color: Colors.white,
// // //         borderRadius: BorderRadius.circular(25),
// // //         border: Border.all(color: Color(0xFFE9ECEF)),
// // //         boxShadow: [
// // //           BoxShadow(
// // //             color: Colors.black.withValues(alpha: 0.05),
// // //             blurRadius: 10,
// // //             offset: Offset(0, 2),
// // //           ),
// // //         ],
// // //       ),
// // //       child: ElevatedButton.icon(
// // //         onPressed: () async {
// // //           final user = await AuthService().signInWithGoogle();
// // //           if (user != null) {
// // //             print("Signed in: ${user.displayName}, ${user.email}");
// // //           } else {
// // //             print("Sign in failed or cancelled");
// // //           }
// // //         },
// // //
// // //         style: ElevatedButton.styleFrom(
// // //           backgroundColor: Colors.white,
// // //           foregroundColor: Colors.black87,
// // //           shadowColor: Colors.transparent,
// // //           padding: EdgeInsets.symmetric(vertical: 16),
// // //           shape: RoundedRectangleBorder(
// // //             borderRadius: BorderRadius.circular(25),
// // //           ),
// // //         ),
// // //         icon: Container(
// // //           width: 20,
// // //           height: 20,
// // //           decoration: BoxDecoration(
// // //             image: DecorationImage(
// // //               image: NetworkImage('https://developers.google.com/identity/images/g-logo.png'),
// // //             ),
// // //           ),
// // //         ),
// // //         label: Text(
// // //           'Continue with Google',
// // //           style: TextStyle(
// // //             fontSize: 16,
// // //             fontWeight: FontWeight.w500,
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // //
// // //
// // //   void _showSuccessDialog() {
// // //     showDialog(
// // //       context: context,
// // //       barrierDismissible: false,
// // //       builder: (context) => Dialog(
// // //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// // //         child: Padding(
// // //           padding: EdgeInsets.all(24),
// // //           child: Column(
// // //             mainAxisSize: MainAxisSize.min,
// // //             children: [
// // //               Container(
// // //                 width: 80,
// // //                 height: 80,
// // //                 decoration: BoxDecoration(
// // //                   color: Color(0xFFE91E63).withValues(alpha: 0.1),
// // //                   shape: BoxShape.circle,
// // //                 ),
// // //                 child: Icon(
// // //                   Icons.check_circle_outline,
// // //                   size: 40,
// // //                   color: Color(0xFFE91E63),
// // //                 ),
// // //               ),
// // //               SizedBox(height: 24),
// // //               Text(
// // //                 'Registration Successful!',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(
// // //                   fontSize: 20,
// // //                   fontWeight: FontWeight.bold,
// // //                   color: Colors.black87,
// // //                 ),
// // //               ),
// // //               SizedBox(height: 12),
// // //               Text(
// // //                 'Welcome to HappyWeds! Your account has been created successfully.',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(
// // //                   fontSize: 14,
// // //                   color: Colors.grey[600],
// // //                   height: 1.4,
// // //                 ),
// // //               ),
// // //               SizedBox(height: 32),
// // //               SizedBox(
// // //                 width: double.infinity,
// // //                 child: ElevatedButton(
// // //                   onPressed: () {
// // //                     Navigator.pop(context);
// // //                     Navigator.pop(context); // Go back to previous screen
// // //                   },
// // //                   style: ElevatedButton.styleFrom(
// // //                     backgroundColor: Color(0xFFE91E63),
// // //                     padding: EdgeInsets.symmetric(vertical: 16),
// // //                     shape: RoundedRectangleBorder(
// // //                       borderRadius: BorderRadius.circular(25),
// // //                     ),
// // //                   ),
// // //                   child: Text(
// // //                     'Get Started',
// // //                     style: TextStyle(
// // //                       fontSize: 16,
// // //                       fontWeight: FontWeight.w600,
// // //                       color: Colors.white,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // //
// // //
// // // Future<bool> verifyCaptcha(String token) async {
// // //   final response = await http.post(
// // //     Uri.parse('https://www.google.com/recaptcha/api/siteverify'),
// // //     headers: {"Content-Type": "application/x-www-form-urlencoded"},
// // //     body: {
// // //       'secret': '6Lfh29UrAAAAAELnNO3hztAwReacEmVjtz8XVSZm', // Replace with your secret key
// // //       'response': token,
// // //     },
// // //   );
// // //
// // //   if (response.statusCode == 200) {
// // //     final data = jsonDecode(response.body);
// // //     return data['success'] == true;
// // //   } else {
// // //     throw Exception('Failed to verify CAPTCHA');
// // //   }
// // // }
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// //
// // // 6Lfh29UrAAAAAOl0cLa6dFknlONpgs3Q6xQowMDc site key
// // //6Lfh29UrAAAAAELnNO3hztAwReacEmVjtz8XVSZm secret key
// // lib/main.dart
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
//
//
//
// class AuthService {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email', 'profile'],
//     // clientId only needed for web OAuth; mobile uses native config
//     clientId: '27907630225-7ej3amekq30agtsk4qfft344ths43uk1.apps.googleusercontent.com',
//   );
//
//   Future<Map<String, String>?> signInWithGoogle() async {
//     try {
//       final account = await _googleSignIn.signIn();
//       if (account == null) return null; // user cancelled
//       final auth = await account.authentication;
//       return {
//         'email': account.email,
//         'displayName': account.displayName ?? '',
//         'idToken': auth.idToken ?? '',
//         'accessToken': auth.accessToken ?? ''
//       };
//     } catch (e) {
//       debugPrint('Google sign-in error: $e');
//       return null;
//     }
//   }
// }
//
// class SignUpScreen extends StatefulWidget {
//   const SignUpScreen({super.key});
//   @override
//   _SignUpScreenState createState() => _SignUpScreenState();
// }
//
// class _SignUpScreenState extends State<SignUpScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   final _nameCtrl = TextEditingController();
//   final _emailCtrl = TextEditingController();
//   final _passwordCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _venueCtrl = TextEditingController();
//   final _dateCtrl = TextEditingController();
//
//   String? _selectedCountry;
//   String? _selectedCity;
//   DateTime? _selectedDate;
//
//   bool _isGoogleSignUp = false;
//   String? _lastRecaptchaToken;
//
//   final AuthService _auth = AuthService();
//
//   final List<String> _countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];
//   final Map<String, List<String>> _cities = {
//     'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune'],
//     'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston'],
//     'UK': ['London', 'Manchester', 'Liverpool', 'Birmingham'],
//     'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary'],
//     'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
//   };
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _emailCtrl.dispose();
//     _passwordCtrl.dispose();
//     _phoneCtrl.dispose();
//     _venueCtrl.dispose();
//     _dateCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 30)),
//       firstDate: DateTime.now(),
//       lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDate = picked;
//         _dateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
//       });
//     }
//   }
//
//   Future<void> _doGoogleSignIn() async {
//     final info = await _auth.signInWithGoogle();
//     if (info != null) {
//       setState(() {
//         _isGoogleSignUp = true;
//         _nameCtrl.text = info['displayName'] ?? '';
//         _emailCtrl.text = info['email'] ?? '';
//         _passwordCtrl.text = "google_auth_${DateTime.now().millisecondsSinceEpoch}";
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Google connected — complete the form and Sign Up')),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Google sign-in cancelled or failed')),
//       );
//     }
//   }
//   Future<String?> _getRecaptchaToken() async {
//     final tokenCompleter = Completer<String?>();
//
//     final controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..addJavaScriptChannel('RecaptchaFlutter', onMessageReceived: (msg) {
//         final token = msg.message;
//         if (!tokenCompleter.isCompleted) tokenCompleter.complete(token);
//       })
//       ..loadFlutterAsset('assets/recaptcha_v3.html');
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => Dialog(
//         child: SizedBox(
//           width: double.infinity,
//           height: 250,
//           child: WebViewWidget(controller: controller),
//         ),
//       ),
//     );
//
//     final token = await tokenCompleter.future.timeout(
//       const Duration(seconds: 15),
//       onTimeout: () {
//         if (!tokenCompleter.isCompleted) tokenCompleter.complete(null);
//         return null;
//       },
//     );
//
//     Navigator.of(context, rootNavigator: true).pop();
//     return token;
//   }
//
//   // Open a small WebView running the recaptcha_v3 HTML which calls grecaptcha.execute and posts token back
//   // Future<String?> _getRecaptchaToken() async {
//   //   final tokenCompleter = Completer<String?>();
//   //
//   //   final controller = WebViewController()
//   //     ..setJavaScriptMode(JavaScriptMode.unrestricted)
//   //     ..setNavigationDelegate(NavigationDelegate(
//   //       onPageFinished: (url) {
//   //         debugPrint('recaptcha page loaded: $url');
//   //       },
//   //     ))
//   //     ..addJavaScriptChannel('RecaptchaFlutter', onMessageReceived: (msg) {
//   //       final token = msg.message;
//   //       if (!tokenCompleter.isCompleted) tokenCompleter.complete(token);
//   //     });
//   //
//   //   // load local asset html which will call grecaptcha.execute(siteKey, {action: 'signup'}) and then post message
//   //   controller.loadFlutterAsset('assets/recaptcha_v3.html');
//   //
//   //   // show the webview in a dialog
//   //   showDialog(
//   //     context: context,
//   //     barrierDismissible: false,
//   //     builder: (_) => Dialog(
//   //       child: SizedBox(
//   //         width: double.infinity,
//   //         height: 250,
//   //         child: WebViewWidget(controller: controller),
//   //       ),
//   //     ),
//   //   );
//   //
//   //   // wait for token (or timeout)
//   //   final token = await tokenCompleter.future.timeout(
//   //     const Duration(seconds: 15),
//   //     onTimeout: () {
//   //       if (!tokenCompleter.isCompleted) tokenCompleter.complete(null);
//   //       return null;
//   //     },
//   //   );
//   //
//   //   Navigator.of(context, rootNavigator: true).pop(); // close dialog
//   //   return token;
//   // }
//
//   Future<void> _onSignUpTap() async {
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//     if (!(_formKey.currentState?.validate() ?? false)) return;
//
//     // 1️⃣ Get the reCAPTCHA token from WebView
//     final token = await _getRecaptchaToken();
//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Captcha verification failed")),
//       );
//       return;
//     }
//
//     // 2️⃣ Verify the token with Google server
//     final verificationResponse = await http.post(
//       Uri.parse('https://www.google.com/recaptcha/api/siteverify'),
//       body: {
//         'secret': '6Lfh29UrAAAAAELnNO3hztAwReacEmVjtz8XVSZm', // your secret key
//         'response': token,
//       },
//     );
//
//     final verificationResult = jsonDecode(verificationResponse.body);
//     if (!(verificationResult['success'] == true &&
//         verificationResult['score'] >= 0.5)) {
//       // reCAPTCHA failed or score too low
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Captcha verification failed")),
//       );
//       return;
//     }
//     // Get real reCAPTCHA v3 token from WebView (client-side) — must be verified server-side.
//     // final token = await _getRecaptchaToken();
//     // if (token == null || token.isEmpty) {
//     //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get reCAPTCHA token')));
//     //   return;
//     // }
//     // _lastRecaptchaToken = token; // for debugging if needed
//
//     // Build payload. If google sign-in was used, client should include idToken (optional).
//     final payload = {
//       'name': _nameCtrl.text.trim(),
//       'email': _emailCtrl.text.trim().toLowerCase(),
//       'password': _isGoogleSignUp ? null : _passwordCtrl.text.trim(),
//       'phone': _phoneCtrl.text.trim(),
//       'weddingVenue': _venueCtrl.text.trim(),
//       'country': _selectedCountry,
//       'city': _selectedCity,
//       'weddingDate': _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
//       'captchaToken': token,
//       'signupMethod': _isGoogleSignUp ? 'google' : 'email',
//     };
//         print(payload);
//     // If google sign in, try to include idToken for server verification (optional)
//     if (_isGoogleSignUp) {
//       final account = await GoogleSignIn().signInSilently(); // try to get signed-in acct
//       final auth = await account?.authentication;
//       if (auth?.idToken != null) payload['googleIdToken'] = auth!.idToken;
//     }
//
//     try {
//       final resp = await http.post(
//         Uri.parse('https://happywedz.com/api/user/register'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(payload),
//       );
//
//       if (resp.statusCode == 200 || resp.statusCode == 201) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful! Check email.')));
//       } else {
//         final body = resp.body.isEmpty ? '' : jsonDecode(resp.body);
//         debugPrint('Register failed: ${resp.statusCode} - $body');
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed: ${resp.statusCode}')));
//       }
//     } catch (e) {
//       debugPrint('Register error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }
//
//   Widget _input(String label, TextEditingController ctrl, {bool obs = false, TextInputType type = TextInputType.text, bool readOnly=false, VoidCallback? onTap, String? Function(String?)? validator}) {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
//       const SizedBox(height: 6),
//       TextFormField(
//         controller: ctrl,
//         obscureText: obs,
//         keyboardType: type,
//         readOnly: readOnly,
//         onTap: onTap,
//         validator: validator,
//         decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
//       ),
//     ]);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Signup — HappyWeds')),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(children: [
//             _input('Full Name *', _nameCtrl, validator: (v) => v==null || v.trim().isEmpty ? 'Required' : null),
//             const SizedBox(height: 12),
//             _input('Email *', _emailCtrl, type: TextInputType.emailAddress, readOnly: _isGoogleSignUp, validator: (v) {
//               if (v==null || v.trim().isEmpty) return 'Required';
//               final re = RegExp(r'^[^@]+@[^@]+\.[^@]+');
//               return re.hasMatch(v) ? null : 'Invalid email';
//             }),
//             const SizedBox(height: 12),
//             if (!_isGoogleSignUp)
//               _input('Password *', _passwordCtrl, obs: true, validator: (v) => (v==null||v.length<8) ? 'Min 8 chars' : null),
//             const SizedBox(height: 12),
//             _input('Phone *', _phoneCtrl, type: TextInputType.phone, validator: (v) => (v==null||v.trim().length<10) ? 'Enter valid phone' : null),
//             const SizedBox(height: 12),
//             _input('Wedding Venue', _venueCtrl),
//             const SizedBox(height: 12),
//             DropdownButtonFormField<String>(
//               value: _selectedCountry,
//               items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//               onChanged: (v) { setState(() { _selectedCountry = v; _selectedCity = null; }); },
//               decoration: InputDecoration(labelText: 'Country *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
//               validator: (v) => v==null ? 'Select country' : null,
//             ),
//             const SizedBox(height: 12),
//             DropdownButtonFormField<String>(
//               value: _selectedCity,
//               items: (_selectedCountry != null ? _cities[_selectedCountry!]! : <String>[]).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//               onChanged: (v) { setState(() { _selectedCity = v; }); },
//               decoration: InputDecoration(labelText: 'City *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
//               validator: (v) => v==null ? 'Select city' : null,
//             ),
//             const SizedBox(height: 12),
//             _input('Wedding Date', _dateCtrl, readOnly: true, onTap: _selectDate, validator: (v) => v==null || v.isEmpty ? 'Select date' : null),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(onPressed: _doGoogleSignIn, icon: const Icon(Icons.login), label: const Text('Continue with Google'), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size.fromHeight(48))),
//             const SizedBox(height: 12),
//             ElevatedButton(onPressed: _onSignUpTap, child: const SizedBox(width: double.infinity, child: Center(child: Text('Sign Up'))), style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, minimumSize: const Size.fromHeight(48))),
//             const SizedBox(height: 12),
//             if (_lastRecaptchaToken != null) Text('Last token (truncated): ${_lastRecaptchaToken!.substring(0,20)}...'),
//           ]),
//         ),
//       ),
//     );
//   }
// }







import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import 'core/core.dart';

class RecaptchaHandler {
  static Future<String?> executeV3(BuildContext context) async {
    final tokenCompleter = Completer<String?>();

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RecaptchaFlutter',
        onMessageReceived: (msg) {
          if (!tokenCompleter.isCompleted) tokenCompleter.complete(msg.message);
        },
      )
      ..loadFlutterAsset('assets/file/recaptcha_v3.html');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Verifying you are human', style: AppText.cardTitle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'This only takes a moment.',
                style: AppText.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: AppRadii.rMd,
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: WebViewWidget(controller: controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final token = await tokenCompleter.future.timeout(Duration(seconds: 15), onTimeout: () {
      if (!tokenCompleter.isCompleted) tokenCompleter.complete(null);
      return null;
    });

    Navigator.of(context, rootNavigator: true).pop();
    return token;
  }
}

// class AuthService {
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email', 'profile'],
//     clientId: '27907630225-7ej3amekq30agtsk4qfft344ths43uk1.apps.googleusercontent.com', // for web
//   );
//
//   Future<GoogleSignInAccount?> signInWithGoogle() async {
//     try {
//       final account = await _googleSignIn.signIn();
//       if (account != null) print('Google sign-in: ${account.email}');
//       return account;
//     } catch (e) {
//       print('Google sign-in error: $e');
//       return null;
//     }
//   }
// }

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _selectedCountry;
  String? _selectedCity;
  DateTime? _selectedDate;
  String? _captchaToken;
  bool _isGoogleSignUp = false;

  /// True while a registration request is in flight — drives the button's
  /// loading state and blocks duplicate submissions.
  bool _isSubmitting = false;

  final List<String> _countries = ['India', 'USA', 'UK', 'Canada', 'Australia'];
  final Map<String, List<String>> _cities = {
    'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune'],
    'USA': ['New York', 'Los Angeles', 'Chicago', 'Houston'],
    'UK': ['London', 'Manchester', 'Liverpool', 'Birmingham'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary'],
    'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
  };


  Future<bool> verifyRecaptchaServerSide(String token) async {
    final response = await http.post(
      Uri.parse('https://www.google.com/recaptcha/api/siteverify'),
      body: {
        'secret': '6Lfh29UrAAAAAELnNO3hztAwReacEmVjtz8XVSZm',
        'response': token,
      },
    );
    final data = jsonDecode(response.body);
    return data['success'] == true && (data['score'] ?? 0.0) > 0.5;
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Future<void> _handleGoogleSignUp() async {
  //   final user = await AuthService().signInWithGoogle();
  //   if (user != null) {
  //     setState(() {
  //       _isGoogleSignUp = true;
  //       _nameController.text = user.displayName ?? '';
  //       _emailController.text = user.email;
  //       _passwordController.text = "google_auth_${DateTime.now().millisecondsSinceEpoch}";
  //     });
  //   }
  // }

  Future<void> _sendWelcomeEmail(String toEmail, String userName, String userPassword) async {
    try {
      final smtpServer = gmail("harshada.anantkamalstudios@gmail.com", "Pass@123"); // use app password
      final message = Message()
        ..from = Address("your-email@gmail.com", "HappyWeds Team")
        ..recipients.add(toEmail)
        ..subject = "Welcome to HappyWeds"
        ..html = """
          <h2>Hello $userName!</h2>
          <p>Your account has been created.</p>
          <p>Email: $toEmail</p>
          <p>Password: ${_isGoogleSignUp ? "Secured with Google" : userPassword}</p>
        """;
      await send(message, smtpServer);
      debugPrint("Email sent to $toEmail");
    } catch (e) {
      debugPrint("Email send failed: $e");
    }
  }

  Future<void> _handleSignUp() async {
    // Guard against duplicate submissions while a request is in flight.
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppSnackbar.warning(context, 'Please fill the highlighted fields.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    try {
      await _submitSignUp();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitSignUp() async {
    // 1️⃣ Get real reCAPTCHA token
    String? token = await RecaptchaHandler.executeV3(context);
    if (token == null) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        'We could not verify that you are human. Please try again.',
        title: 'Verification failed',
      );
      return;
    }
    // AUDIT FIX (security): the reCAPTCHA token is a single-use credential —
    // never log it. Only the fact that one was obtained is recorded.
    debugPrint('Recaptcha token obtained');
    // 2️⃣ Verify server-side
    bool verified = await verifyRecaptchaServerSide(token);
    if (!verified) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        'Verification could not be completed. Please try again.',
        title: 'Verification failed',
      );
      return;
    }
  debugPrint('Recaptcha verified');
    final payload = {
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "phone": _phoneController.text.trim(),
      "weddingVenue": _venueController.text.trim(),
      "country": _selectedCountry,
      "city": _selectedCity,
      "weddingDate": _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null,
      "captchaToken": token,
      "signupMethod": _isGoogleSignUp ? "google" : "email",
    };

    debugPrint('Payload: $payload');

    try {
      final response = await http.post(
        Uri.parse("https://happywedz.com/api/user/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _sendWelcomeEmail(_emailController.text, _nameController.text, _passwordController.text);
        if (!mounted) return;
        await SuccessPopup.show(
          context,
          title: 'Welcome to HappyWedz!',
          message: 'Your account has been created successfully.',
        );
      } else {
        if (!mounted) return;
        await ErrorPopup.show(
          context,
          title: 'Registration failed',
          message:
              "We couldn't create your account right now. Please check your details and try again.",
          onRetry: _handleSignUp,
        );
      }
    } catch (e) {
      debugPrint('${e}');
      if (!mounted) return;
      await ErrorPopup.show(
        context,
        title: AppErrorMessage.titleFor(e),
        message: AppErrorMessage.bodyFor(e),
        onRetry: _handleSignUp,
      );
    }
  }

  /// Dropdown styled to match [AppTextField].
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
    IconData icon = Icons.expand_more_rounded,
    String hint = 'Select',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
          child: RichText(
            text: TextSpan(
              text: label,
              style: AppText.formLabel,
              children: [
                TextSpan(
                  text: ' *',
                  style: AppText.formLabel.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          borderRadius: AppRadii.rMd,
          icon: Icon(icon, color: AppColors.textTertiary),
          style: AppText.body,
          hint: Text(
            hint,
            style: AppText.body.copyWith(color: AppColors.textTertiary),
          ),
          items: items
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c,
                  child: Text(c, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: _isSubmitting ? null : onChanged,
          validator: validator,
          decoration: const InputDecoration(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cities = _selectedCountry == null
        ? const <String>[]
        : (_cities[_selectedCountry!] ?? const <String>[]);

    return Scaffold(
      backgroundColor: AppColors.background,
      // resizeToAvoidBottomInset defaults to true — the scroll view below keeps
      // every field reachable while the keyboard is open.
      body: Column(
        children: [
          GradientHeader(
            child: Row(
              children: [
                if (Navigator.of(context).canPop())
                  AppBackButton(color: Colors.white),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Create your account',
                          style: AppText.pageTitle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Start planning your big day in minutes',
                          style: AppText.bodySm.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom * 0,
              ),
              child: Form(
                key: _formKey,
                child: FadeSlideIn(
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    radius: AppRadii.xl,
                    shadow: AppColors.shadowMd,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTextField(
                          label: 'Full Name',
                          required: true,
                          hint: 'Enter your full name',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSubmitting,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Email',
                          required: true,
                          hint: 'you@example.com',
                          controller: _emailController,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          readOnly: _isGoogleSignUp,
                          enabled: !_isSubmitting,
                          autofillHints: const [AutofillHints.email],
                          validator: (v) {
                            if (v == null || v.isEmpty) return "Required";
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                              return "Invalid email";
                            }
                            return null;
                          },
                        ),
                        if (!_isGoogleSignUp) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField(
                            label: 'Password',
                            required: true,
                            hint: 'At least 8 characters',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            enabled: !_isSubmitting,
                            validator: (v) {
                              if (v == null || v.length < 8) {
                                return "Min 8 characters";
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Phone',
                          required: true,
                          hint: 'Mobile number',
                          controller: _phoneController,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSubmitting,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Required" : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Wedding Venue',
                          hint: 'Where is the celebration?',
                          controller: _venueController,
                          prefixIcon: Icons.location_on_outlined,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDropdown(
                          label: 'Country',
                          value: _selectedCountry,
                          items: _countries,
                          hint: 'Select country',
                          onChanged: (v) => setState(() {
                            _selectedCountry = v;
                            _selectedCity = null;
                          }),
                          validator: (v) => v == null ? "Select country" : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _buildDropdown(
                          label: 'City',
                          value: _selectedCity,
                          items: cities,
                          hint: _selectedCountry == null
                              ? 'Select a country first'
                              : 'Select city',
                          onChanged: (v) => setState(() => _selectedCity = v),
                          validator: (v) => v == null ? "Select city" : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Wedding Date',
                          hint: 'DD/MM/YYYY',
                          controller: _dateController,
                          prefixIcon: Icons.calendar_today_outlined,
                          suffixIcon: Icons.edit_calendar_outlined,
                          readOnly: true,
                          enabled: !_isSubmitting,
                          onTap: _isSubmitting ? null : _selectDate,
                          onSuffixTap: _isSubmitting ? null : _selectDate,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Select date" : null,
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        PremiumButton(
                          label: 'Create Account',
                          icon: Icons.favorite_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _handleSignUp,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: Text('or', style: AppText.caption),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PremiumButton.outlined(
                          label: 'Continue with Gmail',
                          icon: Icons.mail_outline_rounded,
                          enabled: !_isSubmitting,
                          // onPressed: _handleGoogleSignUp,
                          onPressed: () {},
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'By continuing you agree to the HappyWedz Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: AppText.caption,
                        ),
                      ],
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
}
