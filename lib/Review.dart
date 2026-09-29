import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import 'core/config/api_config.dart';
import 'core/core.dart';
import 'main.dart' show requireAuthentication;
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

  /// Photos picked in [WriteReviewScreen]. Carried here so the final submit
  /// step can attach them — previously dropped because this model never held
  /// them, so a picked photo never reached the server.
  List<XFile> images = [];

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

  // REPLACED 2026-09-28 by [toFormFields] (web WriteReviewPage.jsx sends
  // guest_count / spent as "" when left empty, not "0"). Kept per project rule.
  // Map<String, dynamic> toMap() {
  //   final map = {
  //     'would_recommend': wouldRecommend,
  //     'rating_quality': ratingQuality.toInt(),
  //     'rating_responsiveness': ratingResponsiveness.toInt(),
  //     'rating_professionalism': ratingProfessionalism.toInt(),
  //     'rating_value': ratingValue.toInt(),
  //     'rating_flexibility': ratingFlexibility.toInt(),
  //     'title': title,
  //     'comment': comment,
  //     'happywedz_helped': happywedzHelped,
  //     'guest_count': guestCount ?? "0",   // default to "0" if null
  //     'spent': amountSpent ?? "0",       // default to "0" if null
  //   };
  //   return map;
  // }

  /// Exactly the multipart text fields the web appends
  /// (`Object.entries(formData).forEach(([k, v]) => data.append(k, v))`):
  /// every key always present, ratings as integers, optional fields as ""
  /// when blank. No `vendor_id` field — the id travels in the URL.
  Map<String, String> toFormFields() => {
        'would_recommend': wouldRecommend,
        'rating_quality': ratingQuality.toInt().toString(),
        'rating_responsiveness': ratingResponsiveness.toInt().toString(),
        'rating_professionalism': ratingProfessionalism.toInt().toString(),
        'rating_value': ratingValue.toInt().toString(),
        'rating_flexibility': ratingFlexibility.toInt().toString(),
        'title': title,
        'comment': comment,
        'happywedz_helped': happywedzHelped,
        'guest_count': guestCount ?? '',
        'spent': amountSpent ?? '',
      };

  double ratingFor(String field) {
    switch (field) {
      case 'rating_quality':
        return ratingQuality;
      case 'rating_responsiveness':
        return ratingResponsiveness;
      case 'rating_professionalism':
        return ratingProfessionalism;
      case 'rating_value':
        return ratingValue;
      case 'rating_flexibility':
        return ratingFlexibility;
    }
    return 0;
  }

  void setRating(String field, double value) {
    switch (field) {
      case 'rating_quality':
        ratingQuality = value;
      case 'rating_responsiveness':
        ratingResponsiveness = value;
      case 'rating_professionalism':
        ratingProfessionalism = value;
      case 'rating_value':
        ratingValue = value;
      case 'rating_flexibility':
        ratingFlexibility = value;
    }
  }
}

// ---------------------------------------------------------------------------
// Web parity helpers (WriteReviewPage.jsx) — public for unit tests.
// ---------------------------------------------------------------------------

/// Web `ratingLabels`, in the order the web renders the star rows. The web
/// label decides the backend field: Quality → rating_quality, Responsiveness
/// → rating_responsiveness, Professionalism → rating_professionalism, Value
/// → rating_value, Flexibility → rating_flexibility.
const Map<String, String> kReviewRatingLabels = {
  'rating_quality': 'Quality',
  'rating_responsiveness': 'Responsiveness',
  'rating_professionalism': 'Professionalism',
  'rating_value': 'Value',
  'rating_flexibility': 'Flexibility',
};

const String kReviewSuccessMessage = 'Review submitted successfully!';
const String kReviewIncompleteMessage =
    'Please complete all required fields and ratings before submitting.';
const String kReviewTitleMissingMessage =
    'Please provide a title for your review.';
const String kReviewCommentMissingMessage =
    'Please write a comment about your experience.';
const String kReviewFailedMessage = 'Failed to submit.';
const String kReviewBadVendorMessage =
    "We couldn't identify this vendor. Please go back and try again.";

/// Step "Rate Experience" → Next. Null when every rating is set.
String? reviewRatingsError(ReviewData data) {
  final missing = kReviewRatingLabels.keys
      .where((f) => data.ratingFor(f) <= 0)
      .map((f) => kReviewRatingLabels[f]!)
      .toList();
  if (missing.isEmpty) return null;
  return 'Please select a star rating for: ${missing.join(', ')}';
}

