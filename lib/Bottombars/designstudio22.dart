// // visual_design_screen.dart
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
//
// /// ---------- CONFIG ----------
// const String baseUrl = 'https://www.happywedz.com/ai/api';
// const String productsApi = 'http://www.happywedz.com/ai/api/products/filter_products?category=MAKEUP';
// /// ----------------------------
//
// /// --- Models ---
// class CategoryModel {
//   final int id;
//   final String name;
//   final String? imageDataUri; // base64 image data or remote URL (if provided)
//
//   CategoryModel({required this.id, required this.name, this.imageDataUri});
//
//   factory CategoryModel.fromApi(int id, Map<String, dynamic> json) {
//     return CategoryModel(
//       id: id,
//       name: json['product_detailed_category_name'] ?? json['name'] ?? 'Unknown',
//       imageDataUri: json['product_detailed_image'],
//     );
//   }
// }
//
// class Brand {
//   final String name;
//   final int id; // product id from API
//   final List<Color> shades;
//   final String? productImageDataUri;
//
//   Brand({
//     required this.name,
//     required this.id,
//     List<Color>? shades,
//     this.productImageDataUri,
//   }) : shades = shades ?? [];
//
//   @override
//   String toString() => 'Brand(name:$name,id:$id,shades:${shades.length})';
// }
//
// /// ---------------- VisualDesignScreen ----------------
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
//   // Shared selection state
//   int selectedCategory = 0;
//   int? selectedBrandIndex;
//   int? selectedShadeIndex;
//   final Map<int, Map<String, dynamic>> selections = {};
//
//   ImageProvider get _placeholderImage => const NetworkImage(
//       'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1200&q=80');
//
//   // Networking / image handling
//   String? _uploadedImageId; // id returned by upload (e.g. 4896)
//   bool _isApplying = false;
//   Uint8List? _processedImageBytes;
//   bool _isUploading = false;
//
//   // Data fetched from API
//   List<CategoryModel> apiCategories = [];
//   List<List<Brand>> apiBrandsByCategory = [];
//
//   // Image picker
//   final ImagePicker _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     if (widget.userImage != null) {
//       // upload original image if passed in constructor
//       _uploadOriginalImage(widget.userImage!);
//     }
//     _fetchProducts(); // fetch categories & brands/shades from products API
//   }
//
//   // ---------------- UI ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           _buildTopBar(),
//           Expanded(
//             child: IndexedStack(
//               index: _currentTab,
//               children: [
//                 Column(
//                   children: [
//                     // photo area
//                     Container(
//                       height: 525,
//                       margin: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFEDEDED),
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.08),
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
//                                 : _processedImageBytes != null
//                                 ? Image.memory(_processedImageBytes!, fit: BoxFit.cover)
//                                 : Image(image: _placeholderImage, fit: BoxFit.cover),
//                           ),
//                           if (_isUploading)
//                             const Positioned.fill(
//                               child: Center(child: CircularProgressIndicator()),
//                             ),
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
//                                       selections[selectedCategory]?['intensity'] = val;
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
//                     Expanded(
//                       child: ShadesScreen(
//                         selectedCategory: selectedCategory,
//                         selectedBrandIndex: selectedBrandIndex,
//                         selectedShadeIndex: selectedShadeIndex,
//                         onCategorySelected: (catIndex) async {
//                           setState(() {
//                             selectedCategory = catIndex;
//                             selectedBrandIndex = null;
//                             selectedShadeIndex = null;
//                           });
//                           // non-blocking: ensure brands are present (we already load all via _fetchProducts)
//                           if (apiBrandsByCategory.length <= catIndex) {
//                             // nothing
//                           }
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
//                               'intensity': selections[selectedCategory]?['intensity'] ?? 1.0,
//                             };
//                           });
//                         },
//                         brandsByCategory: apiBrandsByCategory,
//                         categories: apiCategories.isNotEmpty ? apiCategories.map((c) => c.name).toList() : null,
//                         fetchBrandsForCategory: (int idx) async {
//                           // Products endpoint already returns brands/shades; nothing extra needed.
//                           // But we keep this hook if you want to implement per-category fetch later.
//                           return;
//                         },
//                         fetchShadesForBrand: (int brandId) async {
//                           // The product objects from product API contain product_colors already,
//                           // so here we attempt to find them in loaded data. Fallback empty.
//                           for (final list in apiBrandsByCategory) {
//                             for (final b in list) {
//                               if (b.id == brandId) return b.shades;
//                             }
//                           }
//                           return <Color>[];
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 CompareScreen(
//                   image: _processedImageBytes != null
//                       ? MemoryImage(_processedImageBytes!)
//                       : widget.userImage != null
//                       ? Image.file(widget.userImage!, fit: BoxFit.cover).image
//                       : _placeholderImage,
//                 ),
//
//                 CompleteLooksScreen(
//                   userImageProvider: _processedImageBytes != null
//                       ? MemoryImage(_processedImageBytes!)
//                       : widget.userImage != null
//                       ? Image.file(widget.userImage!).image
//                       : _placeholderImage,
//                   selections: selections,
//                 ),
//               ],
//             ),
//           ),
//           _buildBottomTabs(),
//         ],
//       ),
//       floatingActionButton: _buildFloatingActions(),
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
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
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
//       decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
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
//         onTap: () async {
//           if (index == 2) {
//             await _maybeApplyMakeupForSelections();
//           }
//           setState(() => _currentTab = index);
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             border: Border(top: BorderSide(color: isSelected ? Colors.pink : Colors.transparent, width: 3)),
//             color: isSelected ? const Color(0xFFFFF1F6) : Colors.white,
//           ),
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(color: isSelected ? Colors.pink : Colors.black54, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFloatingActions() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         FloatingActionButton(
//           heroTag: 'pick_image',
//           backgroundColor: Colors.pink,
//           onPressed: () async {
//             final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
//             if (picked != null) {
//               setState(() {});
//               await _uploadOriginalImage(File(picked.path));
//             }
//           },
//           child: const Icon(Icons.photo_library),
//         ),
//         const SizedBox(height: 8),
//         FloatingActionButton(
//           heroTag: 'camera',
//           backgroundColor: Colors.pink,
//           onPressed: () async {
//             final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
//             if (picked != null) {
//               setState(() {});
//               await _uploadOriginalImage(File(picked.path));
//             }
//           },
//           child: const Icon(Icons.camera_alt),
//         ),
//       ],
//     );
//   }
//
//   // ---------------- Networking helper functions ----------------
//
//   Future<void> _fetchProducts() async {
//     try {
//       final resp = await http.get(Uri.parse(productsApi));
//       if (resp.statusCode == 200) {
//         final jsonList = jsonDecode(resp.body) as List;
//         apiCategories.clear();
//         apiBrandsByCategory.clear();
//         int idx = 0;
//         for (final item in jsonList) {
//           final cat = CategoryModel.fromApi(idx, item as Map<String, dynamic>);
//           apiCategories.add(cat);
//
//           // parse products -> each product is effectively a brand entry in our UI
//           final products = (item['products'] as List?) ?? [];
//           final List<Brand> brands = [];
//           for (final p in products) {
//             final product = p as Map<String, dynamic>;
//             final List<Color> shades = [];
//             final colors = product['product_colors'] as List<dynamic>? ?? [];
//             for (final c in colors) {
//               try {
//                 shades.add(_hexToColor(c.toString()));
//               } catch (_) {}
//             }
//             final brand = Brand(
//               name: (product['brand_name'] ?? product['product_name'] ?? 'Brand').toString(),
//               id: (product['id'] is int) ? product['id'] as int : int.tryParse(product['id']?.toString() ?? '') ?? 0,
//               shades: shades,
//               productImageDataUri: product['product_real_image'],
//             );
//             brands.add(brand);
//           }
//
//           apiBrandsByCategory.add(brands);
//           idx++;
//         }
//         setState(() {});
//       } else {
//         _showSnackBar('Failed to load products: ${resp.statusCode}', Colors.red);
//       }
//     } catch (e) {
//       _showSnackBar('Error fetching products: $e', Colors.red);
//     }
//   }
//
//   Future<void> _uploadOriginalImage(File imageFile) async {
//     setState(() => _isUploading = true);
//     try {
//       final uri = Uri.parse('$baseUrl/images');
//       var request = http.MultipartRequest('POST', uri);
//       request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
//       request.fields['image_type'] = 'ORIGINAL';
//
//       final streamedResp = await request.send();
//       final respStr = await streamedResp.stream.bytesToString();
//
//       if (streamedResp.statusCode == 200 || streamedResp.statusCode == 201) {
//         final json = jsonDecode(respStr);
//         String? idStr;
//         if (json['id'] != null) idStr = json['id'].toString();
//         if (json['image_id'] != null) idStr = json['image_id'].toString();
//         if (json['uploaded_image_id'] != null) idStr = json['uploaded_image_id'].toString();
//         if (idStr == null && json['processed_image_id'] != null) idStr = json['processed_image_id'].toString();
//
//         if (idStr != null) {
//           _uploadedImageId = idStr;
//           _showSnackBar('Image uploaded (id: $_uploadedImageId)', Colors.green);
//         } else {
//           _showSnackBar('Upload succeeded but id not found', Colors.orange);
//         }
//       } else {
//         _showSnackBar('Failed to upload image: ${streamedResp.statusCode}', Colors.red);
//       }
//     } catch (e) {
//       _showSnackBar('Error uploading image: $e', Colors.red);
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }
//
//   Future<void> _maybeApplyMakeupForSelections() async {
//     if (_isApplying) return;
//     if (_uploadedImageId == null) {
//       if (widget.userImage != null) {
//         await _uploadOriginalImage(widget.userImage!);
//       } else {
//         _showSnackBar('Please upload an image first (use camera or gallery)', Colors.orange);
//         return;
//       }
//     }
//     if (_uploadedImageId == null) {
//       _showSnackBar('No uploaded image id available', Colors.red);
//       return;
//     }
//
//     // collect product ids from selections (brand id)
//     final productIds = <int>[];
//     selections.forEach((catIndex, map) {
//       final brand = map['brand'];
//       if (brand is int) {
//         if (apiBrandsByCategory.length > catIndex && apiBrandsByCategory[catIndex].isNotEmpty) {
//           final b = apiBrandsByCategory[catIndex][brand];
//           if (b != null && b.id != 0) {
//             productIds.add(b.id);
//             return;
//           }
//         }
//         // fallback: try brand index + 1
//         productIds.add((brand as int) + 1);
//       }
//     });
//
//     if (productIds.isEmpty) {
//       // fallback to first product id available globally
//       final first = apiBrandsByCategory.expand((e) => e).firstWhere((_) => true, orElse: () => Brand(name: 'dummy', id: 1));
//       productIds.add(first.id);
//     }
//
//     final requestData = <String, dynamic>{
//       "image_id": int.tryParse(_uploadedImageId!) ?? 0,
//       "product_ids": productIds,
//     };
//
//     // Prefer shade hexes from selection if available
//     selections.forEach((catIndex, map) {
//       final brandIndex = map['brand'];
//       final shadeIndex = map['shade'];
//       final intensity = map['intensity'];
//       if (brandIndex is int && shadeIndex is int) {
//         if (apiBrandsByCategory.length > catIndex) {
//           final brands = apiBrandsByCategory[catIndex];
//           if (brandIndex < brands.length) {
//             final b = brands[brandIndex];
//             if (b.shades.isNotEmpty && shadeIndex < b.shades.length) {
//               final hex = _colorToHex(b.shades[shadeIndex]);
//               final catName = (apiCategories.isNotEmpty && catIndex < apiCategories.length) ? apiCategories[catIndex].name.toLowerCase() : '';
//               if (catName.contains('lip') || catName.contains('lipstick')) {
//                 requestData["lipstick_color"] = hex;
//                 if (intensity != null) requestData["lipstick_intensity"] = intensity;
//               } else if (catName.contains('blush')) {
//                 requestData["blush_color"] = hex;
//                 if (intensity != null) requestData["blush_intensity"] = intensity;
//               } else if (catName.contains('eye') || catName.contains('eyeshadow')) {
//                 requestData["eyeshadow_color"] = hex;
//                 if (intensity != null) requestData["eyeshadow_intensity"] = intensity;
//               } else if (catName.contains('found') || catName.contains('foundation')) {
//                 requestData["foundation_color"] = hex;
//                 if (intensity != null) requestData["foundation_intensity"] = intensity;
//               } else {
//                 // generic map by index
//                 if (catIndex == 1) {
//                   requestData["lipstick_color"] = hex;
//                   if (intensity != null) requestData["lipstick_intensity"] = intensity;
//                 } else if (catIndex == 2) {
//                   requestData["blush_color"] = hex;
//                   if (intensity != null) requestData["blush_intensity"] = intensity;
//                 } else if (catIndex == 3) {
//                   requestData["eyeshadow_color"] = hex;
//                   if (intensity != null) requestData["eyeshadow_intensity"] = intensity;
//                 } else if (catIndex == 0) {
//                   requestData["foundation_color"] = hex;
//                   if (intensity != null) requestData["foundation_intensity"] = intensity;
//                 }
//               }
//             }
//           }
//         }
//       }
//     });
//
//     // Add default intensities if not present
//     requestData.addAll({
//       "lipstick_intensity": requestData["lipstick_intensity"] ?? 0.8,
//       "blush_intensity": requestData["blush_intensity"] ?? 0.6,
//       "eyeshadow_intensity": requestData["eyeshadow_intensity"] ?? 0.9,
//       "foundation_intensity": requestData["foundation_intensity"] ?? 0.6,
//     });
//
//     setState(() => _isApplying = true);
//     try {
//       final resp = await http.post(
//         Uri.parse('$baseUrl/images/apply-makeup'),
//         headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
//         body: jsonEncode(requestData),
//       );
//
//       if (resp.statusCode == 200 || resp.statusCode == 201) {
//         final jsonResp = jsonDecode(resp.body) as Map<String, dynamic>;
//         final processedId = jsonResp['processed_image_id'] ?? jsonResp['id'] ?? jsonResp['image_id'];
//         String? imageUrl;
//         if (jsonResp['url'] != null) {
//           imageUrl = jsonResp['url'].toString();
//         } else if (processedId != null) {
//           imageUrl = '$baseUrl/images/$processedId';
//         }
//
//         if (imageUrl != null) {
//           final imgResp = await http.get(Uri.parse(imageUrl));
//           if (imgResp.statusCode == 200) {
//             setState(() {
//               _processedImageBytes = imgResp.bodyBytes;
//             });
//             _showSnackBar('Processed image loaded', Colors.green);
//           } else {
//             _showSnackBar('Failed to fetch processed image (${imgResp.statusCode})', Colors.red);
//           }
//         } else {
//           _showSnackBar('No processed image id or url returned', Colors.red);
//         }
//       } else {
//         String err = 'Apply makeup failed: ${resp.statusCode}';
//         try {
//           err += '\n${resp.body}';
//         } catch (_) {}
//         _showSnackBar(err, Colors.red);
//       }
//     } catch (e) {
//       _showSnackBar('Error applying makeup: $e', Colors.red);
//     } finally {
//       setState(() => _isApplying = false);
//     }
//   }
//
//   // ---------------- Utilities ----------------
//   Color _hexToColor(String hex) {
//     var h = hex.replaceAll('#', '').trim();
//     if (h.length == 6) h = 'FF$h';
//     final val = int.tryParse(h, radix: 16) ?? 0xFFFFFFFF;
//     return Color(val);
//   }
//
//   String _colorToHex(Color color) {
//     String hex = color.value.toRadixString(16).padLeft(8, '0');
//     return '#${hex.substring(2).toUpperCase()}';
//   }
//
//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, maxLines: 6),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }
// lib/screens/visual_design_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// ---------------- CONFIG ----------------
const String baseUrl = 'https://www.happywedz.com/ai/api';
const String productsApi = 'http://69.62.85.170:5001/api/products/filter_products?category=MAKEUP';
// ----------------------------------------

/// NOTE:
/// This file expects your existing ShadesScreen, CompareScreen, CompleteLooksScreen
/// to be available (unchanged). This file only updates networking/logic while keeping UI intact.
///
///
class VisualDesignScreen extends StatefulWidget {
  final File? userImage;
  const VisualDesignScreen({Key? key, this.userImage}) : super(key: key);

  @override
  State<VisualDesignScreen> createState() => _VisualDesignScreenState();
}

class _VisualDesignScreenState extends State<VisualDesignScreen> {
  int _currentTab = 0;

  int selectedCategory = 0;
  int? selectedBrandIndex;
  int? selectedShadeIndex;
  final Map<int, Map<String, dynamic>> selections = {};

  String? _uploadedImageId;
  bool _isUploading = false;
  bool _isApplying = false;
  Uint8List? _processedImageBytes;
  final ImagePicker _picker = ImagePicker();

  List<CategoryModel> apiCategories = [];
  List<List<Brand>> apiBrandsByCategory = [];

  final String baseUrl = 'https://www.happywedz.com/ai/api';
  final String productsApi = 'https://www.happywedz.com/ai/api/products/filter_products?category=MAKEUP';

  ImageProvider get _placeholderImage => const NetworkImage(
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1200&q=80');

  @override
  void initState() {
    super.initState();
    if (widget.userImage != null) _uploadOriginalImage(widget.userImage!);
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                Column(
                  children: [
                    Container(
                      height: 525,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEDED),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.userImage != null
                                ? Image.file(widget.userImage!, fit: BoxFit.cover)
                                : _processedImageBytes != null
                                ? Image.memory(_processedImageBytes!, fit: BoxFit.cover)
                                : Image(image: _placeholderImage, fit: BoxFit.cover),
                          ),
                          if (_isUploading)
                            const Positioned.fill(
                              child: Center(child: CircularProgressIndicator()),
                            ),
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
                    Expanded(
                      child: ShadesScreen(
                        selectedCategory: selectedCategory,
                        selectedBrandIndex: selectedBrandIndex,
                        selectedShadeIndex: selectedShadeIndex,
                        onCategorySelected: (catIndex) {
                          setState(() {
                            selectedCategory = catIndex;
                            selectedBrandIndex = null;
                            selectedShadeIndex = null;
                          });
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
                              'intensity': selections[selectedCategory]?['intensity'] ?? 1.0,
                            };
                          });
                        },
                        brandsByCategory: apiBrandsByCategory,
                        categories: apiCategories.isNotEmpty ? apiCategories.map((c) => c.name).toList() : null,
                      ),

                    )
                  ],
                ),
                CompareScreen(
                  image: _processedImageBytes != null
                      ? MemoryImage(_processedImageBytes!)
                      : widget.userImage != null
                      ? Image.file(widget.userImage!, fit: BoxFit.cover).image
                      : _placeholderImage,
                ),
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
          _buildBottomTabs(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFEC1E79), Color(0xFFEF6AA9)]),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 8),
            const Expanded(
              child: Center(
                child: Text('Visual Design', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
              ),
            ),
            IconButton(icon: const Icon(Icons.location_on, color: Colors.white), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTabs() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
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
          if (index == 2) await _maybeApplyMakeupForSelections();
          setState(() => _currentTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: isSelected ? Colors.pink : Colors.transparent, width: 3)),
            color: isSelected ? const Color(0xFFFFF1F6) : Colors.white,
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.pink : Colors.black54, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
        ),
      ),
    );
  }

  Future<void> _fetchProducts() async {
    try {
      debugPrint('GET $productsApi');
      final resp = await http.get(Uri.parse(productsApi));
      debugPrint('Products API status: ${resp.statusCode}');
      print('--- PRODUCTS RESPONSE ---\n${resp.body}');

      if (resp.statusCode == 200) {
        final jsonList = jsonDecode(resp.body) as List;
        apiCategories.clear();
        apiBrandsByCategory.clear();
        int idx = 0;
        for (final itm in jsonList) {
          final map = itm as Map<String, dynamic>;
          final cat = CategoryModel.fromApi(idx, map);
          apiCategories.add(cat);

          final products = (map['products'] as List?) ?? [];
          final List<Brand> brands = [];
          for (final p in products) {
            final product = p as Map<String, dynamic>;
            final List<Color> shades = [];
            for (final c in (product['product_colors'] as List? ?? [])) {
              try { shades.add(_hexToColor(c.toString())); } catch (_) {}
            }
            final brand = Brand(
              name: (product['brand_name'] ?? product['product_name'] ?? 'Brand').toString(),
              id: product['id'] is int ? product['id'] : int.tryParse(product['id']?.toString() ?? '') ?? 0,
              shades: shades,
              productImageDataUri: product['product_real_image'],
              // productName: product['product_name']?.toString(),
            );
            brands.add(brand);
          }
          apiBrandsByCategory.add(brands);
          idx++;
        }
        setState(() {});
        print('Products & shades loaded successfully.');
      } else {
        print('Failed to load products: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _uploadOriginalImage(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final uri = Uri.parse('$baseUrl/images');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['image_type'] = 'ORIGINAL';

      final streamed = await request.send();
      final respStr = await streamed.stream.bytesToString();

      print('--- UPLOAD RESPONSE ---\nStatus: ${streamed.statusCode}\n$respStr');

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        final jsonResp = jsonDecode(respStr) as Map<String, dynamic>;
        _uploadedImageId = jsonResp['id']?.toString();
        print('Uploaded image id: $_uploadedImageId');
      } else {
        print('Upload failed: ${streamed.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _maybeApplyMakeupForSelections() async {
    if (_isApplying) return;
    if (_uploadedImageId == null) {
      if (widget.userImage != null) await _uploadOriginalImage(widget.userImage!);
      if (_uploadedImageId == null) return;
    }

    final productIds = <int>[];
    selections.forEach((catIndex, map) {
      final brandIdx = map['brand'];
      if (brandIdx is int && apiBrandsByCategory.length > catIndex) {
        final b = apiBrandsByCategory[catIndex][brandIdx];
        if (b != null && b.id != 0) productIds.add(b.id);
      }
    });
    if (productIds.isEmpty) productIds.add(apiBrandsByCategory.expand((e) => e).first.id);

    final Map<String, dynamic> payload = {"image_id": int.parse(_uploadedImageId!), "product_ids": productIds};

    selections.forEach((catIndex, map) {
      final brandIndex = map['brand'];
      final shadeIndex = map['shade'];
      final intensity = map['intensity'] ?? 1.0;
      if (brandIndex != null && shadeIndex != null && apiBrandsByCategory.length > catIndex) {
        final b = apiBrandsByCategory[catIndex][brandIndex];
        if (b.shades.isNotEmpty && shadeIndex < b.shades.length) {
          final hex = _colorToHex(b.shades[shadeIndex]);
          final catName = apiCategories[catIndex].name.toLowerCase();
          if (catName.contains('lip')) { payload['lipstick_color'] = hex; payload['lipstick_intensity'] = intensity; }
          else if (catName.contains('blush')) { payload['blush_color'] = hex; payload['blush_intensity'] = intensity; }
          else if (catName.contains('eye')) { payload['eyeshadow_color'] = hex; payload['eyeshadow_intensity'] = intensity; }
          else if (catName.contains('found')) { payload['foundation_color'] = hex; payload['foundation_intensity'] = intensity; }
        }
      }
    });

    print('--- APPLY MAKEUP REQUEST ---\n${jsonEncode(payload)}');
    setState(() => _isApplying = true);

    try {
      final resp = await http.post(
        Uri.parse('$baseUrl/images/apply-makeup'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(payload),
      );
      print('--- APPLY MAKEUP RESPONSE ---\nStatus: ${resp.statusCode}\n${resp.body}');

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final jsonResp = jsonDecode(resp.body);
        final processedId = jsonResp['processed_image_id'] ?? jsonResp['id'] ?? jsonResp['image_id'];
        final imageUrl = jsonResp['url']?.toString() ?? '$baseUrl/images/$processedId';
        final imgResp = await http.get(Uri.parse(imageUrl));
        if (imgResp.statusCode == 200) setState(() => _processedImageBytes = imgResp.bodyBytes);
      }
    } catch (e) {
      print('Error applying makeup: $e');
    } finally {
      setState(() => _isApplying = false);
    }
  }

  Color _hexToColor(String hex) {
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFFFFFFFF);
  }

  String _colorToHex(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }
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
//   // State for selections
//   int selectedCategory = 0;
//   int? selectedBrandIndex;
//   int? selectedShadeIndex;
//   final Map<int, Map<String, dynamic>> selections = {};
//
//   // Images & network state
//   String? _uploadedImageId;
//   bool _isUploading = false;
//   bool _isApplying = false;
//   Uint8List? _processedImageBytes;
//   final ImagePicker _picker = ImagePicker();
//
//   // Data from products API
//   List<CategoryModel> apiCategories = [];
//   List<List<Brand>> apiBrandsByCategory = [];
//
//   ImageProvider get _placeholderImage => const NetworkImage(
//       'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=1200&q=80');
//
//   @override
//   void initState() {
//     super.initState();
//     // If a file was supplied from previous screen, upload it now
//     if (widget.userImage != null) {
//       _uploadOriginalImage(widget.userImage!);
//     }
//     // fetch product categories & brands
//     _fetchProducts();
//   }
//
//   // ---------------- UI BUILD ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Column(
//         children: [
//           _buildTopBar(),
//           Expanded(
//             child: IndexedStack(
//               index: _currentTab,
//               children: [
//                 // Shades tab (photo + ShadesScreen below)
//                 Column(
//                   children: [
//                     Container(
//                       height: 525,
//                       margin: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFEDEDED),
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))
//                         ],
//                       ),
//                       child: Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(16),
//                             child: widget.userImage != null
//                                 ? Image.file(widget.userImage!, fit: BoxFit.cover)
//                                 : _processedImageBytes != null
//                                 ? Image.memory(_processedImageBytes!, fit: BoxFit.cover)
//                                 : Image(image: _placeholderImage, fit: BoxFit.cover),
//                           ),
//
//                           if (_isUploading)
//                             const Positioned.fill(
//                               child: Center(child: CircularProgressIndicator()),
//                             ),
//
//                           // Intensity slider (vertical) shown when a shade is selected
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
//                                       selections[selectedCategory]?['intensity'] = val;
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
//                               'intensity': selections[selectedCategory]?['intensity'] ?? 1.0,
//                             };
//                           });
//                         },
//                         brandsByCategory: apiBrandsByCategory,
//                         categories: apiCategories.isNotEmpty ? apiCategories.map((c) => c.name).toList() : null,
//                         fetchBrandsForCategory: (int idx) async {
//                           // we already load everything via _fetchProducts(); keep hook for later
//                           return;
//                         },
//                         fetchShadesForBrand: (int brandId) async {
//                           for (final list in apiBrandsByCategory) {
//                             for (final b in list) {
//                               if (b.id == brandId) return b.shades;
//                             }
//                           }
//                           return <Color>[];
//                         },
//                       ),
//                     )
//                   ],
//                 ),
//
//                 // Compare tab
//                 CompareScreen(
//                   image: _processedImageBytes != null
//                       ? MemoryImage(_processedImageBytes!)
//                       : widget.userImage != null
//                       ? Image.file(widget.userImage!, fit: BoxFit.cover).image
//                       : _placeholderImage,
//                 ),
//
//                 // Complete Looks tab
//                 CompleteLooksScreen(
//                   userImageProvider: _processedImageBytes != null
//                       ? MemoryImage(_processedImageBytes!)
//                       : widget.userImage != null
//                       ? Image.file(widget.userImage!).image
//                       : _placeholderImage,
//                   selections: selections,
//                 ),
//               ],
//             ),
//           ),
//           _buildBottomTabs(),
//         ],
//       ),
//       // floatingActionButton: _buildFloatingActions(),
//     );
//   }
//
//   Widget _buildTopBar() {
//     return Container(
//       height: 72,
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(colors: [Color(0xFFEC1E79), Color(0xFFEF6AA9)]),
//       ),
//       child: SafeArea(
//         bottom: false,
//         child: Row(
//           children: [
//             IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).maybePop()),
//             const SizedBox(width: 8),
//             const Expanded(
//               child: Center(
//                 child: Text('Visual Design', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
//               ),
//             ),
//             IconButton(icon: const Icon(Icons.location_on, color: Colors.white), onPressed: () {}),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomTabs() {
//     return Container(
//       decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)]),
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
//         onTap: () async {
//           if (index == 2) {
//             // when going to Complete Looks, run apply makeup (uses intensities from selections)
//             await _maybeApplyMakeupForSelections();
//           }
//           setState(() => _currentTab = index);
//         },
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             border: Border(top: BorderSide(color: isSelected ? Colors.pink : Colors.transparent, width: 3)),
//             color: isSelected ? const Color(0xFFFFF1F6) : Colors.white,
//           ),
//           child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.pink : Colors.black54, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFloatingActions() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         FloatingActionButton(
//           heroTag: 'pick_image',
//           backgroundColor: Colors.pink,
//           onPressed: () async {
//             final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
//             if (picked != null) {
//               // update displayed image (widget.userImage is immutable; for simplicity show via local file in the constructor when you push this screen)
//               await _uploadOriginalImage(File(picked.path));
//               setState(() {});
//             }
//           },
//           child: const Icon(Icons.photo_library),
//         ),
//         const SizedBox(height: 8),
//         FloatingActionButton(
//           heroTag: 'camera',
//           backgroundColor: Colors.pink,
//           onPressed: () async {
//             final XFile? picked = await _picker.pickImage(source: ImageSource.camera);
//             if (picked != null) {
//               await _uploadOriginalImage(File(picked.path));
//               setState(() {});
//             }
//           },
//           child: const Icon(Icons.camera_alt),
//         ),
//       ],
//     );
//   }
//
//   // ---------------- Networking Logic ----------------
//
//   /// Fetch products from your product API and populate categories -> brands -> shades
//   Future<void> _fetchProducts() async {
//     try {
//       debugPrint('GET $productsApi');
//       final resp = await http.get(Uri.parse(productsApi));
//       debugPrint('Products API response status: ${resp.statusCode}');
//       debugPrint('Products API response body: ${resp.body}');
//       print('--- PRODUCTS RESPONSE (full) ---');
//       print(resp.body);
//
//       if (resp.statusCode == 200) {
//         final jsonList = jsonDecode(resp.body) as List;
//         apiCategories.clear();
//         apiBrandsByCategory.clear();
//         int idx = 0;
//         for (final itm in jsonList) {
//           final map = itm as Map<String, dynamic>;
//           final cat = CategoryModel.fromApi(idx, map);
//           apiCategories.add(cat);
//
//           final products = (map['products'] as List?) ?? [];
//           final List<Brand> brands = [];
//           for (final p in products) {
//             final product = p as Map<String, dynamic>;
//             final List<Color> shades = [];
//             final colors = product['product_colors'] as List<dynamic>? ?? [];
//             for (final c in colors) {
//               try {
//                 shades.add(_hexToColor(c.toString()));
//               } catch (_) {}
//             }
//             final brand = Brand(
//               name: (product['brand_name'] ?? product['product_name'] ?? 'Brand').toString(),
//               id: (product['id'] is int) ? product['id'] as int : int.tryParse(product['id']?.toString() ?? '') ?? 0,
//               shades: shades,
//               productImageDataUri: product['product_real_image'],
//               productName: product['product_name']?.toString(),
//             );
//             brands.add(brand);
//           }
//
//           apiBrandsByCategory.add(brands);
//           idx++;
//         }
//         setState(() {});
//         _showBeautifulDialog('Products Loaded', 'Products & shades loaded successfully from API.');
//       } else {
//         _showSnackBar('Failed to load products: ${resp.statusCode}', Colors.red);
//         _showBeautifulDialog('Products Error', 'Failed to load products: ${resp.statusCode}');
//       }
//     } catch (e) {
//       print('Error fetching products: $e');
//       _showSnackBar('Error fetching products: $e', Colors.red);
//       _showBeautifulDialog('Products Error', 'Error fetching products: $e');
//     }
//   }
//
//   /// Upload original image to server to obtain image id
//   Future<void> _uploadOriginalImage(File imageFile) async {
//     setState(() => _isUploading = true);
//     try {
//       final uri = Uri.parse('$baseUrl/images');
//       var request = http.MultipartRequest('POST', uri);
//       request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
//       request.fields['image_type'] = 'ORIGINAL';
//
//       debugPrint('POST $uri (multipart) - uploading file: ${imageFile.path}');
//       final streamed = await request.send();
//       final respStr = await streamed.stream.bytesToString();
//
//       debugPrint('Upload response status: ${streamed.statusCode}');
//       debugPrint('Upload response body: $respStr');
//       print('--- UPLOAD RESPONSE (full) ---');
//       print(respStr);
//
//       if (streamed.statusCode == 200 || streamed.statusCode == 201) {
//         final jsonResp = jsonDecode(respStr) as Map<String, dynamic>;
//         final idVal = jsonResp['id'] ?? jsonResp['image_id'] ?? jsonResp['uploaded_image_id'] ?? jsonResp['processed_image_id'];
//         if (idVal != null) {
//           _uploadedImageId = idVal.toString();
//           _showSnackBar('Image uploaded (id: $_uploadedImageId)', Colors.green);
//           _showBeautifulDialog('Upload Success', 'Image uploaded successfully.\nID: $_uploadedImageId\n\nFull response:\n${jsonEncode(jsonResp)}');
//         } else {
//           _showSnackBar('Upload succeeded but id not found', Colors.orange);
//           _showBeautifulDialog('Upload Partial', 'Upload succeeded but id not found.\nResponse:\n$respStr');
//         }
//       } else {
//         _showSnackBar('Failed to upload image: ${streamed.statusCode}', Colors.red);
//         _showBeautifulDialog('Upload Failed', 'Status: ${streamed.statusCode}\nBody:\n$respStr');
//       }
//     } catch (e) {
//       print('Error uploading image: $e');
//       _showSnackBar('Error uploading image: $e', Colors.red);
//       _showBeautifulDialog('Upload Error', 'Error uploading image: $e');
//     } finally {
//       setState(() => _isUploading = false);
//     }
//   }
//
//   /// Apply makeup using the selections map and intensities; fetch processed image
//   Future<void> _maybeApplyMakeupForSelections() async {
//     if (_isApplying) {
//       _showSnackBar('Already applying makeup... please wait', Colors.orange);
//       return;
//     }
//
//     if (_uploadedImageId == null) {
//       // If widget.userImage passed in and not uploaded yet, upload now
//       if (widget.userImage != null) {
//         await _uploadOriginalImage(widget.userImage!);
//       } else {
//         _showSnackBar('Please upload an image first (camera/gallery)', Colors.orange);
//         _showBeautifulDialog('No Image', 'Please upload an image first (camera or gallery).');
//         return;
//       }
//     }
//
//     if (_uploadedImageId == null) {
//       _showSnackBar('Image ID missing; cannot apply makeup', Colors.red);
//       return;
//     }
//
//     // Prepare product_ids from selections
//     final productIds = <int>[];
//     selections.forEach((catIndex, map) {
//       final brandIdx = map['brand'];
//       if (brandIdx is int) {
//         if (apiBrandsByCategory.length > catIndex && apiBrandsByCategory[catIndex].isNotEmpty) {
//           final b = apiBrandsByCategory[catIndex][brandIdx];
//           if (b != null && b.id != 0) {
//             productIds.add(b.id);
//             return;
//           }
//         }
//         // fallback: brand index + 1 (shouldn't be needed if API product ids exist)
//         productIds.add(brandIdx + 1);
//       }
//     });
//
//     // fallback to first available product id if user didn't select anything
//     if (productIds.isEmpty) {
//       final found = apiBrandsByCategory.expand((e) => e).firstWhere((_) => true, orElse: () => Brand(name: 'fallback', id: 1));
//       productIds.add(found.id);
//     }
//
//     // Build request payload
//     final Map<String, dynamic> payload = {
//       "image_id": int.tryParse(_uploadedImageId!) ?? 0,
//       "product_ids": productIds,
//     };
//
//     // Merge shade colors + intensities from selections (try to map by category name where possible)
//     selections.forEach((catIndex, map) {
//       final brandIndex = map['brand'];
//       final shadeIndex = map['shade'];
//       final intensity = map['intensity'] ?? 1.0;
//       if (brandIndex is int && shadeIndex is int) {
//         if (apiBrandsByCategory.length > catIndex) {
//           final brands = apiBrandsByCategory[catIndex];
//           if (brandIndex < brands.length) {
//             final b = brands[brandIndex];
//             if (b.shades.isNotEmpty && shadeIndex < b.shades.length) {
//               final hex = _colorToHex(b.shades[shadeIndex]);
//               final catName = (apiCategories.isNotEmpty && catIndex < apiCategories.length) ? apiCategories[catIndex].name.toLowerCase() : '';
//
//               if (catName.contains('lip') || catName.contains('lipstick')) {
//                 payload['lipstick_color'] = hex;
//                 payload['lipstick_intensity'] = intensity;
//               } else if (catName.contains('blush')) {
//                 payload['blush_color'] = hex;
//                 payload['blush_intensity'] = intensity;
//               } else if (catName.contains('eye') || catName.contains('eyeshadow')) {
//                 payload['eyeshadow_color'] = hex;
//                 payload['eyeshadow_intensity'] = intensity;
//               } else if (catName.contains('found') || catName.contains('foundation')) {
//                 payload['foundation_color'] = hex;
//                 payload['foundation_intensity'] = intensity;
//               } else {
//                 // generic mapping by index fallback
//                 if (catIndex == 1) {
//                   payload['lipstick_color'] = hex;
//                   payload['lipstick_intensity'] = intensity;
//                 } else if (catIndex == 2) {
//                   payload['blush_color'] = hex;
//                   payload['blush_intensity'] = intensity;
//                 } else if (catIndex == 3) {
//                   payload['eyeshadow_color'] = hex;
//                   payload['eyeshadow_intensity'] = intensity;
//                 } else if (catIndex == 0) {
//                   payload['foundation_color'] = hex;
//                   payload['foundation_intensity'] = intensity;
//                 }
//               }
//             }
//           }
//         }
//       }
//     });
//
//     // Ensure some default intensities exist
//     payload.putIfAbsent('lipstick_intensity', () => 0.8);
//     payload.putIfAbsent('blush_intensity', () => 0.6);
//     payload.putIfAbsent('eyeshadow_intensity', () => 0.9);
//     payload.putIfAbsent('foundation_intensity', () => 0.6);
//
//     debugPrint('POST $baseUrl/images/apply-makeup');
//     debugPrint('Payload: ${jsonEncode(payload)}');
//     print('--- APPLY MAKEUP REQUEST ---');
//     print(jsonEncode(payload));
//
//     setState(() => _isApplying = true);
//     try {
//       final resp = await http.post(
//         Uri.parse('$baseUrl/images/apply-makeup'),
//         headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
//         body: jsonEncode(payload),
//       );
//
//       debugPrint('Apply response status: ${resp.statusCode}');
//       debugPrint('Apply response body: ${resp.body}');
//       print('--- APPLY MAKEUP RESPONSE (full) ---');
//       print(resp.body);
//
//       if (resp.statusCode == 200 || resp.statusCode == 201) {
//         final jsonResp = jsonDecode(resp.body) as Map<String, dynamic>;
//         final processedId = jsonResp['processed_image_id'] ?? jsonResp['id'] ?? jsonResp['image_id'];
//         String? imageUrl;
//         if (jsonResp['url'] != null) imageUrl = jsonResp['url'].toString();
//         if (imageUrl == null && processedId != null) imageUrl = '$baseUrl/images/$processedId';
//
//         if (imageUrl != null) {
//           final imgResp = await http.get(Uri.parse(imageUrl));
//           debugPrint('Fetched processed image status: ${imgResp.statusCode}');
//           if (imgResp.statusCode == 200) {
//             setState(() {
//               _processedImageBytes = imgResp.bodyBytes;
//             });
//             _showSnackBar('Processed image loaded', Colors.green);
//             _showBeautifulDialog('Makeup Applied', 'Makeup applied successfully. Processed image loaded.');
//           } else {
//             _showSnackBar('Failed to download processed image: ${imgResp.statusCode}', Colors.red);
//             _showBeautifulDialog('Processed Image Error', 'Failed to download processed image. Status: ${imgResp.statusCode}');
//           }
//         } else {
//           _showSnackBar('No processed image id/url returned', Colors.red);
//           _showBeautifulDialog('Apply Response Missing', 'No processed image id or url returned.\n\nResponse:\n${jsonEncode(jsonResp)}');
//         }
//       } else {
//         _showSnackBar('Apply makeup failed: ${resp.statusCode}', Colors.red);
//         _showBeautifulDialog('Apply Failed', 'Status: ${resp.statusCode}\nBody:\n${resp.body}');
//       }
//     } catch (e) {
//       print('Error applying makeup: $e');
//       _showSnackBar('Error applying makeup: $e', Colors.red);
//       _showBeautifulDialog('Apply Error', 'Error applying makeup: $e');
//     } finally {
//       setState(() => _isApplying = false);
//     }
//   }
//
//   // ---------------- Utilities ----------------
//
//   Color _hexToColor(String hex) {
//     var h = hex.replaceAll('#', '').trim();
//     if (h.length == 6) h = 'FF$h';
//     final val = int.tryParse(h, radix: 16) ?? 0xFFFFFFFF;
//     return Color(val);
//   }
//
//   String _colorToHex(Color color) {
//     final hex = color.value.toRadixString(16).padLeft(8, '0');
//     return '#${hex.substring(2).toUpperCase()}';
//   }
//
//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, maxLines: 6),
//         backgroundColor: color,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
//
//   /// A slightly prettier dialog for important API responses / errors
//   void _showBeautifulDialog(String title, String body) {
//     showDialog(
//       context: context,
//       builder: (ctx) {
//         return Dialog(
//           backgroundColor: Colors.white,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//           child: Container(
//             constraints: const BoxConstraints(maxWidth: 520),
//             padding: const EdgeInsets.all(18),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(children: [
//                   const Icon(Icons.info_outline, color: Colors.pink),
//                   const SizedBox(width: 8),
//                   Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
//                 ]),
//                 const SizedBox(height: 12),
//                 Text(body, style: const TextStyle(fontSize: 14, height: 1.35)),
//                 const SizedBox(height: 18),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

/// ----------------- Small data models used by this screen -----------------
class CategoryModel {
  final int id;
  final String name;
  final String? imageDataUri;
  CategoryModel({required this.id, required this.name, this.imageDataUri});

  factory CategoryModel.fromApi(int idIndex, Map<String, dynamic> json) {
    return CategoryModel(
      id: idIndex,
      name: json['product_detailed_category_name'] ?? json['name'] ?? 'Unknown',
      imageDataUri: json['product_detailed_image'],
    );
  }
}

// class Brand {
//   final String name;
//   final int id;
//   final List<Color> shades;
//   final String? productImageDataUri;
//   final String? productName;
//
//   Brand({required this.name, required this.id, List<Color>? shades, this.productImageDataUri, this.productName}) : shades = shades ?? [];
// }
//
// /// ---------------- ShadesScreen (unchanged UI, hooked to dynamic data) ----------------
// enum BarStage { categories, brands, shades }
class ShadesScreen extends StatefulWidget {
  final int selectedCategory;
  final void Function(int) onCategorySelected;
  final void Function(int) onBrandSelected;
  final void Function(int) onShadeSelected;
  final int? selectedBrandIndex;
  final int? selectedShadeIndex;

  final List<List<Brand>>? brandsByCategory;
  final List<String>? categories;

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
  }) : super(key: key);

  @override
  State<ShadesScreen> createState() => _ShadesScreenState();
}

