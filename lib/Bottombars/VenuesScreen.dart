import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai_chat_screen/ai_chat_screen.dart';
import '../vendor/vendordetailsscreen.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'GenieScreen.dart';

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
//                       color: Colors.purple.withOpacity(0.5),
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
//           color: Colors.white.withOpacity(0.9),
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
//               color: Colors.black.withOpacity(0.08),
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
//                             color: Colors.white.withOpacity(0.85),
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
//   //             color: Colors.black.withOpacity(0.1),
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
//   //                           color: Colors.white.withOpacity(0.85),
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
      final url = Uri.parse(
          "https://happywedz.com/api/vendor-services?vendorType=venue&page=$page&limit=20"
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
  Future<void> fetchVenues({int page = 1, String? serverQuery}) async {
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

        // parse items safely
        // parse items safely
        final loaded = data.map((service) {
          final attributes = service['attributes'] ?? {};
          final vendor = service['vendor'] ?? {};
          final subcategory = service['subcategory'] ?? {};
          final media = service['media'] ?? [];
          final vendorId = service['vendor_id'];
          final vendorSubcategoryId = service['vendor_subcategory_id'];

          // ✅ 1. READ lat/lng from attributes
          final latRaw = attributes['latitude'];
          final lngRaw = attributes['longitude'];

          double? lat;
          double? lng;

          if (latRaw is String) lat = double.tryParse(latRaw);
          if (lngRaw is String) lng = double.tryParse(lngRaw);
          if (latRaw is num) lat = latRaw.toDouble();
          if (lngRaw is num) lng = lngRaw.toDouble();

          debugPrint("VENUE ${service['id']} RAW LAT=$latRaw LNG=$lngRaw  =>  $lat , $lng");
            print(lat);
            print(lng);

          // 🔹 IMAGE
          String imageUrl = '';

          if (media is List && media.isNotEmpty) {
            final first = media.first;
            if (first is String) {
              imageUrl = first;
            } else if (first is Map) {
              imageUrl = (first['url'] ?? first['original_url'] ?? '').toString();
            }
          } else if (media is Map) {
            imageUrl = (media['coverImage'] ?? media['original_url'] ?? '').toString();
          }

          if (imageUrl.startsWith('/uploads/')) {
            imageUrl = "https://happywedzbackend.happywedz.com$imageUrl";
          }
          if (imageUrl.isEmpty) {
            imageUrl = 'https://via.placeholder.com/400x300.png?text=No+Image';
          }

          // ✅ 2. PASS latitude & longitude into Venue constructor
          return Venue(
            id: service['id'] ?? 0,
            vendorId: vendorId,                     // ✅ add this
            vendorSubcategoryId: vendorSubcategoryId,
            vendorName: attributes['vendor_name'] ?? vendor['businessName'] ?? '',
            city: attributes['city'] ?? vendor['city'] ?? '',
            vegPrice: attributes['veg_price']?.toString() ?? '',
            nonVegPrice: attributes['non_veg_price']?.toString() ?? '',
            area: attributes['area'] ?? '',
            address: attributes['address'] ?? '',
            rating: attributes['averageRating']?.toString() ?? '0.0',
            reviewCount: attributes['totalReviews']?.toString() ?? '0',
            about: attributes['about_us'] ?? '',
            type: subcategory['name'] ?? vendor['vendorType']?['name'] ?? '',
            image: imageUrl,
            latitude: lat,      // 👈 important
            longitude: lng,     // 👈 important
            isFavourite: (service['is_favourite']?.toString() ?? '') == "1" ||
                service['is_favourite'] == true,
          );
        }).toList();

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to manage wishlist')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
      "vendor_id": v.vendorId, // ✅ THIS WAS MISSING
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
      "media": [
        {"original_url": v.image}
      ]
    };
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final primaryAccent = Colors.pink.shade600;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 84,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFEC5E5), Color(0xFFFFE4E1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
        ),
        title: const Text('Venues', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(isList ? Icons.list : Icons.grid_view), onPressed: () => setState(() => isList = !isList)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // search & filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(25)),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: const InputDecoration(hintText: 'Search venues, city, name...', border: InputBorder.none),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.filter_list, color: Colors.pink), onPressed: _openFilterSheet),
                ],
              ),
            ),

            // results count + clear filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Text('${venues.length} results', style: const TextStyle(color: Colors.black54)),
                  Row(
                    children: [
                      if (selectedCity.isNotEmpty || minPrice != 0 || maxPrice != 200000 || selectedRating != 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedCity = "";
                              minPrice = 0;
                              maxPrice = 200000;
                              selectedRating = 0;
                            });
                            _applyFiltersAndSearch();
                          },
                          child: const Text('Clear filters'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // main content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : venues.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No venues found'))])
                  : RefreshIndicator(
                color: Colors.pink,
                onRefresh: () async {
                  // refresh current search state (page 1)
                  page = 1;
                  await fetchVenues(page: 1, serverQuery: currentServerQuery);
                },
                child: isList ? _buildList() : _buildGrid(),
              ),
            ),
            // floating AI button (unchanged)

          ],

        ),

      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: venues.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == venues.length) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: CircularProgressIndicator()));
        }
        return _buildVenueCard(context, venues[index]);
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.50),
      itemCount: venues.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == venues.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
        }
        return _buildVenueCard(context, venues[index]);
      },
    );
  }

  Widget _buildVenueCard(BuildContext context, Venue venue) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(service: _serviceShapeFromVenue(venue)))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // image + fav + overlays
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: Image.network(venue.image, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (ctx, e, st) => Container(height: 140, color: Colors.grey[200], child: const Center(child: Icon(Icons.broken_image)))),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _toggleFavourite(venue),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                  child: Icon(venue.isFavourite || favouriteVenues.contains(venue.id.toString()) ? Icons.favorite : Icons.favorite_border, color: Colors.pink, size: 20),
                ),
              ),
            ),
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 12),
                  const SizedBox(width: 6),
                  SizedBox(width: 120, child: Text(venue.city, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(6)),
                child: Row(children: [
                  const Icon(Icons.star, color: Colors.white, size: 12),
                  const SizedBox(width: 6),
                  Text(double.tryParse(venue.rating)?.toStringAsFixed(1) ?? '0.0', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ]),
          // details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(venue.vendorName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (venue.vegPrice.isNotEmpty) Text('Veg: ${venue.vegPrice}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (venue.nonVegPrice.isNotEmpty) Text('Non-veg: ${venue.nonVegPrice}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_city, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(venue.area, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TYPE
                  Row(
                    children: [
                      const Icon(Icons.event, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venue.type,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ACTION BUTTONS (Wrapped to avoid overflow)
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _actionItem(
                        icon: const Icon(Icons.call, color: Colors.green),
                        label: "Call",
                        onTap: () => _tryCall(""),
                      ),
                      _actionItem(
                        icon: Image.asset('assets/whatsapp.png', height: 30, width: 30),
                        label: "WhatsApp",
                        onTap: () => _tryWhatsApp(""),
                      ),
                      _actionItem(
                        icon: const Icon(Icons.message, color: Colors.blue),
                        label: "Message",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(service: _serviceShapeFromVenue(venue)))),
                      ),
                    ],
                  ),
                ],
              )
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _actionItem({required Widget icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade200,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: icon,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _smallAction(Widget icon, String label) {
    return Column(children: [CircleAvatar(backgroundColor: Colors.grey.shade100, child: icon), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54))]);
  }

  Future<void> _tryCall(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone not available')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _tryWhatsApp(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WhatsApp not available')));
      return;
    }
    final url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
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

    // IMAGE FIX
    String image = "";
    final media = json["media"];
    if (media is List && media.isNotEmpty) {
      if (media.first is String) {
        image = media.first;
      } else if (media.first is Map) {
        image = media.first["url"] ?? media.first["original_url"] ?? "";
      }
    }

    if (image.startsWith("/uploads/")) {
      image = "https://happywedzbackend.happywedz.com$image";
    }

    // fall back
    if (image.isEmpty) {
      image = "https://via.placeholder.com/400x300.png?text=No+Image";
    }

    return Venue(
      id: json["id"] ?? 0,
      vendorId: json["vendor_id"],                 // ✅ add
      vendorSubcategoryId: json["vendor_subcategory_id"], // ✅ add
      vendorName: attr["name"] ?? vendor["businessName"] ?? "",
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
      latitude: lat,
      longitude: lng,
      isFavourite: json["is_favourite"]?.toString() == "1",
    );
  }
}
