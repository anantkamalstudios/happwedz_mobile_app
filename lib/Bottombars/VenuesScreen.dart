import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/core.dart';
import '../vendor/vendordetailsscreen.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;


// class VenuesScreen extends StatefulWidget {
//   const VenuesScreen({Key? key}) : super(key: key);
//
//   @override
//   State<VenuesScreen> createState() => _VenuesScreenState();
// }
//
// class _VenuesScreenState extends State<VenuesScreen> {
//   List<Venue> venues = [];
//   bool isLoading = true;
//   bool isLoadingMore = false;
//   bool hasMore = true;
//   int page = 1;
//   final int limit = 10; // ✅ only 10 per page
//   int totalPages = 1; // ✅ added for pagination
//   String searchQuery = "";
//
//   List<Venue> allVenues = []; // keep all fetched venues
//
//
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _searchController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     fetchVenues(page: page);
//
//     _searchController.addListener(() {
//       final query = _searchController.text.trim();
//       if (query != searchQuery) {
//         searchQuery = query;
//         _onSearchChanged();
//       }
//     });
//   }
//
//   Future<void> _onSearchChanged() async {
//     final query = searchQuery.toLowerCase();
//     setState(() {
//       if (query.isEmpty) {
//         venues = List.from(allVenues); // reset
//       } else {
//         venues = allVenues
//             .where((v) =>
//         v.vendorName.toLowerCase().contains(query) ||
//             v.area.toLowerCase().contains(query) || // ✅ maybe contains city/area info
//             v.type.toLowerCase().contains(query)) // ✅ or type/category name
//             .toList()
//           ..sort((a, b) => a.vendorName.toLowerCase().compareTo(b.vendorName.toLowerCase()));
//
//       }
//     });
//   }
//
//   Future<void> fetchVenues({int page = 1, String query = ""}) async {
//     setState(() {
//       isLoading = true;
//     });
//
//     try {
//       final url = Uri.parse(
//         "https://happywedz.com/api/vendor-services?subCategory=venue&page=$page&limit=$limit&search=$query",
//       );
//
//       print("Fetching venues from: $url");
//
//       final response = await http.get(url, headers: {"Accept": "application/json"});
//
//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         final List<dynamic> data = decoded['data'] ?? [];
//
//         // ✅ Safer total pages calculation — ensures buttons always show
//         // ✅ Dynamic total page calculation
//         final totalItems = decoded['total'];
//
//         if (totalItems != null && totalItems is int && totalItems > 0) {
//           totalPages = (totalItems / limit).ceil();
//         } else {
//           // If API doesn’t send total count,
//           // we’ll estimate based on data length
//           final fetchedCount = (decoded['data'] as List?)?.length ?? 0;
//           if (fetchedCount < limit) {
//             totalPages = page; // likely last page
//           } else {
//             totalPages = page + 1; // assume one more page
//           }
//         }
//         print("📄 Estimated total pages: $totalPages");
//
//
//
//         final List<Venue> loadedVenues = data.map((service) {
//           final attributes = service['attributes'] ?? {};
//           final vendor = service['vendor'] ?? {};
//           final subcategory = service['subcategory'] ?? {};
//           final media = service['media'] ?? {};
//
//           String imageUrl = '';
//           if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
//             final cover = media['coverImage'].toString();
//             imageUrl = cover.startsWith('/uploads/')
//                 ? "https://happywedzbackend.happywedz.com$cover"
//                 : cover;
//           } else if (media['gallery'] != null && media['gallery'].isNotEmpty) {
//             final gallery = media['gallery'];
//             final firstImage = gallery.firstWhere(
//                   (g) => g is String && g.toString().startsWith('/uploads/'),
//               orElse: () => null,
//             );
//             if (firstImage != null) {
//               imageUrl = "https://happywedzbackend.happywedz.com$firstImage";
//             }
//           }
//
//           return Venue(
//             id: service['id'] ?? 0,
//             vendorName: attributes['vendor_name'] ?? vendor['businessName'] ?? '',
//             city: attributes['city'] ?? vendor['city'] ?? '',
//             vegPrice: attributes['veg_price']?.toString() ?? '',
//             nonVegPrice: attributes['non_veg_price']?.toString() ?? '',
//             area: attributes['area'] ?? '',
//             address: attributes['address'] ?? '',
//             rating: attributes['averageRating']?.toString() ?? '0.0',
//             reviewCount: attributes['totalReviews']?.toString() ?? '0',
//             about: attributes['about_us'] ?? '',
//             type: subcategory['name'] ?? vendor['vendorType']?['name'] ?? '',
//             image: imageUrl.isNotEmpty
//                 ? imageUrl
//                 : 'https://via.placeholder.com/400x300.png?text=No+Image',
//             isFavourite: service['is_favourite'] == true || service['is_favourite'] == 1,
//           );
//
//         }).toList();
//
//         setState(() {
//           allVenues = loadedVenues; // save full list
//           venues = loadedVenues;    // currently displayed
//           isLoading = false;
//           hasMore = loadedVenues.length >= limit;
//         });
//
//       } else {
//         print("❌ Error fetching venues: ${response.statusCode}");
//         setState(() {
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       print("💥 API Error: $e");
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//
//           // ---------- MAIN VENUE UI ----------
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
//                 stops: [0.0, 0.3, 0.6],
//               ),
//             ),
//             child: SafeArea(
//               child: Column(
//                 children: [
//                   _buildAppBar(context),
//                   _buildSearchBar(),
//                   Expanded(
//                     child: isLoading
//                         ? const Center(child: CircularProgressIndicator(color: Colors.pink))
//                         : venues.isEmpty
//                         ? const Center(
//                       child: Text(
//                         "No venues found 😔",
//                         style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey),
//                       ),
//                     )
//                         : RefreshIndicator(
//                       color: Colors.pink,
//                       onRefresh: () async => await fetchVenues(page: 1),
//                       child: SingleChildScrollView(
//                         controller: _scrollController,
//                         child: Column(
//                           children: [
//                             ListView.builder(
//                               shrinkWrap: true,
//                               physics: const NeverScrollableScrollPhysics(),
//                               padding: const EdgeInsets.all(16.0),
//                               itemCount: venues.length,
//                               itemBuilder: (context, index) {
//                                 final venue = venues[index];
//                                 return _buildVenueCard(context, venue);
//                               },
//                             ),
//                             _buildPaginationButtons(),
//                             const SizedBox(height: 80),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // ---------- FLOATING GENIE BUTTON ----------
//           Positioned(
//             bottom: 20,
//             right: 20,
//             child: GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const GenieScreen()),
//                 );
//               },
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 600),
//                 curve: Curves.easeInOut,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFF6A5AE0), Color(0xFFB26BF2)],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.purple.withValues(alpha: 0.5),
//                       blurRadius: 20,
//                       spreadRadius: 5,
//                     ),
//                   ],
//                 ),
//                 padding: const EdgeInsets.all(18),
//                 child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
//               ),
//             ),
//           ),
//
//         ],
//       ),
//     );
//
//   }
//
//   Widget _buildPaginationButtons() {
//     if (totalPages <= 1) return const SizedBox();
//
//     List<Widget> buttons = [];
//     for (int i = 1; i <= totalPages; i++) {
//       buttons.add(
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 4),
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: i == page ? Colors.pink : Colors.white,
//               foregroundColor: i == page ? Colors.white : Colors.pink,
//               side: const BorderSide(color: Colors.pink),
//               minimumSize: const Size(40, 36),
//             ),
//             onPressed: () {
//               setState(() => page = i);
//               fetchVenues(page: i, query: searchQuery);
//             },
//             child: Text('$i'),
//           ),
//         ),
//       );
//     }
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: buttons,
//         ),
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
//         child: TextField(
//           controller: _searchController,
//           decoration: const InputDecoration(
//             hintText: 'Search wedding venues...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAppBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // LEFT BACK BUTTON
//           // Align(
//           //   alignment: Alignment.centerLeft,
//           //   child: IconButton(
//           //     icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//           //     onPressed: () => Navigator.pop(context),
//           //   ),
//           // ),
//
//           // CENTER TITLE
//           const Text(
//             'Venues',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildVenueCard(BuildContext context, Venue venue) {
//     return GestureDetector(
//       onTap: () {
//         // Passing complete & correct structure to VendorDetailsScreen
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VendorDetailsScreen(
//               service: {
//                 "attributes": {
//                   "vendor_name": venue.vendorName ?? "",
//                   "veg_price": venue.vegPrice ?? "",
//                   "non_veg_price": venue.nonVegPrice ?? "",
//                   "area": venue.area ?? "",
//                   "address": venue.address ?? "",
//                   "averageRating": venue.rating ?? 0,
//                   "totalReviews": venue.reviewCount ?? 0,
//                   "about_us": venue.about ?? "",
//                   "vendor_type": venue.type ?? "",
//                 },
//
//                 "media": [
//                   {
//                     "original_url": venue.image ??
//                         "https://via.placeholder.com/500x300?text=No+Image",
//                   }
//                 ],
//
//                 "vendor": {
//                   "id": venue.id ?? 0,
//                   // "phone": venue.phone ?? "",
//                   "review_count": venue.reviewCount ?? 0,
//                 }
//               },
//             ),
//           ),
//         );
//       },
//
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ----------------------------------
//             // IMAGE + FAV BUTTON
//             // ----------------------------------
//             Stack(
//               children: [
//                 Container(
//                   height: 200,
//                   decoration: BoxDecoration(
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(12),
//                       topRight: Radius.circular(12),
//                     ),
//                     image: DecorationImage(
//                       image: NetworkImage(
//                         venue.image ??
//                             "https://via.placeholder.com/500x300?text=No+Image",
//                       ),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//
//                 // ❤️ Wishlist Icon
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: StatefulBuilder(
//                     builder: (context, setInnerState) {
//                       bool isFav = venue.isFavourite ?? false;
//
//                       Future<void> toggleWishlist() async {
//                         final prefs = await SharedPreferences.getInstance();
//                         final userId = prefs.getInt('user_id');
//                         final token = prefs.getString('auth_token') ?? '';
//
//                         if (userId == null) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Please sign in first')),
//                           );
//                           return;
//                         }
//
//                         final url = Uri.parse(
//                             'https://happywedz.com/api/wishlist/toggle');
//
//                         final body = {
//                           'user_id': userId.toString(),
//                           'vendor_services_id': venue.id.toString(),
//                         };
//
//                         try {
//                           final response = await http.post(
//                             url,
//                             headers: {
//                               'Content-Type': 'application/json',
//                               'Accept': 'application/json',
//                               'Authorization': 'Bearer $token',
//                             },
//                             body: jsonEncode(body),
//                           );
//
//                           if (response.statusCode == 200) {
//                             final data = jsonDecode(response.body);
//                             final message = data['message'] ?? "";
//
//                             setInnerState(() {
//                               isFav = message.toLowerCase().contains("added");
//                               venue.isFavourite = isFav;
//                             });
//
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text(message)),
//                             );
//                           }
//                         } catch (e) {
//                           print("💥 Wishlist Error: $e");
//                         }
//                       }
//
//                       return InkWell(
//                         onTap: toggleWishlist,
//                         child: Container(
//                           padding: const EdgeInsets.all(6),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withValues(alpha: 0.85),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             isFav ? Icons.favorite : Icons.favorite_border,
//                             color: Colors.pinkAccent,
//                             size: 20,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//
//             // ----------------------------------
//             // VENUE DETAILS
//             // ----------------------------------
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Name
//                   Text(
//                     venue.vendorName ?? "Not available",
//                     style: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//
//                   const SizedBox(height: 4),
//
//                   // Veg Price
//                   Text(
//                     venue.vegPrice ?? "",
//                     style: const TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   // Location
//                   Row(
//                     children: [
//                       const Icon(Icons.location_on,
//                           size: 16, color: Colors.grey),
//                       const SizedBox(width: 4),
//                       Expanded(
//                         child: Text(
//                           venue.area ?? "",
//                           style: const TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   const SizedBox(height: 8),
//
//                   // Type
//                   Row(
//                     children: [
//                       const Icon(Icons.event, size: 16, color: Colors.grey),
//                       const SizedBox(width: 4),
//                       Text(
//                         venue.type ?? "",
//                         style: const TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Widget _buildVenueCard(BuildContext context, Venue venue) {
//   //   return GestureDetector(
//   //     onTap: () {
//   //       Navigator.push(
//   //         context,
//   //         MaterialPageRoute(
//   //           builder: (context) => VendorDetailsScreen(
//   //             service: {
//   //               "attributes": {
//   //                 "vendor_name": venue.vendorName,
//   //                 "veg_price": venue.vegPrice,
//   //                 "non_veg_price": venue.nonVegPrice,
//   //                 "area": venue.area,
//   //                 "address": venue.address,
//   //                 "averageRating": venue.rating,
//   //                 "totalReviews": venue.reviewCount,
//   //                 "about_us": venue.about,
//   //                 "vendor_type": venue.type,
//   //               },
//   //
//   //               "media": [
//   //                 {"original_url": venue.image}   // Matches your backend format
//   //               ],
//   //
//   //               "vendor": {
//   //                 "id": venue.id,
//   //                 "phone": "",   // leave empty if not available
//   //                 "review_count": venue.reviewCount,
//   //               }
//   //             },
//   //           ),
//   //         ),
//   //       );
//   //
//   //     },
//   //     child: Container(
//   //       margin: const EdgeInsets.only(bottom: 24),
//   //       decoration: BoxDecoration(
//   //         color: Colors.white,
//   //         borderRadius: BorderRadius.circular(12),
//   //         boxShadow: [
//   //           BoxShadow(
//   //             color: Colors.black.withValues(alpha: 0.1),
//   //             blurRadius: 8,
//   //             offset: const Offset(0, 2),
//   //           ),
//   //         ],
//   //       ),
//   //       child: Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           Stack(
//   //             children: [
//   //               Container(
//   //                 height: 200,
//   //                 decoration: BoxDecoration(
//   //                   borderRadius: const BorderRadius.only(
//   //                     topLeft: Radius.circular(12),
//   //                     topRight: Radius.circular(12),
//   //                   ),
//   //                   image: DecorationImage(
//   //                     image: NetworkImage(venue.image),
//   //                     fit: BoxFit.cover,
//   //                   ),
//   //                 ),
//   //               ),
//   //               Positioned(
//   //                 top: 8,
//   //                 right: 8,
//   //                 child: StatefulBuilder(
//   //                   builder: (context, setInnerState) {
//   //                     bool isFav = venue.isFavourite ?? false;
//   //
//   //                     Future<void> toggleWishlist() async {
//   //                       final prefs = await SharedPreferences.getInstance();
//   //                       final userId = prefs.getInt('user_id');
//   //                       final token = prefs.getString('auth_token') ?? '';
//   //
//   //                       if (userId == null || userId == 0) {
//   //                         ScaffoldMessenger.of(context).showSnackBar(
//   //                           const SnackBar(content: Text('Please sign in first')),
//   //                         );
//   //                         return;
//   //                       }
//   //
//   //                       final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
//   //                       final body = {
//   //                         'user_id': userId.toString(),
//   //                         'vendor_services_id': venue.id.toString(),
//   //                       };
//   //
//   //                       try {
//   //                         print('🟢 Current userId: $userId');
//   //                         print('🔑 Token (first 20 chars): ${token.isNotEmpty ? token.substring(0, 20) : "none"}');
//   //                         print('⭐ Vendor Service ID: ${venue.id}');
//   //                         print('🌍 Sending POST → $url');
//   //                         print('📦 Headers: {Content-Type: application/json, Authorization: Bearer $token}');
//   //                         print('📦 Body: $body');
//   //
//   //                         final response = await http.post(
//   //                           url,
//   //                           headers: {
//   //                             'Content-Type': 'application/json',
//   //                             'Accept': 'application/json',
//   //                             'Authorization': 'Bearer $token',
//   //                           },
//   //                           body: jsonEncode(body),
//   //                         );
//   //
//   //                         print('📬 Response status: ${response.statusCode}');
//   //                         print('📬 Response body: ${response.body}');
//   //
//   //                         if (response.statusCode == 200) {
//   //                           final data = jsonDecode(response.body);
//   //                           final message = data['message'] ?? 'Unknown response';
//   //
//   //                           setInnerState(() {
//   //                             isFav = message.toLowerCase().contains('added');
//   //                             venue.isFavourite = isFav;
//   //                           });
//   //
//   //                           ScaffoldMessenger.of(context).showSnackBar(
//   //                             SnackBar(content: Text(message)),
//   //                           );
//   //                         } else if (response.statusCode == 401) {
//   //                           print('🚫 401 Unauthorized → Token invalid or expired.');
//   //                           ScaffoldMessenger.of(context).showSnackBar(
//   //                             const SnackBar(content: Text('Session expired. Please sign in again.')),
//   //                           );
//   //                         } else {
//   //                           print('❌ Unexpected status: ${response.statusCode}');
//   //                         }
//   //                       } catch (e) {
//   //                         print('💥 Error toggling wishlist: $e');
//   //                       }
//   //                     }
//   //
//   //
//   //                     return InkWell(
//   //                       onTap: toggleWishlist,
//   //                       child: Container(
//   //                         padding: const EdgeInsets.all(6),
//   //                         decoration: BoxDecoration(
//   //                           color: Colors.white.withValues(alpha: 0.85),
//   //                           shape: BoxShape.circle,
//   //                         ),
//   //                         child: Icon(
//   //                           isFav ? Icons.favorite : Icons.favorite_border,
//   //                           color: Colors.pinkAccent,
//   //                           size: 20,
//   //                         ),
//   //                       ),
//   //                     );
//   //                   },
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //           Padding(
//   //             padding: const EdgeInsets.all(16.0),
//   //             child: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               children: [
//   //                 Text(
//   //                   venue.vendorName ?? "Not available",
//   //                   style: const TextStyle(
//   //                     fontSize: 16,
//   //                     fontWeight: FontWeight.bold,
//   //                     color: Colors.black87,
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 4),
//   //                 Text(
//   //                   venue.vegPrice,
//   //                   style: const TextStyle(
//   //                     fontSize: 16,
//   //                     fontWeight: FontWeight.bold,
//   //                     color: Colors.black87,
//   //                   ),
//   //                 ),
//   //                 const SizedBox(height: 8),
//   //                 Row(
//   //                   children: [
//   //                     const Icon(Icons.location_on, size: 16, color: Colors.grey),
//   //                     const SizedBox(width: 4),
//   //                     Expanded(
//   //                       child: Text(
//   //                         venue.area,
//   //                         style: const TextStyle(fontSize: 12, color: Colors.grey),
//   //                       ),
//   //                     ),
//   //                   ],
//   //                 ),
//   //                 const SizedBox(height: 8),
//   //                 Row(
//   //                   children: [
//   //                     const Icon(Icons.event, size: 16, color: Colors.grey),
//   //                     const SizedBox(width: 4),
//   //                     Text(
//   //                       venue.type,
//   //                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//   //                     ),
//   //                   ],
//   //                 ),
//   //               ],
//   //             ),
//   //           ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
//
// }
//
// class Venue {
//   final int id;
//   final String vendorName;
//   final String city;
//   final String vegPrice;
//   final String nonVegPrice;
//   final String area;
//   final String address;
//   final String rating;
//   final String reviewCount;
//   final String about;
//   final String type;
//   final String image;
//   bool isFavourite;
//
//   Venue({
//     required this.id,
//     required this.vendorName,
//     required this.city,
//     required this.vegPrice,
//     required this.nonVegPrice,
//     required this.area,
//     required this.address,
//     required this.rating,
//     required this.reviewCount,
//     required this.about,
//     required this.type,
//     required this.image,
//     this.isFavourite = false,
//   });
//
//   factory Venue.fromJson(Map<String, dynamic> json) {
//     final attr = json['attributes'] ?? {};
//     final vendor = json['vendor'] ?? {};
//     final vendorType = vendor['vendorType'] ?? {};
//
//     return Venue(
//       id: json['id'] ?? 0,
//       vendorName: attr['vendor_name'] ?? vendor['businessName'] ?? '',
//       city: attr['city'] ?? vendor['city'] ?? '',
//       vegPrice: attr['veg_price']?.toString() ?? '',
//       nonVegPrice: attr['non_veg_price']?.toString() ?? '',
//       area: attr['area'] ?? '',
//       address: attr['address'] ?? '',
//       rating: attr['averageRating']?.toString() ?? '0.0',
//       reviewCount: attr['totalReviews']?.toString() ?? '0',
//       about: attr['about_us'] ?? '',
//       type: vendorType['name'] ?? '',
//       image: (json['media'] != null)
//           ? json['media'][0]['url'] ?? ''
//           : '', // handle null media
//       isFavourite: json['is_favourite'].toString() == "1",
//     );
//   }
// }

