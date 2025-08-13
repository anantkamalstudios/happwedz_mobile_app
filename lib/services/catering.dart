// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class CateringItem {
//   final String name;
//   final String category;
//   final String imageUrl;
//   final String about;
//   final String phone;
//   final List<String> menuImages;
//
//   CateringItem({
//     required this.name,
//     required this.category,
//     required this.imageUrl,
//     required this.about,
//     required this.phone,
//     required this.menuImages,
//   });
// }
//
// class CateringDetailScreen extends StatelessWidget {
//   final CateringItem item;
//
//   const CateringDetailScreen({super.key, required this.item});
//
//   Future<void> _makePhoneCall(String phone) async {
//     final Uri uri = Uri(scheme: 'tel', path: phone);
//     await launchUrl(uri);
//   }
//
//   Future<void> _openWhatsApp(String phone) async {
//     final Uri uri = Uri.parse("https://wa.me/$phone");
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           CustomScrollView(
//             slivers: [
//               // Banner image
//               SliverAppBar(
//                 expandedHeight: 250,
//                 pinned: true,
//                 backgroundColor: Colors.white,
//                 iconTheme: const IconThemeData(color: Colors.black87),
//                 flexibleSpace: FlexibleSpaceBar(
//                   background: Image.asset(
//                     item.imageUrl,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Catering name & category
//                       Text(
//                         item.name,
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         item.category,
//                         style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                       ),
//
//                       const SizedBox(height: 16),
//                       const Divider(),
//                       const SizedBox(height: 8),
//
//                       // About
//                       const Text(
//                         "About",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         item.about,
//                         style: TextStyle(fontSize: 14, color: Colors.grey[800]),
//                       ),
//
//                       const SizedBox(height: 16),
//
//                       // Menu images
//                       if (item.menuImages.isNotEmpty) ...[
//                         const Text(
//                           "Menu Highlights",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         SizedBox(
//                           height: 120,
//                           child: ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: item.menuImages.length,
//                             itemBuilder: (context, index) {
//                               return Container(
//                                 margin: const EdgeInsets.only(right: 8),
//                                 width: 120,
//                                 decoration: BoxDecoration(
//                                   borderRadius: BorderRadius.circular(8),
//                                   image: DecorationImage(
//                                     image: AssetImage(item.menuImages[index]),
//                                     fit: BoxFit.cover,
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ],
//
//                       const SizedBox(height: 100),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//
//           // Call & WhatsApp
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 0,
//             child: Container(
//               padding:
//               const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               color: Colors.white,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       icon: const Icon(Icons.call, color: Colors.white),
//                       label: const Text(
//                         "Call",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       onPressed: () => _makePhoneCall(item.phone),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.teal,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       icon: Image.asset(
//                         'assets/images/whatsapp_icon.webp',
//                         height: 30,
//                         width: 30,
//                       ),
//                       label: const Text(
//                         "WhatsApp",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                       onPressed: () => _openWhatsApp(item.phone),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';


class CateringPage extends StatelessWidget {
  final List<Map<String, String>> cateringOptions = [
    {
      'name': 'Royal Feast Caterers',
      'image': 'https://images.pexels.com/photos/67468/pexels-photo-67468.jpeg',
      'price': '₹800 per plate',
      'description':
      'We specialize in royal-themed catering with exquisite Indian and continental dishes.',
    },
    {
      'name': 'Golden Spoon Events',
      'image': 'https://images.pexels.com/photos/5531420/pexels-photo-5531420.jpeg',
      'price': '₹950 per plate',
      'description':
      'Luxury catering with gourmet recipes, live counters, and bespoke menus.',
    },
    {
      'name': 'Flavours of India',
      'image': 'https://images.pexels.com/photos/326279/pexels-photo-326279.jpeg',
      'price': '₹700 per plate',
      'description':
      'Authentic Indian cuisine with a variety of regional flavors and fresh ingredients.',
    },
  ];

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
                hintText: "Search caters...",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: cateringOptions.length,
        itemBuilder: (context, index) {
          final catering = cateringOptions[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CateringDetailPage(catering: catering),
                ),
              );
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      catering['image']!,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catering['name']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          catering['price']!,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CateringDetailPage extends StatelessWidget {
  final Map<String, String> catering;

  const CateringDetailPage({Key? key, required this.catering})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(catering['name']!),
        backgroundColor: Colors.pinkAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              catering['image']!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    catering['name']!,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    catering['price']!,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.pinkAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    catering['description']!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text(
                      "Contact Caterer",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      // Call or message
                    },
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

