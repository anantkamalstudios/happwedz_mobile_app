import 'package:flutter/material.dart';

class VendorPage extends StatefulWidget {
  @override
  _VendorPageState createState() => _VendorPageState();
}

class _VendorPageState extends State<VendorPage> {
  List<Map<String, dynamic>> vendors = [
    {
      "name": "Dream Weddings Photography",
      "location": "Mumbai",
      "rating": 4.8,
      "price": "₹50,000 onwards",
      "image": "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e"
    },
    {
      "name": "Elegant Decorators",
      "location": "Delhi",
      "rating": 4.6,
      "price": "₹1,20,000 onwards",
      "image": "https://www.shaadibaraati.com/vendors-profile/bbe6d5f8a88ad1e53cd5d4b376ee8081.jpg"
    },
    {
      "name": "Golden Touch Catering",
      "location": "Jaipur",
      "rating": 4.7,
      "price": "₹800 per plate",
      "image": "https://images.unsplash.com/photo-1562059390-a761a084768e"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: Column(
        children: [
          _buildCategoryTabs(),
          Expanded(
            child: ListView.builder(
              itemCount: vendors.length,
              itemBuilder: (context, index) {
                return _buildVendorCard(vendors[index]);
              },
            ),
          ),
        ],
      ),
    );
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
                hintText: "Search vendors...",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    List<String> categories = [
      "Photography",
      "Makeup Artist",
      "Venue",
      "Decor",
      "Catering"
    ];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                foregroundColor: Colors.black,
              ),
              onPressed: () {},
              child: Text(categories[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            vendor["image"],
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              vendor["name"],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                Text(vendor["location"]),
                const Spacer(),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(vendor["rating"].toString()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              vendor["price"],
              style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