class _ShadesScreenState extends State<ShadesScreen> {
  BarStage _stage = BarStage.categories;
  int _categoryIndex = 0;
  int _brandIndex = 0;
  int _shadeIndex = 0;

  @override
  void initState() {
    super.initState();
    _categoryIndex = widget.selectedCategory;
    _brandIndex = widget.selectedBrandIndex ?? 0;
    _shadeIndex = widget.selectedShadeIndex ?? 0;
    _stage = BarStage.categories;
  }

  List<String> get effectiveCategories => widget.categories ?? [];
  List<List<Brand>> get effectiveBrandsByCategory => widget.brandsByCategory ?? [];

  Brand? _safeGetBrand(int catIdx, int brandIdx) {
    if (catIdx < effectiveBrandsByCategory.length) {
      final brands = effectiveBrandsByCategory[catIdx];
      if (brandIdx < brands.length) return brands[brandIdx];
    }
    return null;
  }

  Color _hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  void _goToBrands(int categoryIdx) {
    setState(() {
      _categoryIndex = categoryIdx;
      _stage = BarStage.brands;
      _brandIndex = 0;
      _shadeIndex = 0;
      widget.onCategorySelected(categoryIdx);
    });
  }

  void _goToShades(int brandIdx) {
    setState(() {
      _brandIndex = brandIdx;
      _stage = BarStage.shades;
      _shadeIndex = 0;
      widget.onBrandSelected(brandIdx);
    });

    final brand = _safeGetBrand(_categoryIndex, _brandIndex);
    if (brand != null) {
      final colors = brand.productColors?.map(_hexToColor).toList() ?? [];
      setState(() {
        brand.shades = colors; // populate shades dynamically
      });
    }
  }