/// Step "Write Review" → Next. Null when title and comment are filled.
String? reviewTextError(String title, String comment) {
  if (title.trim().isEmpty) return kReviewTitleMissingMessage;
  if (comment.trim().isEmpty) return kReviewCommentMissingMessage;
  return null;
}

/// Final guard in the web's `handleSubmit`.
String? reviewSubmitError(ReviewData data) {
  if (data.title.trim().isEmpty ||
      data.comment.trim().isEmpty ||
      reviewRatingsError(data) != null) {
    return kReviewIncompleteMessage;
  }
  return null;
}

/// POST target — `${API_BASE_URL}/reviews/${vendorId}` on the web, where
/// `vendorId` is the vendor-SERVICE (listing) id, not the vendor account id.
/// Throws [FormatException] when [serviceId] is not a numeric id.
Uri reviewSubmitUri(String serviceId) {
  final id = int.parse(serviceId.trim());
  return Uri.parse('${ApiConfig.apiBase}/reviews/$id');
}

/// Result of [postReview]: `ok` plus the message to show.
class ReviewSubmitResult {
  final bool ok;
  final String message;
  const ReviewSubmitResult(this.ok, this.message);
}

/// Sends the review exactly like the web: always multipart/form-data (even
/// with no photos), Bearer token, each photo under the `media` field.
Future<ReviewSubmitResult> postReview({
  required http.Client client,
  required String serviceId,
  required ReviewData data,
  required String token,
}) async {
  final request = http.MultipartRequest('POST', reviewSubmitUri(serviceId))
    ..headers['Authorization'] = 'Bearer $token'
    ..fields.addAll(data.toFormFields());
  for (final image in data.images) {
    request.files.add(await http.MultipartFile.fromPath('media', image.path));
  }
  final streamed = await client.send(request);
  final res = await http.Response.fromStream(streamed);
  if (kDebugMode) debugPrint('📥 Response: ${res.statusCode} ${res.body}');

  String? serverMessage;
  try {
    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['message'] != null) {
      serverMessage = decoded['message'].toString();
    }
  } catch (_) {}

  if (res.statusCode >= 200 && res.statusCode < 300) {
    return const ReviewSubmitResult(true, kReviewSuccessMessage);
  }
  return ReviewSubmitResult(
    false,
    (serverMessage != null && serverMessage.isNotEmpty)
        ? serverMessage
        : kReviewFailedMessage,
  );
}


// 🌸 STEP 1 — RECOMMENDATION


class RecommendVendorScreen extends StatelessWidget {
  final String vendorId; // dynamic vendor ID
  final String vendorName;
  final String? vendorImage;
  final String? currentUserId;


