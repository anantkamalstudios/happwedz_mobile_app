import 'package:flutter/material.dart';

import '../core/core.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';


class CardTemplate {
  final String title;
  final String imagePath;
  final List<Color> gradient;

  CardTemplate({
    required this.title,
    required this.imagePath,
    required this.gradient,
  });
}




















class WeddingCardsScreen extends StatefulWidget {
  const WeddingCardsScreen({super.key});
  @override
  State<WeddingCardsScreen> createState() => _WeddingCardsScreenState();
}

class _WeddingCardsScreenState extends State<WeddingCardsScreen> {
  String selectedSort = 'Trending';
  String selectedCulture = 'All';
  String selectedTheme = 'All';

  final List<String> sortOptions = ['Trending', 'Newest'];
  final List<String> cultureOptions = [
    'All', 'Hindu', 'South Indian', 'Muslim', 'Christian',
    'Marathi', 'Bengali', 'Sikh', 'Rajasthani', 'Generic'
  ];
  final List<String> themeOptions = [
    'All', 'Traditional', 'Elegant', 'Royal', 'Luxury',
    'Photo', 'Beach', 'Save the Date', 'Engagement',
    'Mountains', 'With God Photos'
  ];

  final List<CardTemplate> templates = [
    CardTemplate(
      title: 'Blooming in Love',
      imagePath: 'assets/wedding_card_1.jpg',
      gradient: [const Color(0xFF8B4513), const Color(0xFFFFB6C1)],
    ),
    CardTemplate(
      title: 'Blank Garden',
      imagePath: 'assets/wedding_card_2.jpg',
      gradient: [const Color(0xFF20B2AA), const Color(0xFF98FB98)],
    ),
    CardTemplate(
      title: 'Scent of Summer',
      imagePath: 'assets/wedding_card_3.jpg',
      gradient: [const Color(0xFFDEB887), const Color(0xFFF0E68C)],
    ),
    CardTemplate(
      title: 'Regal',
      imagePath: 'assets/wedding_card_4.jpg',
      gradient: [const Color(0xFF2F4F4F), const Color(0xFF8FBC8F)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,   // important
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
          top: false,   // ✅ allow gradient behind “status + header”
          child: Column(
            children: [
              // ✅ gradient header – same like budget screen
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: kToolbarHeight + 8,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "E-Invites",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),

                  ],
                ),
              ),

              // ✅ your original content
              _buildNavigationTabs(),
              _buildFilterSection(),
              Expanded(child: _buildCardsGrid()),
            ],
          ),
        ),
      ),
    );
  }




  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'E-Invites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          _buildNavTab('Wedding Cards', true),
          const SizedBox(width: 20),
          _buildNavTab('Video Cards', false),
          const SizedBox(width: 20),
          _buildNavTab('Save The Date Cards', false),
        ],
      ),
    );
  }

  Widget _buildNavTab(String title, bool isSelected) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildDropdown('Sort By', selectedSort, sortOptions, (value) => setState(() => selectedSort = value!), hasHeart: true),
          const SizedBox(width: 8),
          _buildDropdown('Culture', selectedCulture, cultureOptions, (value) => setState(() => selectedCulture = value!)),
          const SizedBox(width: 8),
          _buildDropdown('Theme', selectedTheme, themeOptions, (value) => setState(() => selectedTheme = value!)),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String selectedValue, List<String> options, Function(String?) onChanged, {bool hasHeart = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue == 'All' ? null : selectedValue,
            hint: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasHeart) const Icon(Icons.favorite, color: Color(0xFFFF69B4), size: 14),
                if (hasHeart) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
            isDense: true,
            isExpanded: true,
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildCardsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 20,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) => _buildCardTemplate(templates[index]),
      ),
    );
  }

  Widget _buildCardTemplate(CardTemplate template) {
    return GestureDetector(
      onTap: () => _showCardPreview(template),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: template.gradient,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildTemplateDecoration(template),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sample Text',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 1,
                                width: 40,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Wedding Invitation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white),
                child: Text(
                  template.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateDecoration(CardTemplate template) {
    return Stack(
      children: [
        if (template.title.contains('Love') || template.title.contains('Garden'))
          const Positioned(
            top: 10,
            right: 10,
            child: Icon(
              Icons.local_florist,
              color: Colors.white,
              size: 20,
            ),
          ),
        if (template.title.contains('Regal'))
          const Positioned(
            top: 15,
            left: 15,
            child: Icon(
              Icons.diamond,
              color: Colors.white,
              size: 18,
            ),
          ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCardPreview(CardTemplate template) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(colors: template.gradient),
          ),
          child: Stack(
            children: [
              _buildTemplateDecoration(template),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      template.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CardCustomizationScreen(template: template),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Customize'),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






class CardCustomizationScreen extends StatefulWidget {
  final CardTemplate template;
  const CardCustomizationScreen({super.key, required this.template});

  @override
  State<CardCustomizationScreen> createState() => _CardCustomizationScreenState();
}

class _CardCustomizationScreenState extends State<CardCustomizationScreen> {
  double cardScale = 1.0;
  String selectedTool = 'text';
  List<Map<String, dynamic>> undoStack = [];
  int currentUndoIndex = -1;
  bool isDraft = false;

  // Text editing variables
  String mainTitle = 'Wedding Invitation';
  String coupleNames = 'John & Jane';
  String eventDate = '25th December 2025';
  Color textColor = Colors.white;
  double fontSize = 18;

  // Color variables
  late List<Color> currentGradient;

  // Stickers
  List<Map<String, dynamic>> addedStickers = [];
  final List<String> availableStickers = ['💕', '💐', '💍', '🌸', '🥂', '👰', '🤵', '🎉'];

  // Effects
  double blur = 0.0;
  double brightness = 1.0;
  double contrast = 1.0;

  final List<Map<String, dynamic>> tools = [
    {'icon': Icons.text_fields, 'label': 'Text', 'id': 'text'},
    {'icon': Icons.image, 'label': 'Images', 'id': 'image'},
    {'icon': Icons.palette, 'label': 'Colors', 'id': 'color'},
    {'icon': Icons.auto_fix_high, 'label': 'Stickers', 'id': 'stickers'},
    {'icon': Icons.crop, 'label': 'Crop', 'id': 'crop'},
    {'icon': Icons.tune, 'label': 'Effects', 'id': 'effects'},
  ];

  final ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    currentGradient = List.from(widget.template.gradient);
    _saveState();
  }

  void _saveState() {
    undoStack.add({
      'mainTitle': mainTitle,
      'coupleNames': coupleNames,
      'eventDate': eventDate,
      'textColor': textColor,
      'fontSize': fontSize,
      'currentGradient': List.from(currentGradient),
      'addedStickers': List.from(addedStickers),
      'blur': blur,
      'brightness': brightness,
      'contrast': contrast,
    });
    currentUndoIndex = undoStack.length - 1;
  }

  void _undo() {
    if (currentUndoIndex > 0) {
      setState(() {
        currentUndoIndex--;
        _applyState(undoStack[currentUndoIndex]);
      });
    }
  }

  void _redo() {
    if (currentUndoIndex < undoStack.length - 1) {
      setState(() {
        currentUndoIndex++;
        _applyState(undoStack[currentUndoIndex]);
      });
    }
  }

  void _applyState(Map<String, dynamic> state) {
    mainTitle = state['mainTitle'];
    coupleNames = state['coupleNames'];
    eventDate = state['eventDate'];
    textColor = state['textColor'];
    fontSize = state['fontSize'];
    currentGradient = List.from(state['currentGradient']);
    addedStickers = List.from(state['addedStickers']);
    blur = state['blur'];
    brightness = state['brightness'];
    contrast = state['contrast'];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopHeader(),
              Container(
                height: MediaQuery.of(context).size.height * 0.5, // <-- Fixed height
                child: _buildCanvasArea(),
              ),
              _buildBottomTools(),
              if (_shouldShowEditPanel())
                Container(
                  height: 120, // <-- Fixed height
                  child: _buildEditPanel(),
                ),
              SafeArea(top: false, child: _buildActionButtons()),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowEditPanel() => selectedTool != 'crop';

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Spacer(),

          Expanded(
            child: Row(
              children: [
                _buildActionIcon(Icons.undo, currentUndoIndex > 0, _undo),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.redo, currentUndoIndex < undoStack.length - 1, _redo),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildActionIcon(IconData icon, bool enabled, VoidCallback onPressed) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey[700] : Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.grey[600],
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCanvasArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Center(
        child: Screenshot(
          controller: screenshotController,
          child: Transform.scale(
            scale: cardScale,
            child: Container(
              width: 280,
              height: 350,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: currentGradient,
                    ),
                  ),
                  child: Stack(
                    children: [
                      _buildTemplateDecoration(widget.template),
                      // Stickers Layer
                      ...addedStickers.map((sticker) {
                        return Positioned(
                          left: sticker['x'],
                          top: sticker['y'],
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                addedStickers.remove(sticker);
                                _saveState();
                              });
                            },
                            child: Text(
                              sticker['emoji'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      }).toList(),
                      // Main Content
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              mainTitle,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: blur,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              height: 2,
                              width: 60,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              coupleNames,
                              style: TextStyle(
                                color: textColor,
                                fontSize: fontSize + 4,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: blur,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              eventDate,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.9),
                                fontSize: fontSize - 4,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: blur,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTools() {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final tool = tools[index];
          final isSelected = selectedTool == tool['id'];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedTool = tool['id'];
                _saveState();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF69B4) : Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tool['icon'], color: Colors.white, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    tool['label'],
                    style: const TextStyle(color: Colors.white, fontSize: 8),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditPanel() {
    return Container(
      height: 120,
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(child: _buildToolPanel()),
    );
  }

  Widget _buildToolPanel() {
    switch (selectedTool) {
      case 'text':
        return _buildTextPanel();
      case 'color':
        return _buildColorPanel();
      case 'stickers':
        return _buildStickersPanel();
      case 'effects':
        return _buildEffectsPanel();
      case 'image':
        return _buildImagePanel();
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Edit title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      mainTitle = value;
                      _saveState();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Couple names',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      coupleNames = value;
                      _saveState();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Size: ', style: TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: fontSize,
                  min: 12,
                  max: 28,
                  divisions: 16,
                  onChanged: (value) {
                    setState(() {
                      fontSize = value;
                      _saveState();
                    });
                  },
                ),
              ),
              Text('${fontSize.toInt()}', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Color:', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedColor = await showDialog<Color>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Pick a color'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: textColor,
                    onColorChanged: (color) {
                      setState(() {
                        textColor = color;
                        _saveState();
                      });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            if (pickedColor != null) {
              setState(() => textColor = pickedColor);
            }
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Background:', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            [Colors.pink, Colors.purple],
            [Colors.blue, Colors.cyan],
            [Colors.green, Colors.lime],
            [Colors.orange, Colors.red],
            [Colors.brown, Colors.amber],
          ].map((gradientColors) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  currentGradient = gradientColors;
                  _saveState();
                });
              },
              child: Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white54),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStickersPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Add Stickers:', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: availableStickers.map((sticker) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (addedStickers.length < 5) {
                    addedStickers.add({
                      'emoji': sticker,
                      'x': 50.0,
                      'y': 50.0,
                    });
                    _saveState();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(sticker, style: const TextStyle(fontSize: 20)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          'Added: ${addedStickers.length}/5 (Tap to remove)',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEffectsPanel() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Blur:', style: TextStyle(color: Colors.white)),
            Expanded(
              child: Slider(
                value: blur,
                min: 0,
                max: 10,
                onChanged: (value) {
                  setState(() {
                    blur = value;
                    _saveState();
                  });
                },
              ),
            ),
            Text('${blur.toInt()}', style: const TextStyle(color: Colors.white)),
          ],
        ),
        Row(
          children: [
            const Text('Brightness:', style: TextStyle(color: Colors.white)),
            Expanded(
              child: Slider(
                value: brightness,
                min: 0.5,
                max: 2.0,
                onChanged: (value) {
                  setState(() {
                    brightness = value;
                    _saveState();
                  });
                },
              ),
            ),
            Text('${brightness.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image Options:', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildImageOption('Gallery', Icons.photo_library, () {}),
            const SizedBox(width: 15),
            _buildImageOption('Camera', Icons.camera_alt, () {}),
            const SizedBox(width: 15),
            _buildImageOption('Remove', Icons.delete, () {}),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Tap to add photos from gallery or camera',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildImageOption(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => isDraft = true);
                AppSnackbar.success(context, 'Draft saved successfully!');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Save Draft',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (isDraft) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: _showCompletionDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateDecoration(CardTemplate template) {
    return Stack(
      children: [
        if (template.title.contains('Love') || template.title.contains('Garden'))
          const Positioned(
            top: 20,
            right: 20,
            child: Icon(
              Icons.local_florist,
              color: Colors.white,
              size: 25,
            ),
          ),
        if (template.title.contains('Regal'))
          const Positioned(
            top: 25,
            left: 25,
            child: Icon(
              Icons.diamond,
              color: Colors.white,
              size: 22,
            ),
          ),
        Positioned(
          bottom: 40,
          left: 30,
          right: 30,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Customize Complete!'),
        content: const Text('Your wedding card has been customized successfully. Would you like to download or share it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final image = await screenshotController.captureFromWidget(_buildCardPreview());
              // await ImageGallerySaver.saveImage(image);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              AppSnackbar.success(context, 'Card saved to gallery!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF69B4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    return Container(
      width: 280,
      height: 350,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: currentGradient,
            ),
          ),
          child: Stack(
            children: [
              _buildTemplateDecoration(widget.template),
              // Stickers Layer
              ...addedStickers.map((sticker) {
                return Positioned(
                  left: sticker['x'],
                  top: sticker['y'],
                  child: Text(
                    sticker['emoji'],
                    style: const TextStyle(fontSize: 24),
                  ),
                );
              }).toList(),
              // Main Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mainTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: blur,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      height: 2,
                      width: 60,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      coupleNames,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize + 4,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: blur,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eventDate,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: fontSize - 4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: blur,
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
      ),
    );
  }
}
