import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class MakeupScreen extends StatefulWidget {
  const MakeupScreen({super.key});

  @override
  State<MakeupScreen> createState() => _MakeupScreenState();
}

class _MakeupScreenState extends State<MakeupScreen> {
  final List<Map<String, String>> makeupArtists = [
    {
      "name": "Glam Studio",
      "location": "Mumbai, India",
      "image": "assets/images/makeup1.webp",
      "phone": "+911234567890",
      "whatsapp": "+911234567890"
    },
    {
      "name": "Bridal Beauty",
      "location": "Delhi, India",
      "image": "assets/images/makeup2.webp",
      "phone": "+919876543210",
      "whatsapp": "+919876543210"
    },
    {
      "name": "Royal Touch",
      "location": "Jaipur, India",
      "image": "assets/images/makeup3.webp",
      "phone": "+918888888888",
      "whatsapp": "+918888888888"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Makeup Artists"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Column(
        children: [
          // Search and Filter Row
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search makeup artists...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list, color: Colors.pinkAccent),
                  onPressed: () {
                    // TODO: Add filter functionality
                  },
                ),
              ],
            ),
          ),

          // List of Makeup Artists
          Expanded(
            child: ListView.builder(
              itemCount: makeupArtists.length,
              itemBuilder: (context, index) {
                var artist = makeupArtists[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MakeupArtistScreen(),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          child: Image.asset(
                            artist["image"]!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  artist["name"]!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  artist["location"]!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.call, color: Colors.green),
                                      onPressed: () {

                                      },
                                    ),
                                    IconButton(
                                      icon: Image.asset(
                                        'assets/images/whatsapp_icon.webp',
                                        height: 30,
                                        width: 30,

                                      ),
                                      onPressed: () {

                                      },
                                    ),
                                  ],
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
          ),
        ],
      ),
    );
  }
}



































class MakeupArtistScreen extends StatelessWidget {
  const MakeupArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Glam by Neha',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/bridal_makeup.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating & Price Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          Column(
                            children: [
                              Icon(Icons.star, color: Colors.pink, size: 24),
                              SizedBox(height: 4),
                              Text('4.8', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Ratings', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              Icon(Icons.currency_rupee, color: Colors.pink, size: 24),
                              SizedBox(height: 4),
                              Text('₹15,000', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Per function', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About Section
                  const Text(
                    "About",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Neha is a professional makeup artist with over 8 years of experience "
                        "in bridal, engagement, and party makeovers. She uses high-quality products "
                        "to ensure long-lasting looks that enhance your natural beauty.",
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),

                  // Photos Section
                  const Text(
                    "Photos",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildPhotoCard('assets/images/makeup1.jpg'),
                        _buildPhotoCard('assets/images/makeup2.jpg'),
                        _buildPhotoCard('assets/images/makeup3.jpg'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reviews Section
                  const Text(
                    "Reviews",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildReviewCard(
                    'Aditi Sharma',
                    'Neha did an amazing job for my wedding day! The makeup lasted all day and looked stunning in photos.',
                  ),
                  _buildReviewCard(
                    'Riya Kapoor',
                    'She is super friendly and understands the client’s needs perfectly. Highly recommend!',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildPhotoCard(String imagePath) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  static Widget _buildReviewCard(String name, String review) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              review,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
