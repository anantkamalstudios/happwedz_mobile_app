import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class CreateYourLookScreen extends StatefulWidget {
  @override
  _CreateYourLookScreenState createState() => _CreateYourLookScreenState();
}

class _CreateYourLookScreenState extends State<CreateYourLookScreen>
    with TickerProviderStateMixin {
  int selectedTab = 0;
  int selectedLipstick = 0;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Your Look',
          style: TextStyle(
            color: Colors.pinkAccent,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header gradient section
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF69B4),
                      Color(0xFFFFB6C1),
                      Colors.white,
                    ],
                  ),
                ),
              ),

              // Profile photo upload section
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    children: [
                      // Profile circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFFE91E63).withOpacity(0.3),
                            width: 2,
                          ),
                          color: Colors.white,
                        ),
                        child: Icon(
                          Icons.person_outline,
                          size: 50,
                          color: Color(0xFFE91E63).withOpacity(0.5),
                        ),
                      ),

                      SizedBox(height: 16),

                      Text(
                        'Upload your photo to get started',
                        style: TextStyle(
                          color: Color(0xFFE91E63),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 24),

                      // Upload options
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildUploadOption(
                              icon: Icons.upload_file,
                              title: 'Upload a file',
                              subtitle: 'Browse device for photos',
                              onTap: () {
                                _showCaptureYourFaceModal(context);
                              },
                            ),
                          ),
                          // SizedBox(width: 16),
                          // Expanded(
                          //   child: _buildUploadOption(
                          //     icon: Icons.camera_alt,
                          //     title: 'Live Camera',
                          //     subtitle: 'Take a live photo',
                          //     onTap: () {
                          //       // Handle camera
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Tabs section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildTab('Makeup', 0),
                    _buildTab('Dress', 1),
                    _buildTab('Complete Looks', 2),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Lipstick section
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lipstick',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Lipstick options
                    Row(
                      children: [
                        Expanded(
                          child: _buildLipstickOption(
                            'Matte Red',
                            Color(0xFFDC143C),
                            0,
                            'assets/lipstick_red.jpg',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildLipstickOption(
                            'Coral Matte',
                            Color(0xFFFF7F50),
                            1,
                            'assets/lipstick_coral.jpg',
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    Text(
                      'Foundation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Foundation options
                    Row(
                      children: [
                        Expanded(
                          child: _buildLipstickOption(
                            'Medium Tan',
                            Color(0xFFDC143C),
                            0,
                            'assets/lipstick_red.jpg',
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildLipstickOption(
                            'Light Beige',
                            Color(0xFFFF7F50),
                            1,
                            'assets/lipstick_coral.jpg',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Apply button
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle apply
                          _showApplyAnimation(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE91E63),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Look',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFFE91E63).withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Color(0xFFE91E63),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF718096),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE91E63) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Color(0xFF718096),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildLipstickOption(String name, Color color, int index, String imagePath) {
    bool isSelected = selectedLipstick == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedLipstick = index;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFFE91E63) : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Lipstick image placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.face,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApplyAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF69B4)),
                ),
                SizedBox(height: 20),
                Text(
                  'Applying Look...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto dismiss after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop(); // close dialog
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FinalLookResultScreen()),
      );

    });
  }

  // ===== CAPTURE YOUR FACE MODAL =====
  void _showCaptureYourFaceModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Images Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProfileImage(),
                    const SizedBox(width: 10),
                    _buildProfileImage(),
                    const SizedBox(width: 10),
                    _buildProfileImage(),
                  ],
                ),

                const SizedBox(height: 20),

                // Title
                const Text(
                  'Capture Your Face',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'For accurate results, please follow these guidelines:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Guidelines
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGuidelineColumn([
                      'High-quality image from 720-1080 px',
                      'full body should be visible (head to toe)',
                      'image should not be blur',
                      'image should not be illuminated or over-lit',
                      'image should be front facing (no side or back view)',
                      'multi eyes, ears, shoulders, hands and boots should be visible',
                    ]),
                    const SizedBox(width: 20),
                    _buildGuidelineColumn([
                      'plain background',
                      'no group photos',
                      'formals / big group',
                      'max size: 5MB',
                      'max size: 5MB',
                    ]),
                  ],
                ),

                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleUploadPhoto(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF69B4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Upload photo',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          color: const Color(0xFFFF69B4).withOpacity(0.3),
          child: const Icon(
            Icons.person,
            color: Color(0xFFFF69B4),
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineColumn(List<String> guidelines) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: guidelines.map((guideline) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF69B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Color(0xFFFF69B4),
                  ),
                ),
                Expanded(
                  child: Text(
                    guideline,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleUploadPhoto(BuildContext context) {
    // Show image picker options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Select Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPhotoOption(
                          icon: Icons.camera_alt,
                          title: 'Camera',
                          onTap: () {
                            Navigator.pop(context);
                            // Implement camera functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Camera selected'),
                                backgroundColor: Color(0xFFFF69B4),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildPhotoOption(
                          icon: Icons.photo_library,
                          title: 'Gallery',
                          onTap: () {
                            Navigator.pop(context);
                            // Implement gallery functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gallery selected'),
                                backgroundColor: Color(0xFFFF69B4),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF69B4).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFFFF69B4),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



















class FinalLookResultScreen extends StatefulWidget {
  final String? selectedLipstickName;
  final Color? selectedLipstickColor;
  final String? selectedFoundationName;
  final String? userImagePath;

  const FinalLookResultScreen({
    Key? key,
    this.selectedLipstickName,
    this.selectedLipstickColor,
    this.selectedFoundationName,
    this.userImagePath,
  }) : super(key: key);

  @override
  _FinalLookResultScreenState createState() => _FinalLookResultScreenState();
}

class _FinalLookResultScreenState extends State<FinalLookResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFE91E63),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Your Look',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header gradient section
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE91E63),
                      Color(0xFFFFB6C1),
                      Colors.white,
                    ],
                  ),
                ),
              ),

              // Main content
              SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Title section with celebration animation
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.star,
                                color: Color(0xFFE91E63),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your Final Look!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Absolutely stunning with your selections',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF718096),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Result image with enhanced styling
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 280,
                              height: 320,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.pink.shade50,
                                    Colors.orange.shade50,
                                  ],
                                ),
                              ),
                              child: widget.userImagePath != null
                                  ? Image.asset(
                                widget.userImagePath!,
                                fit: BoxFit.cover,
                              )
                                  : _buildPlaceholderImage(),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // Applied Products section
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Applied Products',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Products grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildProductCard(
                                    name: widget.selectedLipstickName ?? 'Matte Red',
                                    color: widget.selectedLipstickColor ?? const Color(0xFFDC143C),
                                    type: 'Lipstick',
                                    icon: Icons.face,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildProductCard(
                                    name: widget.selectedFoundationName ?? 'Medium Tan',
                                    color: const Color(0xFFD2B48C),
                                    type: 'Foundation',
                                    icon: Icons.brush,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Action buttons
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Save Look button
                            Container(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: _saveLook,
                                icon: const Icon(Icons.favorite, color: Colors.white),
                                label: const Text(
                                  'Save This Look',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Try Another Look button
                            Container(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton.icon(
                                onPressed: _tryAnotherLook,
                                icon: const Icon(Icons.refresh, color: Color(0xFFE91E63)),
                                label: const Text(
                                  'Try Another Look',
                                  style: TextStyle(
                                    color: Color(0xFFE91E63),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE91E63), width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Share button
                            Container(
                              width: double.infinity,
                              height: 54,
                              child: TextButton.icon(
                                onPressed: _shareLook,
                                icon: const Icon(Icons.share, color: Color(0xFF718096)),
                                label: const Text(
                                  'Share with Friends',
                                  style: TextStyle(
                                    color: Color(0xFF718096),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE91E63).withOpacity(0.1),
                  const Color(0xFFFF69B4).withOpacity(0.1),
                ],
              ),
            ),
          ),
          // Sample model image placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Look Applied!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required String name,
    required Color color,
    required String type,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product image section
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Container(
                width: 50,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),

          // Product details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveLook() {
    _showSuccessMessage('Look saved to your favorites! ❤️');
  }

  void _tryAnotherLook() {
    Navigator.pop(context);
  }

  void _shareLook() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Share Your Look',
          style: TextStyle(color: Color(0xFFE91E63)),
        ),
        content: const Text('Share your beautiful look with friends on social media!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSuccessMessage('Sharing options opened! 📱');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Share', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}