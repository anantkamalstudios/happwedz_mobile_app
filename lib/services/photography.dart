import 'package:flutter/material.dart';

class PhotographyScreen extends StatefulWidget {
  const PhotographyScreen({super.key});

  @override
  State<PhotographyScreen> createState() => _PhotographyScreenState();
}

class _PhotographyScreenState extends State<PhotographyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
        },
        icon: const Icon(Icons.phone),
        label: const Text("Request Callback"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    "assets/images/photography.webp",
                    fit: BoxFit.cover,
                  ),
                  Container(color: Colors.black.withOpacity(0.3)),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage("assets/images/photographer_profile.webp"),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Dream Wedding Photography",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Mumbai, India",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: const [
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            SizedBox(width: 4),
                            Text("4.9", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.pinkAccent,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.pinkAccent,
                      tabs: const [
                        Tab(text: "Portfolio"),
                        Tab(text: "Reviews"),
                        Tab(text: "About"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPortfolioTab(),
            _buildReviewsTab(),
            _buildAboutTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTab() {
    List<String> portfolioImages = [
      "assets/images/ph1.webp",
      "assets/images/ph2.webp",
      "assets/images/ph3.webp",
      "assets/images/ph4.webp",
      "assets/images/ph5.webp",
      "assets/images/ph6.webp",
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: portfolioImages.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(portfolioImages[index], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage("assets/images/user_profile.webp"),
            ),
            title: const Text("Priya Sharma"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 4),
                Text(
                  "Amazing work! Very professional and creative. Highly recommended.",
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star_half, size: 16, color: Colors.amber),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dream Wedding Photography is a team of passionate photographers specializing in weddings, pre-weddings, and candid photography. Our mission is to capture your most precious moments beautifully and creatively.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Handle phone call
                },
                icon: const Icon(Icons.phone, color: Colors.blue),
              ),
              IconButton(
                onPressed: () {
                  // TODO: Handle WhatsApp
                },
                icon:Image.asset(
                  'assets/images/whatsapp_icon.webp',
                  height: 30,
                  width: 30,

                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
