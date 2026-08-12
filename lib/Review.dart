import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'core/core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 🌸 COLOR PALETTE
const Color primaryPink = Color(0xFFFF69B4);
const Color softPink = Color(0xFFFFB6C1);
const Color accentBlue = Color(0xFF007BFF);

// 🌟 Custom Page Route Animation
Route _createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final tween =
      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

// 🌸 REVIEW DATA MODEL
class ReviewData {
  String wouldRecommend; // "yes" or "no"
  double ratingQuality;
  double ratingResponsiveness;
  double ratingProfessionalism;
  double ratingValue;
  double ratingFlexibility;
  String title;
  String comment;
  String happywedzHelped; // "yes" or "no"
  String? guestCount;
  String? amountSpent;

  ReviewData({
    required this.wouldRecommend,
    required this.ratingQuality,
    required this.ratingResponsiveness,
    required this.ratingProfessionalism,
    required this.ratingValue,
    required this.ratingFlexibility,
    required this.title,
    required this.comment,
    required this.happywedzHelped,
    this.guestCount,
    this.amountSpent,
  });

  /// ✅ Added simple constructor
  ReviewData.simple({
    required this.wouldRecommend,
    required this.happywedzHelped,
  })  : ratingQuality = 0,
        ratingResponsiveness = 0,
        ratingProfessionalism = 0,
        ratingValue = 0,
        ratingFlexibility = 0,
        title = "",
        comment = "",
        guestCount = null,
        amountSpent = null;

  Map<String, dynamic> toMap() {
    final map = {
      'would_recommend': wouldRecommend,
      'rating_quality': ratingQuality.toInt(),
      'rating_responsiveness': ratingResponsiveness.toInt(),
      'rating_professionalism': ratingProfessionalism.toInt(),
      'rating_value': ratingValue.toInt(),
      'rating_flexibility': ratingFlexibility.toInt(),
      'title': title,
      'comment': comment,
      'happywedz_helped': happywedzHelped,
      'guest_count': guestCount ?? "0",   // default to "0" if null
      'spent': amountSpent ?? "0",       // default to "0" if null
    };
    return map;
  }



}


// 🌸 STEP 1 — RECOMMENDATION


class RecommendVendorScreen extends StatelessWidget {
  final String vendorId; // dynamic vendor ID
  final String vendorName;
  final String? vendorImage;
  final String? currentUserId;


