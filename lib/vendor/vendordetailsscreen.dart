import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:imageview360/imageview360.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import '../ClaimBusiness.dart';
import '../Review.dart';
import '../ai_chat_screen/ai_chat_screen.dart';
import '../chat_page_new.dart';
import '../profile.dart';



// ⬇️ Import your other screens

// Updated VendorServicesScreen with rich UI, wishlist, list/grid toggle, search, filters
// NOTE: This is a full file. Replace your existing code with this.


// Final VendorServicesScreen — Fully integrated with pagination, grid/list toggle, search, filters,
// wishlist toggle, phone/WhatsApp/message actions, safe image handling and no overflow.


// Replace with your actual vendor details screen import

class VendorServicesScreen extends StatefulWidget {
  final String subcategoryName;

  const VendorServicesScreen({Key? key, required this.subcategoryName}) : super(key: key);

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  // Raw data storage (all fetched pages)
  final List<dynamic> allServices = [];
  // Filtered & displayed list
  List<dynamic> services = [];

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  String? currentUserId;
  Set<String> favouriteVendors = {};

  // bool isGrid = true; // Toggle List/Grid
  final ScrollController _scrollController = ScrollController();
  bool isList = true;
  // Search & Filters
  final TextEditingController searchController = TextEditingController();
  String filterCity = '';
  double filterMinPrice = 0;
  double filterMaxPrice = 100000;
  double filterMinRating = 0;
  String selectedCity = "";
  double minPrice = 0;
  double maxPrice = 200000;
  double selectedRating = 0;

  String? selectedSubCategory;
  String? selectedVendorType;




  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    // fetchServices();
    fetchAllServices();
    // setupPaginationListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }
  Future<void> fetchAllServices() async {
    setState(() {
      isLoading = true;
      allServices.clear();
      services.clear();
    });

    try {
      final sub = Uri.encodeComponent(widget.subcategoryName.toLowerCase());

      final url = Uri.parse(
          "https://happywedz.com/api/vendor-services?subCategory=$sub&limit=5000"
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final raw = data["data"];

        List<dynamic> list = [];

        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          list = [raw];
        }

        setState(() {
          allServices.addAll(list);
        });

        _applyFiltersAndSearch();
      }
    } catch (e) {
      print("Error loading ALL services: $e");
    }

