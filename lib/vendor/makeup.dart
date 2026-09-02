import 'package:flutter/material.dart';

import '../core/core.dart';

// class MakeupScreen extends StatelessWidget {
//   const MakeupScreen({Key? key}) : super(key: key);
//
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
//                       _buildMakeupCard(),
//                       const SizedBox(height: 24),
//                       _buildMakeupCard(),
//                       const SizedBox(height: 24),
//                       _buildMakeupCard(),
//                       const SizedBox(height: 24),
//                       _buildMakeupCard(),
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
//               'Makeup',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 48),
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
//           color: Colors.white.withValues(alpha: 0.9),
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: const TextField(
//           decoration: InputDecoration(
//             hintText: 'Search bridal makeup artists...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMakeupCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             height: 200,
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//               image: DecorationImage(
//                 image: NetworkImage(
//                   'https://images.unsplash.com/photo-1522337660859-02fbefca4702?w=400&h=300&fit=crop',
//                 ),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Koregaon Park, Pune',
//                             style: TextStyle(fontSize: 12, color: Colors.grey),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'Glam Studio Makeup Artist',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           SizedBox(height: 4),
//                           Text(
//                             'Bridal, Party Makeup',
//                             style: TextStyle(fontSize: 12, color: Colors.grey),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Container(
//                       padding:
//                       const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.orange,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.star, color: Colors.white, size: 12),
//                           SizedBox(width: 2),
//                           Text(
//                             '4.9(120)',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 10,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   '₹ 15,000 onwards',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: const [
//                     Icon(Icons.location_on, size: 16, color: Colors.grey),
//                     SizedBox(width: 4),
//                     Text(
//                       'Available for travel',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                     SizedBox(width: 16),
//                     Icon(Icons.brush, size: 16, color: Colors.grey),
//                     SizedBox(width: 4),
//                     Text(
//                       'HD & Airbrush Makeup',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: const Color(0xFFE91E63)),
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.message,
//                                 color: Color(0xFFE91E63), size: 18),
//                             SizedBox(width: 8),
//                             Text(
//                               'Message',
//                               style: TextStyle(
//                                 color: Color(0xFFE91E63),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: const Icon(Icons.message,
//                           color: Colors.white, size: 18),
//                     ),
//                     const SizedBox(width: 8),
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: const Icon(Icons.phone,
//                           color: Colors.white, size: 18),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:happy_wedz/core/config/api_config.dart';

class MakeupScreen extends StatefulWidget {
  const MakeupScreen({Key? key}) : super(key: key);

  @override
  State<MakeupScreen> createState() => _MakeupScreenState();
}

class _MakeupScreenState extends State<MakeupScreen> {
  List<dynamic> makeupList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMakeupVendors();
  }

  Future<void> fetchMakeupVendors() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.apiBase}/vendor-services?subCategory=bridal%20makeup'),
      );

      if (response.statusCode == 200) {
        setState(() {
          makeupList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error: $e');
    }
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
                child: isLoading
                    ? const AppLoader()
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: makeupList
                        .map((vendor) => Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildMakeupCard(vendor),
                    ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Makeup',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
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
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search bridal makeup artists...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildMakeupCard(dynamic vendor) {
    final attributes = vendor['attributes'];
    final location = attributes['location'];

    // Determine image
    String imageUrl = '';
    if (vendor['media'] != null &&
        vendor['media']['gallery'] != null &&
        vendor['media']['gallery'].isNotEmpty) {
      final gallery = vendor['media']['gallery'];
      if (gallery[0] is Map && gallery[0]['id'] != null) {
        imageUrl = '${ApiConfig.baseUrl}/uploads/${gallery[0]['id']}';
      } else if (gallery[0] is String) {
        imageUrl = '${ApiConfig.baseUrl}${gallery[0]}';
      }
    } else {
      imageUrl =
      'https://images.unsplash.com/photo-1522337660859-02fbefca4702?w=400&h=300&fit=crop';
    }

    return GestureDetector(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BridalDetailsScreen(  vendor: BridalVendor.fromJson(vendor),),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location['city'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              attributes['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              vendor['subcategory']['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 12),
                            SizedBox(width: 2),
                            Text(
                              '4.9(120)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '₹ ${attributes['starting_price'] ?? 'N/A'} onwards',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Available for travel',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.brush, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'HD & Airbrush Makeup',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE91E63)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message,
                                  color: Color(0xFFE91E63), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Message',
                                style: TextStyle(
                                  color: Color(0xFFE91E63),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.message,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child:
                        const Icon(Icons.phone, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




class BridalVendor {
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

  BridalVendor({
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

  factory BridalVendor.fromJson(Map<String, dynamic> json) {
    // Parse gallery images
    List<String> imagesList = [];
    if (json['media'] != null &&
        json['media']['gallery'] != null &&
        (json['media']['gallery'] as List).isNotEmpty) {
      for (var img in json['media']['gallery']) {
        if (img is Map && img['id'] != null) {
          imagesList.add('${ApiConfig.baseUrl}/uploads/${img['id']}');
        } else if (img is String) {
          imagesList.add('${ApiConfig.baseUrl}$img');
        }
      }
    }

    final attributes = json['attributes'] ?? {};
    final contact = attributes['contact'] ?? {};

    return BridalVendor(
      name: attributes['name'] ?? json['vendor']?['businessName'] ?? 'Unknown',
      subcategory: json['subcategory']?['name'] ?? 'Bridal Makeup',
      city: attributes['location']?['city'] ?? 'Unknown',
      state: attributes['location']?['state'] ?? '',
      address: attributes['location']?['address'] ?? '',
      description: attributes['description'] ?? 'No description available',
      startingPrice: attributes['starting_price'] ?? 0,
      phone: contact['phone'] ?? json['vendor']?['phone'] ?? '',
      email: contact['email'] ?? json['vendor']?['email'] ?? '',
      website: contact['website'] ?? '',
      whatsapp: contact['whatsapp'] ?? '',
      tagline: attributes['tagline'] ?? '',
      images: imagesList,
      priceUnit: attributes['price_unit'] ?? '',
      alcoholPolicy: attributes['alcohol_policy'] ?? '',
      cancellationPolicy: attributes['cancellation_policy'] ?? '',
      availableForTravel: true, // default, can extend based on API
    );
  }
}


class BridalDetailsScreen extends StatefulWidget {
  final BridalVendor vendor;

  BridalDetailsScreen({required this.vendor});

  @override
  _BridalDetailsScreenState createState() => _BridalDetailsScreenState();
}

class _BridalDetailsScreenState extends State<BridalDetailsScreen> {
  PageController _pageController = PageController();
  int _currentImageIndex = 0;

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
            backgroundColor: Color(0xFFE91E63),
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
                      return NetworkImageWidget(url: vendor.images[index], fit: BoxFit.cover);
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
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
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
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('${vendor.city}, ${vendor.state}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 8),
                  Text(vendor.address, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  SizedBox(height: 16),

                  Text('Tagline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(vendor.tagline, style: TextStyle(fontSize: 14, color: Colors.grey[700])),

                  SizedBox(height: 16),
                  Text('Starting Price', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('₹${vendor.startingPrice} ${vendor.priceUnit}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),

                  SizedBox(height: 16),
                  Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text(vendor.description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),

                  SizedBox(height: 16),
                  Text('Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Alcohol Policy: ${vendor.alcoholPolicy}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  Text('Cancellation Policy: ${vendor.cancellationPolicy}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),

                  SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Implement messaging functionality
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Message', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // Call vendor.phone
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.phone, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          // Open vendor.website
                        },
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.web, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