  const RecommendVendorScreen({
    Key? key,
    required this.vendorId,
    required this.vendorName,
    this.vendorImage,
    this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [softPink, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Text(
                "Would you recommend ${vendorName.isNotEmpty ? vendorName : "this vendor"}?",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionButton(
                    context,
                    Icons.thumb_up_alt_outlined,
                    "Yes",
                    "I'd recommend them",
                    true,
                  ),
                  const SizedBox(width: 20),
                  _buildOptionButton(
                    context,
                    Icons.thumb_down_alt_outlined,
                    "No",
                    "Not recommended",
                    false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      bool isRecommended,
      ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final reviewData = ReviewData.simple(
            wouldRecommend: isRecommended ? "yes" : "no",
            happywedzHelped: "yes",
          );

          Navigator.push(
            context,
            _createRoute(
              RateExperienceScreen(
                reviewData: reviewData,
                vendorId: vendorId,
                vendorName: vendorName,
                vendorImage: vendorImage,
                currentUserId: currentUserId,
              ),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          height: 130,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: isRecommended ? primaryPink : Colors.grey.shade600),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}


// 🌸 STEP 2 — RATE EXPERIENCE
class RateExperienceScreen extends StatefulWidget {
  final ReviewData reviewData;
  final String vendorId;

  final String vendorName;
  final String? vendorImage;
  final String? currentUserId;

  const RateExperienceScreen({
    super.key,
    required this.reviewData,
    required this.vendorId,
    required this.vendorName,
    this.vendorImage,
    this.currentUserId,
  });

  @override
  State<RateExperienceScreen> createState() => _RateExperienceScreenState();
}

class _RateExperienceScreenState extends State<RateExperienceScreen> with SingleTickerProviderStateMixin {
  final Map<String, double> ratings = {
    "Quality": 0,
    "Professionalism": 0,
    "Communication": 0,
    "Value for Money": 0,
    "Punctuality": 0,
  };

  late AnimationController _controller;
  bool get allRated => ratings.values.every((v) => v > 0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fadeIn(Widget child, int delay) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Interval(delay * 0.1, 1, curve: Curves.easeOut)),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fadeIn(
                  const Center(
                    child: Text("Write a Review", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  1),
              const SizedBox(height: 30),
              _fadeIn(_buildStepIndicator(1, activeStep: 1), 2),
              const SizedBox(height: 40),
              _fadeIn(const Text("Rate your experience", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), 3),
              const SizedBox(height: 20),
              ...ratings.keys.map((key) => _fadeIn(_buildRatingRow(key), 4)).toList(),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: primaryPink),
                    label: const Text("Back", style: TextStyle(color: primaryPink)),
                  ),
                  ElevatedButton.icon(
                    onPressed: allRated
                        ? () {
                      // Correct mapping to ReviewData
                      widget.reviewData.ratingQuality = ratings["Quality"]!;
                      widget.reviewData.ratingProfessionalism = ratings["Professionalism"]!;
                      widget.reviewData.ratingResponsiveness = ratings["Communication"]!;
                      widget.reviewData.ratingValue = ratings["Value for Money"]!;
                      widget.reviewData.ratingFlexibility = ratings["Punctuality"]!;

                      Navigator.push(
                        context,
                        _createRoute(WriteReviewScreen(reviewData: widget.reviewData, vendorId: widget.vendorId)),
                      );
                    }
                        : null,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text("Next", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allRated ? primaryPink : Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Row(
            children: List.generate(
              5,
                  (index) => IconButton(
                icon: Icon(
                  index < ratings[label]! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    ratings[label] = (index + 1).toDouble();
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, {int activeStep = 1}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepCircle("1", "Rate Experience", isActive: true),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        _buildStepCircle("2", "Write Review"),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        _buildStepCircle("3", "Additional Details"),
      ],
    );
  }

  Widget _buildStepCircle(String number, String label, {bool isActive = false}) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: isActive ? accentBlue : Colors.grey.shade400,
            child: Text(number, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.black : Colors.grey.shade600)),
      ],
    );
  }
}

// 🌸 STEP 3 — WRITE REVIEW
// … rest of your code remains completely unchanged …

// 🌸 STEP 3 — WRITE REVIEW
// 🌸 STEP 3 — WRITE REVIEW
class WriteReviewScreen extends StatefulWidget {
  final ReviewData reviewData;
  final String vendorId;

  const WriteReviewScreen({super.key, required this.reviewData, required this.vendorId});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> images = [];

  bool get isValid =>
      _titleController.text.trim().isNotEmpty &&
          _descController.text.trim().isNotEmpty;

  Future<void> pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        images.addAll(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text("Write a Review",
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              _buildStepIndicator(2),
              const SizedBox(height: 40),
              const Text("Give your review a title *",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                onChanged: (_) => setState(() {}), // 👈 refresh on typing
                decoration: InputDecoration(
                  hintText: "Amazing Experience",
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryPink, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Tell us about your experience *",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                onChanged: (_) => setState(() {}), // 👈 refresh on typing
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Share the details of your experience with this vendor...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Add Photos (Optional)",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: pickImages,
                icon: const Icon(Icons.upload, color: accentBlue),
                label: const Text("Upload Images"),
              ),
              const SizedBox(height: 10),
              if (images.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: images
                      .map((img) => Image.file(File(img.path),
                      height: 80, width: 80, fit: BoxFit.cover))
                      .toList(),
                ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: primaryPink),
                    label:
                    const Text("Back", style: TextStyle(color: primaryPink)),
                  ),
                  ElevatedButton.icon(
                    onPressed: isValid
                        ? () {
                      widget.reviewData.title = _titleController.text.trim();
                      widget.reviewData.comment = _descController.text.trim();

                      // ✅ Photos optional — continue even if none
                      Navigator.push(
                        context,
                        _createRoute(AdditionalDetailsScreen(
                          reviewData: widget.reviewData,
                          vendorId: widget.vendorId,
                        )),
                      );
                    }
                        : null,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text("Next", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isValid ? primaryPink : Colors.grey.shade400,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )

                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepCircle("1", "Rate Experience", isDone: true),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        _buildStepCircle("2", "Write Review", isActive: true),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        _buildStepCircle("3", "Additional Details"),
      ],
    );
  }

  Widget _buildStepCircle(String number, String label,
      {bool isActive = false, bool isDone = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
          isDone || isActive ? accentBlue : Colors.grey.shade400,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text(number,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.black : Colors.grey.shade600)),
      ],
    );
  }
}

// 🌸 STEP 4 — ADDITIONAL DETAILS & SUBMIT
class AdditionalDetailsScreen extends StatefulWidget {
  final ReviewData reviewData;
  final String vendorId;

  const AdditionalDetailsScreen(
      {super.key, required this.reviewData, required this.vendorId});

  @override
  State<AdditionalDetailsScreen> createState() =>
      _AdditionalDetailsScreenState();
}

class _AdditionalDetailsScreenState extends State<AdditionalDetailsScreen> {
  final _guestController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text("Write a Review",
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              _buildStepIndicator(),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField("Guest Count (Optional)",
                        "Number of guests", _guestController),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTextField("Amount Spent (Optional)",
                        "Amount in ₹", _amountController),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: primaryPink),
                    label:
                    const Text("Back", style: TextStyle(color: primaryPink)),
                  ),
                  ElevatedButton.icon(
                    onPressed: _submitReview,
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Submit Review",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 26),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            focusedBorder: OutlineInputBorder(
                borderSide:
                BorderSide(color: primaryPink, width: 2),
                borderRadius: BorderRadius.circular(12)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepCircle("1", "Rate Experience", isDone: true),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        _buildStepCircle("2", "Write Review", isDone: true),
        Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        _buildStepCircle("3", "Additional Details", isActive: true),
      ],
    );
  }

