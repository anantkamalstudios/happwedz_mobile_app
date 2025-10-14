import 'package:flutter/material.dart';


import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class VirtualTryOnScreennnnnnn extends StatelessWidget {
  const VirtualTryOnScreennnnnnn({Key? key}) : super(key: key);

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
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        // Navigate back
                      },
                    ),
                    const Text(
                      'Nashik',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Visual Design',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 56), // Balance the back button
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Stack(
                  children: [
                    // Background image with camera frame
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Stack(
                          children: [
                            // Placeholder for camera/image
                            Center(
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                ),
                                child: Image.asset(
                                  'assets/1g.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Corner brackets overlay
                            CustomPaint(
                              size: Size.infinite,
                              painter: FrameBracketsPainter(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content overlay - positioned inside the frame
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'VIRTUAL TRY - ON',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Wedding fit is an innovative ideas that help your perfect clothes.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),

                            // Get Started button
                            SizedBox(
                              width: 200,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Navigate to try-on
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4081),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

}

// Custom painter for corner brackets
// Custom painter for corner brackets
class FrameBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const double bracketLength = 50; // Adjusted bracket length
    const double marginHorizontal = 40; // Horizontal margin
    const double marginTop = 120; // Top margin
    const double marginBottom = 140; // Bottom margin

    // Top-left corner
    canvas.drawLine(
      Offset(marginHorizontal, marginTop),
      Offset(marginHorizontal + bracketLength, marginTop),
      paint,
    );
    canvas.drawLine(
      Offset(marginHorizontal, marginTop),
      Offset(marginHorizontal, marginTop + bracketLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - marginHorizontal, marginTop),
      Offset(size.width - marginHorizontal - bracketLength, marginTop),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - marginHorizontal, marginTop),
      Offset(size.width - marginHorizontal, marginTop + bracketLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(marginHorizontal, size.height - marginBottom),
      Offset(marginHorizontal + bracketLength, size.height - marginBottom),
      paint,
    );
    canvas.drawLine(
      Offset(marginHorizontal, size.height - marginBottom),
      Offset(marginHorizontal, size.height - marginBottom - bracketLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - marginHorizontal, size.height - marginBottom),
      Offset(size.width - marginHorizontal - bracketLength, size.height - marginBottom),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - marginHorizontal, size.height - marginBottom),
      Offset(size.width - marginHorizontal, size.height - marginBottom - bracketLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// Custom painter for corner brackets
// class FrameBracketsPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3
//       ..style = PaintingStyle.stroke;
//
//     const double bracketLength = 60;
//     const double margin = 80;
//
//     // Top-left corner
//     canvas.drawLine(
//       Offset(margin, margin),
//       Offset(margin + bracketLength, margin),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(margin, margin),
//       Offset(margin, margin + bracketLength),
//       paint,
//     );
//
//     // Top-right corner
//     canvas.drawLine(
//       Offset(size.width - margin, margin),
//       Offset(size.width - margin - bracketLength, margin),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(size.width - margin, margin),
//       Offset(size.width - margin, margin + bracketLength),
//       paint,
//     );
//
//     // Bottom-left corner
//     canvas.drawLine(
//       Offset(margin, size.height - margin - 150),
//       Offset(margin + bracketLength, size.height - margin - 150),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(margin, size.height - margin - 150),
//       Offset(margin, size.height - margin - bracketLength - 150),
//       paint,
//     );
//
//     // Bottom-right corner
//     canvas.drawLine(
//       Offset(size.width - margin, size.height - margin - 150),
//       Offset(size.width - margin - bracketLength, size.height - margin - 150),
//       paint,
//     );
//     canvas.drawLine(
//       Offset(size.width - margin, size.height - margin - 150),
//       Offset(size.width - margin, size.height - margin - bracketLength - 150),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }
// class VirtualTryOnScreennn extends StatelessWidget {
//   const VirtualTryOnScreennn({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.pink,
//
//       ),
//       body: Stack(
//         children: [
//           // 🌸 Background Image
//           Positioned.fill(
//             child: Image.asset(
//               'assets/1g.png', // Ensure this is in your assets folder and added in pubspec.yaml
//               fit: BoxFit.cover,
//             ),
//           ),
//
//           // 🌸 Dark Overlay
//           Positioned.fill(
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     Colors.black.withOpacity(0.3),
//                     Colors.black.withOpacity(0.6),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // 🌸 Main Content
//           SafeArea(
//             child: Column(
//               children: [
//                 // 🔹 Top Bar
//                 // Padding(
//                 //   padding:
//                 //   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 //   child: Row(
//                 //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 //     children: [
//                 //       Row(
//                 //         children: const [
//                 //           Icon(Icons.arrow_back_ios,
//                 //               color: Colors.white, size: 20),
//                 //           SizedBox(width: 4),
//                 //           Text(
//                 //             'Nashik',
//                 //             style: TextStyle(
//                 //               color: Colors.white,
//                 //               fontSize: 17,
//                 //               fontWeight: FontWeight.w400,
//                 //             ),
//                 //           ),
//                 //         ],
//                 //       ),
//                 //       const Text(
//                 //         'Visual Design',
//                 //         style: TextStyle(
//                 //           color: Colors.white,
//                 //           fontSize: 17,
//                 //           fontWeight: FontWeight.w600,
//                 //         ),
//                 //       ),
//                 //       const SizedBox(width: 40),
//                 //     ],
//                 //   ),
//                 // ),
//
//                 // 🌸 Center Card Section
//                 Expanded(
//                   child: Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 40),
//                       child: Stack(
//                         children: [
//                           Positioned.fill(
//                             child: _buildCornerDecorations(),
//                           ),
//                           Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                                 vertical: 60, horizontal: 20),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(20),
//                               color: Colors.white.withOpacity(0.1),
//                             ),
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 const Text(
//                                   'VIRTUAL TRY - ON',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 28,
//                                     fontWeight: FontWeight.w700,
//                                     letterSpacing: 1.5,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   'Instantly try on makeup looks and find your perfect shades.',
//                                   style: TextStyle(
//                                     color: Colors.white.withOpacity(0.9),
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w400,
//                                     height: 1.4,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                                 const SizedBox(height: 30),
//                                 SizedBox(
//                                   width: double.infinity,
//                                   height: 50,
//                                   child: ElevatedButton(
//                                     onPressed: () {
//
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(builder: (context) => const ChooseOneScreen()),
//                                       );
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color(0xFFE91E63),
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(25),
//                                       ),
//                                       elevation: 0,
//                                     ),
//                                     child: const Text(
//                                       'Get Started',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 🌸 Decorative Corner Brackets
//   Widget _buildCornerDecorations() {
//     return Stack(
//       children: const [
//         Positioned(
//           top: 0,
//           left: 0,
//           child: CustomPaint(
//             size: Size(40, 40),
//             painter: CornerBracketPainter(isTopLeft: true),
//           ),
//         ),
//         Positioned(
//           top: 0,
//           right: 0,
//           child: CustomPaint(
//             size: Size(40, 40),
//             painter: CornerBracketPainter(isTopRight: true),
//           ),
//         ),
//         Positioned(
//           bottom: 0,
//           left: 0,
//           child: CustomPaint(
//             size: Size(40, 40),
//             painter: CornerBracketPainter(isBottomLeft: true),
//           ),
//         ),
//         Positioned(
//           bottom: 0,
//           right: 0,
//           child: CustomPaint(
//             size: Size(40, 40),
//             painter: CornerBracketPainter(isBottomRight: true),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // 🌸 Painter for decorative brackets
// class CornerBracketPainter extends CustomPainter {
//   final bool isTopLeft;
//   final bool isTopRight;
//   final bool isBottomLeft;
//   final bool isBottomRight;
//
//   const CornerBracketPainter({
//     this.isTopLeft = false,
//     this.isTopRight = false,
//     this.isBottomLeft = false,
//     this.isBottomRight = false,
//   });
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white
//       ..strokeWidth = 3
//       ..style = PaintingStyle.stroke;
//
//     final path = Path();
//
//     if (isTopLeft) {
//       path.moveTo(0, size.height * 0.4);
//       path.lineTo(0, 0);
//       path.lineTo(size.width * 0.4, 0);
//     } else if (isTopRight) {
//       path.moveTo(size.width * 0.6, 0);
//       path.lineTo(size.width, 0);
//       path.lineTo(size.width, size.height * 0.4);
//     } else if (isBottomLeft) {
//       path.moveTo(0, size.height * 0.6);
//       path.lineTo(0, size.height);
//       path.lineTo(size.width * 0.4, size.height);
//     } else if (isBottomRight) {
//       path.moveTo(size.width * 0.6, size.height);
//       path.lineTo(size.width, size.height);
//       path.lineTo(size.width, size.height * 0.6);
//     }
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(CornerBracketPainter oldDelegate) => false;
// }


// Screen 2: Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController(text: 'Loisbecket@gmail.com');
  final _passwordController = TextEditingController(text: '••••••••');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B1E5F),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.network(
                'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFF8B1E5F));
                },
              ),
            ),
          ),

          Column(
            children: [
              // Top Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Naashik',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Visual Design',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Login Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Close Button
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE91E63),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login Title
                    const Center(
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Signup Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email Field
                    Text(
                      'Email or Mobile',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: 'Enter email or mobile',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE91E63)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE91E63)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFFE91E63),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Forgot Password ?',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2196F3),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ChooseOneScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Or Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Google Sign In
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 20,
                          height: 20,
                        ),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              //
              // // Bottom Navigation (same as before)
              // Container(
              //   height: 65,
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE91E63),
              //     borderRadius: const BorderRadius.only(
              //       topLeft: Radius.circular(20),
              //       topRight: Radius.circular(20),
              //     ),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceAround,
              //     children: [
              //       _buildNavItem(Icons.home, 'Home', false),
              //       _buildNavItem(Icons.store, 'Vendors', false),
              //       _buildNavItem(Icons.photo_camera, 'VirtualStudio', true),
              //       _buildNavItem(Icons.group, 'Vendors', false),
              //       _buildNavItem(Icons.menu, 'More', false),
              //     ],
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF64B5F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              if (isActive)
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// Screen 3: Choose One Screen
class ChooseOneScreen extends StatelessWidget {
  const ChooseOneScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Bar
          Container(
            color: const Color(0xFFE91E63),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Nashik',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Visual Design',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Choose one',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE91E63),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Instantly try on makeup looks and find your perfect shades.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Bride and Groom Cards
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Bride Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to Bride section
                              },
                              child: Container(

                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Transform.scale(
                                        scale: 1.2,
                                        child: Image.asset(
                                          'assets/bride.png',
                                           fit: BoxFit.cover,
                                        
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.pink[50],
                                              child: const Center(
                                                child: Icon(Icons.image, size: 150, color: Colors.grey),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.5),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 20,
                                        left: 0,
                                        right: 0,
                                        child: const Text(
                                          'Bride',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Groom Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to Groom section
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        'assets/groom.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.brown[50],
                                            child: const Center(
                                              child: Icon(Icons.image, size: 60, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.5),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 20,
                                        left: 0,
                                        right: 0,
                                        child: const Text(
                                          'Groom',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),


                          // other Card
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to Groom section
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        'assets/other.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.brown[50],
                                            child: const Center(
                                              child: Icon(Icons.image, size: 60, color: Colors.grey),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.5),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 20,
                                        left: 0,
                                        right: 0,
                                        child: const Text(
                                          'Other',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Navigation
          // Container(
          //   height: 65,
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFE91E63),
          //     borderRadius: const BorderRadius.only(
          //       topLeft: Radius.circular(20),
          //       topRight: Radius.circular(20),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceAround,
          //     children: [
          //       _buildNavItem(Icons.home, 'Home', false),
          //       _buildNavItem(Icons.store, 'Vendors', false),
          //       _buildNavItem(Icons.photo_camera, 'VirtualStudio', true),
          //       _buildNavItem(Icons.group, 'Vendors', false),
          //       _buildNavItem(Icons.menu, 'More', false),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF64B5F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              if (isActive)
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}