// venues_screen.dart
import 'package:url_launcher/url_launcher.dart';

// import 'vendor_details_screen.dart'; // adjust path to your file

// VenuesScreen.dart

// Replace this import with your actual VendorDetailsScreen import path

// Paste required imports at top of your file
import 'dart:async';

// ---------------- IMAGE HELPERS (same approach as Vendor.dart) ----------------
// Vendor.dart images: "https://happywedz.com/api/<path>" — that endpoint serves
// the backend /uploads/... files, so venues use exactly the same base.
const String kApiBase = "https://happywedz.com/api";

/// Local asset used when the API gives us no usable image (or the URL fails).
const String kVenuePlaceholderAsset = "assets/venue.png";

String normalizeImageUrl(String? url) {
  if (url == null) return '';
  final u = url.trim();
  if (u.isEmpty) return '';

  // protocol relative → https
  if (u.startsWith('//')) return normalizeImageUrl('https:$u');

  // absolute URL (S3 link from the API) → use as is, it already works
  if (u.startsWith('http://') || u.startsWith('https://')) return u;

  // backend relative path (/uploads/...) → same base as Vendor.dart
  if (u.startsWith('/')) return '$kApiBase$u';

  return '$kApiBase/$u';
}

/// Collects every usable image from an API service object.
/// media can be a List<String>, List<Map>, a Map or null — all handled here.
List<String> extractVenueImages(dynamic media, dynamic vendor, dynamic attributes) {
  final List<String> images = [];

  void add(dynamic raw) {
    if (raw == null) return;
    final u = normalizeImageUrl(raw.toString());
    if (u.isNotEmpty && u.startsWith('http') && !images.contains(u)) {
      images.add(u);
    }
  }

  if (media is List) {
    for (final item in media) {
      if (item is String) {
        add(item);
      } else if (item is Map) {
        add(item['original_url'] ?? item['url'] ?? item['image'] ?? item['thumb']);
      }
    }
  } else if (media is Map) {
    add(media['coverImage']);
    add(media['original_url']);
    add(media['url']);
    if (media['gallery'] is List) {
      for (final g in media['gallery']) {
        add(g is Map ? (g['url'] ?? g['original_url']) : g);
      }
    }
  } else if (media is String) {
    add(media);
  }

  // portfolio fallback (pipe separated) — same as vendor screen
  if (images.isEmpty && attributes is Map) {
    final portfolio =
        attributes['Portfolio'] ?? attributes['portfolio_urls'] ?? attributes['portfolio'];
    if (portfolio is String && portfolio.isNotEmpty) {
      for (final p in portfolio.split('|')) {
        add(p);
      }
    } else if (portfolio is List) {
      for (final p in portfolio) {
        add(p);
      }
    }
  }

  // vendor profile image fallback
  if (images.isEmpty && vendor is Map) {
    add(vendor['profileImage']);
  }

  return images;
}

