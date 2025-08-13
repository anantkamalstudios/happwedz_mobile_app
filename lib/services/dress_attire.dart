import 'package:flutter/material.dart';

class DressItem {
  final String name;
  final String brand;
  final String imageUrl;

  DressItem({
    required this.name,
    required this.brand,
    required this.imageUrl,
  });
}

class DressAttireScreen extends StatelessWidget {
  DressAttireScreen({super.key});

  final List<DressItem> dresses = [
    DressItem(
      name: "Embroidered Lehenga",
      brand: "Sabyasachi",
      imageUrl:
      "assets/images/d_a3.webp",
    ),
    DressItem(
      name: "Red Bridal Saree",
      brand: "Kiya Sharma",
      imageUrl:
      "assets/images/d_a2.webp",
    ),
    DressItem(
      name: "Golden Gown",
      brand: "Anita Dongre",
      imageUrl:
      "assets/images/d_a4.webp",
    ),
    DressItem(
      name: "Pastel Lehenga",
      brand: "Tarun Tahiliani",
      imageUrl:
      "assets/images/d_a1.webp",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.white;
    final accentColor = Color(0xFFD17E83);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          "Dress & Attire",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: accentColor),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: accentColor),
            onPressed: () {},
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: dresses.length,
        itemBuilder: (context, index) {
          final item = dresses[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DressDetailScreen(dress: item),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      item.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white.withOpacity(0.85),
                      padding: EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            item.brand,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
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

class DressDetailScreen extends StatelessWidget {
  final DressItem dress;

  const DressDetailScreen({super.key, required this.dress});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFFD17E83);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(dress.name, style: TextStyle(color: Colors.black87)),
        iconTheme: IconThemeData(color: accentColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              dress.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              dress.brand,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),

        ],
      ),
    );
  }
}