  void _selectShade(int shadeIdx) {
    setState(() {
      _shadeIndex = shadeIdx;
      widget.onShadeSelected(shadeIdx);
    });
  }

  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: effectiveCategories.length,
        itemBuilder: (context, i) {
          final selected = i == _categoryIndex && _stage == BarStage.categories;
          final label = effectiveCategories[i];
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
                  Icon(
                    i == 0
                        ? Icons.blur_on
                        : i == 1
                        ? Icons.brightness_4
                        : i == 2
                        ? Icons.circle
                        : Icons.remove_red_eye,
                    size: 36,
                    color: selected ? Colors.pink : Colors.grey[700],
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: TextStyle(color: selected ? Colors.pink : Colors.black87)),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
      ),
    );
  }

  Widget _buildBrandsBar() {
    final brands = (_categoryIndex < effectiveBrandsByCategory.length)
        ? effectiveBrandsByCategory[_categoryIndex]
        : <Brand>[];
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _stage = BarStage.categories);
            },
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              scrollDirection: Axis.horizontal,
              itemCount: brands.length,
              itemBuilder: (context, i) {
                final isSel = i == _brandIndex && _stage == BarStage.brands;
                final brand = brands[i];
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
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                          child: brand.productImageDataUri != null
                              ? _maybeShowBase64(brand.productImageDataUri!)
                              : const Icon(Icons.image, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(brand.name, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.normal))),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 12),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildShadesBar() {
    final brands = (_categoryIndex < effectiveBrandsByCategory.length) ? effectiveBrandsByCategory[_categoryIndex] : <Brand>[];
    final selectedBrand = (brands.isNotEmpty && _brandIndex < brands.length) ? brands[_brandIndex] : Brand(name: 'Brand', id: 0, shades: []);
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

  static Widget _maybeShowBase64(String dataUri) {
    try {
      if (dataUri.startsWith('data:image')) {
        final base64Str = dataUri.split(',').last;
        final bytes = base64Decode(base64Str);
        return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, fit: BoxFit.cover));
      }
    } catch (_) {}
    return const Icon(Icons.image, color: Colors.grey);
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