    setState(() => isLoading = false);
  }

  void setupPaginationListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        fetchMoreServices();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }
  Future<void> fetchServices() async {
    setState(() => isLoading = true);

    Map<String, String> queryParams = {};

    if (selectedCity.isNotEmpty) queryParams["city"] = selectedCity;
    if (selectedSubCategory != null) queryParams["subCategory"] = selectedSubCategory!;
    if (selectedVendorType != null) queryParams["vendorType"] = selectedVendorType!;

    queryParams["minPrice"] = minPrice.toInt().toString();
    queryParams["maxPrice"] = maxPrice.toInt().toString();
    queryParams["minRating"] = selectedRating.toString();

    final uri = Uri.https(
      "happywedz.com",
      "/api/vendor-services",
      queryParams,
    );

    print("API URL → $uri");

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          vendorList = data["data"];
        });
      }
    } catch (e) {
      print("Error fetching services: $e");
    }

    setState(() => isLoading = false);
  }



  Future<void> fetchMoreServices() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    try {
      currentPage++;

      final encodedSubcategory =
      Uri.encodeComponent(widget.subcategoryName.toLowerCase());

      final url = Uri.parse(
          "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory&page=$currentPage&limit=9");

      final response = await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // final List<dynamic> list = (data['data'] ?? []) as List<dynamic>;
        final rawData = data['data'];

        List<dynamic> list = [];

        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map<String, dynamic>) {
          list = [rawData];  // wrap single object into a list
        } else {
          list = [];  // null or unexpected format
        }

        final pagination = data['pagination'] ?? {};

        totalPages = (pagination['totalPages'] ?? 1) is int
            ? pagination['totalPages']
            : int.tryParse('${pagination['totalPages']}') ?? totalPages;
        hasMore = currentPage < totalPages;

        setState(() {
          allServices.addAll(list);
        });

        _applyFiltersAndSearch();
      } else {
        print('More API error ${response.statusCode}');
      }
    } catch (e, st) {
      print('fetchMoreServices error $e');
      print(st);
    }

    setState(() => isLoadingMore = false);
  }
  Future<void> applyFilters() async {
    setState(() {
      filterCity = selectedCity;
      filterMinPrice = minPrice;
      filterMaxPrice = maxPrice;
      filterMinRating = selectedRating;
    });

    _applyFiltersAndSearch(); // 🔥 local filtering
  }




  void _applyFiltersAndSearch() {
    final q = searchController.text.trim().toLowerCase();

    final filtered = allServices.where((service) {
      final attr = service['attributes'] ?? {};
      final vendor = service['vendor'] ?? {};

      final name = (vendor['businessName'] ??
          attr['vendor_name'] ??
          attr['Name'] ??
          '')
          .toString()
          .toLowerCase();

      final city = (vendor['city'] ?? attr['city'] ?? '')
          .toString()
          .toLowerCase();

      // Price extraction
      double price = 0;
      final pText = (attr['veg_price'] ?? attr['PriceRange'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      if (pText.isNotEmpty) price = double.tryParse(pText) ?? 0.0;

      // Rating
      final rating = double.tryParse(
        (attr['rating'] ??
            attr['averageRating'] ??
            '0')
            .toString(),
      ) ??
          0;

      return
        // 🔎 SEARCH (name + city)
        (q.isEmpty || name.contains(q) || city.contains(q)) &&

            // 🏙 City Filter
            (filterCity.isEmpty || city.contains(filterCity.toLowerCase())) &&

            // 💰 Price Filter
            price >= filterMinPrice &&
            price <= filterMaxPrice &&

            // ⭐ Rating Filter
            rating >= filterMinRating;
    }).toList();

    setState(() {
      services = filtered;
    });
  }



  Future<void> _toggleFavourite(String vendorServiceId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to manage wishlist')));
      return;
    }

    final isFav = favouriteVendors.contains(vendorServiceId);
    setState(() {
      if (isFav) favouriteVendors.remove(vendorServiceId);
      else favouriteVendors.add(vendorServiceId);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
      final body = jsonEncode({
        'user_id': currentUserId.toString(),
        'vendor_services_id': vendorServiceId.toString(),
      });

      final res = await http.post(url, headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      }, body: body);

      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        final msg = m['message'] ?? 'Wishlist updated';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else if (res.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please log in again.')));
      }
    } catch (e) {
      print('wishlist api error $e');
    }
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    // ensure number is in international format if needed; here we assume API gives proper number
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openChat(String vendorId, String name) async {
    // Replace with your chat page navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorDetailsScreen(service: {'vendor': {'id': vendorId, 'businessName': name}}),
      ),
    );
  }
  Set<String> allSubCategories = {};
  Set<String> allVendorTypes = {};

  void extractFilters(List vendors) {
    for (var v in vendors) {
      if (v["subcategory"] != null) {
        allSubCategories.add(v["subcategory"]["name"]);
      }
      if (v["vendor"]?["vendorType"] != null) {
        allVendorTypes.add(v["vendor"]["vendorType"]["name"]);
      }
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Filters",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      )),

                  const SizedBox(height: 20),

                  /// ⭐ CITY FILTER
                  const Text("City", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Enter City",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (value) {
                      setStateSheet(() => selectedCity = value.trim());
                    },
                  ),

                  const SizedBox(height: 20),

                  /// ⭐ PRICE FILTER
                  const Text("Price Range",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  RangeSlider(
                    values: RangeValues(minPrice, maxPrice),
                    min: 0,
                    max: 200000,
                    divisions: 50,
                    labels: RangeLabels(
                      "₹${minPrice.toInt()}",
                      "₹${maxPrice.toInt()}",
                    ),
                    onChanged: (values) {
                      setStateSheet(() {
                        minPrice = values.start;
                        maxPrice = values.end;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  /// ⭐ RATING FILTER
                  const Text("Rating",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: selectedRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: selectedRating.toString(),
                    onChanged: (value) {
                      setStateSheet(() => selectedRating = value);
                    },
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      /// RESET BUTTON
                      TextButton(
                        child: const Text("Reset"),
                        onPressed: () {
                          setState(() {
                            selectedCity = "";
                            minPrice = 0;
                            maxPrice = 200000;
                            selectedRating = 0;
                          });
                          Navigator.pop(context);
                          fetchServices();
                        },
                      ),

                      /// APPLY BUTTON
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Apply",
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          Navigator.pop(context);
                          applyFilters();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.subcategoryName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: Icon(isList ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => isList = !isList),
          )
        ],
      ),
    );
  }
  List<dynamic> vendorList = [];

  Future<void> fetchVendors(String query) async {
    final url = Uri.parse(
      "https://happywedz.com/api/vendor-services?search=$query",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        vendorList = data['data']; // Adjust based on API response
      });
    } else {
      print("Error fetching vendors: ${response.statusCode}");
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search vendors, city, name...',
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => _applyFiltersAndSearch(),
                    ),
                  ),

                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
    IconButton(
    padding: EdgeInsets.zero,
    onPressed: () {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AiChatScreen()),
    );
    },
    icon: Container(
    height: 40,       // Adjust size
    width: 40,
    decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.pink,       // 🌸 Pink Circle Background
    ),
    child: Image.asset(
    'assets/shadiai-unscreen.gif',
    fit: BoxFit.contain,
    ),
    ),
    ),


    ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: services.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == services.length) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ));
        }
        return _buildServiceCard(services[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: services.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == services.length) return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
        return _buildServiceCard(services[index]);
      },
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final attributes = service['attributes'] ?? {};
    final vendor = service['vendor'] ?? {};

    final String vendorServiceId = (service['id'] ?? '').toString();
    final String businessName = (vendor['businessName'] ?? attributes['vendor_name'] ?? attributes['Name'] ?? '').toString();
    final String city = (vendor['city'] ?? attributes['city'] ?? attributes['address'] ?? '').toString();
    final String phone = (vendor['phone'] ?? attributes['Phone'] ?? '').toString();

    // rating
    final double rating = double.tryParse((attributes['rating'] ?? attributes['averageRating'] ?? '0').toString().replaceAll(',', '')) ?? 0.0;

    // price parsing
    String vegRaw = (attributes['veg_price'] ?? attributes['PriceRange'] ?? attributes['vegPrice'] ?? '').toString();
    vegRaw = vegRaw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    final priceValue = double.tryParse(vegRaw) ?? 0.0;

    String priceText = priceValue > 0 ? '₹${priceValue.toInt()} / Day' : '-';

    // media handling: API sometimes returns null media; try attributes.Portfolio or media list
    String imageUrl = '';
    final media = service['media'];
    if (media != null) {
      if (media is List && media.isNotEmpty) {
        final first = media[0];
        imageUrl = first is String ? first : (first['url'] ?? '').toString();
      } else if (media is String && media.isNotEmpty) {
        imageUrl = media;
      } else if (media is Map && media['coverImage'] != null) {
        imageUrl = media['coverImage'].toString();
      }
    }

    // fallback to attributes.Portfolio or happywedz_url
    if (imageUrl.isEmpty) {
      final portfolio = attributes['Portfolio'] ?? attributes['portfolio_urls'] ?? attributes['portfolio'] ?? '';
      if (portfolio is String && portfolio.isNotEmpty) {
        // portfolio might be pipe separated; take first
        imageUrl = portfolio.split('|').first;
      }
    }

    if (imageUrl.isEmpty) imageUrl = 'https://via.placeholder.com/600x400?text=No+Image';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(service: service))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with wishlist & rating overlay
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavourite(vendorServiceId),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Icon(
                          favouriteVendors.contains(vendorServiceId) ? Icons.favorite : Icons.favorite_border,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 140,
                            child: Text(city, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                          )
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 6),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(businessName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(child: Text(city, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(priceText, style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(onTap: () => _launchPhone(phone), child: _smallAction(Icon(Icons.call, color: Colors.green), 'Call')),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _launchWhatsApp(phone),
                            child: _smallAction(
                              Image.asset(
                                'assets/whatsapp.png',
                                height: 30,
                                width: 30,
                              ),
                              'WhatsApp',
                            ),
                          ),

                          const SizedBox(width: 8),
                          GestureDetector(onTap: () => _openChat(vendor['id']?.toString() ?? '', businessName), child: _smallAction(Icon(Icons.message, color: Colors.blue), 'Message')),
                        ],
                      ),
                      // ElevatedButton(
                      //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(service: service))),
                      //   style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                      //   child: const Text('View'),
                      // )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _smallAction(Widget icon, String label) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: Colors.grey.shade100, child: icon),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            const SizedBox(height: 8),
            _buildSearchBar(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Text('${services.length} results', style: const TextStyle(color: Colors.black54)),
                  TextButton.icon(onPressed: _openFilterSheet, icon: const Icon(Icons.filter_list), label: const Text('Filters'))
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: Colors.pink,
                onRefresh: () async {
                  await fetchServices();
                },
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : services.isEmpty
                    ? ListView( // Required because RefreshIndicator needs scrollable widget
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('No services found')),
                  ],
                )
                    : isList
                    ? _buildListView()
                    : _buildGridView(),

              ),
            ),

            // Expanded(
            //   child: isLoading
            //       ? const Center(child: CircularProgressIndicator())
            //       : services.isEmpty
            //       ? const Center(child: Text('No services found'))
            //       : isList
            //       ? _buildGridView()
            //       : _buildListView(),
            // )
          ],
        ),
      ),
    );
  }
}

