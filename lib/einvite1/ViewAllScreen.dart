import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/einvite1/weddingCard.dart';

class ViewAllScreen extends StatefulWidget {
  final String categoryTitle;
  final List<Map<String, String>> cards;

  const ViewAllScreen({super.key, required this.categoryTitle, required this.cards});

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  String? selectedSort;
  String? selectedCulture;
  String? selectedTheme;

  final List<String> sortOptions = ['Trending', 'Newest'];
  final List<String> cultureOptions = [
    'Hindu',
    'South Indian',
    'Muslim',
    'Christian',
    'Marathi',
    'Bangali',
    'Sikh',
    'Rajasthani',
    'Generic'
  ];
  final List<String> themeOptions = [
    'Traditional',
    'Elegant',
    'Caricature',
    'Royal',
    'Luxury',
    'Photo',
    'Beach',
    'With god photos',
    'Mountains',
    'Save The Date'
  ];

  void _openBottomSheet(
      String title,
      List<String> options,
      String? selectedValue,
      Function(String) onSelected,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "OK",
                            style: TextStyle(
                                color: Colors.pink,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Radio options
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final item = options[index];
                          return RadioListTile<String>(
                            activeColor: Colors.pink,
                            title: Text(item),
                            value: item,
                            groupValue: selectedValue,
                            onChanged: (value) {
                              setModalState(() {
                                selectedValue = value;
                              });
                              onSelected(value!);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterButton(String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade400),
        color: Colors.white,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.black)),
              const Icon(Icons.keyboard_arrow_down, color: Colors.pink),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E63),
        centerTitle: true,
        leading: const Icon(Icons.arrow_back, color: Colors.white),
        title: const Text('E-Invites',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Text('Wedding Cards',
                      style: TextStyle(
                          color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
                  Text('Video Cards', style: TextStyle(color: Colors.grey)),
                  Text('Save The Date Cards', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Filter Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton("Sort By", () {
                      _openBottomSheet("Sort By", sortOptions, selectedSort, (value) {
                        setState(() {
                          selectedSort = value;
                        });
                      });
                    }),
                    _buildFilterButton("Culture", () {
                      _openBottomSheet("Culture", cultureOptions, selectedCulture, (value) {
                        setState(() {
                          selectedCulture = value;
                        });
                      });
                    }),
                    _buildFilterButton("Theme", () {
                      _openBottomSheet("Theme", themeOptions, selectedTheme, (value) {
                        setState(() {
                          selectedTheme = value;
                        });
                      });
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grid with API images
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final card = widget.cards[index];

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomizeCardScreen(templateImage: card['image']!),
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              card['image']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          card['title']!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
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
