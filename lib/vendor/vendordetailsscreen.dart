import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:html/parser.dart' show parse;
import '../ClaimBusiness.dart';
import '../Review.dart';
import '../chat/chat_screen.dart';
import '../chat/chat_service.dart';
import '../chat_page_new.dart';
import '../main.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ⬇️ Import your other screens


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
  String? currentUserId;
  Set<String> favouriteVendors = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchServices();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }

  Future<void> fetchServices() async {
    try {
      final encodedSubcategory =
      Uri.encodeComponent(widget.subcategoryName.toLowerCase());
      final url = Uri.parse(
          "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory");
      print("🔍 Fetching services from: $url");

      final response =
      await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        List<dynamic> servicesList = [];
        if (data is List) {
          servicesList = data;
        } else if (data is Map) {
          if (data['data'] != null && data['data'] is List) {
            servicesList = data['data'];
          } else if (data['services'] != null && data['services'] is List) {
            servicesList = data['services'];
          } else {
            servicesList = [data];
          }
        }

        print("✅ Found ${servicesList.length} services");

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
            colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
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

    final String businessName = vendor['businessName'] ??
        vendor['vendor_name'] ??
        attributes['name'] ??
        attributes['vendor_name'] ??
        'Unnamed Venue';

    final String city =
        vendor['city'] ?? attributes['city'] ?? 'Unknown Location';

    final double rating = double.tryParse(
        (vendor['rating'] ?? attributes['rating'] ?? '0').toString()) ??
        0.0;

    final String phone =
        vendor['phone']?.toString() ?? attributes['Phone']?.toString() ?? '';

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

    String imageUrl = 'https://via.placeholder.com/400x300';
    final media = service['media'];
    if (media != null) {
      if (media is Map && media['coverImage'] != null) {
        imageUrl = media['coverImage'].toString();
      } else if (media is List && media.isNotEmpty) {
        final first = media[0];
        if (first is Map && first['url'] != null) {
          imageUrl = first['url'];
        } else if (first is String) {
          imageUrl = first;
        }
      }
      if (imageUrl.startsWith('/uploads/')) {
        imageUrl = "https://happywedzbackend.happywedz.com$imageUrl";
      }
    }

    final vendorServiceId = service['id']?.toString() ?? '';

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
            // 🖼 IMAGE & OVERLAYS
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image,
                          size: 50, color: Colors.white),
                    ),
                  ),
                ),
                // 📍 Location
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                // ⭐ Rating
                if (rating > 0)
                  Positioned(
                    top: 8,
                    right: 48,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star,
                              color: Colors.white, size: 12),
                        ],
                      ),
                    ),
                  ),
                // ❤️ Favourite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _toggleFavourite(vendorServiceId),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        favouriteVendors.contains(vendorServiceId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.pinkAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🧾 Details Section
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
                        color: Colors.black87),
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
                          color: Color(0xFFE91E63)),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final loggedIn = await ensureLoggedIn(context);
                            if (!loggedIn) return;

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
                            padding:
                            const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _iconButton(
                        icon: Icons.chat,
                        color: const Color(0xFF25D366),
                        onPressed: () async {
                          final loggedIn = await ensureLoggedIn(context);
                          if (!loggedIn) return;
                          if (phone.isNotEmpty) {
                            final uri = Uri.parse("https://wa.me/$phone");
                            launchUrl(uri);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _iconButton(
                        icon: Icons.phone,
                        color: Colors.green,
                        onPressed: () {
                          if (phone.isNotEmpty) {
                            final uri = Uri(scheme: 'tel', path: phone);
                            launchUrl(uri);
                          }
                        },
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

  Widget _iconButton(
      {required IconData icon,
        required Color color,
        required VoidCallback onPressed}) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _toggleFavourite(String vendorServiceId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please sign in first")),
      );
      return;
    }

    final isFav = favouriteVendors.contains(vendorServiceId);
    setState(() {
      if (isFav) {
        favouriteVendors.remove(vendorServiceId);
      } else {
        favouriteVendors.add(vendorServiceId);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    print('🟢 Current userId: $currentUserId');
    print('🔑 Token (first 20 chars): ${token.isNotEmpty ? token.substring(0, 20) : "EMPTY"}...');
    print('⭐ Vendor Service ID: $vendorServiceId');

    if (token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login again')));
      return;
    }

    final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
    final body = {
      'user_id': currentUserId.toString(),
      'vendor_services_id': vendorServiceId.toString(),
    };

    try {
      print('🌍 Sending POST → $url');
      print('📦 Headers: {Content-Type: application/json, Authorization: Bearer $token}');
      print('📦 Body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body), // ✅ match JSON structure
      );

      print('📬 Response status: ${response.statusCode}');
      print('📬 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final msg = res['message'] ?? 'Wishlist updated';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else if (response.statusCode == 401) {
        print('🚫 401 Unauthorized → Token invalid or expired.');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Session expired. Please log in again.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('❌ Exception in toggleFavourite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    }
  }



  Future<bool> ensureLoggedIn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login first')));
      return false;
    }
    return true;
  }
}









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

//   Future<void> toggleWishlist(Map<String, dynamic> service) async {
//     if (currentUserId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
//       return;
//     }
//
//     final attributes = (service['attributes'] is Map) ? Map<String, dynamic>.from(service['attributes']) : <String, dynamic>{};
//     final vendor = (service['vendor'] is Map) ? Map<String, dynamic>.from(service['vendor']) : <String, dynamic>{};
//     final media = (service['media'] is List) ? List.from(service['media']) : [];
//
//     final String vendorName = (attributes['vendor_name'] ?? attributes['Name'] ?? vendor['businessName'] ?? 'No Name').toString();
//     final String city = (attributes['city'] ?? vendor['city'] ?? '').toString();
//     final String image = media.isNotEmpty ? media[0].toString() : ''; // first image
//
// // API payload
//     final Map<String, dynamic> payload = {
//       'user_id': currentUserId,
//       'vendor_id': vendor['id'] ?? attributes['vendor_id'] ?? '',
//       'vendor_name': vendorName,
//       'city': city,
//       'hero_image': image,
//     };
//
//     try {
//       final response = await http.post(
//         Uri.parse('https://happywedz.com/api/wishlist/toggle'), // replace with your API
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(payload),
//       );
//
//       if (response.statusCode == 200) {
//         setState(() => _isShortlisted = !_isShortlisted);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(_isShortlisted ? 'Added to wishlist' : 'Removed from wishlist')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to update wishlist')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Something went wrong')),
//       );
//     }
//   }


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
    final String aboutRaw = (attributes['about_us'] ?? attributes['Aboutus'] ?? '').toString();
    final String about = aboutRaw
        .replaceAll(r'\n', '')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '')
        .trim();

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
        child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                            // toggleWishlist(widget.service); // ✅ call the new function
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
                  // Scrollable content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    child:
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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





                      const SizedBox(height: 8),

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
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Claim Your Business clicked (demo)')),
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusinessClaimForm(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.business_center_outlined, // 👈 business-related icon
                              color: Colors.pink,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Claim Your Business',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                      ),

                      const SizedBox(height: 5),



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

                      // About
                      if (_hasValue(about)) ...[
                        const Text(
                          'About',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),

                        AnimatedCrossFade(
                          firstChild: SizedBox(
                            height: 180,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Html(
                                data: about,
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    fontSize: FontSize(15),
                                    lineHeight: LineHeight(1.6),
                                    color: Colors.black87,
                                  ),
                                  "h5": Style(
                                    fontSize: FontSize(18),
                                    fontWeight: FontWeight.bold,
                                    margin: Margins.only(top: 12, bottom: 6),
                                    color: Colors.black,
                                  ),
                                  "ul": Style(
                                    padding: HtmlPaddings.only(left: 20),
                                  ),
                                  "li": Style(
                                    margin: Margins.only(bottom: 6),
                                  ),
                                },
                              ),
                            ),
                          ),
                          secondChild: Html(
                            data: about,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(15),
                                lineHeight: LineHeight(1.6),
                                color: Colors.black87,
                              ),
                              "h5": Style(
                                fontSize: FontSize(18),
                                fontWeight: FontWeight.bold,
                                margin: Margins.only(top: 12, bottom: 6),
                                color: Colors.black,
                              ),
                              "ul": Style(
                                padding: HtmlPaddings.only(left: 20),
                              ),
                              "li": Style(
                                margin: Margins.only(bottom: 6),
                              ),
                            },
                          ),
                          crossFadeState:
                          _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),

                        if ((parse(about).body?.text.length ?? 0) > 250)
                          TextButton(
                            onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded),
                            child: Text(_aboutExpanded ? 'Read less' : 'Read more'),
                          ),
                      ]




                      // Policies (only for venues)
                      ,if (isVenue && (_hasValue(decorPolicy) || _hasValue(cateringPolicy))) ...[
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

                      const SizedBox(height: 4),
                    ]),
                  ),


                  const SizedBox(height: 1),

                  // Ratings & Reviews Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Ratings & Reviews (273)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Summary",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ⭐ Rating Bars
                        Column(
                          children: [
                            _buildRatingRow(5, 0.9),
                            _buildRatingRow(4, 0.7),
                            _buildRatingRow(3, 0.4),
                            _buildRatingRow(2, 0.2),
                            _buildRatingRow(1, 0.1),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ⭐ Summary details
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "4.5 ",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            Icon(Icons.star, color: Colors.pink, size: 24),
                            SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("273 Reviews", style: TextStyle(color: Colors.black54)),
                                SizedBox(height: 4),
                                Text("88% Recommended", style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // 🩷 Write a review button (static)
                        OutlinedButton(
                          onPressed: () {
                            if (currentUserId == null || currentUserId!.isEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignInScreen()),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecommendVendorScreen(
                                  vendorId: vendorId,
                                  vendorName: vendorName,
                                  vendorImage: images.isNotEmpty ? images[0] : null,
                                  currentUserId: currentUserId,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.pink),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          child: const Text(
                            'Write a review',
                            style: TextStyle(
                              color: Colors.pink,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 40),


                ])
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: SafeArea(
          child: Row(
            children: [
              // Write a Review button
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () {
              //       if (currentUserId == null || currentUserId!.isEmpty) {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(builder: (_) => const SignInScreen()),
              //         );
              //         return;
              //       }
              //
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (_) => RecommendVendorScreen(
              //             vendorId: vendorId,                 // dynamic from vendor details
              //             vendorName: vendorName,             // dynamic vendor name
              //             vendorImage: images.isNotEmpty ? images[0] : null, // first image if exists
              //             currentUserId: currentUserId,       // optional (pass user id if your API needs)
              //           ),
              //         ),
              //       );
              //
              //     },
              //     icon: const Icon(Icons.rate_review, color: Colors.pink),
              //     label: const Text('Write a\nReview', style: TextStyle(color: Colors.pink)),
              //     style: OutlinedButton.styleFrom(
              //       side: const BorderSide(color: Colors.pink),
              //       padding: const EdgeInsets.symmetric(vertical: 14),
              //     ),
              //   ),
              //
              // ),
              const SizedBox(width: 12),

              // Message button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (currentUserId == null || currentUserId!.isEmpty) {
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
                          currentUid: currentUserId!,
                          otherUid: vendorId,
                          otherName: vendorName,
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

              // Call button
              Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  icon: const Icon(Icons.phone, color: Colors.white),
                  onPressed: () {
                    if (phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone not available')),
                      );
                      return;
                    }
                    _call(phone);
                  },
                ),
              ),
            ],

          ),
        ),
      ),


    );
    // Bottom call/message bar

  }
  Widget _buildRatingRow(int star, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(star.toString()),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.pink,
              backgroundColor: Colors.grey[300],
            ),
          ),
        ],
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



