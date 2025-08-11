import 'package:flutter/material.dart';

class AllFeaturesScreen extends StatelessWidget {
  const AllFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {"icon": Icons.checklist, "title": "Checklist", "description": "Plan every wedding task with a smart checklist."},
      {"icon": Icons.group, "title": "Guestlist Manager", "description": "Manage all your guests in one place."},
      {"icon": Icons.event_available, "title": "Biggest Planner", "description": "Stay on top of all wedding events."},
      {"icon": Icons.camera_alt, "title": "Photo Inspiration", "description": "Browse trending wedding looks & decor."},
      {"icon": Icons.favorite, "title": "Vendors", "description": "Find and book the best vendors instantly."},
    ];

    return Scaffold(
      appBar: AppBar(
        // title: const Text("All Features"),
        // backgroundColor: Colors.pink[200],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: features.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final feature = features[index];
          return ListTile(
            leading: Icon(feature["icon"], color: Colors.pink[200]),
            title: Text(feature["title"], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(feature["description"]),
            onTap: () {
              // Navigate to that feature’s page
            },
          );
        },
      ),
    );
  }
}
