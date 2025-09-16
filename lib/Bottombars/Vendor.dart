import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

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
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // IconButton(
                    //   icon: const Icon(
                    //     Icons.arrow_back_ios,
                    //     color: Colors.white,
                    //     size: 20,
                    //   ),
                    //   onPressed: () => Navigator.pop(context),
                    // ),
                    // const Text(
                    //   'Nashik',
                    //   style: TextStyle(
                    //     color: Colors.white,
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    Text(
                      'Vendor Categories',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 60), // Balance the left side
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: 'Search wedding venues...',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Categories List
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Venues Category
                      _buildCategoryCard(
                        title: 'Venues',
                        subtitle: 'Banquet Halls, Marriage Gardens',
                        backgroundColor: const Color(0xFFE8D5E8), // Light purple
                        isExpanded: isVenuesExpanded,
                        onTap: () => setState(() => isVenuesExpanded = !isVenuesExpanded),
                        image: 'assets/images/venues.jpg',
                        subcategories: [
                          // 'View all Venues',
                          '',
                          'Farm Houses',
                          'Marriage Gardens / Lawns',
                          '',
                          'Wedding Resorts',
                          '',
                          'Small Functions / Party Halls',
                          '',
                          'Destination Wedding Venues',
                          '',
                          'Kalyana Mandapams',
                          '',
                          '4 Star & Above Wedding Hotels',
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Photographers Category
                      _buildCategoryCard(
                        title: 'Photographers',
                        subtitle: 'Photographers',
                        backgroundColor: const Color(0xFFFFF9C4), // Light yellow
                        isExpanded: isPhotographersExpanded,
                        onTap: () => setState(() => isPhotographersExpanded = !isPhotographersExpanded),
                        image: 'assets/images/photographers.jpg',
                        subcategories: [
                          '',
                          'Photographers',
                          '',
                        ],

                      ),

                      const SizedBox(height: 12),

                      // Makeup Category
                      _buildCategoryCard(
                        title: 'Makeup',
                        subtitle: 'Bridal Makeup, Family Makeup',
                        backgroundColor: const Color(0xFFE1BEE7), // Light purple
                        isExpanded: isMakeupExpanded,
                        onTap: () => setState(() => isMakeupExpanded = !isMakeupExpanded),
                        image: 'assets/images/makeup.jpg',
                        subcategories: [
                          '',
                          'Bridal Makeup',
                          '',
                          'Family Makeup',
                          '',
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Planning & Decor Category
                      _buildCategoryCard(
                        title: 'Planning & Decor',
                        subtitle: 'Wedding planners, Decorators',
                        backgroundColor: const Color(0xFFFCE4EC), // Light pink
                        isExpanded: isPlanningExpanded,
                        onTap: () => setState(() => isPlanningExpanded = !isPlanningExpanded),
                        image: 'assets/images/planning.jpg',
                        subcategories: [
                          '',
                          'Wedding Planners',
                          '',
                          'Decorators',
                          '',
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Virtual Planning Category
                      _buildCategoryCard(
                        title: 'Virtual Planning',
                        subtitle: 'Virtual planning',
                        backgroundColor: const Color(0xFFE0F2F1), // Light teal
                        isExpanded: isVirtualPlanningExpanded,
                        onTap: () => setState(() => isVirtualPlanningExpanded = !isVirtualPlanningExpanded),
                        image: 'assets/images/virtual_planning.jpg',
                        subcategories: [
                          '',
                          'Virtual Planning',
                          '',

                        ],
                      ),

                      const SizedBox(height: 12),

                      // Mehndi Category
                      _buildCategoryCard(
                        title: 'Mehndi',
                        subtitle: 'Mehndi Artist',
                        backgroundColor: const Color(0xFFE8F5E8), // Light green
                        isExpanded: isMehndiExpanded,
                        onTap: () => setState(() => isMehndiExpanded = !isMehndiExpanded),
                        image: 'assets/images/mehndi.jpg',
                        subcategories: [
                          '',
                          'Mehendi Artist',
                          '',
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Music & Dance Category
                      _buildCategoryCard(
                        title: 'Music & Dance',
                        subtitle: 'DJs, Bands, Choreographers',
                        backgroundColor: const Color(0xFFFBE9E7), // Light orange
                        isExpanded: isMusicDanceExpanded,
                        onTap: () => setState(() => isMusicDanceExpanded = !isMusicDanceExpanded),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'DJs',
                          '',
                          'Sangeet Choreographer',
                          '',
                          'Wedding Entertainment',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Music & Dance Category
                      _buildCategoryCard(
                        title: 'Food',
                        subtitle: 'Catering Services, Cake, Chaat & Food Stalls, Bartenders',
                        backgroundColor: const Color(0xFFEDE7F6), // Light orange
                        isExpanded: isFoodExpanded,
                        onTap: () => setState(() => isFoodExpanded = !isFoodExpanded),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Catering Services',
                          '',
                          'Cake',
                          '',
                          'Chaat & Food Stalls',
                          '',
                          'Bartenders',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Music & Dance Category
                      _buildCategoryCard(
                        title: 'Invites & Gifts',
                        subtitle: 'Invitations,Favours,Trousseau Packers',
                        backgroundColor: const Color(0xFFFBE9E7), // Light orange
                        isExpanded: isGiftExpanded,
                        onTap: () => setState(() => isGiftExpanded = !isGiftExpanded),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Invitations',
                          '',
                          'Favours',
                          '',
                          'Trousseau Packers',
                          '',
                          'Invitations Gifts',
                          '',
                          'Mehendi Favours',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Music & Dance Category
                      // _buildCategoryCard(
                      //   title: 'Food',
                      //   subtitle: 'Catering Services, Cake, Chaat & Food Stalls, Bartenders',
                      //   backgroundColor: const Color(0xFFFFF3E0), // Light orange
                      //   isExpanded: isMusicDanceExpanded,
                      //   onTap: () => setState(() => isMusicDanceExpanded = !isMusicDanceExpanded),
                      //   image: 'assets/images/music_dance.jpg',
                      //   subcategories: [
                      //     '',
                      //     'Catering Services',
                      //     '',
                      //     'Cake',
                      //     '',
                      //     'Chaat & Food Stalls',
                      //     '',
                      //     'Bartenders',
                      //     '',
                      //   ],
                      // ),
                      // const SizedBox(height: 12),

                      // Music & Dance Category
                      _buildCategoryCard(
                        title: 'Pre Wedding Shoot',
                        subtitle: 'Pre Wedding Shoot Locations, Pre Wedding Photographers',
                        backgroundColor: const Color(0xFFFFFDE7), // Light orange
                        isExpanded: isprewedshot,
                        onTap: () => setState(() => isprewedshot = !isprewedshot),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Pre Wedding Shoot Locations',
                          '',
                          'Pre Wedding Photographers',
                          '',

                        ],
                      ),
                      const SizedBox(height: 12),

                      // Music & Dance Category
                      _buildCategoryCard(
                        title: 'Bridal Wear',
                        subtitle: 'Bridal Lehengas, Kanjeevaram/Silk Sarees, Cocktail Gowns, Trousseau Sarees, Bridal Lehenga on Rent',
                        backgroundColor: const Color(0xFFE0F7FA), // Light orange
                        isExpanded: isbridewear,
                        onTap: () => setState(() => isbridewear = !isbridewear),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Bridal Lehengas',
                          '',
                          'Kanjeevaram/Silk Sarees',
                          '',
                          'Cocktail Gowns',
                          '',
                          'Trousseau Sarees',
                          '',
                          'Bridal Lehenga on Rent',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Music & Dance Category
                      _buildCategoryCard(
                        title: 'Groom Wear',
                        subtitle: 'Sherwani, Wedding Suits/Tuxes, Sherwani On Rent',
                        backgroundColor: const Color(0xFFFFEBEE), // Light orange
                        isExpanded: isgroomwear,
                        onTap: () => setState(() => isgroomwear = !isgroomwear),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Sherwani',
                          '',
                          'Wedding Suits/Tuxes',
                          '',
                          'Sherwani On Rent',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryCard(
                        title: 'Jewellery & Accessories',
                        subtitle: 'Jewellery, Flower Jewellery, Bridal Jewellery on Rent, Accessories',
                        backgroundColor: const Color(0xFFF1F8E9), // Light orange
                        isExpanded: isjewellery ,
                        onTap: () => setState(() => isjewellery = !isjewellery),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Jewellery',
                          '',
                          'Flower Jewellery',
                          '',
                          'Bridal Jewellery on Rent',
                          '',
                          'Accessories',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryCard(
                        title: 'Pandits',
                        subtitle: 'Wedding Pandits',
                        backgroundColor: const Color(0xFFE3F2FD), // Light orange
                        isExpanded: ispandit,
                        onTap: () => setState(() => ispandit = !ispandit),
                        image: 'assets/images/music_dance.jpg',
                        subcategories: [
                          '',
                          'Wedding Pandits',
                          '',
                        ],
                      ),
                      const SizedBox(height: 12),

                      const SizedBox(height: 20),
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

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required bool isExpanded,
    required VoidCallback onTap,
    required String image,
    required List<String> subcategories,
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
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
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
                  // Category Image
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
                      child: Container(
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 30,
                        ),
                        // Replace with actual image:
                        // Image.asset(
                        //   image,
                        //   fit: BoxFit.cover,
                        // ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Subcategories
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.grey),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: subcategories.map((subcategory) {
                  if (subcategory.isEmpty) {
                    return const SizedBox(height: 8);
                  }
                  return InkWell(
                    onTap: () {
                      // Handle subcategory tap
                      print('Tapped: $subcategory');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
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
