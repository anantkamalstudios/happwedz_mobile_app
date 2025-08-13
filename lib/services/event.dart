import 'package:flutter/material.dart';


class EventCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;

  const EventCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(
              imagePath: imagePath,
              title: title,
              location: location,
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          padding: const EdgeInsets.all(12),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                location,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
















class EventDetailsScreen extends StatelessWidget {
  final String imagePath;
  final String title;
  final String location;

  const EventDetailsScreen({
    super.key,
    required this.imagePath,
    required this.title,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: const TextStyle(fontSize: 16)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(imagePath, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.pink, size: 20),
                      const SizedBox(width: 4),
                      Text(location,
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "About this Venue",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This venue offers a perfect blend of elegance and comfort, ideal for weddings and events. With spacious halls, lush gardens, and top-notch services, it ensures a memorable experience for your special day.",
                    style: TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Call action
                          },
                          icon: const Icon(Icons.call),
                          label: const Text("Call"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // WhatsApp action
                          },
                          icon: Image.asset(
                            'assets/images/whatsapp_icon.webp',
                            height: 30,
                            width: 30,

                          ),
                          label: const Text("WhatsApp"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
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