// Update your Brand model to support productColors as hex strings
class Brand {
  final int id;
  final String name;
  List<Color> shades;
  final List<String>? productColors; // hex strings from API
  final String? productImageDataUri;

  Brand({required this.name, required this.id, this.shades = const [], this.productColors, this.productImageDataUri});
}

enum BarStage { categories, brands, shades }

// class ShadesScreen extends StatefulWidget {
//   final int selectedCategory;
//   final void Function(int) onCategorySelected;
//   final void Function(int) onBrandSelected;
//   final void Function(int) onShadeSelected;
//   final int? selectedBrandIndex;
//   final int? selectedShadeIndex;
//
//   final List<List<Brand>>? brandsByCategory;
//   final List<String>? categories;
//   final Future<void> Function(int)? fetchBrandsForCategory;
//   final Future<List<Color>> Function(int)? fetchShadesForBrand;
//
//   const ShadesScreen({
//     Key? key,
//     required this.selectedCategory,
//     required this.onCategorySelected,
//     required this.onBrandSelected,
//     required this.onShadeSelected,
//     this.selectedBrandIndex,
//     this.selectedShadeIndex,
//     this.brandsByCategory,
//     this.categories,
//     this.fetchBrandsForCategory,
//     this.fetchShadesForBrand,
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
//   List<String> categoriesLocal = ['Foundation', 'Lipstick', 'Blush', 'Eyeshadow'];
//   late List<List<Brand>> brandsByCategoryLocal;
//
//   @override
//   void initState() {
//     super.initState();
//     _categoryIndex = widget.selectedCategory;
//     brandsByCategoryLocal = [
//       [Brand(name: "L'Oreal Paris", id: 1, shades: [Color(0xFFDDB79B), Color(0xFFC89C74)])],
//       [Brand(name: "MAC Retro", id: 4, shades: [Color(0xFFD32F2F), Color(0xFFB71C1C)])],
//       [Brand(name: "NARS Orgasm", id: 6, shades: [Color(0xFFF8BBD0)])],
//       [Brand(name: "Urban Decay", id: 7, shades: [Color(0xFF8D6E63)])],
//     ];
//     _brandIndex = widget.selectedBrandIndex ?? 0;
//     _shadeIndex = widget.selectedShadeIndex ?? 0;
//     _stage = BarStage.categories;
//   }
//
//   List<String> get effectiveCategories => widget.categories ?? categoriesLocal;
//   List<List<Brand>> get effectiveBrandsByCategory => widget.brandsByCategory ?? brandsByCategoryLocal;
//
//   void _goToBrands(int categoryIdx) async {
//     setState(() {
//       _categoryIndex = categoryIdx;
//       _stage = BarStage.brands;
//       _brandIndex = 0;
//       _shadeIndex = 0;
//       widget.onCategorySelected(categoryIdx);
//     });
//
//     if (widget.fetchBrandsForCategory != null) {
//       await widget.fetchBrandsForCategory!(categoryIdx);
//       setState(() {});
//     }
//   }
//
//   void _goToShades(int brandIdx) async {
//     setState(() {
//       _brandIndex = brandIdx;
//       _stage = BarStage.shades;
//       _shadeIndex = 0;
//       widget.onBrandSelected(brandIdx);
//     });
//
//     if (widget.fetchShadesForBrand != null) {
//       final brand = _safeGetBrand(_categoryIndex, _brandIndex);
//       if (brand != null && brand.id != 0) {
//         final colors = await widget.fetchShadesForBrand!(brand.id);
//         if (colors.isNotEmpty) {
//           setState(() {
//             brand.shades.clear();
//             brand.shades.addAll(colors);
//           });
//         }
//       }
//     }
//   }
//
//   void _selectShade(int shadeIdx) {
//     setState(() {
//       _shadeIndex = shadeIdx;
//       widget.onShadeSelected(shadeIdx);
//     });
//   }
//
//   Brand? _safeGetBrand(int catIdx, int brandIdx) {
//     final list = effectiveBrandsByCategory;
//     if (catIdx < list.length) {
//       final brands = list[catIdx];
//       if (brandIdx < brands.length) return brands[brandIdx];
//     }
//     return null;
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
//           final label = i < effectiveCategories.length ? effectiveCategories[i] : 'Category $i';
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
//                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(i == 0 ? Icons.blur_on : i == 1 ? Icons.brightness_4 : i == 2 ? Icons.circle : Icons.remove_red_eye,
//                       size: 36, color: selected ? Colors.pink : Colors.grey[700]),
//                   const SizedBox(height: 6),
//                   Text(label, style: TextStyle(color: selected ? Colors.pink : Colors.black87)),
//                 ],
//               ),
//             ),
//           );
//         },
//         separatorBuilder: (_, __) => const SizedBox(width: 12),
//         itemCount: effectiveCategories.length,
//       ),
//     );
//   }
//
//   Widget _buildBrandsBar() {
//     final brands = (effectiveBrandsByCategory.length > _categoryIndex) ? effectiveBrandsByCategory[_categoryIndex] : <Brand>[];
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
//                 final brand = i < brands.length ? brands[i] : Brand(name: 'Brand $i', id: 0);
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
//                       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
//                     ),
//                     child: Row(
//                       children: [
//                         const SizedBox(width: 8),
//                         Container(
//                           width: 58,
//                           height: 58,
//                           decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
//                           child: brand.productImageDataUri != null
//                               ? _maybeShowBase64(brand.productImageDataUri!)
//                               : const Icon(Icons.image, color: Colors.grey),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(child: Text(brand.name, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.normal))),
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
//     final brands = (effectiveBrandsByCategory.length > _categoryIndex) ? effectiveBrandsByCategory[_categoryIndex] : <Brand>[];
//     final selectedBrand = brands.isNotEmpty && _brandIndex < brands.length ? brands[_brandIndex] : Brand(name: 'Brand', id: 0, shades: []);
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
//                           boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6)],
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       if (isSel)
//                         Container(width: 44, height: 6, decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(3))),
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
//   static Widget _maybeShowBase64(String dataUri) {
//     try {
//       if (dataUri.startsWith('data:image')) {
//         final base64Str = dataUri.split(',').last;
//         final bytes = base64Decode(base64Str);
//         return ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.memory(bytes, fit: BoxFit.cover));
//       }
//     } catch (_) {}
//     return const Icon(Icons.image, color: Colors.grey);
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
//                   _stage == BarStage.categories ? 'Products' : _stage == BarStage.brands ? 'Brands' : 'Shades',
//                   style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//                 ),
//               ],
//             ),
//           ),
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