// class VendorServicesScreen extends StatefulWidget {
//   final String subcategoryName;
//
//   const VendorServicesScreen({Key? key, required this.subcategoryName})
//       : super(key: key);
//
//   @override
//   State<VendorServicesScreen> createState() => _VendorServicesScreenState();
// }
//
// class _VendorServicesScreenState extends State<VendorServicesScreen> {
//   List<dynamic> services = [];
//   bool isLoading = true;
//   String? currentUserId;
//   Set<String> favouriteVendors = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentUser();
//     fetchServices();
//   }
//
//   Future<void> _loadCurrentUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       currentUserId = prefs.getInt('user_id')?.toString();
//     });
//   }
//
//   Future<void> fetchServices() async {
//     try {
//       final encodedSubcategory =
//       Uri.encodeComponent(widget.subcategoryName.toLowerCase());
//       final url = Uri.parse(
//           "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory");
//       print("🔍 Fetching services from: $url");
//
//       final response =
//       await http.get(url, headers: {"Accept": "application/json"});
//
//       if (response.statusCode == 200) {
//         final dynamic data = json.decode(response.body);
//
//         List<dynamic> servicesList = [];
//         if (data is List) {
//           servicesList = data;
//         } else if (data is Map) {
//           if (data['data'] != null && data['data'] is List) {
//             servicesList = data['data'];
//           } else if (data['services'] != null && data['services'] is List) {
//             servicesList = data['services'];
//           } else {
//             servicesList = [data];
//           }
//         }
//
//         print("✅ Found ${servicesList.length} services");
//
//         setState(() {
//           services = servicesList;
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//         print("❌ Error fetching services: ${response.statusCode}");
//       }
//     } catch (e, stackTrace) {
//       setState(() => isLoading = false);
//       print("💥 API Error: $e");
//       print("Stack trace: $stackTrace");
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
//             colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
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
//                     children: services
//                         .map((service) => _buildServiceCard(service))
//                         .toList(),
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
//
//     final String businessName = vendor['businessName'] ??
//         vendor['vendor_name'] ??
//         attributes['name'] ??
//         attributes['vendor_name'] ??
//         'Unnamed Venue';
//
//     final String city =
//         vendor['city'] ?? attributes['city'] ?? 'Unknown Location';
//
//     final double rating = double.tryParse(
//         (vendor['rating'] ?? attributes['rating'] ?? '0').toString()) ??
//         0.0;
//
//     final String phone =
//         vendor['phone']?.toString() ?? attributes['Phone']?.toString() ?? '';
//
//     String priceText = '';
//     final vegPrice = attributes['veg_price']?.toString() ?? '';
//     final startingPrice = attributes['starting_price']?.toString() ?? '';
//     final photoPackagePrice = attributes['photo_package_price']?.toString() ??
//         attributes['PhotoPackage_Price']?.toString() ??
//         '';
//
//     if (vegPrice.isNotEmpty) {
//       priceText = '₹$vegPrice per plate';
//     } else if (startingPrice.isNotEmpty) {
//       priceText = '₹$startingPrice onwards';
//     } else if (photoPackagePrice.isNotEmpty) {
//       priceText = photoPackagePrice;
//     }
//
//     String imageUrl = 'https://via.placeholder.com/400x300';
//     final media = service['media'];
//     if (media != null) {
//       if (media is Map && media['coverImage'] != null) {
//         imageUrl = media['coverImage'].toString();
//       } else if (media is List && media.isNotEmpty) {
//         final first = media[0];
//         if (first is Map && first['url'] != null) {
//           imageUrl = first['url'];
//         } else if (first is String) {
//           imageUrl = first;
//         }
//       }
//       if (imageUrl.startsWith('/uploads/')) {
//         imageUrl = "https://happywedzbackend.happywedz.com$imageUrl";
//       }
//     }
//
//     final vendorServiceId = service['id']?.toString() ?? '';
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
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🖼 IMAGE & OVERLAYS
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(8), topRight: Radius.circular(8)),
//                   child: Image.network(
//                     imageUrl,
//                     height: 200,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       height: 200,
//                       color: Colors.grey[300],
//                       child: const Icon(Icons.image,
//                           size: 50, color: Colors.white),
//                     ),
//                   ),
//                 ),
//                 // 📍 Location
//                 Positioned(
//                   bottom: 8,
//                   left: 8,
//                   child: Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.location_on,
//                             color: Colors.white, size: 12),
//                         const SizedBox(width: 4),
//                         Text(
//                           city,
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 11,
//                               fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // ⭐ Rating
//                 if (rating > 0)
//                   Positioned(
//                     top: 8,
//                     right: 48,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             rating.toStringAsFixed(1),
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(width: 2),
//                           const Icon(Icons.star,
//                               color: Colors.white, size: 12),
//                         ],
//                       ),
//                     ),
//                   ),
//                 // ❤️ Favourite Button
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: InkWell(
//                     onTap: () => _toggleFavourite(vendorServiceId),
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.85),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         favouriteVendors.contains(vendorServiceId)
//                             ? Icons.favorite
//                             : Icons.favorite_border,
//                         color: Colors.pinkAccent,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // 🧾 Details Section
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     businessName,
//                     style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black87),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   if (priceText.isNotEmpty)
//                     Text(
//                       priceText,
//                       style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFFE91E63)),
//                     ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () async {
//                             final loggedIn = await ensureLoggedIn(context);
//                             if (!loggedIn) return;
//
//                             final vendorId = service['vendor_id']?.toString() ??
//                                 vendor['id']?.toString() ??
//                                 attributes['vendor_id']?.toString() ??
//                                 '';
//
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => ChatPage(
//                                   currentUid: currentUserId ?? '',
//                                   otherUid: vendorId,
//                                   otherName: businessName,
//                                 ),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.message, size: 16),
//                           label: const Text('Message'),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: const Color(0xFFE91E63),
//                             side: const BorderSide(color: Color(0xFFE91E63)),
//                             padding:
//                             const EdgeInsets.symmetric(vertical: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       _iconButton(
//                         icon: Icons.chat,
//                         color: const Color(0xFF25D366),
//                         onPressed: () async {
//                           final loggedIn = await ensureLoggedIn(context);
//                           if (!loggedIn) return;
//                           if (phone.isNotEmpty) {
//                             final uri = Uri.parse("https://wa.me/$phone");
//                             launchUrl(uri);
//                           }
//                         },
//                       ),
//                       const SizedBox(width: 8),
//                       _iconButton(
//                         icon: Icons.phone,
//                         color: Colors.green,
//                         onPressed: () {
//                           if (phone.isNotEmpty) {
//                             final uri = Uri(scheme: 'tel', path: phone);
//                             launchUrl(uri);
//                           }
//                         },
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
//
//   Widget _iconButton(
//       {required IconData icon,
//         required Color color,
//         required VoidCallback onPressed}) {
//     return Container(
//       height: 40,
//       width: 40,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white, size: 18),
//         onPressed: onPressed,
//         padding: EdgeInsets.zero,
//       ),
//     );
//   }
//
//   Future<void> _toggleFavourite(String vendorServiceId) async {
//     if (currentUserId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please sign in first")),
//       );
//       return;
//     }
//
//     final isFav = favouriteVendors.contains(vendorServiceId);
//     setState(() {
//       if (isFav) {
//         favouriteVendors.remove(vendorServiceId);
//       } else {
//         favouriteVendors.add(vendorServiceId);
//       }
//     });
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token') ?? '';
//
//     print('🟢 Current userId: $currentUserId');
//     print('🔑 Token (first 20 chars): ${token.isNotEmpty ? token.substring(0, 20) : "EMPTY"}...');
//     print('⭐ Vendor Service ID: $vendorServiceId');
//
//     if (token.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Please login again')));
//       return;
//     }
//
//     final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
//     final body = {
//       'user_id': currentUserId.toString(),
//       'vendor_services_id': vendorServiceId.toString(),
//     };
//
//     try {
//       print('🌍 Sending POST → $url');
//       print('📦 Headers: {Content-Type: application/json, Authorization: Bearer $token}');
//       print('📦 Body: $body');
//
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body), // ✅ match JSON structure
//       );
//
//       print('📬 Response status: ${response.statusCode}');
//       print('📬 Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final res = jsonDecode(response.body);
//         final msg = res['message'] ?? 'Wishlist updated';
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//       } else if (response.statusCode == 401) {
//         print('🚫 401 Unauthorized → Token invalid or expired.');
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Session expired. Please log in again.')));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${response.statusCode}')),
//         );
//       }
//     } catch (e) {
//       print('❌ Exception in toggleFavourite: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Something went wrong')),
//       );
//     }
//   }
//
//   Future<bool> ensureLoggedIn(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//     if (token == null || token.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Please login first')));
//       return false;
//     }
//     return true;
//   }
// }






// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Put this file in your lib/ folder and import where needed.
// Make sure pubspec.yaml includes:
//  http, shared_preferences, carousel_slider, flutter_html, url_launcher, share_plus
// And add an asset for whatsapp at assets/icons/whatsapp.png (optional)


class VendorDetailsScreen extends StatefulWidget {
  final dynamic service;
  const VendorDetailsScreen({Key? key, required this.service}) : super(key: key);

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen>
    with SingleTickerProviderStateMixin {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentCarouselIndex = 0;
  bool _aboutExpanded = false;
  DateTime? _selectedDate;
  bool _isShortlisted = false;
  String? currentUserId;

  // Reviews
  bool isReviewsLoading = false;
  bool reviewsError = false;
  double apiAverageRating = 0.0;
  int apiTotalReviews = 0;
  List<Map<String, dynamic>> reviews = [];
  bool isProfileCompleted = false;


  bool isClaimLoading = true;
  bool hasClaim = false;
  bool canSubmit = true;
  String claimStatus = "";
  String? rejectionReason;
  int? claimId;


  @override
  void initState() {
    super.initState();
    loadFavouritesFromLocal();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchReviewsFromApi();
    });
    checkClaimStatus();
  }
  Future<void> checkClaimStatus() async {
    final url = Uri.parse(
        "https://happywedz.com/api/business/claims/check-status?"
            "vendor_id=${widget.service['id']}&vendor_subcategory_data_id=${widget.service['vendor_subcategory_id']}"
    );

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          hasClaim = data["hasClaim"];
          canSubmit = data["canSubmit"];
          claimStatus = data["claimStatus"] ?? "";
          claimId = data["claimId"];
          rejectionReason = data["rejectionReason"];
          isClaimLoading = false;
        });
      } else {
        setState(() => isClaimLoading = false);
      }
    } catch (e) {
      print("STATUS ERROR: $e");
      setState(() => isClaimLoading = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }

  // ---------------------------
  // Helper parsers (kept from your code)
  // ---------------------------
  String normalizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    if (url.startsWith('//')) {
      return 'https:$url';
    }

    if (url.startsWith('/uploads/')) {
      return "https://happywedzbackend.happywedz.com$url";
    }

    return url;
  }

  List<String> extractImages(dynamic media, dynamic vendor) {
    final Set<String> images = {};

    void add(String? url) {
      if (url == null || url.trim().isEmpty) return;
      final u = normalizeUrl(url);
      if (u.startsWith('http')) {
        images.add(u);
      }
    }

    // media as List
    if (media is List) {
      for (final item in media) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          add(item['original_url']);
          add(item['url']);
          add(item['thumb']);
        }
      }
    }

    // media as Map
    if (media is Map) {
      add(media['original_url']);
      add(media['url']);
      add(media['coverImage']);
    }

    // fallback to vendor profile image
    if (images.isEmpty && vendor is Map) {
      add(vendor['profileImage']);
    }

    // final fallback
    if (images.isEmpty) {
      images.add(
        'https://via.placeholder.com/1200x700?text=No+Image',
      );
    }

    return images.toList();
  }

  List<Map<String, String>> parseArea(String areaRaw) {
    final parts = <String>[];
    if (areaRaw == null) return [];
    if (areaRaw.trim().isEmpty) return [];
    for (var p in areaRaw.split(RegExp(r',\s*'))) {
      final cleaned = p.trim();
      if (cleaned.isNotEmpty) parts.add(cleaned);
    }
    final List<Map<String, String>> out = [];
    for (var p in parts) {
      final seatingMatch =
      RegExp(r'(\d+)\s*Seating', caseSensitive: false).firstMatch(p);
      final floatMatch =
      RegExp(r'(\d+)\s*Floating', caseSensitive: false).firstMatch(p);
      final titleCandidate =
          RegExp(r'^[A-Za-z0-9\s\-&():]+').stringMatch(p) ?? p;
      out.add({
        'title': titleCandidate.trim(),
        'seating': seatingMatch?.group(1) ?? '',
        'floating': floatMatch?.group(1) ?? '',
        'raw': p,
      });
    }
    return out;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is num) return value > 0;
    return true;
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Phone not available')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cannot make a call')));
    }
  }

  Future<void> _launchWhatsApp(String phone, {String? text}) async {
    if (phone.isEmpty || phone == '0000000000') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('WhatsApp not available')));
      return;
    }
    final encoded = Uri.encodeComponent(text ?? "Hi, I'm interested in your services.");
    final url = Uri.parse("https://wa.me/$phone?text=$encoded");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cannot open WhatsApp')));
    }
  }

  // ---------------------------
  // Reviews API fetch
  // ---------------------------
  Future<void> fetchReviewsFromApi({int page = 1, int limit = 20}) async {
    // Try to determine vendorId from service passed in
    final service = widget.service ?? {};
    final vendorMap = (service['vendor'] is Map) ? Map<String, dynamic>.from(service['vendor']) : <String, dynamic>{};
    final attributes = (service['attributes'] is Map) ? Map<String, dynamic>.from(service['attributes']) : <String, dynamic>{};
    final String vendorId = (vendorMap['id'] ?? attributes['vendor_id'] ?? '').toString();

    if (vendorId.isEmpty) {
      setState(() {
        reviewsError = true;
        isReviewsLoading = false;
      });
      return;
    }

    setState(() {
      isReviewsLoading = true;
      reviewsError = false;
    });

    try {
      // <-- Adjust endpoint if your backend uses a different path/params -->
      final url = Uri.parse(
          "https://happywedz.com/api/vendor-reviews?vendorId=$vendorId&page=$page&limit=$limit");
      final res = await http.get(url, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(res.body);

        // Expecting structure: { data: [reviews...], meta: { avgRating, totalReviews } }
        final List<dynamic> list = jsonData['data'] ?? jsonData['reviews'] ?? [];
        final meta = jsonData['meta'] ?? jsonData['pagination'] ?? jsonData['summary'] ?? {};

        final parsed = list.map<Map<String, dynamic>>((item) {
          // normalize common fields if backend varies
          return {
            'id': item['id'] ?? item['review_id'] ?? '',
            'rating': (item['rating'] ?? item['rate'] ?? 0).toString(),
            'title': item['title'] ?? '',
            'comment': item['comment'] ?? item['review'] ?? item['description'] ?? '',
            'userName': item['userName'] ?? item['user_name'] ?? item['user'] ?? 'Guest',
            'createdAt': item['createdAt'] ?? item['created_at'] ?? item['date'] ?? '',
          };
        }).toList();

        setState(() {
          reviews = parsed;
          apiAverageRating =
              double.tryParse((meta['avgRating'] ?? meta['averageRating'] ?? meta['average_rating'] ?? '0').toString()) ?? 0.0;
          apiTotalReviews = int.tryParse((meta['totalReviews'] ?? meta['total_reviews'] ?? meta['count'] ?? parsed.length).toString()) ?? parsed.length;
          isReviewsLoading = false;
          reviewsError = false;
        });
      } else {
        setState(() {
          reviewsError = true;
          isReviewsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        reviewsError = true;
        isReviewsLoading = false;
      });
      debugPrint("Reviews API error: $e");
    }
  }
  Widget claimButton(String vendorId, String vendorSubcategoryId) {
    if (isClaimLoading) {
      return ElevatedButton(
        onPressed: () {},
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // APPROVED
    if (claimStatus == "approved") {
      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Business Claim Approved"),
              content: Text("Your claim is approved. You cannot submit again."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"))
              ],
            ),
          );
        },
        icon: Icon(Icons.check_circle, color: Colors.white),
        label: Text("Approved",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // PENDING
    if (claimStatus == "pending") {
      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Pending Review"),
              content: Text("Your claim is under review."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"))
              ],
            ),
          );
        },
        icon: Icon(Icons.hourglass_top, color: Colors.white),
        label: Text("Pending",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // REJECTED
    if (claimStatus == "rejected") {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessClaimForm(
                vendorId: vendorId,
                vendorSubcategoryId: vendorSubcategoryId,
              ),
            ),
          );
        },
        icon: Icon(Icons.cancel, color: Colors.white),
        label: Text("Rejected – Resubmit",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // DEFAULT — SHOW CLAIM FORM BUTTON
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessClaimForm(
              vendorId: vendorId,
              vendorSubcategoryId: vendorSubcategoryId,
            ),
          ),
        );
      },
      icon: Icon(Icons.business_center_outlined, color: Colors.white),
      label: Text("Claim Your Business",style: TextStyle(color: Colors.white),),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  // ---------------------------
  // Wishlist toggle (placeholder — wire to your backend)
  // ---------------------------
  // Future<void> toggleWishlist() async {
  //   setState(() => _isShortlisted = !_isShortlisted);
  //   // TODO: call your API to persist wishlist state
  //   // Example:
  //   // await http.post(Uri.parse('https://your.api/wishlist'), body: {...});
  // }
  Set<String> favouriteVendors = {};
  Future<void> saveFavouritesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("favourite_vendors", favouriteVendors.toList());
  }

  Future<void> loadFavouritesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList("favourite_vendors") ?? [];
    setState(() {
      favouriteVendors = savedList.toSet();
    });
  }

  Future<void> toggleWishlist(String vendorServiceId) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to manage wishlist')),
      );
      return;
    }

    final isFav = favouriteVendors.contains(vendorServiceId);

    setState(() {
      if (isFav)
        favouriteVendors.remove(vendorServiceId);
      else
        favouriteVendors.add(vendorServiceId);
    });

    // SAVE LOCALLY
    saveFavouritesToLocal();

    // Optional: Call API
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
      final body = jsonEncode({
        'user_id': currentUserId.toString(),
        'vendor_services_id': vendorServiceId,
      });

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
    } catch (e) {
      print("Wishlist API error: $e");
    }
  }



  void open360Viewer(
      BuildContext context,
      List<ImageProvider> images,
      ) {
    if (images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('360° view not available')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) {
        bool autoRotate = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    // ✅ 360 VIEW
                    Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: ImageView360(
                          key: UniqueKey(),
                          imageList: images,
                          autoRotate: autoRotate,
                          rotationCount: images.length,
                          swipeSensitivity: 2,
                          allowSwipeToRotate: true,
                        ),
                      ),
                    ),

                    // ✅ CLOSE
                    Positioned(
                      top: 12,
                      left: 12,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // ✅ PLAY / PAUSE
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              autoRotate
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 44,
                            ),
                            onPressed: () {
                              setState(() => autoRotate = !autoRotate);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }



  Future<void> showProfilePopup() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Complete Your Profile"),
        content: const Text(
          "To continue chatting, please complete your profile details.",
        ),
        actions: [
          TextButton(
            child: const Text("Go to Profile"),
            onPressed: () async {
              Navigator.pop(context);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsScreen(),
                ),
              );

              // initChat(); // re-check after profile update

            },
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final service = widget.service ?? <String, dynamic>{};
    final String vendorServiceId = service['id'].toString();

    final attributes = (service['attributes'] is Map) ? Map<String, dynamic>.from(service['attributes']) : <String, dynamic>{};
    final vendor = (service['vendor'] is Map) ? Map<String, dynamic>.from(service['vendor']) : <String, dynamic>{};
    // final media = (service['media'] is List) ? List.from(service['media']) : [];
    //
    // // Build images list
    // final List<String> images = [];
    // for (var item in media) {
    //   if (item is String && item.isNotEmpty) {
    //     images.add(normalizeUrl(item));
    //   } else if (item is Map && item['url'] != null) {
    //     images.add(normalizeUrl(item['url'].toString()));
    //   }
    // }
    // if (images.isEmpty) images.add('https://via.placeholder.com/1200x700?text=No+Image');
    final List<String> images = extractImages(service['media'], vendor);
    print("IMAGES COUNT: ${images.length}");
    images.forEach(print);

    final String vendorId = (service['id'] ?? attributes['vendor_id'] ?? '').toString();
    final String vendorSubcategoryId = (service['vendor_subcategory_id'] ?? attributes['vendor_subcategory_id'] ?? '').toString();
    final String vendorName = (attributes['vendor_name'] ?? attributes['Name'] ?? vendor['businessName'] ?? 'No Name').toString();
    final String city = (attributes['city'] ?? vendor['city'] ?? '').toString();
    final String address = (attributes['address'] ?? attributes['Address'] ?? '').toString();
    final String aboutRaw = (attributes['about_us'] ?? attributes['Aboutus'] ?? '').toString();
    final String about = aboutRaw.replaceAll(r'\n', '').replaceAll(r'\"', '"').replaceAll(r'\\', '').trim();
    final String phone = (vendor['phone'] ?? attributes['Phone'] ?? '').toString();

    print("Vendor ID: $vendorId");
    print("Vendor Subcategory ID: $vendorSubcategoryId");
    final double rating =
        double.tryParse((vendor['rating'] ?? attributes['rating'] ?? apiAverageRating ?? '0').toString()) ?? apiAverageRating;
    final int reviewCount = int.tryParse((vendor['review_count'] ?? attributes['review_count'] ?? apiTotalReviews ?? '0').toString()) ?? apiTotalReviews;
    final String vendorType = (vendor['vendorType']?['name'] ?? attributes['vendor_type'] ?? '').toString();

    final String vegPrice = (attributes['veg_price'] ?? '').toString();
    final String nonVegPrice = (attributes['non_veg_price'] ?? '').toString();

    final seatingList = parseArea((attributes['area'] ?? ''));

    // Visual theme colors
    final primaryAccent = Colors.pink.shade600;

    // // Parse lat & lng carefully (they might be num or String)
    // dynamic latRaw = attributes['latitude'] ?? attributes['lat'] ?? attributes['Latitude'] ?? attributes['LATITUDE'];
    // dynamic lngRaw = attributes['longitude'] ?? attributes['lng'] ?? attributes['lon'] ?? attributes['Longitude'] ?? attributes['LONGITUDE'];
    //
    // double? latitude;
    // double? longitude;
    //
    // if (latRaw != null) {
    //   if (latRaw is num) latitude = latRaw.toDouble();
    //   else if (latRaw is String) latitude = double.tryParse(latRaw);
    // }
    //
    // if (lngRaw != null) {
    //   if (lngRaw is num) longitude = lngRaw.toDouble();
    //   else if (lngRaw is String) longitude = double.tryParse(lngRaw);
    // }
    double? latitude;
    double? longitude;

