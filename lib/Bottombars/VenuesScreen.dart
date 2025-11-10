import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Wishlist/Wishlistscreen.dart';
import '../vendor/vendordetailsscreen.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class VenuesScreen extends StatefulWidget {
  const VenuesScreen({Key? key}) : super(key: key);

  @override
  State<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends State<VenuesScreen> {
  List<Venue> venues = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int page = 1;
  final int limit = 10; // ✅ only 10 per page
  int totalPages = 1; // ✅ added for pagination
  String searchQuery = "";

  List<Venue> allVenues = []; // keep all fetched venues


  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchVenues(page: page);

    _searchController.addListener(() {
      final query = _searchController.text.trim();
      if (query != searchQuery) {
        searchQuery = query;
        _onSearchChanged();
      }
    });
  }

  Future<void> _onSearchChanged() async {
    final query = searchQuery.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        venues = List.from(allVenues); // reset
      } else {
        venues = allVenues
            .where((v) =>
        v.name.toLowerCase().contains(query) ||
            v.pax.toLowerCase().contains(query) || // ✅ maybe contains city/area info
            v.type.toLowerCase().contains(query)) // ✅ or type/category name
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      }
    });
  }


  Future<void> fetchVenues({int page = 1, String query = ""}) async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
        "https://happywedz.com/api/vendor-services?subCategory=venue&page=$page&limit=$limit&search=$query",
      );

      print("Fetching venues from: $url");

      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];

        // ✅ Safer total pages calculation — ensures buttons always show
        // ✅ Dynamic total page calculation
        final totalItems = decoded['total'];

        if (totalItems != null && totalItems is int && totalItems > 0) {
          totalPages = (totalItems / limit).ceil();
        } else {
          // If API doesn’t send total count,
          // we’ll estimate based on data length
          final fetchedCount = (decoded['data'] as List?)?.length ?? 0;
          if (fetchedCount < limit) {
            totalPages = page; // likely last page
          } else {
            totalPages = page + 1; // assume one more page
          }
        }
        print("📄 Estimated total pages: $totalPages");



        final List<Venue> loadedVenues = data.map((service) {
          final attributes = service['attributes'] ?? {};
          final vendor = service['vendor'] ?? {};
          final subcategory = service['subcategory'] ?? {};
          final media = service['media'] ?? {};

          String imageUrl = '';
          if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
            final cover = media['coverImage'].toString();
            imageUrl = cover.startsWith('/uploads/')
                ? "https://happywedzbackend.happywedz.com$cover"
                : cover;
          } else if (media['gallery'] != null && media['gallery'].isNotEmpty) {
            final gallery = media['gallery'];
            final firstImage = gallery.firstWhere(
                  (g) => g is String && g.toString().startsWith('/uploads/'),
              orElse: () => null,
            );
            if (firstImage != null) {
              imageUrl = "https://happywedzbackend.happywedz.com$firstImage";
            }
          }

          return Venue(
            id: service['id'] ?? 0,
            name: vendor['businessName'] ?? 'Unknown Venue',
            image: imageUrl.isNotEmpty
                ? imageUrl
                : 'https://via.placeholder.com/400x300.png?text=No+Image',
            price: "₹ ${attributes['veg_price'] ?? '—'} per plate",
            pax: attributes['area'] ?? 'Capacity info not available',
            type: subcategory['name'] ?? 'Venue',
            isFavourite: service['is_favourite'] == true || service['is_favourite'] == 1,
          );

        }).toList();

        setState(() {
          allVenues = loadedVenues; // save full list
          venues = loadedVenues;    // currently displayed
          isLoading = false;
          hasMore = loadedVenues.length >= limit;
        });

      } else {
        print("❌ Error fetching venues: ${response.statusCode}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("💥 API Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
              _buildAppBar(context),
              _buildSearchBar(),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.pink))
                    : venues.isEmpty
                    ? const Center(
                  child: Text(
                    "No venues found 😔",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                )
                    : RefreshIndicator(
                  color: Colors.pink,
                  onRefresh: () async => await fetchVenues(page: 1),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16.0),
                          itemCount: venues.length,
                          itemBuilder: (context, index) {
                            final venue = venues[index];
                            return _buildVenueCard(context, venue);
                          },
                        ),
                        _buildPaginationButtons(), // ✅ added here
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButtons() {
    if (totalPages <= 1) return const SizedBox();

    List<Widget> buttons = [];
    for (int i = 1; i <= totalPages; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: i == page ? Colors.pink : Colors.white,
              foregroundColor: i == page ? Colors.white : Colors.pink,
              side: const BorderSide(color: Colors.pink),
              minimumSize: const Size(40, 36),
            ),
            onPressed: () {
              setState(() => page = i);
              fetchVenues(page: i, query: searchQuery);
            },
            child: Text('$i'),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttons,
        ),
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
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search wedding venues...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
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
              'Venues',
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

  Widget _buildVenueCard(BuildContext context, Venue venue) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailsScreen(service: venue),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(venue.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: StatefulBuilder(
                    builder: (context, setInnerState) {
                      bool isFav = venue.isFavourite ?? false;

                      Future<void> toggleWishlist() async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getInt('user_id') ?? 0;

                        if (userId == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please sign in first')),
                          );
                          return;
                        }

                        try {
                          final response = await http.post(
                            Uri.parse('https://happywedz.com/api/wishlist/toggle'),
                            body: {
                              'user_id': userId.toString(),
                              'vendor_services_id': venue.id.toString(),
                            },
                          );

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            final message = data['message'] ?? '';

                            setInnerState(() {
                              isFav = message.toLowerCase().contains('added');
                              venue.isFavourite = isFav;
                            });
                          } else {
                            debugPrint('Wishlist toggle failed: ${response.statusCode}');
                          }
                        } catch (e) {
                          debugPrint('Error toggling wishlist: $e');
                        }
                      }

                      return InkWell(
                        onTap: toggleWishlist,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.pinkAccent,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.price,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.pax,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        venue.type,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
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

// ✅ Venue Model
class Venue {
  final int id;
  final String name;
  final String image;
  final String price;
  final String pax;
  final String type;
  bool isFavourite;

  Venue({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.pax,
    required this.type,
    this.isFavourite = false,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      price: json['price']?.toString() ?? '',
      pax: json['pax']?.toString() ?? '',
      type: json['type'] ?? '',
      isFavourite:
      json['is_favourite'] == 1 || json['is_favourite'] == true ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'price': price,
      'pax': pax,
      'type': type,
      'is_favourite': isFavourite,
    };
  }
}


