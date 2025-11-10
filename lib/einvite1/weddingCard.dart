import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'ViewAllScreen.dart';

class CustomizeCardScreen extends StatefulWidget {
  final String templateImage;

  const CustomizeCardScreen({required this.templateImage, super.key});

  @override
  State<CustomizeCardScreen> createState() => _CustomizeCardScreenState();
}

class _CustomizeCardScreenState extends State<CustomizeCardScreen> {
  List<TextInfo> get defaultTexts => [
    TextInfo(
      text: "SHIVANI",
      left: 120,
      top: 120,
      fontFamily: 'Poppins',
      fontSize: 32,
      color: Colors.black,
      isBold: false,
      isItalic: false,
    ),
    TextInfo(
      text: "weds",
      left: 160,
      top: 160,
      fontFamily: 'Poppins',
      fontSize: 22,
      color: Colors.black,
      isBold: false,
      isItalic: true,
    ),
    TextInfo(
      text: "RAHUL",
      left: 130,
      top: 200,
      fontFamily: 'Poppins',
      fontSize: 32,
      color: Colors.black,
      isBold: false,
      isItalic: false,
    ),
  ];

  final List<String> fonts = ['Poppins', 'Roboto', 'Lobster', 'Dancing Script'];
  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.white,
  ];

  late Map<String, List<TextInfo>> pages;
  String currentPage = "Wedding";

  bool isEditing = false;
  int? selectedIndex;

  final List<List<TextInfo>> _undoStack = [];

  @override
  void initState() {
    super.initState();
    pages = {}; // start empty — user will create pages
    _loadDraft();



  }


  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();

    // Convert TextInfo objects into a storable Map
    final data = pages.map((pageName, texts) => MapEntry(
      pageName,
      texts
          .map((t) => {
        'text': t.text,
        'left': t.left,
        'top': t.top,
        'fontFamily': t.fontFamily,
        'fontSize': t.fontSize,
        'color': t.color.value,
        'isBold': t.isBold,
        'isItalic': t.isItalic,
      })
          .toList(),
    ));

    // Save to SharedPreferences
    await prefs.setString('draftData', jsonEncode(data));
    await prefs.setString('draftTemplate', widget.templateImage);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Draft saved successfully!')),
    );
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('draftData');
    final savedTemplate = prefs.getString('draftTemplate');

    if (savedData != null && savedTemplate == widget.templateImage) {
      final decoded = jsonDecode(savedData) as Map<String, dynamic>;

      setState(() {
        pages = decoded.map((pageName, textList) {
          final list = (textList as List<dynamic>)
              .map((t) => TextInfo(
            text: t['text'],
            left: (t['left'] as num).toDouble(),
            top: (t['top'] as num).toDouble(),
            fontFamily: t['fontFamily'],
            fontSize: (t['fontSize'] as num).toDouble(),
            color: Color(t['color']),
            isBold: t['isBold'],
            isItalic: t['isItalic'],
          ))
              .toList();
          return MapEntry(pageName, list);
        });
        if (pages.isNotEmpty) currentPage = pages.keys.first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📂 Draft loaded!')),
      );
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draftData');
    await prefs.remove('draftTemplate');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🗑️ Draft cleared')),
    );
  }


  // 🧾 Save draft

  List<TextInfo> get texts => pages[currentPage] ?? [];

  void _saveForUndo() {
    _undoStack.add(texts.map((t) => t.copy()).toList());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        pages[currentPage] = _undoStack.removeLast();
        selectedIndex = null;
      });
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to undo')));
    }
  }

  void _applyToSelected(void Function(TextInfo t) fn) {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a text first')));
      return;
    }
    _saveForUndo();
    setState(() {
      fn(texts[selectedIndex!]);
    });
  }

  void _showPageOptions(String pageName) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Rename Page"),
                onTap: () {
                  Navigator.pop(context);
                  _renamePage(pageName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Delete Page", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePage(pageName);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deletePage(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Page"),
        content: Text("Are you sure you want to delete '$name'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        pages.remove(name);
        if (currentPage == name) {
          currentPage = pages.keys.isNotEmpty ? pages.keys.first : "";
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Page '$name' deleted 🗑️")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customize Card"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
            color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: isEditing ? _buildEditMode(context) : _buildPreviewMode(context),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildPageTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          ...pages.keys.map((pageName) {
            final bool selected = pageName == currentPage;
            return GestureDetector(
              onTap: () {
                setState(() {
                  currentPage = pageName;
                  selectedIndex = null;
                });
              },
              onLongPress: () => _showPageOptions(pageName),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? Colors.pink : Colors.grey.shade400,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Text(
                  pageName,
                  style: TextStyle(
                    fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
          GestureDetector(
            onTap: _addNewPage,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pink),
              ),
              child: const Text(
                "+ Add",
                style:
                TextStyle(color: Colors.pink, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPreviewMode(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildPageTabs(),
            Expanded(
              child: widget.templateImage.startsWith('http')
                  ? Image.network(
                widget.templateImage,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              )
                  : Image.asset(
                widget.templateImage,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),

          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                final loggedIn = await ensureLoggedIn(context);
                if (!loggedIn) return; // 🚫 not logged in → go to SignInScreen

                // ✅ continue if logged in
                setState(() => isEditing = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Customise the card",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ),

      ],
    );
  }

  Widget _buildEditMode(BuildContext context) {
    return Column(
      children: [
        _buildPageTabs(),
        Expanded(
          child: Stack(
            children: [
              widget.templateImage.startsWith('http')
                  ? Image.network(
                widget.templateImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              )
                  : Image.asset(
                widget.templateImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Stack(
                children: [
                  // Template image
                  widget.templateImage.startsWith('http')
                      ? Image.network(
                    widget.templateImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  )
                      : Image.asset(
                    widget.templateImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),

                  // Draggable Texts
                  ...texts.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final t = entry.value;

                    return Positioned(
                      left: t.left,
                      top: t.top,
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = idx),
                        onPanUpdate: (details) {
                          setState(() {
                            t.left += details.delta.dx;
                            t.top += details.delta.dy;
                          });
                        },
                        onLongPress: () => _openEditDialog(idx),
                        child: Container(
                          padding: selectedIndex == idx
                              ? const EdgeInsets.all(4)
                              : EdgeInsets.zero,
                          decoration: selectedIndex == idx
                              ? BoxDecoration(
                            border: Border.all(color: Colors.pink, width: 1.5),
                          )
                              : null,
                          child: Text(
                            t.text,
                            style: GoogleFonts.getFont(
                              t.fontFamily,
                              fontSize: t.fontSize,
                              color: t.color,
                              fontWeight: t.isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: t.isItalic ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),

                        ),
                      ),
                    );
                  }).toList(),
                ],
              )

            ],
          ),
        ),

        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.pink,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _bottomButton(Icons.font_download, "Font", _showFontSelector),
            _bottomButton(Icons.format_color_text, "Color", _showColorPicker),
            _bottomButton(Icons.text_fields, "Size", _showSizeSlider),
            _bottomButton(Icons.format_bold, "Bold",
                    () => _applyToSelected((t) => t.isBold = !t.isBold)),
            _bottomButton(Icons.format_italic, "Italic",
                    () => _applyToSelected((t) => t.isItalic = !t.isItalic)),
            _bottomButton(Icons.undo, "Undo", _undo),
            _bottomButton(Icons.add, "Add Text", _addNewText),
            _bottomButton(Icons.save, "Save", _saveDraft),

            const SizedBox(width: 12),

          ],
        ),
      ),
    );
  }

  Widget _bottomButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  void _showFontSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(12),
          height: 240,
          child: ListView(
            children: fonts.map((font) {
              return ListTile(
                title: Text(font, style: GoogleFonts.getFont(font)),
                onTap: () {
                  _applyToSelected((t) => t.fontFamily = font);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _addNewText() async {
    final controller = TextEditingController();
    final newText = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Text"),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: "Enter your text here",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (newText != null && newText.isNotEmpty) {
      _saveForUndo(); // save state for undo
      setState(() {
        final t = TextInfo(
          text: newText,
          left: 50, // default position
          top: 50,  // default position
          fontFamily: 'Poppins',
          fontSize: 24,
          color: Colors.black,
          isBold: false,
          isItalic: false,
        );
        // Add to current page
        pages.putIfAbsent(currentPage, () => []).add(t);
        // ✅ Select new text immediately so styling works
        selectedIndex = pages[currentPage]!.length - 1;
      });
    }
  }




  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  _applyToSelected((t) => t.color = color);
                  Navigator.pop(context);
                },
                child: CircleAvatar(backgroundColor: color, radius: 20),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showSizeSlider() {
    if (selectedIndex == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a text first')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (_) {
        double localSize = texts[selectedIndex!].fontSize;
        return StatefulBuilder(builder: (context, setLocal) {
          return Container(
            height: 140,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text("Adjust Font Size",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Slider(
                  min: 8,
                  max: 120,
                  value: localSize,
                  onChanged: (v) {
                    setLocal(() => localSize = v);
                    setState(() => texts[selectedIndex!].fontSize = v);
                  },
                  activeColor: Colors.pink,
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _addNewPage() async {
    final controller = TextEditingController();
    final newPage = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("New Page"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Enter page name (e.g. Engagement, Reception)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim()),
            child: const Text("Add"),
          ),
        ],
      ),
    );

    if (newPage != null &&
        newPage.isNotEmpty &&
        !pages.containsKey(newPage)) {
      setState(() {
        pages[newPage] = defaultTexts.map((t) => t.copy()).toList();
        currentPage = newPage;
      });
    } else if (pages.containsKey(newPage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Page name already exists ⚠️")),
      );
    }
  }

  void _renamePage(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Page"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Enter new name"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text("Rename")),
        ],
      ),
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != oldName &&
        !pages.containsKey(newName)) {
      setState(() {
        pages[newName] = pages.remove(oldName)!;
        currentPage = newName;
      });
    }
  }

  void _openEditDialog(int idx) async {
    final newText = await showDialog<String?>(
      context: context,
      builder: (_) => TextEditDialog(initialText: texts[idx].text),
    );
    if (newText != null) {
      _saveForUndo();
      setState(() {
        texts[idx].text = newText;
      });
    }
  }
}

class TextInfo {
  String text;
  double left;
  double top;
  String fontFamily;
  double fontSize;
  Color color;
  bool isBold;
  bool isItalic;

  TextInfo({
    required this.text,
    required this.left,
    required this.top,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.isBold,
    required this.isItalic,
  });

  TextInfo copy() => TextInfo(
    text: text,
    left: left,
    top: top,
    fontFamily: fontFamily,
    fontSize: fontSize,
    color: color,
    isBold: isBold,
    isItalic: isItalic,
  );
}

class TextEditDialog extends StatefulWidget {
  final String initialText;
  const TextEditDialog({required this.initialText, super.key});

  @override
  State<TextEditDialog> createState() => _TextEditDialogState();
}

class _TextEditDialogState extends State<TextEditDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Text"),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text("Done"),
        )
      ],
    );
  }
}
