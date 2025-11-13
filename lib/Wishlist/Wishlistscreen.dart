import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchWishlist();
  }

  Future<void> _loadUserAndFetchWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id')?.toString();
    final token = prefs.getString('auth_token');

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
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty || currentUserId == null) {
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse('https://happywedz.com/api/wishlist');
      print('🌍 Fetching wishlist → $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Wishlist response: ${response.statusCode}');
      print('📦 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];

        print('🧾 Wishlist count: ${items.length}');

        List<dynamic> fullDetails = [];

        // For each wishlist item, get full vendor service details
        for (var item in items) {
          final vendorServiceId = item['vendor_services_id']?.toString() ?? '';
          if (vendorServiceId.isEmpty) continue;

          final vendorData = await fetchVendorDetails(vendorServiceId);

          if (vendorData.isNotEmpty) {
            fullDetails.add({
              'vendor_services_id': vendorServiceId,
              'attributes': vendorData,
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
      } else {
        print('❌ Failed to load wishlist: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("💥 Error fetching wishlist: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>> fetchVendorDetails(String vendorServiceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url = Uri.parse('https://happywedz.com/api/vendor-services/$vendorServiceId');
    print('🌍 Fetching vendor service → $url');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📬 Vendor service ${response.statusCode}');
      print('📦 Vendor details: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('attributes')) {
          return data['attributes'] ?? {};
        } else if (data is List && data.isNotEmpty) {
          return data[0]['attributes'] ?? {};
        }
      } else {
        print('🚫 Vendor service fetch failed: ${response.statusCode}');
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
    final body = {'user_id': currentUserId, 'vendor_services_id': vendorServiceId};

    try {
      final response = await http.post(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      if (response.statusCode == 200) {
        setState(() {
          if (favouriteVendors.contains(vendorServiceId)) {
            favouriteVendors.remove(vendorServiceId);
            wishlistItems.removeWhere(
                    (element) => element['vendor_services_id'].toString() == vendorServiceId);
          } else {
            favouriteVendors.add(vendorServiceId);
            fetchWishlist();
          }
        });
      } else {
        debugPrint("❌ Toggle failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("💥 Error toggling wishlist: $e");
    }
  }

  @override
  @override
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1, // You can add tabs if needed
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF69B4), // Hot Pink
                Color(0xFFFFB6C1), // Light Pink
                Colors.white,       // White
              ],
              stops: [0.0, 0.3, 0.6],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom AppBar
                Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Wishlist',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: fetchWishlist,
                        ),
                      ],
                    ),
                  ),
                ),

                // Body
                Expanded(
                  child: isLoading
                      ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                  )
                      : wishlistItems.isEmpty
                      ? const Center(
                    child: Text(
                      'No favourites yet.\nTap ♥ on any vendor to save it here!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: wishlistItems.length,
                    itemBuilder: (ctx, index) {
                      final service = wishlistItems[index];
                      final vendorServiceId = service['vendor_services_id']?.toString() ?? '';
                      final attributes = service['attributes'] ?? {};
                      final businessName = attributes['Name'] ?? 'Unnamed Venue';
                      final city = attributes['city'] ?? 'Unknown Location';
                      final media = attributes['Portfolio'] != null
                          ? attributes['Portfolio'].toString().split('|')
                          : [];
                      final imageUrl = media.isNotEmpty
                          ? (media[0].toString().startsWith('/uploads/')
                          ? "https://happywedzbackend.happywedz.com${media[0]}"
                          : media[0])
                          : 'https://via.placeholder.com/400x300';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorDetailsScreen(
                                  service: {
                                    'attributes': attributes,
                                    'media': media,
                                    'vendor_services_id': vendorServiceId,
                                  },
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Vendor image
                              Stack(
                                children: [
                                  // Vendor image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        height: 200,
                                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  // ❌ Cross button at top-right
                                  if (favouriteVendors.contains(vendorServiceId))
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: InkWell(
                                        onTap: () => toggleWishlist(vendorServiceId),
                                        borderRadius: BorderRadius.circular(20),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.85),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Vendor details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            businessName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            city,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Favorite button
                                    // ❌ Remove from wishlist button

                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );


                    },
                  ),
                ),
              ],
            ),
          ),
        ),

      ),
    );
  }



}
