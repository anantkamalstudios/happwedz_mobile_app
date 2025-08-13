import 'package:flutter/material.dart';

class MehendiArtistScreen extends StatelessWidget {
  const MehendiArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent[200],
        title: const Text("Mehendi Artists"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search Mehendi Artists...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip("Bridal"),
                  _buildChip("Party"),
                  _buildChip("Budget Friendly"),
                  _buildChip("Luxury"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Artist Cards (Using assets instead of network images)
            _artistCard(
              image: "assets/images/m_a_1.webp",
              name: "Henna by Ayesha",
              location: "Mumbai",
              price: "₹5,000 onwards",
              rating: 4.9,
              reviews: 120,
              phone: "+91 9876543210",
              whatsapp: "+91 9876543210",
            ),
            _artistCard(
              image: "assets/images/m_a_2.webp",
              name: "Shalini Mehendi Art",
              location: "Delhi",
              price: "₹3,500 onwards",
              rating: 4.8,
              reviews: 98,
              phone: "+91 9123456780",
              whatsapp: "+91 9123456780",
            ),
            _artistCard(
              image: "assets/images/m_a_3.webp",
              name: "Elegant Henna by Priya",
              location: "Bangalore",
              price: "₹4,000 onwards",
              rating: 4.7,
              reviews: 85,
              phone: "+91 9988776655",
              whatsapp: "+91 9988776655",
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        backgroundColor: Colors.pink[50],
        labelStyle: const TextStyle(color: Colors.pinkAccent),
      ),
    );
  }

  static Widget _artistCard({
    required String image,
    required String name,
    required String location,
    required String price,
    required double rating,
    required int reviews,
    required String phone,
    required String whatsapp,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image from assets
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              image,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(location, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(price,
                    style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 16),
                    const SizedBox(width: 4),
                    Text("$rating • $reviews reviews"),
                  ],
                ),
                const SizedBox(height: 10),

                // Phone & WhatsApp row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.blue),
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
        ],
      ),
    );
  }
}
