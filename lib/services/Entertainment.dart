import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EntertainmentItem {
  final String name;
  final String category;
  final String imageUrl;
  final String about;
  final String phone;

  EntertainmentItem({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.about,
    required this.phone,
  });
}

class EntertainmentListScreen extends StatelessWidget {
  EntertainmentListScreen({super.key});

  final List<EntertainmentItem> items = [
    EntertainmentItem(
      name: "DJ Rohit",
      category: "Wedding DJ",
      imageUrl: "assets/images/e1.webp",
      about:
          "DJ Rohit has been entertaining weddings for over 10 years, bringing the best music and vibes to make your special day unforgettable.",
      phone: "+911234567890",
    ),
    EntertainmentItem(
      name: "Live Band Harmony",
      category: "Live Band",
      imageUrl: "assets/images/e2.webp",
      about:
          "Harmony is a live band specializing in soulful music for weddings, receptions, and special events.",
      phone: "+911234567891",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Entertainment")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                item.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(item.name),
            subtitle: Text(item.category),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EntertainmentDetailScreen(item: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class EntertainmentDetailScreen extends StatelessWidget {
  final EntertainmentItem item;

  const EntertainmentDetailScreen({super.key, required this.item});

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
    final accentColor = Color(0xFFD17E83);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(item.name),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: Image.asset(
              item.imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Name, Category, About
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.category,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "About",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.about,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ),
            ),
          ),

          // Call & WhatsApp buttons pinned at bottom
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(Icons.call, color: Colors.white),
                    label: Text("Call", style: TextStyle(color: Colors.white)),
                    onPressed: () => _makePhoneCall(item.phone),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/whatsapp_icon.webp',
                      height: 30,
                      width: 30,
                    ),
                    label: Text(
                      "WhatsApp",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _openWhatsApp(item.phone),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
