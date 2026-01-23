import 'package:flutter/material.dart';

import '../Bottombars/Vendor.dart';

// class PhotographerScreen extends StatefulWidget {
//
//   const PhotographerScreen({Key? key,}) : super(key: key);
//
//   @override
//   State<PhotographerScreen> createState() => _PhotographerScreenState();
// }
//
// class _PhotographerScreenState extends State<PhotographerScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),
//               Color(0xFFFFB6C1),
//               Colors.white,
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildAppBar(context),
//               _buildSearchBar(),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildDestinationRatesSection(),
//                       const SizedBox(height: 24),
//                       _buildDestinationRatesSection(),
//                       const SizedBox(height: 24),
//                       _buildDestinationRatesSection(),
//                       const SizedBox(height: 24),
//                       _buildDestinationRatesSection(),
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
//   Widget _buildAppBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Expanded(
//             child: Text(
//               'Photographers',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 48), // Balance the back button
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.9),
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: const TextField(
//           decoration: InputDecoration(
//             hintText: 'Search wedding photographers...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDestinationRatesSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 height: 200,
//                 decoration: const BoxDecoration(
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(12),
//                     topRight: Radius.circular(12),
//                   ),
//                   image: DecorationImage(
//                     // 👉 You can replace with photographers image
//                     image: NetworkImage('https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400&h=300&fit=crop'),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Pune, Maharashtra',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Candid Moments Photography',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 'Wedding Photographer',
//                                 style: TextStyle(
//                                   fontSize: 12,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.orange,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Icon(Icons.star, color: Colors.white, size: 12),
//                               SizedBox(width: 2),
//                               Text(
//                                 '4.9(50)',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       '₹ 49,999 per day',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: const [
//                         Icon(Icons.camera_alt, size: 16, color: Colors.grey),
//                         SizedBox(width: 4),
//                         Text(
//                           'Candid, Traditional, Pre-wedding',
//                           style: TextStyle(fontSize: 12, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Color(0xFFE91E63)),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.message, color: Color(0xFFE91E63), size: 18),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'Message',
//                                   style: TextStyle(
//                                     color: Color(0xFFE91E63),
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.green,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: const Icon(Icons.message, color: Colors.white, size: 18),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.green,
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: const Icon(Icons.phone, color: Colors.white, size: 18),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Vendor>> fetchPhotographers() async {
  final url = Uri.parse('https://happywedz.com/api/vendor-services?subCategory=photographers');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((json) => Vendor.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load photographers');
  }
}

class Vendor {
  final String name;
  final String subcategory;
  final String city;
  final String state;
  final String address;
  final String description;
  final int startingPrice;
  final String phone;
  final String email;
  final String website;
  final String whatsapp;
  final String tagline;
  final List<String> images;
  final String priceUnit;
  final String alcoholPolicy;
  final String cancellationPolicy;
  final bool availableForTravel;

  Vendor({
    required this.name,
    required this.subcategory,
    required this.city,
    required this.state,
    required this.address,
    required this.description,
    required this.startingPrice,
    required this.phone,
    required this.email,
    required this.website,
    required this.whatsapp,
    required this.tagline,
    required this.images,
    required this.priceUnit,
    required this.alcoholPolicy,
    required this.cancellationPolicy,
    this.availableForTravel = true,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['media']?['gallery'] != null) {
      for (var img in json['media']['gallery']) {
        if (img is Map && img['id'] != null) {
          imagesList.add('https://happywedz.com/uploads/${img['id']}');
        } else if (img is String) {
          imagesList.add('https://happywedz.com$img');
        }
      }
    }

    final attr = json['attributes'] ?? {};
    final contact = attr['contact'] ?? {};

    return Vendor(
      name: attr['name'] ?? json['vendor']?['businessName'] ?? 'Unknown',
      subcategory: json['subcategory']?['name'] ?? 'Photographer',
      city: attr['location']?['city'] ?? 'Unknown',
      state: attr['location']?['state'] ?? '',
      address: attr['location']?['address'] ?? '',
      description: attr['description'] ?? '',
      startingPrice: attr['starting_price'] ?? 0,
      phone: contact['phone'] ?? json['vendor']?['phone'] ?? '',
      email: contact['email'] ?? json['vendor']?['email'] ?? '',
      website: contact['website'] ?? '',
      whatsapp: contact['whatsapp'] ?? '',
      tagline: attr['tagline'] ?? '',
      images: imagesList,
      priceUnit: attr['price_unit'] ?? '',
      alcoholPolicy: attr['alcohol_policy'] ?? '',
      cancellationPolicy: attr['cancellation_policy'] ?? '',
      availableForTravel: true,
    );
  }
}


class PhotographerScreen extends StatefulWidget {
  const PhotographerScreen({Key? key}) : super(key: key);

  @override
  State<PhotographerScreen> createState() => _PhotographerScreenState();
}

class _PhotographerScreenState extends State<PhotographerScreen> {
  late Future<List<Vendor>> _vendorsFuture;

  @override
  void initState() {
    super.initState();
    _vendorsFuture = fetchPhotographers();
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
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              Expanded(
                child: FutureBuilder<List<Vendor>>(
                  future: _vendorsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No photographers found.'));
                    }

                    final vendors = snapshot.data!;
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: vendors.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        final vendor = vendors[index];
                        return _buildVendorCard(vendor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    final image = vendor.images.isNotEmpty
        ? vendor.images[0]
        : 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400&h=300&fit=crop';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PhotographerDetailsScreen(vendor: vendor)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.city, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(vendor.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(vendor.subcategory, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text('₹${vendor.startingPrice} ${vendor.priceUnit}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Expanded(
            child: Text(
              'Photographers',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(25)),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search wedding photographers...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}








































class PhotographerDetailsScreen extends StatefulWidget {
  final Vendor vendor;

  const PhotographerDetailsScreen({required this.vendor, Key? key}) : super(key: key);

  @override
  State<PhotographerDetailsScreen> createState() => _PhotographerDetailsScreenState();
}

class _PhotographerDetailsScreenState extends State<PhotographerDetailsScreen> with SingleTickerProviderStateMixin {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFFE91E63),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: vendor.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        vendor.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.photo_camera, size: 50, color: Colors.white54),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(vendor.images.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentImageIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index ? Colors.white : Colors.white54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Title
                  Text(vendor.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${vendor.city}, ${vendor.state}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  const SizedBox(height: 16),

                  // Albums
                  if (vendor.images.length > 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Albums', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: vendor.images.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(vendor.images[index], fit: BoxFit.cover),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                  // About
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Text(vendor.description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
                  const SizedBox(height: 32),

                  // Details
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(vendor.phone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.email, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(vendor.email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(vendor.address, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.message, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Message', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




