// share_wedding_story.dart
import 'dart:convert';
import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ShareWeddingStory extends StatefulWidget {
  const ShareWeddingStory({Key? key}) : super(key: key);

  @override
  State<ShareWeddingStory> createState() => _ShareWeddingStoryState();
}

class _ShareWeddingStoryState extends State<ShareWeddingStory> {
  int currentStep = 1;

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

  // Story
  final TextEditingController storyCtrl = TextEditingController();

  // Events & Vendors
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> vendors = [];

  // STEP 7 controllers (themes/outfits/special moments)
  final TextEditingController weddingThemesCtrl = TextEditingController();
  final TextEditingController brideOutfitCtrl = TextEditingController();
  final TextEditingController groomOutfitCtrl = TextEditingController();
  final TextEditingController specialMomentsCtrl = TextEditingController();

  // Credits
  final TextEditingController photographerCtrl = TextEditingController();
  final TextEditingController makeupCtrl = TextEditingController();
  final TextEditingController decorCtrl = TextEditingController();

  List<Map<String, dynamic>> additionalCredits = [];

  bool isFeatured = false;
  bool isSubmitting = false;

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

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Share Your Wedding Story",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(
              child: Text(
                "Inspire thousands of couples with your special day",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),

            // Steps bar
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final isActive = index + 1 == currentStep;
                  return GestureDetector(
                    onTap: () {
                      if (index + 1 <= currentStep + 1) {
                        setState(() => currentStep = index + 1);
                      }
                    },
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor:
                          isActive ? const Color(0xFFE91E63) : Colors.grey.shade300,
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? const Color(0xFFE91E63) : Colors.black54,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // render steps
            if (currentStep == 1) _buildStep1(),
            if (currentStep == 2) _buildStep2(),
            if (currentStep == 3) _buildStep3(),
            if (currentStep == 4) _buildStep4(),
            if (currentStep == 5) _buildStep5(),
            if (currentStep == 6) _buildStep6(),
            if (currentStep == 7) _buildStep7(),
            if (currentStep == 8) _buildStep8(),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 1)
                  OutlinedButton(
                    onPressed: () => setState(() => currentStep--),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black26),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Previous"),
                  )
                else
                  const SizedBox(width: 110),

                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Draft saved locally")));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("Save Draft"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                        if (currentStep < steps.length) {
                          setState(() => currentStep++);
                        } else {
                          // final submit
                          setState(() => isSubmitting = true);
                          await _submitWeddingStory(context);
                          setState(() => isSubmitting = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(currentStep < steps.length ? "Next" : "Submit for\n Approval", style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  // -------------------------
  // Submission (Multipart)
  // -------------------------
  Future<void> _submitWeddingStory(BuildContext context) async {
    print("🟢 Starting wedding story submission...");
    final url = Uri.parse('https://happywedz.com/api/realwedding');
    print("📍 API Endpoint: $url");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      print("❌ No token found - user must login");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    // Basic validation example (you can expand)
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter title')));
      return;
    }

    try {
      var request = http.MultipartRequest('POST', url);

      // Headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Format weddingDate to yyyy-MM-dd if possible
      String weddingDateToSend = weddingDateCtrl.text.trim();
      if (weddingDateToSend.isNotEmpty) {
        weddingDateToSend = _tryFormatDate(weddingDateToSend) ?? weddingDateToSend;
      }

      // Fields
      request.fields.addAll({
        'title': titleCtrl.text.trim(),
        'slug': slugCtrl.text.trim(),
        'weddingDate': weddingDateToSend,
        'country': countryCtrl.text.trim(),
        'city': cityCtrl.text.trim(),
        'venues': jsonEncode(venuesCtrl.text.trim().isNotEmpty ? [venuesCtrl.text.trim()] : []),
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

      print("📝 Fields added:");
      request.fields.forEach((k, v) => print("   ➜ $k: $v"));

      // Attach files - use exact backend names you provided:
      // coverPhoto (single), highlightPhotos (many), allPhotos (many)

      // coverPhoto
      if (_coverPhotos.isNotEmpty) {
        final file = _coverPhotos.first;
        print("📸 Attaching coverPhoto: ${file.path}");
        request.files.add(await http.MultipartFile.fromPath('coverPhoto', file.path, filename: basename(file.path)));
      }

      // highlightPhotos
      for (var i = 0; i < _highlightPhotos.length; i++) {
        final file = _highlightPhotos[i];
        print("✨ Attaching highlightPhotos #${i + 1}: ${file.path}");
        // sending with same field name multiple times (Multer should accept)
        request.files.add(await http.MultipartFile.fromPath('highlightPhotos', file.path, filename: basename(file.path)));
      }

      // allPhotos
      for (var i = 0; i < _weddingPhotos.length; i++) {
        final file = _weddingPhotos[i];
        print("💒 Attaching allPhotos #${i + 1}: ${file.path}");
        request.files.add(await http.MultipartFile.fromPath('allPhotos', file.path, filename: basename(file.path)));
      }

      print("🚀 Sending request...");
      setState(() => isSubmitting = true);
      final streamedResponse = await request.send();
      final status = streamedResponse.statusCode;
      final respStr = await streamedResponse.stream.bytesToString();

      print("📡 Response status: $status");
      print("📨 Response body: $respStr");

      if (status >= 200 && status < 300) {
        print("✅ Wedding story submitted successfully!");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wedding story submitted successfully!')));
        // optionally reset form / navigate
      } else {
        print("❌ Failed to submit: $status");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $status\n$respStr')));
      }
    } catch (e, st) {
      print("🔥 Error occurred: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error occurred: $e')));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // Try to parse common date formats and return yyyy-MM-dd; returns null if can't parse
  String? _tryFormatDate(String input) {
    final candidates = [
      "yyyy-MM-dd",
      "dd/MM/yyyy",
      "MM/dd/yyyy",
      "dd-MM-yyyy",
      "yyyy/MM/dd"
    ];

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

  Future<void> _pickDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE91E63), // pink header
              onPrimary: Colors.white, // text color on header
              onSurface: Colors.black, // body text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MM-yyyy').format(picked);
    }
  }


  // -------------------------
  // STEP UIs (kept minimal)
  // -------------------------
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📋 Basic Information",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 16),
        _buildTextField("Wedding Title", "e.g. Krishna and Radha Romantic Beach Wedding", controller: titleCtrl),
        const SizedBox(height: 12),
        _buildTextField("URL Slug", "e.g. emma-james-beach-wedding", controller: slugCtrl),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Wedding Date", "dd-mm-yyyy", controller: weddingDateCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField("Country", "India", controller: countryCtrl)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("City", "Enter your city (e.g. Mumbai, Delhi, New York)", controller: cityCtrl),
        const SizedBox(height: 12),
        _buildTextField("Venues", "Add a venue and press enter", controller: venuesCtrl),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Couple Information",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField("Bride's Name", "e.g. Emma Smith", controller: brideNameCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField("Groom's Name", "e.g. James Wilson", controller: groomNameCtrl)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Bride's Bio", "Tell us about the bride...", controller: brideBioCtrl, maxLines: 4),
        const SizedBox(height: 12),
        _buildTextField("Groom's Bio", "Tell us about the groom...", controller: groomBioCtrl, maxLines: 4),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your wedding story",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 12),
        _buildTextField("Your Story", "Share how your love story unfolded...", controller: storyCtrl, maxLines: 6),
      ],
    );
  }

  Widget _buildStep4() {
    final TextEditingController eventNameCtrl = TextEditingController();
    final TextEditingController eventDateCtrl = TextEditingController();
    final TextEditingController eventVenueCtrl = TextEditingController();
    final TextEditingController eventDescCtrl = TextEditingController();

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
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFFE91E63),
                ),
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

    return Builder(
      builder: (outerContext) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Adding Events",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildTextFieldWithController(
                  "Event name",
                  "e.g., Mehandi",
                  controller: eventNameCtrl,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(outerContext),
                  child: AbsorbPointer(
                    child: _buildTextFieldWithController(
                      "Date",
                      "dd-mm-yyyy",
                      controller: eventDateCtrl,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          _buildTextFieldWithController(
            "Venues",
            "Add a venue and press enter",
            controller: eventVenueCtrl,
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithController(
            "Description (optional)",
            "Brief details about this event",
            controller: eventDescCtrl,
          ),
          const SizedBox(height: 12),

          StatefulBuilder(
            builder: (buttonContext, setStateButton) {
              bool isHovered = false;
              bool isPressed = false;

              return MouseRegion(
                onEnter: (_) => setStateButton(() => isHovered = true),
                onExit: (_) => setStateButton(() => isHovered = false),
                child: GestureDetector(
                  onTapDown: (_) => setStateButton(() => isPressed = true),
                  onTapUp: (_) {
                    setStateButton(() => isPressed = false);
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
                      ScaffoldMessenger.of(outerContext).showSnackBar(
                        const SnackBar(content: Text('Please enter event name')),
                      );
                    }
                  },
                  onTapCancel: () => setStateButton(() => isPressed = false),
                  child: DottedBorder(
                    color: const Color(0xFFE91E63),
                    strokeWidth: 1.5,
                    dashPattern: const [6, 4],
                    borderType: BorderType.RRect,
                    radius: const Radius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: (isHovered || isPressed)
                            ? const Color(0xFFE91E63)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              color: (isHovered || isPressed)
                                  ? Colors.white
                                  : const Color(0xFFE91E63)),
                          const SizedBox(width: 8),
                          Text(
                            "Add Event",
                            style: TextStyle(
                              color: (isHovered || isPressed)
                                  ? Colors.white
                                  : const Color(0xFFE91E63),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text("Added Events:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Column(
              children: List.generate(events.length, (i) {
                final ev = events[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(ev['name'] ?? ''),
                  subtitle: Text("${ev['date']} • ${ev['venue']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        events.removeAt(i);
                      });
                    },
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }




  Widget _buildStep5() {
    final TextEditingController vendorTypeCtrl = TextEditingController();
    final TextEditingController vendorNameCtrl = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vendors",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextFieldWithController("Vendor Type", "Select Type", controller: vendorTypeCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _buildTextFieldWithController("Vendor Name", "e.g. Dia", controller: vendorNameCtrl)),
          ],
        ),
        const SizedBox(height: 12),
        StatefulBuilder(
          builder: (context, setStateButton) {
            bool isHovered = false;
            bool isPressed = false;

            return MouseRegion(
              onEnter: (_) => setStateButton(() => isHovered = true),
              onExit: (_) => setStateButton(() => isHovered = false),
              child: GestureDetector(
                onTapDown: (_) => setStateButton(() => isPressed = true),
                onTapUp: (_) {
                  setStateButton(() => isPressed = false);
                  if (vendorTypeCtrl.text.trim().isNotEmpty && vendorNameCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      vendors.add({
                        'type': vendorTypeCtrl.text.trim(),
                        'name': vendorNameCtrl.text.trim(),
                      });
                      vendorTypeCtrl.clear();
                      vendorNameCtrl.clear();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter vendor type and name')));
                  }
                },
                onTapCancel: () => setStateButton(() => isPressed = false),
                child: DottedBorder(
                  color: const Color(0xFFE91E63),
                  strokeWidth: 1.5,
                  dashPattern: const [6, 4],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: (isHovered || isPressed) ? const Color(0xFFE91E63) : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: (isHovered || isPressed) ? Colors.white : const Color(0xFFE91E63)),
                        const SizedBox(width: 8),
                        Text(
                          "Add Vendor",
                          style: TextStyle(
                            color: (isHovered || isPressed) ? Colors.white : const Color(0xFFE91E63),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (vendors.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text("Added Vendors:", style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Column(
            children: List.generate(vendors.length, (i) {
              final v = vendors[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(v['name'] ?? ''),
                subtitle: Text(v['type'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      vendors.removeAt(i);
                    });
                  },
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📷 Gallery",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 16),
        // Cover
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
        const SizedBox(height: 24),
        // Highlight
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
        const SizedBox(height: 24),
        // All wedding photos
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
      ],
    );
  }

  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Highlights",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 12),
        _buildTextField("Wedding Themes", "Add themes and press enter", controller: weddingThemesCtrl),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Bride's Outfit", "Describe the bride's outfit", controller: brideOutfitCtrl)),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField("Groom's Outfit", "e.g. James Wilson", controller: groomOutfitCtrl)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField("Special Moments", "Share the most memorable moments from your wedding...", controller: specialMomentsCtrl, maxLines: 4),
      ],
    );
  }

  Widget _buildStep8() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "👤 Credits & Publish",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
        ),
        const SizedBox(height: 16),
        _buildTextField("Photographer", "Photographer's name or business", controller: photographerCtrl),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Makeup Artist", "Makeup artist's name or business", controller: makeupCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField("Decor & Floral", "Decorator's name or business", controller: decorCtrl)),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        // Featured Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text("Featured Wedding", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              SizedBox(height: 4),
            ]),
            Switch(
              activeColor: Color(0xFFE91E63),
              value: isFeatured,
              onChanged: (val) {
                setState(() => isFeatured = val);
              },
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // -------------------------
  // Helpers / Widgets
  // -------------------------
  Widget _buildGallerySection({
    required String title,
    required List<File> imageList,
    required VoidCallback onPickImage,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onPickImage,
        child: DottedBorder(
          color: const Color(0xFFE91E63),
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(12),
          child: Container(
            width: double.infinity,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
              Icon(Icons.cloud_upload_outlined, size: 28, color: Color(0xFFE91E63)),
              SizedBox(height: 8),
              Text("Tap to browse photos", style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
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

  Widget _buildTextField(String label, String hint, {int maxLines = 1, TextEditingController? controller}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black26)),
        ),
      ),
      const SizedBox(height: 12),
    ]);
  }

  // wrapper (used in your step code)
  Widget _buildTextFieldWithController(String label, String hint, {int maxLines = 1, required TextEditingController controller}) {
    return _buildTextField(label, hint, maxLines: maxLines, controller: controller);
  }
}