  const RecommendVendorScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.vendorImage,
    this.currentUserId,
  });

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
              // Web: business name as the heading, then the fixed question.
              // Text(
              //   "Would you recommend ${vendorName.isNotEmpty ? vendorName : "this vendor"}?",
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              // ),
              if (vendorName.isNotEmpty) ...[
                Text(
                  vendorName,
                  textAlign: TextAlign.center,
                  style: AppText.displaySm,
                ),
                const SizedBox(height: 24),
              ],
              const Text(
                "Would you recommend this vendor?",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
        onTap: () async {
          final reviewData = ReviewData.simple(
            wouldRecommend: isRecommended ? "yes" : "no",
            happywedzHelped: "yes",
          );

          final submitted = await Navigator.push(
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
          // Review posted: close the flow and hand `true` to whoever opened
          // it (the vendor detail screen), like the web's navigate(-1).
          if (submitted == true && context.mounted) {
            Navigator.pop(context, true);
          }
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
  // REPLACED 2026-09-28: labels now follow the web's `ratingLabels`, keyed by
  // the backend field they fill. The old "Communication" / "Value for Money"
  // / "Punctuality" labels did not exist on the web.
  // final Map<String, double> ratings = {
  //   "Quality": 0,
  //   "Professionalism": 0,
  //   "Communication": 0,
  //   "Value for Money": 0,
  //   "Punctuality": 0,
  // };
  /// Backend field → stars, in the web's row order.
  final Map<String, double> ratings = {
    for (final field in kReviewRatingLabels.keys) field: 0,
  };

  String? _error;

  late AnimationController _controller;
  bool get allRated => ratings.values.every((v) => v > 0);

  void _next() {
    ratings.forEach(widget.reviewData.setRating);
    final error = reviewRatingsError(widget.reviewData);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);
    Navigator.push(
      context,
      _createRoute(WriteReviewScreen(
        reviewData: widget.reviewData,
        vendorId: widget.vendorId,
      )),
    ).then((submitted) {
      if (submitted == true && mounted) Navigator.pop(context, true);
    });
  }

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
              // _fadeIn(const Text("Rate your experience", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), 3),
              _fadeIn(const Text("How was your experience?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), 3),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ReviewErrorBanner(message: _error!),
              ],
              const SizedBox(height: 20),
              // Scrolls so five rows + the error banner fit small phones.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: ratings.keys
                        .map((key) => _fadeIn(_buildRatingRow(key), 4))
                        .toList(),
                  ),
                ),
              ),
              // const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: primaryPink),
                    label: const Text("Back", style: TextStyle(color: primaryPink)),
                  ),
                  ElevatedButton.icon(
                    key: const ValueKey('review_rate_next'),
                    // Web keeps Next enabled and explains what is missing.
                    // onPressed: allRated
                    //     ? () {
                    //   // Correct mapping to ReviewData
                    //   widget.reviewData.ratingQuality = ratings["Quality"]!;
                    //   widget.reviewData.ratingProfessionalism = ratings["Professionalism"]!;
                    //   widget.reviewData.ratingResponsiveness = ratings["Communication"]!;
                    //   widget.reviewData.ratingValue = ratings["Value for Money"]!;
                    //   widget.reviewData.ratingFlexibility = ratings["Punctuality"]!;
                    //
                    //   Navigator.push(
                    //     context,
                    //     _createRoute(WriteReviewScreen(reviewData: widget.reviewData, vendorId: widget.vendorId)),
                    //   );
                    // }
                    //     : null,
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text("Next", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: allRated ? primaryPink : Colors.grey.shade300,
                      backgroundColor: primaryPink,
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
            // `label` is the backend field; the web label is shown.
            child: Text(kReviewRatingLabels[label] ?? label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
                  (index) => IconButton(
                key: ValueKey('star_${label}_${index + 1}'),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  index < ratings[label]! ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    ratings[label] = (index + 1).toDouble();
                    _error = null;
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
        // Text(label, style: TextStyle(fontSize: 13, color: isActive ? Colors.black : Colors.grey.shade600)),
        // Bounded like the other two steps — unbounded it overflowed a phone.
        SizedBox(
          width: 76,
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  color: isActive ? Colors.black : Colors.grey.shade600)),
        ),
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

  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _next() {
    final error =
        reviewTextError(_titleController.text, _descController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() => _error = null);
    widget.reviewData.title = _titleController.text.trim();
    widget.reviewData.comment = _descController.text.trim();
    widget.reviewData.images = images;
    Navigator.push(
      context,
      _createRoute(AdditionalDetailsScreen(
        reviewData: widget.reviewData,
        vendorId: widget.vendorId,
      )),
    ).then((submitted) {
      if (submitted == true && mounted) Navigator.pop(context, true);
    });
  }

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
          // Content scrolls, the action row stays pinned. The previous
          // Spacer() overflowed as soon as the keyboard opened.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
              if (_error != null) ...[
                const SizedBox(height: 20),
                _ReviewErrorBanner(message: _error!),
              ],
              const SizedBox(height: 40),
              const Text("Give your review a title *",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('review_title'),
                controller: _titleController,
                onChanged: (_) => setState(() => _error = null), // 👈 refresh on typing
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
                key: const ValueKey('review_comment'),
                controller: _descController,
                onChanged: (_) => setState(() => _error = null), // 👈 refresh on typing
                maxLines: 6,
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
                  // children: images
                  //     .map((img) => Image.file(File(img.path),
                  //     height: 80, width: 80, fit: BoxFit.cover))
                  //     .toList(),
                  // Web previews carry a remove (×) button per photo.
                  children: [
                    for (var i = 0; i < images.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(images[i].path),
                                height: 80, width: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => images.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                    key: const ValueKey('review_write_next'),
                    // Web keeps Next enabled and explains what is missing.
                    // onPressed: isValid
                    //     ? () {
                    //   widget.reviewData.title = _titleController.text.trim();
                    //   widget.reviewData.comment = _descController.text.trim();
                    //   widget.reviewData.images = images;
                    //
                    //   // ✅ Photos optional — continue even if none
                    //   Navigator.push(
                    //     context,
                    //     _createRoute(AdditionalDetailsScreen(
                    //       reviewData: widget.reviewData,
                    //       vendorId: widget.vendorId,
                    //     )),
                    //   );
                    // }
                    //     : null,
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    label: const Text("Next", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: isValid ? primaryPink : Colors.grey.shade400,
                      backgroundColor: primaryPink,
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
        // Bounded so three labels + two dividers never exceed the row.
        SizedBox(
          width: 76,
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  color: isActive ? Colors.black : Colors.grey.shade600)),
        ),
      ],
    );
  }
}