// --- VenuesScreen starts here ---
class VenuesScreen extends StatefulWidget {
  const VenuesScreen({Key? key}) : super(key: key);

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  // Data
  final List<Venue> allVenues = [];
  List<Venue> venues = [];

  // Pagination & loading for infinite scroll
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int page = 1;
  final int limit = 10;
  int totalPages = 1;

  // Server-side search state
  String currentServerQuery = '';
  Timer? _searchDebounce;
  // NEW FILTERS
  String selectedVenueType = "";
  String selectedCapacity = "";
  String selectedPricePlate = "";
  String selectedRooms = "";

  // UI
  bool isList = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Filters (applied locally on top of loaded server results)
  String selectedCity = "";
  double minPrice = 0;
  double maxPrice = 200000;
  double selectedRating = 0;
  int currentLoadingPage = 0;
  bool isBulkLoading = false;

  // Wishlist (local)
  Set<String> favouriteVenues = {};
  String? currentUserId;
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadFavouritesFromLocal();
    fetchAllVenues(page: 1);     // 🔥 load everything once


    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (hasMore && !isLoadingMore) {
          fetchVenues(page: page + 1);
        }
      }
    });
    _searchController.addListener(_applyFiltersAndSearch);
  }

  Future<void> fetchAllVenues({int page = 1}) async {
    if (isLoadingMore) return;

    setState(() {
      if (page == 1) isLoading = true;
      isLoadingMore = true;
    });

    try {
      // image_exists=true → API sirf wahi venues bhejta hai jinki photo actually
      // available hai (website bhi yahi param use karti hai)
      final url = Uri.parse(
          "https://happywedz.com/api/vendor-services?vendorType=venue&page=$page&limit=20&image_exists=true"
      );

      final res = await http.get(url);

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List data = decoded["data"] ?? [];

        // total pages
        final pagination = decoded["pagination"] ?? {};
        totalPages = pagination["totalPages"] ?? 1;

        final newVenues = data.map((e) => Venue.fromJson(e)).toList();

        setState(() {
          if (page == 1) {
            allVenues.clear();
            allVenues.addAll(newVenues);
          } else {
            allVenues.addAll(newVenues);
          }

          venues = allVenues;
          hasMore = page < totalPages;
          this.page = page;
        });
      }
    } catch (e) {
      debugPrint("Error fetching venues: $e");
    }

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      currentServerQuery = value.trim();
      _startFreshLoad(); // resets + calls API
    });
  }


  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ----------------- Local storage -----------------
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }

  Future<void> _loadFavouritesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('favourite_venues') ?? [];
    setState(() => favouriteVenues = list.toSet());
  }

  Future<void> _saveFavouritesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favourite_venues', favouriteVenues.toList());
  }

  // ----------------- Scroll & search handlers -----------------
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = 200;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - threshold &&
        !isLoadingMore &&
        hasMore &&
        !isLoading) {
      fetchMoreVenues();
    }
  }

  void _startFreshLoad() {
    // Reset pagination & list, then fetch page 1 with currentServerQuery
    page = 1;
    totalPages = 1;
    hasMore = true;
    allVenues.clear();
    venues.clear();
    fetchVenues(page: 1, serverQuery: currentServerQuery);
  }

  // ----------------- Fetching (server aware) -----------------
  /// fetchVenues - loads a single page (appends to allVenues)
  Future<void> fetchVenues({int page = 1, String? serverQuery, bool onlyWithImages = true}) async {
    setState(() {
      // only show main spinner for first page / full refresh
      isLoading = page == 1;
      isLoadingMore = page != 1;
      this.page = page;
    });

    try {
      final encoded = Uri.encodeComponent("venue");
      final buffer = StringBuffer();
      // buffer.write("https://happywedz.com/api/vendor-services");
      // buffer.write("?subCategory=$encoded");
      // buffer.write("&page=$page");
      // buffer.write("&limit=$limit");
      // if (serverQuery != null && serverQuery.isNotEmpty) {
      //   buffer.write("&search=${Uri.encodeQueryComponent(serverQuery)}");
      // }
      buffer.write("https://happywedz.com/api/vendor-services");
      buffer.write("?vendorType=venue");
      buffer.write("&page=$page");
      buffer.write("&limit=$limit");
      if (onlyWithImages) buffer.write("&image_exists=true"); // sirf photo wale venues

      if (currentServerQuery.isNotEmpty) {
        buffer.write("&search=${Uri.encodeQueryComponent(currentServerQuery)}");
      }

      // If you want server-side city filter, you may add: &city=${Uri.encodeQueryComponent(selectedCity)}
      final url = Uri.parse(buffer.toString());

      debugPrint("Fetching venues → $url");

      final res = await http.get(url, headers: {"Accept": "application/json"});
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final List<dynamic> data = (decoded['data'] ?? []) as List<dynamic>;

        // Search ke sath photo-only filter lagane par kabhi kabhi 0 result aate
        // hain — us case me bina filter ke dobara try karo taaki search na tute.
        if (data.isEmpty &&
            onlyWithImages &&
            currentServerQuery.isNotEmpty &&
            page == 1) {
          await fetchVenues(page: 1, serverQuery: serverQuery, onlyWithImages: false);
          return;
        }

        // Determine total pages if API supplies total or pagination
        final totalItems = decoded['total'] ??
            decoded['pagination']?['totalItems'] ??
            decoded['pagination']?['total'] ??
            null;

        if (totalItems != null && totalItems is int && totalItems > 0) {
          totalPages = (totalItems / limit).ceil();
        } else if (decoded['pagination'] is Map &&
            decoded['pagination']['totalPages'] != null) {
          // fallback if API returns totalPages
          final tp = decoded['pagination']['totalPages'];
          if (tp is int) totalPages = tp;
          else totalPages = int.tryParse(tp?.toString() ?? '') ?? totalPages;
        } else {
          final fetchedCount = data.length;
          if (fetchedCount < limit) totalPages = page;
          else totalPages = page + 1;
        }

        // parse items safely — same parsing (incl. images) as fetchAllVenues
        final loaded = data
            .map((service) => Venue.fromJson(service as Map<String, dynamic>))
            .toList();

        // final loaded = data.map((service) {
        //   final attributes = service['attributes'] ?? {};
        //   final vendor = service['vendor'] ?? {};
        //   final subcategory = service['subcategory'] ?? {};
        //   final media = service['media'] ?? [];
        //
        //   String imageUrl = '';
        //
        //   if (media is List && media.isNotEmpty) {
        //     final first = media.first;
        //     if (first is String) imageUrl = first;
        //     else if (first is Map) {
        //       imageUrl = (first['url'] ?? first['original_url'] ?? '').toString();
        //     }
        //   } else if (media is Map) {
        //     imageUrl = (media['coverImage'] ?? media['original_url'] ?? '').toString();
        //   }
        //
        //   if (imageUrl.startsWith('/uploads/')) {
        //     imageUrl = "https://happywedzbackend.happywedz.com$imageUrl";
        //   }
        //   if (imageUrl.isEmpty) {
        //     imageUrl = 'https://via.placeholder.com/400x300.png?text=No+Image';
        //   }
        //
        //   return Venue(
        //     id: service['id'] ?? 0,
        //     vendorName: attributes['vendor_name'] ?? vendor['businessName'] ?? '',
        //     city: attributes['city'] ?? vendor['city'] ?? '',
        //     vegPrice: attributes['veg_price']?.toString() ?? '',
        //     nonVegPrice: attributes['non_veg_price']?.toString() ?? '',
        //     area: attributes['area'] ?? '',
        //     address: attributes['address'] ?? '',
        //     rating: attributes['averageRating']?.toString() ?? '0.0',
        //     reviewCount: attributes['totalReviews']?.toString() ?? '0',
        //     about: attributes['about_us'] ?? '',
        //     type: subcategory['name'] ?? vendor['vendorType']?['name'] ?? '',
        //     image: imageUrl,
        //     isFavourite: (service['is_favourite']?.toString() ?? '') == "1" ||
        //         service['is_favourite'] == true,
        //   );
        // }).toList();

        // append or replace depending on page
        setState(() {
          if (page == 1) {
            allVenues.clear();
            allVenues.addAll(loaded);
          } else {
            // avoid duplicates (sometimes API returns overlapping data)
            final existingIds = allVenues.map((e) => e.id).toSet();
            final newOnes =
            loaded.where((v) => !existingIds.contains(v.id)).toList();
            allVenues.addAll(newOnes);
          }

          // local filters applied on top of loaded data
          _applyFiltersAndSearch(); // sets venues from allVenues
          hasMore = page < totalPages;
          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        debugPrint('Venues API error: ${res.statusCode}');
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e, st) {
      debugPrint('Venues fetch error: $e\n$st');
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> fetchMoreVenues() async {
    if (!hasMore) return;
    if (isLoadingMore) return;
    setState(() => isLoadingMore = true);
    final next = page + 1;
    // fetch next page with same server query (if any)
    await fetchVenues(page: next, serverQuery: currentServerQuery);
    setState(() => isLoadingMore = false);
  }


  void  _applyFiltersAndSearch() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = allVenues.where((v) {
      final name = v.vendorName.toLowerCase();
      final city = v.city.toLowerCase();
      final type = v.type.toLowerCase();
      final area = v.area.toLowerCase();

      final rating = double.tryParse(v.rating) ?? 0;

      double price = 0;
      final match = RegExp(r'\d+').firstMatch(v.vegPrice);
      if (match != null) {
        price = double.tryParse(match.group(0)!) ?? 0;
      }

      return
        // SEARCH
        (query.isEmpty ||
            name.contains(query) ||
            city.contains(query) ||
            area.contains(query)) &&

            // CITY
            (selectedCity.isEmpty ||
                city.contains(selectedCity.toLowerCase())) &&

            // RATING
            rating >= selectedRating &&

            // PRICE RANGE
            price >= minPrice && price <= maxPrice &&

            // VENUE TYPE
            (selectedVenueType.isEmpty ||
                type.contains(selectedVenueType.toLowerCase())) &&

            // PRICE PER PLATE dropdown
            _pricePlateMatch(price, selectedPricePlate);

    }).toList();

    setState(() => venues = filtered);
  }


  int _extractCapacity(String area) {
    final match = RegExp(r'(\d+)\s*Seating').firstMatch(area);
    if (match != null) return int.tryParse(match.group(1)!) ?? 0;
    return 0;
  }

  bool _capacityMatch(int capacity, String filter) {
    if (filter.isEmpty) return true;

    switch (filter) {
      case "<100": return capacity < 100;
      case "100-200": return capacity >= 100 && capacity <= 200;
      case "200-500": return capacity >= 200 && capacity <= 500;
      case "500-1000": return capacity >= 500 && capacity <= 1000;
      case "1000+": return capacity > 1000;
    }
    return true;
  }

  bool _pricePlateMatch(double price, String filter) {
    switch (filter) {
      case "<1000": return price < 1000;
      case "1000-2000": return price >= 1000 && price <= 2000;
      case "2000-3000": return price >= 2000 && price <= 3000;
      case "3000+": return price > 3000;
    }
    return true;
  }

  bool _roomMatch(int rooms, String filter) {
    switch (filter) {
      case "10": return rooms == 10;
      case "10-20": return rooms >= 10 && rooms <= 20;
      case "20-30": return rooms >= 20 && rooms <= 30;
      case "30-40": return rooms >= 30 && rooms <= 40;
      case "40-50": return rooms >= 40 && rooms <= 50;
      case "50-100": return rooms >= 50 && rooms <= 100;
      case "100+": return rooms > 100;
    }
    return true;
  }


  Future<void> _toggleFavourite(Venue v) async {
    if (currentUserId == null) {
      AppSnackbar.info(context, 'Please sign in to manage your wishlist.');
      return;
    }

    final idStr = v.id.toString();
    setState(() {
      if (favouriteVenues.contains(idStr)) {
        favouriteVenues.remove(idStr);
        v.isFavourite = false;
      } else {
        favouriteVenues.add(idStr);
        v.isFavourite = true;
      }
    });

    await _saveFavouritesToLocal();

    // Optionally sync with API
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;
      final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
      final body = jsonEncode({'user_id': currentUserId, 'vendor_services_id': idStr});
      final res = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        final msg = m['message'] ?? 'Wishlist updated';
        AppSnackbar.success(context, msg.toString());
      }
    } catch (e) {
      debugPrint('Wishlist API error: $e');
    }
  }

  // ----------------- Filters sheet -----------------
  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // temp variables for sheet
        String tmpCity = selectedCity;
        double tmpMin = minPrice;
        double tmpMax = maxPrice;
        double tmpRating = selectedRating;

        String tmpVenueType = selectedVenueType;
        String tmpCapacity = selectedCapacity;
        String tmpPricePlate = selectedPricePlate;
        String tmpRooms = selectedRooms;

        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // const SizedBox(height: 20),
                  //
                  // // ---------------- CITY ----------------
                  // const Text('City', style: TextStyle(fontWeight: FontWeight.w600)),
                  // const SizedBox(height: 6),
                  // TextField(
                  //   decoration: InputDecoration(
                  //     hintText: 'Enter city',
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //   ),
                  //   controller: TextEditingController(text: tmpCity),
                  //   onChanged: (v) => setSheetState(() => tmpCity = v.trim()),
                  // ),

                  const SizedBox(height: 20),

                  // ---------------- VENUE TYPE ----------------
                  const Text('Venue Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  DropdownButtonFormField(
                    value: tmpVenueType.isEmpty ? null : tmpVenueType,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      "Banquet Halls",
                      "Marriage Garden / Lawns",
                      "Wedding Farmhouses",
                      "Wedding Resorts",
                      "Destination Wedding Venues",
                      "Kalyana Mandapams",
                      "4 Star And Above Wedding Hotels",
                    ]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => tmpVenueType = v.toString()),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- CAPACITY ----------------
                  const Text('Capacity', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  DropdownButtonFormField(
                    value: tmpCapacity.isEmpty ? null : tmpCapacity,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      "<100",
                      "100-200",
                      "200-500",
                      "500-1000",
                      "1000+",
                    ]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => tmpCapacity = v.toString()),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- PRICE PER PLATE ----------------
                  const Text('Price Per Plate', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  DropdownButtonFormField(
                    value: tmpPricePlate.isEmpty ? null : tmpPricePlate,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      "<1000",
                      "1000-2000",
                      "2000-3000",
                      "3000+",
                    ]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => tmpPricePlate = v.toString()),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- ROOMS ----------------
                  const Text('Rooms', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),

                  DropdownButtonFormField(
                    value: tmpRooms.isEmpty ? null : tmpRooms,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12))),
                    items: [
                      "10",
                      "10-20",
                      "20-30",
                      "30-40",
                      "40-50",
                      "50-100",
                      "100+",
                    ]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => tmpRooms = v.toString()),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- PRICE RANGE ----------------
                  const Text('Price Range',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: RangeValues(tmpMin, tmpMax),
                    min: 0,
                    max: 200000,
                    divisions: 100,
                    labels: RangeLabels(
                        '₹${tmpMin.toInt()}', '₹${tmpMax.toInt()}'),
                    onChanged: (vals) =>
                        setSheetState(() {
                          tmpMin = vals.start;
                          tmpMax = vals.end;
                        }),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- RATING ----------------
                  const Text('Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: tmpRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: tmpRating.toString(),
                    onChanged: (v) => setSheetState(() => tmpRating = v),
                  ),

                  const SizedBox(height: 20),

                  // ---------------- ACTION BUTTONS ----------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: const Text('Reset'),
                        onPressed: () {
                          setState(() {
                            selectedCity = "";
                            selectedVenueType = "";
                            selectedCapacity = "";
                            selectedPricePlate = "";
                            selectedRooms = "";
                            minPrice = 0;
                            maxPrice = 200000;
                            selectedRating = 0;
                          });
                          Navigator.pop(context);
                          _applyFiltersAndSearch();
                        },
                      ),
                      ElevatedButton(
                        child: const Text('Apply',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink),
                        onPressed: () {
                          setState(() {
                            selectedCity = tmpCity;
                            selectedVenueType = tmpVenueType;
                            selectedCapacity = tmpCapacity;
                            selectedPricePlate = tmpPricePlate;
                            selectedRooms = tmpRooms;
                            minPrice = tmpMin;
                            maxPrice = tmpMax;
                            selectedRating = tmpRating;
                          });
                          Navigator.pop(context);
                          _applyFiltersAndSearch();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Map<String, dynamic> _serviceShapeFromVenue(Venue v) {
  //   return {
  //     "attributes": {
  //       "vendor_name": v.vendorName,
  //       "veg_price": v.vegPrice,
  //       "non_veg_price": v.nonVegPrice,
  //       "area": v.area,
  //       "address": v.address,
  //       "averageRating": v.rating,
  //       "totalReviews": v.reviewCount,
  //       "about_us": v.about,
  //       "vendor_type": v.type,
  //       "latitude": v.latitude,
  //       "longitude": v.longitude,
  //     },
  //     "media": [
  //       {"original_url": v.image}
  //     ],
  //     "vendor": {
  //       "id": v.vendorId,                    // ✅ FIXED
  //       "vendor_subcategory_id": v.vendorSubcategoryId,
  //       "phone": "",
  //       "review_count": v.reviewCount,
  //
  //       "businessName": v.vendorName,
  //     }
  //   };
  // }
  Map<String, dynamic> _serviceShapeFromVenue(Venue v) {
    return {
      "id": v.id, // service id
      "vendor_id": v.vendorId, //
      "vendor_subcategory_id": v.vendorSubcategoryId,
      "attributes": {
        "vendor_name": v.vendorName,
        "veg_price": v.vegPrice,
        "non_veg_price": v.nonVegPrice,
        "area": v.area,
        "address": v.address,
        "averageRating": v.rating,
        "totalReviews": v.reviewCount,
        "about_us": v.about,
        "latitude": v.latitude,
        "longitude": v.longitude,
      },
      "vendor": {
        "id": v.vendorId,
        "businessName": v.vendorName,
      },
      // pass every image we parsed, not just the first one
      "image_exists": v.images.isNotEmpty,
      "media": (v.images.isNotEmpty ? v.images : [v.image])
          .where((e) => e.isNotEmpty)
          .map((e) => {"original_url": e})
          .toList(),
    };
  }

  // ----------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters =
        selectedCity.isNotEmpty ||
        minPrice != 0 ||
        maxPrice != 200000 ||
        selectedRating != 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        // -------- BACKGROUND GRADIENT (existing colors) --------
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // -------- HEADER --------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        'Venues',
                        textAlign: TextAlign.center,
                        style: AppText.pageTitle.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        tooltip: isList ? 'Grid view' : 'List view',
                        icon: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: Icon(
                            isList
                                ? Icons.grid_view_rounded
                                : Icons.view_agenda_outlined,
                            key: ValueKey(isList),
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        onPressed: () => setState(() => isList = !isList),
                      ),
                    ),
                  ],
                ),
              ),

              // -------- MAIN WHITE SHEET --------
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      // -------- SEARCH --------
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  style: AppText.body,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Search venues,name…',
                                    hintStyle: AppText.body.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                Pressable(
                                  onTap: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // -------- CLEAR FILTERS --------
                      if (hasActiveFilters)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: PremiumButton.text(
                              label: 'Clear filters',
                              size: PremiumButtonSize.small,
                              onPressed: () {
                                setState(() {
                                  selectedCity = "";
                                  minPrice = 0;
                                  maxPrice = 200000;
                                  selectedRating = 0;
                                });
                                _applyFiltersAndSearch();
                              },
                            ),
                          ),
                        ),

                      // -------- LIST / GRID CONTENT --------
                      Expanded(child: _buildContent(hasActiveFilters)),
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

  Future<void> _refreshVenues() async {
    page = 1;
    await fetchVenues(page: 1, serverQuery: currentServerQuery);
  }

  Widget _buildContent(bool hasActiveFilters) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: isList
            ? Skeletons.listCards(count: 4, height: 260)
            : Skeletons.grid(count: 6, aspectRatio: 0.72),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refreshVenues,
      child: venues.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                EmptyState(
                  title: 'No venues found',
                  message: 'Try changing your search or filters.',
                  icon: Icons.location_city_outlined,
                  actionLabel:
                      hasActiveFilters || _searchController.text.isNotEmpty
                      ? 'Clear filters'
                      : null,
                  onAction:
                      hasActiveFilters || _searchController.text.isNotEmpty
                      ? () {
                          _searchController.clear();
                          setState(() {
                            selectedCity = "";
                            minPrice = 0;
                            maxPrice = 200000;
                            selectedRating = 0;
                          });
                          _applyFiltersAndSearch();
                        }
                      : null,
                ),
              ],
            )
          : isList
          ? _buildList()
          : _buildGrid(),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   final primaryAccent = Colors.pink.shade600;
  //
  //   return Scaffold(
  //     backgroundColor: Colors.grey.shade50,
  //     appBar: AppBar(
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       toolbarHeight: 84,
  //       flexibleSpace: Container(
  //         decoration: const BoxDecoration(
  //           gradient: LinearGradient(colors: [Color(0xFFFEC5E5), Color(0xFFFFE4E1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  //           borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
  //         ),
  //       ),
  //       title: const Text('Venues', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
  //       centerTitle: true,
  //       actions: [
  //         IconButton(icon: Icon(isList ? Icons.list : Icons.grid_view), onPressed: () => setState(() => isList = !isList)),
  //       ],
  //     ),
  //     body: SafeArea(
  //       child: Column(
  //         children: [
  //           // search & filter row
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 12),
  //                     decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
  //                     child: Row(
  //                       children: [
  //                         const Icon(Icons.search, color: Colors.grey),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           child: TextField(
  //                             controller: _searchController,
  //                             onChanged: _onSearchChanged,
  //                             decoration: const InputDecoration(hintText: 'Search venues, city, name...', border: InputBorder.none),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 IconButton(icon: const Icon(Icons.filter_list, color: Colors.pink), onPressed: _openFilterSheet),
  //               ],
  //             ),
  //           ),
  //
  //           // results count + clear filters
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 12.0),
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 // Text('${venues.length} results', style: const TextStyle(color: Colors.black54)),
  //                 Row(
  //                   children: [
  //                     if (selectedCity.isNotEmpty || minPrice != 0 || maxPrice != 200000 || selectedRating != 0)
  //                       TextButton(
  //                         onPressed: () {
  //                           setState(() {
  //                             selectedCity = "";
  //                             minPrice = 0;
  //                             maxPrice = 200000;
  //                             selectedRating = 0;
  //                           });
  //                           _applyFiltersAndSearch();
  //                         },
  //                         child: const Text('Clear filters'),
  //                       ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //
  //           // main content
  //           Expanded(
  //             child: isLoading
  //                 ? const Center(child: CircularProgressIndicator())
  //                 : venues.isEmpty
  //                 ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No venues found'))])
  //                 : RefreshIndicator(
  //               color: Colors.pink,
  //               onRefresh: () async {
  //                 // refresh current search state (page 1)
  //                 page = 1;
  //                 await fetchVenues(page: 1, serverQuery: currentServerQuery);
  //               },
  //               child: isList ? _buildList() : _buildGrid(),
  //             ),
  //           ),
  //           // floating AI button (unchanged)
  //
  //         ],
  //
  //       ),
  //
  //     ),
  //   );
  // }

  Widget _buildList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: venues.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index >= venues.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: AppLoader(),
          );
        }
        return FadeSlideIn(
          delay: AppMotion.staggerFor(index),
          child: _buildVenueCard(context, venues[index]),
        );
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        // Compact card (no action row) fits comfortably at this ratio.
        childAspectRatio: 0.72,
      ),
      itemCount: venues.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= venues.length) {
          return const SkeletonBox(height: double.infinity, radius: AppRadii.lg);
        }
        return FadeSlideIn(
          delay: AppMotion.staggerFor(index),
          child: _buildVenueCard(context, venues[index], compact: true),
        );
      },
    );
  }

  Widget _buildVenueCard(
    BuildContext context,
    Venue venue, {
    bool compact = false,
  }) {
    void openDetails() => Navigator.push(
      context,
      AnimatedPageRoute(
        page: VendorDetailsScreen(service: _serviceShapeFromVenue(venue)),
        style: PageTransitionStyle.slideRight,
      ),
    );

    final ratingText =
        double.tryParse(venue.rating)?.toStringAsFixed(1) ?? '0.0';
    final hasRating = (double.tryParse(venue.rating) ?? 0) > 0;

    return AppCard(
      onTap: openDetails,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // image + fav + overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                child: _venueImage(venue, height: compact ? 118 : 168),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: FavoriteButton(
                  isFavorite:
                      venue.isFavourite ||
                      favouriteVenues.contains(venue.id.toString()),
                  onTap: () => _toggleFavourite(venue),
                ),
              ),
              if (venue.city.trim().isNotEmpty)
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  right: hasRating ? 68 : AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: AppRadii.rSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            venue.city,
                            style: AppText.caption.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hasRating)
                Positioned(
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successDark,
                      borderRadius: AppRadii.rSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ratingText,
                          style: AppText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  venue.vendorName,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (venue.vegPrice.isNotEmpty ||
                    venue.nonVegPrice.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xxs,
                    children: [
                      if (venue.vegPrice.isNotEmpty)
                        Text(
                          'Veg: ${venue.vegPrice}',
                          style: AppText.priceSm,
                        ),
                      if (venue.nonVegPrice.isNotEmpty)
                        Text(
                          'Non-veg: ${venue.nonVegPrice}',
                          style: AppText.priceSm,
                        ),
                    ],
                  ),
                ],
                if (venue.area.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(icon: Icons.location_city_rounded, text: venue.area),
                ],
                if (venue.type.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  _MetaRow(icon: Icons.event_rounded, text: venue.type),
                ],

                // The action row is list-only — in the grid there is no room
                // for it without overflowing the tile.
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _actionItem(
                        icon: const Icon(
                          Icons.call_rounded,
                          color: AppColors.successDark,
                          size: 18,
                        ),
                        label: "Call",
                        onTap: () => _tryCall(""),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _actionItem(
                        icon: Image.asset(
                          'assets/whatsapp.png',
                          height: 20,
                          width: 20,
                        ),
                        label: "WhatsApp",
                        onTap: () => _tryWhatsApp(""),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _actionItem(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        label: "Message",
                        onTap: openDetails,
                      ),
                      const Spacer(),
                      PremiumButton.text(
                        label: 'View',
                        size: PremiumButtonSize.small,
                        onPressed: openDetails,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Venue card image — tries every URL the API gave us, and falls back to the
  /// bundled asset if none of them load (some legacy vendor photos are gone).
  Widget _venueImage(Venue venue, {double height = 140}) {
    final urls = venue.images.isNotEmpty
        ? venue.images
        : (venue.image.isNotEmpty ? [venue.image] : const <String>[]);

    if (urls.isEmpty) return _fallbackImage(height);

    return _NetworkImageWithFallback(
      urls: urls,
      height: height,
      fallback: _fallbackImage(height),
    );
  }

  Widget _fallbackImage(double height) => Image.asset(
        kVenuePlaceholderAsset,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (ctx, e, st) => Container(
          height: height,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
        ),
      );

  Widget _actionItem({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }

  Widget _smallAction(Widget icon, String label) {
    return Column(children: [CircleAvatar(backgroundColor: Colors.grey.shade100, child: icon), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54))]);
  }

  Future<void> _tryCall(String phone) async {
    if (phone.isEmpty) {
      AppSnackbar.info(context, 'Phone number not available for this venue.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _tryWhatsApp(String phone) async {
    if (phone.isEmpty) {
      AppSnackbar.info(context, 'WhatsApp is not available for this venue.');
      return;
    }
    final url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}


/// Loads [urls] one by one; if a URL fails (404/403/timeout) it automatically
/// tries the next one, and shows [fallback] once every URL has failed.
class _NetworkImageWithFallback extends StatefulWidget {
  final List<String> urls;
  final double height;
  final Widget fallback;

  const _NetworkImageWithFallback({
    Key? key,
    required this.urls,
    required this.height,
    required this.fallback,
  }) : super(key: key);

  @override
  State<_NetworkImageWithFallback> createState() => _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<_NetworkImageWithFallback> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    if (index >= widget.urls.length) return widget.fallback;

    return Image.network(
      widget.urls[index],
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      // Fade the decoded frame in so cards do not pop.
      frameBuilder: (ctx, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          child: child,
        );
      },
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return LoadingShimmer(
          child: SkeletonBox(height: widget.height, width: double.infinity),
        );
      },
      errorBuilder: (ctx, e, st) {
        // try the next URL on the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index < widget.urls.length) setState(() => index++);
        });
        return LoadingShimmer(
          child: SkeletonBox(height: widget.height, width: double.infinity),
        );
      },
    );
  }
}

