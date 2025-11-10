import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../chat_page_new.dart';
import '../main.dart';
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

      if (token.isEmpty) {
        print("❌ No auth token found — please login");
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse('https://happywedz.com/api/wishlist');
      final response = await http.get(url, headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      print("Wishlist API Response Status: ${response.statusCode}");
      print("Wishlist API Raw Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['data'] ?? [];

        print("Decoded Wishlist Items: $items");

        setState(() {
          wishlistItems = items;
          favouriteVendors = items
              .map((e) => e['vendor_services_id'].toString())
              .toSet();
        });
      } else {
        print("❌ Failed to fetch wishlist: ${response.statusCode}");
      }
    } catch (e) {
      print("💥 Error fetching wishlist: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
            // Optionally, refetch wishlist to get the new item fully
            fetchWishlist();
          }
        });
      } else {
        print("❌ Toggle failed: ${response.statusCode}");
      }
    } catch (e) {
      print("💥 Error toggling wishlist: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
          stops: [0.0, 0.3, 0.6],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Wishlist', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : wishlistItems.isEmpty
            ? const Center(
          child: Text(
            'No favourites yet. Tap ♥ on any vendor to save it here!',
            textAlign: TextAlign.center,
          ),
        )
            : SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children:
              wishlistItems.map((service) => _buildServiceCard(service)).toList(),
            ),
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
                // ❤️ Favourite icon (top right)
                // ❤️ Favourite icon (top right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () async {
                      if (currentUserId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please sign in first")),
                        );
                        print("❌ User not logged in — currentUserId is null");
                        return;
                      }

                      final vendorServiceId = service['id']?.toString() ?? '';
                      if (vendorServiceId.isEmpty) {
                        print("❌ vendorServiceId missing in service data");
                        return;
                      }

                      // Local toggle first
                      final isFav = favouriteVendors.contains(vendorServiceId);
                      setState(() {
                        if (isFav) {
                          favouriteVendors.remove(vendorServiceId);
                        } else {
                          favouriteVendors.add(vendorServiceId);
                        }
                      });

                      // Get token from SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('auth_token');

                      if (token == null || token.isEmpty) {
                        print("❌ No auth token found — please login again");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please login again')),
                        );
                        return;
                      }

                      final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
                      final body = {
                        'user_id': currentUserId,
                        'vendor_services_id': vendorServiceId,
                      };

                      print("🛰 Sending POST request to: $url");
                      print("📦 Body: $body");
                      print("🔑 Authorization: Bearer $token");

                      try {
                        final response = await http.post(
                          url,
                          headers: {
                            'Accept': 'application/json',
                            'Authorization': 'Bearer $token', // ✅ crucial
                          },
                          body: body,
                        );

                        print("📨 Response status: ${response.statusCode}");
                        print("📨 Response body: ${response.body}");

                        if (response.statusCode == 200) {
                          final res = jsonDecode(response.body);
                          final msg = res['message'] ?? 'Wishlist updated';
                          print("✅ Success: $msg");

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
                          );
                        } else if (response.statusCode == 401) {
                          print("❌ Unauthorized (401) — invalid token or user_id");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unauthorized — please log in again')),
                          );
                        } else {
                          print("❌ Error ${response.statusCode}: ${response.body}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${response.statusCode}')),
                          );
                        }
                      } catch (e, stack) {
                        print("💥 Exception while calling wishlist API: $e");
                        print(stack);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Something went wrong')),
                        );
                      }
                    },

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
                          onPressed: () async {
                            final loggedIn = await ensureLoggedIn(context);
                            if (!loggedIn) return; // 🚫 not logged in → stopped here

                            final vendorId = service['vendor_id']?.toString() ??
                                vendor['id']?.toString() ??
                                attributes['vendor_id']?.toString() ??
                                '';

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  currentUid: currentUserId ?? '',
                                  otherUid: vendorId,
                                  otherName: businessName,
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
                          onPressed: () async {
                            final loggedIn = await ensureLoggedIn(context);
                            if (!loggedIn) return;

                            if (phone.isNotEmpty) {
                              final uri = Uri.parse("https://wa.me/$phone");
                              launchUrl(uri);
                            }
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
}