  Widget _buildStepCircle(String number, String label,
      {bool isDone = false, bool isActive = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor:
          isDone || isActive ? accentBlue : Colors.grey.shade400,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : Text(number,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.black : Colors.grey.shade600)),
      ],
    );
  }

  Future<void> _submitReview() async {
    print("📤 Submit Review Pressed");

    widget.reviewData.guestCount = _guestController.text.trim();
    widget.reviewData.amountSpent = _amountController.text.trim();

    final vendorId = widget.vendorId.trim();
    if (vendorId.isEmpty) {
      AppSnackbar.error(context, "We couldn't identify this vendor. Please go back and try again.");
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    if (authToken == null || authToken.isEmpty) {
      AppSnackbar.info(context, 'Please sign in to post a review.');
      return;
    }

    final Map<String, dynamic> body = {
      'vendor_id': int.parse(vendorId),
      'would_recommend': widget.reviewData.wouldRecommend,
      'rating_quality': widget.reviewData.ratingQuality,
      'rating_responsiveness': widget.reviewData.ratingResponsiveness,
      'rating_professionalism': widget.reviewData.ratingProfessionalism,
      'rating_value': widget.reviewData.ratingValue,
      'rating_flexibility': widget.reviewData.ratingFlexibility,
      'title': widget.reviewData.title,
      'comment': widget.reviewData.comment,
      'happywedz_helped': widget.reviewData.happywedzHelped,
    };

    // only add if not empty
    if (_guestController.text.trim().isNotEmpty) {
      body['guest_count'] = int.tryParse(_guestController.text.trim());
    }
    if (_amountController.text.trim().isNotEmpty) {
      body['spent'] = double.tryParse(_amountController.text.trim());
    }


    final url = Uri.parse('https://happywedz.com/api/reviews/$vendorId');

    print("📤 Body: $body");

    try {
      final res = await http.post(url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken'
          },
          body: jsonEncode(body));

      print("📥 Response: ${res.statusCode} ${res.body}");
      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        await SuccessPopup.show(
          context,
          title: 'Review submitted',
          message: 'Thank you for sharing your experience.',
        );
        if (!mounted) return;
        Navigator.popUntil(context, (r) => r.isFirst);
      } else {
        await ErrorPopup.show(
          context,
          title: "Couldn't submit review",
          message:
              'Something went wrong while posting your review. Please try again.',
          onRetry: _submitReview,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await ErrorPopup.show(
        context,
        title: AppErrorMessage.titleFor(e),
        message: AppErrorMessage.bodyFor(e),
        onRetry: _submitReview,
      );
    }
  }
}

