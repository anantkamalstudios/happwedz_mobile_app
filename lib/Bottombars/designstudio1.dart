import 'dart:io';
//
// import 'package:flutter/material.dart';

import '../core/core.dart';
//
//
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'designstudio22.dart';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
class VirtualTryOnScreennnnnnn extends StatelessWidget {
  const VirtualTryOnScreennnnnnn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  'Design Studio',
                  style: AppText.pageTitle.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),

              // Hero frame
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      child: Image.asset(
                        'assets/1g.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey[850]),
                      ),
                    ),

                    // Scrim keeps the copy readable over any photo.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x33000000),
                            Color(0x99000000),
                          ],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),

                    CustomPaint(
                      size: Size.infinite,
                      painter: FrameBracketsPainter(),
                    ),

                    // Copy + CTA
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                          vertical: AppSpacing.xxl,
                        ),
                        child: FadeSlideIn(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VIRTUAL TRY-ON',
                                textAlign: TextAlign.center,
                                style: AppText.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Wedding fit is an innovative idea that helps '
                                'you find your perfect clothes.',
                                textAlign: TextAlign.center,
                                style: AppText.body.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              SizedBox(
                                width: 200,
                                child: PremiumButton(
                                  label: 'Get Started',
                                  trailingIcon: Icons.arrow_forward_rounded,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      AnimatedPageRoute(
                                        page:
                                            const VirtualDesignChooseScreen(),
                                        style:
                                            PageTransitionStyle.slideRight,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
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

//
// class VisualDesignScreen extends StatefulWidget {
//   final File? userImage;
//   const VisualDesignScreen({Key? key, this.userImage}) : super(key: key);
//
//   @override
//   State<VisualDesignScreen> createState() => _VisualDesignScreenState();
// }
//
// class _VisualDesignScreenState extends State<VisualDesignScreen> {
//   int _currentTab = 0;
//
//   // Shared state across tab widgets
//   int selectedCategory = 0; // 0: Foundation, 1: Lipstick, ...
//   int? selectedBrandIndex;
//   int? selectedShadeIndex;
//
//   // store final selections as map: categoryIndex -> (brandIndex, shadeIndex)
//   final Map<int, Map<String, int>> selections = {};
//
//   ImageProvider get _placeholderImage => const NetworkImage(
//       'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1200&q=80');
//
//   @override
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           // 1️⃣ AppBar
//           _buildTopBar(),
//
//           // 2️⃣ Tab content
//           Expanded(
//             child: IndexedStack(
//               index: _currentTab,
//               children: [
//                 // ✅ Shades tab: show photo + shades
//                 // Column(
//                 //   children: [
//                 //     // Photo area only in Shades tab
//                 //     Container(
//                 //       height: 525, // adjust as needed
//                 //       margin: const EdgeInsets.all(16),
//                 //       decoration: BoxDecoration(
//                 //         color: const Color(0xFFEDEDED),
//                 //         borderRadius: BorderRadius.circular(16),
//                 //         boxShadow: [
//                 //           BoxShadow(
//                 //             color: Colors.black.withValues(alpha: 0.08),
//                 //             blurRadius: 8,
//                 //             offset: const Offset(0, 4),
//                 //           ),
//                 //         ],
//                 //       ),
//                 //       child: ClipRRect(
//                 //         borderRadius: BorderRadius.circular(16),
//                 //         child: widget.userImage != null
//                 //             ? Image.file(widget.userImage!, fit: BoxFit.cover)
//                 //             : Image(image: _placeholderImage, fit: BoxFit.cover),
//                 //       ),
//                 //     ),
//                 //
//                 //     // Shades list below the photo
//                 //     Expanded(
//                 //       child: ShadesScreen(
//                 //         selectedCategory: selectedCategory,
//                 //         onCategorySelected: (catIndex) {
//                 //           setState(() {
//                 //             selectedCategory = catIndex;
//                 //             selectedBrandIndex = null;
//                 //             selectedShadeIndex = null;
//                 //           });
//                 //         },
//                 //         selectedBrandIndex: selectedBrandIndex,
//                 //         selectedShadeIndex: selectedShadeIndex,
//                 //         onBrandSelected: (brandIndex) {
//                 //           setState(() {
//                 //             selectedBrandIndex = brandIndex;
//                 //             selectedShadeIndex = null;
//                 //           });
//                 //         },
//                 //         onShadeSelected: (shadeIndex) {
//                 //           setState(() {
//                 //             selectedShadeIndex = shadeIndex;
//                 //             selections[selectedCategory] = {
//                 //               'brand': selectedBrandIndex ?? 0,
//                 //               'shade': shadeIndex
//                 //             };
//                 //           });
//                 //         },
//                 //       ),
//                 //     ),
//                 //   ],
//                 // ),
//                 // Shades tab: photo + product + brand + shades + intensity
//                 Column(
//                   children: [
//                     // 1️⃣ Photo area
//                     Container(
//                       height: 525,
//                       margin: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFEDEDED),
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.08),
//                             blurRadius: 8,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(16),
//                             child: widget.userImage != null
//                                 ? Image.file(widget.userImage!, fit: BoxFit.cover)
//                                 : Image(image: _placeholderImage, fit: BoxFit.cover),
//                           ),
//
//                           // 2️⃣ Intensity slider only if shade is selected
//                           if (selectedShadeIndex != null)
//                             Positioned(
//                               top: 50,
//                               bottom: 50,
//                               right: 8,
//                               child: RotatedBox(
//                                 quarterTurns: -1,
//                                 child: Slider(
//                                   value: selections[selectedCategory]?['intensity']?.toDouble() ?? 1.0,
//                                   min: 0.0,
//                                   max: 1.0,
//                                   onChanged: (val) {
//                                     setState(() {
//                                       selections[selectedCategory]?['intensity'] = 1;
//                                     });
//                                   },
//                                   activeColor: Colors.pink,
//                                   inactiveColor: Colors.grey[300],
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//
//                     // 3️⃣ Products + Brands + Shades
//                     Expanded(
//                       child: ShadesScreen(
//                         selectedCategory: selectedCategory,
//                         selectedBrandIndex: selectedBrandIndex,
//                         selectedShadeIndex: selectedShadeIndex,
//                         onCategorySelected: (catIndex) {
//                           setState(() {
//                             selectedCategory = catIndex;
//                             selectedBrandIndex = null;
//                             selectedShadeIndex = null;
//                           });
//                         },
//                         onBrandSelected: (brandIndex) {
//                           setState(() {
//                             selectedBrandIndex = brandIndex;
//                             selectedShadeIndex = null;
//                           });
//                         },
//                         onShadeSelected: (shadeIndex) {
//                           setState(() {
//                             selectedShadeIndex = shadeIndex;
//                             selections[selectedCategory] = {
//                               'brand': selectedBrandIndex ?? 0,
//                               'shade': shadeIndex,
//                               'intensity': 1, // default intensity
//                             };
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 // ✅ Compare tab: only CompareScreen (no photo above)
//                 CompareScreen(
//                   image: widget.userImage != null
//                       ? Image.file(widget.userImage!, fit: BoxFit.cover).image
//                       : _placeholderImage,
//                   // overlayColor: Colors.pink.withValues(alpha: 0.5), // virtual makeup effect
//                 ),
//
//                 // ✅ Complete Looks tab: just content
//                 CompleteLooksScreen(
//                   userImageProvider: widget.userImage != null
//                       ? Image.file(widget.userImage!).image
//                       : _placeholderImage,
//                   selections: selections,
//                 ),
//               ],
//             ),
//           ),
//
//           // 3️⃣ Bottom tab bar
//           _buildBottomTabs(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTopBar() {
//     return Container(
//       height: 72,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFEC1E79), Color(0xFFEF6AA9)],
//         ),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Row(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.arrow_back, color: Colors.white),
//               onPressed: () => Navigator.of(context).maybePop(),
//             ),
//             const SizedBox(width: 8),
//             const Expanded(
//               child: Center(
//                 child: Text(
//                   'Visual Design',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 18),
//                 ),
//               ),
//             ),
//             IconButton(
//               icon: const Icon(Icons.location_on, color: Colors.white),
//               onPressed: () {},
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomTabs() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Row(
//           children: [
//             _bottomTabButton('Shades', 0),
//             _bottomTabButton('Compare', 1),
//             _bottomTabButton('Complete Looks', 2),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _bottomTabButton(String label, int index) {
//     final isSelected = index == _currentTab;
//     return Expanded(
//       child: InkWell(
//         onTap: () => setState(() => _currentTab = index),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             border: Border(
//               top: BorderSide(color: isSelected ? Colors.pink : Colors.transparent, width: 3),
//             ),
//             color: isSelected ? const Color(0xFFFFF1F6) : Colors.white,
//           ),
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               color: isSelected ? Colors.pink : Colors.black54,
//               fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//


enum BarStage { categories, brands, shades }


class Brand {
  final String name;
  final List<Color> shades;
  Brand({required this.name, required this.shades});
}


class VirtualDesignChooseScreen extends StatelessWidget {
  const VirtualDesignChooseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              const _StudioAppBar(title: 'Visual Design'),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'CHOOSE ONE',
                        textAlign: TextAlign.center,
                        style: AppText.display.copyWith(
                          fontSize: 24,
                          color: AppColors.magenta,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Completely fill the screen with a single person photo',
                        textAlign: TextAlign.center,
                        style: AppText.bodySm,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      for (final option in const [
                        ('Bride', 'assets/bride.png'),
                        ('Groom', 'assets/groom.png'),
                        ('Others', 'assets/other.png'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppSpacing.xl,
                          ),
                          child: _buildOptionCard(
                            context,
                            option.$1,
                            option.$2,
                            () {
                              if (option.$1 == 'Bride') {
                                Navigator.push(
                                  context,
                                  AnimatedPageRoute(
                                    page: const VirtualDesignBrideScreen(),
                                    style: PageTransitionStyle.slideRight,
                                  ),
                                );
                              } else {
                                AppSnackbar.info(
                                  context,
                                  '${option.$1} try-on is coming soon.',
                                );
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Full-bleed option tile. Width follows the viewport — the previous fixed
  /// 377px overflowed on anything narrower than a large phone.
  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String imagePath,
    VoidCallback onTap,
  ) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rLg,
      child: ClipRRect(
        borderRadius: AppRadii.rLg,
        child: AspectRatio(
          aspectRatio: 377 / 310,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.pinkSurface,
                  child: const Icon(
                    Icons.person_rounded,
                    size: 56,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.imageScrim),
                child: SizedBox.expand(),
              ),
              Positioned(
                bottom: AppSpacing.xl,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.sectionTitle.copyWith(
                    color: Colors.white,
                    letterSpacing: 1.3,
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

/// Shared translucent app bar for the studio flow.
class _StudioAppBar extends StatelessWidget {
  const _StudioAppBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const AppBackButton(color: AppColors.textOnPrimary),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.pageTitle.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class VirtualDesignBrideScreen extends StatelessWidget {
  const VirtualDesignBrideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              const _StudioAppBar(title: 'Visual Design'),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Choose one',
                        textAlign: TextAlign.center,
                        style: AppText.display.copyWith(
                          fontSize: 22,
                          color: AppColors.magenta,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Completely fill the screen with a single person photo',
                        textAlign: TextAlign.center,
                        style: AppText.bodySm,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      _buildImageCard(
                        context,
                        'assets/group3.png',
                        'MAKEUP TRY ON',
                        onTap: () => _openConsent(context),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildImageCard(
                        context,
                        'assets/group2.png',
                        'JEWELLERY TRY ON',
                        onTap: () => AppSnackbar.info(
                          context,
                          'Jewellery try-on is coming soon.',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _buildImageCard(
                        context,
                        'assets/group1.png',
                        'OUTFIT TRY ON',
                        onTap: () => AppSnackbar.info(
                          context,
                          'Outfit try-on is coming soon.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Consent gate. Presented as a real modal — it used to be pushed as an
  /// opaque page route, which rendered the dialog on a bare background.
  void _openConsent(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (_) => const PrivacyPopupDialog(),
    );
  }

  /// Try-on tile. Height follows the viewport instead of a fixed 430x400,
  /// which overflowed horizontally on standard phones.
  Widget _buildImageCard(
    BuildContext context,
    String imagePath,
    String buttonText, {
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rLg,
      child: ClipRRect(
        borderRadius: AppRadii.rLg,
        child: AspectRatio(
          aspectRatio: 430 / 400,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Colors.black,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[850],
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 72,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.imageScrim),
                child: SizedBox.expand(),
              ),
              Positioned(
                bottom: AppSpacing.xxl,
                left: AppSpacing.xxxl,
                right: AppSpacing.xxxl,
                child: PremiumButton(
                  label: buttonText,
                  size: PremiumButtonSize.medium,
                  onPressed: onTap,
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
class CornerBracketsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const bracketLength = 40.0;
    const margin = 20.0;

    // Top-left corner
    canvas.drawLine(
      const Offset(margin, margin + bracketLength),
      const Offset(margin, margin),
      paint,
    );
    canvas.drawLine(
      const Offset(margin, margin),
      const Offset(margin + bracketLength, margin),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - margin - bracketLength, margin),
      Offset(size.width - margin, margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(size.width - margin, margin + bracketLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(margin, size.height - margin - bracketLength),
      Offset(margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(margin, size.height - margin),
      Offset(margin + bracketLength, size.height - margin),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - margin - bracketLength, size.height - margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, size.height - margin - bracketLength),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class PrivacyPopupDialog extends StatefulWidget {
  const PrivacyPopupDialog({Key? key}) : super(key: key);

  @override
  State<PrivacyPopupDialog> createState() => _PrivacyPopupDialogState();
}

class _PrivacyPopupDialogState extends State<PrivacyPopupDialog> {
  bool consent1 = true;
  bool consent2 = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Our Privacy",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD81B60),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFD81B60)),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const SizedBox(height: 8),

              const Text(
                "To access this service, you must be at least 18 years old. By continuing, you agree that HappyWedz may temporarily store your uploaded image only for the purpose of applying AI filters and generating your virtual try-on experience. Your photos are never shared, sold, or used for any purpose other than providing this feature. Images are stored securely and automatically deleted within a short period after processing, in line with our data retention policy.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              _buildCheckbox(
                value: consent1,
                onChanged: (val) => setState(() => consent1 = val!),
                text: "I agree to use my image for AI try-on filters.",
              ),
              const SizedBox(height: 8),
              _buildCheckbox(
                value: consent2,
                onChanged: (val) => setState(() => consent2 = val!),
                text: "I am 18+ and accept HappyWedz’s privacy terms.",
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (consent1 && consent2)
                      ? () {
                    Navigator.of(context).pop(); // close popup first
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MakeupTryOnScreen123(),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    disabledBackgroundColor:
                    const Color(0xFFD81B60).withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "I Consent",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required Function(bool?) onChanged,
    required String text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFD81B60),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// Colours now come from AppColors (lib/core/theme/app_colors.dart) — the
// values are identical, they just live in one place now.


//
//
// // // Screen 1: Makeup Try-On Screen
// // class MakeupTryOnScreen123 extends StatelessWidget {
// //   const MakeupTryOnScreen123({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Header
// //             Container(
// //               width: double.infinity,
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [AppColors.primary, AppColors.primaryDeep],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back, color: Colors.white),
// //                     onPressed: () {},
// //                   ),
// //                   const Expanded(
// //                     child: Text(
// //                       'Visual Design',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.info_outline, color: Colors.white),
// //                     onPressed: () {},
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // Main Content
// //             Expanded(
// //               child: SingleChildScrollView(
// //                 child: Column(
// //                   children: [
// //                     const SizedBox(height: 16),
// //
// //                     // Title Section
// //                     const Padding(
// //                       padding: EdgeInsets.symmetric(horizontal: 24),
// //                       child: Text(
// //                         'Virtual Try - On',
// //                         style: TextStyle(
// //                           fontSize: 24,
// //                           fontWeight: FontWeight.bold,
// //                           color: AppColors.textPrimary,
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     const Padding(
// //                       padding: EdgeInsets.symmetric(horizontal: 24),
// //                       child: Text(
// //                         'Instantly try on makeup looks virtually before you order',
// //                         style: TextStyle(
// //                           fontSize: 14,
// //                           color: AppColors.textSecondary,
// //                         ),
// //                         textAlign: TextAlign.center,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 24),
// //
// //                     // Model Image with Try On Text
// //                     Stack(
// //                       alignment: Alignment.center,
// //                       children: [
// //                         Container(
// //                           width: MediaQuery.of(context).size.width * 0.85,
// //                           height: 400,
// //                           decoration: BoxDecoration(
// //                             borderRadius: BorderRadius.circular(20),
// //                             boxShadow: [
// //                               BoxShadow(
// //                                 color: Colors.black.withValues(alpha: 0.1),
// //                                 blurRadius: 10,
// //                                 offset: const Offset(0, 5),
// //                               ),
// //                             ],
// //                           ),
// //                           child: ClipRRect(
// //                             borderRadius: BorderRadius.circular(20),
// //                             child: Image.asset(
// //                               'assets/rect.png',
// //                               fit: BoxFit.cover,
// //                             ),
// //                           ),
// //                         ),
// //                         Positioned(
// //                           top: 20,
// //                           child: Container(
// //                             padding: const EdgeInsets.symmetric(
// //                               horizontal: 16,
// //                               vertical: 8,
// //                             ),
// //                             decoration: BoxDecoration(
// //                               color: Colors.white.withValues(alpha: 0.9),
// //                               borderRadius: BorderRadius.circular(20),
// //                               boxShadow: [
// //                                 BoxShadow(
// //                                   color: Colors.black.withValues(alpha: 0.1),
// //                                   blurRadius: 8,
// //                                 ),
// //                               ],
// //                             ),
// //                             child: const Text(
// //                               'Instantly try on makeup',
// //                               style: TextStyle(
// //                                 fontSize: 12,
// //                                 fontWeight: FontWeight.w500,
// //                                 color: AppColors.textPrimary,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                     const SizedBox(height: 24),
// //
// //                     // Action Buttons
// //                     Padding(
// //                       padding: const EdgeInsets.symmetric(horizontal: 24),
// //                       child: Column(
// //                         children: [
// //                           SizedBox(
// //                             width: double.infinity,
// //                             height: 50,
// //                             child: ElevatedButton(
// //                               onPressed: () {},
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: AppColors.primary,
// //                                 shape: RoundedRectangleBorder(
// //                                   borderRadius: BorderRadius.circular(25),
// //                                 ),
// //                                 elevation: 3,
// //                               ),
// //                               child: const Text(
// //                                 'SELFIE MODE',
// //                                 style: TextStyle(
// //                                   fontSize: 16,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: Colors.white,
// //                                   letterSpacing: 1.2,
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                           const SizedBox(height: 16),
// //                           SizedBox(
// //                             width: double.infinity,
// //                             height: 50,
// //                             child: ElevatedButton(
// //                               onPressed: () {
// //                                 Navigator.push(
// //                                   context,
// //                                   MaterialPageRoute(
// //                                     builder: (context) => const PhotoInstructionsScreen(),
// //                                   ),
// //                                 );
// //                               },
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: AppColors.primary,
// //                                 shape: RoundedRectangleBorder(
// //                                   borderRadius: BorderRadius.circular(25),
// //                                 ),
// //                                 elevation: 3,
// //                               ),
// //                               child: const Text(
// //                                 'UPLOAD PHOTO',
// //                                 style: TextStyle(
// //                                   fontSize: 16,
// //                                   fontWeight: FontWeight.bold,
// //                                   color: Colors.white,
// //                                   letterSpacing: 1.2,
// //                                 ),
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     const SizedBox(height: 24),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// // // Screen 2: Photo Instructions Screen
// // class PhotoInstructionsScreen extends StatelessWidget {
// //   const PhotoInstructionsScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Header
// //             Container(
// //               width: double.infinity,
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [AppColors.primary, AppColors.primaryDeep],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back, color: Colors.white),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const Expanded(
// //                     child: Text(
// //                       'Visual Design',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.info_outline, color: Colors.white),
// //                     onPressed: () {},
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // Content
// //             Expanded(
// //               child: SingleChildScrollView(
// //                 padding: const EdgeInsets.all(24),
// //                 child: Column(
// //                   crossAxisAlignment: CrossAxisAlignment.start,
// //                   children: [
// //                     const Text(
// //                       'Photo instructions',
// //                       style: TextStyle(
// //                         fontSize: 24,
// //                         fontWeight: FontWeight.bold,
// //                         color: AppColors.textPrimary,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 24),
// //
// //                     // Instruction Items
// //                     _buildInstructionItem(
// //                       'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
// //                       'Look straight at camera',
// //                     ),
// //                     const SizedBox(height: 16),
// //                     _buildInstructionItem(
// //                       'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100',
// //                       'Put hair back',
// //                     ),
// //                     const SizedBox(height: 16),
// //                     _buildInstructionItem(
// //                       'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
// //                       'Remove glasses',
// //                     ),
// //                     const SizedBox(height: 16),
// //                     _buildInstructionItem(
// //                       'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=100',
// //                       'Plain background',
// //                     ),
// //                     const SizedBox(height: 32),
// //
// //                     // Upload Button
// //                     SizedBox(
// //                       width: double.infinity,
// //                       height: 50,
// //                       child: ElevatedButton(
// //                         onPressed: () {
// //                           Navigator.push(
// //                             context,
// //                             MaterialPageRoute(
// //                               builder: (context) => const UploadPhotoScreen(),
// //                             ),
// //                           );
// //                         },
// //                         style: ElevatedButton.styleFrom(
// //                           backgroundColor: AppColors.primary,
// //                           shape: RoundedRectangleBorder(
// //                             borderRadius: BorderRadius.circular(25),
// //                           ),
// //                           elevation: 3,
// //                         ),
// //                         child: const Text(
// //                           'UPLOAD PHOTO',
// //                           style: TextStyle(
// //                             fontSize: 16,
// //                             fontWeight: FontWeight.bold,
// //                             color: Colors.white,
// //                             letterSpacing: 1.2,
// //                           ),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildInstructionItem(String imageUrl, String text) {
// //     return Row(
// //       children: [
// //         Container(
// //           width: 60,
// //           height: 60,
// //           decoration: BoxDecoration(
// //             borderRadius: BorderRadius.circular(10),
// //             boxShadow: [
// //               BoxShadow(
// //                 color: Colors.black.withValues(alpha: 0.1),
// //                 blurRadius: 5,
// //                 offset: const Offset(0, 2),
// //               ),
// //             ],
// //           ),
// //           child: ClipRRect(
// //             borderRadius: BorderRadius.circular(10),
// //             child: Image.network(
// //               imageUrl,
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //         ),
// //         const SizedBox(width: 16),
// //         Expanded(
// //           child: Text(
// //             text,
// //             style: const TextStyle(
// //               fontSize: 16,
// //               color: AppColors.textPrimary,
// //               fontWeight: FontWeight.w400,
// //             ),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // // Screen 3: Upload Photo Screen with Options
// // class UploadPhotoScreen extends StatefulWidget {
// //   const UploadPhotoScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   State<UploadPhotoScreen> createState() => _UploadPhotoScreenState();
// // }
// //
// // class _UploadPhotoScreenState extends State<UploadPhotoScreen> {
// //   String? selectedImage;
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Header
// //             Container(
// //               width: double.infinity,
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [AppColors.primary, AppColors.primaryDeep],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back, color: Colors.white),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const Expanded(
// //                     child: Text(
// //                       'Visual Design',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.info_outline, color: Colors.white),
// //                     onPressed: () {},
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // Content
// //             Expanded(
// //               child: Column(
// //                 children: [
// //                   const SizedBox(height: 20),
// //
// //                   // Photo Display Area
// //                   Expanded(
// //                     child: Container(
// //                       margin: const EdgeInsets.symmetric(horizontal: 24),
// //                       decoration: BoxDecoration(
// //                         color: Colors.white,
// //                         borderRadius: BorderRadius.circular(20),
// //                         border: Border.all(
// //                           color: AppColors.primary.withValues(alpha: 0.3),
// //                           width: 2,
// //                         ),
// //                         boxShadow: [
// //                           BoxShadow(
// //                             color: Colors.black.withValues(alpha: 0.05),
// //                             blurRadius: 10,
// //                             offset: const Offset(0, 5),
// //                           ),
// //                         ],
// //                       ),
// //                       child: selectedImage != null
// //                           ? ClipRRect(
// //                         borderRadius: BorderRadius.circular(18),
// //                         child: Image.network(
// //                           selectedImage!,
// //                           fit: BoxFit.cover,
// //                         ),
// //                       )
// //                           : Center(
// //                         child: Column(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             Icon(
// //                               Icons.person_outline,
// //                               size: 80,
// //                               color: AppColors.primary.withValues(alpha: 0.3),
// //                             ),
// //                             const SizedBox(height: 16),
// //                             const Text(
// //                               'Upload your photo',
// //                               style: TextStyle(
// //                                 fontSize: 16,
// //                                 color: AppColors.textSecondary,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //
// //                   const SizedBox(height: 20),
// //
// //                   // Skin Tone Options
// //                   Container(
// //                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
// //                     child: Column(
// //                       crossAxisAlignment: CrossAxisAlignment.start,
// //                       children: [
// //                         const Text(
// //                           'Select skin tone',
// //                           style: TextStyle(
// //                             fontSize: 14,
// //                             fontWeight: FontWeight.w500,
// //                             color: AppColors.textPrimary,
// //                           ),
// //                         ),
// //                         const SizedBox(height: 12),
// //                         SizedBox(
// //                           height: 80,
// //                           child: ListView(
// //                             scrollDirection: Axis.horizontal,
// //                             children: [
// //                               _buildSkinToneOption(const Color(0xFFF4D4C3), 'Light'),
// //                               _buildSkinToneOption(const Color(0xFFE5B89D), 'Medium Light'),
// //                               _buildSkinToneOption(const Color(0xFFD6A07B), 'Medium'),
// //                               _buildSkinToneOption(const Color(0xFFC48E6C), 'Tan'),
// //                               _buildSkinToneOption(const Color(0xFFA97555), 'Deep'),
// //                             ],
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //
// //                   // Action Buttons
// //                   Container(
// //                     padding: const EdgeInsets.all(24),
// //                     decoration: BoxDecoration(
// //                       color: AppColors.pinkSurface,
// //                       borderRadius: const BorderRadius.only(
// //                         topLeft: Radius.circular(30),
// //                         topRight: Radius.circular(30),
// //                       ),
// //                     ),
// //                     child: Row(
// //                       children: [
// //                         Expanded(
// //                           child: ElevatedButton(
// //                             onPressed: () {
// //                               setState(() {
// //                                 selectedImage = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400';
// //                               });
// //                             },
// //                             style: ElevatedButton.styleFrom(
// //                               backgroundColor: AppColors.primary,
// //                               padding: const EdgeInsets.symmetric(vertical: 14),
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(25),
// //                               ),
// //                               elevation: 2,
// //                             ),
// //                             child: const Text(
// //                               'Shades',
// //                               style: TextStyle(
// //                                 fontSize: 15,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: Colors.white,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(width: 12),
// //                         Expanded(
// //                           child: OutlinedButton(
// //                             onPressed: () {
// //                               Navigator.push(
// //                                 context,
// //                                 MaterialPageRoute(
// //                                   builder: (context) => const CompareLooksScreen(),
// //                                 ),
// //                               );
// //                             },
// //                             style: OutlinedButton.styleFrom(
// //                               padding: const EdgeInsets.symmetric(vertical: 14),
// //                               side: const BorderSide(
// //                                 color: AppColors.primary,
// //                                 width: 2,
// //                               ),
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(25),
// //                               ),
// //                             ),
// //                             child: const Text(
// //                               'Compare',
// //                               style: TextStyle(
// //                                 fontSize: 15,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: AppColors.primary,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                         const SizedBox(width: 12),
// //                         Expanded(
// //                           child: OutlinedButton(
// //                             onPressed: () {},
// //                             style: OutlinedButton.styleFrom(
// //                               padding: const EdgeInsets.symmetric(vertical: 14),
// //                               side: const BorderSide(
// //                                 color: AppColors.primary,
// //                                 width: 2,
// //                               ),
// //                               shape: RoundedRectangleBorder(
// //                                 borderRadius: BorderRadius.circular(25),
// //                               ),
// //                             ),
// //                             child: const Text(
// //                               'Complete Looks',
// //                               style: TextStyle(
// //                                 fontSize: 13,
// //                                 fontWeight: FontWeight.w600,
// //                                 color: AppColors.primary,
// //                               ),
// //                             ),
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildSkinToneOption(Color color, String label) {
// //     return Padding(
// //       padding: const EdgeInsets.only(right: 12),
// //       child: Column(
// //         children: [
// //           Container(
// //             width: 50,
// //             height: 50,
// //             decoration: BoxDecoration(
// //               color: color,
// //               shape: BoxShape.circle,
// //               border: Border.all(
// //                 color: AppColors.primary.withValues(alpha: 0.3),
// //                 width: 2,
// //               ),
// //               boxShadow: [
// //                 BoxShadow(
// //                   color: Colors.black.withValues(alpha: 0.1),
// //                   blurRadius: 5,
// //                   offset: const Offset(0, 2),
// //                 ),
// //               ],
// //             ),
// //           ),
// //           const SizedBox(height: 6),
// //           Text(
// //             label,
// //             style: const TextStyle(
// //               fontSize: 10,
// //               color: AppColors.textSecondary,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // // Screen 4: Compare Looks Screen
// // class CompareLooksScreen extends StatelessWidget {
// //   const CompareLooksScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       body: SafeArea(
// //         child: Column(
// //           children: [
// //             // Header
// //             Container(
// //               width: double.infinity,
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   colors: [AppColors.primary, AppColors.primaryDeep],
// //                   begin: Alignment.topLeft,
// //                   end: Alignment.bottomRight,
// //                 ),
// //               ),
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// //               child: Row(
// //                 children: [
// //                   IconButton(
// //                     icon: const Icon(Icons.arrow_back, color: Colors.white),
// //                     onPressed: () => Navigator.pop(context),
// //                   ),
// //                   const Expanded(
// //                     child: Text(
// //                       'Visual Design',
// //                       style: TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 18,
// //                         fontWeight: FontWeight.w500,
// //                       ),
// //                       textAlign: TextAlign.center,
// //                     ),
// //                   ),
// //                   IconButton(
// //                     icon: const Icon(Icons.info_outline, color: Colors.white),
// //                     onPressed: () {},
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             // Content
// //             Expanded(
// //               child: SingleChildScrollView(
// //                 child: Padding(
// //                   padding: const EdgeInsets.all(16),
// //                   child: Column(
// //                     children: [
// //                       const SizedBox(height: 10),
// //                       // Grid of comparison images
// //                       GridView.builder(
// //                         shrinkWrap: true,
// //                         physics: const NeverScrollableScrollPhysics(),
// //                         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
// //                           crossAxisCount: 2,
// //                           crossAxisSpacing: 12,
// //                           mainAxisSpacing: 12,
// //                           childAspectRatio: 0.75,
// //                         ),
// //                         itemCount: 6,
// //                         itemBuilder: (context, index) {
// //                           return _buildComparisonCard();
// //                         },
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _buildComparisonCard() {
// //     return Container(
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(15),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.black.withValues(alpha: 0.08),
// //             blurRadius: 8,
// //             offset: const Offset(0, 4),
// //           ),
// //         ],
// //       ),
// //       child: ClipRRect(
// //         borderRadius: BorderRadius.circular(15),
// //         child: Image.network(
// //           'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=400',
// //           fit: BoxFit.cover,
// //         ),
// //       ),
// //     );
// //   }
// // }
// //
// //
// //
//
//
// Common Gradient Background Widget
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: child,
    );
  }
}

// Screen 1: Makeup Try-On Screen
class MakeupTryOnScreen123 extends StatefulWidget {
  const MakeupTryOnScreen123({Key? key}) : super(key: key);

  @override
  State<MakeupTryOnScreen123> createState() => _MakeupTryOnScreen123State();
}

class _MakeupTryOnScreen123State extends State<MakeupTryOnScreen123> {
  final ImagePicker _picker = ImagePicker();

  /// True while the picker is open, so a double-tap can't push two routes.
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? file = await _picker.pickImage(source: source);
      if (file == null || !mounted) return;
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: VisualDesignScreen(userImage: File(file.path)),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } catch (e) {
      debugPrint('Image pick error: $e');
      if (!mounted) return;
      AppSnackbar.error(
        context,
        source == ImageSource.camera
            ? "We couldn't open the camera. Please check permissions."
            : "We couldn't open your gallery. Please check permissions.",
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  // 📸 Open Camera
  Future<void> _pickFromCamera() => _pick(ImageSource.camera);

  // 🖼️ Open Gallery
  Future<void> _pickFromGallery() => _pick(ImageSource.gallery);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const _StudioAppBar(title: 'Visual Design'),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  child: Column(
                    children: [
                      // Preview
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: ClipRRect(
                          borderRadius: AppRadii.rXl,
                          child: AspectRatio(
                            aspectRatio: 0.92,
                            child: Image.asset(
                              'assets/rect.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.pinkSurface,
                                    child: const Center(
                                      child: Icon(
                                        Icons.face_retouching_natural_rounded,
                                        size: 64,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxl,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Virtual Try-On',
                              textAlign: TextAlign.center,
                              style: AppText.display.copyWith(fontSize: 24),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Instantly try on makeup looks virtually '
                              'before you order',
                              textAlign: TextAlign.center,
                              style: AppText.bodySm,
                            ),
                            const SizedBox(height: AppSpacing.xxl),

                            PremiumButton(
                              label: 'SELFIE MODE',
                              icon: Icons.photo_camera_rounded,
                              isLoading: _picking,
                              onPressed: _pickFromCamera,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PremiumButton.outlined(
                              label: 'UPLOAD PHOTO',
                              icon: Icons.photo_library_outlined,
                              enabled: !_picking,
                              onPressed: _pickFromGallery,
                            ),
                          ],
                        ),
                      ),
                    ],
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


// class ShadesScreen extends StatefulWidget {
//   final int selectedCategory; // 0..n
//   final void Function(int) onCategorySelected;
//   final void Function(int) onBrandSelected;
//   final void Function(int) onShadeSelected;
//   final int? selectedBrandIndex;
//   final int? selectedShadeIndex;
//
//   const ShadesScreen({
//     Key? key,
//     required this.selectedCategory,
//     required this.onCategorySelected,
//     required this.onBrandSelected,
//     required this.onShadeSelected,
//     this.selectedBrandIndex,
//     this.selectedShadeIndex,
//   }) : super(key: key);
//
//   @override
//   State<ShadesScreen> createState() => _ShadesScreenState();
// }
//
// class _ShadesScreenState extends State<ShadesScreen> {
//   BarStage _stage = BarStage.categories;
//   int _categoryIndex = 0;
//   int _brandIndex = 0;
//   int _shadeIndex = 0;
//
//   final List<String> categories = ['Foundation', 'Lipstick', 'Blush', 'Eyeshadow'];
//
//   // Mock brands and shades per category:
//   late final List<List<Brand>> brandsByCategory;
//
//   @override
//   void initState() {
//     super.initState();
//     _categoryIndex = widget.selectedCategory;
//
//     brandsByCategory = [
//       // Foundation
//       [
//         Brand(name: "L'Oreal Paris", shades: [Color(0xFFDDB79B), Color(0xFFC89C74)]),
//         Brand(name: "Maybelline Fit Me", shades: [Color(0xFFD7A883), Color(0xFFC4906A)]),
//         Brand(name: "NARS Natural", shades: [Color(0xFFE0BFA0), Color(0xFFD1A383)]),
//       ],
//       // Lipstick
//       [
//         Brand(name: "MAC Retro", shades: [Color(0xFFD32F2F), Color(0xFFB71C1C)]),
//         Brand(name: "Maybelline SuperStay", shades: [Color(0xFFD05B77), Color(0xFFC13F5A)]),
//       ],
//       // Blush
//       [
//         Brand(name: "NARS Orgasm", shades: [Color(0xFFF8BBD0), Color(0xFFF06292)]),
//       ],
//       // Eyeshadow
//       [
//         Brand(name: "Urban Decay", shades: [Color(0xFF8D6E63), Color(0xFF5D4037)]),
//       ],
//     ];
//
//     _brandIndex = widget.selectedBrandIndex ?? 0;
//     _shadeIndex = widget.selectedShadeIndex ?? 0;
//     _stage = BarStage.categories;
//   }
//
//   void _goToBrands(int categoryIdx) {
//     setState(() {
//       _categoryIndex = categoryIdx;
//       _stage = BarStage.brands;
//       _brandIndex = 0;
//       _shadeIndex = 0;
//       widget.onCategorySelected(categoryIdx);
//     });
//   }
//
//   void _goToShades(int brandIdx) {
//     setState(() {
//       _brandIndex = brandIdx;
//       _stage = BarStage.shades;
//       _shadeIndex = 0;
//       widget.onBrandSelected(brandIdx);
//     });
//   }
//
//   void _selectShade(int shadeIdx) {
//     setState(() {
//       _shadeIndex = shadeIdx;
//       widget.onShadeSelected(shadeIdx);
//     });
//   }
//
//   Widget _buildCategoriesBar() {
//     return SizedBox(
//       height: 100,
//       child: ListView.separated(
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         scrollDirection: Axis.horizontal,
//         itemBuilder: (context, i) {
//           final selected = i == _categoryIndex && _stage == BarStage.categories;
//           return GestureDetector(
//             onTap: () => _goToBrands(i),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 250),
//               width: 130,
//               margin: const EdgeInsets.symmetric(vertical: 10),
//               decoration: BoxDecoration(
//                 color: selected ? const Color(0xFFFDE8EF) : Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: selected ? Colors.pink : Colors.transparent, width: 2),
//                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(i == 0 ? Icons.blur_on : i == 1 ? Icons.brightness_4 : i == 2 ? Icons.circle : Icons.remove_red_eye,
//                       size: 36, color: selected ? Colors.pink : Colors.grey[700]),
//                   const SizedBox(height: 6),
//                   Text(categories[i], style: TextStyle(color: selected ? Colors.pink : Colors.black87)),
//                 ],
//               ),
//             ),
//           );
//         },
//         separatorBuilder: (_, __) => const SizedBox(width: 12),
//         itemCount: categories.length,
//       ),
//     );
//   }
//
//   Widget _buildBrandsBar() {
//     final brands = brandsByCategory[_categoryIndex];
//     return SizedBox(
//       height: 100,
//       child: Row(
//         children: [
//           IconButton(
//               icon: const Icon(Icons.chevron_left),
//               onPressed: () {
//                 setState(() => _stage = BarStage.categories);
//               }),
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.symmetric(horizontal: 6),
//               scrollDirection: Axis.horizontal,
//               itemBuilder: (context, i) {
//                 final isSel = i == _brandIndex && _stage == BarStage.brands;
//                 return GestureDetector(
//                   onTap: () => _goToShades(i),
//                   child: AnimatedContainer(
//                     duration: const Duration(milliseconds: 250),
//                     width: 160,
//                     margin: const EdgeInsets.symmetric(vertical: 10),
//                     decoration: BoxDecoration(
//                       color: isSel ? const Color(0xFFFFF1F6) : Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: isSel ? Colors.pink : Colors.transparent, width: 2),
//                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
//                     ),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 8),
//                         Container(
//                           width: 58,
//                           height: 58,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Icon(Icons.image, color: Colors.grey),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(brands[i].name, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.normal)),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//               separatorBuilder: (_, __) => const SizedBox(width: 12),
//               itemCount: brands.length,
//             ),
//           ),
//           IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildShadesBar() {
//     final brands = brandsByCategory[_categoryIndex];
//     final selectedBrand = brands[_brandIndex];
//     return SizedBox(
//       height: 120,
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.chevron_left),
//             onPressed: () {
//               setState(() => _stage = BarStage.brands);
//             },
//           ),
//           Expanded(
//             child: ListView.separated(
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               scrollDirection: Axis.horizontal,
//               itemCount: selectedBrand.shades.length,
//               separatorBuilder: (_, __) => const SizedBox(width: 18),
//               itemBuilder: (context, i) {
//                 final isSel = i == _shadeIndex && _stage == BarStage.shades;
//                 return GestureDetector(
//                   onTap: () => _selectShade(i),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       AnimatedContainer(
//                         duration: const Duration(milliseconds: 200),
//                         width: isSel ? 72 : 56,
//                         height: isSel ? 72 : 56,
//                         decoration: BoxDecoration(
//                           color: selectedBrand.shades[i],
//                           shape: BoxShape.circle,
//                           border: Border.all(color: isSel ? Colors.pink : Colors.white, width: isSel ? 4 : 2),
//                           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6)],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       if (isSel)
//                         Container(
//                           width: 44,
//                           height: 6,
//                           decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(3)),
//                         ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//           IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     Widget child;
//     switch (_stage) {
//       case BarStage.categories:
//         child = _buildCategoriesBar();
//         break;
//       case BarStage.brands:
//         child = _buildBrandsBar();
//         break;
//       case BarStage.shades:
//       default:
//         child = _buildShadesBar();
//         break;
//     }
//
//     return SingleChildScrollView(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Stage header with back control when needed
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: Row(
//               children: [
//                 if (_stage != BarStage.categories)
//                   GestureDetector(
//                     onTap: () {
//                       setState(() {
//                         if (_stage == BarStage.shades) _stage = BarStage.brands;
//                         else _stage = BarStage.categories;
//                       });
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
//                       padding: const EdgeInsets.all(8),
//                       child: const Icon(Icons.arrow_back, color: Colors.pink),
//                     ),
//                   ),
//                 const SizedBox(width: 12),
//                 Text(
//                   _stage == BarStage.categories
//                       ? 'Products'
//                       : _stage == BarStage.brands
//                       ? 'Brands'
//                       : 'Shades',
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
//
//           // AnimatedSwitcher keeps everything on same row and transitions smoothly
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             transitionBuilder: (child, anim) {
//               final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim);
//               return SlideTransition(position: offsetAnim, child: FadeTransition(opacity: anim, child: child));
//             },
//             child: SizedBox(key: ValueKey(_stage), child: child),
//           ),
//         ],
//       ),
//     );
//   }
// }
//


// class CompareScreen extends StatefulWidget {
//   final ImageProvider image; // just the user photo
//   const CompareScreen({Key? key, required this.image}) : super(key: key);
//
//   @override
//   State<CompareScreen> createState() => _CompareScreenState();
// }
//
// class _CompareScreenState extends State<CompareScreen> {
//   double _dividerPosition = 0.5; // slider position
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 700, // same as Shades photo height
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       child: GestureDetector(
//         onHorizontalDragUpdate: (details) {
//           final box = context.findRenderObject() as RenderBox;
//           final local = box.globalToLocal(details.globalPosition);
//           setState(() {
//             _dividerPosition = (local.dx / box.size.width).clamp(0.0, 1.0);
//           });
//         },
//         child: LayoutBuilder(builder: (context, constraints) {
//           final w = constraints.maxWidth;
//           final h = constraints.maxHeight;
//           final clipWidth = w * _dividerPosition;
//
//           return Stack(
//             children: [
//               // Full user photo
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(16),
//                 child: Image(image: widget.image, width: w, height: h, fit: BoxFit.cover),
//               ),
//
//               // Left part clipped by slider (transparent, same photo)
//               Positioned(
//                 left: 0,
//                 top: 0,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(16),
//                   child: Container(
//                     width: clipWidth,
//                     height: h,
//                     child: Image(image: widget.image, fit: BoxFit.cover),
//                   ),
//                 ),
//               ),
//
//               // Slider divider line
//               Positioned(
//                 left: clipWidth - 1,
//                 top: 0,
//                 bottom: 0,
//                 child: Container(
//                   width: 2,
//                   color: Colors.white,
//                 ),
//               ),
//
//               // Round draggable handle
//               Positioned(
//                 left: clipWidth - 18,
//                 top: (h / 2) - 18,
//                 child: Container(
//                   width: 36,
//                   height: 36,
//                   decoration: BoxDecoration(
//                     color: Colors.white.withValues(alpha: 0.8),
//                     shape: BoxShape.circle,
//                     boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
//                   ),
//                   child: const Icon(Icons.drag_handle, color: Colors.black, size: 20),
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }



// class CompleteLooksScreen extends StatelessWidget {
//   final ImageProvider userImageProvider;
//   final Map<int, Map<String, int>> selections;
//   const CompleteLooksScreen({Key? key, required this.userImageProvider, required this.selections}) : super(key: key);
//
//   // Mock readable names for categories & brands (should mirror ShadesScreen's mock)
//   static const List<String> categories = ['Foundation', 'Lipstick', 'Blush', 'Eyeshadow'];
//   static const List<List<String>> brands = [
//     ["L'Oreal Paris", "Maybelline Fit Me", "NARS Natural"],
//     ["MAC Retro", "Maybelline SuperStay"],
//     ["NARS Orgasm"],
//     ["Urban Decay"],
//   ];
//
//   // Mock shade colors (should match ShadesScreen's list) - keep it simple for display
//   static final List<List<List<Color>>> shades = [
//     [
//       [Color(0xFFDDB79B), Color(0xFFC89C74)],
//       [Color(0xFFD7A883), Color(0xFFC4906A)],
//       [Color(0xFFE0BFA0), Color(0xFFD1A383)],
//     ],
//     [
//       [Color(0xFFD32F2F), Color(0xFFB71C1C)],
//       [Color(0xFFD05B77), Color(0xFFC13F5A)],
//     ],
//     [
//       [Color(0xFFF8BBD0), Color(0xFFF06292)],
//     ],
//     [
//       [Color(0xFF8D6E63), Color(0xFF5D4037)],
//     ],
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     final selectedEntries = selections.entries.toList();
//
//     return Container(
//       padding: const EdgeInsets.all(12),
//       child: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Final output image
//             Container(
//               height: 525,
//               decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
//               child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image(image: userImageProvider, fit: BoxFit.cover)),
//             ),
//             const SizedBox(height: 12),
//             // Selected product list
//             SizedBox(
//               height: 120,
//               child: selectedEntries.isEmpty
//                   ? const Center(child: Text('No products selected yet'))
//                   : ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: selectedEntries.length,
//                 separatorBuilder: (_, __) => const SizedBox(width: 12),
//                 itemBuilder: (context, i) {
//                   final catIndex = selectedEntries[i].key;
//                   final map = selectedEntries[i].value;
//                   final brandIndex = map['brand'] ?? 0;
//                   final shadeIndex = map['shade'] ?? 0;
//                   final brandName = brands[catIndex][brandIndex];
//                   final shadeColor = shades[catIndex][brandIndex][shadeIndex];
//
//                   return Container(
//                     width: 220,
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
//                     child: Row(
//                       children: [
//                         Container(width: 64, height: 64, decoration: BoxDecoration(color: shadeColor, borderRadius: BorderRadius.circular(8))),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(categories[catIndex], style: const TextStyle(fontWeight: FontWeight.w700)),
//                               const SizedBox(height: 6),
//                               Text(brandName, style: const TextStyle(fontSize: 12)),
//                               const SizedBox(height: 6),
//                               Row(children: [
//                                 Container(width: 18, height: 18, decoration: BoxDecoration(color: shadeColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1))),
//                                 const SizedBox(width: 6),
//                                 Text('Shade ${shadeIndex + 1}', style: const TextStyle(fontSize: 12))
//                               ])
//                             ],
//                           ),
//                         )
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }




// // Custom painter for corner brackets
// // class FrameBracketsPainter extends CustomPainter {
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final paint = Paint()
// //       ..color = Colors.white
// //       ..strokeWidth = 3
// //       ..style = PaintingStyle.stroke;
// //
// //     const double bracketLength = 60;
// //     const double margin = 80;
// //
// //     // Top-left corner
// //     canvas.drawLine(
// //       Offset(margin, margin),
// //       Offset(margin + bracketLength, margin),
// //       paint,
// //     );
// //     canvas.drawLine(
// //       Offset(margin, margin),
// //       Offset(margin, margin + bracketLength),
// //       paint,
// //     );
// //
// //     // Top-right corner
// //     canvas.drawLine(
// //       Offset(size.width - margin, margin),
// //       Offset(size.width - margin - bracketLength, margin),
// //       paint,
// //     );
// //     canvas.drawLine(
// //       Offset(size.width - margin, margin),
// //       Offset(size.width - margin, margin + bracketLength),
// //       paint,
// //     );
// //
// //     // Bottom-left corner
// //     canvas.drawLine(
// //       Offset(margin, size.height - margin - 150),
// //       Offset(margin + bracketLength, size.height - margin - 150),
// //       paint,
// //     );
// //     canvas.drawLine(
// //       Offset(margin, size.height - margin - 150),
// //       Offset(margin, size.height - margin - bracketLength - 150),
// //       paint,
// //     );
// //
// //     // Bottom-right corner
// //     canvas.drawLine(
// //       Offset(size.width - margin, size.height - margin - 150),
// //       Offset(size.width - margin - bracketLength, size.height - margin - 150),
// //       paint,
// //     );
// //     canvas.drawLine(
// //       Offset(size.width - margin, size.height - margin - 150),
// //       Offset(size.width - margin, size.height - margin - bracketLength - 150),
// //       paint,
// //     );
// //   }
// //
// //   @override
// //   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// // }
// // class VirtualTryOnScreennn extends StatelessWidget {
// //   const VirtualTryOnScreennn({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         backgroundColor: Colors.pink,
// //
// //       ),
// //       body: Stack(
// //         children: [
// //           // 🌸 Background Image
// //           Positioned.fill(
// //             child: Image.asset(
// //               'assets/1g.png', // Ensure this is in your assets folder and added in pubspec.yaml
// //               fit: BoxFit.cover,
// //             ),
// //           ),
// //
// //           // 🌸 Dark Overlay
// //           Positioned.fill(
// //             child: Container(
// //               decoration: BoxDecoration(
// //                 gradient: LinearGradient(
// //                   begin: Alignment.topCenter,
// //                   end: Alignment.bottomCenter,
// //                   colors: [
// //                     Colors.black.withValues(alpha: 0.3),
// //                     Colors.black.withValues(alpha: 0.6),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           ),
// //
// //           // 🌸 Main Content
// //           SafeArea(
// //             child: Column(
// //               children: [
// //                 // 🔹 Top Bar
// //                 // Padding(
// //                 //   padding:
// //                 //   const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //                 //   child: Row(
// //                 //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 //     children: [
// //                 //       Row(
// //                 //         children: const [
// //                 //           Icon(Icons.arrow_back_ios,
// //                 //               color: Colors.white, size: 20),
// //                 //           SizedBox(width: 4),
// //                 //           Text(
// //                 //             'Nashik',
// //                 //             style: TextStyle(
// //                 //               color: Colors.white,
// //                 //               fontSize: 17,
// //                 //               fontWeight: FontWeight.w400,
// //                 //             ),
// //                 //           ),
// //                 //         ],
// //                 //       ),
// //                 //       const Text(
// //                 //         'Visual Design',
// //                 //         style: TextStyle(
// //                 //           color: Colors.white,
// //                 //           fontSize: 17,
// //                 //           fontWeight: FontWeight.w600,
// //                 //         ),
// //                 //       ),
// //                 //       const SizedBox(width: 40),
// //                 //     ],
// //                 //   ),
// //                 // ),
// //
// //                 // 🌸 Center Card Section
// //                 Expanded(
// //                   child: Center(
// //                     child: Padding(
// //                       padding: const EdgeInsets.symmetric(horizontal: 40),
// //                       child: Stack(
// //                         children: [
// //                           Positioned.fill(
// //                             child: _buildCornerDecorations(),
// //                           ),
// //                           Container(
// //                             width: double.infinity,
// //                             padding: const EdgeInsets.symmetric(
// //                                 vertical: 60, horizontal: 20),
// //                             decoration: BoxDecoration(
// //                               borderRadius: BorderRadius.circular(20),
// //                               color: Colors.white.withValues(alpha: 0.1),
// //                             ),
// //                             child: Column(
// //                               mainAxisSize: MainAxisSize.min,
// //                               children: [
// //                                 const Text(
// //                                   'VIRTUAL TRY - ON',
// //                                   style: TextStyle(
// //                                     color: Colors.white,
// //                                     fontSize: 28,
// //                                     fontWeight: FontWeight.w700,
// //                                     letterSpacing: 1.5,
// //                                   ),
// //                                   textAlign: TextAlign.center,
// //                                 ),
// //                                 const SizedBox(height: 16),
// //                                 Text(
// //                                   'Instantly try on makeup looks and find your perfect shades.',
// //                                   style: TextStyle(
// //                                     color: Colors.white.withValues(alpha: 0.9),
// //                                     fontSize: 14,
// //                                     fontWeight: FontWeight.w400,
// //                                     height: 1.4,
// //                                   ),
// //                                   textAlign: TextAlign.center,
// //                                 ),
// //                                 const SizedBox(height: 30),
// //                                 SizedBox(
// //                                   width: double.infinity,
// //                                   height: 50,
// //                                   child: ElevatedButton(
// //                                     onPressed: () {
// //
// //                                       Navigator.push(
// //                                         context,
// //                                         MaterialPageRoute(builder: (context) => const ChooseOneScreen()),
// //                                       );
// //                                     },
// //                                     style: ElevatedButton.styleFrom(
// //                                       backgroundColor: const Color(0xFFE91E63),
// //                                       shape: RoundedRectangleBorder(
// //                                         borderRadius: BorderRadius.circular(25),
// //                                       ),
// //                                       elevation: 0,
// //                                     ),
// //                                     child: const Text(
// //                                       'Get Started',
// //                                       style: TextStyle(
// //                                         color: Colors.white,
// //                                         fontSize: 16,
// //                                         fontWeight: FontWeight.w600,
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   // 🌸 Decorative Corner Brackets
// //   Widget _buildCornerDecorations() {
// //     return Stack(
// //       children: const [
// //         Positioned(
// //           top: 0,
// //           left: 0,
// //           child: CustomPaint(
// //             size: Size(40, 40),
// //             painter: CornerBracketPainter(isTopLeft: true),
// //           ),
// //         ),
// //         Positioned(
// //           top: 0,
// //           right: 0,
// //           child: CustomPaint(
// //             size: Size(40, 40),
// //             painter: CornerBracketPainter(isTopRight: true),
// //           ),
// //         ),
// //         Positioned(
// //           bottom: 0,
// //           left: 0,
// //           child: CustomPaint(
// //             size: Size(40, 40),
// //             painter: CornerBracketPainter(isBottomLeft: true),
// //           ),
// //         ),
// //         Positioned(
// //           bottom: 0,
// //           right: 0,
// //           child: CustomPaint(
// //             size: Size(40, 40),
// //             painter: CornerBracketPainter(isBottomRight: true),
// //           ),
// //         ),
// //       ],
// //     );
// //   }
// // }
// //
// // // 🌸 Painter for decorative brackets
// // class CornerBracketPainter extends CustomPainter {
// //   final bool isTopLeft;
// //   final bool isTopRight;
// //   final bool isBottomLeft;
// //   final bool isBottomRight;
// //
// //   const CornerBracketPainter({
// //     this.isTopLeft = false,
// //     this.isTopRight = false,
// //     this.isBottomLeft = false,
// //     this.isBottomRight = false,
// //   });
// //
// //   @override
// //   void paint(Canvas canvas, Size size) {
// //     final paint = Paint()
// //       ..color = Colors.white
// //       ..strokeWidth = 3
// //       ..style = PaintingStyle.stroke;
// //
// //     final path = Path();
// //
// //     if (isTopLeft) {
// //       path.moveTo(0, size.height * 0.4);
// //       path.lineTo(0, 0);
// //       path.lineTo(size.width * 0.4, 0);
// //     } else if (isTopRight) {
// //       path.moveTo(size.width * 0.6, 0);
// //       path.lineTo(size.width, 0);
// //       path.lineTo(size.width, size.height * 0.4);
// //     } else if (isBottomLeft) {
// //       path.moveTo(0, size.height * 0.6);
// //       path.lineTo(0, size.height);
// //       path.lineTo(size.width * 0.4, size.height);
// //     } else if (isBottomRight) {
// //       path.moveTo(size.width * 0.6, size.height);
// //       path.lineTo(size.width, size.height);
// //       path.lineTo(size.width, size.height * 0.6);
// //     }
// //
// //     canvas.drawPath(path, paint);
// //   }
// //
// //   @override
// //   bool shouldRepaint(CornerBracketPainter oldDelegate) => false;
// // }
//
//
// // Screen 2: Login Screen
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   bool _rememberMe = false;
//   bool _obscurePassword = true;
//   final _emailController = TextEditingController(text: 'Loisbecket@gmail.com');
//   final _passwordController = TextEditingController(text: '••••••••');
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF8B1E5F),
//       body: Stack(
//         children: [
//           // Background Image
//           Positioned.fill(
//             child: Opacity(
//               opacity: 0.3,
//               child: Image.network(
//                 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800',
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(color: const Color(0xFF8B1E5F));
//                 },
//               ),
//             ),
//           ),
//
//           Column(
//             children: [
//               // Top Bar
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Naashik',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 17,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Text(
//                         'Visual Design',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 17,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(width: 40),
//                     ],
//                   ),
//                 ),
//               ),
//
//               const Spacer(),
//
//               // Login Card
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 24),
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Close Button
//                     Align(
//                       alignment: Alignment.topRight,
//                       child: GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: const BoxDecoration(
//                             color: Color(0xFFE91E63),
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.close,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Login Title
//                     const Center(
//                       child: Text(
//                         'Login',
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     // Signup Link
//                     Center(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Don\'t have an account? ',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () {},
//                             child: const Text(
//                               'Sign Up',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Color(0xFF2196F3),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // Email Field
//                     Text(
//                       'Email or Mobile',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[700],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         hintText: 'Enter email or mobile',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Color(0xFFE91E63)),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Password Field
//                     Text(
//                       'Password',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[700],
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: _passwordController,
//                       obscureText: _obscurePassword,
//                       decoration: InputDecoration(
//                         hintText: 'Enter password',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(color: Color(0xFFE91E63)),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword ? Icons.visibility_off : Icons.visibility,
//                             color: Colors.grey,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Remember Me & Forgot Password
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: Checkbox(
//                                 value: _rememberMe,
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _rememberMe = value ?? false;
//                                   });
//                                 },
//                                 activeColor: const Color(0xFFE91E63),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               'Remember me',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[700],
//                               ),
//                             ),
//                           ],
//                         ),
//                         GestureDetector(
//                           onTap: () {},
//                           child: const Text(
//                             'Forgot Password ?',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Color(0xFF2196F3),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 24),
//
//                     // Login Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (context) => const ChooseOneScreen()),
//                           );
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFFE91E63),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(25),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: const Text(
//                           'Log In',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Or Divider
//                     Row(
//                       children: [
//                         Expanded(child: Divider(color: Colors.grey[300])),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           child: Text(
//                             'Or',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                         ),
//                         Expanded(child: Divider(color: Colors.grey[300])),
//                       ],
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     // Google Sign In
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: OutlinedButton.icon(
//                         onPressed: () {},
//                         icon: Image.network(
//                           'https://www.google.com/favicon.ico',
//                           width: 20,
//                           height: 20,
//                         ),
//                         label: const Text(
//                           'Continue with Google',
//                           style: TextStyle(
//                             color: Colors.black87,
//                             fontSize: 15,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(color: Colors.grey[300]!),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               const Spacer(),
//               //
//               // // Bottom Navigation (same as before)
//               // Container(
//               //   height: 65,
//               //   decoration: BoxDecoration(
//               //     color: const Color(0xFFE91E63),
//               //     borderRadius: const BorderRadius.only(
//               //       topLeft: Radius.circular(20),
//               //       topRight: Radius.circular(20),
//               //     ),
//               //   ),
//               //   child: Row(
//               //     mainAxisAlignment: MainAxisAlignment.spaceAround,
//               //     children: [
//               //       _buildNavItem(Icons.home, 'Home', false),
//               //       _buildNavItem(Icons.store, 'Vendors', false),
//               //       _buildNavItem(Icons.photo_camera, 'VirtualStudio', true),
//               //       _buildNavItem(Icons.group, 'Vendors', false),
//               //       _buildNavItem(Icons.menu, 'More', false),
//               //     ],
//               //   ),
//               // ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem(IconData icon, String label, bool isActive) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           decoration: BoxDecoration(
//             color: isActive ? const Color(0xFF64B5F6) : Colors.transparent,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 icon,
//                 color: Colors.white,
//                 size: 24,
//               ),
//               if (isActive)
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // Screen 3: Choose One Screen
// class ChooseOneScreen extends StatelessWidget {
//   const ChooseOneScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Top Bar
//           Container(
//             color: const Color(0xFFE91E63),
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
//                         const SizedBox(width: 4),
//                         Text(
//                           'Nashik',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 17,
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                       ],
//                     ),
//                     Text(
//                       'Visual Design',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 17,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     const SizedBox(width: 40),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//
//           // Content
//           Expanded(
//             child: Container(
//               color: Colors.white,
//               child: Column(
//                 children: [
//                   const SizedBox(height: 32),
//
//                   // Title
//                   const Text(
//                     'Choose one',
//                     style: TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.w700,
//                       color: Color(0xFFE91E63),
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   // Subtitle
//                   Text(
//                     'Instantly try on makeup looks and find your perfect shades.',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                       fontWeight: FontWeight.w400,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//
//                   const SizedBox(height: 32),
//
//                   // Bride and Groom Cards
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 24),
//                       child: Column(
//                         children: [
//                           // Bride Card
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () {
//                                 // Navigate to Bride section
//                               },
//                               child: Container(
//
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(16),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withValues(alpha: 0.1),
//                                       blurRadius: 10,
//                                       offset: const Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(16),
//                                   child: Stack(
//                                     fit: StackFit.expand,
//                                     children: [
//                                       Transform.scale(
//                                         scale: 1.2,
//                                         child: Image.asset(
//                                           'assets/bride.png',
//                                            fit: BoxFit.cover,
//
//                                           errorBuilder: (context, error, stackTrace) {
//                                             return Container(
//                                               color: Colors.pink[50],
//                                               child: const Center(
//                                                 child: Icon(Icons.image, size: 150, color: Colors.grey),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ),
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           gradient: LinearGradient(
//                                             begin: Alignment.topCenter,
//                                             end: Alignment.bottomCenter,
//                                             colors: [
//                                               Colors.transparent,
//                                               Colors.black.withValues(alpha: 0.5),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         bottom: 20,
//                                         left: 0,
//                                         right: 0,
//                                         child: const Text(
//                                           'Bride',
//                                           style: TextStyle(
//                                             fontSize: 36,
//                                             fontWeight: FontWeight.w700,
//                                             color: Colors.white,
//                                             letterSpacing: 1.2,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(height: 24),
//
//                           // Groom Card
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () {
//                                 // Navigate to Groom section
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(16),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withValues(alpha: 0.1),
//                                       blurRadius: 10,
//                                       offset: const Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(16),
//                                   child: Stack(
//                                     fit: StackFit.expand,
//                                     children: [
//                                       Image.asset(
//                                         'assets/groom.png',
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (context, error, stackTrace) {
//                                           return Container(
//                                             color: Colors.brown[50],
//                                             child: const Center(
//                                               child: Icon(Icons.image, size: 60, color: Colors.grey),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           gradient: LinearGradient(
//                                             begin: Alignment.topCenter,
//                                             end: Alignment.bottomCenter,
//                                             colors: [
//                                               Colors.transparent,
//                                               Colors.black.withValues(alpha: 0.5),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         bottom: 20,
//                                         left: 0,
//                                         right: 0,
//                                         child: const Text(
//                                           'Groom',
//                                           style: TextStyle(
//                                             fontSize: 36,
//                                             fontWeight: FontWeight.w700,
//                                             color: Colors.white,
//                                             letterSpacing: 1.2,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//
//                           const SizedBox(height: 24),
//
//
//                           // other Card
//                           Expanded(
//                             child: GestureDetector(
//                               onTap: () {
//                                 // Navigate to Groom section
//                               },
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(16),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.black.withValues(alpha: 0.1),
//                                       blurRadius: 10,
//                                       offset: const Offset(0, 4),
//                                     ),
//                                   ],
//                                 ),
//                                 child: ClipRRect(
//                                   borderRadius: BorderRadius.circular(16),
//                                   child: Stack(
//                                     fit: StackFit.expand,
//                                     children: [
//                                       Image.asset(
//                                         'assets/other.png',
//                                         fit: BoxFit.cover,
//                                         errorBuilder: (context, error, stackTrace) {
//                                           return Container(
//                                             color: Colors.brown[50],
//                                             child: const Center(
//                                               child: Icon(Icons.image, size: 60, color: Colors.grey),
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           gradient: LinearGradient(
//                                             begin: Alignment.topCenter,
//                                             end: Alignment.bottomCenter,
//                                             colors: [
//                                               Colors.transparent,
//                                               Colors.black.withValues(alpha: 0.5),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         bottom: 20,
//                                         left: 0,
//                                         right: 0,
//                                         child: const Text(
//                                           'Other',
//                                           style: TextStyle(
//                                             fontSize: 36,
//                                             fontWeight: FontWeight.w700,
//                                             color: Colors.white,
//                                             letterSpacing: 1.2,
//                                           ),
//                                           textAlign: TextAlign.center,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 24),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Bottom Navigation
//           // Container(
//           //   height: 65,
//           //   decoration: BoxDecoration(
//           //     color: const Color(0xFFE91E63),
//           //     borderRadius: const BorderRadius.only(
//           //       topLeft: Radius.circular(20),
//           //       topRight: Radius.circular(20),
//           //     ),
//           //   ),
//           //   child: Row(
//           //     mainAxisAlignment: MainAxisAlignment.spaceAround,
//           //     children: [
//           //       _buildNavItem(Icons.home, 'Home', false),
//           //       _buildNavItem(Icons.store, 'Vendors', false),
//           //       _buildNavItem(Icons.photo_camera, 'VirtualStudio', true),
//           //       _buildNavItem(Icons.group, 'Vendors', false),
//           //       _buildNavItem(Icons.menu, 'More', false),
//           //     ],
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildNavItem(IconData icon, String label, bool isActive) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//           decoration: BoxDecoration(
//             color: isActive ? const Color(0xFF64B5F6) : Colors.transparent,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Column(
//             children: [
//               Icon(
//                 icon,
//                 color: Colors.white,
//                 size: 24,
//               ),
//               if (isActive)
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
//
//
// 888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