// 1️⃣ From attributes
    dynamic latRaw = attributes['latitude'] ??
        attributes['lat'] ??
        attributes['Latitude'] ??
        attributes['LATITUDE'];

    dynamic lngRaw = attributes['longitude'] ??
        attributes['lng'] ??
        attributes['lon'] ??
        attributes['Longitude'] ??
        attributes['LONGITUDE'];

// 2️⃣ From vendor
    latRaw ??= vendor['latitude'] ?? vendor['lat'];
    lngRaw ??= vendor['longitude'] ?? vendor['lng'];

// 3️⃣ From service root
    latRaw ??= service['latitude'] ?? service['lat'];
    lngRaw ??= service['longitude'] ?? service['lng'];

// 4️⃣ From attributes.location
    if (latRaw == null || lngRaw == null) {
      final location = attributes['location'] ?? vendor['location'];
      if (location is Map) {
        latRaw ??= location['latitude'];
        lngRaw ??= location['longitude'];
      }
    }

// 5️⃣ From lat_lng string
    if (latRaw == null || lngRaw == null) {
      final latLng =
          attributes['lat_lng'] ??
              vendor['lat_lng'] ??
              service['lat_lng'];
      if (latLng is String && latLng.contains(',')) {
        final parts = latLng.split(',');
        latRaw ??= parts[0];
        lngRaw ??= parts[1];
      }
    }

