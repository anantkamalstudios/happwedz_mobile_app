import 'package:flutter/material.dart';
import 'package:happy_wedz/core/config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LancomeMakeupTryOnScreen1 extends StatefulWidget {
  @override
  _LancomeMakeupTryOnScreen1State createState() => _LancomeMakeupTryOnScreen1State();
}

class _LancomeMakeupTryOnScreen1State extends State<LancomeMakeupTryOnScreen1>
    with TickerProviderStateMixin {
  final String baseUrl = '${ApiConfig.baseUrl}/ai/api';
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String? _uploadedImageId;
  Uint8List? _resultImage;
  List<Product> _products = [];
  List<Product> _selectedProducts = [];
  String _selectedCategory = 'MAKEUP';
  String _selectedDetailedCategory = 'LIPSTICK';
  bool _isLoading = false;
  bool _showBeforeAfter = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Makeup parameters - Lancôme style defaults
  double lipstickIntensity = 0.85;
  Color lipstickColor = Color(0xFFE91E63);
  double blushIntensity = 0.35;
  double blushRadius = 55;
  Color blushColor = Color(0xFFFFB6C1);
  double eyeshadowIntensity = 0.6;
  double eyeshadowThickness = 28;
  Color eyeshadowColor = Color(0xFFDDA0DD);
  double lensIntensity = 0.15;
  double lensRadiusScale = 1.2;
  Color lensColor = Color(0xFF87CEEB);
  double foundationIntensity = 0.7;
  Color foundationColor = Color(0xFFFFF5EE);
  double kajalIntensity = 0.95;
  Color kajalColor = Colors.black;
  double concealerIntensity = 0.85;
  Color concealerColor = Color(0xFFFFE4E1);
  double contourIntensity = 0.25;
  Color contourColor = Color(0xFFCD853F);
  int bindiSize = 5;
  Color bindiColor = Color(0xFFE91E63);

  final List<String> categories = ['MAKEUP'];
  final List<String> detailedCategories = [
    'LIPSTICK', 'BLUSH', 'EYESHADOW', 'FOUNDATION', 'KAJAL', 'CONCEALER',
    'CONTOUR', 'MASCARA', 'CONTACTLENSES', 'BINDI', 'MANGTIKA'
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildLancomeSliverAppBar(),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          _buildLancomeHeroSection(),
                          SizedBox(height: 24),
                          _buildLancomeImageSection(),
                          if (_uploadedImageId != null) ...[
                            SizedBox(height: 24),
                            _buildLancomeProductSelector(),
                            SizedBox(height: 24),
                            _buildLancomeCustomizationPanel(),
                            SizedBox(height: 30),
                            _buildLancomeApplyButton(),
                          ],
                          if (_resultImage != null) ...[
                            SizedBox(height: 30),
                            _buildLancomeResultSection(),
                          ],
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLancomeSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Color(0xFFFF69B4),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LANCÔME',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'VIRTUAL MAKEUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF69B4),
                Color(0xFFFF1493),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLancomeHeroSection() {
    return Container(
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF69B4).withValues(alpha: 0.2),
            blurRadius: 25,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.face_retouching_natural_outlined,
            size: 48,
            color: Color(0xFFFF1493),
          ),
          SizedBox(height: 16),
          Text(
            'TRY ON MAKEUP VIRTUALLY',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF1493),
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Discover your perfect look with our AI-powered virtual makeup try-on. Upload your photo and experiment with different makeup styles instantly.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLancomeImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB6C1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt, color: Color(0xFFFF1493), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'UPLOAD YOUR PHOTO',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF1493),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          GestureDetector(
            onTap: _showLancomeImagePicker,
            child: Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _selectedImage != null
                    ? null
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFE4E1),
                    Color(0xFFFFB6C1).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFFFF69B4).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(_selectedImage!, fit: BoxFit.cover),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF69B4).withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 56,
                      color: Color(0xFFFF1493),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'TAP TO SELECT PHOTO',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFFF1493),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'JPG or PNG format',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImage != null && _uploadedImageId == null) ...[
            SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadImage,
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('UPLOADING...', style: TextStyle(letterSpacing: 1)),
                  ],
                )
                    : Text(
                  'UPLOAD & CONTINUE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF1493),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLancomeProductSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB6C1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, color: Color(0xFFFF1493), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'SELECT MAKEUP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF1493),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFFFFE4E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFFF69B4).withValues(alpha: 0.3)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedDetailedCategory,
              decoration: InputDecoration(
                labelText: 'Makeup Category',
                labelStyle: TextStyle(
                  color: Color(0xFFFF1493),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              dropdownColor: Colors.white,
              items: detailedCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF1493),
                    ),
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
          SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: Icon(Icons.refresh, size: 20),
              label: Text(
                'LOAD PRODUCTS',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF69B4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          if (_products.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(
              'Available Products',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF1493),
              ),
            ),
            SizedBox(height: 12),
            Container(
              height: 110,
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
                      width: 90,
                      margin: EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                          colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : LinearGradient(
                          colors: [Colors.white, Color(0xFFFFE4E1)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFFFF1493)
                              : Color(0xFFFFB6C1).withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isSelected ? Color(0xFFFF1493) : Colors.grey)
                                .withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.brush_outlined,
                            color: isSelected ? Colors.white : Color(0xFFFF1493),
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              product.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Color(0xFFFF1493),
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

  Widget _buildLancomeCustomizationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB6C1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune_outlined, color: Color(0xFFFF1493), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'CUSTOMIZE MAKEUP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF1493),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildLancomeSlider('Lipstick Intensity', lipstickIntensity, (v) {
            setState(() => lipstickIntensity = v);
          }),
          _buildLancomeColorPicker('Lipstick Color', lipstickColor, (c) {
            setState(() => lipstickColor = c);
          }),
          Divider(height: 32, color: Color(0xFFFFB6C1).withValues(alpha: 0.3)),
          _buildLancomeSlider('Blush Intensity', blushIntensity, (v) {
            setState(() => blushIntensity = v);
          }),
          _buildLancomeSlider('Blush Radius', blushRadius, (v) {
            setState(() => blushRadius = v);
          }, min: 10, max: 100),
          _buildLancomeColorPicker('Blush Color', blushColor, (c) {
            setState(() => blushColor = c);
          }),
          Divider(height: 32, color: Color(0xFFFFB6C1).withValues(alpha: 0.3)),
          _buildLancomeSlider('Eyeshadow Intensity', eyeshadowIntensity, (v) {
            setState(() => eyeshadowIntensity = v);
          }),
          _buildLancomeColorPicker('Eyeshadow Color', eyeshadowColor, (c) {
            setState(() => eyeshadowColor = c);
          }),
          Divider(height: 32, color: Color(0xFFFFB6C1).withValues(alpha: 0.3)),
          _buildLancomeSlider('Foundation Intensity', foundationIntensity, (v) {
            setState(() => foundationIntensity = v);
          }),
          Divider(height: 32, color: Color(0xFFFFB6C1).withValues(alpha: 0.3)),
          _buildLancomeSlider('Bindi Size', bindiSize.toDouble(), (v) {
            setState(() => bindiSize = v.toInt());
          }, min: 1, max: 10),
          _buildLancomeColorPicker('Bindi Color', bindiColor, (c) {
            setState(() => bindiColor = c);
          }),
        ],
      ),
    );
  }

  Widget _buildLancomeSlider(String label, double value, Function(double) onChanged,
      {double min = 0.0, double max = 1.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF1493),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Color(0xFFFF1493),
                    inactiveTrackColor: Color(0xFFFFB6C1).withValues(alpha: 0.3),
                    thumbColor: Color(0xFFFF1493),
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 11),
                    overlayColor: Color(0xFFFF69B4).withValues(alpha: 0.3),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: value.clamp(min, max),
                    min: min,
                    max: max,
                    divisions: 20,
                    onChanged: onChanged,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 55,
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFE4E1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(0xFFFF69B4).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF1493),
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

  Widget _buildLancomeColorPicker(String label, Color color, Function(Color) onChanged) {
    final colors = [
      Color(0xFFFF1493), Color(0xFFFF69B4), Color(0xFFFFB6C1), Color(0xFFDDA0DD),
      Color(0xFFBA55D3), Color(0xFF9370DB), Color(0xFF6A5ACD), Color(0xFF4169E1),
      Color(0xFF00BFFF), Color(0xFF00CED1), Color(0xFF20B2AA), Color(0xFF32CD32),
      Color(0xFFFFFF00), Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF4500),
      Color(0xFFD2691E), Color(0xFF8B4513), Color(0xFF696969), Colors.black,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF1493),
            ),
          ),
          SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: colors.map((c) {
              final isSelected = color.value == c.value;
              return GestureDetector(
                onTap: () => onChanged(c),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Color(0xFFFF1493) : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Color(0xFFFF69B4).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                    Icons.check,
                    color: c.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    size: 20,
                  )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLancomeApplyButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF1493), Color(0xFFFF69B4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(29),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF1493).withValues(alpha: 0.5),
            blurRadius: 20,
            offset: Offset(0, 10),
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
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text(
              'APPLYING MAKEUP...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_fix_high_outlined, size: 24),
            SizedBox(width: 12),
            Text(
              'APPLY MAKEUP NOW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(29),
          ),
        ),
      ),
    );
  }

  Widget _buildLancomeResultSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFFB6C1).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_outlined, color: Color(0xFFFF1493), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'YOUR NEW LOOK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF1493),
                  letterSpacing: 0.5,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showBeforeAfter = !_showBeforeAfter;
                  });
                },
                icon: Icon(
                  _showBeforeAfter ? Icons.compare : Icons.compare_outlined,
                  color: Color(0xFFFF1493),
                ),
                tooltip: 'Compare Before/After',
              ),
            ],
          ),
          SizedBox(height: 18),
          if (_showBeforeAfter && _selectedImage != null) ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'BEFORE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'AFTER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF1493),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFF69B4).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_resultImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF69B4).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(_resultImage!, fit: BoxFit.cover),
              ),
            ),
          ],
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveResult,
                  icon: Icon(Icons.download_outlined, size: 20),
                  label: Text(
                    'SAVE',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF69B4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareResult,
                  icon: Icon(Icons.share_outlined, size: 20),
                  label: Text(
                    'SHARE',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF1493),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _uploadedImageId = null;
                  _resultImage = null;
                  _products = [];
                  _selectedProducts = [];
                });
              },
              icon: Icon(Icons.refresh_outlined, size: 20),
              label: Text(
                'TRY ANOTHER LOOK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFFFF1493),
                side: BorderSide(color: Color(0xFFFF1493), width: 2),
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLancomeImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Color(0xFFFFB6C1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'SELECT PHOTO',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF1493),
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 40),
                            SizedBox(height: 12),
                            Text(
                              'GALLERY',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF69B4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 40),
                            SizedBox(height: 12),
                            Text(
                              'CAMERA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF1493),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
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
        _products = [];
        _selectedProducts = [];
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
        _showLancomeSnackBar('Photo uploaded successfully', true);
      } else {
        _showLancomeSnackBar('Failed to upload photo', false);
      }
    } catch (e) {
      _showLancomeSnackBar('Error: ${e.toString()}', false);
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
            products.addAll(
              (item['products'] as List).map((p) => Product.fromJson(p)),
            );
          }
        }

        setState(() {
          _products = products;
          _selectedProducts = [];
          for (var product in _products) {
            _selectedProducts.add(product);
          }
        });

        if (products.isNotEmpty) {
          _showLancomeSnackBar('${products.length} products loaded', true);
        } else {
          _showLancomeSnackBar('No products found', false);
        }
      } else {
        _showLancomeSnackBar('Failed to load products', false);
      }
    } catch (e) {
      _showLancomeSnackBar('Error: ${e.toString()}', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyMakeup() async {
    if (_uploadedImageId == null) {
      _showLancomeSnackBar('Please upload a photo first', false);
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
        "bindi_size": bindiSize,
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
          String imageUrl = '$baseUrl/images/${jsonResponse['processed_image_id']}';

          final imageResponse = await http.get(Uri.parse(imageUrl));

          if (imageResponse.statusCode == 200) {
            setState(() {
              _resultImage = imageResponse.bodyBytes;
            });
            _showLancomeSnackBar('Makeup applied successfully', true);
          } else {
            _showLancomeSnackBar('Failed to load result', false);
          }
        }
      } else {
        _showLancomeSnackBar('Failed to apply makeup', false);
      }
    } catch (e) {
      _showLancomeSnackBar('Error: ${e.toString()}', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _colorToHex(Color color) {
    String hex = color.value.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  void _showLancomeSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Color(0xFFFF1493) : Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveResult() {
    _showLancomeSnackBar('Save functionality to be implemented', true);
  }

  void _shareResult() {
    _showLancomeSnackBar('Share functionality to be implemented', true);
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