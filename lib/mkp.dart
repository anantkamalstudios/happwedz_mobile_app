import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:happy_wedz/core/config/api_config.dart';

class LancomeMakeupTryOnScreen13 extends StatefulWidget {
  @override
  _LancomeMakeupTryOnScreen13State createState() => _LancomeMakeupTryOnScreen13State();
}

class _LancomeMakeupTryOnScreen13State extends State<LancomeMakeupTryOnScreen13> {
  final String baseUrl = '${ApiConfig.baseUrl}/ai/api';
  final ImagePicker _picker = ImagePicker();
  double beforeAfterValue = 0.5;
  File? _selectedImage;
  String? _uploadedImageId;
  Uint8List? _resultImage;

  List<Product> _products = [];
  Product? _selectedProduct; // Only one product at a time
  String _selectedCategory = 'MAKEUP';
  String _selectedDetailedCategory = 'LIPSTICK';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F0F5),
      appBar: AppBar(
        title: Text('Virtual Makeup Try-On'),
        backgroundColor: Color(0xFFD81B60),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildImageUploadSection(),
            SizedBox(height: 30),
            if (_uploadedImageId != null) _buildProductSection(),
            SizedBox(height: 30),
            if (_resultImage != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _selectedImage == null
              ? LinearGradient(colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD9)])
              : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE91E63).withValues(alpha: 0.3), width: 2),
        ),
        child: _selectedImage != null
            ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_selectedImage!, fit: BoxFit.cover))
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 50, color: Color(0xFFE91E63)),
            SizedBox(height: 10),
            Text('Tap to upload your photo', style: TextStyle(fontSize: 16, color: Color(0xFFD81B60))),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSection() {
    if (_products.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Product & Shade', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFD81B60))),
        SizedBox(height: 15),
        Container(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              final isSelected = _selectedProduct?.id == product.id;

              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 10, offset: Offset(0, 5))],
                  border: Border.all(color: isSelected ? Color(0xFFD81B60) : Colors.grey.withValues(alpha: 0.3), width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFD81B60))),
                    SizedBox(height: 10),
                    if (product.colors.isNotEmpty)
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: product.colors.length,
                          itemBuilder: (context, cIndex) {
                            final color = _hexToColor(product.colors[cIndex]);
                            final isColorSelected = isSelected;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProduct = product;
                                });
                                _applyMakeup(); // Live apply on selection
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4),
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isColorSelected ? Color(0xFFD81B60) : Colors.grey.withValues(alpha: 0.3), width: isColorSelected ? 3 : 1),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    if (_selectedImage == null || _resultImage == null) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your Virtual Try-On', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFFD81B60))),
        SizedBox(height: 20),
        Container(
          height: 400,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BeforeAfter(
              value: beforeAfterValue, // double between 0.0 and 1.0
              before: Image.file(_selectedImage!, fit: BoxFit.cover),
              after: Image.memory(_resultImage!, fit: BoxFit.cover),
              onValueChanged: (newValue) {
                setState(() {
                  beforeAfterValue = newValue; // update slider position
                });
              },
            )

          ),

        ),
      ],
    );
  }

  // --- Image Picker ---
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                icon: Icon(Icons.photo_library),
                label: Text('Gallery'),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _uploadedImageId = null;
        _resultImage = null;
      });
      _uploadImage();
    }
  }

  // --- API Calls ---
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
        setState(() => _uploadedImageId = data['id'].toString());
        _loadProducts();
      }
    } catch (e) {
      debugPrint('Upload error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final url = '$baseUrl/products/filter_products?category=$_selectedCategory&detailed_category=$_selectedDetailedCategory';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body) as List;
        List<Product> products = [];
        for (var item in data) {
          if (item['products'] != null) {
            products.addAll((item['products'] as List).map((p) => Product.fromJson(p)));
          }
        }
        setState(() => _products = products);
      }
    } catch (e) {
      debugPrint('Load products error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyMakeup() async {
    if (_uploadedImageId == null || _selectedProduct == null) return;
    setState(() => _isLoading = true);

    try {
      final requestData = {
        "image_id": int.parse(_uploadedImageId!),
        "product_ids": [_selectedProduct!.id],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/images/apply-makeup'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        String imageUrl = '$baseUrl/images/${jsonResponse['processed_image_id']}';
        final imageResponse = await http.get(Uri.parse(imageUrl));
        if (imageResponse.statusCode == 200) {
          setState(() => _resultImage = imageResponse.bodyBytes);
        }
      }
    } catch (e) {
      debugPrint('Apply makeup error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    if (hex.length == 6) hex = "FF$hex";
    return Color(int.parse(hex, radix: 16));
  }
}

// --- Product Model ---
class Product {
  final int id;
  final String name;
  final List<String> colors;

  Product({required this.id, required this.name, required this.colors});

  factory Product.fromJson(Map<String, dynamic> json) {
    int parsedId = json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '') ?? 0;
    String parsedName = json['product_name'] ?? 'Unknown';
    List<String> parsedColors = [];
    if (json['product_colors'] != null) parsedColors = List<String>.from(json['product_colors']);
    return Product(id: parsedId, name: parsedName, colors: parsedColors);
  }
}
