import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';
import '../vendor/vendordetailsscreen.dart';

class FavouritesPage extends StatefulWidget {
  const FavouritesPage({Key? key}) : super(key: key);

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}
class _FavouritesPageState extends State<FavouritesPage> {
  bool isLoading = false;
  List<dynamic> wishlistItems = [];
  String? currentUserId;
  Set<String> favouriteVendors = {};

  /// AUDIT FIX: the screen had no failure state at all. A network error was
  /// swallowed by the catch below and the body then rendered "No favourites
  /// yet" — telling the user their saved vendors had vanished when in fact the
  /// request never completed. This holds the last failure so [_buildBody] can
  /// show a real error with a working retry instead.
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchWishlist();
  }

  Future<void> _loadUserAndFetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id')?.toString();
    final token = prefs.getString('auth_token');
    if (!mounted) return;

    if (storedId == null || token == null || token.isEmpty) {
      debugPrint('❌ User not signed in or token missing');
      return;
    }

    setState(() {
      currentUserId = storedId;
    });

    fetchWishlist();
  }

  Future<void> fetchWishlist() async {
    setState(() {
      isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (!mounted) return;

      if (token.isEmpty || currentUserId == null) {
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse('https://happywedz.com/api/wishlist');
      debugPrint('🌍 Fetching wishlist → $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (!mounted) return;

      // Previously any non-200 fell through silently and the list stayed empty.
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final List<dynamic> items = data['data'] ?? [];

      final ids = items
          .map((item) => item['vendor_services_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      // The detail lookups used to run one after another inside a for-loop, so
      // a 20-item wishlist meant 20 sequential round trips. They are
      // independent, so they now run together — same endpoint, same parsing.
      final details = await Future.wait(ids.map(fetchVendorDetails));
      if (!mounted) return;

      final fullDetails = <dynamic>[];
      for (var i = 0; i < ids.length; i++) {
        if (details[i].isNotEmpty) {
          fullDetails.add({
            'vendor_services_id': ids[i],
            'attributes': details[i],
          });
        }
      }

      setState(() {
        wishlistItems = fullDetails;
        favouriteVendors = fullDetails
            .map((e) => e['vendor_services_id']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toSet();
      });
    } catch (e) {
      debugPrint("💥 Error fetching wishlist: $e");
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      // Guarded: the user can pop this screen mid-request.
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>> fetchVendorDetails(String vendorServiceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse('https://happywedz.com/api/vendor-services/$vendorServiceId');
    debugPrint('🌍 Fetching vendor service → $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // API actual structure:
        // { id: 123, attributes: { name, city, ... } }
        if (data is Map && data.containsKey('attributes')) {
          return data['attributes'] ?? {};
        }
      }
    } catch (e) {
      debugPrint("💥 Vendor service fetch error: $e");
    }
    return {};
  }

  Future<void> toggleWishlist(String vendorServiceId) async {
    if (currentUserId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
    final body = {
      'user_id': currentUserId,
      'vendor_services_id': vendorServiceId,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        setState(() {
          if (favouriteVendors.contains(vendorServiceId)) {
            favouriteVendors.remove(vendorServiceId);
            wishlistItems.removeWhere(
                  (element) =>
              element['vendor_services_id'].toString() == vendorServiceId,
            );
          } else {
            favouriteVendors.add(vendorServiceId);
            fetchWishlist();
          }
        });
      }
    } catch (e) {
      debugPrint("💥 Error toggling wishlist: $e");
    }
  }

  /// Resolves the card image, preserving the existing URL rules:
  /// `/uploads/...` paths are served from the backend host, everything else is
  /// used as-is.
  String _resolveImage(List<String> media) {
    if (media.isEmpty) return '';
    final first = media[0];
    return first.startsWith('/uploads/')
        ? 'https://happywedzbackend.happywedz.com$first'
        : first;
  }

  // PREMIUM CARD UI
  Widget buildWishlistCard({
    required Map<String, dynamic> attributes,
    required String vendorServiceId,
    required List<String> media,
    required VoidCallback onRemove,
    required VoidCallback onTap,
  }) {
    final name = attributes['name'] ?? "Unnamed Venue";
    final city = attributes['city'] ?? "Unknown Location";
    final imageUrl = _resolveImage(media);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        colors: [AppColors.blush, Colors.white],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // IMAGE
          Stack(
            children: [
              NetworkImageWidget(
                url: imageUrl,
                height: 200,
                width: double.infinity,
                memCacheWidth: 900,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                scrim: true,
              ),

              // REMOVE BUTTON
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: FavoriteButton(
                  isFavorite: true,
                  size: 40,
                  iconSize: 21,
                  onTap: onRemove,
                ),
              ),
            ],
          ),

          // DETAILS
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '$city',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardSubtitle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // TOP BAR
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    const AppBackButton(color: AppColors.textOnPrimary),
                    Expanded(
                      child: Text(
                        'Wishlist',
                        textAlign: TextAlign.center,
                        style: AppText.pageTitle.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.textOnPrimary,
                      ),
                      onPressed: fetchWishlist,
                    ),
                  ],
                ),
              ),

              // BODY
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Skeletons.listCards(count: 3, height: 280),
      );
    }

    // AUDIT FIX: a failed load now says so and offers a retry that really
    // re-issues the request, instead of silently rendering the empty state.
    if (_error != null) {
      return ErrorState(error: _error, onRetry: fetchWishlist);
    }

    if (wishlistItems.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: fetchWishlist,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            const EmptyState(
              title: 'No favourites yet',
              message: 'Tap the heart on any vendor to save it here.',
              icon: Icons.favorite_border_rounded,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: fetchWishlist,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: wishlistItems.length,
        itemBuilder: (ctx, i) {
          final service = wishlistItems[i];
          final vendorServiceId = service['vendor_services_id'] ?? '';
          final attributes = service['attributes'] ?? {};
          final media = attributes['Portfolio'] != null
              ? attributes['Portfolio'].toString().split('|')
              : [];

          return FadeSlideIn(
            delay: AppMotion.staggerFor(i),
            child: buildWishlistCard(
              attributes: Map<String, dynamic>.from(attributes),
              vendorServiceId: vendorServiceId,
              media: List<String>.from(media),
              onRemove: () => toggleWishlist(vendorServiceId),
              onTap: () {
                Navigator.push(
                  context,
                  AnimatedPageRoute(
                    page: VendorDetailsScreen(
                      service: {
                        'attributes': attributes,
                        'media': media,
                        'vendor_services_id': vendorServiceId,
                      },
                    ),
                    style: PageTransitionStyle.slideRight,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// class _FavouritesPageState extends State<FavouritesPage> {
//   bool isLoading = false;
//   List<dynamic> wishlistItems = [];
//   String? currentUserId;
//   Set<String> favouriteVendors = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadUserAndFetchWishlist();
//   }
//
//   Future<void> _loadUserAndFetchWishlist() async {
//     final prefs = await SharedPreferences.getInstance();
//     final storedId = prefs.getInt('user_id')?.toString();
//     final token = prefs.getString('auth_token');
//
//     if (storedId == null || token == null || token.isEmpty) {
//       debugPrint('❌ User not signed in or token missing');
//       return;
//     }
//
//     setState(() {
//       currentUserId = storedId;
//     });
//
//     fetchWishlist();
//   }
//
//   Future<void> fetchWishlist() async {
//     setState(() => isLoading = true);
//
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('auth_token') ?? '';
//       if (token.isEmpty || currentUserId == null) {
//         setState(() => isLoading = false);
//         return;
//       }
//
//       final url = Uri.parse('https://happywedz.com/api/wishlist');
//       print('🌍 Fetching wishlist → $url');
//
//       final response = await http.get(
//         url,
//         headers: {
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       print('📬 Wishlist response: ${response.statusCode}');
//       print('📦 Body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final List<dynamic> items = data['data'] ?? [];
//
//         print('🧾 Wishlist count: ${items.length}');
//
//         List<dynamic> fullDetails = [];
//
//         // For each wishlist item, get full vendor service details
//         for (var item in items) {
//           final vendorServiceId = item['vendor_services_id']?.toString() ?? '';
//           if (vendorServiceId.isEmpty) continue;
//
//           final vendorData = await fetchVendorDetails(vendorServiceId);
//
//           if (vendorData.isNotEmpty) {
//             fullDetails.add({
//               'vendor_services_id': vendorServiceId,
//               'attributes': vendorData,
//             });
//           }
//         }
//         setState(() {
//           wishlistItems = fullDetails;
//           favouriteVendors = fullDetails
//               .map((e) => e['vendor_services_id']?.toString() ?? '')
//               .where((e) => e.isNotEmpty)
//               .toSet();
//         });
//       } else {
//         print('❌ Failed to load wishlist: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint("💥 Error fetching wishlist: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }
//
//   Future<Map<String, dynamic>> fetchVendorDetails(String vendorServiceId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token') ?? '';
//
//     final url = Uri.parse('https://happywedz.com/api/vendor-services/$vendorServiceId');
//     print('🌍 Fetching vendor service → $url');
//
//     try {
//       final response = await http.get(
//         url,
//         headers: {
//           'Accept': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//       );
//
//       print('📬 Vendor service ${response.statusCode}');
//       print('📦 Vendor details: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data is Map && data.containsKey('attributes')) {
//           return data['attributes'] ?? {};
//         } else if (data is List && data.isNotEmpty) {
//           return data[0]['attributes'] ?? {};
//         }
//       } else {
//         print('🚫 Vendor service fetch failed: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint("💥 Vendor service fetch error: $e");
//     }
//     return {};
//   }
//
//
//   Future<void> toggleWishlist(String vendorServiceId) async {
//     if (currentUserId == null) return;
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token') ?? '';
//
//     final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
//     final body = {'user_id': currentUserId, 'vendor_services_id': vendorServiceId};
//
//     try {
//       final response = await http.post(url, headers: {
//         'Accept': 'application/json',
//         'Authorization': 'Bearer $token',
//       }, body: body);
//
//       if (response.statusCode == 200) {
//         setState(() {
//           if (favouriteVendors.contains(vendorServiceId)) {
//             favouriteVendors.remove(vendorServiceId);
//             wishlistItems.removeWhere(
//                     (element) => element['vendor_services_id'].toString() == vendorServiceId);
//           } else {
//             favouriteVendors.add(vendorServiceId);
//             fetchWishlist();
//           }
//         });
//       } else {
//         debugPrint("❌ Toggle failed: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("💥 Error toggling wishlist: $e");
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return DefaultTabController(
//       length: 1, // You can add tabs if needed
//       child: Scaffold(
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [
//                 Color(0xFFFF69B4), // Hot Pink
//                 Color(0xFFFFB6C1), // Light Pink
//                 Colors.white,       // White
//               ],
//               stops: [0.0, 0.3, 0.6],
//             ),
//           ),
//           child: SafeArea(
//             child: Column(
//               children: [
//                 // Custom AppBar
//                 Container(
//                   color: Colors.transparent,
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.arrow_back, color: Colors.white),
//                           onPressed: () => Navigator.pop(context),
//                         ),
//                         const Text(
//                           'Wishlist',
//                           style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 20),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.refresh, color: Colors.white),
//                           onPressed: fetchWishlist,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 // Body
//                 Expanded(
//                   child: isLoading
//                       ? const Center(
//                     child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
//                   )
//                       : wishlistItems.isEmpty
//                       ? const Center(
//                     child: Text(
//                       'No favourites yet.\nTap ♥ on any vendor to save it here!',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 16, color: Colors.black54),
//                     ),
//                   )
//                       : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     itemCount: wishlistItems.length,
//                     itemBuilder: (ctx, index) {
//                       final service = wishlistItems[index];
//                       final vendorServiceId = service['vendor_services_id']?.toString() ?? '';
//                       final attributes = service['attributes'] ?? {};
//                       final businessName = attributes['Name'] ?? 'Unnamed Venue';
//                       final city = attributes['city'] ?? 'Unknown Location';
//                       final media = attributes['Portfolio'] != null
//                           ? attributes['Portfolio'].toString().split('|')
//                           : [];
//                       final imageUrl = media.isNotEmpty
//                           ? (media[0].toString().startsWith('/uploads/')
//                           ? "https://happywedzbackend.happywedz.com${media[0]}"
//                           : media[0])
//                           : 'https://via.placeholder.com/400x300';
//
//                       return Card(
//                         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 4,
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(16),
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => VendorDetailsScreen(
//                                   service: {
//                                     'attributes': attributes,
//                                     'media': media,
//                                     'vendor_services_id': vendorServiceId,
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // Vendor image
//                               Stack(
//                                 children: [
//                                   // Vendor image
//                                   ClipRRect(
//                                     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//                                     child: Image.network(
//                                       imageUrl,
//                                       width: double.infinity,
//                                       height: 200,
//                                       fit: BoxFit.cover,
//                                       errorBuilder: (context, error, stackTrace) => Container(
//                                         color: Colors.grey[300],
//                                         height: 200,
//                                         child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
//                                       ),
//                                     ),
//                                   ),
//                                   // ❌ Cross button at top-right
//                                   if (favouriteVendors.contains(vendorServiceId))
//                                     Positioned(
//                                       top: 8,
//                                       right: 8,
//                                       child: InkWell(
//                                         onTap: () => toggleWishlist(vendorServiceId),
//                                         borderRadius: BorderRadius.circular(20),
//                                         child: Container(
//                                           padding: const EdgeInsets.all(6),
//                                           decoration: BoxDecoration(
//                                             color: Colors.white.withValues(alpha: 0.85),
//                                             shape: BoxShape.circle,
//                                           ),
//                                           child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//
//                               Padding(
//                                 padding: const EdgeInsets.all(12.0),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // Vendor details
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             businessName,
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 18,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Text(
//                                             city,
//                                             style: const TextStyle(
//                                               color: Colors.grey,
//                                               fontSize: 14,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                     // Favorite button
//                                     // ❌ Remove from wishlist button
//
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//
//
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//
//       ),
//     );
//   }
//
//
//
// }
