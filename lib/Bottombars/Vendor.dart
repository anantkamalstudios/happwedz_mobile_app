import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../vendor/vendordetailsscreen.dart';
import 'GenieScreen.dart';

class VendorCategoriesScreen extends StatefulWidget {
  const VendorCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<VendorCategoriesScreen> createState() => _VendorCategoriesScreenState();
}

class _VendorCategoriesScreenState extends State<VendorCategoriesScreen> {
  bool isVenuesExpanded = false;
  bool isPhotographersExpanded = false;
  bool isMakeupExpanded = false;
  bool isPlanningExpanded = false;
  bool isVirtualPlanningExpanded = false;
  bool isMehndiExpanded = false;
  bool isMusicDanceExpanded = false;
  bool isFoodExpanded=false;
  bool isGiftExpanded=false;
  bool isprewedshot=false;
  bool isbridewear=false;
  bool isgroomwear=false;
  bool isjewellery=false;
  bool ispandit=false;
  List<VendorCategory> categories = [];
  Map<int, bool> expandedState = {}; // Track expanded cards

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }
  Future<void> fetchSubcategoryServices(Subcategory subcategory) async {
    try {
      final response = await http.get(
        Uri.parse("https://happywedz.com/api/vendor-services?subCategory=${subcategory.name.toLowerCase()}"),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          subcategory.services = data; // assign API data
        });
        print(response);
        print(response.body);
        print(data);
      } else {
        print("Error fetching ${subcategory.name} services: ${response.statusCode}");
      }
    } catch (e) {
      print("API Error for ${subcategory.name}: $e");
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse("https://happywedz.com/api/vendor-types/with-subcategories/all"),
        headers: {"Accept": "application/json"},
      );

      print("Status Code: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categories = data.map((e) => VendorCategory.fromJson(e)).toList();
          for (var cat in categories) {
            expandedState[cat.id] = false;
          }
        });
        print("Status Code: ${response.statusCode}");
        print("Body: ${response.body}");
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("API Error: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // ---------------------- MAIN SCREEN UI ----------------------
          Container(
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
              child: Column(
                children: [

                  // ------------------ HEADER ------------------
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Center(
                      child: Text(
                        'Vendor Categories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // ------------------ CATEGORY LIST ------------------
                  Expanded(
                    child: categories.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: categories.map((cat) {
                          return Column(
                            children: [
                              _buildCategoryCard(
                                title: cat.name,
                                subtitle: cat.description ?? "",
                                backgroundColor: const Color(0xFFE8D5E8),
                                isExpanded: expandedState[cat.id] ?? false,
                                onTap: () async {
                                  setState(() {
                                    expandedState[cat.id] =
                                    !(expandedState[cat.id] ?? false);
                                  });

                                  for (var sub in cat.subcategories) {
                                    if (sub.services == null) {
                                      await fetchSubcategoryServices(sub);
                                    }
                                  }
                                },
                                image: cat.heroImage,
                                subcategories:
                                cat.subcategories.map((s) => s.name).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------- FLOATING GENIE BUTTON ----------------------
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GenieScreen()),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6A5AE0),
                      Color(0xFFB26BF2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),

        ],
      ),

    );
  }


  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required bool isExpanded,
    required VoidCallback onTap,
    required String image,
    required List<String> subcategories, // List of subcategory names
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,

                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.black54,
                              size: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "https://happywedz.com/api/$image",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: subcategories.map((subcategory) {
                  if (subcategory.isEmpty) return const SizedBox(height: 8);

                  return InkWell(
                    onTap: () {
                      // Pass the exact subcategory name as returned from API
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VendorServicesScreen(
                            subcategoryName: subcategory, // exact casing & spaces
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Text(
                        subcategory,
                        style: TextStyle(
                          fontSize: 14,
                          color: subcategory == 'View all Venues'
                              ? const Color(0xFFE91E63)
                              : Colors.black54,
                          fontWeight: subcategory == 'View all Venues'
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }



}

class VendorCategory {
  final int id;
  final String name;
  final String? description;
  final String heroImage;
  final List<Subcategory> subcategories;

  VendorCategory({
    required this.id,
    required this.name,
    this.description,
    required this.heroImage,
    required this.subcategories,
  });

  factory VendorCategory.fromJson(Map<String, dynamic> json) {
    return VendorCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      heroImage: json['hero_image'] ?? "",
      subcategories: (json['subcategories'] as List<dynamic>)
          .map((e) => Subcategory.fromJson(e))
          .toList(),
    );
  }
}

class Subcategory {
  final int id;
  final String name;
  List<dynamic>? services; // This will hold API response for this subcategory

  Subcategory({
    required this.id,
    required this.name,
    this.services,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

