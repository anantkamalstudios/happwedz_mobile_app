// visual_design_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// ---------- CONFIG ----------
const String baseUrl = 'https://www.happywedz.com/ai/api';
/// ----------------------------

class VisualDesignScreen extends StatefulWidget {
  final File? userImage; // optional local image file
  const VisualDesignScreen({Key? key, this.userImage}) : super(key: key);

  @override
  State<VisualDesignScreen> createState() => _VisualDesignScreenState();
}

class _VisualDesignScreenState extends State<VisualDesignScreen> {
  int _currentTab = 0;

  // Shared state across tab widgets
  int selectedCategory = 0; // 0: Foundation, 1: Lipstick, ...
  int? selectedBrandIndex;
  int? selectedShadeIndex;

  // store final selections as map: categoryIndex -> (brandIndex, shadeIndex, intensity)
  final Map<int, Map<String, dynamic>> selections = {};

  ImageProvider get _placeholderImage => const NetworkImage(
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1200&q=80');

  // --- Networking / image handling ---
  String? _uploadedImageId; // id returned when uploading original image
  bool _isApplying = false;
  Uint8List? _processedImageBytes; // result from apply-makeup
  bool _isUploading = false;

  // Data fetched from API (if available)
  List<CategoryModel> apiCategories = [];
  List<List<Brand>> apiBrandsByCategory = []; // brand lists per category (fetched)
  // Shades are stored inside Brand.shades list

  // Image picker for optional local upload from VisualDesignScreen
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // optionally upload widget.userImage (if provided)
    if (widget.userImage != null) {
      // upload and fetch processed image only when apply is called; but we will upload original to get an image_id now
      _uploadOriginalImage(widget.userImage!);
    }
    // Optionally prefetch categories from API
    _fetchCategories();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1️⃣ AppBar
          _buildTopBar(),

          // 2️⃣ Tab content
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                // Shades tab: photo + product + brand + shades + intensity
                Column(
                  children: [
                    // 1️⃣ Photo area
                    Container(
                      height: 525,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.userImage != null
                                ? Image.file(widget.userImage!, fit: BoxFit.cover)
                                : Image(image: _placeholderImage, fit: BoxFit.cover),
                          ),

                          // 2️⃣ Intensity slider only if shade is selected
                          if (selectedShadeIndex != null)
                            Positioned(
                              top: 50,
                              bottom: 50,
                              right: 8,
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Slider(
                                  value: selections[selectedCategory]?['intensity']?.toDouble() ?? 1.0,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    setState(() {
                                      selections[selectedCategory]?['intensity'] = val;
                                    });
                                  },
                                  activeColor: Colors.pink,
                                  inactiveColor: Colors.grey[300],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // 3️⃣ Products + Brands + Shades
                    Expanded(
                      child: ShadesScreen(
                        selectedCategory: selectedCategory,
                        selectedBrandIndex: selectedBrandIndex,
                        selectedShadeIndex: selectedShadeIndex,
                        onCategorySelected: (catIndex) async {
                          setState(() {
                            selectedCategory = catIndex;
                            selectedBrandIndex = null;
                            selectedShadeIndex = null;
                          });
                          // Try to fetch brands for this category from API (non-blocking)
                          await _fetchBrandsForCategory(catIndex);
                        },
                        onBrandSelected: (brandIndex) {
                          setState(() {
                            selectedBrandIndex = brandIndex;
                            selectedShadeIndex = null;
                          });
                        },
                        onShadeSelected: (shadeIndex) {
                          setState(() {
                            selectedShadeIndex = shadeIndex;
                            selections[selectedCategory] = {
                              'brand': selectedBrandIndex ?? 0,
                              'shade': shadeIndex,
                              'intensity': 1.0,
                            };
                          });
                        },

                        // pass API-fed brands if available
                        brandsByCategory: apiBrandsByCategory,
                        categories: apiCategories.isNotEmpty ? apiCategories.map((c) => c.name).toList() : null,
                        fetchBrandsForCategory: _fetchBrandsForCategory,
                        fetchShadesForBrand: _fetchShadesForBrand,
                      ),
                    ),
                  ],
                ),

                // Compare tab: only CompareScreen (no photo above)
                CompareScreen(
                  image: _processedImageBytes != null
                      ? MemoryImage(_processedImageBytes!)
                      : widget.userImage != null
                      ? Image.file(widget.userImage!, fit: BoxFit.cover).image
                      : _placeholderImage,
                ),

                // Complete Looks tab: just content (we'll trigger apply-makeup on entering tab)
                CompleteLooksScreen(
                  userImageProvider: _processedImageBytes != null
                      ? MemoryImage(_processedImageBytes!)
                      : widget.userImage != null
                      ? Image.file(widget.userImage!).image
                      : _placeholderImage,
                  selections: selections,
                ),
              ],
            ),
          ),

          // 3️⃣ Bottom tab bar
          _buildBottomTabs(),
        ],
      ),
      // floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEC1E79), Color(0xFFEF6AA9)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Center(
                child: Text(
                  'Visual Design',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.location_on, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _bottomTabButton('Shades', 0),
            _bottomTabButton('Compare', 1),
            _bottomTabButton('Complete Looks', 2),
          ],
        ),
      ),
    );
  }

  Widget _bottomTabButton(String label, int index) {
    final isSelected = index == _currentTab;
    return Expanded(
      child: InkWell(
        onTap: () async {
          // if going to Complete Looks, apply makeup automatically
          if (index == 2) {
            await _maybeApplyMakeupForSelections();
          }
          setState(() => _currentTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: isSelected ? Colors.pink : Colors.transparent, width: 3),
            ),
            color: isSelected ? const Color(0xFFFFF1F6) : Colors.white,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.pink : Colors.black54,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    // allow picking/uploading image from this screen (keeps UI unchanged)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'pick_image',
          backgroundColor: Colors.pink,
          onPressed: () async {
            final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
            if (picked != null) {
              setState(() {
                // update displayed image
                // Note: this only updates the local displayed image; the upload will happen automatically when needed
              });
              // Upload and store id
              await _uploadOriginalImage(File(picked.path));
            }
          },
          child: const Icon(Icons.photo_library),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'camera',
          backgroundColor: Colors.pink,
          onPressed: () async {
            final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
            if (picked != null) {
              setState(() {});
              await _uploadOriginalImage(File(picked.path));
            }
          },
          child: const Icon(Icons.camera_alt),
        ),
      ],
    );
  }

  // ---------------- Networking helper functions ----------------

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        apiCategories = jsonList.map((e) => CategoryModel.fromJson(e)).toList();
      } else {
        // ignore; keep defaults inside ShadesScreen
      }
    } catch (e) {
      // ignore
    }
  }

  /// fetch brands for a given category index (we map index -> category id if available)
  Future<void> _fetchBrandsForCategory(int categoryIndex) async {
    try {
      if (apiCategories.isEmpty) {
        // if categories not fetched, try to fetch once
        await _fetchCategories();
      }
      if (apiCategories.isNotEmpty && categoryIndex < apiCategories.length) {
        final catId = apiCategories[categoryIndex].id;
        final response = await http.get(Uri.parse('$baseUrl/brands?category_id=$catId'));
        if (response.statusCode == 200) {
          final jsonList = jsonDecode(response.body) as List;
          final brands = jsonList.map((b) {
            // brand must include shades? if not, we'll fetch shades separately
            return Brand(name: b['name'] ?? 'Unknown', id: b['id'] ?? 0, shades: (b['shades'] as List?)
                ?.map<Color>((s) => _hexToColor(s['hex'] ?? '#FFFFFF'))
                .toList() ??
                []);
          }).toList();

          // ensure apiBrandsByCategory has proper length
          if (apiBrandsByCategory.length <= categoryIndex) {
            // extend list
            while (apiBrandsByCategory.length <= categoryIndex) apiBrandsByCategory.add([]);
          }
          apiBrandsByCategory[categoryIndex] = brands;
          setState(() {});
        }
      }
    } catch (e) {
      // ignore network errors for now
    }
  }

  /// fetch shades for a brand (if the brand has an id)
  Future<List<Color>> _fetchShadesForBrand(int brandId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/shades?brand_id=$brandId'));
      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final colors = jsonList.map<Color>((s) {
          final hex = s['hex'] ?? s['color'] ?? '#FFFFFF';
          return _hexToColor(hex);
        }).toList();
        return colors;
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  /// upload original image to /images to receive image id (like your other code)
  Future<void> _uploadOriginalImage(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final uri = Uri.parse('$baseUrl/images');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['image_type'] = 'ORIGINAL';

      final streamedResp = await request.send();
      final respStr = await streamedResp.stream.bytesToString();
      if (streamedResp.statusCode == 200 || streamedResp.statusCode == 201) {
        final json = jsonDecode(respStr);
        // some APIs return 'id' or 'image_id' or 'processed_image_id' - check which
        String? idStr;
        if (json['id'] != null) idStr = json['id'].toString();
        if (json['image_id'] != null) idStr = json['image_id'].toString();
        if (json['uploaded_image_id'] != null) idStr = json['uploaded_image_id'].toString();
        if (idStr == null && json['processed_image_id'] != null) idStr = json['processed_image_id'].toString();

        if (idStr != null) {
          _uploadedImageId = idStr;
          _showSnackBar('Image uploaded (id: $_uploadedImageId)', Colors.green);
        } else {
          _showSnackBar('Upload succeeded but id not found', Colors.orange);
        }
      } else {
        _showSnackBar('Failed to upload image: ${streamedResp.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e', Colors.red);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// When user navigates to Complete Looks, we automatically call apply-makeup to get processed image
  Future<void> _maybeApplyMakeupForSelections() async {
    if (_isApplying) return;
    if (_uploadedImageId == null) {
      // can't apply without image id: try uploading widget.userImage if present
      if (widget.userImage != null) {
        await _uploadOriginalImage(widget.userImage!);
      } else {
        _showSnackBar('Please upload an image first (or provide widget.userImage with an image id).', Colors.orange);
        return;
      }
    }
    if (_uploadedImageId == null) {
      _showSnackBar('No uploaded image id available to apply makeup', Colors.red);
      return;
    }

    // Build product_ids from selections (we map brand->product id if available; fallback: brand index)
    final productIds = <int>[];
    selections.forEach((catIndex, map) {
      final brand = map['brand'];
      if (brand is int) {
        // Try to find brand id (if apiBrandsByCategory available)
        int resolvedId = 0;
        if (apiBrandsByCategory.length > catIndex && apiBrandsByCategory[catIndex].isNotEmpty) {
          final b = apiBrandsByCategory[catIndex][brand];
          if (b != null && b.id != 0) resolvedId = b.id;
        }
        if (resolvedId == 0) {
          // fallback: use brand index + 1 as dummy
          resolvedId = brand + 1;
        }
        productIds.add(resolvedId);
      }
    });

    if (productIds.isEmpty) {
      // fallback single product id if none selected
      productIds.add(1);
    }

    // Build request payload similar to your sample JSON
    final Map<String, dynamic> requestData = {
      "image_id": int.tryParse(_uploadedImageId!) ?? 0,
      "product_ids": productIds,
      // Hardcode makeup params per selection entries (or use single global intensity stored in selections)
    };

    // Optionally attach params per category if present (we'll attach some generic defaults)
    // If you stored intensities per selection, include them. Here we include default values
    requestData.addAll({
      "lipstick_intensity": selections[1]?['intensity'] ?? 0.8,
      "lipstick_color": selections[1]?['hex'] ?? '#B22222',
      "blush_intensity": selections[2]?['intensity'] ?? 0.2,
      "blush_radius": selections[2]?['radius'] ?? 60,
      "blush_color": selections[2]?['hex'] ?? '#F08080',
      "eyeshadow_intensity": selections[3]?['intensity'] ?? 0.4,
      "eyeshadow_thickness": selections[3]?['thickness'] ?? 25,
      "eyeshadow_color": selections[3]?['hex'] ?? '#9370DB',
      "lens_intensity": 0.2,
      "lens_radius_scale": 1.3,
      "lens_color": "#4B9CD3",
      "foundation_intensity": 0.6,
      "foundation_color": "#F5D6C6",
      "kajal_intensity": 1.0,
      "kajal_color": "#000000",
      "concealer_intensity": 0.9,
      "concealer_color": "#FFDAB9",
      "contour_intensity": 0.3,
      "contour_color": "#8B4513",
      "bindi_size": 6,
      "bindi_color": "#FF0000",
    });

    // If selections include explicit hex colors or intensities, prefer them
    // For example if selections store a 'hex' for the chosen shade:
    selections.forEach((catIndex, map) {
      final brandIndex = map['brand'];
      final shadeIndex = map['shade'];
      final intensity = map['intensity'];
      Color? shadeColor;
      if (apiBrandsByCategory.length > catIndex && apiBrandsByCategory[catIndex].isNotEmpty) {
        final brands = apiBrandsByCategory[catIndex];
        if (brandIndex != null && brandIndex < brands.length) {
          final brand = brands[brandIndex];
          if (brand.shades.isNotEmpty && shadeIndex != null && shadeIndex < brand.shades.length) {
            shadeColor = brand.shades[shadeIndex];
          }
        }
      }
      if (shadeColor != null) {
        final hex = _colorToHex(shadeColor);
        // map categories (approx): 0 Foundation, 1 Lipstick, 2 Blush, 3 Eyeshadow ...
        final catName = apiCategories.isNotEmpty && catIndex < apiCategories.length ? apiCategories[catIndex].name.toLowerCase() : 'cat$catIndex';
        if (catName.contains('lip') || catName.contains('lipstick')) {
          requestData["lipstick_color"] = hex;
          if (intensity != null) requestData["lipstick_intensity"] = intensity;
        } else if (catName.contains('blush')) {
          requestData["blush_color"] = hex;
          if (intensity != null) requestData["blush_intensity"] = intensity;
        } else if (catName.contains('eye') || catName.contains('eyeshadow')) {
          requestData["eyeshadow_color"] = hex;
          if (intensity != null) requestData["eyeshadow_intensity"] = intensity;
        } else if (catName.contains('foundation')) {
          requestData["foundation_color"] = hex;
          if (intensity != null) requestData["foundation_intensity"] = intensity;
        } else {
          // generic mapping based on index (if categor names not available)
          if (catIndex == 1) { // lipstick
            requestData["lipstick_color"] = hex;
            if (intensity != null) requestData["lipstick_intensity"] = intensity;
          } else if (catIndex == 2) {
            requestData["blush_color"] = hex;
            if (intensity != null) requestData["blush_intensity"] = intensity;
          } else if (catIndex == 3) {
            requestData["eyeshadow_color"] = hex;
            if (intensity != null) requestData["eyeshadow_intensity"] = intensity;
          } else if (catIndex == 0) {
            requestData["foundation_color"] = hex;
            if (intensity != null) requestData["foundation_intensity"] = intensity;
          }
        }
      }
    });

    // Post to /images/apply-makeup
    setState(() => _isApplying = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/images/apply-makeup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final processedId = jsonResponse['processed_image_id'] ?? jsonResponse['id'] ?? jsonResponse['image_id'];

        if (processedId != null) {
          final imageUrl = '$baseUrl/images/$processedId';
          final imageResp = await http.get(Uri.parse(imageUrl));
          if (imageResp.statusCode == 200) {
            setState(() {
              _processedImageBytes = imageResp.bodyBytes;
            });
            _showSnackBar('Processed image loaded', Colors.green);
          } else {
            _showSnackBar('Failed to fetch processed image: ${imageResp.statusCode}', Colors.red);
          }
        } else if (jsonResponse['url'] != null) {
          final imageResp = await http.get(Uri.parse(jsonResponse['url']));
          if (imageResp.statusCode == 200) {
            setState(() {
              _processedImageBytes = imageResp.bodyBytes;
            });
            _showSnackBar('Processed image loaded', Colors.green);
          } else {
            _showSnackBar('Failed to fetch processed image from URL', Colors.red);
          }
        } else {
          _showSnackBar('No processed image id/url returned', Colors.red);
        }
      } else {
        // parse error body
        String err = 'Apply makeup failed: ${response.statusCode}';
        try {
          final errJson = jsonDecode(response.body);
          err += '\n${errJson.toString()}';
        } catch (_) {
          err += '\n${response.body}';
        }
        _showSnackBar(err, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error applying makeup: $e', Colors.red);
    } finally {
      setState(() => _isApplying = false);
    }
  }

  // ---------------- Utilities ----------------
  Color _hexToColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final val = int.tryParse(h, radix: 16) ?? 0xFFFFFFFF;
    return Color(val);
  }

  String _colorToHex(Color color) {
    String hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 5),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// ---------------------------
/// Data models & child widgets
/// ---------------------------

class CategoryModel {
  final int id;
  final String name;

  CategoryModel({required this.id, required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(id: json['id'] ?? 0, name: json['name'] ?? json['detailed_category'] ?? 'Unknown');
  }
}

class Brand {
  final String name;
  final int id;
  final List<Color> shades;

  Brand({required this.name, this.id = 0, List<Color>? shades}) : shades = shades ?? [];
}

/// ShadesScreen (modified to accept API-driven brands list and fetch callbacks)
enum BarStage { categories, brands, shades }

class ShadesScreen extends StatefulWidget {
  final int selectedCategory; // 0..n
  final void Function(int) onCategorySelected;
  final void Function(int) onBrandSelected;
  final void Function(int) onShadeSelected;
  final int? selectedBrandIndex;
  final int? selectedShadeIndex;

  // optional API-driven inputs (if provided these will replace the internal mock)
  final List<List<Brand>>? brandsByCategory;
  final List<String>? categories;
  final Future<void> Function(int)? fetchBrandsForCategory;
  final Future<List<Color>> Function(int)? fetchShadesForBrand;

  const ShadesScreen({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onBrandSelected,
    required this.onShadeSelected,
    this.selectedBrandIndex,
    this.selectedShadeIndex,
    this.brandsByCategory,
    this.categories,
    this.fetchBrandsForCategory,
    this.fetchShadesForBrand,
  }) : super(key: key);

  @override
  State<ShadesScreen> createState() => _ShadesScreenState();
}

class _ShadesScreenState extends State<ShadesScreen> {
  BarStage _stage = BarStage.categories;
  int _categoryIndex = 0;
  int _brandIndex = 0;
  int _shadeIndex = 0;

  // Local categories (fallback to mock)
  List<String> categoriesLocal = ['Foundation', 'Lipstick', 'Blush', 'Eyeshadow'];

  // Mock brands and shades per category as fallback
  late List<List<Brand>> brandsByCategoryLocal;

  @override
  void initState() {
    super.initState();
    _categoryIndex = widget.selectedCategory;

    brandsByCategoryLocal = [
      // Foundation
      [
        Brand(name: "L'Oreal Paris", shades: [Color(0xFFDDB79B), Color(0xFFC89C74)], id: 1),
        Brand(name: "Maybelline Fit Me", shades: [Color(0xFFD7A883), Color(0xFFC4906A)], id: 2),
        Brand(name: "NARS Natural", shades: [Color(0xFFE0BFA0), Color(0xFFD1A383)], id: 3),
      ],
      // Lipstick
      [
        Brand(name: "MAC Retro", shades: [Color(0xFFD32F2F), Color(0xFFB71C1C)], id: 4),
        Brand(name: "Maybelline SuperStay", shades: [Color(0xFFD05B77), Color(0xFFC13F5A)], id: 5),
      ],
      // Blush
      [
        Brand(name: "NARS Orgasm", shades: [Color(0xFFF8BBD0), Color(0xFFF06292)], id: 6),
      ],
      // Eyeshadow
      [
        Brand(name: "Urban Decay", shades: [Color(0xFF8D6E63), Color(0xFF5D4037)], id: 7),
      ],
    ];

    _brandIndex = widget.selectedBrandIndex ?? 0;
    _shadeIndex = widget.selectedShadeIndex ?? 0;
    _stage = BarStage.categories;
  }

  List<String> get effectiveCategories => widget.categories ?? categoriesLocal;
  List<List<Brand>> get effectiveBrandsByCategory => widget.brandsByCategory ?? brandsByCategoryLocal;

  void _goToBrands(int categoryIdx) async {
    setState(() {
      _categoryIndex = categoryIdx;
      _stage = BarStage.brands;
      _brandIndex = 0;
      _shadeIndex = 0;
      widget.onCategorySelected(categoryIdx);
    });

    // If fetch callback provided, use it to refresh brand list for the category (non-blocking)
    if (widget.fetchBrandsForCategory != null) {
      await widget.fetchBrandsForCategory!(categoryIdx);
      setState(() {}); // pick up any changes passed by parent
    }
  }

  void _goToShades(int brandIdx) async {
    setState(() {
      _brandIndex = brandIdx;
      _stage = BarStage.shades;
      _shadeIndex = 0;
      widget.onBrandSelected(brandIdx);
    });

    // If fetch shades callback provided, fetch shades for brand id (non-blocking)
    if (widget.fetchShadesForBrand != null) {
      final brand = _safeGetBrand(_categoryIndex, _brandIndex);
      if (brand != null && brand.id != 0) {
        final colors = await widget.fetchShadesForBrand!(brand.id);
        if (colors.isNotEmpty) {
          // if parent holds same reference array, update brand shades
          setState(() {
            brand.shades.clear();
            brand.shades.addAll(colors);
          });
        }
      }
    }
  }

  void _selectShade(int shadeIdx) {
    setState(() {
      _shadeIndex = shadeIdx;
      widget.onShadeSelected(shadeIdx);
    });
  }

  Brand? _safeGetBrand(int catIdx, int brandIdx) {
    final list = effectiveBrandsByCategory;
    if (catIdx < list.length) {
      final brands = list[catIdx];
      if (brandIdx < brands.length) return brands[brandIdx];
    }
    return null;
  }

  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final selected = i == _categoryIndex && _stage == BarStage.categories;
          final label = i < effectiveCategories.length ? effectiveCategories[i] : 'Category $i';
          return GestureDetector(
            onTap: () => _goToBrands(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 130,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFDE8EF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? Colors.pink : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(i == 0 ? Icons.blur_on : i == 1 ? Icons.brightness_4 : i == 2 ? Icons.circle : Icons.remove_red_eye,
                      size: 36, color: selected ? Colors.pink : Colors.grey[700]),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(color: selected ? Colors.pink : Colors.black87)),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: effectiveCategories.length,
      ),
    );
  }

  Widget _buildBrandsBar() {
    final brands = (effectiveBrandsByCategory.length > _categoryIndex) ? effectiveBrandsByCategory[_categoryIndex] : <Brand>[];
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() => _stage = BarStage.categories);
              }),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final isSel = i == _brandIndex && _stage == BarStage.brands;
                final brand = i < brands.length ? brands[i] : Brand(name: 'Brand $i');
                return GestureDetector(
                  onTap: () => _goToShades(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 160,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFFFF1F6) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? Colors.pink : Colors.transparent, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(brand.name, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.normal)),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: brands.length,
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildShadesBar() {
    final brands = (effectiveBrandsByCategory.length > _categoryIndex) ? effectiveBrandsByCategory[_categoryIndex] : <Brand>[];
    final selectedBrand = brands.isNotEmpty && _brandIndex < brands.length ? brands[_brandIndex] : Brand(name: 'Brand', shades: []);
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _stage = BarStage.brands);
            },
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: selectedBrand.shades.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, i) {
                final isSel = i == _shadeIndex && _stage == BarStage.shades;
                return GestureDetector(
                  onTap: () => _selectShade(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSel ? 72 : 56,
                        height: isSel ? 72 : 56,
                        decoration: BoxDecoration(
                          color: selectedBrand.shades[i],
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? Colors.pink : Colors.white, width: isSel ? 4 : 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (isSel)
                        Container(
                          width: 44,
                          height: 6,
                          decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(3)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (_stage) {
      case BarStage.categories:
        child = _buildCategoriesBar();
        break;
      case BarStage.brands:
        child = _buildBrandsBar();
        break;
      case BarStage.shades:
      default:
        child = _buildShadesBar();
        break;
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stage header with back control when needed
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (_stage != BarStage.categories)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_stage == BarStage.shades) _stage = BarStage.brands;
                        else _stage = BarStage.categories;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.arrow_back, color: Colors.pink),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  _stage == BarStage.categories
                      ? 'Products'
                      : _stage == BarStage.brands
                      ? 'Brands'
                      : 'Shades',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          // AnimatedSwitcher keeps everything on same row and transitions smoothly
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) {
              final offsetAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(anim);
              return SlideTransition(position: offsetAnim, child: FadeTransition(opacity: anim, child: child));
            },
            child: SizedBox(key: ValueKey(_stage), child: child),
          ),
        ],
      ),
    );
  }
}

