import 'dart:io';

import 'package:flutter/material.dart';

import '../core/core.dart';
import 'package:image_picker/image_picker.dart';

import 'custome_theme.dart';
import 'moment_my_photos_screen.dart';
import 'movment_plus_api.dart';

class MomentPrivacyDialog extends StatefulWidget {
  const MomentPrivacyDialog({super.key, required this.token});

  final String token;

  static const Color primary = Color(0xFFC31162);

  @override
  State<MomentPrivacyDialog> createState() => _MomentPrivacyDialogState();
}

class _MomentPrivacyDialogState extends State<MomentPrivacyDialog> {
  static const Color primary = MomentPrivacyDialog.primary;

  bool _consentToProcessing = false;
  bool _confirmsAdult = false;

  bool get _allAgreed => _consentToProcessing && _confirmsAdult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.45),
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
                  color: primary.withValues(alpha: 0.18),
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
                  _consentToProcessing,
                  (v) => setState(() => _consentToProcessing = v ?? false),
                ),

                const SizedBox(height: 12),

                /// ================= CHECKBOX 2 =================
                _checkRow(
                  "I am at least 18 years old and agree to the terms.",
                  _confirmsAdult,
                  (v) => setState(() => _confirmsAdult = v ?? false),
                ),

                const Spacer(),

                /// ================= CONSENT BUTTON =================
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Both disclosures must be agreed to before continuing —
                    // matches the web's `allAgreed` gate on this same dialog.
                    onPressed: _allAgreed
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MomentFindPhotos(token: widget.token),
                              ),
                            );
                          }
                        : null,
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
  Widget _checkRow(String text, bool value, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              checkColor: primary,
              fillColor: WidgetStateProperty.all(Colors.white),
              side: const BorderSide(color: Colors.white),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
      ),
    );
  }
}

/// =======================================================
/// FIND PHOTOS
/// =======================================================
class MomentFindPhotos extends StatelessWidget {
  const MomentFindPhotos({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return _baseScreen(
      context,
      title: "Let Us Find Your Photos",
      icon: Icons.face_retouching_natural,
      buttons: [
        _actionBtn(context, "Selfie Mode",
                () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MomentCaptureSelfie(token: token)))),
        _actionBtn(context, "Upload Photo",
                () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MomentUploadSelfie(token: token)))),
      ],
    );
  }
}

/// =======================================================
/// CAPTURE SELFIE
/// =======================================================
class MomentCaptureSelfie extends StatelessWidget {
  const MomentCaptureSelfie({super.key, required this.token});

  final String token;

  Future<void> _takeSelfie(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );

      if (image == null) return;
      if (!context.mounted) return;

      await _uploadAndFindPhotos(context, File(image.path), token);
    } catch (e) {
      if (context.mounted) AppSnackbar.info(context, "Unable to open camera");
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
  required String token,
}) async {
  try {
    final XFile? image = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
    );

    if (image == null) return;
    if (!context.mounted) return;

    await _uploadAndFindPhotos(context, File(image.path), token);
  } catch (e) {
    if (context.mounted) AppSnackbar.info(context, "Failed to pick image");
  }
}

/// Shared by both capture paths (camera / gallery picker): submits the
/// selfie to the AI service, then hands off to [MomentMyPhotos] to poll for
/// matches — matching itself is a separate, much slower call
/// (`MovmentPlusApi.getMyPhotos`), so this only waits on the upload.
Future<void> _uploadAndFindPhotos(
  BuildContext context,
  File selfieFile,
  String token,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: CircularProgressIndicator(color: MpTheme.primaryColor),
    ),
  );

  try {
    await MovmentPlusApi.uploadSelfie(token: token, file: selfieFile);
    if (!context.mounted) return;
    Navigator.pop(context); // close the loading dialog
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MomentMyPhotos(token: token)),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context); // close the loading dialog
    AppSnackbar.info(context, e.toString());
  }
}

class MomentUploadSelfie extends StatelessWidget {
  const MomentUploadSelfie({super.key, required this.token});

  final String token;

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
              token: token,
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
      const BoxDecoration(gradient: MpTheme.backgroundGradient),
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
                                    color: MpTheme.primaryColor, // #C31162
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

