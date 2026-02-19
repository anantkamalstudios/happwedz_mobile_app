import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'custome_theme.dart';

class MomentPrivacyDialog extends StatelessWidget {
  const MomentPrivacyDialog({super.key});

  static const Color primary = Color(0xFFC31162);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.45),
      body: SafeArea(
        child: Center(
          child: Container(
            width: 310,
            height: 486,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(0),
              border: Border.all(color: primary, width: 1),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// ================= HEADER =================
                Row(
                  children: [
                    const Spacer(),
                    const Text(
                      "Our Privacy",
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close,
                          size: 20, color: Colors.black),
                    )
                  ],
                ),

                Center(
                  child: const Text(
                    "Our Privacy",
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.45,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                /// ================= DESCRIPTION =================
                const Text(
                  "To access this service, you must be at least 18 years old.\n\n"
                      "By continuing, you agree that HappyWedz may temporarily store your "
                      "uploaded images only for the purpose of delivering AI-driven "
                      "photo experiences. Your photos are never shared, sold, or reused. "
                      "Images are securely deleted after processing.",
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Privacy Notice",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  /// 👇 UNDERLINE
                  Container(
                    width: 100,       // underline length
                    height: 1,       // thickness
                    color: Colors.white,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

                /// ================= CHECKBOX 1 =================
                _checkRow(
                  "I consent to the use of my image for AI processing.",
                ),

                const SizedBox(height: 12),

                /// ================= CHECKBOX 2 =================
                _checkRow(
                  "I am at least 18 years old and agree to the terms.",
                ),

                const Spacer(),

                /// ================= CONSENT BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MomentFindPhotos(),
                        ),
                      );
                    },
                    child: const Text(
                      "I Consent",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ================= CHECK ROW =================
  Widget _checkRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_box,
          size: 18,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// =======================================================
/// FIND PHOTOS
/// =======================================================
class MomentFindPhotos extends StatelessWidget {
  const MomentFindPhotos({super.key});

  @override
  Widget build(BuildContext context) {
    return _baseScreen(
      context,
      title: "Let Us Find Your Photos",
      icon: Icons.face_retouching_natural,
      buttons: [
        _actionBtn(context, "Selfie Mode",
                () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MomentCaptureSelfie()))),
        _actionBtn(context, "Upload Photo",
                () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MomentUploadSelfie()))),
      ],
    );
  }
}

/// =======================================================
/// CAPTURE SELFIE
/// =======================================================
class MomentCaptureSelfie extends StatelessWidget {
  const MomentCaptureSelfie({super.key});

  Future<void> _takeSelfie(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (image == null) return;

      final File selfieFile = File(image.path);

      // 🔹 Temporary preview (replace with upload / save logic)
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Selfie Preview"),
          content: Image.file(selfieFile),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open camera")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _baseScreen(
      context,
      title: "Capture Selfie",
      icon: Icons.camera_front,
      buttons: [
        _actionBtn(
          context,
          "Take Selfie",
              () => _takeSelfie(context),
        ),
      ],
    );
  }
}

/// =======================================================
/// UPLOAD SELFIE
/// =======================================================
///
final ImagePicker _picker = ImagePicker();

Future<void> pickSelfie({
  required BuildContext context,
  required ImageSource source,
}) async {
  try {
    final XFile? image = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );

    if (image == null) return;

    File file = File(image.path);

    // 🔹 For now just preview
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Image.file(file),
      ),
    );

    // TODO: upload / save / pass to next screen
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to pick image")),
    );
  }
}
class MomentUploadSelfie extends StatelessWidget {
  const MomentUploadSelfie({super.key});

  @override
  Widget build(BuildContext context) {
    return _baseScreen(
      context,
      title: "Upload Selfie",
      icon: Icons.upload_file,
      buttons: [
        _actionBtn(
          context,
          "Upload Selfie",
              () {
            pickSelfie(
              context: context,
              source: ImageSource.gallery,
            );
          },
        ),
      ],
    );
  }
}


/// =======================================================
/// BASE SCREEN (REUSED)
/// =======================================================
Widget _baseScreen(
    BuildContext context, {
      required String title,
      required IconData icon,
      required List<Widget> buttons,
    }) {
  return Scaffold(
    body: Container(
      decoration:
      const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [

            /// APP BAR (WISHLIST STYLE)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    "Movement Plus",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            /// HEADER CARD
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

            const SizedBox(height: 40),

            Image.asset(
              'assets/images/selfie.png',
              width: 190,
              height: 128,
            ),

            const SizedBox(height: 24),

            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text(
              "Face recognition that finds your photos",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 40),

            ...buttons,
          ],
        ),
      ),
    ),
  );
}

/// BUTTON BUILDER
Widget _actionBtn(
    BuildContext context,
    String text,
    VoidCallback onTap,
    ) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      width: 220,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFE83580),
            Color(0xFF821E48),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0A0D12), // #0A0D120D
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