/// Small icon + muted text line used inside the venue card body.
class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppText.cardSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Venue model
class Venue {
  final int id;
  final String vendorName;
  final String city;
  final String vegPrice;
  final String nonVegPrice;
  final String area;
  final String address;
  final String rating;
  final String reviewCount;
  final String about;
  final String type;
  final String image;
  final List<String> images;
  final String? rooms;
  final double? latitude;     // ✅
  final double? longitude;
  final int? vendorId;
  final int? vendorSubcategoryId;

  bool isFavourite;

  Venue({
    required this.id,
    required this.vendorName,
    required this.city,
    required this.vegPrice,
    required this.nonVegPrice,
    required this.area,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.about,
    required this.type,
    required this.image,
    this.images = const [],
    this.rooms,
    this.latitude,
    this.longitude,
    this.isFavourite = false, this.vendorId, this.vendorSubcategoryId,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    final attr = json['attributes'] ?? {};
    final vendor = json['vendor'] ?? {};
    final subcategory = json['subcategory'] ?? {};
    final latRaw = attr['latitude'];
    final lngRaw = attr['longitude'];

    double? lat;
    double? lng;

    if (latRaw is String) lat = double.tryParse(latRaw);
    if (lngRaw is String) lng = double.tryParse(lngRaw);
    if (latRaw is num) lat = latRaw.toDouble();
    if (lngRaw is num) lng = lngRaw.toDouble();

    // IMAGE — same handling as the vendor screen
    final List<String> images = extractVenueImages(json["media"], vendor, attr);
    final String image = images.isNotEmpty ? images.first : "";

    return Venue(
      id: json["id"] ?? 0,
      vendorId: json["vendor_id"],                 // ✅ add
      vendorSubcategoryId: json["vendor_subcategory_id"], // ✅ add
      vendorName: attr["name"] ?? attr["vendor_name"] ?? vendor["businessName"] ?? "",
      city: attr["city"] ?? vendor["city"] ?? "",
      vegPrice: attr["veg_price"]?.toString() ?? "",
      nonVegPrice: attr["non_veg_price"]?.toString() ?? "",
      area: attr["area"] ?? "",
      address: attr["address"] ?? "",
      rating: attr["averageRating"]?.toString() ?? "0",
      reviewCount: attr["totalReviews"]?.toString() ?? "0",
      about: attr["about_us"] ?? "",
      type: subcategory["name"]?.toString() ?? "",     // << Correct venue type
      rooms: attr["rooms"]?.toString(),
      image: image,
      images: images,
      latitude: lat,
      longitude: lng,
      isFavourite: json["is_favourite"]?.toString() == "1",
    );
  }
}