// ✅ Parse safely
    if (latRaw is num) latitude = latRaw.toDouble();
    if (lngRaw is num) longitude = lngRaw.toDouble();

    if (latRaw is String) latitude ??= double.tryParse(latRaw.trim());
    if (lngRaw is String) longitude ??= double.tryParse(lngRaw.trim());

    print("✅ FINAL LAT LNG => $latitude , $longitude");

    Future<void> openMap(double lat, double lng) async {
      final Uri geoUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");

      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        // fallback to browser
        final webUrl = Uri.parse("https://maps.google.com/?q=$lat,$lng");
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
    final String? panoramaImage = attributes['panorama_image'] as String?;
    final bool hasPanorama = panoramaImage != null && panoramaImage.isNotEmpty;



    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar overlay on carousel
                    Stack(
                      children: [
                        // Carousel
                        CarouselSlider.builder(
                          carouselController: _controller,
                          itemCount: images.length,
                          itemBuilder: (context, index, real) {
                            final img = images[index];
                            return ClipRRect(
                              borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18)),
                              child: Image.network(
                                img,
                                width: double.infinity,
                                height: 300,
                                fit: BoxFit.cover,
                                loadingBuilder: (ctx, child, prog) {
                                  if (prog == null) return child;
                                  return Container(
                                    height: 300,
                                    color: Colors.grey.shade200,
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (ctx, e, st) {
                                  return Container(
                                    height: 300,
                                    color: Colors.grey.shade300,
                                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                                  );
                                },
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1,
                            autoPlay: images.length > 1,
                            onPageChanged: (i, r) => setState(() => _currentCarouselIndex = i),
                          ),
                        ),
                        // Positioned(
                        //   right: 16,
                        //   bottom: 20,
                        //   child: ElevatedButton.icon(
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.black.withOpacity(0.7),
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        //     ),
                        //     icon: const Icon(Icons.threed_rotation, color: Colors.white),
                        //     label: const Text("360° View", style: TextStyle(color: Colors.white)),
                        //     onPressed: () {
                        //       final List<ImageProvider> providers =
                        //       images.map((e) => NetworkImage(e)).toList();
                        //
                        //       open360Viewer(context, providers);
                        //     },
                        //
                        //
                        //   ),
                        // ),

                        // Top controls
                        Positioned(
                          top: 8,
                          left: 6,
                          right: 6,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.45),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const Spacer(),
                              // Share
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black.withOpacity(0.45),
                                child: IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                                  onPressed: () {
                                    final shareLink = attributes['URL']?.toString() ?? attributes['url']?.toString() ?? '';
                                    if (shareLink.isNotEmpty) {
                                      Share.share(shareLink);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No link to share')));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // WhatsApp icon (asset fallback to Icon)
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green.shade600,
                                child: IconButton(
                                  icon: Image.asset(
                                    'assets/icons/whatsapp.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (ctx, e, st) => const Icon(Icons.sms, color: Colors.white),
                                  ),
                                  onPressed: () => _launchWhatsApp(phone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Wishlist toggle
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.85),
                                child: IconButton(
                                  icon: Icon(
                                    favouriteVendors.contains(vendorServiceId)
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: primaryAccent,
                                  ),
                                  onPressed: () => toggleWishlist(vendorServiceId),
                                ),

                              ),
                            ],
                          ),
                        ),

                        // bottom-left overlay info
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendorName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.white.withOpacity(0.85), size: 14),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 180,
                                          child: Text(
                                            city,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.orange.shade700, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        rating > 0 ? rating.toStringAsFixed(1) : (apiAverageRating > 0 ? apiAverageRating.toStringAsFixed(1) : '—'),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // dots indicator
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
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: active ? 26 : 8,
                                decoration: BoxDecoration(
                                  color: active ? Colors.black87 : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    // Main content card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // name + actions row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vendorName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text('$city ${address.isNotEmpty ? "· $address" : ""}', style: TextStyle(color: Colors.grey.shade700))),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  // Price preview
                                  if (_hasValue(vegPrice) || _hasValue(nonVegPrice))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6)],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(_hasValue(vegPrice) ? '₹$vegPrice' : _hasValue(nonVegPrice) ? '₹$nonVegPrice' : '--',
                                              style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          const Text('Per plate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // chips / quick info
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip(vendorType, Icons.business),
                              if (_hasValue(vegPrice)) _infoChip('₹$vegPrice / plate', Icons.restaurant),
                              if (_hasValue(nonVegPrice)) _infoChip('Non-veg ₹$nonVegPrice', Icons.fastfood),
                              if (seatingList.isNotEmpty) _infoChip('${seatingList.length} spaces', Icons.people),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Claim / contact actions
                          Row(
                            children: [
                              Expanded(child: claimButton(vendorId, vendorSubcategoryId)),

                              // Expanded(
                              //   child:
                              //   ElevatedButton.icon(
                              //
                              //     onPressed: () {
                              //       // claim
                              //       Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //           builder: (_) => BusinessClaimForm(
                              //             vendorId: vendorId,
                              //             vendorSubcategoryId: vendorSubcategoryId,
                              //
                              //           ),
                              //         ),
                              //       );
                              //
                              //     },
                              //     icon: const Icon(Icons.business_center_outlined,color: Colors.white,),
                              //     label: const Text('Claim Your Business',style: TextStyle(color: Colors.white),),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: primaryAccent,
                              //       padding: const EdgeInsets.symmetric(vertical: 12),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  tooltip: 'View on map',
                  icon: const Icon(Icons.location_on_sharp),
                    onPressed: () async {
                      if (latitude != null && longitude != null) {
                        await openMap(latitude!, longitude!);
                      } else if (address.isNotEmpty || city.isNotEmpty) {
                        final query = Uri.encodeComponent("$vendorName $address $city");
                        final fallback = Uri.parse(
                          "geo:0,0?q=$query",
                        );
                        await launchUrl(
                          fallback,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location not available')),
                        );
                      }
                    }
                ),
              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Pricing card
                          if (_hasValue(vegPrice) || _hasValue(nonVegPrice))
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      if (_hasValue(vegPrice)) Text('Veg: ₹$vegPrice / plate', style: const TextStyle(color: Colors.grey)),
                                      if (_hasValue(nonVegPrice)) Text('Non-veg: ₹$nonVegPrice / plate', style: const TextStyle(color: Colors.grey)),
                                    ]),
                                    // const Spacer(),
                                    // ElevatedButton(
                                    //   onPressed: () async {
                                    //     final picked = await showDatePicker(
                                    //       context: context,
                                    //       initialDate: _selectedDate ?? DateTime.now(),
                                    //       firstDate: DateTime.now(),
                                    //       lastDate: DateTime(DateTime.now().year + 2),
                                    //     );
                                    //     if (picked != null) {
                                    //       setState(() => _selectedDate = picked);
                                    //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checked availability: ${picked.day}/${picked.month}/${picked.year}')));
                                    //     }
                                    //   },
                                    //   child: const Text('Check availability',style: TextStyle(color: Colors.white),),
                                    //   style: ElevatedButton.styleFrom(
                                    //     backgroundColor: primaryAccent,
                                    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    //   ),
                                    // )
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Portfolio (thumbnails)
                          if (images.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 110,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    itemBuilder: (ctx, idx) {
                                      return Container(
                                        width: 150,
                                        margin: EdgeInsets.only(right: idx == images.length - 1 ? 0 : 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(image: NetworkImage(images[idx]), fit: BoxFit.cover),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // About
                          if (_hasValue(about))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                AnimatedCrossFade(
                                  firstChild: SizedBox(
                                    height: 140,
                                    child: SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: Html(
                                        data: about,
                                        style: {
                                          "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero, fontSize: FontSize(15), color: Colors.black87),
                                        },
                                      ),
                                    ),
                                  ),
                                  secondChild: Html(data: about),
                                  crossFadeState: _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 250),
                                ),
                                if ((about.length) > 250)
                                  TextButton(onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded), child: Text(_aboutExpanded ? 'Read less' : 'Read more')),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // Policies (if any)
                          if (_hasValue(attributes['decor_policy']) || _hasValue(attributes['catering_policy']))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                if (_hasValue(attributes['decor_policy'])) Text('• Decor: ${attributes['decor_policy']}', style: const TextStyle(height: 1.4)),
                                if (_hasValue(attributes['catering_policy'])) Text('• Catering: ${attributes['catering_policy']}', style: const TextStyle(height: 1.4)),
                              ],
                            ),

                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: IconButton(
                              tooltip: 'Write a review',
                              icon: const Icon(Icons.rate_review_outlined),
                              onPressed: ()  {
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
                                print('Reviews');
                                print("Vendor ID: $vendorId");
                                  print(currentUserId);
                                  print(vendorName);

                              },
                            ),
                          )



                          // Ratings summary + call to fetch reviews
                          // Card(
                          //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(12),
                          //     child: Column(
                          //       children: [
                          //         Row(
                          //           children: [
                          //             Column(
                          //               crossAxisAlignment: CrossAxisAlignment.start,
                          //               children: [
                          //                 Text(
                          //                   apiAverageRating > 0 ? apiAverageRating.toStringAsFixed(1) : rating > 0 ? rating.toStringAsFixed(1) : '—',
                          //                   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink),
                          //                 ),
                          //                 Row(
                          //                   children: [
                          //                     Icon(Icons.star, color: Colors.pink.shade400),
                          //                     const SizedBox(width: 6),
                          //                     Text('${apiTotalReviews > 0 ? apiTotalReviews : reviewCount} Reviews', style: const TextStyle(color: Colors.black54)),
                          //                   ],
                          //                 ),
                          //               ],
                          //             ),
                          //             const Spacer(),
                          //             ElevatedButton(
                          //               onPressed: () {
                          //                 fetchReviewsFromApi();
                          //                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing reviews...')));
                          //               },
                          //               child: const Text('Refresh reviews'),
                          //               style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                          //             )
                          //           ],
                          //         ),
                          //         const SizedBox(height: 12),
                          //         if (isReviewsLoading)
                          //           const Center(child: CircularProgressIndicator())
                          //         else if (reviewsError)
                          //           Center(child: Text('Failed to load reviews', style: TextStyle(color: Colors.red.shade400)))
                          //         else if (reviews.isEmpty)
                          //             const Center(child: Text('No reviews yet'))
                          //           else
                          //             Column(
                          //               children: reviews.take(3).map((r) {
                          //                 final rRating = double.tryParse(r['rating']?.toString() ?? '0') ?? 0.0;
                          //                 final rName = r['userName'] ?? 'Guest';
                          //                 final rComment = r['comment'] ?? '';
                          //                 final rDate = r['createdAt'] ?? '';
                          //                 return ListTile(
                          //                   contentPadding: EdgeInsets.zero,
                          //                   leading: CircleAvatar(child: Text(rName.isNotEmpty ? rName[0].toUpperCase() : 'G')),
                          //                   title: Row(
                          //                     children: [
                          //                       Text(rName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          //                       const SizedBox(width: 8),
                          //                       Container(
                          //                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          //                         decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          //                         child: Row(
                          //                           children: [
                          //                             Icon(Icons.star, size: 14, color: Colors.orange.shade700),
                          //                             const SizedBox(width: 4),
                          //                             Text(rRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                          //                           ],
                          //                         ),
                          //                       )
                          //                     ],
                          //                   ),
                          //                   subtitle: Column(
                          //                     crossAxisAlignment: CrossAxisAlignment.start,
                          //                     children: [
                          //                       const SizedBox(height: 6),
                          //                       Text(rComment, maxLines: 2, overflow: TextOverflow.ellipsis),
                          //                       const SizedBox(height: 6),
                          //                       Text(rDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          //                     ],
                          //                   ),
                          //                 );
                          //               }).toList(),
                          //             ),
                          //
                          //         // 'View all reviews' button
                          //         if (!isReviewsLoading && reviews.isNotEmpty)
                          //           TextButton(
                          //             onPressed: () {
                          //               // navigate to full reviews screen if you have one
                          //             },
                          //             child: const Text('View all reviews'),
                          //           )
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          //
                          // const SizedBox(height: 80), // space for bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Sticky bottom bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          child: Row(
            children: [
              // Message (chat)
              Expanded(
                child: OutlinedButton.icon(
                  // onPressed: () {
                  //   if (currentUserId == null || currentUserId!.isEmpty) {
                  //     // redirect to sign in
                  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to message')));
                  //     return;
                  //   }
                  //   final int uid = int.parse(currentUserId!);
                  //   final int vendor = int.parse(vendorId);
                  //
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => ChatPage(
                  //         currentUid: uid,
                  //         otherUid: vendor,
                  //         otherName: vendorName,
                  //         vendorId: vendor,
                  //       ),
                  //     ),
                  //   );
                  //   print("Vendor ID: $vendorId");
                  //   print(currentUserId);
                  //   print(vendor);
                  //   print(vendorName);
                  //
                  //   },
      onPressed: ()  async{
        // Not logged in
        if (currentUserId == null || currentUserId!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to message')),
          );
          return;
        }

        // Profile incomplete
        if (!isProfileCompleted) {
          await showProfilePopup();
          return; // ⛔ THIS FIXES YOUR ISSUE
        }

        final int uid = int.parse(currentUserId!);
        final int vendor = int.parse(vendorId);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              currentUid: uid,
              otherUid: vendor,
              otherName: vendorName,
              vendorId: vendor,
            ),
          ),
        );
          print("Vendor ID: $vendorId");
          print(currentUserId);
          print(vendor);
          print(vendorName);
      },
                  icon: const Icon(Icons.message, color: Colors.pink),
                  label: const Text('Message', style: TextStyle(color: Colors.pink)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.pink.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Call now (primary)
              SizedBox(
                width: 120,
                child: ElevatedButton.icon(
                  onPressed: () => _call(phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // small helper chip used in UI
  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6),
      ]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey.shade800),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}


