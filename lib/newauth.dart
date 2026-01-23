// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:http/http.dart' as http;
//
//
// class AuthHome extends StatefulWidget {
//   const AuthHome({super.key});
//   @override
//   State<AuthHome> createState() => _AuthHomeState();
// }
//
// class _AuthHomeState extends State<AuthHome> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background image (wedding theme)
//           Positioned.fill(
//             child: Image.asset(
//               'assets/image 4.png', // add your image in assets and reference in pubspec
//               fit: BoxFit.cover,
//             ),
//           ),
//
//           // Top logo or title
//           SafeArea(
//             child: Align(
//               alignment: Alignment.topCenter,
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 24.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('HappyWedz', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
//                     const SizedBox(height: 8),
//                     Text('Find vendors • Plan weddings', style: TextStyle(color: Colors.white70)),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // Bottom card like WedMeGood
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Container(
//               width: double.infinity,
//               height: size.height * 0.55,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
//                 boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
//                 child: Column(
//                   children: [
//                     // Tabs: Login / Sign up
//                     TabBar(
//                       controller: _tabController,
//                       indicatorColor: Theme.of(context).primaryColor,
//                       labelColor: Colors.black,
//                       unselectedLabelColor: Colors.grey,
//                       tabs: const [
//                         Tab(text: 'Login'),
//                         Tab(text: 'Sign up'),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Expanded(
//                       child: TabBarView(
//                         controller: _tabController,
//                         children: const [
//                           LoginScreen(),
//                           SignupScreen(),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//                     const Text('Or continue with'),
//                     const SizedBox(height: 10),
//
//                     // Google Sign-in button (styled)
//                     ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         side: BorderSide(color: Colors.grey.shade300),
//                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                       ),
//                       onPressed: () async {
//                         // call Google sign in from your auth client
//                         // we'll call via a static helper so keep UI code simple:
//                         final result = await AuthService.signInWithGoogle();
//                         if (result['success']) {
//                           // navigate or show success
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed in as ${result['email']}')));
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google sign in failed: ${result['message']}')));
//                         }
//                       },
//                       icon: Image.asset('assets/image 4.png', height: 22, width: 22),
//                       label: const Text('Continue with Google', style: TextStyle(color: Colors.black87)),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String email = '';
//   String password = '';
//   bool loading = false;
//
//   void submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() { loading = true; });
//     final res = await AuthService.login(email.trim(), password);
//     setState(() { loading = false; });
//     if (res['success']) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome ${res['user']['email']}')));
//       // navigate to app
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Login failed')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           const SizedBox(height: 12),
//           Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   decoration: const InputDecoration(labelText: 'Email'),
//                   keyboardType: TextInputType.emailAddress,
//                   onChanged: (v) => email = v,
//                   validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
//                 ),
//                 const SizedBox(height: 8),
//                 TextFormField(
//                   decoration: const InputDecoration(labelText: 'Password'),
//                   obscureText: true,
//                   onChanged: (v) => password = v,
//                   validator: (v) => (v != null && v.length >= 6) ? null : 'Password min 6 chars',
//                 ),
//                 const SizedBox(height: 18),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: loading ? null : submit,
//                     child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login'),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
//
//
// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});
//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }
//
// class _SignupScreenState extends State<SignupScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String email = '';
//   String password = '';
//   String name = '';
//   bool loading = false;
//
//   void submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() { loading = true; });
//     final res = await AuthService.register(name.trim(), email.trim(), password);
//     setState(() { loading = false; });
//     if (res['success']) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration successful — check your email')));
//       // optionally navigate to login
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Registration failed')));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(children: [
//         const SizedBox(height: 12),
//         Form(
//           key: _formKey,
//           child: Column(children: [
//             TextFormField(
//               decoration: const InputDecoration(labelText: 'Full name'),
//               onChanged: (v) => name = v,
//               validator: (v) => (v != null && v.isNotEmpty) ? null : 'Enter name',
//             ),
//             const SizedBox(height: 8),
//             TextFormField(
//               decoration: const InputDecoration(labelText: 'Email'),
//               keyboardType: TextInputType.emailAddress,
//               onChanged: (v) => email = v,
//               validator: (v) => v != null && v.contains('@') ? null : 'Enter valid email',
//             ),
//             const SizedBox(height: 8),
//             TextFormField(
//               decoration: const InputDecoration(labelText: 'Password'),
//               obscureText: true,
//               onChanged: (v) => password = v,
//               validator: (v) => (v != null && v.length >= 6) ? null : 'Password min 6 chars',
//             ),
//             const SizedBox(height: 18),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: loading ? null : submit,
//                 child: loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account'),
//               ),
//             ),
//           ]),
//         )
//       ]),
//     );
//   }
// }
//
//
//
//
// class AuthService {
//   static const String BASE_URL = "http://happywedz.com"; // e.g. http://192.168.1.20:3000
//
//   // Email registration
//   static Future<Map<String, dynamic>> register(String name, String email, String password) async {
//     final uri = Uri.parse('$BASE_URL/api/user/register');
//     final res = await http.post(uri, body: {'name': name, 'email': email, 'password': password});
//     if (res.statusCode == 200) {
//       print(jsonDecode(res.body));
//       return {'success': true, 'data': jsonDecode(res.body)};
//     } else {
//       print(res.body);
//       return {'success': false, 'message': res.body};
//     }
//
//   }
//
//   // Email login
//   static Future<Map<String, dynamic>> login(String email, String password) async {
//     final uri = Uri.parse('$BASE_URL/api/user/login');
//     final res = await http.post(uri, body: {'email': email, 'password': password});
//     if (res.statusCode == 200) {
//       print(jsonDecode(res.body));
//       return {'success': true, 'data': jsonDecode(res.body), 'user': jsonDecode(res.body)['user']};
//     } else {
//       print(res.body);
//       return {'success': false, 'message': res.body};
//     }
//   }
//
//   // Google sign in without firebase. We sign in on client, then send idToken to server for verification and/or registration.
//   static final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email', 'profile'],
//   );
//
//   static Future<Map<String, dynamic>> signInWithGoogle() async {
//     try {
//       final account = await _googleSignIn.signIn();
//       if (account == null) return {'success': false, 'message': 'Cancelled by user'};
//
//       final auth = await account.authentication;
//       final email = account.email;
//       final name = account.displayName ?? "User";
//
//       final uri = Uri.parse('$BASE_URL/api/user/register');
//       final res = await http.post(
//         uri,
//         body: {
//           'name': name,
//           'email': email,
//           'password': auth.idToken ?? 'google_login', // dummy password
//         },
//       );
//
//       if (res.statusCode == 200) {
//         final body = jsonDecode(res.body);
//         print(body);
//         return {'success': true, 'body': body};
//       } else {
//         print(res.body);
//         return {'success': false, 'message': res.body};
//       }
//     } catch (e) {
//       print(e);
//       return {'success': false, 'message': e.toString()};
//     }
//   }
// }
