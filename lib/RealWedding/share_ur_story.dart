//
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:dotted_border/dotted_border.dart';
// import 'package:flutter/material.dart';

import '../core/core.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:path/path.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
//
//
//
// share_wedding_story.dart
import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class Venue {
  final int id;
  final String name;
  final String city;
  final String image;           // first image for suggestions
  final List<String> gallery;   // all images
  final String price;
  final String pax;
  final String type;
  final bool isFavourite;

  Venue({
    required this.id,
    required this.name,
    required this.city,
    required this.image,
    required this.gallery,
    required this.price,
    required this.pax,
    required this.type,
    required this.isFavourite,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    final attributes = json["attributes"] ?? {};
    final vendor = json["vendor"] ?? {};
    final subcat = json["subcategory"] ?? {};

    // SAFE GALLERY PARSE
    List<String> galleryImages = [];
    if (json["media"] is List) {
      galleryImages = (json["media"] as List)
          .whereType<String>()
          .map((url) => url.startsWith("http")
          ? url
          : "https://happywedzbackend.happywedz.com$url")
          .toList();
    }

    // MAIN IMAGE = first gallery image or placeholder
    final mainImage = galleryImages.isNotEmpty
        ? galleryImages.first
        : "https://via.placeholder.com/400x300.png?text=No+Image";

    return Venue(
      id: int.tryParse(json["id"].toString()) ?? 0,

      // Name
      name: vendor["businessName"]?.toString() ?? "Unnamed Venue",

      // City
      city: attributes["city"]?.toString() ?? "Unknown City",

      // Image
      image: mainImage,

      // Gallery
      gallery: galleryImages,

      // Price
      price: attributes["veg_price"] != null
          ? "₹ ${attributes["veg_price"]} per plate"
          : "Price not available",

      pax: attributes["area"]?.toString() ?? "Capacity not available",

      type: subcat["name"]?.toString() ?? "Venue",

      isFavourite: json["is_favourite"] == true || json["is_favourite"] == 1,
    );
  }
}

// class ShareWeddingStory extends StatefulWidget {
//   const ShareWeddingStory({Key? key}) : super(key: key);
//
//   @override
//   State<ShareWeddingStory> createState() => _ShareWeddingStoryState();
// }
//
// class _ShareWeddingStoryState extends State<ShareWeddingStory> {
//
//   final TextEditingController storyCtrl = TextEditingController();
//   int wordCount = 0;
//   int currentStep = 1;
//
//   bool isBold = false;
//   bool isItalic = false;
//   bool isUnderline = false;
//   TextAlign align = TextAlign.left;
//
//
//   final List<String> steps = [
//     'Basic Info',
//     'Couple',
//     'Wedding Story',
//     'Events',
//     'Vendors',
//     'Gallery',
//     'Highlights',
//     'Credits & Publish',
//   ];
//
//   // For dropdown data
//
//   List<String> selectedVenues = [];
//
//   List<String> countries = [];
//   List<Venue> allVenues = [];
//   List<String> cultures = [];
//   bool isLoadingVenues = false;
//   bool isLoadingCountries = false;
//   bool isLoadingCultures = false;
//
//   bool _settingSlugProgrammatically = false;
//   bool _slugEditedByUser = false;
//
//
//
//
// // Selected values
//   String? selectedCountry;
//   Venue? selectedVenue;
//   String? selectedCulture;
//   String? selectedTheme;
//
//
//
//   TextEditingController venueSearchCtrl = TextEditingController();
//
//   List<Venue> venueSuggestions = [];
//
//
//   bool isSearchingVenues = false;
//
//
//   final ImagePicker _picker = ImagePicker();
//   List<File> _coverPhotos = [];
//   List<File> _highlightPhotos = [];
//   List<File> _weddingPhotos = [];
//
//   // STEP 1 controllers
//   final TextEditingController titleCtrl = TextEditingController();
//   final TextEditingController slugCtrl = TextEditingController();
//   final TextEditingController weddingDateCtrl = TextEditingController();
//   final TextEditingController countryCtrl = TextEditingController();
//   final TextEditingController cityCtrl = TextEditingController();
//   final TextEditingController venuesCtrl = TextEditingController();
//
//   // Couple info
//   final TextEditingController brideNameCtrl = TextEditingController();
//   final TextEditingController groomNameCtrl = TextEditingController();
//   final TextEditingController brideBioCtrl = TextEditingController();
//   final TextEditingController groomBioCtrl = TextEditingController();
//
//   // Story
//
//
//   // Events & Vendors
//   List<Map<String, dynamic>> events = [];
//   List<Map<String, dynamic>> vendors = [];
//
//   final TextEditingController eventNameCtrl = TextEditingController();
//   final TextEditingController eventDateCtrl = TextEditingController();
//   final TextEditingController eventVenueCtrl = TextEditingController();
//   final TextEditingController eventDescCtrl = TextEditingController();
//
//   // STEP 7 controllers (themes/outfits/special moments)
//   final TextEditingController weddingThemesCtrl = TextEditingController();
//   final TextEditingController brideOutfitCtrl = TextEditingController();
//   final TextEditingController groomOutfitCtrl = TextEditingController();
//   final TextEditingController specialMomentsCtrl = TextEditingController();
//
//   // Credits
//   final TextEditingController photographerCtrl = TextEditingController();
//   final TextEditingController makeupCtrl = TextEditingController();
//   final TextEditingController decorCtrl = TextEditingController();
//   final TextEditingController vendorNameCtrl = TextEditingController();
//   String? selectedVendorType;
//
//   List<Map<String, dynamic>> additionalCredits = [];
//
//   bool isFeatured = false;
//   bool isSubmitting = false;
//
//   List<String> vendorTypes = [];
//
//
//
//   @override
//   void initState() {
//
//     fetchVendorTypes().then((types) {
//       setState(() {
//         vendorTypes = types;
//       });
//     });
//
//     storyCtrl.addListener(() {
//       final text = storyCtrl.text.trim();
//       setState(() {
//         wordCount = text.isEmpty ? 0 : text.split(RegExp(r"\s+")).length;
//       });
//     });
//
//     venueSearchCtrl.addListener(() {
//       searchVenues(venueSearchCtrl.text.trim());
//     });
//
//     loadAllVenues();
//
//     super.initState();
//     fetchCountries();
//     fetchCultures();
//     searchVenues("");
//
//     titleCtrl.addListener(() {
//       if (_slugEditedByUser) return; // user manually edited slug → stop auto-sync
//
//       _settingSlugProgrammatically = true;
//
//       // AUTO COPY TITLE → SLUG (same text, no slugify)
//       slugCtrl.text = titleCtrl.text;
//
//       _settingSlugProgrammatically = false;
//     });
//
//     slugCtrl.addListener(() {
//       if (_settingSlugProgrammatically) return; // ignore programmatic updates
//       _slugEditedByUser = true; // user started editing slug manually
//     });
//
//
//   }
//
//   @override
//   void dispose() {
//     titleCtrl.dispose();
//     slugCtrl.dispose();
//     weddingDateCtrl.dispose();
//     countryCtrl.dispose();
//     cityCtrl.dispose();
//     venuesCtrl.dispose();
//     brideNameCtrl.dispose();
//     groomNameCtrl.dispose();
//     brideBioCtrl.dispose();
//     groomBioCtrl.dispose();
//     storyCtrl.dispose();
//     weddingThemesCtrl.dispose();
//     brideOutfitCtrl.dispose();
//     groomOutfitCtrl.dispose();
//     specialMomentsCtrl.dispose();
//     photographerCtrl.dispose();
//     makeupCtrl.dispose();
//     decorCtrl.dispose();
//     super.dispose();
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,   // ✅ shows gradient behind appbar
//       backgroundColor: Colors.transparent, // ✅ let gradient be visible
//
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,   // ✅ transparent appbar
//         centerTitle: true,
//         title: const Text(
//           "Share Your Wedding Story",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         iconTheme: const IconThemeData(
//           color: Colors.white,
//         ),
//       ),
//
//
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),  // Hot pink
//               Color(0xFFFFB6C1),  // Light pink
//               Colors.white,       // White
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//
//                 const Center(
//                   child: Text(
//                     "Inspire thousands of couples with your special day",
//                     style: TextStyle(fontSize: 14, color: Colors.black54),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//
//                 // ✅ Keeps your steps + content
//                 // ------------------- TOP STEPS WITH PINK LINE -------------------
//                 SizedBox(
//                   height: 90,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//
//                       // ---------- PINK LINE BEHIND CIRCLES ----------
//                       Positioned(
//                         top: 18,  // aligns perfectly with circle center
//                         left: 0,
//                         right: 0,
//                         child: Container(
//                           height: 3,
//                           color: const Color(0xFFE91E63).withValues(alpha: 0.4),
//                         ),
//                       ),
//
//                       // ---------- STEPS SCROLLING ROW ----------
//                       ListView.separated(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: steps.length,
//                         separatorBuilder: (_, __) => const SizedBox(width: 35), // equal spacing
//                         itemBuilder: (context, index) {
//                           final isActive = index + 1 == currentStep;
//
//                           return GestureDetector(
//                             onTap: () {
//                               if (index + 1 <= currentStep + 1) {
//                                 setState(() => currentStep = index + 1);
//                               }
//                             },
//                             child: Column(
//                               children: [
//                                 CircleAvatar(
//                                   radius: 21,
//                                   backgroundColor: Colors.white,
//                                   child: CircleAvatar(
//                                     radius: 18,
//                                     backgroundColor: isActive
//                                         ? const Color(0xFFE91E63)
//                                         : Colors.grey.shade300,
//                                     child: Text(
//                                       "${index + 1}",
//                                       style: TextStyle(
//                                         color: isActive ? Colors.white : Colors.black54,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 SizedBox(
//                                   width: 80,
//                                   child: Text(
//                                     steps[index],
//                                     textAlign: TextAlign.center,
//                                     maxLines: 2,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: isActive
//                                           ? const Color(0xFFE91E63)
//                                           : Colors.black54,
//                                       fontWeight:
//                                       isActive ? FontWeight.bold : FontWeight.normal,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//
//
//                 const SizedBox(height: 24),
//
//                 if (currentStep == 1) _buildStep1(),
//                 if (currentStep == 2) _buildStep2(),
//                 if (currentStep == 3) _buildStep3(),
//                 if (currentStep == 4) _buildStep4(),
//                 if (currentStep == 5) _buildStep5(),
//                 if (currentStep == 6) _buildStep6(),
//                 if (currentStep == 7) _buildStep7(),
//                 if (currentStep == 8) _buildStep8(),
//
//                 const SizedBox(height: 30),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     if (currentStep > 1)
//                       OutlinedButton(
//                         onPressed: () => setState(() => currentStep--),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: Colors.black87,
//                           side: const BorderSide(color: Colors.black26),
//                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                         child: const Text("Previous"),
//                       )
//                     else
//                       const SizedBox(width: 110),
//
//                     Row(
//                       children: [
//                         OutlinedButton(
//                           onPressed: () {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text("Draft saved locally")),
//                             );
//                           },
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: Colors.black87,
//                             side: const BorderSide(color: Colors.black26),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           child: const Text("Save Draft"),
//                         ),
//                         const SizedBox(width: 12),
//                         ElevatedButton(
//                           onPressed: isSubmitting
//                               ? null
//                               : () async {
//                             if (currentStep < steps.length) {
//                               setState(() => currentStep++);
//                             } else {
//                               setState(() => isSubmitting = true);
//                               await _submitWeddingStory(context);
//                               setState(() => isSubmitting = false);
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFE91E63),
//                             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(30),
//                             ),
//                           ),
//                           child: isSubmitting
//                               ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: Colors.white,
//                             ),
//                           )
//                               : Text(
//                             currentStep < steps.length
//                                 ? "Next"
//                                 : "Submit for\n Approval",
//                             style: const TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _submitWeddingStory(BuildContext context) async {
//     print("🟢 Starting wedding story submission...");
//     final url = Uri.parse('https://happywedz.com/api/realwedding');
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//
//     if (token == null || token.isEmpty) {
//       print("❌ No token found!");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please login first')),
//       );
//       return;
//     }
//
//     if (titleCtrl.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter wedding title')),
//       );
//       return;
//     }
//
//     try {
//       var request = http.MultipartRequest('POST', url);
//
//       // -------------------------
//       // 🔐 Correct Auth Headers
//       // -------------------------
//       request.headers['Authorization'] = 'Bearer $token';
//       request.headers['Accept'] = 'application/json';
//       // ❌ DO NOT add Content-Type manually, MultipartRequest will set it.
//
//       // -------------------------
//       // 🗓 Format Date
//       // -------------------------
//       String weddingDateToSend = weddingDateCtrl.text.trim();
//       if (weddingDateToSend.isNotEmpty) {
//         weddingDateToSend = _tryFormatDate(weddingDateToSend) ?? weddingDateToSend;
//       }
//
//       // -------------------------
//       // 🏨 Venues (multiple)
//       // -------------------------
//       final List<String> venueList = selectedVenues.map((v) => v.toString()).toList();
//
//       // -------------------------
//       // 📝 Add Fields
//       // -------------------------
//       request.fields.addAll({
//         'title': titleCtrl.text.trim(),
//         'slug': slugCtrl.text.trim(),
//         'weddingDate': weddingDateToSend,
//         'country': selectedCountry ?? "",
//         'city': cityCtrl.text.trim(),
//         'venues': jsonEncode(venueList),
//
//         'brideName': brideNameCtrl.text.trim(),
//         'brideBio': brideBioCtrl.text.trim(),
//         'groomName': groomNameCtrl.text.trim(),
//         'groomBio': groomBioCtrl.text.trim(),
//         'story': storyCtrl.text.trim(),
//
//         'events': jsonEncode(events),
//         'vendors': jsonEncode(vendors),
//         'themes': jsonEncode(
//             weddingThemesCtrl.text.trim().isNotEmpty ? [weddingThemesCtrl.text.trim()] : []
//         ),
//         'additionalCredits': jsonEncode(additionalCredits),
//
//         'brideOutfit': brideOutfitCtrl.text.trim(),
//         'groomOutfit': groomOutfitCtrl.text.trim(),
//         'specialMoments': specialMomentsCtrl.text.trim(),
//         'photographer': photographerCtrl.text.trim(),
//         'makeup': makeupCtrl.text.trim(),
//         'decor': decorCtrl.text.trim(),
//
//         'status': 'pending',
//         'featured': isFeatured ? 'true' : 'false',
//       });
//
//       print("📝 FIELDS SENT:");
//       request.fields.forEach((k, v) => print("   ➤ $k: $v"));
//
//
//       // -------------------------
//       // 📸 Add Files
//       // -------------------------
//
//       // Cover Photo (single)
//       if (_coverPhotos.isNotEmpty) {
//         final file = _coverPhotos.first;
//         request.files.add(
//           await http.MultipartFile.fromPath('coverPhoto', file.path),
//         );
//         print("📌 coverPhoto: ${file.path}");
//       }
//
//       // Highlight Photos (multiple)
//       for (var file in _highlightPhotos) {
//         request.files.add(
//           await http.MultipartFile.fromPath('highlightPhotos', file.path),
//         );
//         print("✨ highlightPhotos: ${file.path}");
//       }
//
//       // All Photos (multiple)
//       for (var file in _weddingPhotos) {
//         request.files.add(
//           await http.MultipartFile.fromPath('allPhotos', file.path),
//         );
//         print("📷 allPhotos: ${file.path}");
//       }
//
//       // -------------------------
//       // 🚀 Send Request
//       // -------------------------
//       print("🚀 Sending request...");
//       setState(() => isSubmitting = true);
//
//       final streamedResponse = await request.send();
//       final status = streamedResponse.statusCode;
//       final respStr = await streamedResponse.stream.bytesToString();
//
//       print("📡 STATUS: $status");
//       print("📨 RESPONSE: $respStr");
//
//       if (status == 200 || status == 201) {
//         print("✅ Wedding story submitted successfully!");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Wedding story submitted successfully!')),
//         );
//         return;
//       } else if (status == 401) {
//         print("❌ Unauthorized token!");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Session expired. Please login again')),
//         );
//         return;
//       } else {
//         print("❌ Failed: $status");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed to submit ($status): $respStr")),
//         );
//       }
//
//     } catch (e, st) {
//       print("🔥 ERROR: $e\n$st");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error: $e')),
//       );
//     } finally {
//       setState(() => isSubmitting = false);
//     }
//   }
//
//   String? _tryFormatDate(String input) {
//     final candidates = [
//       "yyyy-MM-dd",
//       "dd/MM/yyyy",
//       "MM/dd/yyyy",
//       "dd-MM-yyyy",
//       "yyyy/MM/dd"
//     ];
//
//     for (var fmt in candidates) {
//       try {
//         final parsed = DateFormat(fmt).parseStrict(input);
//         return DateFormat('yyyy-MM-dd').format(parsed);
//       } catch (_) {
//         // ignore
//       }
//     }
//     return null;
//   }
//
//   void filterVenues(String query) {
//     if (query.isEmpty) {
//       setState(() => venueSuggestions = []);
//       return;
//     }
//
//     setState(() {
//       venueSuggestions = allVenues
//           .where((v) => v.name.toLowerCase().startsWith(query.toLowerCase()))
//           .toList()
//         ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
//     });
//   }
//
//   Future<List<String>> fetchVendorTypes() async {
//     final url = Uri.parse('https://happywedz.com/api/vendor-types/with-subcategories/all');
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       // assuming API returns list of objects with 'name'
//       return List<String>.from(data.map((item) => item['name']));
//     } else {
//       throw Exception('Failed to load vendor types');
//     }
//   }
//
//   Future<void> _selectDate(BuildContext ctx) async {
//     final DateTime? picked = await showDatePicker(
//       context: ctx,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFFE91E63),
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//             textButtonTheme: TextButtonThemeData(
//               style: TextButton.styleFrom(
//                 foregroundColor: Color(0xFFE91E63),
//               ),
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null) {
//       eventDateCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
//     }
//   }
//
//   Future<void> fetchCountries() async {
//     setState(() => isLoadingCountries = true);
//
//     try {
//       final response = await http.get(
//         Uri.parse('https://countriesnow.space/api/v0.1/countries'),
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final List countriesData = data['data'];
//
//         countries = countriesData.map<String>((c) => c['country']).toList();
//
//         setState(() {
//           isLoadingCountries = false;
//         });
//       }
//     } catch (e) {
//       print("Country API Error: $e");
//       setState(() => isLoadingCountries = false);
//     }
//   }
//
//   Future<void> loadAllVenues() async {
//     try {
//       final url = Uri.parse("https://happywedz.com/api/vendor-services?vendorType=Venues");
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         List list = decoded["data"] ?? [];
//
//         allVenues = list.map((v) => Venue.fromJson(v)).toList();
//         setState(() {});
//       }
//     } catch (e) {
//       print("Error loading all venues $e");
//     }
//   }
//
//   Future<void> fetchCultures() async {
//     setState(() => isLoadingCultures = true);
//
//     try {
//       final url = Uri.parse("https://happywedz.com/api/real-wedding-culture/public");
//       final response = await http.get(url, headers: {"Accept": "application/json"});
//
//       print("👉 Culture API Status: ${response.statusCode}");
//       print("👉 Culture API Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//
//         final List<dynamic> list = decoded["cultures"] ?? [];
//
//         setState(() {
//           cultures = list.map((c) => c["name"].toString()).toList();
//           isLoadingCultures = false;
//         });
//       } else {
//         throw Exception("Invalid status");
//       }
//     } catch (e) {
//       print("❌ Culture API error: $e");
//       setState(() => isLoadingCultures = false);
//     }
//   }
//
//   Future<void> _selectWeddingDate(BuildContext ctx) async {
//     final DateTime? picked = await showDatePicker(
//       context: ctx,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Color(0xFFE91E63),
//               onPrimary: Colors.white,
//               onSurface: Colors.black,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       weddingDateCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
//     }
//   }
//
//   Future<void> searchVenues(String query) async {
//     // If empty → clear
//     if (query.isEmpty) {
//       setState(() => venueSuggestions = []);
//       return;
//     }
//
//     // 1️⃣ Local suggestions first (instant response)
//     List<Venue> localFiltered = allVenues
//         .where((v) => v.name.toLowerCase().startsWith(query.toLowerCase()))
//         .toList()
//       ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
//
//     setState(() => venueSuggestions = localFiltered); // show instantly
//
//     // 2️⃣ API suggestions (optional)
//     try {
//       final url = Uri.parse(
//         "https://happywedz.com/api/vendor-services?search=$query&vendorType=Venues",
//       );
//
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         final rawData = decoded["data"];
//
//         List<Venue> apiList = [];
//
//         if (rawData is List) {
//           apiList = rawData.map((v) => Venue.fromJson(v)).toList();
//         } else if (rawData is Map && rawData["data"] is List) {
//           apiList =
//               (rawData["data"] as List).map((v) => Venue.fromJson(v)).toList();
//         }
//
//         // Merge + remove duplicates
//         List<Venue> combined = [...localFiltered, ...apiList];
//
//         combined = {
//           for (var v in combined) v.name.toLowerCase(): v
//         }.values.toList();
//
//         combined.sort(
//                 (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
//
//         setState(() => venueSuggestions = combined);
//       }
//     } catch (e) {
//       print("Venue search error: $e");
//     }
//   }
//
//   Widget _buildStep1() {
//
//     return Builder(
//       builder: (outerContext) => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//
//           const Text(
//             "📋 Basic Information",
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
//           ),
//           const SizedBox(height: 16),
//
//           _buildTextField("Wedding Title", "e.g. Krishna and Radha Romantic Beach Wedding",
//               controller: titleCtrl),
//           const SizedBox(height: 12),
//
//           _buildTextField("URL Slug", "e.g. emma-james-beach-wedding", controller: slugCtrl),
//           const SizedBox(height: 12),
//
//           /// DATE PICKER FIX WORKS NOW
//           GestureDetector(
//             onTap: () => _selectWeddingDate(outerContext),
//             child: AbsorbPointer(
//               child: _buildTextField(
//                 "Wedding Date",
//                 "dd-mm-yyyy",
//                 controller: weddingDateCtrl,
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 12),
//
//           // COUNTRY
//           const Text("Country", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//           const SizedBox(height: 6),
//           isLoadingCountries
//               ? const Center(child: CircularProgressIndicator())
//               :SizedBox(
//             width: double.infinity,
//             child: DropdownButtonFormField<String>(
//               value: selectedCountry,
//               isExpanded: true, // prevents overflow
//               items: countries
//                   .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//                   .toList(),
//               onChanged: (v) => setState(() => selectedCountry = v),
//               decoration: InputDecoration(
//                 hintText: "Select Country",
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 20),
//
//           // CITY
//           _buildTextField("City", "Enter your city (e.g. Mumbai, Delhi, New York)",
//               controller: cityCtrl),
//           const SizedBox(height: 12),
//
//           // CULTURE
//           const Text("Culture", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//           const SizedBox(height: 6),
//           isLoadingCultures
//               ? const Center(child: CircularProgressIndicator())
//               : DropdownButtonFormField<String>(
//             value: selectedCulture,
//             items: cultures.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//             onChanged: (v) => setState(() => selectedCulture = v),
//             decoration: InputDecoration(
//               hintText: "Select Culture",
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           // ⭐ VENUE SEARCH
//           const Text("Venue", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//           const SizedBox(height: 6),
//
//           TextField(
//             controller: venueSearchCtrl,
//             decoration: InputDecoration(
//               hintText: "Search venues or type and press Enter to add",
//               border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//             ),
//             onSubmitted: (value) {
//               if (value.trim().isEmpty) return;
//
//               setState(() {
//                 selectedVenues.add(value.trim());
//               });
//
//               venueSearchCtrl.clear();
//             },
//           ),
//
//
//
//           if (isSearchingVenues)
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: CircularProgressIndicator(),
//             ),
//
//           if (venueSuggestions.isNotEmpty)
//             ConstrainedBox(
//               constraints: const BoxConstraints(maxHeight: 220),
//               child: Container(
//                 margin: const EdgeInsets.only(top: 4),
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.grey.shade300),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: ListView.builder(
//                   itemCount: venueSuggestions.length,
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   itemBuilder: (context, index) {
//                     final v = venueSuggestions[index];
//                     return ListTile(
//                       leading: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           v.image,
//                           width: 50,
//                           height: 50,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) =>
//                           const Icon(Icons.image_not_supported, size: 40),
//                         ),
//                       ),
//                       title: Text(v.name),
//                       subtitle: Text(v.city),
//                         onTap: () {
//                           setState(() {
//                             if (!selectedVenues.contains(v.name)) {
//                               selectedVenues.add(v.name);
//                             }
//                             venueSearchCtrl.clear();   // <-- important
//                             venueSuggestions = [];
//                           });
//                         }
//
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//           const SizedBox(height: 12),
//
//           // SHOW SELECTED VENUES AS CHIPS
//           if (selectedVenues.isNotEmpty)
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: selectedVenues.map((venue) {
//                 return Chip(
//                   label: Text(
//                     venue,
//                     style: const TextStyle(color: Color(0xFFE91E63)),
//                   ),
//                   backgroundColor: const Color(0xFFFFE0EB),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(50),
//                   ),
//                   deleteIcon: const Icon(Icons.close, size: 18, color: Color(0xFFE91E63)),
//                   onDeleted: () {
//                     setState(() {
//                       selectedVenues.remove(venue);
//                     });
//                   },
//                 );
//               }).toList(),
//             ),
//
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStep2() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Couple Information",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(child: _buildTextField("Bride's Name", "e.g. Emma Smith", controller: brideNameCtrl)),
//             const SizedBox(width: 10),
//             Expanded(child: _buildTextField("Groom's Name", "e.g. James Wilson", controller: groomNameCtrl)),
//           ],
//         ),
//         const SizedBox(height: 12),
//         _buildTextField("Bride's Bio", "Tell us about the bride...", controller: brideBioCtrl, maxLines: 4),
//         const SizedBox(height: 12),
//         _buildTextField("Groom's Bio", "Tell us about the groom...", controller: groomBioCtrl, maxLines: 4),
//       ],
//     );
//   }
//
//   Widget _buildStep3() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Wedding Story",
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Color(0xFFE91E63),
//           ),
//         ),
//
//         const SizedBox(height: 16),
//
//         const Text(
//           "Your Wedding Story",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//         ),
//         const SizedBox(height: 12),
//
//         // ⭐ Toolbar (custom)
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(6),
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: Row(
//             children: [
//               formattingButton(Icons.format_bold, isBold, () {
//                 setState(() => isBold = !isBold);
//               }),
//               const SizedBox(width: 8),
//               formattingButton(Icons.format_italic, isItalic, () {
//                 setState(() => isItalic = !isItalic);
//               }),
//               const SizedBox(width: 8),
//               formattingButton(Icons.format_underline, isUnderline, () {
//                 setState(() => isUnderline = !isUnderline);
//               }),
//               const SizedBox(width: 20),
//
//               // Alignment buttons
//               formattingButton(Icons.format_align_left, align == TextAlign.left, () {
//                 setState(() => align = TextAlign.left);
//               }),
//               const SizedBox(width: 8),
//               formattingButton(Icons.format_align_center, align == TextAlign.center, () {
//                 setState(() => align = TextAlign.center);
//               }),
//               const SizedBox(width: 8),
//               formattingButton(Icons.format_align_right, align == TextAlign.right, () {
//                 setState(() => align = TextAlign.right);
//               }),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 10),
//
//         // ⭐ Editor box
//         Container(
//           height: 260,
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(6),
//             border: Border.all(color: Colors.grey.shade300),
//           ),
//           child: TextField(
//             controller: storyCtrl,
//             maxLines: null,
//             expands: true,
//             textAlign: align,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
//               fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
//               decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
//             ),
//             decoration: const InputDecoration(
//               hintText: "Share how your love story unfolded...",
//               border: InputBorder.none,
//             ),
//           ),
//         ),
//
//         const SizedBox(height: 6),
//
//         Text(
//           "$wordCount words",
//           style: const TextStyle(color: Colors.grey),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStep4() {
//     return Builder(
//       builder: (outerContext) => Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Adding Events",
//             style: TextStyle(
//                 fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
//           ),
//           const SizedBox(height: 16),
//
//           Row(
//             children: [
//               Expanded(
//                 child: _buildTextFieldWithController(
//                   "Event name",
//                   "e.g., Mehandi",
//                   controller: eventNameCtrl,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () => _selectDate(outerContext),
//                   child: AbsorbPointer(
//                     child: _buildTextFieldWithController(
//                       "Date",
//                       "dd-mm-yyyy",
//                       controller: eventDateCtrl,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 12),
//           _buildTextFieldWithController(
//             "Venues",
//             "Add a venue and press enter",
//             controller: eventVenueCtrl,
//           ),
//           const SizedBox(height: 12),
//           _buildTextFieldWithController(
//             "Description (optional)",
//             "Brief details about this event",
//             controller: eventDescCtrl,
//           ),
//           const SizedBox(height: 12),
//
//           StatefulBuilder(
//             builder: (buttonContext, setStateButton) {
//               bool isHovered = false;
//               bool isPressed = false;
//
//               return MouseRegion(
//                 onEnter: (_) => setStateButton(() => isHovered = true),
//                 onExit: (_) => setStateButton(() => isHovered = false),
//                 child: GestureDetector(
//                   onTapDown: (_) => setStateButton(() => isPressed = true),
//                   onTapUp: (_) {
//                     setStateButton(() => isPressed = false);
//                     if (eventNameCtrl.text.trim().isNotEmpty) {
//                       setState(() {
//                         events.add({
//                           'name': eventNameCtrl.text.trim(),
//                           'date': eventDateCtrl.text.trim(),
//                           'venue': eventVenueCtrl.text.trim(),
//                           'description': eventDescCtrl.text.trim(),
//                         });
//                       });
//                       eventNameCtrl.clear();
//                       eventDateCtrl.clear();
//                       eventVenueCtrl.clear();
//                       eventDescCtrl.clear();
//                     } else {
//                       ScaffoldMessenger.of(outerContext).showSnackBar(
//                         const SnackBar(content: Text('Please enter event name')),
//                       );
//                     }
//                   },
//                   onTapCancel: () => setStateButton(() => isPressed = false),
//                   child: DottedBorder(
//                     color: const Color(0xFFE91E63),
//                     strokeWidth: 1.5,
//                     dashPattern: const [6, 4],
//                     borderType: BorderType.RRect,
//                     radius: const Radius.circular(30),
//                     child: AnimatedContainer(
//                       duration: const Duration(milliseconds: 150),
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: (isHovered || isPressed)
//                             ? const Color(0xFFE91E63)
//                             : Colors.transparent,
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.add,
//                               color: (isHovered || isPressed)
//                                   ? Colors.white
//                                   : const Color(0xFFE91E63)),
//                           const SizedBox(width: 8),
//                           Text(
//                             "Add Event",
//                             style: TextStyle(
//                               color: (isHovered || isPressed)
//                                   ? Colors.white
//                                   : const Color(0xFFE91E63),
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//
//           const SizedBox(height: 12),
//           if (events.isNotEmpty) ...[
//             const SizedBox(height: 12),
//             const Text("Added Events:", style: TextStyle(fontWeight: FontWeight.w600)),
//             const SizedBox(height: 8),
//             Column(
//               children: List.generate(events.length, (i) {
//                 final ev = events[i];
//                 return ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   title: Text(ev['name'] ?? ''),
//                   subtitle: Text("${ev['date']} • ${ev['venue']}"),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete_outline),
//                     onPressed: () {
//                       setState(() {
//                         events.removeAt(i);
//                       });
//                     },
//                   ),
//                 );
//               }),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStep5() {
//     return SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Step Title
//             const Text(
//               "🧑‍💼 Vendors",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFFE91E63),
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               "Add Your Wedding Vendors",
//               style: TextStyle(fontSize: 14, color: Colors.black54),
//             ),
//             const SizedBox(height: 16),
//
//             // Vendor Input Container
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 border: Border.all(color: Colors.black12),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Labels
//                   Row(
//                     children: const [
//                       Expanded(
//                         child: Text(
//                           "Vendor Type",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 10),
//                       Expanded(
//                         child: Text(
//                           "Vendor Name",
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//
//                   // Input Fields
//                   Row(
//                     children: [
//                       Expanded(
//                         child: vendorTypes.isEmpty
//                             ? const Center(child: CircularProgressIndicator())
//                             : DropdownButtonFormField<String>(
//                           isExpanded: true, // Prevent overflow
//                           decoration: InputDecoration(
//                             hintText: "Select type",
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 14),
//                           ),
//                           value: selectedVendorType,
//                           items: vendorTypes
//                               .map((type) => DropdownMenuItem(
//                             value: type,
//                             child: Text(type),
//                           ))
//                               .toList(),
//                           onChanged: (val) {
//                             setState(() => selectedVendorType = val);
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: _buildTextField(
//                           "",
//                           "e.g. DreamWed Planners",
//                           controller: vendorNameCtrl,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Add Vendor Button
//                   GestureDetector(
//                     onTap: () {
//                       if ((selectedVendorType ?? '').isNotEmpty &&
//                           vendorNameCtrl.text.trim().isNotEmpty) {
//                         setState(() {
//                           vendors.add({
//                             'type': selectedVendorType!,
//                             'name': vendorNameCtrl.text.trim(),
//                           });
//                         });
//                         vendorNameCtrl.clear();
//                         selectedVendorType = null;
//                       }
//                     },
//                     child: DottedBorder(
//                       color: const Color(0xFFE91E63),
//                       strokeWidth: 1.5,
//                       dashPattern: const [6, 4],
//                       borderType: BorderType.RRect,
//                       radius: const Radius.circular(30),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 22, vertical: 12),
//                         alignment: Alignment.center,
//                         child: const Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(Icons.add, color: Color(0xFFE91E63)),
//                             SizedBox(width: 10),
//                             Text(
//                               "Add Vendor",
//                               style: TextStyle(
//                                 color: Color(0xFFE91E63),
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Added Vendors List
//             if (vendors.isNotEmpty) ...[
//               const Text(
//                 "Added Vendors:",
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
//               ),
//               const SizedBox(height: 10),
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: vendors.length,
//                 itemBuilder: (context, index) {
//                   final vendor = vendors[index];
//                   return Card(
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                       side: const BorderSide(color: Colors.black12),
//                     ),
//                     child: ListTile(
//                       title: Text(vendor['name']),
//                       subtitle: Text(vendor['type']),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.delete_outline),
//                         onPressed: () {
//                           setState(() => vendors.removeAt(index));
//                         },
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ],
//         ));
//     }
//
//
//   Widget _buildStep6() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "📷 Gallery",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
//         ),
//         const SizedBox(height: 16),
//         // Cover
//         _buildGallerySection(
//           title: "Cover Photo",
//           imageList: _coverPhotos,
//           onPickImage: () async {
//             final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//             if (pickedFile != null) {
//               setState(() => _coverPhotos = [File(pickedFile.path)]);
//             }
//           },
//         ),
//         const SizedBox(height: 24),
//         // Highlight
//         _buildGallerySection(
//           title: "Highlight Photos",
//           imageList: _highlightPhotos,
//           onPickImage: () async {
//             final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//             if (pickedFile != null) {
//               setState(() => _highlightPhotos.add(File(pickedFile.path)));
//             }
//           },
//         ),
//         const SizedBox(height: 24),
//         // All wedding photos
//         _buildGallerySection(
//           title: "All Wedding Photos",
//           imageList: _weddingPhotos,
//           onPickImage: () async {
//             final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
//             if (pickedFile != null) {
//               setState(() => _weddingPhotos.add(File(pickedFile.path)));
//             }
//           },
//         ),
//       ],
//     );
//   }
//
//   Widget _buildStep7() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Highlights",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
//         ),
//         const SizedBox(height: 12),
//
//         /// 🔽 Wedding Themes Dropdown
//         DropdownButtonFormField<String>(
//           decoration: InputDecoration(
//             labelText: "Wedding Themes",
//             border: OutlineInputBorder(),
//           ),
//           value: selectedTheme,
//           hint: const Text("Select a theme"),
//           items: [
//             "Destination",
//             "Classic",
//             "Grand & Luxurious",
//             "Pocket Friendly Stunners",
//             "Intimate & Minimalist",
//             "Modern & Stylish",
//             "International",
//             "Others",
//           ].map((theme) {
//             return DropdownMenuItem(
//               value: theme,
//               child: Text(theme),
//             );
//           }).toList(),
//           onChanged: (value) {
//             setState(() {
//               selectedTheme = value;
//               weddingThemesCtrl.text = value ?? "";
//             });
//           },
//         ),
//
//         const SizedBox(height: 12),
//
//         Row(
//           children: [
//             Expanded(child: _buildTextField("Bride's Outfit", "Describe the bride's outfit", controller: brideOutfitCtrl)),
//             const SizedBox(width: 10),
//             Expanded(child: _buildTextField("Groom's Outfit", "e.g. James Wilson", controller: groomOutfitCtrl)),
//           ],
//         ),
//         const SizedBox(height: 12),
//         _buildTextField("Special Moments", "Share the most memorable moments from your wedding...", controller: specialMomentsCtrl, maxLines: 4),
//       ],
//     );
//   }
//
//   Widget _buildStep8() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "👤 Credits & Publish",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
//         ),
//         const SizedBox(height: 16),
//         _buildTextField("Photographer", "Photographer's name or business", controller: photographerCtrl),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             Expanded(child: _buildTextField("Makeup Artist", "Makeup artist's name or business", controller: makeupCtrl)),
//             const SizedBox(width: 12),
//             Expanded(child: _buildTextField("Decor & Floral", "Decorator's name or business", controller: decorCtrl)),
//           ],
//         ),
//         const SizedBox(height: 20),
//         const Divider(),
//         const SizedBox(height: 12),
//         // Featured Toggle
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
//               Text("Featured Wedding", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
//               SizedBox(height: 4),
//             ]),
//             Switch(
//               activeColor: Color(0xFFE91E63),
//               value: isFeatured,
//               onChanged: (val) {
//                 setState(() => isFeatured = val);
//               },
//             ),
//           ],
//         ),
//         const SizedBox(height: 30),
//       ],
//     );
//   }
//
//   Widget _buildGallerySection({
//     required String title,
//     required List<File> imageList,
//     required VoidCallback onPickImage,
//   }) {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
//       const SizedBox(height: 8),
//       GestureDetector(
//         onTap: onPickImage,
//         child: DottedBorder(
//           color: const Color(0xFFE91E63),
//           strokeWidth: 1.5,
//           dashPattern: const [6, 4],
//           borderType: BorderType.RRect,
//           radius: const Radius.circular(12),
//           child: Container(
//             width: double.infinity,
//             height: 120,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
//             child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
//               Icon(Icons.cloud_upload_outlined, size: 28, color: Color(0xFFE91E63)),
//               SizedBox(height: 8),
//               Text("Tap to browse photos", style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
//             ]),
//           ),
//         ),
//       ),
//       const SizedBox(height: 12),
//       if (imageList.isNotEmpty)
//         Wrap(
//           spacing: 12,
//           runSpacing: 12,
//           children: List.generate(imageList.length, (index) {
//             return Stack(children: [
//               ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(imageList[index], width: 100, height: 100, fit: BoxFit.cover)),
//               Positioned(
//                 right: 4,
//                 top: 4,
//                 child: GestureDetector(
//                   onTap: () => setState(() => imageList.removeAt(index)),
//                   child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, size: 16, color: Colors.white)),
//                 ),
//               )
//             ]);
//           }),
//         ),
//     ]);
//   }
//   Widget formattingButton(IconData icon, bool active, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(6),
//         decoration: BoxDecoration(
//           color: active ? Colors.pink.shade100 : Colors.white,
//           borderRadius: BorderRadius.circular(6),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Icon(icon, size: 20, color: active ? Colors.pink : Colors.black),
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, String hint, {int maxLines = 1, TextEditingController? controller}) {
//     return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//       Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
//       const SizedBox(height: 6),
//       TextField(
//         controller: controller,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           hintText: hint,
//           hintStyle: const TextStyle(color: Colors.black45),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
//           enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
//         ),
//       ),
//       const SizedBox(height: 12),
//     ]);
//   }
//
//   // wrapper (used in your step code)
//   Widget _buildTextFieldWithController(String label, String hint, {int maxLines = 1, required TextEditingController controller}) {
//     return _buildTextField(label, hint, maxLines: maxLines, controller: controller);
//   }
//
// }


/// Make sure Venue class exists in your project; original code referenced it.
/// If it's in another file, import that file. For demonstration, a minimal class:
// class Venue {
//   final String id;
//   final String name;
//   final String city;
//   final String image;
//
//   Venue({
//     required this.id,
//     required this.name,
//     required this.city,
//     required this.image,
//   });
//
//   factory Venue.fromJson(Map<String, dynamic> json) {
//     return Venue(
//       id: json['id']?.toString() ?? '',
//       name: json['name']?.toString() ?? '',
//       city: json['city']?.toString() ?? '',
//       image: json['image']?.toString() ??
//           'https://via.placeholder.com/150', // fallback
//     );
//   }
// }

class ShareWeddingStory extends StatefulWidget {
  const ShareWeddingStory({Key? key}) : super(key: key);

  @override
  State<ShareWeddingStory> createState() => _ShareWeddingStoryState();
}

class _ShareWeddingStoryState extends State<ShareWeddingStory> {
  // ----------------------------
  // Keep all existing controllers, fields & methods intact
  // (I did not change names or signatures)
  // ----------------------------

  final TextEditingController storyCtrl = TextEditingController();
  int wordCount = 0;
  int currentStep = 1;

  bool isBold = false;
  bool isItalic = false;
  bool isUnderline = false;
  TextAlign align = TextAlign.left;

  final List<String> steps = [
    'Basic Info',
    'Couple',
    'Wedding Story',
    'Events',
    'Vendors',
    'Gallery',
    'Highlights',
    'Credits & Publish',
  ];

  List<String> selectedVenues = [];

  List<String> countries = [];
  List<Venue> allVenues = [];
  List<String> cultures = [];
  bool isLoadingVenues = false;
  bool isLoadingCountries = false;
  bool isLoadingCultures = false;

  bool _settingSlugProgrammatically = false;
  bool _slugEditedByUser = false;

  String? selectedCountry;
  Venue? selectedVenue;
  String? selectedCulture;
  String? selectedTheme;

  TextEditingController venueSearchCtrl = TextEditingController();

  List<Venue> venueSuggestions = [];

  bool isSearchingVenues = false;

  final ImagePicker _picker = ImagePicker();
  List<File> _coverPhotos = [];
  List<File> _highlightPhotos = [];
  List<File> _weddingPhotos = [];

  // STEP 1 controllers
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController slugCtrl = TextEditingController();
  final TextEditingController weddingDateCtrl = TextEditingController();
  final TextEditingController countryCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController venuesCtrl = TextEditingController();

  // Couple info
  final TextEditingController brideNameCtrl = TextEditingController();
  final TextEditingController groomNameCtrl = TextEditingController();
  final TextEditingController brideBioCtrl = TextEditingController();
  final TextEditingController groomBioCtrl = TextEditingController();

  // Events & Vendors
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> vendors = [];

  final TextEditingController eventNameCtrl = TextEditingController();
  final TextEditingController eventDateCtrl = TextEditingController();
  final TextEditingController eventVenueCtrl = TextEditingController();
  final TextEditingController eventDescCtrl = TextEditingController();

  // STEP 7 controllers (themes/outfits/special moments)
  final TextEditingController weddingThemesCtrl = TextEditingController();
  final TextEditingController brideOutfitCtrl = TextEditingController();
  final TextEditingController groomOutfitCtrl = TextEditingController();
  final TextEditingController specialMomentsCtrl = TextEditingController();

  // Credits
  final TextEditingController photographerCtrl = TextEditingController();
  final TextEditingController makeupCtrl = TextEditingController();
  final TextEditingController decorCtrl = TextEditingController();
  final TextEditingController vendorNameCtrl = TextEditingController();
  String? selectedVendorType;

  List<Map<String, dynamic>> additionalCredits = [];

  bool isFeatured = false;
  bool isSubmitting = false;

  List<String> vendorTypes = [];

  // ----------------------------
  // initState / dispose / listeners
  // ----------------------------
  @override
  void initState() {
    super.initState();

    fetchVendorTypes().then((types) {
      setState(() {
        vendorTypes = types;
      });
    });

    storyCtrl.addListener(() {
      final text = storyCtrl.text.trim();
      setState(() {
        wordCount = text.isEmpty ? 0 : text.split(RegExp(r"\s+")).length;
      });
    });

    venueSearchCtrl.addListener(() {
      searchVenues(venueSearchCtrl.text.trim());
    });

    loadAllVenues();
    fetchCountries();
    fetchCultures();
    searchVenues("");

    titleCtrl.addListener(() {
      if (_slugEditedByUser) return;
      _settingSlugProgrammatically = true;
      slugCtrl.text = titleCtrl.text;
      _settingSlugProgrammatically = false;
    });

    slugCtrl.addListener(() {
      if (_settingSlugProgrammatically) return;
      _slugEditedByUser = true;
    });
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    slugCtrl.dispose();
    weddingDateCtrl.dispose();
    countryCtrl.dispose();
    cityCtrl.dispose();
    venuesCtrl.dispose();
    brideNameCtrl.dispose();
    groomNameCtrl.dispose();
    brideBioCtrl.dispose();
    groomBioCtrl.dispose();
    storyCtrl.dispose();
    weddingThemesCtrl.dispose();
    brideOutfitCtrl.dispose();
    groomOutfitCtrl.dispose();
    specialMomentsCtrl.dispose();
    photographerCtrl.dispose();
    makeupCtrl.dispose();
    decorCtrl.dispose();
    venueSearchCtrl.dispose();
    eventNameCtrl.dispose();
    eventDateCtrl.dispose();
    eventVenueCtrl.dispose();
    eventDescCtrl.dispose();
    vendorNameCtrl.dispose();
    super.dispose();
  }

  // ----------------------------
  // BUILD (main scaffold)
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFEEF6), // very light pink
              Color(0xFFFFF7FB), // near-white
            ],
            stops: [0.0, 0.9],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroSection(),
                const SizedBox(height: 20),
                _stepsScroller(),
                const SizedBox(height: 18),
                // Steps Content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _stepContent(),
                ),
                const SizedBox(height: 30),
                _actionRow(context),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------
  // AppBar
  // ----------------------------
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        "Share Your Wedding Story",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  // ----------------------------
  // Hero section
  // ----------------------------
  Widget _heroSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F6), Color(0xFFFFF7FB)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.pink.shade50),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              // illustration circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC1E3), Color(0xFFFF9FCE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Inspire thousands of couples with your special day",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Share your story, photos and vendor details — let your wedding shine!",
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------
  // Steps scroller
  // ----------------------------
  Widget _stepsScroller() {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // horizontal soft line
          Positioned(
            top: 48,
            left: 10,
            right: 10,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // steps
          ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: steps.length,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final isActive = index + 1 == currentStep;
              final reached = index + 1 <= currentStep;
              return GestureDetector(
                onTap: () {
                  if (index + 1 <= currentStep + 1) {
                    setState(() => currentStep = index + 1);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isActive ? 54 : 48,
                      height: isActive ? 54 : 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                            colors: [Color(0xFFFF9FCE), Color(0xFFFF578E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                            : null,
                        color: isActive ? null : Colors.white,
                        border: Border.all(
                          color: reached ? Colors.pink.shade100 : Colors.grey.shade200,
                        ),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.16),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: Text(
                        steps[index],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.pink.shade600 : Colors.black54,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Step content switcher
  // ----------------------------
  Widget _stepContent() {
    switch (currentStep) {
      case 1:
        return _wrappedGlass(child: _buildStep1());
      case 2:
        return _wrappedGlass(child: _buildStep2());
      case 3:
        return _wrappedGlass(child: _buildStep3());
      case 4:
        return _wrappedGlass(child: _buildStep4());
      case 5:
        return _wrappedGlass(child: _buildStep5());
      case 6:
        return _wrappedGlass(child: _buildStep6());
      case 7:
        return _wrappedGlass(child: _buildStep7());
      case 8:
        return _wrappedGlass(child: _buildStep8());
      default:
        return _wrappedGlass(child: _buildStep1());
    }
  }

  // Glass wrapper used for each step (consistent styling)
  Widget _wrappedGlass({required Widget child}) {
    return Container(
      key: ValueKey(currentStep),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: child,
    );
  }

  // ----------------------------
  // Action row (previous / save / next)
  // ----------------------------
  Widget _actionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 12,
        children: [

          // Previous button (only if > step 1)
          if (currentStep > 1)
            _outlinedButton(
              label: "Previous",
              onPressed: () => setState(() => currentStep--),
            )
          else
            const SizedBox(width: 110),

          // Save Draft
          _outlinedButton(
            label: "Save Draft",
            onPressed: () {
              AppSnackbar.info(context, "Draft saved locally");
            },
          ),

          // Next or Submit button
          _primaryButton(
            label: currentStep < steps.length ? "Next" : "Submit for Approval",
            loading: isSubmitting,
            onPressed: isSubmitting
                ? null
                : () async {
              if (currentStep < steps.length) {
                setState(() => currentStep++);
              } else {
                setState(() => isSubmitting = true);
                await _submitWeddingStory(context);
                setState(() => isSubmitting = false);
              }
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // UI Helpers: Buttons / Inputs / Formatting button
  // ----------------------------
  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 6,
        backgroundColor: Colors.pink.shade400,
      ),
      child: loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _outlinedButton({required String label, required VoidCallback onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
    );
  }

  Widget formattingButton(IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? Colors.pink.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icon, size: 20, color: active ? Colors.pink.shade400 : Colors.black54),
      ),
    );
  }

  Widget _styledTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    int maxLines = 1,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.pink.shade500),
          ),
        ),
      GestureDetector(
        onTap: onTap,
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly || onTap != null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.pink.shade50)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.pink.shade50)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.pink.shade200, width: 2)),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // ----------------------------
  // Step 1 (Basic Info) - redesigned
  // ----------------------------
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _gradientTitle("📋 Basic Information"),
        const SizedBox(height: 12),
        // Row: Title + Slug
        Row(
          children: [
            Expanded(child: _styledTextField(label: "Wedding Title", hint: "e.g. Krishna and Radha Romantic Beach Wedding", controller: titleCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _styledTextField(label: "URL Slug", hint: "e.g. emma-james-beach-wedding", controller: slugCtrl)),
          ],
        ),
        // Date / Country / City
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectWeddingDate(context),
                child: AbsorbPointer(
                  child: _styledTextField(label: "Wedding Date", hint: "dd-mm-yyyy", controller: weddingDateCtrl),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: isLoadingCountries
                  ? const AppLoader()
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedCountry,
                  isExpanded: true,
                  items: countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => selectedCountry = v),
                  decoration: InputDecoration(
                    hintText: "Select Country",
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ],
        ),
        _styledTextField(label: "City", hint: "Enter your city (e.g. Mumbai, Delhi, New York)", controller: cityCtrl),
        // Culture
        const SizedBox(height: 6),
        Text("Culture", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.pink.shade500)),
        const SizedBox(height: 8),
        isLoadingCultures
            ? const AppLoader()
            : DropdownButtonFormField<String>(
          value: selectedCulture,
          items: cultures.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => selectedCulture = v),
          decoration: InputDecoration(
            hintText: "Select Culture",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),

        // Venue search + suggestions
        Text("Venue", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.pink.shade500)),
        const SizedBox(height: 8),
        TextField(
          controller: venueSearchCtrl,
          decoration: InputDecoration(
            hintText: "Search venues or type and press Enter to add",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (value) {
            if (value.trim().isEmpty) return;
            setState(() {
              selectedVenues.add(value.trim());
            });
            venueSearchCtrl.clear();
          },
        ),

        if (isSearchingVenues) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
        const SizedBox(height: 8),
        if (venueSuggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              color: Colors.white,
            ),
            child: ListView.builder(
              itemCount: venueSuggestions.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                final v = venueSuggestions[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: NetworkImageWidget(url: v.image, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  title: Text(v.name),
                  subtitle: Text(v.city),
                  onTap: () {
                    setState(() {
                      if (!selectedVenues.contains(v.name)) {
                        selectedVenues.add(v.name);
                      }
                      venueSearchCtrl.clear();
                      venueSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        if (selectedVenues.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedVenues.map((venue) {
              return Chip(
                label: Text(venue, style: TextStyle(color: Colors.pink.shade600)),
                backgroundColor: Colors.pink.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                deleteIcon: Icon(Icons.close, size: 18, color: Colors.pink.shade600),
                onDeleted: () {
                  setState(() {
                    selectedVenues.remove(venue);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // ----------------------------
  // Step 2: Couple Information
  // ----------------------------
  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("Couple Information"),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _styledTextField(label: "Bride's Name", hint: "e.g. Emma Smith", controller: brideNameCtrl)),
          const SizedBox(width: 12),
          Expanded(child: _styledTextField(label: "Groom's Name", hint: "e.g. James Wilson", controller: groomNameCtrl)),
        ],
      ),
      _styledTextField(label: "Bride's Bio", hint: "Tell us about the bride...", controller: brideBioCtrl, maxLines: 4),
      _styledTextField(label: "Groom's Bio", hint: "Tell us about the groom...", controller: groomBioCtrl, maxLines: 4),
    ]);
  }

  // ----------------------------
  // Step 3: Wedding Story (editor toolbar)
  // ----------------------------
  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("Wedding Story"),
      const SizedBox(height: 16),
      const Text("Your Wedding Story", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),

      // toolbar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink.shade50),
        ),
        child: Row(children: [
          formattingButton(Icons.format_bold, isBold, () => setState(() => isBold = !isBold)),
          const SizedBox(width: 8),
          formattingButton(Icons.format_italic, isItalic, () => setState(() => isItalic = !isItalic)),
          const SizedBox(width: 8),
          formattingButton(Icons.format_underline, isUnderline, () => setState(() => isUnderline = !isUnderline)),
          const SizedBox(width: 16),
          formattingButton(Icons.format_align_left, align == TextAlign.left, () => setState(() => align = TextAlign.left)),
          const SizedBox(width: 8),
          formattingButton(Icons.format_align_center, align == TextAlign.center, () => setState(() => align = TextAlign.center)),
          const SizedBox(width: 8),
          formattingButton(Icons.format_align_right, align == TextAlign.right, () => setState(() => align = TextAlign.right)),
        ]),
      ),

      const SizedBox(height: 12),

      // editor
      Container(
        height: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.pink.shade50),
        ),
        child: TextField(
          controller: storyCtrl,
          maxLines: null,
          expands: true,
          textAlign: align,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          ),
          decoration: const InputDecoration.collapsed(hintText: "Share how your love story unfolded..."),
        ),
      ),
      const SizedBox(height: 8),
      Text("$wordCount words", style: const TextStyle(color: Colors.grey)),
    ]);
  }

  // ----------------------------
  // Step 4: Events
  // ----------------------------
  Widget _buildStep4() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("Adding Events"),
      const SizedBox(height: 14),

      Row(children: [
        Expanded(child: _styledTextField(label: "Event name", hint: "e.g., Mehandi", controller: eventNameCtrl)),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(child: _styledTextField(label: "Date", hint: "dd-mm-yyyy", controller: eventDateCtrl)),
          ),
        ),
      ]),
      _styledTextField(label: "Venues", hint: "Add a venue and press enter", controller: eventVenueCtrl),
      _styledTextField(label: "Description (optional)", hint: "Brief details about this event", controller: eventDescCtrl),

      const SizedBox(height: 8),

      // Add Event dotted button
      GestureDetector(
        onTap: () {
          if (eventNameCtrl.text.trim().isNotEmpty) {
            setState(() {
              events.add({
                'name': eventNameCtrl.text.trim(),
                'date': eventDateCtrl.text.trim(),
                'venue': eventVenueCtrl.text.trim(),
                'description': eventDescCtrl.text.trim(),
              });
            });
            eventNameCtrl.clear();
            eventDateCtrl.clear();
            eventVenueCtrl.clear();
            eventDescCtrl.clear();
          } else {
            AppSnackbar.info(context, 'Please enter event name');
          }
        },
        child: DottedBorder(
          color: Colors.pink.shade200,
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, color: Colors.pink.shade400),
              const SizedBox(width: 8),
              Text("Add Event", style: TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      ),

      const SizedBox(height: 14),
      if (events.isNotEmpty) ...[
        const SizedBox(height: 6),
        const Text("Added Events:", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Column(
          children: List.generate(events.length, (i) {
            final ev = events[i];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
              child: ListTile(
                title: Text(ev['name'] ?? ''),
                subtitle: Text("${ev['date']} • ${ev['venue']}"),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => events.removeAt(i))),
              ),
            );
          }),
        ),
      ],
    ]);
  }

  // ----------------------------
  // Step 5: Vendors
  // ----------------------------
  Widget _buildStep5() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("🧑‍💼 Vendors"),
      const SizedBox(height: 10),
      const Text("Add Your Wedding Vendors", style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 12),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.pink.shade50),
        ),
        child: Column(children: [
          Row(children: const [
            Expanded(child: Text("Vendor Type", style: TextStyle(fontWeight: FontWeight.w700))),
            SizedBox(width: 8),
            Expanded(child: Text("Vendor Name", style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: vendorTypes.isEmpty
                  ? const AppLoader()
                  : DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: "Select type",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                value: selectedVendorType,
                items: vendorTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) => setState(() => selectedVendorType = val),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _styledTextField(label: "", hint: "e.g. DreamWed Planners", controller: vendorNameCtrl)),
          ]),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if ((selectedVendorType ?? '').isNotEmpty && vendorNameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  vendors.add({'type': selectedVendorType!, 'name': vendorNameCtrl.text.trim()});
                });
                vendorNameCtrl.clear();
                selectedVendorType = null;
              }
            },
            child: DottedBorder(
              color: Colors.pink.shade200,
              strokeWidth: 1.5,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                alignment: Alignment.center,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, color: Colors.pink.shade400),
                  const SizedBox(width: 10),
                  Text("Add Vendor", style: TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 14),
      if (vendors.isNotEmpty) ...[
        const Text("Added Vendors:", style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
              child: ListTile(
                title: Text(vendor['name']),
                subtitle: Text(vendor['type']),
                trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => setState(() => vendors.removeAt(index))),
              ),
            );
          },
        ),
      ],
    ]);
  }

  // ----------------------------
  // Step 6: Gallery
  // ----------------------------
  Widget _buildStep6() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("📷 Gallery"),
      const SizedBox(height: 12),
      _buildGallerySection(
        title: "Cover Photo",
        imageList: _coverPhotos,
        onPickImage: () async {
          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            setState(() => _coverPhotos = [File(pickedFile.path)]);
          }
        },
      ),
      const SizedBox(height: 18),
      _buildGallerySection(
        title: "Highlight Photos",
        imageList: _highlightPhotos,
        onPickImage: () async {
          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            setState(() => _highlightPhotos.add(File(pickedFile.path)));
          }
        },
      ),
      const SizedBox(height: 18),
      _buildGallerySection(
        title: "All Wedding Photos",
        imageList: _weddingPhotos,
        onPickImage: () async {
          final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            setState(() => _weddingPhotos.add(File(pickedFile.path)));
          }
        },
      ),
    ]);
  }

  Widget _buildGallerySection({
    required String title,
    required List<File> imageList,
    required VoidCallback onPickImage,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.pink.shade500)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onPickImage,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.pink.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.pink.shade50),
          ),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.cloud_upload_outlined, size: 28, color: Colors.pink.shade400),
              const SizedBox(height: 8),
              const Text("Tap to browse photos", style: TextStyle(color: Colors.black54)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (imageList.isNotEmpty)
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(imageList.length, (index) {
            return Stack(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(imageList[index], width: 100, height: 100, fit: BoxFit.cover)),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => setState(() => imageList.removeAt(index)),
                  child: Container(decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                ),
              )
            ]);
          }),
        ),
    ]);
  }

  // ----------------------------
  // Step 7: Highlights
  // ----------------------------
  Widget _buildStep7() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("Highlights"),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: "Wedding Themes", border: OutlineInputBorder()),
        value: selectedTheme,
        hint: const Text("Select a theme"),
        items: [
          "Destination",
          "Classic",
          "Grand & Luxurious",
          "Pocket Friendly Stunners",
          "Intimate & Minimalist",
          "Modern & Stylish",
          "International",
          "Others",
        ].map((theme) => DropdownMenuItem(value: theme, child: Text(theme))).toList(),
        onChanged: (value) {
          setState(() {
            selectedTheme = value;
            weddingThemesCtrl.text = value ?? "";
          });
        },
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _styledTextField(label: "Bride's Outfit", hint: "Describe the bride's outfit", controller: brideOutfitCtrl)),
        const SizedBox(width: 12),
        Expanded(child: _styledTextField(label: "Groom's Outfit", hint: "e.g. James Wilson", controller: groomOutfitCtrl)),
      ]),
      _styledTextField(label: "Special Moments", hint: "Share the most memorable moments from your wedding...", controller: specialMomentsCtrl, maxLines: 4),
    ]);
  }

  // ----------------------------
  // Step 8: Credits & Publish
  // ----------------------------
  Widget _buildStep8() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _gradientTitle("👤 Credits & Publish"),
      const SizedBox(height: 12),
      _styledTextField(label: "Photographer", hint: "Photographer's name or business", controller: photographerCtrl),
      Row(children: [
        Expanded(child: _styledTextField(label: "Makeup Artist", hint: "Makeup artist's name or business", controller: makeupCtrl)),
        const SizedBox(width: 12),
        Expanded(child: _styledTextField(label: "Decor & Floral", hint: "Decorator's name or business", controller: decorCtrl)),
      ]),
      const SizedBox(height: 18),
      const Divider(),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text("Featured Wedding", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          SizedBox(height: 4),
        ]),
        Switch(
          activeColor: Color(0xFFE91E63),
          value: isFeatured,
          onChanged: (val) {
            setState(() => isFeatured = val);
          },
        ),
      ]),
      const SizedBox(height: 20),
    ]);
  }

  // ----------------------------
  // Utility: gradient title
  // ----------------------------
  Widget _gradientTitle(String text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 6,
        height: 28,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade200]),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.pink.shade600),
      ),
    ]);
  }

  // ----------------------------
  // ----------------------------
  // The following methods are kept exactly as in your original file:
  // - _submitWeddingStory
  // - _tryFormatDate
  // - filterVenues
  // - fetchVendorTypes
  // - _selectDate
  // - fetchCountries
  // - loadAllVenues
  // - fetchCultures
  // - _selectWeddingDate
  // - searchVenues
  // All method bodies are preserved (but formatted to fit this file).
  // ----------------------------
  // ----------------------------

  Future<void> _submitWeddingStory(BuildContext context) async {
    print("🟢 Starting wedding story submission...");
    final url = Uri.parse('https://happywedz.com/api/realwedding');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      print("❌ No token found!");
      AppSnackbar.info(context, 'Please login first');
      return;
    }

    if (titleCtrl.text.trim().isEmpty) {
      AppSnackbar.info(context, 'Please enter wedding title');
      return;
    }

    try {
      var request = http.MultipartRequest('POST', url);

      // -------------------------
      // 🔐 Correct Auth Headers
      // -------------------------
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      // ❌ DO NOT add Content-Type manually, MultipartRequest will set it.

      // -------------------------
      // 🗓 Format Date
      // -------------------------
      String weddingDateToSend = weddingDateCtrl.text.trim();
      if (weddingDateToSend.isNotEmpty) {
        weddingDateToSend = _tryFormatDate(weddingDateToSend) ?? weddingDateToSend;
      }

      // -------------------------
      // 🏨 Venues (multiple)
      // -------------------------
      final List<String> venueList = selectedVenues.map((v) => v.toString()).toList();

      // -------------------------
      // 📝 Add Fields
      // -------------------------
      request.fields.addAll({
        'title': titleCtrl.text.trim(),
        'slug': slugCtrl.text.trim(),
        'weddingDate': weddingDateToSend,
        'country': selectedCountry ?? "",
        'city': cityCtrl.text.trim(),
        'venues': jsonEncode(venueList),
        'brideName': brideNameCtrl.text.trim(),
        'brideBio': brideBioCtrl.text.trim(),
        'groomName': groomNameCtrl.text.trim(),
        'groomBio': groomBioCtrl.text.trim(),
        'story': storyCtrl.text.trim(),
        'events': jsonEncode(events),
        'vendors': jsonEncode(vendors),
        'themes': jsonEncode(weddingThemesCtrl.text.trim().isNotEmpty ? [weddingThemesCtrl.text.trim()] : []),
        'additionalCredits': jsonEncode(additionalCredits),
        'brideOutfit': brideOutfitCtrl.text.trim(),
        'groomOutfit': groomOutfitCtrl.text.trim(),
        'specialMoments': specialMomentsCtrl.text.trim(),
        'photographer': photographerCtrl.text.trim(),
        'makeup': makeupCtrl.text.trim(),
        'decor': decorCtrl.text.trim(),
        'status': 'pending',
        'featured': isFeatured ? 'true' : 'false',
      });

      print("📝 FIELDS SENT:");
      request.fields.forEach((k, v) => print("   ➤ $k: $v"));

      // Files
      if (_coverPhotos.isNotEmpty) {
        final file = _coverPhotos.first;
        request.files.add(await http.MultipartFile.fromPath('coverPhoto', file.path));
        print("📌 coverPhoto: ${file.path}");
      }

      for (var file in _highlightPhotos) {
        request.files.add(await http.MultipartFile.fromPath('highlightPhotos', file.path));
        print("✨ highlightPhotos: ${file.path}");
      }

      for (var file in _weddingPhotos) {
        request.files.add(await http.MultipartFile.fromPath('allPhotos', file.path));
        print("📷 allPhotos: ${file.path}");
      }

      // Send
      print("🚀 Sending request...");
      setState(() => isSubmitting = true);

      final streamedResponse = await request.send();
      final status = streamedResponse.statusCode;
      final respStr = await streamedResponse.stream.bytesToString();

      print("📡 STATUS: $status");
      print("📨 RESPONSE: $respStr");

      if (status == 200 || status == 201) {
        print("✅ Wedding story submitted successfully!");
        AppSnackbar.info(context, 'Wedding story submitted successfully!');
        return;
      } else if (status == 401) {
        print("❌ Unauthorized token!");
        AppSnackbar.info(context, 'Session expired. Please login again');
        return;
      } else {
        print("❌ Failed: $status");
        AppSnackbar.info(context, "Failed to submit ($status): $respStr");
      }
    } catch (e, st) {
      print("🔥 ERROR: $e\n$st");
      AppSnackbar.info(context, 'Error: $e');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  String? _tryFormatDate(String input) {
    final candidates = ["yyyy-MM-dd", "dd/MM/yyyy", "MM/dd/yyyy", "dd-MM-yyyy", "yyyy/MM/dd"];

    for (var fmt in candidates) {
      try {
        final parsed = DateFormat(fmt).parseStrict(input);
        return DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        // ignore
      }
    }
    return null;
  }

  void filterVenues(String query) {
    if (query.isEmpty) {
      setState(() => venueSuggestions = []);
      return;
    }

    setState(() {
      venueSuggestions = allVenues.where((v) => v.name.toLowerCase().startsWith(query.toLowerCase())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  Future<List<String>> fetchVendorTypes() async {
    final url = Uri.parse('https://happywedz.com/api/vendor-types/with-subcategories/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data.map((item) => item['name']));
    } else {
      throw Exception('Failed to load vendor types');
    }
  }

  Future<void> _selectDate(BuildContext ctx) async {
    final DateTime? picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Color(0xFFE91E63)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      eventDateCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  Future<void> fetchCountries() async {
    setState(() => isLoadingCountries = true);

    try {
      final response = await http.get(Uri.parse('https://countriesnow.space/api/v0.1/countries'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List countriesData = data['data'];

        countries = countriesData.map<String>((c) => c['country']).toList();

        setState(() {
          isLoadingCountries = false;
        });
      }
    } catch (e) {
      print("Country API Error: $e");
      setState(() => isLoadingCountries = false);
    }
  }

  Future<void> loadAllVenues() async {
    try {
      final url = Uri.parse("https://happywedz.com/api/vendor-services?vendorType=Venues");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List list = decoded["data"] ?? [];

        allVenues = list.map((v) => Venue.fromJson(v)).toList();
        setState(() {});
      }
    } catch (e) {
      print("Error loading all venues $e");
    }
  }

  Future<void> fetchCultures() async {
    setState(() => isLoadingCultures = true);

    try {
      final url = Uri.parse("https://happywedz.com/api/real-wedding-culture/public");
      final response = await http.get(url, headers: {"Accept": "application/json"});

      print("👉 Culture API Status: ${response.statusCode}");
      print("👉 Culture API Body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        final List<dynamic> list = decoded["cultures"] ?? [];

        setState(() {
          cultures = list.map((c) => c["name"].toString()).toList();
          isLoadingCultures = false;
        });
      } else {
        throw Exception("Invalid status");
      }
    } catch (e) {
      print("❌ Culture API error: $e");
      setState(() => isLoadingCultures = false);
    }
  }

  Future<void> _selectWeddingDate(BuildContext ctx) async {
    final DateTime? picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      weddingDateCtrl.text = "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  Future<void> searchVenues(String query) async {
    // If empty → clear
    if (query.isEmpty) {
      setState(() => venueSuggestions = []);
      return;
    }

    // 1️⃣ Local suggestions first (instant response)
    List<Venue> localFiltered = allVenues.where((v) => v.name.toLowerCase().startsWith(query.toLowerCase())).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() => venueSuggestions = localFiltered); // show instantly

    // 2️⃣ API suggestions (optional)
    try {
      final url = Uri.parse("https://happywedz.com/api/vendor-services?search=$query&vendorType=Venues");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final rawData = decoded["data"];

        List<Venue> apiList = [];

        if (rawData is List) {
          apiList = rawData.map((v) => Venue.fromJson(v)).toList();
        } else if (rawData is Map && rawData["data"] is List) {
          apiList = (rawData["data"] as List).map((v) => Venue.fromJson(v)).toList();
        }

        // Merge + remove duplicates
        List<Venue> combined = [...localFiltered, ...apiList];

        combined = {for (var v in combined) v.name.toLowerCase(): v}.values.toList();

        combined.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        setState(() => venueSuggestions = combined);
      }
    } catch (e) {
      print("Venue search error: $e");
    }
  }
}
