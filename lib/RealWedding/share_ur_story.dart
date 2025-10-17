

import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ShareWeddingStory extends StatefulWidget {
  const ShareWeddingStory({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                "Inspire thousands of couples with your special day",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable Steps Bar
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final isActive = index + 1 == currentStep;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor:
                        isActive ? const Color(0xFFE91E63) : Colors.grey
                            .shade300,
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
                          color: isActive ? const Color(0xFFE91E63) : Colors
                              .black54,
                          fontWeight: isActive ? FontWeight.bold : FontWeight
                              .normal,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Main Step Content
            if (currentStep == 1) _buildStep1(),
            if (currentStep == 2) _buildStep2(),
            if (currentStep == 3) _buildStep3(),
            if (currentStep == 4) _buildStep4(),
            if (currentStep == 5) _buildStep5(),
            if (currentStep == 6) _buildStep6(),
            if (currentStep == 7) _buildStep7(),
            if (currentStep == 8) _buildStep8(),

            const SizedBox(height: 30),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 1)
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        currentStep--;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black26),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text("Previous"),
                  )
                else
                  const SizedBox(width: 110), // placeholder alignment

                Row(
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.black26),
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text("Save Draft"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (currentStep < steps.length) {
                          setState(() {
                            currentStep++;
                          });
                        } else {
                          // Submit for Approval logic here
                          print("Submit for Approval clicked");
                          // You could show a dialog/snackbar here
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        currentStep < steps.length ? "Next" : "Submit for\n Approval",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1 UI
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📋 Basic Information",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
            "Wedding Title", "e.g. Krishna and Radha Romantic Beach Wedding"),
        const SizedBox(height: 12),
        _buildTextField("URL Slug", "e.g. emma-james-beach-wedding"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField("Wedding Date", "dd-mm-yyyy")),
            const SizedBox(width: 10),
            Expanded(child: _buildTextField("Country", "India")),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
            "City", "Enter your city (e.g. Mumbai, Delhi, New York)"),
        const SizedBox(height: 12),
        _buildTextField("Venues", "Add a venue and press enter"),
      ],
    );
  }

  // STEP 2 UI
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          " Couple Information",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField("Bride's Name", "e.g. Emma Smith")),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField("Groom's Name", "e.g. James Wilson")),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
            "Bride's Bio", "Tell us about the bride...", maxLines: 4),
        const SizedBox(height: 12),
        _buildTextField(
            "Groom's Bio", "Tell us about the groom...", maxLines: 4),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          " Your wedding story",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),


        const SizedBox(height: 12),
        _buildTextField(
            "Bride's Bio", "Tell us about the bride...", maxLines: 4),
        const SizedBox(height: 12),

      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Adding Events",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField("Event name", "e.g, Mehandi")),
            Expanded(child: _buildTextField("Date", "dd-mm-yyyy")),
            const SizedBox(width: 10),

          ],
        ),

        const SizedBox(height: 12),
        _buildTextField("Venues", "Add a venue and press enter"),

        const SizedBox(height: 12),
        _buildTextField("Desccription(optional)", "Brief details about this event"),
        const SizedBox(height: 12),
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
                  // Your add event logic
                  print("Add Event Clicked");
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
                          "Add Event",
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




      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vendors",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField("Venor Type", "Select Type")),
            Expanded(child: _buildTextField("Vendor Name", "e.g dia")),
            const SizedBox(width: 10),

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
                  // Your add event logic
                  print("Add Event Clicked");
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




      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "📷 Gallery",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),

        // --- Cover Photo ---
        _buildGallerySection(
          title: "Cover Photo",
          imageList: _coverPhotos,
          onPickImage: () async {
            final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              setState(() => _coverPhotos.add(File(pickedFile.path)));
            }
          },
        ),

        const SizedBox(height: 24),

        // --- Highlight Photos ---
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

        // --- All Wedding Photos ---
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
          "HighLights",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        _buildTextField(
            "Wedding Themes", "Add themes and press enter"),
        const SizedBox(height: 12),

        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField("Bride's Outfit", "Describe the bride's outfit")),
            const SizedBox(width: 10),
            Expanded(
                child: _buildTextField("Groom's Outfit", "e.g. James Wilson")),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
            "Special Moments", "Share the most memorable moments from your wedding...", maxLines: 4),
      ],
    );
  }

  Widget _buildStep8() {
    bool isFeatured = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "👤 Credits & Publish",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),

        _buildTextField("Photographer", "Photographer's name or business"),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildTextField(
                  "Makeup Artist", "Makeup artist's name or business"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                  "Decor & Floral", "Decorator's name or business"),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),

        // Featured Toggle
        StatefulBuilder(
          builder: (context, setStateToggle) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Featured Wedding",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Feature this wedding on the homepage and category pages",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Switch(
                  activeColor: Color(0xFFE91E63),
                  value: isFeatured,
                  onChanged: (val) {
                    setStateToggle(() => isFeatured = val);
                  },
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 30),

        // Removed buttons from here!
      ],
    );
  }




  Widget _buildGallerySection({
    required String title,
    required List<File> imageList,
    required VoidCallback onPickImage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
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
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.cloud_upload_outlined,
                      size: 40, color: Color(0xFFE91E63)),
                  SizedBox(height: 12),
                  Text(
                    "Drag & drop your photo here or tap to browse",
                    style: TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Recommended size: 1200 x 800 pixels",
                    style: TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (imageList.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              imageList.length,
                  (index) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      imageList[index],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => imageList.removeAt(index));
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.close,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }



  // Common Field Builder
  Widget _buildTextField(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black45),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black26),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }

}

