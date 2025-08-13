import 'package:flutter/material.dart';
//
// class VenueScreen extends StatefulWidget {
//   @override
//   _VenueScreenState createState() => _VenueScreenState();
// }
//
// class _VenueScreenState extends State<VenueScreen> {
//   String selectedCity = 'Mumbai';
//   List<Map<String, dynamic>> venues = [
//     {
//       "name": "Royal Palace Banquet",
//       "location": "Mumbai",
//       "rating": 4.5,
//       "priceVeg": "₹1,200",
//       "priceNonVeg": "₹1,500",
//       "capacity": "300-500",
//       "image": "https://www.behance.net/gallery/103717055/ROYAL-PALACE-WEDDING-HALL/modules/596268763"
//     },
//     {
//       "name": "Sunset Lawn Resort",
//       "location": "Jaipur",
//       "rating": 4.7,
//       "priceVeg": "₹1,000",
//       "priceNonVeg": "₹1,300",
//       "capacity": "500-1000",
//       "image": "https://images.unsplash.com/photo-1506744038136-46273834b3fb"
//     }
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             const Icon(Icons.location_on, size: 18),
//             const SizedBox(width: 4),
//             DropdownButton<String>(
//               value: selectedCity,
//               underline: const SizedBox(),
//               icon: const Icon(Icons.keyboard_arrow_down),
//               items: ['Mumbai', 'Delhi', 'Jaipur', 'Bangalore']
//                   .map((city) => DropdownMenuItem(
//                 value: city,
//                 child: Text(city),
//               ))
//                   .toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedCity = value!;
//                 });
//               },
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildFilters(),
//           Expanded(
//             child: ListView.builder(
//               itemCount: venues.length,
//               itemBuilder: (context, index) {
//                 return _buildVenueCard(venues[index]);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildFilters() {
//     List<String> filters = [
//       "Price Per Plate",
//       "Capacity",
//       "Venue Type",
//       "More Filters"
//     ];
//     return Container(
//       height: 50,
//       padding: const EdgeInsets.symmetric(horizontal: 8),
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         itemBuilder: (context, index) {
//           return OutlinedButton(
//             onPressed: () {},
//             style: OutlinedButton.styleFrom(
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20)),
//             ),
//             child: Text(filters[index]),
//           );
//         },
//         separatorBuilder: (_, __) => const SizedBox(width: 8),
//         itemCount: filters.length,
//       ),
//     );
//   }
//
//   Widget _buildVenueCard(Map<String, dynamic> venue) {
//     return Card(
//       margin: const EdgeInsets.all(8),
//       clipBehavior: Clip.antiAlias,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Image.network(
//             venue["image"],
//             height: 180,
//             width: double.infinity,
//             fit: BoxFit.cover,
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               venue["name"],
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: Row(
//               children: [
//                 const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                 Text(venue["location"]),
//                 const Spacer(),
//                 const Icon(Icons.star, color: Colors.amber, size: 16),
//                 Text(venue["rating"].toString()),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Text("Veg: ${venue["priceVeg"]}",
//                     style: const TextStyle(color: Colors.green)),
//                 const SizedBox(width: 16),
//                 Text("Non-Veg: ${venue["priceNonVeg"]}",
//                     style: const TextStyle(color: Colors.red)),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text("Capacity: ${venue["capacity"]} guests",
//                 style: const TextStyle(fontWeight: FontWeight.w500)),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:url_launcher/url_launcher.dart';

import 'category_chip.dart';

class VenueScreen extends StatefulWidget {
  const VenueScreen({super.key});

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

Widget _buildSearchBar() {
  return Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Row(
      children: [
        Icon(Icons.search, color: Colors.grey, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search venue...",
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}

class _VenueScreenState extends State<VenueScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: _buildSearchBar(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              // Open filter modal
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip("Banquet Hall"),
                _buildCategoryChip("4 Star Hotel"),
                _buildCategoryChip("3 Star Hotel"),
                _buildCategoryChip("5 Star Hotel"),
                _buildCategoryChip("Wedding Resort"),
                _buildCategoryChip("Marriage Lawns"),
                _buildCategoryChip("Small Functions"),
                _buildCategoryChip("Party Halls"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          VenueCard(
            imageUrl: 'assets/images/palace1.webp',
            name: 'The Grand Palace',
            location: 'Mumbai',
            price: '₹2,000/plate',
            phone: '9876543210',
            whatsappNumber: '919876543210',
            rating: '4.5',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace3.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace4.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace5.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace6.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.webp',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211',
            rating: '4.7',
          ),
        ],
      ),
    );
  }
}

Widget _buildCategoryChip(String title) {
  return Container(
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.pink[200],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Center(
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

class VenueCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String location;
  final String price;
  final String phone;
  final String whatsappNumber;
  final String rating;

  const VenueCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.location,
    required this.price,
    required this.phone,
    required this.whatsappNumber,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.pink[50],
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📸 Venue Image with overlay + favorite icon
          const SizedBox(height: 20),
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // 🔘 Favorite heart icon
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.red),
                    onPressed: () {},
                  ),
                ),
              ),
              // Gradient + venue name
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(0),
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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

          // 📍 Location + price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(location, style: const TextStyle(color: Colors.grey)),
                Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 📞 Action icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.blueAccent),
                  onPressed: () => _makeCall(phone),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Image.asset(
                    'assets/images/whatsapp_icon.webp',
                    height: 30,
                    width: 30,
                  ),
                  onPressed: () {
                    // Action here
                  },
                ),

                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.message, color: Colors.grey),
                  onPressed: () => {},
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VenueViewDetailsScreen(),
                      ),
                    );
                  },
                  child: const Text("View Details"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _makeCall(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openWhatsApp(String number) async {
    final url = Uri.parse("https://wa.me/$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

// 🔘 Feature button
class FeatureButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Feature coming soon')));
      },
      icon: const Icon(Icons.message, color: Colors.pinkAccent),
      label: const Text('Message', style: TextStyle(color: Colors.pinkAccent)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.pinkAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// 🟢 WhatsApp button
class WhatsAppButton extends StatelessWidget {
  final String phoneNumber;

  const WhatsAppButton({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final url = Uri.parse("https://wa.me/$phoneNumber");
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      icon: Icon(Icons.whatshot, color: Colors.green),
      label: const Text('WhatsApp', style: TextStyle(color: Colors.green)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.green),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ☎️ Call button
class CallButton extends StatelessWidget {
  final String phoneNumber;

  const CallButton({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final url = Uri.parse("tel:$phoneNumber");
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
      icon: const Icon(Icons.call, color: Colors.blueAccent),
      label: const Text('Call', style: TextStyle(color: Colors.blueAccent)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.blueAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

//banquet hall,4 star hotel,3 star hotel,5 star hotel,wedding resort,Marriage lawns,Small functions,party halls
//

class VenueViewDetailsScreen extends StatefulWidget {
  const VenueViewDetailsScreen({super.key});

  @override
  State<VenueViewDetailsScreen> createState() => _VenueViewDetailsScreenState();
}

class _VenueViewDetailsScreenState extends State<VenueViewDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: true,
              expandedHeight: 250,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset("assets/images/venue.webp", fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.3)),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Grand Wedding Palace",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(
                                Icons.location_on,
                                color: Colors.white70,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Mumbai, Maharashtra",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: const [
                              Icon(Icons.star, color: Colors.yellow, size: 16),
                              SizedBox(width: 4),
                              Text(
                                "4.8 (120 reviews)",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.pinkAccent,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.pinkAccent,
                        isScrollable: true,
                        tabs: const [
                          Tab(text: "About"),
                          Tab(text: "Photos"),
                          Tab(text: "Reviews"),
                          Tab(text: "FAQs"),
                          Tab(text: "Contact"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAboutTab(),
            _buildPhotosTab(),
            _buildReviewsTab(),
            _buildFaqsTab(),
            _buildContactTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(
        "Grand Wedding Palace offers the perfect venue for your dream wedding, "
        "featuring spacious banquet halls, elegant decor, and premium services. "
        "We cater to all wedding needs and make your special day unforgettable.",
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              "assets/images/venue${index + 1}.webp",
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage("assets/images/user.webp"),
            ),
            title: const Text("John Doe"),
            subtitle: const Text(
              "Amazing venue with top-notch service. Highly recommended!",
            ),
            trailing: const Icon(Icons.star, color: Colors.yellow),
          ),
        );
      },
    );
  }

  Widget _buildFaqsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ExpansionTile(
          title: Text("What is the seating capacity?"),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Our venue can comfortably accommodate up to 500 guests.",
              ),
            ),
          ],
        ),
        ExpansionTile(
          title: Text("Do you provide catering services?"),
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Yes, we provide premium catering services with customizable menus.",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text("Call"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            icon: Image.asset(
              'assets/images/whatsapp_icon.webp',
              height: 30,
              width: 30,
            ),
            label: const Text("WhatsApp"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
