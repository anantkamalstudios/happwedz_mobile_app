import 'dart:async';
import 'package:flutter/material.dart';
import 'package:h_w_a/services/category_chip.dart';
import 'package:h_w_a/services/plan.dart';
import 'package:h_w_a/services/rate.dart';

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
  final List<String> weddingImages = [
    'assets/images/wedding1.jpg',
    'assets/images/wedding2.jpg',
    'assets/images/wedding3.jpg',
    'assets/images/wedding4.jpg',
    'assets/images/wedding5.jpg',
    'assets/images/wedding6.jpg',
  ];

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

          Row(
            children: [
              Text(
                'Popular Venue Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[200],
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All >',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink[200],
                  ),
                ),
              ),
            ],
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
          Row(
            children: [
              Text(
                'Real Wedding Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[200],
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WeddingIdeasScreen(initialTabIndex: 0),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All >',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink[200],
                  ),
                ),
              ),
            ],
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
          Row(
            children: [
              Text(
                'Plan Your Perfect Day!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w200,
                  color: Colors.pink[200],
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllFeaturesScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All >',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink[200],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AnimatedFeatureCard(
                  icon: Icons.checklist,
                  label: 'Checklist',
                  onTap: () {},
                ),
                AnimatedFeatureCard(
                  icon: Icons.group,
                  label: 'Guestlist Manager',
                  onTap: () {},
                ),
                AnimatedFeatureCard(
                  icon: Icons.event_available,
                  label: 'Biggest Planner',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // Row(
          //   children: [
          //     Text(
          //       'Wedding Checklist',
          //       style: TextStyle(
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //         color: Colors.pink[200],
          //       ),
          //     ),
          //     Spacer(),
          //     TextButton(
          //       onPressed: () {
          //         // Navigate to real weddings list
          //       },
          //       style: TextButton.styleFrom(
          //         padding: EdgeInsets.zero,
          //         minimumSize: const Size(40, 30),
          //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //       ),
          //       child: Text(
          //         'See All >',
          //         style: TextStyle(
          //           fontSize: 14,
          //           fontWeight: FontWeight.w500,
          //           color: Colors.pink[200],
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          //  const SizedBox(height: 10),
          // _buildChecklistSection(),
          //
          // const SizedBox(height: 20),
          Text(
            'Wedding Story',
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
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        WeddingIdeasScreen(initialTabIndex: 1),
                  ),
                );
              },

              label: Text(
                'View all Wedding Stories >',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.pink[200],
                  fontWeight: FontWeight.w600,
                ),
              ),
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
            height: 310,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                WeddingIdeaCard1(
                  imagePath: 'assets/images/wc1.jpg',
                  caption:
                      'This Bride Turned Her Mom’s Saree Into a Corset Skirt Set & We’re Obsessed!” (Aug 8, 2025): A creative and deeply sentimental bridal outfit idea rooted in tradition.',
                ),
                WeddingIdeaCard1(
                  imagePath: 'assets/images/wc2.jpg',
                  caption:
                      '7 Unique Wedding Themes That We Are Obsessing Over!”: From whimsical MET Gala vibes to location-based themes like a London café—this is inspiration central.',
                ),
                WeddingIdeaCard1(
                  imagePath: 'assets/images/wc3.jpg',
                  caption:
                      '8 Unique Bridal Entry Ideas We Spotted Recently!”: Featuring everything from walking down the aisle with pets to ballet-style veil entrances and a bride arriving in a boat!',
                ),
                WeddingIdeaCard1(
                  imagePath: 'assets/images/wc4.jpg',
                  caption:
                      'Real Wedding Features: Explore authentic stories where real brides reflect on their planning journeys and creative moments. ',
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const WeddingIdeasScreen(initialTabIndex: 3),
                  ),
                );
              },
              label: Text(
                'More Interesting reads >',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.pink[200],
                  fontWeight: FontWeight.w600,
                ),
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Container(
                  //   width: 4,
                  //   height: 20,
                  //   decoration: BoxDecoration(
                  //     color: Colors.pink[200],
                  //     borderRadius: BorderRadius.circular(2),
                  //   ),
                  // ),
                  // const SizedBox(width: 8),
                  Text(
                    'Real Weddings we Love',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.pink[200],
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WeddingIdeasScreen(initialTabIndex: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'See All >',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.pink[200],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 350, // card height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 6, // number of cards
              padding: const EdgeInsets.only(left: 8, right: 8),
              itemBuilder: (context, index) {
                return Container(
                  width: 250, // card width
                  height: 350,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.asset(
                          weddingImages[index],
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Caption
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Beach Wedding in Goa',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Location / Extra info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'Goa, India',
                          style: TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          RateExperienceCard(),
          const SizedBox(height: 20),
        ],
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
    final completed = checklistItems
        .where((item) => item['done'] == true)
        .length;
    final total = checklistItems.length;
    final progress = completed / total;

    return Card(
      color: Colors.pink[50],
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.pink,
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      decoration: item['done']
                          ? TextDecoration.lineThrough
                          : null,
                      color: item['done'] ? Colors.grey : Colors.pink,
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
    super.key,
    required this.imagePath,
    required this.tag,
    required this.caption,
  });

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

class WeddingIdeaCard1 extends StatelessWidget {
  final String imagePath;

  final String caption;

  const WeddingIdeaCard1({
    super.key,
    required this.imagePath,

    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.asset(
                imagePath,
                height: 250,
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            // Text(
            //   tag,
            //   style: TextStyle(
            //     fontSize: 13,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.pinkAccent,
            //   ),
            // ),
            const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class WeddingIdeaCard2 extends StatelessWidget {
  final String imagePath;

  final String caption;

  const WeddingIdeaCard2({
    super.key,
    required this.imagePath,

    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.asset(
                imagePath,
                height: 350,
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            // Text(
            //   tag,
            //   style: TextStyle(
            //     fontSize: 13,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.pinkAccent,
            //   ),
            // ),
            // const SizedBox(height: 4),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class WeddingIdeasScreen extends StatefulWidget {
  final int initialTabIndex; // final is better than late here

  const WeddingIdeasScreen({
    super.key,
    this.initialTabIndex = 0, // default value: Photos tab
  });

  @override
  _WeddingIdeasScreenState createState() => _WeddingIdeasScreenState();
}

class _WeddingIdeasScreenState extends State<WeddingIdeasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> storyImages = [
    'assets/images/wed1.jpg',
    'assets/images/wed2.jpg',
    'assets/images/wed3.jpg',
    'assets/images/wed4.jpg',
    'assets/images/wed5.jpg',
    'assets/images/wed6.jpg',
  ];
  final List<String> weddingStoryImages = [
    'assets/images/decor1.jpg',
    'assets/images/bride.jpg',
    'assets/images/mandap.jpg',
    'assets/images/ml.jpg',
  ];

  final List<String> weddingStoryTitles = [
    'Bright yellow haldi setup!',
    'Princess style entry with smoke bombs',
    'Mandap under a floral canopy',
    'Trendy mehndi outfit ideas',
  ];

  final List<String> weddingStoryImages1 = [
        'assets/images/wc1.jpg'
        'assets/images/wc2.jpg',
        'assets/images/wc3.jpg',
         'assets/images/wc4.jpg',
  ];

  final List<String> weddingStoryTitles1 = [
    'This Bride Turned Her Mom’s Saree Into a Corset Skirt Set & We’re Obsessed!” (Aug 8, 2025): A creative and deeply sentimental bridal outfit idea rooted in tradition.',
    '7 Unique Wedding Themes That We Are Obsessing Over!”: From whimsical MET Gala vibes to location-based themes like a London café—this is inspiration central.',
    '8 Unique Bridal Entry Ideas We Spotted Recently!”: Featuring everything from walking down the aisle with pets to ballet-style veil entrances and a bride arriving in a boat!',
    'Real Wedding Features: Explore authentic stories where real brides reflect on their planning journeys and creative moments. ',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: Colors.white,
          title: Text(
            "Wedding Ideas",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.pink,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: Colors.grey[700]),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.filter_list, color: Colors.grey[700]),
              onPressed: () {},
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.pink[400],
            labelColor: Colors.pink[400],
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(text: "Photos"),
              Tab(text: "Stories"),
              Tab(text: "Real Weddings"),
              Tab(text: "Reads"),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Photos tab
            GridView.builder(
              padding: EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: storyImages.length,

              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        storyImages[index % storyImages.length],
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),

                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: IconButton(
                          icon: Icon(
                            Icons.thumb_up_alt_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Stories tab
            ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          weddingStoryImages[index], // use a list of real images
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          weddingStoryTitles[index], // use matching captions
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Real Weddings tab
            ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.asset(
                          "assets/images/wedding${(index % 2) + 1}.jpg",
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Aditi & Rohan - Jaipur, Rajasthan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Stories tab (WedMeGood-style)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal scrollable avatars
                // Container(
                //   height: 100,
                //   padding: const EdgeInsets.symmetric(vertical: 8),
                //   child: ListView.builder(
                //     scrollDirection: Axis.horizontal,
                //     itemCount: storyImages.length,
                //     itemBuilder: (context, i) {
                //       return Padding(
                //         padding: const EdgeInsets.symmetric(horizontal: 8),
                //         child: Column(
                //           children: [
                //             CircleAvatar(
                //               radius: 35,
                //               backgroundImage: AssetImage(storyImages[i]),
                //             ),
                //             const SizedBox(height: 6),
                //             Text(
                //               'Story ${i + 1}',
                //               style: TextStyle(
                //                 fontSize: 12,
                //                 color: Colors.grey[700],
                //               ),
                //             ),
                //           ],
                //         ),
                //       );
                //     },
                //   ),
                // ),
                // const SizedBox(height: 10),

                // Vertical feed
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: weddingStoryImages.length,
                    itemBuilder: (context, idx) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.asset(
                                weddingStoryImages1[idx],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                weddingStoryTitles1[idx],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
