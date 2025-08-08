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
      appBar:AppBar(
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
        children: const [
          VenueCard(
            imageUrl: 'assets/images/palace1.jpg',
            name: 'The Grand Palace',
            location: 'Mumbai',
            price: '₹2,000/plate',
            phone: '9876543210',
            whatsappNumber: '919876543210', rating: '4.5',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace3.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace4.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace5.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/palace6.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
          VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ), VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ), VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ), VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ), VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ), VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ), VenueCard(
            imageUrl: 'assets/images/venue2.jpg',
            name: 'Royal Garden',
            location: 'Delhi',
            price: '₹1,500/plate',
            phone: '9876543211',
            whatsappNumber: '919876543211', rating: '4.7',
          ),
        ],
      ),
    );
  }
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(0), bottom: Radius.circular(16)),
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
                            style: const TextStyle(color: Colors.white, fontSize: 14),
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
                Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    'assets/images/whatsapp_icon.png',
                   height: 30,
                    width: 30,

                  ),
                  onPressed: () {
                    // Action here
                  },
                ),

                const SizedBox(width: 8),
                IconButton(
                  icon:  Icon(Icons.message, color: Colors.grey),
                  onPressed: () => {}
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text("View Details"),
                )
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feature coming soon')),
        );
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
      icon:  Icon(Icons.whatshot, color: Colors.green),
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
