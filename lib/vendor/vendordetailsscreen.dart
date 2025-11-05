import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';

import '../chat/chat_screen.dart';
import '../chat/chat_service.dart';
import '../chat_page_new.dart';
import '../main.dart';
//
// class VendorServicesScreen extends StatefulWidget {
//   final String subcategoryName;
//
//   const VendorServicesScreen({Key? key, required this.subcategoryName}) : super(key: key);
//
//   @override
//   State<VendorServicesScreen> createState() => _VendorServicesScreenState();
// }
//
// class _VendorServicesScreenState extends State<VendorServicesScreen> {
//   List<dynamic> services = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//   }
//
//   Future<void> fetchServices() async {
//     try {
//       final encodedSubcategory = Uri.encodeComponent(widget.subcategoryName.toLowerCase()); // Use exact casing
//
//       final url = Uri.parse(
//         "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory",
//       );
//
//       print("Fetching services from: $url"); // debug
//
//       final response = await http.get(
//         url,
//         headers: {"Accept": "application/json"},
//       );
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         setState(() {
//           services = data;
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//         print("Error fetching ${widget.subcategoryName} services: ${response.statusCode}");
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       print("API Error: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.subcategoryName),
//         backgroundColor: Colors.pink,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : services.isEmpty
//           ? const Center(child: Text("No services found"))
//           : ListView.builder(
//         itemCount: services.length,
//         itemBuilder: (context, index) {
//           final service = services[index];
//           final attributes = service['attributes'] ?? {};
//           final vendor = service['vendor'] ?? {};
//           final media = service['media'] ?? {};
//
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             child: ListTile(
//               leading: (media['coverImage'] != null && media['coverImage'] != "")
//                   ? Image.network(
//                 "https://happywedz.com/api/${media['coverImage']}",
//                 width: 60,
//                 height: 60,
//                 fit: BoxFit.cover,
//               )
//                   : const Icon(Icons.image, size: 40, color: Colors.grey),
//               title: Text(vendor['businessName'] ?? attributes['name'] ?? "No Name"),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (attributes['description'] != null &&
//                       attributes['description'].toString().isNotEmpty)
//                     Text(attributes['description']),
//                   if (attributes['starting_price'] != null)
//                     Text("Starting Price: ₹${attributes['starting_price']}"),
//                   if (attributes['location'] != null &&
//                       attributes['location']['city'] != null)
//                     Text("City: ${attributes['location']['city']}"),
//                 ],
//               ),
//               trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//               onTap: () {
//                 // You can navigate to a detailed vendor screen here
//                 print("Tapped on vendor: ${vendor['businessName']}");
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'vendor_details_screen.dart';

class VendorServicesScreen extends StatefulWidget {
  final String subcategoryName;

  const VendorServicesScreen({Key? key, required this.subcategoryName})
      : super(key: key);

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  List<dynamic> services = [];
  bool isLoading = true;
  String? currentUserId; // ✅ store logged-in user id

  @override
  void initState() {
    super.initState();
    fetchServices();
    _loadCurrentUser();
  }
// Replace the entire fetchServices method in VendorServicesScreen:
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }
  Future<void> fetchServices() async {
    try {
      final encodedSubcategory = Uri.encodeComponent(widget.subcategoryName.toLowerCase());
      final url = Uri.parse("https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory");
      print("🔍 Fetching services from: $url");

      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> servicesList = [];

        // Handle both List and Map responses
        if (data is List) {
          servicesList = data;
        } else if (data is Map) {
          // Try to extract data from common API response structures
          if (data['data'] != null && data['data'] is List) {
            servicesList = data['data'];
          } else if (data['services'] != null && data['services'] is List) {
            servicesList = data['services'];
          } else {
            // If it's a single object, wrap it in a list
            servicesList = [data];
          }
        }

        print("✅ Found ${servicesList.length} services");

        // Debug first service structure
        if (servicesList.isNotEmpty) {
          print("📦 First service structure: ${json.encode(servicesList[0])}");
        }

        setState(() {
          services = servicesList;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("❌ Error fetching services: ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      print("💥 API Error: $e");
      print("Stack trace: $stackTrace");
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
              _buildAppBar(),
              _buildSearchBar(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : services.isEmpty
                    ? const Center(child: Text("No services found"))
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: services
                        .map((service) => _buildServiceCard(service))
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.subcategoryName,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search services...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }
  Widget _buildServiceCard(dynamic service) {
    final attributes = service['attributes'] ?? {};
    final vendor = service['vendor'] ?? {};
    final media = service['media'] ?? {};

    String imageUrl = 'https://via.placeholder.com/400x300';

    if (media is Map && media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
      final cover = media['coverImage'].toString();
      imageUrl = cover.startsWith('/uploads/')
          ? "https://happywedzbackend.happywedz.com$cover"
          : cover;
    } else if (media is Map && media['gallery'] != null) {
      final gallery = media['gallery'];
      if (gallery is List && gallery.isNotEmpty) {
        for (var item in gallery) {
          if (item is String && item.startsWith('/uploads/')) {
            imageUrl = "https://happywedzbackend.happywedz.com$item";
            break;
          } else if (item is Map && item['url'] != null) {
            final url = item['url'].toString();
            imageUrl = url.startsWith('/uploads/')
                ? "https://happywedzbackend.happywedz.com$url"
                : url;
            break;
          }
        }
      }
    }
    final vendorId = service['vendor_id'].toString();

    final String businessName = vendor['businessName'] ?? attributes['name'] ?? 'Unnamed Venue';
    final String city = attributes['city'] ?? vendor['city'] ?? 'Unknown Location';
    final double rating = double.tryParse((vendor['rating'] ?? attributes['rating'] ?? '0').toString()) ?? 0.0;

    String priceText = '';
    final vegPrice = attributes['veg_price']?.toString() ?? '';
    final startingPrice = attributes['starting_price']?.toString() ?? '';
    final photoPackagePrice = attributes['photo_package_price']?.toString() ??
        attributes['PhotoPackage_Price']?.toString() ??
        '';

    if (vegPrice.isNotEmpty) {
      priceText = '₹$vegPrice per plate';
    } else if (startingPrice.isNotEmpty) {
      priceText = '₹$startingPrice onwards';
    } else if (photoPackagePrice.isNotEmpty) {
      priceText = photoPackagePrice;
    }

    final phone = vendor['phone']?.toString() ?? attributes['Phone']?.toString() ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailsScreen(service: service),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, size: 50, color: Colors.white),
                    ),
                  ),
                ),

                // 📍 Location overlay (bottom left)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ⭐ Rating badge (top right, shifted left slightly)
                if (rating > 0)
                  Positioned(
                    top: 8,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),

                // ❤️ Favourite icon (top right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () {
                      // TODO: Handle favourite toggle logic
                      // e.g. setState(() { isFav = !isFav; });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.pinkAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 📝 Details section (same as before)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (priceText.isNotEmpty)
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (currentUserId == null || currentUserId!.isEmpty) {
                              // 🚀 Redirect user to SignInScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignInScreen()),
                              );
                              return;
                            }

                            final vendorId = service['vendor_id']?.toString() ??
                                vendor['id']?.toString() ??
                                attributes['vendor_id']?.toString() ??
                                '';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  currentUid: currentUserId!,   // ✅ logged-in user
                                  otherUid: vendorId,           // ✅ vendor id
                                  otherName: businessName,      // ✅ vendor name
                                ),
                              ),
                            );
                          },

                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE91E63),
                            side: const BorderSide(color: Color(0xFFE91E63)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chat, color: Colors.white, size: 18),
                          onPressed: () {
                            if (phone.isNotEmpty) {}
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                          onPressed: () {
                            if (phone.isNotEmpty) {
                              final uri = Uri(scheme: 'tel', path: phone);
                              launchUrl(uri);
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
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

// Widget _buildServiceCard(dynamic service) {
  //   final attributes = service['attributes'] ?? {};
  //   final vendor = service['vendor'] ?? {};
  //   final media = service['media'] ?? {};
  //
  //   // Extract image - media is a Map, not a List
  //   String imageUrl = 'https://via.placeholder.com/400x300';
  //
  //   // Try coverImage first
  //   if (media is Map && media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
  //     final cover = media['coverImage'].toString();
  //     imageUrl = cover.startsWith('/uploads/')
  //         ? "https://happywedzbackend.happywedz.com$cover"
  //         : cover;
  //   }
  //   // Try gallery if coverImage not found
  //   else if (media is Map && media['gallery'] != null) {
  //     final gallery = media['gallery'];
  //     if (gallery is List && gallery.isNotEmpty) {
  //       for (var item in gallery) {
  //         if (item is String && item.startsWith('/uploads/')) {
  //           imageUrl = "https://happywedzbackend.happywedz.com$item";
  //           break;
  //         } else if (item is Map && item['url'] != null) {
  //           final url = item['url'].toString();
  //           imageUrl = url.startsWith('/uploads/')
  //               ? "https://happywedzbackend.happywedz.com$url"
  //               : url;
  //           break;
  //         }
  //       }
  //     }
  //   }
  //
  //   // Extract data
  //   final String businessName = vendor['businessName'] ?? attributes['name'] ?? 'Unnamed Venue';
  //   final String city = attributes['city'] ?? vendor['city'] ?? 'Nashik';
  //   final String address = attributes['address'] ?? attributes['Address'] ?? '';
  //   final double rating = double.tryParse((vendor['rating'] ?? attributes['rating'] ?? '0').toString()) ?? 0.0;
  //   final int reviewCount = int.tryParse((attributes['review_count'] ?? '0').toString()) ?? 0;
  //
  //   // Pricing - handle different vendor types
  //   String priceText = '';
  //   final vegPrice = attributes['veg_price']?.toString() ?? '';
  //   final startingPrice = attributes['starting_price']?.toString() ?? '';
  //   final photoPackagePrice = attributes['photo_package_price']?.toString() ?? attributes['PhotoPackage_Price']?.toString() ?? '';
  //
  //   if (vegPrice.isNotEmpty) {
  //     priceText = '₹$vegPrice per plate';
  //   } else if (startingPrice.isNotEmpty) {
  //     priceText = '₹$startingPrice onwards';
  //   } else if (photoPackagePrice.isNotEmpty) {
  //     priceText = photoPackagePrice;
  //   }
  //
  //   // Phone
  //   final phone = vendor['phone']?.toString() ?? attributes['Phone']?.toString() ?? '';
  //
  //   return InkWell(
  //     onTap: () {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => VendorDetailsScreen(service: service),
  //         ),
  //       );
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.only(bottom: 16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(8),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(0.08),
  //             blurRadius: 8,
  //             offset: const Offset(0, 2),
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Image with location overlay
  //           Stack(
  //             children: [
  //               ClipRRect(
  //                 borderRadius: const BorderRadius.only(
  //                   topLeft: Radius.circular(8),
  //                   topRight: Radius.circular(8),
  //                 ),
  //                 child: Image.network(
  //                   imageUrl,
  //                   height: 200,
  //                   width: double.infinity,
  //                   fit: BoxFit.cover,
  //                   errorBuilder: (context, error, stackTrace) => Container(
  //                     height: 200,
  //                     color: Colors.grey[300],
  //                     child: const Icon(Icons.image, size: 50, color: Colors.white),
  //                   ),
  //                 ),
  //               ),
  //               // Location overlay at bottom left
  //               Positioned(
  //                 bottom: 8,
  //                 left: 8,
  //                 child: Container(
  //                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                   decoration: BoxDecoration(
  //                     color: Colors.black.withOpacity(0.6),
  //                     borderRadius: BorderRadius.circular(4),
  //                   ),
  //                   child: Row(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       const Icon(Icons.location_on, color: Colors.white, size: 12),
  //                       const SizedBox(width: 4),
  //                       Text(
  //                         city,
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 11,
  //                           fontWeight: FontWeight.w500,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               // Rating badge at top right
  //               if (rating > 0)
  //                 Positioned(
  //                   top: 8,
  //                   right: 8,
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                     decoration: BoxDecoration(
  //                       color: Colors.green,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                     child: Row(
  //                       mainAxisSize: MainAxisSize.min,
  //                       children: [
  //                         Text(
  //                           rating.toStringAsFixed(1),
  //                           style: const TextStyle(
  //                             color: Colors.white,
  //                             fontSize: 12,
  //                             fontWeight: FontWeight.bold,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 2),
  //                         const Icon(Icons.star, color: Colors.white, size: 12),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //             ],
  //           ),
  //
  //           // Details section
  //           Padding(
  //             padding: const EdgeInsets.all(12),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 // Venue name
  //                 Text(
  //                   businessName,
  //                   style: const TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w700,
  //                     color: Colors.black87,
  //                   ),
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                 ),
  //
  //                 const SizedBox(height: 6),
  //
  //                 // Price
  //                 if (priceText.isNotEmpty)
  //                   Text(
  //                     priceText,
  //                     style: const TextStyle(
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w600,
  //                       color: Color(0xFFE91E63),
  //                     ),
  //                   ),
  //
  //                 const SizedBox(height: 12),
  //
  //                 // Action buttons
  //                 Row(
  //                   children: [
  //                     // Message button
  //                     Expanded(
  //                       child: OutlinedButton.icon(
  //                         onPressed: () {
  //                           // Handle message
  //                         },
  //                         icon: const Icon(Icons.message, size: 16),
  //                         label: const Text('Message'),
  //                         style: OutlinedButton.styleFrom(
  //                           foregroundColor: const Color(0xFFE91E63),
  //                           side: const BorderSide(color: Color(0xFFE91E63)),
  //                           padding: const EdgeInsets.symmetric(vertical: 10),
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(6),
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //
  //                     const SizedBox(width: 8),
  //
  //                     // WhatsApp button
  //                     Container(
  //                       height: 40,
  //                       width: 40,
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFF25D366),
  //                         borderRadius: BorderRadius.circular(6),
  //                       ),
  //                       child: IconButton(
  //                         icon: const Icon(Icons.chat, color: Colors.white, size: 18),
  //                         onPressed: () {
  //                           // Handle WhatsApp
  //                           if (phone.isNotEmpty) {
  //                             // Launch WhatsApp with phone
  //                           }
  //                         },
  //                         padding: EdgeInsets.zero,
  //                       ),
  //                     ),
  //
  //                     const SizedBox(width: 8),
  //
  //                     // Call button
  //                     Container(
  //                       height: 40,
  //                       width: 40,
  //                       decoration: BoxDecoration(
  //                         color: Colors.green,
  //                         borderRadius: BorderRadius.circular(6),
  //                       ),
  //                       child: IconButton(
  //                         icon: const Icon(Icons.phone, color: Colors.white, size: 18),
  //                         onPressed: () {
  //                           // Handle call
  //                           if (phone.isNotEmpty) {
  //                             final uri = Uri(scheme: 'tel', path: phone);
  //                             launchUrl(uri);
  //                           }
  //                         },
  //                         padding: EdgeInsets.zero,
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  //   Widget _buildServiceCard(dynamic service) {

//     final attributes = service['attributes'] ?? {};
//     final vendor = service['vendor'] ?? {};
//     final media = service['media'] ?? {};
//
//     // ✅ Determine proper image URL
//     String imageUrl = 'https://via.placeholder.com/400x300';
//
// // 1️⃣ Try cover image if exists
//     if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
//       final cover = media['coverImage'].toString();
//       imageUrl = cover.startsWith('/uploads/')
//           ? "https://happywedzbackend.happywedz.com$cover"
//           : cover;
//     }
//
// // 2️⃣ If no coverImage, try gallery images
//     else if (media['gallery'] != null && media['gallery'] is List) {
//       for (var item in media['gallery']) {
//         if (item is String && item.startsWith('/uploads/')) {
//           imageUrl = "https://happywedzbackend.happywedz.com$item";
//           break;
//         } else if (item is Map && item['url'] != null) {
//           final url = item['url'].toString();
//           imageUrl = url.startsWith('/uploads/')
//               ? "https://happywedzbackend.happywedz.com$url"
//               : url;
//           break;
//         }
//       }
//     }
//
// // 3️⃣ Log what we’re using
//     print("🧩 Final image used for ${vendor['businessName'] ?? 'Unknown'}: $imageUrl");
//
//
//
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VendorDetailsScreen(service: service),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ✅ Updated cover image logic
//             ClipRRect(
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(12),
//                 topRight: Radius.circular(12),
//               ),
//               child: Image.network(
//                 imageUrl,
//                 height: 200,
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) => Container(
//                   height: 200,
//                   color: Colors.grey[300],
//                   child: const Icon(Icons.image, size: 50, color: Colors.white),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     vendor['businessName'] ?? attributes['name'] ?? "No Name",
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   if (attributes['description'] != null &&
//                       attributes['description'].toString().isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(
//                         attributes['description'],
//                         style: const TextStyle(color: Colors.grey),
//                       ),
//                     ),
//                   if (attributes['starting_price'] != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Text(
//                         "Starting Price: ₹${attributes['starting_price']}",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Color(0xFFE91E63)),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: const Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.message,
//                                   color: Color(0xFFE91E63), size: 18),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Message',
//                                 style: TextStyle(
//                                   color: Color(0xFFE91E63),
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child:
//                         const Icon(Icons.phone, color: Colors.white, size: 18),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
}



//
// class VendorServicesScreen extends StatefulWidget {
//   final String subcategoryName;
//
//   const VendorServicesScreen({Key? key, required this.subcategoryName}) : super(key: key);
//
//   @override
//   State<VendorServicesScreen> createState() => _VendorServicesScreenState();
// }
//
// class _VendorServicesScreenState extends State<VendorServicesScreen> {
//   List<dynamic> services = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchServices();
//   }
//
//   Future<void> fetchServices() async {
//     try {
//       final encodedSubcategory = Uri.encodeComponent(widget.subcategoryName.toLowerCase());
//       final url = Uri.parse("https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory");
//       print("Fetching services from: $url");
//
//       final response = await http.get(url, headers: {"Accept": "application/json"});
//
//       if (response.statusCode == 200) {
//         final List<dynamic> data = json.decode(response.body);
//         setState(() {
//           services = data;
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//         print("Error fetching services: ${response.statusCode}");
//       }
//     } catch (e) {
//       setState(() => isLoading = false);
//       print("API Error: $e");
//     }
//   }
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
//               _buildAppBar(),
//               _buildSearchBar(),
//               Expanded(
//                 child: isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : services.isEmpty
//                     ? const Center(child: Text("No services found"))
//                     : SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: services.map((service) => _buildServiceCard(service)).toList(),
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
//   Widget _buildAppBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           Expanded(
//             child: Text(
//               widget.subcategoryName,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 48), // balance
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
//             hintText: 'Search services...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildServiceCard(dynamic service) {
//     final attributes = service['attributes'] ?? {};
//     final vendor = service['vendor'] ?? {};
//     final media = service['media'] ?? {};
//
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VendorDetailsScreen(service: service),
//           ),
//         );
//       },
//
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             margin: const EdgeInsets.only(bottom: 24),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   height: 200,
//                   decoration: BoxDecoration(
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                     image: DecorationImage(
//                       image: media['coverImage'] != null && media['coverImage'] != ""
//                           ? NetworkImage(
//                         media['coverImage'].toString().startsWith('/uploads/')
//                             ? "https://happywedzbackend.happywedz.com${media['coverImage']}"
//                             : media['coverImage'].toString(),
//                       )
//                           : const NetworkImage("https://via.placeholder.com/400x300"),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//
//                 // Container(
//                 //   height: 200,
//                 //   decoration: BoxDecoration(
//                 //     borderRadius: const BorderRadius.only(
//                 //       topLeft: Radius.circular(12),
//                 //       topRight: Radius.circular(12),
//                 //     ),
//                 //     image: DecorationImage(
//                 //       image: media['coverImage'] != null && media['coverImage'] != ""
//                 //           ? NetworkImage("https://happywedz.com/api/${media['coverImage']}")
//                 //           : const NetworkImage("https://via.placeholder.com/400x300"),
//                 //       fit: BoxFit.cover,
//                 //     ),
//                 //   ),
//                 // ),
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         vendor['businessName'] ?? attributes['name'] ?? "No Name",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       if (attributes['description'] != null && attributes['description'].toString().isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 4),
//                           child: Text(
//                             attributes['description'],
//                             style: const TextStyle(color: Colors.grey),
//                           ),
//                         ),
//                       if (attributes['starting_price'] != null)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8),
//                           child: Text(
//                             "Starting Price: ₹${attributes['starting_price']}",
//                             style: const TextStyle(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87),
//                           ),
//                         ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Container(
//                               padding: const EdgeInsets.symmetric(vertical: 12),
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: const Color(0xFFE91E63)),
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: const Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.message, color: Color(0xFFE91E63), size: 18),
//                                   SizedBox(width: 8),
//                                   Text(
//                                     'Message',
//                                     style: TextStyle(
//                                       color: Color(0xFFE91E63),
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Icon(Icons.phone, color: Colors.white, size: 18),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'chat_service.dart';
// import 'chat_screen.dart';
/////////////////////////////////////////////////////////////////////////////////////
// class VendorDetailsScreen extends StatefulWidget {
//   final dynamic service;
//
//   const VendorDetailsScreen({Key? key, required this.service}) : super(key: key);
//
//   @override
//   _VendorDetailsScreenState createState() => _VendorDetailsScreenState();
// }
//
// class _VendorDetailsScreenState extends State<VendorDetailsScreen>
//     with SingleTickerProviderStateMixin {
//   final PageController _pageController = PageController();
//   int _currentImageIndex = 0;
//   late AnimationController _animationController;
//
//   DateTime? selectedDate;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final service = widget.service;
//     final vendor = service['vendor'] ?? {};
//     final attributes = service['attributes'] ?? {};
//     final media = service['media'] ?? {};
//     final String vendorId = vendor['id']?.toString() ?? '';
//     final String vendorName = vendor['businessName']?.toString() ?? 'Vendor';
//     final String vendorPhone = vendor['phone']?.toString() ?? '';
//
//     // ✅ Build image list (coverImage + gallery)
//     final List<String> images = [];
//
//     // 1️⃣ Add cover image (if exists)
//     if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
//       final coverImage = media['coverImage'].toString();
//       final coverUrl = coverImage.startsWith('/uploads/')
//           ? "https://happywedzbackend.happywedz.com$coverImage"
//           : coverImage;
//       images.add(coverUrl);
//     }
//
//     // 2️⃣ Add gallery images
//     if (media['gallery'] != null && media['gallery'] is List) {
//       for (var item in media['gallery']) {
//         if (item is String && item.startsWith('/uploads/')) {
//           images.add("https://happywedzbackend.happywedz.com$item");
//         } else if (item is Map && item['url'] != null) {
//           final url = item['url'].toString();
//           images.add(url.startsWith('/uploads/')
//               ? "https://happywedzbackend.happywedz.com$url"
//               : url);
//         }
//       }
//     }
//
//     // 3️⃣ Fallback image
//     if (images.isEmpty) {
//       images.add('https://via.placeholder.com/400x300');
//     }
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         slivers: [
//           // Sliver AppBar with image carousel
//           SliverAppBar(
//             expandedHeight: 300,
//             pinned: true,
//             backgroundColor: Colors.pink,
//             leading: Container(
//               margin: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.black26,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.white),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             actions: [
//               Container(
//                 margin: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.black26,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.share, color: Colors.white),
//                   onPressed: () {},
//                 ),
//               ),
//             ],
//             flexibleSpace: FlexibleSpaceBar(
//               background: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   PageView.builder(
//                     controller: _pageController,
//                     onPageChanged: (index) {
//                       setState(() => _currentImageIndex = index);
//                     },
//                     itemCount: images.length,
//                     itemBuilder: (context, index) {
//                       return Image.network(
//                         images[index],
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: Colors.grey[300],
//                             child: const Icon(Icons.image, size: 50, color: Colors.white),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                   // Page indicators
//                   Positioned(
//                     bottom: 20,
//                     left: 0,
//                     right: 0,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(images.length, (index) {
//                         return AnimatedContainer(
//                           duration: const Duration(milliseconds: 300),
//                           margin: const EdgeInsets.symmetric(horizontal: 4),
//                           height: 8,
//                           width: _currentImageIndex == index ? 24 : 8,
//                           decoration: BoxDecoration(
//                             color: _currentImageIndex == index
//                                 ? Colors.white
//                                 : Colors.white54,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         );
//                       }),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Content Section
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Vendor Name and Rating
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               vendor['businessName'] ?? "No Name",
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 const Icon(Icons.star, color: Colors.orange, size: 20),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                   vendor['rating']?.toString() ?? '5.0 Review Score',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () {},
//                         icon: Icon(Icons.favorite_border, color: Colors.grey[400], size: 28),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Location
//                   if (attributes['location'] != null &&
//                       attributes['location']['city'] != null)
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, color: Colors.green, size: 20),
//                         const SizedBox(width: 8),
//                         Text(
//                           '${attributes['location']['city']}, ${attributes['location']['state'] ?? ""}',
//                           style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                         ),
//                       ],
//                     ),
//
//                   const SizedBox(height: 24),
//
//                   // About
//                   if (attributes['description'] != null)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'About',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           attributes['description'],
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[700],
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
//
//                   // Starting Price
//                   if (attributes['starting_price'] != null)
//                     Text(
//                       'Starting Price: ₹${attributes['starting_price']}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//
//                   const SizedBox(height: 24),
//
//                   // Albums
//                   const Text(
//                     'Albums',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//
//                   SizedBox(
//                     height: 100,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: media['gallery'] != null ? media['gallery'].length : 0,
//                       itemBuilder: (context, index) {
//                         final item = media['gallery'][index];
//                         String? imageUrl;
//
//                         if (item is String && item.startsWith('/uploads/')) {
//                           imageUrl = "https://happywedzbackend.happywedz.com$item";
//                         } else if (item is Map && item['url'] != null) {
//                           final url = item['url'].toString();
//                           imageUrl = url.startsWith('/uploads/')
//                               ? "https://happywedzbackend.happywedz.com$url"
//                               : url;
//                         }
//
//                         return Container(
//                           width: 100,
//                           margin: const EdgeInsets.only(right: 12),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             color: Colors.grey[300],
//                             image: imageUrl != null
//                                 ? DecorationImage(
//                               image: NetworkImage(imageUrl),
//                               fit: BoxFit.cover,
//                             )
//                                 : null,
//                           ),
//                           child: imageUrl == null
//                               ? const Icon(Icons.image, color: Colors.white, size: 30)
//                               : null,
//                         );
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 32),
//
//                   _buildCheckAvailability(),
//
//                   const SizedBox(height: 32),
//
//                   // ✅ Message and Call buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: GestureDetector(
//                           onTap: () async {
//                             // ✅ Ensure user is logged in
//                             User? currentUser = FirebaseAuth.instance.currentUser;
//                             if (currentUser == null) {
//                               try {
//                                 final userCredential = await FirebaseAuth.instance.signInAnonymously();
//                                 currentUser = userCredential.user;
//                                 print("✅ Signed in anonymously: ${currentUser?.uid}");
//                               } catch (e) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   SnackBar(content: Text('Failed to sign in anonymously: $e')),
//                                 );
//                                 return;
//                               }
//                             }
//
//                             // ✅ Get or create chat
//                             final chatService = ChatService();
//                             final chatId = await chatService.createOrGetChat(vendorId);
//
//                             if (chatId.isEmpty) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text('Failed to open chat. Please try again.')),
//                               );
//                               return;
//                             }
//
//                             // ✅ Mark all unseen messages as seen before opening chat
//                             await chatService.markMessagesSeen(chatId);
//
//                             // ✅ Navigate to ChatScreen
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => ChatScreen(
//                                   chatId: chatId,
//                                   otherUserName: vendorName,
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(vertical: 16),
//                             decoration: BoxDecoration(
//                               color: Colors.pink,
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.message, color: Colors.white, size: 20),
//                                 SizedBox(width: 8),
//                                 Text(
//                                   'Message',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w600,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       GestureDetector(
//                         onTap: () async {
//                           final Uri url = Uri(scheme: 'tel', path: vendorPhone);
//                           if (await canLaunchUrl(url)) {
//                             await launchUrl(url);
//                           } else {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text('Cannot make a call')),
//                             );
//                           }
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.green,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: const Icon(Icons.phone, color: Colors.white, size: 24),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 📅 Date Picker Section
//   Widget _buildCheckAvailability() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Check Availability',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: GestureDetector(
//                   onTap: _selectDate,
//                   child: Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey[300]!),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.calendar_today,
//                             color: Colors.grey[500], size: 18),
//                         const SizedBox(width: 8),
//                         Text(
//                           selectedDate != null
//                               ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
//                               : 'Select Date',
//                           style: TextStyle(
//                             color: selectedDate != null
//                                 ? Colors.black87
//                                 : Colors.grey[500],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.pink,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Check Dates',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   // 📆 Date Picker Logic
//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: const ColorScheme.light(
//               primary: Colors.pink,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() => selectedDate = picked);
//     }
//   }
// }

// ///////////////////////////////////////////////////////////////////





/// Paste this file into your project and call:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(service: yourServiceMap)));
class VendorDetailsScreen extends StatefulWidget {
  final dynamic service;
  const VendorDetailsScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> with SingleTickerProviderStateMixin {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentCarouselIndex = 0;
  bool _aboutExpanded = false;
  DateTime? _selectedDate;
  bool _isShortlisted = false;
  String? currentUserId; // ✅ store logged-in user id
  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // ✅ load logged-in user id

  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }

  String normalizeUrl(String url) {
    if (url.startsWith('/uploads/')) {
      return "https://happywedzbackend.happywedz.com$url";
    }
    return url;
  }

  List<Map<String, String>> parseArea(String areaRaw) {
    final parts = <String>[];
    if (areaRaw.trim().isEmpty) return [];
    for (var p in areaRaw.split(RegExp(r',\s*'))) {
      final cleaned = p.trim();
      if (cleaned.isNotEmpty) parts.add(cleaned);
    }

    final List<Map<String, String>> out = [];
    for (var p in parts) {
      final seatingMatch = RegExp(r'(\d+)\s*Seating', caseSensitive: false).firstMatch(p);
      final floatMatch = RegExp(r'(\d+)\s*Floating', caseSensitive: false).firstMatch(p);
      final titleCandidate = RegExp(r'^[A-Za-z0-9\s\-&():]+').stringMatch(p) ?? p;
      out.add({
        'title': titleCandidate.trim(),
        'seating': seatingMatch?.group(1) ?? '',
        'floating': floatMatch?.group(1) ?? '',
        'raw': p,
      });
    }
    return out;
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot make a call')));
    }
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is num) return value > 0;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? <String, dynamic>{};
    final attributes = (service['attributes'] is Map) ? Map<String, dynamic>.from(service['attributes']) : <String, dynamic>{};
    final vendor = (service['vendor'] is Map) ? Map<String, dynamic>.from(service['vendor']) : <String, dynamic>{};
    final media = (service['media'] is List) ? List.from(service['media']) : [];

    // Build images
    final List<String> images = [];
    for (var item in media) {
      if (item is String && item.isNotEmpty) {
        images.add(normalizeUrl(item));
      }
    }
    if (images.isEmpty) {
      images.add('https://via.placeholder.com/1200x700?text=No+Image');
    }
    final String vendorId = (vendor['id'] ?? attributes['vendor_id'] ?? '').toString();

    // Common fields
    final String vendorName = (attributes['vendor_name'] ?? attributes['Name'] ?? vendor['businessName'] ?? 'No Name').toString();
    final String city = (attributes['city'] ?? vendor['city'] ?? '').toString();
    final String address = (attributes['address'] ?? attributes['Address'] ?? '').toString();
    final String about = (attributes['about_us'] ?? attributes['Aboutus'] ?? '').toString();
    final String phone = (vendor['phone'] ?? attributes['Phone'] ?? '').toString();
    final double rating = double.tryParse((vendor['rating'] ?? attributes['rating'] ?? '0').toString()) ?? 0.0;
    final int reviewCount = int.tryParse((vendor['review_count'] ?? attributes['review'] ?? '0').toString()) ?? 0;
    final String vendorType = (vendor['vendorType']?['name'] ?? attributes['vendor_type'] ?? '').toString();
    final String priceRange = (attributes['PriceRange'] ?? '').toString();

    // Venue-specific fields
    final String area = (attributes['area'] ?? '').toString();
    final String rooms = (attributes['rooms'] ?? '').toString();
    final String vegPrice = (attributes['veg_price'] ?? '').toString();
    final String nonVegPrice = (attributes['non_veg_price'] ?? '').toString();
    final String destinationPrice = (attributes['destination_price'] ?? '').toString();
    final String roomPrice = (attributes['room_price'] ?? '').toString();
    final String decorPolicy = (attributes['decor_policy'] ?? '').toString();
    final String cateringPolicy = (attributes['catering_policy'] ?? '').toString();

    // Photographer-specific fields
    final String photoPackagePrice = (attributes['photo_package_price'] ?? attributes['PhotoPackage_Price'] ?? '').toString();
    final String photoVideoPrice = (attributes['photo_video_package_price'] ?? attributes['Photo_video_Price'] ?? '').toString();
    final String travelInfo = (attributes['travel_info'] ?? attributes['Travel'] ?? '').toString();
    final String paymentTerms = (attributes['payment_terms'] ?? attributes['Payment'] ?? '').toString();
    final String deliveryTime = (attributes['delivery_time'] ?? attributes['Delivery'] ?? '').toString();
    final List<dynamic> services = (attributes['services'] is List) ? attributes['services'] : [];
    final String offerings = (attributes['offerings'] ?? attributes['Offerings'] ?? '').toString();
    // final String deliveryTime = (attributes['delivery_time'] ?? attributes['Delivery'] ?? '').toString();
    final int vendorSubcategoryId = service['vendor_subcategory_id'] ?? 0;
    final String experience = (attributes['experience'] ?? attributes['Experience'] ?? '').toString();


    // Favors-specific fields
    // final String priceRange = (attributes['PriceRange'] ?? '').toString();
    final String aboutFavors = (attributes['Aboutus'] ?? attributes['about_us'] ?? '').toString();
    final String happyWedzSince = (attributes['happywedz_since'] ?? attributes['HappyWedz'] ?? '').toString();
    // final String deliveryTime = (attributes['delivery_time'] ?? attributes['Delivery'] ?? '').toString();
    // final String offerings = (attributes['Offerings'] ?? attributes['offerings'] ?? '').toString();
    final bool isDJ = vendorType.toLowerCase().contains('dj') ||
        vendorType.toLowerCase().contains('music') ||
        vendorType.toLowerCase().contains('dance');

    // Determine vendor category
    final bool isVenue = vendorType.toLowerCase().contains('venue') ||
        vendorType.toLowerCase().contains('banquet') ||
        _hasValue(vegPrice) || _hasValue(area);

    final bool isPhotographer = vendorType.toLowerCase().contains('photo') ||
        vendorType.toLowerCase().contains('shoot') ||
        _hasValue(photoPackagePrice);

    final bool isMakeup = vendorType.toLowerCase().contains('makeup') ||
        vendorType.toLowerCase().contains('bridal');

    final bool isDecorator = vendorType.toLowerCase().contains('decor') ||
        vendorType.toLowerCase().contains('planning');

    final bool isMehndi = vendorType.toLowerCase().contains('mehndi') ||
        vendorType.toLowerCase().contains('mehendi') ||
        vendorType.toLowerCase().contains('henna');

    final bool isJewellery = vendorType.toLowerCase().contains('jewellery') ||
        vendorType.toLowerCase().contains('jewelry') ||
        vendorType.toLowerCase().contains('accessories');
    final bool isCake = vendorType.toLowerCase().contains('cake');
    final bool isFoodStall = vendorType.toLowerCase().contains('chat') ||
        vendorType.toLowerCase().contains('chaat') ||
        vendorType.toLowerCase().contains('food');
    final bool isFavors = vendorType.toLowerCase().contains('favor') ||
        vendorType.toLowerCase().contains('gift') ||
        vendorType.toLowerCase().contains('favor') ||
        vendorType.toLowerCase().contains('gift');

    final seatingList = parseArea(area);
    final bool hasPoolside = area.toLowerCase().contains('pool');
    final bool hasLawn = area.toLowerCase().contains('lawn') || area.toLowerCase().contains('open');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top appbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      vendorName + (city.isNotEmpty ? ' · $city' : ''),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.black87),
                    onPressed: () {
                      final shareLink = attributes['URL']?.toString() ?? attributes['url']?.toString() ?? '';
                      if (shareLink.isNotEmpty) Share.share(shareLink);
                      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No link to share')));
                    },
                  ),
                  IconButton(
                    icon: Icon(_isShortlisted ? Icons.bookmark : Icons.bookmark_border, color: Colors.black87),
                    onPressed: () {
                      setState(() => _isShortlisted = !_isShortlisted);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isShortlisted ? 'Added to shortlist' : 'Removed from shortlist')));
                    },
                  ),
                ],
              ),
            ),

            // Carousel
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: images.length,
              itemBuilder: (context, index, realIdx) {
                final img = images[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(img, fit: BoxFit.cover, loadingBuilder: (ctx, child, prog) {
                      if (prog == null) return child;
                      return Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()));
                    }, errorBuilder: (ctx, err, st) {
                      return Container(color: Colors.grey[300], child: const Center(child: Icon(Icons.broken_image, size: 44)));
                    }),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 110,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.35)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        ),
                      ),
                    ),
                  ],
                );
              },
              options: CarouselOptions(
                height: 280,
                viewportFraction: 1.0,
                enableInfiniteScroll: images.length > 1,
                enlargeCenterPage: false,
                onPageChanged: (index, reason) => setState(() => _currentCarouselIndex = index),
                autoPlay: images.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
              ),
            ),

            // Carousel indicators
            if (images.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: images.asMap().entries.map((e) {
                      final active = _currentCarouselIndex == e.key;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(color: active ? Colors.black : Colors.grey[400], borderRadius: BorderRadius.circular(6)),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Name and location
                  Text(vendorName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Expanded(child: Text(city + (address.isNotEmpty ? ' · $address' : ''), style: const TextStyle(color: Colors.grey))),
                  ]),

                  const SizedBox(height: 8),

                  // Rating and Reviews
                  if (rating > 0 || reviewCount > 0)
                    Row(children: [
                      if (rating > 0) ...[
                        const Icon(Icons.star, color: Colors.orange, size: 18),
                        const SizedBox(width: 4),
                        Text('${rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                      if (reviewCount > 0) ...[
                        const SizedBox(width: 8),
                        Text('($reviewCount ${reviewCount == 1 ? 'review' : 'reviews'})', style: const TextStyle(color: Colors.grey)),
                      ],
                    ]),

                  const SizedBox(height: 12),

                  // Quick info chips - dynamic based on vendor type
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _infoChip(vendorType, Icons.business),
                    if (isVenue) ...[
                      if (_hasValue(vegPrice)) _infoChip('₹$vegPrice / plate', Icons.restaurant),
                      if (_hasValue(rooms)) _infoChip('$rooms rooms', Icons.hotel),
                      if (hasPoolside) _infoChip('Poolside', Icons.pool),
                      if (hasLawn) _infoChip('Lawn', Icons.park),
                    ],
                    if (isPhotographer && _hasValue(photoPackagePrice))
                      _infoChip(photoPackagePrice, Icons.photo_library),
                    if ((isMakeup || isDecorator) && _hasValue(priceRange))
                      _infoChip(priceRange, Icons.currency_rupee),
                    if (isDJ && _hasValue(priceRange))
                      _infoChip(priceRange, Icons.music_note),
                  ]),

                  const SizedBox(height: 16),

                  // Pricing Info - Dynamic based on vendor type
                  if (isVenue && (_hasValue(vegPrice) || _hasValue(nonVegPrice) || _hasValue(destinationPrice) || _hasValue(roomPrice)))
                    _buildVenuePricing(vegPrice, nonVegPrice, destinationPrice, roomPrice),

                  if (isPhotographer && (_hasValue(photoPackagePrice) || _hasValue(photoVideoPrice)))
                    _buildPhotographerPricing(photoPackagePrice, photoVideoPrice),

                  if ((isMakeup || isDecorator || isMehndi || isJewellery || isCake || isFoodStall) && _hasValue(priceRange))
                    _buildGeneralPricing(
                        priceRange,
                        isMakeup ? 'Makeup Package' :
                        isDecorator ? 'Decor Package' :
                        isMehndi ? 'Mehndi Service' :
                        isCake ? 'Cake Price' :
                        isFoodStall ? 'Food Stall Package' :
                        'Product/Service'
                    ),
                  if (isDJ && _hasValue(priceRange))
                    _buildDJPricing(priceRange, travelInfo, paymentTerms, deliveryTime),
                  if (vendorType.toLowerCase().contains('choreographer') ||
                      vendorType.toLowerCase().contains('dance') ||
                      vendorType.toLowerCase().contains('music') ||
                      vendorSubcategoryId == 18)
                    _buildSangeetPricing(
                      priceRange,
                      travelInfo,
                      paymentTerms,
                      deliveryTime,
                      experience

                    ),

                  // Services/Offerings section
                  if (services.isNotEmpty || offerings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
                      ]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Services Offered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        if (services.isNotEmpty)
                          ...services.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              const Icon(Icons.check_circle, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(child: Text(s.toString())),
                            ]),
                          )).toList()
                        else if (offerings.isNotEmpty)
                          Text(offerings, style: const TextStyle(height: 1.4)),
                      ]),
                    ),
                  ],

                  // Venues & Seating (only for venues)
                  if (isVenue && seatingList.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
                      ]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Banquets & Seating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Column(children: seatingList.map((entry) {
                          final title = (entry['title']?.isNotEmpty ?? false) ? (entry['title'] ?? entry['raw'] ?? '') : (entry['raw'] ?? '');
                          final seating = (entry['seating']?.isNotEmpty ?? false) ? (entry['seating'] ?? '--') : '--';
                          final floating = (entry['floating']?.isNotEmpty ?? false) ? (entry['floating'] ?? '--') : '--';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(children: [
                              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text('Seating: $seating', style: const TextStyle(color: Colors.grey)),
                                Text('Floating: $floating', style: const TextStyle(color: Colors.grey)),
                              ])
                            ]),
                          );
                        }).toList()),
                      ]),
                    ),
                  ],

                  // Additional Info (for photographers/makeup/decorators)
                  if ((isPhotographer || isMakeup || isDecorator || isMehndi || isJewellery) && (_hasValue(travelInfo) || _hasValue(paymentTerms) || _hasValue(deliveryTime))) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
                      ]),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Additional Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        if (_hasValue(travelInfo))
                          _infoRow(Icons.travel_explore, 'Travel', travelInfo),
                        if (_hasValue(paymentTerms))
                          _infoRow(Icons.payment, 'Payment', paymentTerms),
                        if (_hasValue(deliveryTime))
                          _infoRow(Icons.timer, 'Delivery', deliveryTime),
                      ]),
                    ),
                  ],

                  // Albums
                  if (images.length > 1) ...[
                    const SizedBox(height: 16),
                    const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (ctx, idx) {
                          return Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey[300],
                              image: DecorationImage(image: NetworkImage(images[idx]), fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Quote & Chat buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Custom quote requested (demo)')));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.pink),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Require Custom Quote?'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat now (demo)')));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Chat Now'),
                      ),
                    ),
                  ]),


                  const SizedBox(height: 16),

                  // About
                  if (_hasValue(about)) ...[
                    const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    AnimatedCrossFade(
                      firstChild: Text(about, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(height: 1.4)),
                      secondChild: Text(about, style: const TextStyle(height: 1.4)),
                      crossFadeState: _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                    if (about.length > 200)
                      TextButton(
                        onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded),
                        child: Text(_aboutExpanded ? 'Read less' : 'Read more'),
                      ),
                  ],

                  // Policies (only for venues)
                  if (isVenue && (_hasValue(decorPolicy) || _hasValue(cateringPolicy))) ...[
                    const SizedBox(height: 12),
                    const Text('Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    if (_hasValue(decorPolicy))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• Decor: $decorPolicy', style: const TextStyle(height: 1.4)),
                      ),
                    if (_hasValue(cateringPolicy))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text('• Catering: $cateringPolicy', style: const TextStyle(height: 1.4)),
                      ),
                  ],

                  const SizedBox(height: 28),
                ]),
              ),
            )
          ],
        ),
      ),
      // Bottom call/message bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: SafeArea(
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  if (currentUserId == null || currentUserId!.isEmpty) {
                    // 🚀 Redirect user to SignInScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignInScreen()),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        currentUid: currentUserId!,   // <-- logged in user
                        otherUid: vendorId,          // <-- vendor’s unique id
                        otherName: vendorName,       // <-- vendor’s display name
                      ),
                    ),
                  );

                },

                icon: const Icon(Icons.message, color: Colors.pink),
                label: const Text('Message', style: TextStyle(color: Colors.pink)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.pink),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 48,
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
              child: IconButton(
                icon: const Icon(Icons.phone, color: Colors.white),
                onPressed: () {
                  if (phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone not available')));
                    return;
                  }
                  _call(phone);
                },
              ),
            )
          ]),
        ),
      ),
    );
  }

  // Venue pricing widget
  Widget _buildVenuePricing(String vegPrice, String nonVegPrice, String destinationPrice, String roomPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pricing Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          if (_hasValue(vegPrice)) Expanded(child: _priceItem('Veg per plate', vegPrice)),
          if (_hasValue(vegPrice) && _hasValue(nonVegPrice)) const SizedBox(width: 8),
          if (_hasValue(nonVegPrice)) Expanded(child: _priceItem('Non-veg per plate', nonVegPrice)),
        ]),
        if (_hasValue(destinationPrice) || _hasValue(roomPrice)) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (_hasValue(destinationPrice)) Expanded(child: _priceItem('Destination per plate', destinationPrice)),
            if (_hasValue(destinationPrice) && _hasValue(roomPrice)) const SizedBox(width: 8),
            if (_hasValue(roomPrice)) Expanded(child: _priceItem('Room per night', roomPrice)),
          ]),
        ],
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 2),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checked availability for ${picked.day}/${picked.month}/${picked.year} (demo)')));
            }
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          child: const Text('Check Availability'),
        )
      ]),
    );
  }

  // Photographer pricing widget
  Widget _buildPhotographerPricing(String photoPackagePrice, String photoVideoPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Package Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        if (_hasValue(photoPackagePrice))
          _priceItem('Photography Package', photoPackagePrice),
        if (_hasValue(photoPackagePrice) && _hasValue(photoVideoPrice))
          const SizedBox(height: 12),
        if (_hasValue(photoVideoPrice))
          _priceItem('Photo + Video Package', photoVideoPrice),
      ]),
    );
  }
  Widget _buildDJPricing(String priceRange, String travelInfo, String paymentTerms, String deliveryTime) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DJ / Music & Dance Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),

          if (_hasValue(priceRange))
            _priceItem('Price Range', priceRange),

          if (_hasValue(travelInfo))
            _infoRow(Icons.travel_explore, 'Travel', travelInfo),

          if (_hasValue(paymentTerms))
            _infoRow(Icons.payment, 'Payment', paymentTerms),

          if (_hasValue(deliveryTime))
            _infoRow(Icons.timer, 'Delivery', deliveryTime),
        ],
      ),
    );
  }
  Widget _buildSangeetPricing(String priceRange, String travelInfo, String paymentTerms, String deliveryTime, String experience) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sangeet Choreography Pricing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          if (_hasValue(priceRange))
            _priceItem('Package Starting From', priceRange),

          if (_hasValue(experience))
            _infoRow(Icons.star, 'Experience', experience),

          if (_hasValue(travelInfo))
            _infoRow(Icons.travel_explore, 'Travel', travelInfo),

          if (_hasValue(paymentTerms))
            _infoRow(Icons.payment, 'Payment Terms', paymentTerms),

          if (_hasValue(deliveryTime))
            _infoRow(Icons.timer, 'Delivery', deliveryTime),
        ],
      ),
    );
  }

  // General pricing widget (for makeup, decorators, etc.)
  Widget _buildGeneralPricing(String priceRange, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.currency_rupee, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(priceRange, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12))
      ]),
    );
  }

  Widget _priceItem(String title, String amount) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 6),
      Text(amount.isNotEmpty ? (amount.contains('₹') ? amount : '₹$amount') : '--',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

















// class VendorDetailsScreen extends StatefulWidget {
//   final dynamic service; // Pass the selected service/vendor
//
//   const VendorDetailsScreen({Key? key, required this.service}) : super(key: key);
//
//   @override
//   _VendorDetailsScreenState createState() => _VendorDetailsScreenState();
// }
//
// class _VendorDetailsScreenState extends State<VendorDetailsScreen> with SingleTickerProviderStateMixin {
//   PageController _pageController = PageController();
//   int _currentImageIndex = 0;
//   late AnimationController _animationController;
//
//   DateTime? selectedDate;
//   List<String> selectedImages = [];
//   int selectedRating = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final service = widget.service;
//     final vendor = service['vendor'] ?? {};
//     final attributes = service['attributes'] ?? {};
//     final media = service['media'] ?? {};
//
//     // // Images list for carousel
//     // final List<String> images = [
//     //   if (media['coverImage'] != null && media['coverImage'] != "")
//     //     "https://happywedz.com/api/${media['coverImage']}"
//     //   else
//     //     'https://via.placeholder.com/400x300',
//     //   // You can add more images from media['images'] if available
//     // ];
//     // 👇 Add this block right here
//     print("🔍 MEDIA OBJECT:");
//     print(media);
//
//     // Debug cover image URL
//     if (media['coverImage'] != null) {
//       final coverImage = media['coverImage'].toString();
//       final coverUrl = coverImage.startsWith('/uploads/')
//           ? "https://happywedzbackend.happywedz.com$coverImage"
//           : coverImage;
//       print("🖼️ Cover Image URL => $coverUrl");
//     } else {
//       print("⚠️ No coverImage found in media");
//     }
//
//     // Debug gallery images
//     if (media['images'] != null && media['images'] is List) {
//       print("🖼️ Gallery Images:");
//       for (var img in media['images']) {
//         if (img != null) {
//           final imageUrl = img.toString().startsWith('/uploads/')
//               ? "https://happywedzbackend.happywedz.com$img"
//               : img.toString();
//           print("   ➤ $imageUrl");
//         }
//       }
//     } else {
//       print("⚠️ No gallery images found or 'images' is not a List");
//     }
//
//     // 👇 your existing code continues normally below this
//     // Images list for carousel
//     final List<String> images = [];
//
//     if (media['coverImage'] != null && media['coverImage'] != "") {
//       final coverImage = media['coverImage'].toString();
//       images.add(
//         coverImage.startsWith('/uploads/')
//             ? "https://happywedzbackend.happywedz.com$coverImage"
//             : coverImage,
//       );
//     } else {
//       images.add('https://via.placeholder.com/400x300');
//     }
//
//     if (media['images'] != null && media['images'] is List) {
//       for (var img in media['images']) {
//         if (img is String && img.startsWith('/uploads/')) {
//           images.add("https://happywedzbackend.happywedz.com$img");
//         }
//       }
//     }
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         slivers: [
//           // Sliver AppBar with image carousel
//           SliverAppBar(
//             expandedHeight: 300,
//             pinned: true,
//             backgroundColor: Colors.pink,
//             leading: Container(
//               margin: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.black26,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.white),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             actions: [
//               Container(
//                 margin: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.black26,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.share, color: Colors.white),
//                   onPressed: () {},
//                 ),
//               ),
//             ],
//             flexibleSpace: FlexibleSpaceBar(
//               background: Stack(
//                 fit: StackFit.expand,
//                 children: [
//                   PageView.builder(
//                     controller: _pageController,
//                     onPageChanged: (index) {
//                       setState(() {
//                         _currentImageIndex = index;
//                       });
//                     },
//                     itemCount: images.length,
//                     itemBuilder: (context, index) {
//                       return Image.network(
//                         images[index],
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Container(
//                             color: Colors.grey[300],
//                             child: const Icon(Icons.image, size: 50, color: Colors.white),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                   // Page indicators
//                   Positioned(
//                     bottom: 20,
//                     left: 0,
//                     right: 0,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(images.length, (index) {
//                         return AnimatedContainer(
//                           duration: const Duration(milliseconds: 300),
//                           margin: const EdgeInsets.symmetric(horizontal: 4),
//                           height: 8,
//                           width: _currentImageIndex == index ? 24 : 8,
//                           decoration: BoxDecoration(
//                             color: _currentImageIndex == index
//                                 ? Colors.white
//                                 : Colors.white54,
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                         );
//                       }),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Content
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Vendor Title and Rating
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               vendor['businessName'] ?? "No Name",
//                               style: const TextStyle(
//                                 fontSize: 24,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               children: [
//                                 const Icon(Icons.star, color: Colors.orange, size: 20),
//                                 const SizedBox(width: 4),
//                                 Text(
//                                 vendor['rating'] ?? '5.0 Review Score',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () {},
//                         icon: Icon(Icons.favorite_border, color: Colors.grey[400], size: 28),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 16),
//
//                   // Location
//                   if (attributes['location'] != null && attributes['location']['city'] != null)
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, color: Colors.green, size: 20),
//                         const SizedBox(width: 8),
//                         Text(
//                           '${attributes['location']['city']}, ${attributes['location']['state'] ?? ""}',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[700],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                   const SizedBox(height: 24),
//
//                   // About
//                   if (attributes['description'] != null)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'About',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           attributes['description'],
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.grey[700],
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                       ],
//                     ),
//
//                   // Starting Price
//                   if (attributes['starting_price'] != null)
//                     Text(
//                       'Starting Price: ₹${attributes['starting_price']}',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//
//                   const SizedBox(height: 24),
//
//                   // Albums / Gallery
//                   const Text(
//                     'Albums',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   // SizedBox(
//                   //   height: 100,
//                   //   child: ListView.builder(
//                   //     scrollDirection: Axis.horizontal,
//                   //     itemCount: 4,
//                   //     itemBuilder: (context, index) {
//                   //       return Container(
//                   //         width: 100,
//                   //         margin: const EdgeInsets.only(right: 12),
//                   //         decoration: BoxDecoration(
//                   //           borderRadius: BorderRadius.circular(12),
//                   //           color: Colors.grey[300],
//                   //           image: media['images'] != null &&
//                   //               index < media['images'].length
//                   //               ? DecorationImage(
//                   //             image: NetworkImage(
//                   //               "https://happywedz.com/api/${media['images'][index]}",
//                   //             ),
//                   //             fit: BoxFit.cover,
//                   //           )
//                   //               : null,
//                   //         ),
//                   //         child: media['images'] == null ||
//                   //             index >= media['images'].length
//                   //             ? const Icon(Icons.image, color: Colors.white, size: 30)
//                   //             : null,
//                   //       );
//                   //     },
//                   //   ),
//                   // ),
//                   SizedBox(
//                     height: 100,
//                     child: ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: media['images'] != null ? media['images'].length : 0,
//                       itemBuilder: (context, index) {
//                         final img = media['images'][index];
//                         final imageUrl = img != null && img.toString().startsWith('/uploads/')
//                             ? "https://happywedzbackend.happywedz.com$img"
//                             : img ?? 'https://via.placeholder.com/400x300';
//
//                         return Container(
//                           width: 100,
//                           margin: const EdgeInsets.only(right: 12),
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(12),
//                             color: Colors.grey[300],
//                             image: DecorationImage(
//                               image: NetworkImage(imageUrl),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//
//                   const SizedBox(height: 32),
//
//                   // Check Availability
//                   _buildCheckAvailability(),
//
//                   const SizedBox(height: 32),
//
//                   // Action Buttons (Message / Call)
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           decoration: BoxDecoration(
//                             color: Colors.pink,
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: const [
//                               Icon(Icons.message, color: Colors.white, size: 20),
//                               SizedBox(width: 8),
//                               Text(
//                                 'Message',
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(Icons.phone, color: Colors.white, size: 24),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 32),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Check Availability Widget
//   Widget _buildCheckAvailability() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.grey[50],
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey[200]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Check Availability',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: GestureDetector(
//                   onTap: _selectDate,
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey[300]!),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.calendar_today, color: Colors.grey[500], size: 18),
//                         const SizedBox(width: 8),
//                         Text(
//                           selectedDate != null
//                               ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
//                               : 'Select Date',
//                           style: TextStyle(
//                             color: selectedDate != null ? Colors.black87 : Colors.grey[500],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                 decoration: BoxDecoration(
//                   color: Colors.pink,
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Check Dates',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _selectDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: Colors.pink,
//               onPrimary: Colors.white,
//               surface: Colors.white,
//               onSurface: Colors.black87,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//     }
//   }
// }