// 🌸 STEP 4 — ADDITIONAL DETAILS & SUBMIT
class AdditionalDetailsScreen extends StatefulWidget {
  final ReviewData reviewData;
  final String vendorId;

  /// Injected for tests; defaults to a fresh [http.Client].
  final http.Client? httpClient;

  const AdditionalDetailsScreen(
      {super.key,
      required this.reviewData,
      required this.vendorId,
      this.httpClient});

  @override
  State<AdditionalDetailsScreen> createState() =>
      _AdditionalDetailsScreenState();
}

class _AdditionalDetailsScreenState extends State<AdditionalDetailsScreen> {
  final _guestController = TextEditingController();
  final _amountController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _guestController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Content scrolls, the action row stays pinned. The previous
          // Spacer() overflowed as soon as the keyboard opened.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: primaryPink),
                    label:
                    const Text("Back", style: TextStyle(color: primaryPink)),
                  ),
                  const SizedBox(width: 12),
                  // Flexible so a large text scale never overflows the row.
                  Flexible(
                    child: ElevatedButton.icon(
                    key: const ValueKey('review_submit'),
                    // onPressed: _submitReview,
                    onPressed: _submitting ? null : _submitReview,
                    icon: const Icon(Icons.check, color: Colors.white),
                    // label: const Text("Submit Review",
                    //     style: TextStyle(color: Colors.white)),
                    label: Text(
                        _submitting ? "Submitting..." : "Submit Review",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 26),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
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
          key: ValueKey('review_field_$label'),
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
        // Bounded so three labels + two dividers never exceed the row.
        SizedBox(
          width: 76,
          child: Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  color: isActive ? Colors.black : Colors.grey.shade600)),
        ),
      ],
    );
  }

  // LEGACY submit — REPLACED 2026-09-28. Posted to `/api/reviews/{id}`
  // (live: "Route not found"), sent JSON with a `vendor_id` field when there
  // were no photos, crashed on a non-numeric id (int.parse outside try) and
  // popped to the first route. Kept per project rule.
  // Future<void> _submitReview() async {
  //   debugPrint("📤 Submit Review Pressed");
  //
  //   widget.reviewData.guestCount = _guestController.text.trim();
  //   widget.reviewData.amountSpent = _amountController.text.trim();
  //
  //   final vendorId = widget.vendorId.trim();
  //   if (vendorId.isEmpty) {
  //     AppSnackbar.error(context, "We couldn't identify this vendor. Please go back and try again.");
  //     return;
  //   }
  //
  //   // Normally already signed in (the entry points ask first); this covers a
  //   // session that ended while the review was being written — the text the
  //   // user typed stays on screen underneath the sign-in page.
  //   if (!await requireAuthentication(
  //     context,
  //     reason: 'Sign in to post your review.',
  //   )) {
  //     return;
  //   }
  //   if (!mounted) return;
  //   final prefs = await SharedPreferences.getInstance();
  //   final authToken = prefs.getString('auth_token');
  //   if (authToken == null || authToken.isEmpty) return;
  //
  //   final Map<String, dynamic> body = {
  //     'vendor_id': int.parse(vendorId),
  //     'would_recommend': widget.reviewData.wouldRecommend,
  //     'rating_quality': widget.reviewData.ratingQuality,
  //     'rating_responsiveness': widget.reviewData.ratingResponsiveness,
  //     'rating_professionalism': widget.reviewData.ratingProfessionalism,
  //     'rating_value': widget.reviewData.ratingValue,
  //     'rating_flexibility': widget.reviewData.ratingFlexibility,
  //     'title': widget.reviewData.title,
  //     'comment': widget.reviewData.comment,
  //     'happywedz_helped': widget.reviewData.happywedzHelped,
  //   };
  //
  //   // only add if not empty
  //   if (_guestController.text.trim().isNotEmpty) {
  //     body['guest_count'] = int.tryParse(_guestController.text.trim());
  //   }
  //   if (_amountController.text.trim().isNotEmpty) {
  //     body['spent'] = double.tryParse(_amountController.text.trim());
  //   }
  //
  //
  //   final url = Uri.parse('${ApiConfig.baseUrl}/api/reviews/$vendorId');
  //
  //   debugPrint("📤 Body: $body");
  //
  //   try {
  //     final http.Response res;
  //     final images = widget.reviewData.images;
  //     if (images.isEmpty) {
  //       res = await http.post(url,
  //           headers: {
  //             'Content-Type': 'application/json',
  //             'Authorization': 'Bearer $authToken'
  //           },
  //           body: jsonEncode(body));
  //     } else {
  //       // Picked review photos were previously discarded here — the request
  //       // was always plain JSON with nothing attaching them. Matches the
  //       // source's multipart `media` field.
  //       final request = http.MultipartRequest('POST', url)
  //         ..headers['Authorization'] = 'Bearer $authToken';
  //       body.forEach((key, value) {
  //         if (value != null) request.fields[key] = value.toString();
  //       });
  //       for (final image in images) {
  //         request.files.add(
  //           await http.MultipartFile.fromPath('media', image.path),
  //         );
  //       }
  //       final streamed = await request.send();
  //       res = await http.Response.fromStream(streamed);
  //     }
  //
  //     // AUDIT FIX (security): response bodies carry user data and are readable
  //     // via `adb logcat` in a release build — debug only.
  //     if (kDebugMode) debugPrint("📥 Response: ${res.statusCode} ${res.body}");
  //     if (!mounted) return;
  //
  //     if (res.statusCode == 200 || res.statusCode == 201) {
  //       await SuccessPopup.show(
  //         context,
  //         title: 'Review submitted',
  //         message: 'Thank you for sharing your experience.',
  //       );
  //       if (!mounted) return;
  //       Navigator.popUntil(context, (r) => r.isFirst);
  //     } else {
  //       await ErrorPopup.show(
  //         context,
  //         title: "Couldn't submit review",
  //         message:
  //             'Something went wrong while posting your review. Please try again.',
  //         onRetry: _submitReview,
  //       );
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     await ErrorPopup.show(
  //       context,
  //       title: AppErrorMessage.titleFor(e),
  //       message: AppErrorMessage.bodyFor(e),
  //       onRetry: _submitReview,
  //     );
  //   }
  // }

  /// Web `handleSubmit`: final guard, always-multipart POST to
  /// `${ApiConfig.apiBase}/reviews/{serviceId}`, success toast, then back to
  /// the screen that opened the flow with `true`.
  Future<void> _submitReview() async {
    if (_submitting) return;
    debugPrint("📤 Submit Review Pressed");

    widget.reviewData.guestCount = _guestController.text.trim();
    widget.reviewData.amountSpent = _amountController.text.trim();

    final incomplete = reviewSubmitError(widget.reviewData);
    if (incomplete != null) {
      AppSnackbar.error(context, incomplete);
      return;
    }

    // Normally already signed in (the entry points ask first); this covers a
    // session that ended while the review was being written — the text the
    // user typed stays on screen underneath the sign-in page.
    if (!await requireAuthentication(
      context,
      reason: 'Sign in to post your review.',
    )) {
      return;
    }
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    if (!mounted) return;
    if (authToken == null || authToken.isEmpty) {
      AppSnackbar.error(context, 'Please sign in to post your review.');
      return;
    }

    setState(() => _submitting = true);
    final client = widget.httpClient ?? http.Client();
    try {
      final ReviewSubmitResult result;
      try {
        result = await postReview(
          client: client,
          serviceId: widget.vendorId,
          data: widget.reviewData,
          token: authToken,
        );
      } on FormatException {
        // Non-numeric / empty id: previously an uncaught int.parse crash.
        if (mounted) AppSnackbar.error(context, kReviewBadVendorMessage);
        return;
      }
      if (!mounted) return;
      if (result.ok) {
        AppSnackbar.success(context, result.message);
        Navigator.pop(context, true);
      } else {
        AppSnackbar.error(context, result.message);
      }
    } catch (e) {
      debugPrint("[REVIEW] submit error: $e");
      if (mounted) AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    } finally {
      if (widget.httpClient == null) client.close();
      if (mounted) setState(() => _submitting = false);
    }
  }
}

/// Inline error, the app's version of the web's `<Alert severity="error">`.
class _ReviewErrorBanner extends StatelessWidget {
  final String message;
  const _ReviewErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppText.body.copyWith(color: AppColors.errorDark),
            ),
          ),
        ],
      ),
    );
  }
}
