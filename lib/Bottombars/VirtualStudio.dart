import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
//
// class MakeupApiService {
//   final String baseUrl = "http://69.62.85.170:5001/api";
//
//   /// Step 1: Upload Image
//   Future<int?> uploadImage(File imageFile) async {
//     print("➡️ Uploading image: ${imageFile.path}");
//     var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/images"));
//     request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
//     request.fields['image_type'] = "ORIGINAL";
//
//     try {
//       var response = await request.send();
//       var body = await response.stream.bytesToString();
//       print("⬅️ Upload response: $body");
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         var data = json.decode(body);
//         return data["id"];
//       }
//       print("❌ Upload failed: ${response.statusCode}");
//       return null;
//     } catch (e) {
//       print("❌ Upload error: $e");
//       return null;
//     }
//   }
//
//   /// Step 2: Fetch Products (for display only)
//   Future<List<String>> getProducts() async {
//     print("➡️ Fetching products...");
//     var response = await http.get(Uri.parse("$baseUrl/products/filter_products?category=MAKEUP"));
//     print("⬅️ Products response: ${response.body}");
//
//     if (response.statusCode == 200) {
//       var data = json.decode(response.body) as List;
//
//       // Map dynamic list to List<String>
//       return data
//           .map<String>((item) => item["product_detailed_category_name"]?.toString() ?? "Unnamed Product")
//           .toList();
//     }
//     return [];
//   }
//
//   /// Step 3: Apply Makeup (uses hardcoded valid product ID)
//   Future<String?> applyMakeup(int imageId) async {
//     int validProductId = 1; // hardcoded valid product
//
//     var body = json.encode({
//       "image_id": imageId,
//       "product_ids": [validProductId],
//       "lipstick_intensity": 0.8,
//       "lipstick_color": "#B22222",
//       "blush_intensity": 0.2,
//       "blush_radius": 60,
//       "blush_color": "#F08080",
//       "eyeshadow_intensity": 0.4,
//       "eyeshadow_thickness": 25,
//       "eyeshadow_color": "#9370DB",
//       "lens_intensity": 0.2,
//       "lens_radius_scale": 1.3,
//       "lens_color": "#4B9CD3",
//       "foundation_intensity": 0.6,
//       "foundation_color": "#F5D6C6",
//       "kajal_intensity": 1.0,
//       "kajal_color": "#000000",
//       "concealer_intensity": 0.9,
//       "concealer_color": "#FFDAB9",
//       "contour_intensity": 0.3,
//       "contour_color": "#8B4513",
//       "bindi_size": 6,
//       "bindi_color": "#FF0000"
//     });
//
//     var response = await http.post(
//       Uri.parse("$baseUrl/images/apply-makeup"),
//       headers: {"Content-Type": "application/json"},
//       body: body,
//     );
//
//     print("⬅️ Apply response: ${response.statusCode} ${response.body}");
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       var data = json.decode(response.body);
//       // The API returns the URL under "url"
//       return data["url"];
//     }
//
//     print("❌ Server failed with status: ${response.statusCode}");
//     return null;
//   }
// }
//
// class VirMakeupScreen extends StatefulWidget {
//   const VirMakeupScreen({super.key});
//
//   @override
//   State<VirMakeupScreen> createState() => _VirMakeupScreenState();
// }
//
// class _VirMakeupScreenState extends State<VirMakeupScreen> {
//   final MakeupApiService api = MakeupApiService();
//   File? selectedImage;
//   String? finalImageUrl;
//   bool isLoading = false;
//
//   List<String> products = [];
//
//   /// Pick Image from Gallery
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         selectedImage = File(picked.path);
//         finalImageUrl = null;
//         products = [];
//       });
//
//       // Load products (display only)
//       final fetchedProducts = await api.getProducts();
//       setState(() => products = fetchedProducts);
//     }
//   }
//
//   /// Apply Makeup
//   Future<void> processMakeup() async {
//     if (selectedImage == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Please select an image.")));
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     int? imageId = await api.uploadImage(selectedImage!);
//     if (imageId == null) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Image upload failed.")));
//       return;
//     }
//
//     String? url = await api.applyMakeup(imageId);
//     setState(() {
//       finalImageUrl = url;
//       isLoading = false;
//     });
//
//     if (url == null) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text("Makeup application failed.")));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Virtual Makeup")),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 if (selectedImage != null && finalImageUrl == null)
//                   Image.file(selectedImage!, height: 200, fit: BoxFit.cover),
//                 if (finalImageUrl != null)
//                   Image.network(finalImageUrl!, height: 200, fit: BoxFit.cover),
//
//                 const SizedBox(height: 20),
//
//                 if (products.isNotEmpty)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Products (for display only):",
//                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                       ),
//                       ...products.map((name) => ListTile(title: Text(name))).toList(),
//                     ],
//                   ),
//
//                 const SizedBox(height: 20),
//
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     ElevatedButton.icon(
//                       onPressed: isLoading ? null : pickImage,
//                       icon: const Icon(Icons.upload),
//                       label: const Text("Upload"),
//                     ),
//                     ElevatedButton.icon(
//                       onPressed: isLoading ? null : processMakeup,
//                       icon: const Icon(Icons.brush),
//                       label: const Text("Apply Makeup"),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           if (isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.4),
//               child: const Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }




import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class MakeupTryOnScreen extends StatefulWidget {
  @override
  _MakeupTryOnScreenState createState() => _MakeupTryOnScreenState();
}

class _MakeupTryOnScreenState extends State<MakeupTryOnScreen> {
  final String baseUrl = 'https://www.happywedz.com/ai/api';
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _uploadedImageId;
  Uint8List? _resultImage;
  List<Product> _products = [];
  List<Product> _selectedProducts = [];
  String _selectedCategory = 'MAKEUP';
  String _selectedDetailedCategory = 'LIPSTICK';
  bool _isLoading = false;

  // Makeup parameters with pink theme defaults
  double lipstickIntensity = 0.8;
  Color lipstickColor = Color(0xFFE91E63);
  double blushIntensity = 0.35;
  double blushRadius = 60;
  Color blushColor = Color(0xFFFFB6C1);
  double eyeshadowIntensity = 0.4;
  double eyeshadowThickness = 25;
  Color eyeshadowColor = Color(0xFFDDA0DD);
  double lensIntensity = 0.2;
  double lensRadiusScale = 1.3;
  Color lensColor = Color(0xFF4B9CD3);
  double foundationIntensity = 0.6;
  Color foundationColor = Color(0xFFF5D6C6);
  double kajalIntensity = 1.0;
  Color kajalColor = Colors.black;
  double concealerIntensity = 0.9;
  Color concealerColor = Color(0xFFFFDAB9);
  double contourIntensity = 0.3;
  Color contourColor = Color(0xFF8B4513);
  double bindiSize = 6;
  Color bindiColor = Colors.red;

  final List<String> categories = ['MAKEUP'];
  final List<String> detailedCategories = [
    'LIPSTICK', 'BLUSH', 'EYESHADOW', 'FOUNDATION', 'KAJAL', 'CONCEALER', 'CONTOUR', 'MASCARA', 'CONTACTLENSES', 'BINDI', 'MANGTIKA'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Virtual Makeup Try-On', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[200]!, Colors.pink[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(Icons.face, size: 50, color: Colors.pink[600]),
                    SizedBox(height: 10),
                    Text(
                      'Try Virtual Makeup',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink[800],
                      ),
                    ),
                    Text(
                      'Upload your photo and try different makeup looks',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.pink[700],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // Image Upload Section
              _buildImageSection(),
              SizedBox(height: 20),

              // Product Filter Section
              if (_uploadedImageId != null) _buildProductFilterSection(),
              SizedBox(height: 20),

              // Makeup Controls Section
              if (_uploadedImageId != null) _buildMakeupControlsSection(),
              SizedBox(height: 20),

              // Apply Makeup Button
              if (_uploadedImageId != null) _buildApplyMakeupButton(),
              SizedBox(height: 20),

              // Result Image Section
              if (_resultImage != null) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Upload Your Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: 16),
            if (_selectedImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink[300]!, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink[300]!, width: 2, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 50, color: Colors.pink[400]),
                    Text('Tap to select image', style: TextStyle(color: Colors.pink[600])),
                  ],
                ),
              ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null && _uploadedImageId == null) ...[
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploadImage,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Upload Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductFilterSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDetailedCategory,
              decoration: InputDecoration(
                labelText: 'Product Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.pink[400]!),
                ),
              ),
              items: detailedCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDetailedCategory = value!;
                });
                _loadProducts();
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              child: Text('Load Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[400],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_products.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Available Products:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[800]),
              ),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final isSelected = _selectedProducts.contains(product);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedProducts.remove(product);
                          } else {
                            _selectedProducts.add(product);
                          }
                        });
                      },
                      child: Container(
                        width: 100,
                        margin: EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.pink[100] : Colors.white,
                          border: Border.all(
                            color: isSelected ? Colors.pink[400]! : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.palette,
                              color: isSelected ? Colors.pink[600] : Colors.grey[600],
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                product.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.pink[800] : Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis, // 👈 adds "..." if too long
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMakeupControlsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Makeup Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: 16),
            // Lipstick
            _buildSliderControl('Lipstick Intensity', lipstickIntensity, (value) {
              setState(() => lipstickIntensity = value);
            }),
            _buildColorControl('Lipstick Color', lipstickColor, (color) {
              setState(() => lipstickColor = color);
            }),

            SizedBox(height: 20),

            // Blush
            _buildSliderControl('Blush Intensity', blushIntensity, (value) {
              setState(() => blushIntensity = value);
            }),
            _buildSliderControl('Blush Radius', blushRadius, (value) {
              setState(() => blushRadius = value);
            }, min: 10, max: 100),
            _buildColorControl('Blush Color', blushColor, (color) {
              setState(() => blushColor = color);
            }),

            SizedBox(height: 20),

            // Eyeshadow
            _buildSliderControl('Eyeshadow Intensity', eyeshadowIntensity, (value) {
              setState(() => eyeshadowIntensity = value);
            }),
            _buildSliderControl('Eyeshadow Thickness', eyeshadowThickness, (value) {
              setState(() => eyeshadowThickness = value);
            }, min: 1, max: 10),
            _buildColorControl('Eyeshadow Color', eyeshadowColor, (color) {
              setState(() => eyeshadowColor = color);
            }),

            SizedBox(height: 20),

            // Foundation
            _buildSliderControl('Foundation Intensity', foundationIntensity, (value) {
              setState(() => foundationIntensity = value);
            }),
            _buildColorControl('Foundation Color', foundationColor, (color) {
              setState(() => foundationColor = color);
            }),

            SizedBox(height: 20),

            // Kajal
            _buildSliderControl('Kajal Intensity', kajalIntensity, (value) {
              setState(() => kajalIntensity = value);
            }),
            _buildColorControl('Kajal Color', kajalColor, (color) {
              setState(() => kajalColor = color);
            }),

            SizedBox(height: 20),

            // Concealer
            _buildSliderControl('Concealer Intensity', concealerIntensity, (value) {
              setState(() => concealerIntensity = value);
            }),
            _buildColorControl('Concealer Color', concealerColor, (color) {
              setState(() => concealerColor = color);
            }),

            SizedBox(height: 20),

            // Contour
            _buildSliderControl('Contour Intensity', contourIntensity, (value) {
              setState(() => contourIntensity = value);
            }),
            _buildColorControl('Contour Color', contourColor, (color) {
              setState(() => contourColor = color);
            }),

            SizedBox(height: 20),

            // Mascara
            // _buildSliderControl('Mascara Intensity', mascaraIntensity, (value) {
            //   setState(() => mascaraIntensity = value);
            // }),
            // _buildColorControl('Mascara Color', mascaraColor, (color) {
            //   setState(() => mascaraColor = color);
            // }),

            SizedBox(height: 20),

            // Contact Lenses
            _buildSliderControl('Lens Intensity', lensIntensity, (value) {
              setState(() => lensIntensity = value);
            }),
            _buildSliderControl('Lens Radius Scale', lensRadiusScale, (value) {
              setState(() => lensRadiusScale = value);
            }, min: 0.5, max: 2.0),
            _buildColorControl('Lens Color', lensColor, (color) {
              setState(() => lensColor = color);
            }),

            SizedBox(height: 20),

            // Bindi
            _buildColorControl('Bindi Color', bindiColor, (color) {
              setState(() => bindiColor = color);
            }),

            SizedBox(height: 20),

            // Mangtika (no color/intensity, just product_id)
            Text(
              'Mangtika will be applied based on selected product only',
              style: TextStyle(color: Colors.grey),
            ),
            // _buildSliderControl('Lipstick Intensity', lipstickIntensity, (value) {
            //   setState(() => lipstickIntensity = value);
            // }),
            // _buildColorControl('Lipstick Color', lipstickColor, (color) {
            //   setState(() => lipstickColor = color);
            // }),
            // _buildSliderControl('Blush Intensity', blushIntensity, (value) {
            //   setState(() => blushIntensity = value);
            // }),
            // _buildSliderControl('Blush Radius', blushRadius, (value) {
            //   setState(() => blushRadius = value);
            // }, min: 10, max: 100),
            // _buildColorControl('Blush Color', blushColor, (color) {
            //   setState(() => blushColor = color);
            // }),
            // _buildSliderControl('Eyeshadow Intensity', eyeshadowIntensity, (value) {
            //   setState(() => eyeshadowIntensity = value);
            // }),
            // _buildColorControl('Eyeshadow Color', eyeshadowColor, (color) {
            //   setState(() => eyeshadowColor = color);
            // }),
            // _buildSliderControl('Foundation Intensity', foundationIntensity, (value) {
            //   setState(() => foundationIntensity = value);
            // }),
            //
          ],
        ),
      ),
    );
  }

  Widget _buildSliderControl(String label, double value, Function(double) onChanged,
      {double min = 0.0, double max = 1.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.pink[800])),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            label: value.toStringAsFixed(2),
            activeColor: Colors.pink[400],
            inactiveColor: Colors.pink[100],
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildColorControl(String label, Color color, Function(Color) onChanged) {
    final colors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.pink[800])),
          SizedBox(height: 8),
          Container(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final c = colors[index];
                return GestureDetector(
                  onTap: () => onChanged(c),
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color == c ? Colors.pink[600]! : Colors.grey[300]!,
                        width: color == c ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyMakeupButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _uploadedImageId == null || _isLoading ? null : _applyMakeup,
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text('Apply Makeup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Result',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink[800],
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink[300]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_resultImage!, fit: BoxFit.cover),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveResult,
                    icon: Icon(Icons.download),
                    label: Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareResult,
                    icon: Icon(Icons.share),
                    label: Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _uploadedImageId = null;
        _resultImage = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images'));
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      request.fields['image_type'] = 'ORIGINAL';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(responseData);
        setState(() {
          _uploadedImageId = data['id'].toString();
        });
        print(_uploadedImageId);
        print(responseData);
        print(response);
        _showSnackBar('Image uploaded successfully!', Colors.green);
      } else {
        _showSnackBar('Failed to upload image', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final url =
          '$baseUrl/products/filter_products?category=$_selectedCategory&detailed_category=$_selectedDetailedCategory';
      print('Loading products from: $url');

      final response = await http.get(Uri.parse(url));
      print('Products response status: ${response.statusCode}');
      print('Products response body: ${response.body}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List;

        List<Product> products = [];

        for (var item in data) {
          if (item['products'] != null) {
            products.addAll(
              (item['products'] as List).map((p) => Product.fromJson(p)),
            );
          }
        }

        setState(() {
          _products = products;
          // _selectedProducts.clear();

          // Automatically select the first product if available
          // if (_products.isNotEmpty) {
          //   _selectedProducts.add(_products.first);
          // }
          for (var product in _products) {
            if (!_selectedProducts.contains(product)) {
              _selectedProducts.add(product);
            }
          }
        });

        if (products.isNotEmpty) {
          _showSnackBar('Loaded ${products.length} products successfully!', Colors.green);
        } else {
          _showSnackBar('No products found for this category', Colors.orange);
        }
      } else {
        _showSnackBar('Failed to load products. Status: ${response.statusCode}', Colors.red);
        print('Products API error: ${response.body}');
      }
    } catch (e) {
      _showSnackBar('Error loading products: $e', Colors.red);
      print('Exception in _loadProducts: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyMakeup() async {
    if (_uploadedImageId == null) {
      _showSnackBar('Please upload an image first', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get product IDs, use valid defaults if none selected
      // List<int> productIds = _selectedProducts
      //     .map((p) => p.id)
      //     .where((id) => id > 0)
      //     .toList();
      List<int> productIds = _selectedProducts.map((p) => p.id).toList();

      if (productIds.isEmpty && _products.isNotEmpty) {
        productIds = [_products.first.id];
      }

      print('Selected product IDs: $productIds');


      print('Selected product IDs: $productIds'); // Debug print

      final Map<String, dynamic> requestData = {
        "image_id": int.parse(_uploadedImageId!),
        "product_ids": productIds,
        "lipstick_intensity": lipstickIntensity,
        "lipstick_color": _colorToHex(lipstickColor),
        "blush_intensity": blushIntensity,
        "blush_radius": blushRadius.toInt(),
        "blush_color": _colorToHex(blushColor),
        "eyeshadow_intensity": eyeshadowIntensity,
        "eyeshadow_thickness": eyeshadowThickness.toInt(),
        "eyeshadow_color": _colorToHex(eyeshadowColor),
        "lens_intensity": lensIntensity,
        "lens_radius_scale": lensRadiusScale,
        "lens_color": _colorToHex(lensColor),
        "foundation_intensity": foundationIntensity,
        "foundation_color": _colorToHex(foundationColor),
        "kajal_intensity": kajalIntensity,
        "kajal_color": _colorToHex(kajalColor),
        "concealer_intensity": concealerIntensity,
        "concealer_color": _colorToHex(concealerColor),
        "contour_intensity": contourIntensity,
        "contour_color": _colorToHex(contourColor),
        // "bindi_size": bindiSize.toInt(),
        // "bindi_color": _colorToHex(bindiColor),
      };
// Handle Bindi (needs only color)
      if (_selectedDetailedCategory == "BINDI") {
        requestData["bindi_color"] = _colorToHex(bindiColor);


        requestData["bindi_size"] = bindiSize.toInt();
      }


// Handle Mangtika (only product_id, no extra params)
      if (_selectedDetailedCategory == "MANGTIKA") {
        // nothing extra needed, product_id already included
      }
      print('Request Data: ${jsonEncode(requestData)}'); // Debug print

      final response = await http.post(
        Uri.parse('$baseUrl/images/apply-makeup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "image_id": int.parse(_uploadedImageId!),
          "product_ids": [_products.first.id],
        }),
        // body: jsonEncode(requestData),
      );
      print('Response: ${response.statusCode} - ${response.body}');

      print('Response Status: ${response.statusCode}'); // Debug print
      print('Response Headers: ${response.headers}'); // Debug print
      print('Response Body Length: ${response.bodyBytes.length}'); // Debug print

      if (response.statusCode == 200 || response.statusCode == 201) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final jsonResponse = jsonDecode(response.body);
          print('Makeup JSON Response: $jsonResponse');
          String imageUrl =
              'https://www.happywedz.com/ai/api/images/${jsonResponse['processed_image_id']}';

          final imageResponse = await http.get(Uri.parse(imageUrl));

          if (imageResponse.statusCode == 200) {
            setState(() {
              _resultImage = imageResponse.bodyBytes;
            });
            _showSnackBar('Makeup applied successfully!', Colors.green);
          } else {
            _showSnackBar(
              'Failed to load processed image: ${imageResponse.statusCode}',
              Colors.red,
            );
          }
          print(imageResponse.statusCode);
          print(imageResponse);
          print(imageUrl);
        }
        //   final imageUrl = jsonResponse['url'];
        //   if (imageUrl != null) {
        //     final imageResponse = await http.get(Uri.parse(imageUrl));
        //     if (imageResponse.statusCode == 200) {
        //       setState(() {
        //         _resultImage = imageResponse.bodyBytes;
        //       });
        //       _showSnackBar('Makeup applied successfully!', Colors.green);
        //     } else {
        //       _showSnackBar(
        //         'Failed to load processed image: ${imageResponse.statusCode}',
        //         Colors.red,
        //       );
        //       print('Failed to load processed image: ${imageResponse.statusCode}');
        //     }
        //
        //     // if (imageResponse.statusCode == 200 &&
        //     //     imageResponse.headers['content-type']?.startsWith('image/') == true) {
        //     //   setState(() {
        //     //     _resultImage = imageResponse.bodyBytes;
        //     //   });
        //     //   _showSnackBar('Makeup applied successfully!', Colors.green);
        //     // } else {
        //     //   _showSnackBar('Failed to load processed image from server', Colors.red);
        //     // }
        //   } else {
        //     _showSnackBar('Processed image URL not found in response', Colors.red);
        //   }
        // } else {
        //   _showSnackBar('Unexpected content type in makeup response', Colors.red);
        // }
      }
      else {
        print(_products);
        print(response);
        print(response.statusCode);
        String errorMessage = 'Failed to apply makeup. Status: ${response.statusCode}';




        try {
          final errorResponse = jsonDecode(response.body);
          errorMessage += '\nError: ${errorResponse.toString()}';
          print('API Error Response: $errorResponse'); // Debug print
        } catch (e) {
          errorMessage += '\nResponse: ${response.body}';
        }
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      print('Exception in _applyMakeup: $e'); // Debug print
      _showSnackBar('Error applying makeup: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _colorToHex(Color color) {
    // Convert Flutter Color to hex string (ARGB to RGB)
    String hex = color.value.toRadixString(16).padLeft(8, '0');
    // Remove alpha channel and add # prefix
    return '#${hex.substring(2).toUpperCase()}';
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveResult() {
    // Implement save functionality
    _showSnackBar('Save functionality would be not implemented here', Colors.blue);
  }

  void _shareResult() {
    // Implement share functionality
    _showSnackBar('Share functionality would be not implemented here', Colors.blue);
  }
}










































































//
// class Product {
//   final int id;
//   final String name;
//   final String brand;
//   final String description;
//   final List<String> colors;
//
//   Product({
//     required this.id,
//     required this.name,
//     required this.brand,
//     required this.description,
//     required this.colors,
//   });
//
//   factory Product.fromJson(Map<String, dynamic> json) {
//     int parsedId = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0;
//     String parsedName = json['product_name'] ?? 'Unknown Product';
//     String parsedBrand = json['brand_name'] ?? '';
//     String parsedDescription = json['description'] ?? '';
//     List<String> parsedColors = [];
//
//     if (json['product_colors'] != null) {
//       parsedColors = List<String>.from(json['product_colors']);
//     }
//
//     print('Parsed Product: ID=$parsedId, Name=$parsedName'); // debug
//     return Product(
//       id: parsedId,
//       name: parsedName,
//       brand: parsedBrand,
//       description: parsedDescription,
//       colors: parsedColors,
//     );
//   }
// }











































class LancomeMakeupTryOnScreen extends StatefulWidget {
  @override
  _LancomeMakeupTryOnScreenState createState() => _LancomeMakeupTryOnScreenState();
}

class _LancomeMakeupTryOnScreenState extends State<LancomeMakeupTryOnScreen>
    with TickerProviderStateMixin {
  final String baseUrl = 'https://www.happywedz.com/ai/api';
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _uploadedImageId;
  Uint8List? _resultImage;
  List<Product> _products = [];
  List<Product> _selectedProducts = [];
  String _selectedCategory = 'MAKEUP';
  String _selectedDetailedCategory = 'LIPSTICK';
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Makeup parameters with elegant defaults
  double lipstickIntensity = 0.8;
  Color lipstickColor = Color(0xFFDC143C);
  double blushIntensity = 0.3;
  double blushRadius = 60;
  Color blushColor = Color(0xFFFFB6C1);
  double eyeshadowIntensity = 0.5;
  double eyeshadowThickness = 25;
  Color eyeshadowColor = Color(0xFF8B4B8A);
  double lensIntensity = 0.2;
  double lensRadiusScale = 1.3;
  Color lensColor = Color(0xFF4B9CD3);
  double foundationIntensity = 0.6;
  Color foundationColor = Color(0xFFF5D6C6);
  double kajalIntensity = 1.0;
  Color kajalColor = Colors.black;
  double concealerIntensity = 0.9;
  Color concealerColor = Color(0xFFFFDAB9);
  double contourIntensity = 0.3;
  Color contourColor = Color(0xFF8B4513);
  int bindiSize = 6;
  Color bindiColor = Colors.red;

  final List<String> categories = ['MAKEUP'];
  final List<String> detailedCategories = [
    'LIPSTICK', 'BLUSH', 'EYESHADOW', 'FOUNDATION', 'KAJAL', 'CONCEALER',
    'CONTOUR', 'MASCARA', 'CONTACTLENSES', 'BINDI', 'MANGTIKA'
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F0F5),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        SizedBox(height: 30),
                        _buildImageUploadSection(),
                        if (_uploadedImageId != null) ...[
                          SizedBox(height: 30),
                          _buildProductSection(),
                          SizedBox(height: 30),
                          _buildMakeupControlsSection(),
                          SizedBox(height: 30),
                          _buildApplyButton(),
                        ],
                        if (_resultImage != null) ...[
                          SizedBox(height: 30),
                          _buildResultSection(),
                        ],
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE91E63),
                Color(0xFFD81B60),
                Color(0xFFC2185B),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.face_retouching_natural,
                  size: 60,
                  color: Colors.white,
                ),
                SizedBox(height: 15),
                Text(
                  'VIRTUAL MAKEUP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  'TRY-ON EXPERIENCE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFFDF2F8),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Discover Your Perfect Look',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD81B60),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Text(
            'Experience luxury makeup virtually with our advanced AI technology. Upload your photo and try different looks instantly.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: Color(0xFFD81B60), size: 24),
              SizedBox(width: 10),
              Text(
                'Upload Your Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showImagePickerOptions(),
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _selectedImage != null
                    ? null
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFCE4EC),
                    Color(0xFFF8BBD9).withOpacity(0.3),
                    Color(0xFFFCE4EC),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(0xFFE91E63).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFE91E63).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      size: 50,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Tap to upload your photo',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFD81B60),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Supported formats: JPG, PNG',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImage != null && _uploadedImageId == null) ...[
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadImage,
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text('Processing...'),
                  ],
                )
                    : Text(
                  'Upload Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette, color: Color(0xFFD81B60), size: 24),
              SizedBox(width: 10),
              Text(
                'Select Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFE91E63).withOpacity(0.3)),
              color: Color(0xFFFCE4EC).withOpacity(0.3),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedDetailedCategory,
              decoration: InputDecoration(
                labelText: 'Product Category',
                labelStyle: TextStyle(color: Color(0xFFD81B60)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              items: detailedCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDetailedCategory = value!;
                });
                _loadProducts();
              },
            ),
          ),
          SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: _loadProducts,
              child: Text(
                'Load Products',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF06292),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
          if (_products.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(
              'Available Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD81B60),
              ),
            ),
            SizedBox(height: 15),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final isSelected = _selectedProducts.contains(product);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedProducts.remove(product);
                        } else {
                          _selectedProducts.add(product);
                        }
                      });
                    },
                    child: Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 15),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                        )
                            : LinearGradient(
                          colors: [Colors.white, Color(0xFFFCE4EC)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? Color(0xFFE91E63) : Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isSelected ? Color(0xFFE91E63) : Colors.grey).withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.brush,
                            color: isSelected ? Colors.white : Color(0xFFE91E63),
                            size: 35,
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : Color(0xFFD81B60),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMakeupControlsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Color(0xFFD81B60), size: 24),
              SizedBox(width: 10),
              Text(
                'Makeup Controls',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          SizedBox(height: 25),
          _buildSliderControl('Lipstick Intensity', lipstickIntensity, (value) {
            setState(() => lipstickIntensity = value);
          }),
          _buildColorControl('Lipstick Color', lipstickColor, (color) {
            setState(() => lipstickColor = color);
          }),
          SizedBox(height: 20),
          _buildSliderControl('Blush Intensity', blushIntensity, (value) {
            setState(() => blushIntensity = value);
          }),
          _buildSliderControl('Blush Radius', blushRadius, (value) {
            setState(() => blushRadius = value);
          }, min: 10, max: 100),
          _buildColorControl('Blush Color', blushColor, (color) {
            setState(() => blushColor = color);
          }),
          SizedBox(height: 20),
          _buildSliderControl('Eyeshadow Intensity', eyeshadowIntensity, (value) {
            setState(() => eyeshadowIntensity = value);
          }),
          _buildColorControl('Eyeshadow Color', eyeshadowColor, (color) {
            setState(() => eyeshadowColor = color);
          }),
          SizedBox(height: 20),
          _buildSliderControl('Foundation Intensity', foundationIntensity, (value) {
            setState(() => foundationIntensity = value);
          }),
          // Bindi Controls
          SizedBox(height: 20),
          _buildSliderControl(
            'Bindi Size',
            bindiSize.toDouble(),
                (value) {
              setState(() => bindiSize = value.toInt());
            },
            min: 1,
            max: 10,
          ),
          _buildColorControl('Bindi Color', bindiColor, (color) {
            setState(() => bindiColor = color);
          }),

        ],
      ),
    );
  }

  Widget _buildSliderControl(String label, double value, Function(double) onChanged,
      {double min = 0.0, double max = 1.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD81B60),
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Color(0xFFE91E63),
                    inactiveTrackColor: Color(0xFFE91E63).withOpacity(0.2),
                    thumbColor: Color(0xFFE91E63),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayColor: Color(0xFFE91E63).withOpacity(0.2),
                    trackHeight: 6,
                  ),
                  child: Slider(
                    value: value,
                    min: min,
                    max: max,
                    divisions: 20,
                    onChanged: onChanged,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Container(
                width: 50,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD81B60),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorControl(String label, Color color, Function(Color) onChanged) {
    final colors = [
      Color(0xFFDC143C), Color(0xFFFF69B4), Color(0xFFBA55D3), Color(0xFF9370DB),
      Color(0xFF4169E1), Color(0xFF00BFFF), Color(0xFF00CED1), Color(0xFF20B2AA),
      Color(0xFF32CD32), Color(0xFF9AFF9A), Color(0xFFFFFF00), Color(0xFFFFD700),
      Color(0xFFFFA500), Color(0xFFFF4500), Color(0xFFD2691E), Color(0xFF8B4513),
      Color(0xFF696969), Color(0xFF2F4F4F), Color(0xFF000000), Colors.white,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFFD81B60),
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((c) {
              final isSelected = color.value == c.value;
              return GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xFFD81B60) : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Color(0xFFE91E63).withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ] : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFD81B60)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE91E63).withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _uploadedImageId == null || _isLoading ? null : _applyMakeup,
        child: _isLoading
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 15),
            Text(
              'Applying Magic...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_fix_high, size: 24),
            SizedBox(width: 10),
            Text(
              'Apply Makeup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFD81B60), size: 24),
              SizedBox(width: 10),
              Text(
                'Your Stunning Result',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD81B60),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE91E63).withOpacity(0.2),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(_resultImage!, fit: BoxFit.cover),
            ),
          ),
          SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveResult,
                  icon: Icon(Icons.download),
                  label: Text('Save Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF06292),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareResult,
                  icon: Icon(Icons.share),
                  label: Text('Share Look'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Choose Photo Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD81B60),
                ),
              ),
              SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                      icon: Icon(Icons.photo_library, size: 24),
                      label: Text('Gallery', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF06292),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                      icon: Icon(Icons.camera_alt, size: 24),
                      label: Text('Camera', style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _uploadedImageId = null;
        _resultImage = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/images'));
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      request.fields['image_type'] = 'ORIGINAL';

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = jsonDecode(responseData);
        setState(() {
          _uploadedImageId = data['id'].toString();
        });





        print('Upload successful: $_uploadedImageId');
        _showSnackBar('Image uploaded successfully! ✨', Colors.green, Icons.check_circle);
      } else {
        _showSnackBar('Failed to upload image', Colors.red, Icons.error);
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e', Colors.red, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);

    try {
      final url = '$baseUrl/products/filter_products?category=$_selectedCategory&detailed_category=$_selectedDetailedCategory';
      print('Loading products from: $url');

      final response = await http.get(Uri.parse(url));
      print('Products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List;
        List<Product> products = [];

        for (var item in data) {
          if (item['products'] != null) {
            products.addAll(
              (item['products'] as List).map((p) => Product.fromJson(p)),
            );
          }
        }

        setState(() {
          _products = products;
          for (var product in _products) {
            if (!_selectedProducts.contains(product)) {
              _selectedProducts.add(product);
            }
          }
        });

        if (products.isNotEmpty) {
          _showSnackBar('Loaded ${products.length} products! 💄', Colors.green, Icons.palette);
        } else {
          _showSnackBar('No products found for this category', Colors.orange, Icons.info);
        }
      } else {
        _showSnackBar('Failed to load products', Colors.red, Icons.error);
      }
    } catch (e) {
      _showSnackBar('Error loading products: $e', Colors.red, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyMakeup() async {
    if (_uploadedImageId == null) {
      _showSnackBar('Please upload an image first', Colors.orange, Icons.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<int> productIds = _selectedProducts.map((p) => p.id).toList();

      if (productIds.isEmpty && _products.isNotEmpty) {
        productIds = [_products.first.id];
      }

      final Map<String, dynamic> requestData = {
        "image_id": int.parse(_uploadedImageId!),
        "product_ids": productIds,
        "lipstick_intensity": lipstickIntensity,
        "lipstick_color": _colorToHex(lipstickColor),
        "blush_intensity": blushIntensity,
        "blush_radius": blushRadius.toInt(),
        "blush_color": _colorToHex(blushColor),
        "eyeshadow_intensity": eyeshadowIntensity,
        "eyeshadow_thickness": eyeshadowThickness.toInt(),
        "eyeshadow_color": _colorToHex(eyeshadowColor),
        "lens_intensity": lensIntensity,
        "lens_radius_scale": lensRadiusScale,
        "lens_color": _colorToHex(lensColor),
        "foundation_intensity": foundationIntensity,
        "foundation_color": _colorToHex(foundationColor),
        "kajal_intensity": kajalIntensity,
        "kajal_color": _colorToHex(kajalColor),
        "concealer_intensity": concealerIntensity,
        "concealer_color": _colorToHex(concealerColor),
        "contour_intensity": contourIntensity,
        "contour_color": _colorToHex(contourColor),
        "bindi_size": bindiSize.toInt(),
        "bindi_color": _colorToHex(bindiColor),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/images/apply-makeup'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          final jsonResponse = jsonDecode(response.body);
          String imageUrl = 'https://www.happywedz.com/ai/api/images/${jsonResponse['processed_image_id']}';

          final imageResponse = await http.get(Uri.parse(imageUrl));

          if (imageResponse.statusCode == 200) {
            setState(() {
              _resultImage = imageResponse.bodyBytes;
            });
            print('Makeup applied successfully!');
            print(response);
            print(response.body);
            _showSnackBar('Makeup applied successfully! ✨', Colors.green, Icons.auto_fix_high);
          } else {
            _showSnackBar('Failed to load processed image', Colors.red, Icons.error);
          }
        }
      } else {
        String errorMessage = 'Failed to apply makeup. Status: ${response.statusCode}';
        _showSnackBar(errorMessage, Colors.red, Icons.error);
      }
    } catch (e) {
      _showSnackBar('Error applying makeup: $e', Colors.red, Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _colorToHex(Color color) {
    String hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 3),
      ),
    );
  }
  // Future<void> _saveResult() async {
  //   if (_resultImage == null) return;
  //
  //   // Request storage permission
  //   var status = await Permission.storage.request();
  //   if (!status.isGranted) {
  //     _showSnackBar('Storage permission is required', Colors.red, Icons.error);
  //     return;
  //   }
  //
  //   final result = await ImageGallerySaver.saveImage(
  //     Uint8List.fromList(_resultImage!), // Your image bytes
  //     quality: 100,
  //     name: "makeup_result_${DateTime.now().millisecondsSinceEpoch}",
  //   );
  //
  //   if (result['isSuccess']) {
  //     _showSnackBar('Saved to Gallery!', Colors.green, Icons.check);
  //   } else {
  //     _showSnackBar('Failed to save', Colors.red, Icons.error);
  //   }
  // }
  // Future<void> _shareResult() async {
  //   if (_resultImage == null) return;
  //
  //   // Save temporary file to share
  //   final tempDir = await getTemporaryDirectory();
  //   final file = await File('${tempDir.path}/result.png').create();
  //   await file.writeAsBytes(_resultImage!);
  //
  //   // Share image
  //   await Share.shareXFiles(
  //     [XFile(file.path)],
  //     text: 'Check out my new look!',
  //   );
  // }

  void _saveResult() {
    _showSnackBar('Save functionality will be not implemented here', Colors.blue, Icons.info);
  }

  void _shareResult() {

    _showSnackBar('Share functionality will be not implemented here', Colors.blue, Icons.info);
  }
 }

class Product {
  final int id;
  final String name;
  final String brand;
  final String description;
  final List<String> colors;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.description,
    required this.colors,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int parsedId = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0;
    String parsedName = json['product_name'] ?? 'Unknown Product';
    String parsedBrand = json['brand_name'] ?? '';
    String parsedDescription = json['description'] ?? '';
    List<String> parsedColors = [];

    if (json['product_colors'] != null) {
      parsedColors = List<String>.from(json['product_colors']);
    }

    return Product(
      id: parsedId,
      name: parsedName,
      brand: parsedBrand,
      description: parsedDescription,
      colors: parsedColors,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}



//
// class LancomeHomePage extends StatefulWidget {
//   const LancomeHomePage({super.key});
//
//   @override
//   State<LancomeHomePage> createState() => _LancomeHomePageState();
// }
//
// class _LancomeHomePageState extends State<LancomeHomePage>
//     with TickerProviderStateMixin {
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
//     );
//     _fadeController.forward();
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F8F8),
//       body: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: Column(
//             children: [
//               // Header
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const SizedBox(width: 40),
//                     Image.asset(
//                       'assets/lancome_logo.png',
//                       height: 40,
//                       errorBuilder: (context, error, stackTrace) {
//                         return const Text(
//                           'Try On',
//                           style: TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 2,
//                           ),
//                         );
//                       },
//                     ),
//                     const SizedBox(width: 40),
//                   ],
//                 ),
//               ),
//
//               // Main Content
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 40),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Hero Image
//                       Container(
//                         width: 300,
//                         height: 200,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(20),
//                           image: const DecorationImage(
//                             image: NetworkImage(
//                                 'https://via.placeholder.com/300x200/FFB6C1/FFFFFF?text=Beauty+Models'
//                             ),
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                         child: Stack(
//                           children: [
//                             Container(
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(20),
//                                 gradient: LinearGradient(
//                                   begin: Alignment.topCenter,
//                                   end: Alignment.bottomCenter,
//                                   colors: [
//                                     Colors.transparent,
//                                     Colors.pink.withOpacity(0.3),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       // Title
//                       const Text(
//                         'Virtual Try-On',
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF2C2C2C),
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       // Description
//                       const Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 20),
//                         child: Text(
//                           'For the best virtual try-on experience, please use Safari on iOS and Chrome on Android or make sure you have a strong wifi connection.',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Color(0xFF666666),
//                             height: 1.4,
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 40),
//
//                       // Button
//                       _buildActionButton(
//                         'UPLOAD PHOTO',
//                         Icons.upload,
//                             () => _navigateToMakeupScreen(context, false),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed) {
//     return SizedBox(
//       width: double.infinity,
//       height: 50,
//       child: ElevatedButton.icon(
//         onPressed: onPressed,
//         icon: Icon(icon, size: 20),
//         label: Text(
//           text,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             letterSpacing: 1,
//           ),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.pink,
//           foregroundColor: Colors.white,
//           elevation: 0,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _navigateToMakeupScreen(BuildContext context, bool useModel) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => VirtualMakeupScreen(useModel: useModel),
//       ),
//     );
//   }
// }
//
// class VirtualMakeupScreen extends StatefulWidget {
//   final bool useModel;
//   final String? modelImage;
//
//   const VirtualMakeupScreen({
//     super.key,
//     this.useModel = false,
//     this.modelImage,
//   });
//
//   @override
//   State<VirtualMakeupScreen> createState() => _VirtualMakeupScreenState();
// }
//
// class _VirtualMakeupScreenState extends State<VirtualMakeupScreen>
//     with TickerProviderStateMixin {
//   final MakeupApiService api = MakeupApiService();
//   File? selectedImage;
//   String? finalImageUrl;
//   String? currentImageUrl;
//   bool isLoading = false;
//   bool showComparison = false;
//   int selectedProductIndex = 0;
//   bool showShades = false;
//   List<MakeupProduct> products = [];
//
//   late AnimationController _slideController;
//   late Animation<Offset> _slideAnimation;
//   int? selectedImageId;
//
//   // final List<MakeupProduct> products = [
//   //   MakeupProduct('Foundation', Icons.face, 0, [
//   //     ShadeColor('#F5DEB3', 'Fair'),
//   //     ShadeColor('#F0D0A0', 'Light'),
//   //     ShadeColor('#E8C4A0', 'Light Medium'),
//   //     ShadeColor('#D2B48C', 'Medium'),
//   //     ShadeColor('#C19A6B', 'Medium Deep'),
//   //     ShadeColor('#A0522D', 'Deep'),
//   //     ShadeColor('#8B4513', 'Rich'),
//   //     ShadeColor('#654321', 'Very Deep'),
//   //   ]),
//   //   MakeupProduct('Concealer', Icons.brush, 1, [
//   //     ShadeColor('#FFDAB9', 'Porcelain'),
//   //     ShadeColor('#F5DEB3', 'Ivory'),
//   //     ShadeColor('#F0D0A0', 'Light'),
//   //     ShadeColor('#E8C4A0', 'Medium'),
//   //     ShadeColor('#D2B48C', 'Tan'),
//   //     ShadeColor('#C19A6B', 'Deep'),
//   //     ShadeColor('#A0522D', 'Rich'),
//   //   ]),
//   //   MakeupProduct('Blush', Icons.favorite_border, 2, [
//   //     ShadeColor('#FFE4E1', 'Baby Pink'),
//   //     ShadeColor('#FFB6C1', 'Rose Pink'),
//   //     ShadeColor('#F08080', 'Coral'),
//   //     ShadeColor('#FA8072', 'Salmon'),
//   //     ShadeColor('#CD5C5C', 'Berry'),
//   //     ShadeColor('#DC143C', 'Cherry'),
//   //     ShadeColor('#B22222', 'Deep Rose'),
//   //   ]),
//   //   MakeupProduct('Contour', Icons.face, 3, [
//   //     ShadeColor('#DEB887', 'Light'),
//   //     ShadeColor('#D2B48C', 'Medium'),
//   //     ShadeColor('#BC9A6A', 'Medium Deep'),
//   //     ShadeColor('#A0522D', 'Deep'),
//   //     ShadeColor('#8B4513', 'Rich'),
//   //     ShadeColor('#654321', 'Very Deep'),
//   //   ]),
//   //   MakeupProduct('Eyeshadow', Icons.remove_red_eye, 4, [
//   //     ShadeColor('#F5F5DC', 'Champagne'),
//   //     ShadeColor('#DDA0DD', 'Plum'),
//   //     ShadeColor('#D8BFD8', 'Thistle'),
//   //     ShadeColor('#9370DB', 'Medium Slate Blue'),
//   //     ShadeColor('#8A2BE2', 'Blue Violet'),
//   //     ShadeColor('#4B0082', 'Indigo'),
//   //     ShadeColor('#800080', 'Purple'),
//   //     ShadeColor('#654321', 'Bronze'),
//   //     ShadeColor('#8B4513', 'Brown'),
//   //   ]),
//   //   MakeupProduct('Kajal', Icons.create, 5, [
//   //     ShadeColor('#000000', 'Black'),
//   //     ShadeColor('#2F4F4F', 'Dark Slate Gray'),
//   //     ShadeColor('#696969', 'Dim Gray'),
//   //     ShadeColor('#8B4513', 'Saddle Brown'),
//   //     ShadeColor('#4B0082', 'Indigo'),
//   //     ShadeColor('#191970', 'Midnight Blue'),
//   //   ]),
//   //   MakeupProduct('Mascara', Icons.brush_outlined, 6, [
//   //     ShadeColor('#000000', 'Black'),
//   //     ShadeColor('#2F4F4F', 'Charcoal'),
//   //     ShadeColor('#8B4513', 'Brown'),
//   //     ShadeColor('#A0522D', 'Sienna'),
//   //     ShadeColor('#4B0082', 'Purple'),
//   //     ShadeColor('#191970', 'Navy'),
//   //   ]),
//   //   MakeupProduct('Lipstick', Icons.favorite, 7, [
//   //     ShadeColor('#FFE4E1', 'Nude Pink'),
//   //     ShadeColor('#FFB6C1', 'Light Pink'),
//   //     ShadeColor('#FF69B4', 'Hot Pink'),
//   //     ShadeColor('#DC143C', 'Crimson'),
//   //     ShadeColor('#B22222', 'Fire Brick'),
//   //     ShadeColor('#8B0000', 'Dark Red'),
//   //     ShadeColor('#4B0082', 'Purple'),
//   //     ShadeColor('#FF1493', 'Deep Pink'),
//   //     ShadeColor('#CD853F', 'Peru'),
//   //     ShadeColor('#A0522D', 'Brown'),
//   //   ]),
//   //   MakeupProduct('Lenses', Icons.visibility, 8, [
//   //     ShadeColor('#87CEEB', 'Sky Blue'),
//   //     ShadeColor('#4682B4', 'Steel Blue'),
//   //     ShadeColor('#4169E1', 'Royal Blue'),
//   //     ShadeColor('#0000FF', 'Blue'),
//   //     ShadeColor('#228B22', 'Forest Green'),
//   //     ShadeColor('#32CD32', 'Lime Green'),
//   //     ShadeColor('#8B4513', 'Hazel'),
//   //     ShadeColor('#A0522D', 'Brown'),
//   //     ShadeColor('#2F4F4F', 'Gray'),
//   //   ]),
//   // ];
//
//   @override
//   void initState() {
//     super.initState();
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 1),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(
//       parent: _slideController,
//       curve: Curves.easeOut,
//     ));
//
//     _loadProducts();
//
//     if (widget.useModel && widget.modelImage != null) {
//       currentImageUrl = widget.modelImage;
//     }
//   }
//
//   Future<void> _loadProducts() async {
//     setState(() => isLoading = true);
//     try {
//       products = await api.fetchProducts('MAKEUP', 'ALL'); // or specific categories
//       if (products.isNotEmpty) {
//         selectedProductIndex = products[0].index;
//       }
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//
//   @override
//   void dispose() {
//     _slideController.dispose();
//     super.dispose();
//   }
//
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final picked = await picker.pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() {
//         selectedImage = File(picked.path);
//         finalImageUrl = null;
//         showComparison = false;
//         showShades = false;
//       });
//
//       // Upload the image and store the ID
//       selectedImageId = await api.uploadImage(selectedImage!);
//     }
//   }
//
//   Future<void> processMakeup() async {
//     if (selectedImage == null && !widget.useModel) {
//       _showSnackBar('Please select an image.');
//       return;
//     }
//
//     setState(() => isLoading = true);
//
//     try {
//       if (widget.useModel) {
//         await Future.delayed(const Duration(seconds: 2));
//         setState(() {
//           finalImageUrl = 'https://via.placeholder.com/300x400/FFB6C1/FFFFFF?text=Makeup+Applied';
//           showComparison = true;
//         });
//       } else {
//         // Upload image and get ID
//         int? imageId = await api.uploadImage(selectedImage!);
//         if (imageId == null) {
//           _showSnackBar('Image upload failed.');
//           return;
//         }
//         selectedImageId = imageId; // store for future shade applications
//
//         // Build dynamic params map
//         final params = {
//           "image_id": imageId,
//           "product_ids": [products[selectedProductIndex].index],
//           // Default to the first shade of selected product
//           "${products[selectedProductIndex].name.toLowerCase()}_color": products[selectedProductIndex].shades[0].colorCode,
//           "${products[selectedProductIndex].name.toLowerCase()}_intensity": 0.8,
//         };
//
//         // Apply makeup dynamically
//         String? url = await api.applyMakeup(params);
//
//         setState(() {
//           finalImageUrl = url;
//           showComparison = url != null;
//         });
//
//         if (url == null) {
//           _showSnackBar('Makeup application failed.');
//         }
//       }
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.pink,
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   IconButton(
//                     icon: const Icon(Icons.home, color: Colors.white),
//                     onPressed: () => Navigator.popUntil(
//                       context,
//                           (route) => route.isFirst,
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   IconButton(
//                     icon: const Icon(Icons.help_outline, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.search, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                   const SizedBox(width: 16),
//                   IconButton(
//                     icon: const Icon(Icons.share, color: Colors.white),
//                     onPressed: () {},
//                   ),
//                   const SizedBox(width: 16),
//                   IconButton(
//                     icon: const Icon(Icons.close, color: Colors.white),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Main Image Area
//             Expanded(
//               child: Stack(
//                 children: [
//                   Center(
//                     child: Container(
//                       width: MediaQuery.of(context).size.width * 0.8,
//                       height: MediaQuery.of(context).size.height * 0.6,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         color: Colors.grey[200],
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(20),
//                         child: _buildMainImage(),
//                       ),
//                     ),
//                   ),
//
//                   // Loading Overlay
//                   if (isLoading)
//                     Container(
//                       color: Colors.pink.withOpacity(0.7),
//                       child: const Center(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             CircularProgressIndicator(color: Colors.white),
//                             SizedBox(height: 16),
//                             Text(
//                               'Applying makeup...',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//
//             // Product Selection
//             Container(
//               height: 120,
//               padding: const EdgeInsets.symmetric(vertical: 16),
//               child: SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Row(
//                   children: products.map((product) {
//                     bool isSelected = selectedProductIndex == product.index;
//                     return Container(
//                       margin: const EdgeInsets.only(right: 16),
//                       child: GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             selectedProductIndex = product.index;
//                             showShades = true;
//                           });
//                           _slideController.forward();
//                         },
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 50,
//                               height: 50,
//                               decoration: BoxDecoration(
//                                 color: isSelected ? Colors.white : Colors.grey[800],
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: isSelected
//                                     ? Border.all(color: Colors.pink, width: 2)
//                                     : null,
//                               ),
//                               child: Icon(
//                                 product.icon,
//                                 color: isSelected ? Colors.pink : Colors.white,
//                                 size: 24,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             SizedBox(
//                               width: 60,
//                               child: Text(
//                                 product.name.toUpperCase(),
//                                 style: TextStyle(
//                                   color: isSelected ? Colors.white : Colors.grey[400],
//                                   fontSize: 9,
//                                   fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//                                 ),
//                                 textAlign: TextAlign.center,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//
//             // Bottom Controls
//             Container(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   if (showComparison && finalImageUrl != null)
//                     Expanded(
//                       child: Container(
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: () {
//                             setState(() {
//                               showShades = !showShades;
//                               if (showShades) {
//                                 _slideController.forward();
//                               } else {
//                                 _slideController.reverse();
//                               }
//                             });
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.pink,
//                             foregroundColor: Colors.white,
//                             side: const BorderSide(color: Colors.white),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(25),
//                             ),
//                           ),
//                           child: Text(showShades ? 'HIDE SHADES' : 'SHADES'),
//                         ),
//                       ),
//                     ),
//                   if (showComparison && finalImageUrl != null)
//                     const SizedBox(width: 16),
//                   Expanded(
//                     child: Container(
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: widget.useModel ? processMakeup : (selectedImage == null ? pickImage : processMakeup),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: Colors.pink,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(25),
//                           ),
//                         ),
//                         child: Text(
//                           widget.useModel ? 'APPLY MAKEUP' :
//                           (selectedImage == null ? 'UPLOAD PHOTO' : 'TRY ON'),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Shades Panel
//             if (showShades)
//               SlideTransition(
//                 position: _slideAnimation,
//                 child: _buildShadesPanel(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildShadesPanel() {
//     final selectedProduct = products[selectedProductIndex];
//
//     return Container(
//       height: 250,
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(25),
//           topRight: Radius.circular(25),
//         ),
//       ),
//       child: Column(
//         children: [
//           // Handle bar
//           Container(
//             margin: const EdgeInsets.only(top: 8),
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey[300],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//
//           // Header
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   '${selectedProduct.name} Shades',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black,
//                   ),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       showShades = false;
//                     });
//                     _slideController.reverse();
//                   },
//                   icon: const Icon(Icons.close),
//                 ),
//               ],
//             ),
//           ),
//
//           // Shades Grid
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: GridView.builder(
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: selectedProduct.shades.length > 6 ? 5 : 4,
//                   childAspectRatio: 0.8,
//                   crossAxisSpacing: 8,
//                   mainAxisSpacing: 8,
//                 ),
//                 itemCount: selectedProduct.shades.length,
//                 itemBuilder: (context, index) {
//                   final shade = selectedProduct.shades[index];
//                   return GestureDetector(
//                     onTap: () {
//                       _applyShade(shade);
//                     },
//                     child: Column(
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: Container(
//                             decoration: BoxDecoration(
//                               color: Color(int.parse('0xFF${shade.colorCode.substring(1)}')),
//                               shape: BoxShape.circle,
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.2),
//                                   blurRadius: 4,
//                                   spreadRadius: 1,
//                                 ),
//                               ],
//                               border: Border.all(
//                                 color: Colors.white,
//                                 width: 2,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Expanded(
//                           flex: 2,
//                           child: Text(
//                             shade.name,
//                             style: const TextStyle(
//                               fontSize: 9,
//                               fontWeight: FontWeight.w500,
//                               color: Colors.black54,
//                             ),
//                             textAlign: TextAlign.center,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _applyShade(ShadeColor shade) async {
//     if (selectedImage == null && !widget.useModel) return;
//
//     setState(() => isLoading = true);
//
//     try {
//       final params = {
//         "image_id": selectedImageId,
//         "product_ids": [products[selectedProductIndex].index],
//         "${products[selectedProductIndex].name.toLowerCase()}_color": shade.colorCode,
//         "${products[selectedProductIndex].name.toLowerCase()}_intensity": 0.8, // default intensity
//       };
//
//       finalImageUrl = await api.applyMakeup(params);
//       showComparison = finalImageUrl != null;
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//
//   Future<void> _applyMakeupWithShade(ShadeColor shade) async {
//     if (selectedImage == null && !widget.useModel) return;
//
//     setState(() => isLoading = true);
//
//     try {
//       if (widget.useModel) {
//         await Future.delayed(const Duration(seconds: 2));
//         setState(() {
//           finalImageUrl = 'https://via.placeholder.com/300x400/${shade.colorCode.substring(1)}/FFFFFF?text=Makeup+${shade.name}';
//           showComparison = true;
//         });
//       } else {
//         int? imageId = await api.uploadImage(selectedImage!);
//         if (imageId == null) {
//           _showSnackBar('Image upload failed.');
//           return;
//         }
//
//         String? url = await api.applyMakeupWithCustomColor(imageId, selectedProductIndex, shade.colorCode);
//         setState(() {
//           finalImageUrl = url;
//           showComparison = url != null;
//         });
//
//         if (url == null) {
//           _showSnackBar('Makeup application failed.');
//         }
//       }
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   Widget _buildMainImage() {
//     if (showComparison && finalImageUrl != null) {
//       return Stack(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _buildImageSide(
//                   _getBeforeImageProvider(),
//                   isLeft: true,
//                 ),
//               ),
//               Container(
//                 width: 2,
//                 color: Colors.white,
//                 child: const Center(
//                   child: Icon(
//                     Icons.compare_arrows,
//                     color: Colors.white,
//                     size: 30,
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: _buildImageSide(
//                   NetworkImage(finalImageUrl!),
//                   isLeft: false,
//                 ),
//               ),
//             ],
//           ),
//           Positioned(
//             bottom: 16,
//             left: 0,
//             right: 0,
//             child: Container(
//               margin: const EdgeInsets.symmetric(horizontal: 20),
//               padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: Colors.pink.withOpacity(0.8),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: const Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Text(
//                     'BEFORE',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'AFTER',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       );
//     } else if (finalImageUrl != null) {
//       return Image.network(
//         finalImageUrl!,
//         fit: BoxFit.cover,
//         width: double.infinity,
//         height: double.infinity,
//       );
//     } else if (widget.useModel && currentImageUrl != null) {
//       return Image.network(
//         currentImageUrl!,
//         fit: BoxFit.cover,
//         width: double.infinity,
//         height: double.infinity,
//       );
//     } else if (selectedImage != null) {
//       return Image.file(
//         selectedImage!,
//         fit: BoxFit.cover,
//         width: double.infinity,
//         height: double.infinity,
//       );
//     } else {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.face,
//               size: 80,
//               color: Colors.grey,
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Upload a photo to get started',
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   ImageProvider<Object>? _getBeforeImageProvider() {
//     if (widget.useModel && currentImageUrl != null) {
//       return NetworkImage(currentImageUrl!);
//     } else if (selectedImage != null) {
//       return FileImage(selectedImage!);
//     }
//     return null;
//   }
//
//   Widget _buildImageSide(ImageProvider<Object>? imageProvider, {required bool isLeft}) {
//     return ClipRect(
//       child: Container(
//         width: double.infinity,
//         height: double.infinity,
//         child: imageProvider != null
//             ? Image(
//           image: imageProvider,
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//         )
//             : Container(
//           color: Colors.grey[300],
//           child: const Center(
//             child: Icon(Icons.person, size: 50),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class MakeupProduct {
//   final String name;
//   final IconData icon;
//   final int index;
//   final List<ShadeColor> shades;
//
//   MakeupProduct(this.name, this.icon, this.index, this.shades);
// }
//
// class ShadeColor {
//   final String colorCode;
//   final String name;
//
//   ShadeColor(this.colorCode, this.name);
// }
//
// class MakeupApiService {
//   final String baseUrl = "http://69.62.85.170:5001/api";
//   /// Upload image and return image ID
//   Future<int?> uploadImage(File imageFile) async {
//     var request = http.MultipartRequest('POST', Uri.parse("$baseUrl/images"));
//     request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
//     request.fields['image_type'] = "ORIGINAL";
//
//     try {
//       var response = await request.send();
//       var body = await response.stream.bytesToString();
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         var data = json.decode(body);
//         return data["id"];
//       }
//       return null;
//     } catch (e) {
//       print("Upload error: $e");
//       return null;
//     }
//   }
//
//   /// Apply makeup dynamically
//   Future<String?> applyMakeup(Map<String, dynamic> params) async {
//     var response = await http.post(
//       Uri.parse("$baseUrl/images/apply-makeup"),
//       headers: {"Content-Type": "application/json"},
//       body: json.encode(params),
//     );
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       var data = json.decode(response.body);
//       return data["url"];
//     }
//     return null;
//   }
//   /// Fetch products by category and detailed category
//   Future<List<MakeupProduct>> fetchProducts(String category, String detailedCategory) async {
//     final response = await http.get(Uri.parse("$baseUrl/products/filter_products?category=$category&detailed_category=$detailedCategory"));
//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       // Map API products to MakeupProduct
//       return List<MakeupProduct>.from(data.map((item) {
//         final shades = List<ShadeColor>.from(item['shades'].map((s) => ShadeColor(s['color'], s['name'])));
//         return MakeupProduct(item['name'], Icons.brush, item['id'], shades);
//       }));
//     }
//     return [];
//   }
//
//   Future<String?> applyMakeupWithCustomColor(int imageId, int productType, String colorCode) async {
//     int validProductId = 1;
//
//     Map<String, dynamic> makeupParams = {
//       "image_id": imageId,
//       "product_ids": [validProductId],
//       "lipstick_intensity": 0.8,
//       "lipstick_color": "#B22222",
//       "blush_intensity": 0.2,
//       "blush_radius": 60,
//       "blush_color": "#F08080",
//       "eyeshadow_intensity": 0.4,
//       "eyeshadow_thickness": 25,
//       "eyeshadow_color": "#9370DB",
//       "lens_intensity": 0.2,
//       "lens_radius_scale": 1.3,
//       "lens_color": "#4B9CD3",
//       "foundation_intensity": 0.6,
//       "foundation_color": "#F5D6C6",
//       "kajal_intensity": 1.0,
//       "kajal_color": "#000000",
//       "concealer_intensity": 0.9,
//       "concealer_color": "#FFDAB9",
//       "contour_intensity": 0.3,
//       "contour_color": "#8B4513",
//       "bindi_size": 6,
//       "bindi_color": "#FF0000"
//     };
//
//     // Apply selected shade based on product type
//     switch (productType) {
//       case 0: // Foundation
//         makeupParams["foundation_color"] = colorCode;
//         makeupParams["foundation_intensity"] = 0.8;
//         break;
//       case 1: // Concealer
//         makeupParams["concealer_color"] = colorCode;
//         makeupParams["concealer_intensity"] = 0.9;
//         break;
//       case 2: // Blush
//         makeupParams["blush_color"] = colorCode;
//         makeupParams["blush_intensity"] = 0.6;
//         break;
//       case 3: // Contour
//         makeupParams["contour_color"] = colorCode;
//         makeupParams["contour_intensity"] = 0.5;
//         break;
//       case 4: // Eyeshadow
//         makeupParams["eyeshadow_color"] = colorCode;
//         makeupParams["eyeshadow_intensity"] = 0.7;
//         break;
//       case 5: // Kajal
//         makeupParams["kajal_color"] = colorCode;
//         makeupParams["kajal_intensity"] = 1.0;
//         break;
//       case 6: // Mascara (using kajal parameters for now)
//         makeupParams["kajal_color"] = colorCode;
//         makeupParams["kajal_intensity"] = 0.8;
//         break;
//       case 7: // Lipstick
//         makeupParams["lipstick_color"] = colorCode;
//         makeupParams["lipstick_intensity"] = 0.9;
//         break;
//       case 8: // Contact Lenses
//         makeupParams["lens_color"] = colorCode;
//         makeupParams["lens_intensity"] = 0.7;
//         makeupParams["lens_radius_scale"] = 1.2;
//         break;
//     }
//
//     var response = await http.post(
//       Uri.parse("$baseUrl/images/apply-makeup"),
//       headers: {"Content-Type": "application/json"},
//       body: json.encode(makeupParams),
//     );
//
//     print("⬅️ Apply custom color response: ${response.statusCode} ${response.body}");
//
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       var data = json.decode(response.body);
//       return data["url"];
//     }
//
//     print("❌ Server failed with status: ${response.statusCode}");
//     return null;
//   }
//
//
//
//
// }