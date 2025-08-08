

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:h_w_a/services/category_chip.dart';

import 'animatedFeatureCard.dart';
import 'event.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScrollController _eventScrollController = ScrollController();
  late Timer _scrollTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    const scrollDuration = Duration(milliseconds: 60);
    const scrollStep = 4.0;

    _scrollTimer = Timer.periodic(scrollDuration, (timer) {
      if (_eventScrollController.hasClients) {
        final maxScroll = _eventScrollController.position.maxScrollExtent;
        final currentScroll = _eventScrollController.offset;

        if (currentScroll >= maxScroll) {
          _eventScrollController.jumpTo(0); // Reset to start
        } else {
          _eventScrollController.animateTo(
            currentScroll + scrollStep,
            duration: scrollDuration,
            curve: Curves.linear,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollTimer.cancel();
    _eventScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search services...',
                border: InputBorder.none,
                icon: Icon(Icons.search),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Categories
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                CategoryChip(title: 'All'),
                CategoryChip(title: 'Photography'),
                CategoryChip(title: 'Venue'),
                CategoryChip(title: 'Wedding Planner'),
                CategoryChip(title: 'Videography'),
                CategoryChip(title: 'Dress & Attire'),
                CategoryChip(title: 'Decoration & Lighting'),
                CategoryChip(title: 'Entertainment'),
                CategoryChip(title: 'Jewellery'),
                CategoryChip(title: 'Catering'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Service Cards
          Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink[200],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                ServiceCard(
                  imagePath: 'assets/images/venue.jpg',
                  title: 'Venue',
                  rating: 4.8,
                ),
                ServiceCard(
                  imagePath: 'assets/images/VPS.jpg',
                  title: 'Virtual Planning',
                  rating: 4.6,
                ),
                ServiceCard(
                  imagePath: 'assets/images/mehendi_artist.jpg',
                  title: 'Mehendi Artist',
                  rating: 4.9,
                ),
                ServiceCard(
                  imagePath: 'assets/images/bridal_makeup.jpg',
                  title: 'Makeup',
                  rating: 4.9,
                ),
                ServiceCard(
                  imagePath: 'assets/images/photography.jpg',
                  title: 'Photographers',
                  rating: 4.8,
                ),
                ServiceCard(
                  imagePath: 'assets/images/p&d.jpg',
                  title: 'Planning & Decor',
                  rating: 4.8,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Text(
            'Popular Venue Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink[200],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 160,
            child: ListView(
              controller: _eventScrollController,
              scrollDirection: Axis.horizontal,
              children: const [
                EventCard(
                  imagePath: 'assets/images/venue1.jpg',
                  title: 'Royal Garden',
                  location: 'Delhi,India',
                ),
                EventCard(
                  imagePath: 'assets/images/venue2.jpg',
                  title: 'The Wedding Lawn',
                  location: 'Bangalore',
                ),
                EventCard(
                  imagePath: 'assets/images/venue3.jpg',
                  title: 'Grand Sapphire',
                  location: 'Jaipur',
                ),
                EventCard(
                  imagePath: 'assets/images/venue4.jpg',
                  title: 'Royal Garden',
                  location: 'Delhi,India',
                ),
                EventCard(
                  imagePath: 'assets/images/venue5.jpg',
                  title: 'The Wedding Lawn',
                  location: 'Bangalore',
                ),
                EventCard(
                  imagePath: 'assets/images/venue4.jpg',
                  title: 'Grand Sapphire',
                  location: 'Jaipur',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Service Cards
          Text(
            'Real Wedding Photos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink[200],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                ServiceCard1(
                  imagePath: 'assets/images/wed1.jpg',
                  // title: 'Venue',
                  // rating: 4.8,
                ),
                ServiceCard1(
                  imagePath: 'assets/images/wed2.jpg',
                  // title: 'Virtual Planning',
                  // rating: 4.6,
                ),
                ServiceCard1(
                  imagePath: 'assets/images/wed3.jpg',
                  // title: 'Mehendi Artist',
                  // rating: 4.9,
                ),
                ServiceCard1(
                  imagePath: 'assets/images/wed4.jpg',
                  // title: 'Makeup',
                  // rating: 4.9,
                ),
                ServiceCard1(
                  imagePath: 'assets/images/wed5.jpg',
                  // title: 'Photographers',
                  // rating: 4.8,
                ),
                ServiceCard1(
                  imagePath: 'assets/images/wed6.jpg',
                  // title: 'Planning & Decor',
                  // rating: 4.8,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Plan Your Perfect Day!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w200,
              color: Colors.pink[200],
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
          height: 180,
          child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
          AnimatedFeatureCard(icon: Icons.checklist, label: 'Checklist', onTap: () {}),
          AnimatedFeatureCard(icon: Icons.group, label: 'Guestlist Manager', onTap: () {}),
          AnimatedFeatureCard(icon: Icons.event_available, label: 'Biggest Planner', onTap: () {}),
          ],
          ),
          ),

          const SizedBox(height: 20),
          Text(
            'Wedding Checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink[200],
            ),
          ),
           const SizedBox(height: 10),
          _buildChecklistSection(),

          const SizedBox(height: 20),
          Text(
            'Wedding Ideas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink[200],
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                WeddingIdeaCard(
                  imagePath: 'assets/images/decor1.jpg',
                  tag: '#HaldiDecor',
                  caption: 'Bright yellow haldi setup!',
                ),
                WeddingIdeaCard(
                  imagePath: 'assets/images/bride.jpg',
                  tag: '#BridalEntry',
                  caption: 'Princess style entry with smoke bombs',
                ),
                WeddingIdeaCard(
                  imagePath: 'assets/images/mandap.jpg',
                  tag: '#FloralMandap',
                  caption: 'Mandap under a floral canopy',
                ),
                WeddingIdeaCard(
                  imagePath: 'assets/images/ml.jpg',
                  tag: '#MehndiLook',
                  caption: 'Trendy mehndi outfit ideas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            width: double.infinity,
            child:   OutlinedButton.icon(
              onPressed: () {},

              label:  Text('View all Wedding Ideas >', style: TextStyle(fontSize: 16,color: Colors.pink[200],fontWeight: FontWeight.w600),),
              style: OutlinedButton.styleFrom(

                minimumSize: const Size(double.infinity, 48),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Interesting reads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.pink[200],
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                WeddingIdeaCard(
                  imagePath: 'assets/images/decor1.jpg',
                  tag: '#HaldiDecor',
                  caption: 'Bright yellow haldi setup!',
                ),
                WeddingIdeaCard(
                  imagePath: 'assets/images/bride.jpg',
                  tag: '#BridalEntry',
                  caption: 'Princess style entry with smoke bombs',
                ),
                WeddingIdeaCard(
                  imagePath: 'assets/images/mandap.jpg',
                  tag: '#FloralMandap',
                  caption: 'Mandap under a floral canopy',
                ),
                WeddingIdeaCard(
                  imagePath: 'assets/images/ml.jpg',
                  tag: '#MehndiLook',
                  caption: 'Trendy mehndi outfit ideas',
                ),
              ],
            ),
          ),









        ]
      ),
    );
  }













  Widget _buildChecklistSection() {
    final themeColor = Colors.pink;
    final List<Map<String, dynamic>> checklistItems = [
      {'title': 'Book Venue', 'daysLeft': 180, 'done': false},
      {'title': 'Hire Photographer', 'daysLeft': 150, 'done': false},
      {'title': 'Send Invites', 'daysLeft': 100, 'done': true},
      {'title': 'Buy Outfits', 'daysLeft': 60, 'done': false},
    ];
    final completed = checklistItems.where((item) => item['done'] == true).length;
    final total = checklistItems.length;
    final progress = completed / total;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$completed of $total tasks completed',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade300,
                color: themeColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checklist Cards
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: checklistItems.length,
            itemBuilder: (context, index) {
              final item = checklistItems[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item['done'] ? Colors.green : themeColor,
                    child: Icon(
                      item['done'] ? Icons.check : Icons.favorite_border,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    item['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: item['done'] ? TextDecoration.lineThrough : null,
                      color: item['done'] ? Colors.grey : Colors.black,
                    ),
                  ),
                  subtitle: Text('${item['daysLeft']} days to go'),
                  trailing: Checkbox(
                    value: item['done'],
                    onChanged: (value) {
                      setState(() {
                        checklistItems[index]['done'] = value!;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class WeddingIdeaCard extends StatelessWidget {
  final String imagePath;
  final String tag;
  final String caption;

  const WeddingIdeaCard({
    Key? key,
    required this.imagePath,
    required this.tag,
    required this.caption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,

      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              height: 140,
              width: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tag,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
