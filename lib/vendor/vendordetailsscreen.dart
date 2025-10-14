import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../chat/chat_screen.dart';
import '../chat/chat_service.dart';
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

  @override
  void initState() {
    super.initState();
    fetchServices();
  }

  Future<void> fetchServices() async {
    try {
      final encodedSubcategory =
      Uri.encodeComponent(widget.subcategoryName.toLowerCase());
      final url = Uri.parse(
          "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory");
      print("Fetching services from: $url");

      final response =
      await http.get(url, headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        for (var service in data) {
          final media = service['media'] ?? {};
          print("📦 Service media: $media");
          if (media['coverImage'] != null) {
            final cover = media['coverImage'].toString();
            final fullUrl = cover.startsWith('/uploads/')
                ? "https://happywedzbackend.happywedz.com$cover"
                : cover;
            print("🖼️ Cover image URL: $fullUrl");
          } else {
            print("⚠️ No coverImage for this service");
          }
        }

        setState(() {
          services = data;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("❌ Error fetching services: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("💥 API Error: $e");
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

    // ✅ Determine proper image URL
    String imageUrl = 'https://via.placeholder.com/400x300';

// 1️⃣ Try cover image if exists
    if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
      final cover = media['coverImage'].toString();
      imageUrl = cover.startsWith('/uploads/')
          ? "https://happywedzbackend.happywedz.com$cover"
          : cover;
    }

// 2️⃣ If no coverImage, try gallery images
    else if (media['gallery'] != null && media['gallery'] is List) {
      for (var item in media['gallery']) {
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

// 3️⃣ Log what we’re using
    print("🧩 Final image used for ${vendor['businessName'] ?? 'Unknown'}: $imageUrl");



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
            // ✅ Updated cover image logic
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor['businessName'] ?? attributes['name'] ?? "No Name",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (attributes['description'] != null &&
                      attributes['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        attributes['description'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (attributes['starting_price'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Starting Price: ₹${attributes['starting_price']}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFE91E63)),
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

class VendorDetailsScreen extends StatefulWidget {
  final dynamic service;

  const VendorDetailsScreen({Key? key, required this.service}) : super(key: key);

  @override
  _VendorDetailsScreenState createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  late AnimationController _animationController;

  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final vendor = service['vendor'] ?? {};
    final attributes = service['attributes'] ?? {};
    final media = service['media'] ?? {};
    final String vendorId = vendor['id']?.toString() ?? '';
    final String vendorName = vendor['businessName']?.toString() ?? 'Vendor';
    final String vendorPhone = vendor['phone']?.toString() ?? '';

    // ✅ Build image list (coverImage + gallery)
    final List<String> images = [];

    // 1️⃣ Add cover image (if exists)
    if (media['coverImage'] != null && media['coverImage'].toString().isNotEmpty) {
      final coverImage = media['coverImage'].toString();
      final coverUrl = coverImage.startsWith('/uploads/')
          ? "https://happywedzbackend.happywedz.com$coverImage"
          : coverImage;
      images.add(coverUrl);
    }

    // 2️⃣ Add gallery images
    if (media['gallery'] != null && media['gallery'] is List) {
      for (var item in media['gallery']) {
        if (item is String && item.startsWith('/uploads/')) {
          images.add("https://happywedzbackend.happywedz.com$item");
        } else if (item is Map && item['url'] != null) {
          final url = item['url'].toString();
          images.add(url.startsWith('/uploads/')
              ? "https://happywedzbackend.happywedz.com$url"
              : url);
        }
      }
    }

    // 3️⃣ Fallback image
    if (images.isEmpty) {
      images.add('https://via.placeholder.com/400x300');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Sliver AppBar with image carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.pink,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 50, color: Colors.white),
                          );
                        },
                      );
                    },
                  ),
                  // Page indicators
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentImageIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white54,
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

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vendor Name and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor['businessName'] ?? "No Name",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  vendor['rating']?.toString() ?? '5.0 Review Score',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.favorite_border, color: Colors.grey[400], size: 28),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location
                  if (attributes['location'] != null &&
                      attributes['location']['city'] != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${attributes['location']['city']}, ${attributes['location']['state'] ?? ""}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // About
                  if (attributes['description'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          attributes['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Starting Price
                  if (attributes['starting_price'] != null)
                    Text(
                      'Starting Price: ₹${attributes['starting_price']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Albums
                  const Text(
                    'Albums',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: media['gallery'] != null ? media['gallery'].length : 0,
                      itemBuilder: (context, index) {
                        final item = media['gallery'][index];
                        String? imageUrl;

                        if (item is String && item.startsWith('/uploads/')) {
                          imageUrl = "https://happywedzbackend.happywedz.com$item";
                        } else if (item is Map && item['url'] != null) {
                          final url = item['url'].toString();
                          imageUrl = url.startsWith('/uploads/')
                              ? "https://happywedzbackend.happywedz.com$url"
                              : url;
                        }

                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[300],
                            image: imageUrl != null
                                ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: imageUrl == null
                              ? const Icon(Icons.image, color: Colors.white, size: 30)
                              : null,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildCheckAvailability(),

                  const SizedBox(height: 32),

                  // ✅ Message and Call buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            // ✅ Ensure user is logged in
                            User? currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser == null) {
                              try {
                                final userCredential = await FirebaseAuth.instance.signInAnonymously();
                                currentUser = userCredential.user;
                                print("✅ Signed in anonymously: ${currentUser?.uid}");
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to sign in anonymously: $e')),
                                );
                                return;
                              }
                            }

                            // ✅ Get or create chat
                            final chatService = ChatService();
                            final chatId = await chatService.createOrGetChat(vendorId);

                            if (chatId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to open chat. Please try again.')),
                              );
                              return;
                            }

                            // ✅ Mark all unseen messages as seen before opening chat
                            await chatService.markMessagesSeen(chatId);

                            // ✅ Navigate to ChatScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  chatId: chatId,
                                  otherUserName: vendorName,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.pink,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.message, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () async {
                          final Uri url = Uri(scheme: 'tel', path: vendorPhone);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cannot make a call')),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.phone, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📅 Date Picker Section
  Widget _buildCheckAvailability() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Check Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.grey[500], size: 18),
                        const SizedBox(width: 8),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Select Date',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.pink,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Check Dates',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📆 Date Picker Logic
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.pink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
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