/// ---------------- CompareScreen ----------------
class CompareScreen extends StatefulWidget {
  final ImageProvider image;
  const CompareScreen({Key? key, required this.image}) : super(key: key);

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  double _dividerPosition = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 700,
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
              ClipRRect(borderRadius: BorderRadius.circular(16), child: Image(image: widget.image, width: w, height: h, fit: BoxFit.cover)),
              Positioned(
                left: 0,
                top: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(width: clipWidth, height: h, child: Image(image: widget.image, fit: BoxFit.cover)),
                ),
              ),
              Positioned(left: clipWidth - 1, top: 0, bottom: 0, child: Container(width: 2, color: Colors.white)),
              Positioned(
                left: clipWidth - 18,
                top: (h / 2) - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
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

/// ---------------- CompleteLooksScreen ----------------
class CompleteLooksScreen extends StatelessWidget {
  final ImageProvider userImageProvider;
  final Map<int, Map<String, dynamic>> selections;
  const CompleteLooksScreen({Key? key, required this.userImageProvider, required this.selections}) : super(key: key);

  static const List<String> categories = ['Foundation', 'Lipstick', 'Blush', 'Eyeshadow'];
  static const List<List<String>> brands = [
    ["L'Oreal Paris", "Maybelline Fit Me", "NARS Natural"],
    ["MAC Retro", "Maybelline SuperStay"],
    ["NARS Orgasm"],
    ["Urban Decay"],
  ];
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
            Container(
              height: 525,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image(image: userImageProvider, fit: BoxFit.cover)),
            ),
            const SizedBox(height: 12),
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
