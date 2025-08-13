import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CateringItem {
  final String name;
  final String category;
  final String imageUrl;
  final String about;
  final String phone;
  final List<String> menuImages;

  CateringItem({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.about,
    required this.phone,
    required this.menuImages,
  });
}

class CateringDetailScreen extends StatelessWidget {
  final CateringItem item;

  const CateringDetailScreen({super.key, required this.item});

  Future<void> _makePhoneCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String phone) async {
    final Uri uri = Uri.parse("https://wa.me/$phone");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Banner image
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.black87),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    item.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Catering name & category
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      // About
                      const Text(
                        "About",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.about,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),

                      const SizedBox(height: 16),

                      // Menu images
                      if (item.menuImages.isNotEmpty) ...[
                        const Text(
                          "Menu Highlights",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.menuImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: AssetImage(item.menuImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Call & WhatsApp
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text(
                        "Call",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => _makePhoneCall(item.phone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Image.asset(
                        'assets/images/whatsapp_icon.webp',
                        height: 30,
                        width: 30,
                      ),
                      label: const Text(
                        "WhatsApp",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => _openWhatsApp(item.phone),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
