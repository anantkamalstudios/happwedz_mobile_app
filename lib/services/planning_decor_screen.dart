import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlanningDecorScreen extends StatelessWidget {
  const PlanningDecorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.pinkAccent[200],
        title: const Text("Planning & Decor"),
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
                hintText: "Search Planning & Decor vendors...",
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
                  _buildChip("Top Rated"),
                  _buildChip("Budget Friendly"),
                  _buildChip("Luxury"),
                  _buildChip("Near Me"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Vendor Cards
            _vendorCard(
              image:
              "https://images.pexels.com/photos/169190/pexels-photo-169190.jpeg",
              name: "Dream Decorators",
              location: "Mumbai",
              rating: 4.9,
              reviews: 120,
              phone: "+919876543210",
            ),
            _vendorCard(
              image:
              "https://images.pexels.com/photos/587741/pexels-photo-587741.jpeg",
              name: "Royal Weddings & Events",
              location: "Delhi",
              rating: 4.8,
              reviews: 98,
              phone: "+919812345678",
            ),
            _vendorCard(
              image:
              "https://images.pexels.com/photos/169198/pexels-photo-169198.jpeg",
              name: "Floral Fantasy",
              location: "Bangalore",
              rating: 4.7,
              reviews: 85,
              phone: "+919911223344",
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

  static Widget _vendorCard({
    required String image,
    required String name,
    required String location,
    required double rating,
    required int reviews,
    required String phone,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
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
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber[700], size: 16),
                    const SizedBox(width: 4),
                    Text("$rating • $reviews reviews"),
                  ],
                ),
                const SizedBox(height: 8),
                // Call & WhatsApp buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () {
                        launchUrl(Uri.parse("tel:$phone"));
                      },
                    ),
                    IconButton(
                      icon: Image.asset(
                        'assets/images/whatsapp_icon.webp',
                        height: 30,
                        width: 30,

                      ),
                      onPressed: () {
                        launchUrl(Uri.parse(
                            "https://wa.me/${phone.replaceAll('+', '')}"));
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