/// CompareScreen unchanged except can accept MemoryImage too
class CompareScreen extends StatefulWidget {
  final ImageProvider image; // just the user photo
  const CompareScreen({Key? key, required this.image}) : super(key: key);

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double _dividerPosition = 0.5; // slider position

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700, // same as Shades photo height
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          setState(() {
            _dividerPosition = (local.dx / box.size.width).clamp(0.0, 1.0);
          });
        },
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final clipWidth = w * _dividerPosition;

          return Stack(
            children: [
              // Full user photo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image(image: widget.image, width: w, height: h, fit: BoxFit.cover),
              ),

              // Left part clipped by slider (transparent, same photo)
              Positioned(
                left: 0,
                top: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: clipWidth,
                    height: h,
                    child: Image(image: widget.image, fit: BoxFit.cover),
                  ),
                ),
              ),

              // Slider divider line
              Positioned(
                left: clipWidth - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.white,
                ),
              ),

              // Round draggable handle
              Positioned(
                left: clipWidth - 18,
                top: (h / 2) - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: const Icon(Icons.drag_handle, color: Colors.black, size: 20),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// CompleteLooksScreen unchanged except it will display processed image if available
class CompleteLooksScreen extends StatelessWidget {
  final ImageProvider userImageProvider;
  final Map<int, Map<String, dynamic>> selections;
  const CompleteLooksScreen({Key? key, required this.userImageProvider, required this.selections}) : super(key: key);

  // Mock readable names for categories & brands (should mirror ShadesScreen's mock)
  static const List<String> categories = ['Foundation', 'Lipstick', 'Blush', 'Eyeshadow'];
  static const List<List<String>> brands = [
    ["L'Oreal Paris", "Maybelline Fit Me", "NARS Natural"],
    ["MAC Retro", "Maybelline SuperStay"],
    ["NARS Orgasm"],
    ["Urban Decay"],
  ];

  // Mock shade colors (should match ShadesScreen's list) - keep it simple for display
  static final List<List<List<Color>>> shades = [
    [
      [Color(0xFFDDB79B), Color(0xFFC89C74)],
      [Color(0xFFD7A883), Color(0xFFC4906A)],
      [Color(0xFFE0BFA0), Color(0xFFD1A383)],
    ],
    [
      [Color(0xFFD32F2F), Color(0xFFB71C1C)],
      [Color(0xFFD05B77), Color(0xFFC13F5A)],
    ],
    [
      [Color(0xFFF8BBD0), Color(0xFFF06292)],
    ],
    [
      [Color(0xFF8D6E63), Color(0xFF5D4037)],
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final selectedEntries = selections.entries.toList();

    return Container(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Final output image
            Container(
              height: 525,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image(image: userImageProvider, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 12),
            // Selected product list
            SizedBox(
              height: 120,
              child: selectedEntries.isEmpty
                  ? const Center(child: Text('No products selected yet'))
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: selectedEntries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final catIndex = selectedEntries[i].key;
                  final map = selectedEntries[i].value;
                  final brandIndex = map['brand'] ?? 0;
                  final shadeIndex = map['shade'] ?? 0;
                  final brandName = (catIndex < brands.length && brandIndex < brands[catIndex].length) ? brands[catIndex][brandIndex] : 'Brand';
                  final shadeColor = (catIndex < shades.length && brandIndex < shades[catIndex].length && shadeIndex < shades[catIndex][brandIndex].length)
                      ? shades[catIndex][brandIndex][shadeIndex]
                      : Colors.grey;

                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)]),
                    child: Row(
                      children: [
                        Container(width: 64, height: 64, decoration: BoxDecoration(color: shadeColor, borderRadius: BorderRadius.circular(8))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(categories[catIndex], style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(brandName, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(children: [
                                Container(width: 18, height: 18, decoration: BoxDecoration(color: shadeColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1))),
                                const SizedBox(width: 6),
                                Text('Shade ${shadeIndex + 1}', style: const TextStyle(fontSize: 12))
                              ])
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
