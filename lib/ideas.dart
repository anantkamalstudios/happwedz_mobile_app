import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import 'RealWedding/share_ur_story.dart';

class Ideas extends StatefulWidget {
  final int initialSubTabIndex; // 👈 add this

  Ideas({this.initialSubTabIndex = 0}); // default to 0 (Photos)

  @override
  _IdeasState createState() => _IdeasState();
}


class _IdeasState extends State<Ideas> with TickerProviderStateMixin {


  late int _selectedSubTabIndex;
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _storiesFuture;
  final TextEditingController searchController = TextEditingController();

  List<dynamic> allPhotos = [];
  List<dynamic> filteredPhotos = [];

  List<dynamic> allStories = [];
  List<dynamic> filteredStories = [];

  List<dynamic> allWeddings = [];
  List<dynamic> filteredWeddings = [];

  final List<String> _subTabs = ['Photos', 'Stories', 'Real Weddings'];

  @override
  void initState() {
    super.initState();
    _selectedSubTabIndex = widget.initialSubTabIndex; // 👈 set selected tab
    _tabController = TabController(
      length: _subTabs.length,
      vsync: this,
      initialIndex: widget.initialSubTabIndex, // 👈 set controller to same index
      // _tabController = TabController(length: 3, vsync: this);
    );
    _tabController.addListener(() {
      setState(() {}); // 👈 rebuilds when switching tabs
    });

    _storiesFuture = fetchStories();
  }
// Fetch stories from API
  Future<List<Map<String, dynamic>>> fetchStories() async {
    final response = await http.get(Uri.parse('https://happywedz.com/api/blogs/all'));
    print(response);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final Map<String, dynamic> decodedJson = json.decode(response.body);
      final List<dynamic> dataList = decodedJson['data'];
      return dataList.cast<Map<String, dynamic>>().toList();
    } else {
      throw Exception('Failed to load stories');
    }
  }
// Helper for full image URL
  String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/300x200.png';
    }
    return 'https://happywedz.com$path';
  }

  Future<List<RealWedding>> fetchRealWeddings() async {
    final response = await http.get(
      Uri.parse('https://happywedz.com/api/realwedding/public'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      // Safely check for key existence and null
      final List<dynamic>? data = decoded['weddings'];

      if (data == null) {
        throw Exception('No weddings found in response');
      }

      return data.map((json) => RealWedding.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load real weddings');
    }
  }

  Future<void> debugImageUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      print("HEAD $url -> ${response.statusCode}, Content-Type: ${response.headers['content-type']}");
    } catch (e) {
      print("HEAD $url failed: $e");
    }
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Widget _buildStoryCardImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
      ),
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main Tab Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTab('Ideas', true),
                  ],
                ),
              ),

              // Sub-tabs
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < _subTabs.length; i++)
                      GestureDetector(
                        onTap: () => _onSubTabTapped(i),
                        child: _buildSubTab(_subTabs[i], _selectedSubTabIndex == i),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Search Bar
              _buildSearchBar(),

              SizedBox(height: 20),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPhotosTab(),
                    _buildStoriesTab(),
                    _buildRealWeddingsTab(),
                  ],
                ),


              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(),

      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShareWeddingStory(),
            ),
          );
        },
        child: const Icon(Icons.add),
      )
          : null,


    );
  }

  void _onSubTabTapped(int index) {
    setState(() {
      _selectedSubTabIndex = index;
    });
    _tabController.animateTo(index);
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubTab(String title, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Color(0xFFE91E63) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Color(0xFFE91E63) : Colors.grey[600],
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  void _handleSearch(String query) {
    query = query.toLowerCase().trim();

    setState(() {
      if (_selectedSubTabIndex == 0) {
        filteredPhotos = allPhotos.where((photo) {
          return (photo['title'] ?? '').toString().toLowerCase().contains(query);
        }).toList();
      }
      else if (_selectedSubTabIndex == 1) {
        filteredStories = allStories.where((story) {
          return (story['title'] ?? '').toString().toLowerCase().contains(query);
        }).toList();
      }
      else {
        // <--- Search EVERYTHING inside each RealWedding
        filteredWeddings = allWeddings.where((wedding) {
          return wedding.toSearchString().contains(query);
        }).toList();
      }
    });
  }


  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14),
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3), // ↓ smaller height
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16), // ↓ smaller radius
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[400], size: 14), // ↓ smaller icon
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (value) => _handleSearch(value),
              style: TextStyle(fontSize: 12), // ↓ smaller text
              decoration: InputDecoration(
                hintText: _selectedSubTabIndex == 0
                    ? 'Search Photos...'
                    : _selectedSubTabIndex == 1
                    ? 'Search Stories...'
                    : 'Search Real Weddings...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14, // ↓ smaller hint text
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Photos Tab Content
  Widget _buildPhotosTab() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return _buildPhotoCard(index);
      },
    );
  }

  Widget _buildPhotoCard(int index) {
    final List<String> photoUrls = [
      'https://images.unsplash.com/photo-1594736797933-d0701ba0c4bb?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1606800052052-a08af7148866?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=400&h=300&fit=crop',
      'https://images.unsplash.com/photo-1469371670807-013ccf25f16a?w=400&h=300&fit=crop',
    ];

    final List<String> photoTitles = [
      'Bridal Lehenga',
      'Wedding Decor',
      'Mehendi Design',
      'Wedding Jewelry',
      'Bridal Makeup',
      'Groom Outfit',
      'Wedding Flowers',
      'Reception Decor',
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(photoUrls[index % photoUrls.length]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Text(
                  photoTitles[index % photoTitles.length],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Refactored Stories Tab
  Widget _buildStoriesTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _storiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return Center(child: Text('No Stories Found'));

        final stories = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];

            final title = story['title'] ?? 'No Title';
            final date = formatDate(story['postDate'] ?? '');
            final desc = story['shortDescription'] ?? '';
            final author = story['author'] ?? 'HappyWedz';
            final category = story['category']?['name'] ?? 'Stories';

            final imageUrl = story['image']?.toString().isNotEmpty == true
                ? story['image']
                : "https://via.placeholder.com/400x200.png?text=${title.replaceAll(' ', '+')}";

            return Column(
              children: [
                _buildStoryCard(
                  title,
                  date,
                  desc,
                  imageUrl,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlogDetailPage(
                          title: title,
                          date: date,
                          author: author,
                          image: imageUrl,
                          content: desc,
                          category: category,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

//   Widget _buildStoriesTab() {
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: _storiesFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting)
//           return Center(child: CircularProgressIndicator());
//         if (snapshot.hasError)
//           return Center(child: Text('Error: ${snapshot.error}'));
//         if (!snapshot.hasData || snapshot.data!.isEmpty)
//           return Center(child: Text('No categories found'));
//
//         final stories = snapshot.data!;
//
//         return ListView.builder(
//           padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           itemCount: stories.length,
//           itemBuilder: (context, index) {
//             final story = stories[index];
//
//             final title = story['name'] ?? 'No Title';
//             final date = formatDate(story['createdDate'] ?? '');
//             final desc = story['description'] ?? '';
//             final imageUrl = "https://via.placeholder.com/400x200.png?text=${title.replaceAll(' ', '+')}";
//
//             return Column(
//               children: [
//                 _buildStoryCard(title, date, desc, imageUrl, () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => BlogDetailPage(
//                         title: title,
//                         date: date,
//                         readTime: "5 min read",
//                         images: [imageUrl],
//                         content: desc,
//                       ),
//                     ),
//                   );
//                 }),
//                 SizedBox(height: 16),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

  Widget _buildRealWeddingsTab() {
    return FutureBuilder<List<RealWedding>>(
      future: fetchRealWeddings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No weddings found'));
        }

        final weddings = snapshot.data!;

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: weddings.length,
          separatorBuilder: (_, __) => SizedBox(height: 16),
          itemBuilder: (context, index) {
            final wedding = weddings[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RealWeddingDetailPage(wedding: wedding),
                  ),
                );
              },
              child: _buildRealWeddingCardPreview(wedding),
            );
          },
        );
      },
    );
  }

  Widget _buildStoryCard(String title, String date, String description, String imageUrl, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealWeddingCardPreview(RealWedding wedding) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: wedding.coverPhoto != null
                ? Image.network(
              wedding.coverPhoto!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, size: 50),
              ),
            )
                : Container(
              height: 180,
              color: Colors.grey[300],
              child: Icon(Icons.image, size: 50),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  wedding.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),

                // City & Date
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Color(0xFFE91E63)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        wedding.city,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.event, size: 16, color: Color(0xFFE91E63)),
                    SizedBox(width: 4),
                    Text(
                      wedding.weddingDate,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Themes as chips
                if (wedding.themes.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: wedding.themes
                        .map((theme) => Chip(
                      label: Text(theme, style: TextStyle(fontSize: 12)),
                      backgroundColor: Colors.pink.shade50,
                      labelStyle: TextStyle(color: Color(0xFFE91E63)),
                      visualDensity: VisualDensity.compact,
                    ))
                        .toList(),
                  ),

                // Featured label (optional)
                if (wedding.featured)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Featured",
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialStoryCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=400&h=100&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.home, 'Home', true),
          _buildBottomNavItem(Icons.shopping_bag_outlined, 'Venues', false),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE91E63).withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
          _buildBottomNavItem(Icons.groups_outlined, 'Vendors', false),
          _buildBottomNavItem(Icons.menu, 'More', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 8),
        Icon(
          icon,
          color: isSelected ? Color(0xFFE91E63) : Colors.grey[400],
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Color(0xFFE91E63) : Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  // void _navigateToBlogPage(
  //     String title,
  //     String date,
  //     String readTime,
  //     List<String> images,
  //     String content,
  //     ) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => BlogDetailPage(
  //         title: title,
  //         date: date,
  //         readTime: readTime,
  //         images: images,
  //         content: content,
  //       ),
  //     ),
  //   );
  // }


}

class BlogDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final String author;
  final String image;
  final String content;
  final String category;

  const BlogDetailPage({
    Key? key,
    required this.title,
    required this.date,
    required this.author,
    required this.image,
    required this.content,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [

          // ---------------------------------------------------
          // PREMIUM HEADER (Image + Overlay + Back Button)
          // ---------------------------------------------------
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // IMAGE
                  Hero(
                    tag: image,
                    child: Image.network(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // GRADIENT OVERLAY
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------
          // BODY CONTENT
          // ---------------------------------------------------
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // CATEGORY TAG
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.5,
                        color: Colors.pink.shade400,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // TITLE
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AUTHOR + DATE
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.pink.shade100,
                        child: Icon(Icons.person, size: 20, color: Colors.pink.shade600),
                      ),
                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // CONTENT
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.8,
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RealWeddingDetailPage extends StatelessWidget {
  final RealWedding wedding;

  const RealWeddingDetailPage({required this.wedding, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Collapsing Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.pink,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                wedding.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              background: Hero(
                tag: wedding.coverPhoto ?? "",
                child: Image.network(
                  wedding.coverPhoto ?? "",
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  _sectionTitle("Wedding Details"),
                  _infoCard([
                    _infoRow(Icons.location_on, "City", wedding.city),
                    _infoRow(Icons.calendar_month, "Wedding Date", wedding.weddingDate),
                  ]),

                  if (wedding.venues.isNotEmpty) ...[
                    _sectionTitle("Venue"),
                    Wrap(
                      spacing: 8,
                      children:
                      wedding.venues.map((v) => Chip(label: Text(v))).toList(),
                    ),
                  ],

                  _sectionTitle("Bride"),
                  _infoCard([
                    _infoRow(Icons.female, "Name", wedding.brideName),
                    _textBlock(wedding.brideBio),
                  ]),

                  _sectionTitle("Groom"),
                  _infoCard([
                    _infoRow(Icons.male, "Name", wedding.groomName),
                    _textBlock(wedding.groomBio),
                  ]),

                  if (wedding.story.isNotEmpty) ...[
                    _sectionTitle("Their Story"),
                    _textBlock(wedding.story.replaceAll(RegExp(r'<[^>]*>'), "")),
                  ],

                  if (wedding.events.isNotEmpty) ...[
                    _sectionTitle("Wedding Events"),
                    Column(
                      children: wedding.events.map((e) {
                        return _timelineTile(
                          title: e['name'] ?? "",
                          date: e['date'] ?? "",
                          venue: e['venue'] ?? "",
                        );
                      }).toList(),
                    )
                  ],

                  if (wedding.vendors.isNotEmpty) ...[
                    _sectionTitle("Vendors"),
                    Wrap(
                      spacing: 10,
                      children: wedding.vendors.map((v) {
                        return Chip(label: Text("${v['type']}: ${v['name']}"));
                      }).toList(),
                    )
                  ],

                  if (wedding.themes.isNotEmpty) ...[
                    _sectionTitle("Themes"),
                    Wrap(
                      spacing: 8,
                      children: wedding.themes.map((t) => Chip(label: Text(t))).toList(),
                    ),
                  ],

                  _sectionTitle("Special Moments"),
                  _textBlock(wedding.specialMoments),

                  _sectionTitle("Outfits"),
                  _infoCard([
                    _infoRow(Icons.favorite, "Bride Outfit", wedding.brideOutfit),
                    _infoRow(Icons.favorite, "Groom Outfit", wedding.groomOutfit),
                  ]),

                  _sectionTitle("Gallery"),
                  _pinterestGallery(wedding.allPhotos, context),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Widgets ---

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 6),
    child: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _textBlock(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.5),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.pink),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _timelineTile({required String title, required String date, required String venue}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.pink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("$date at $venue",
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinterestGallery(List<String> images, BuildContext context) {
    return MasonryGridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenGallery(images: images, index: index),
            ),
          ),
          child: Hero(
            tag: "img_$index",
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}




class FullScreenGallery extends StatelessWidget {
  final List<String> images;
  final int index;

  const FullScreenGallery({required this.images, required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: index),
            builder: (context, i) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(images[i]),
                heroAttributes: PhotoViewHeroAttributes(tag: "img_$i"),
              );
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          )
        ],
      ),
    );
  }
}
// class RealWeddingDetailPage extends StatelessWidget {
//   final RealWedding wedding;
//
//   const RealWeddingDetailPage({required this.wedding, super.key, });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(wedding.title),
//         backgroundColor: Color(0xFFE91E63),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Cover Photo
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: wedding.coverPhoto != null
//                   ? Image.network(
//                 wedding.coverPhoto!,
//                 width: double.infinity,
//                 height: 220,
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) => Container(
//                   width: double.infinity,
//                   height: 220,
//                   color: Colors.grey[300],
//                   child: Icon(Icons.broken_image, size: 50),
//                 ),
//               )
//                   : Container(
//                 width: double.infinity,
//                 height: 220,
//                 color: Colors.grey[300],
//                 child: Icon(Icons.image, size: 50),
//               ),
//             ),
//             SizedBox(height: 16),
//
//             // Basic Info
//             Text(wedding.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             SizedBox(height: 8),
//             Text('City: ${wedding.city}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//             Text('Wedding Date: ${wedding.weddingDate}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
//             SizedBox(height: 12),
//
//             // Venues
//             if (wedding.venues.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Venues:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   Wrap(
//                     spacing: 8,
//                     children: wedding.venues.map((v) => Chip(label: Text(v))).toList(),
//                   ),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // Bride & Groom Info
//             Text('Bride: ${wedding.brideName}', style: TextStyle(fontWeight: FontWeight.w600)),
//             Text(wedding.brideBio),
//             SizedBox(height: 8),
//             Text('Groom: ${wedding.groomName}', style: TextStyle(fontWeight: FontWeight.w600)),
//             Text(wedding.groomBio),
//             SizedBox(height: 12),
//
//             // Story
//             if (wedding.story.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Story:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   Text(wedding.story),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // Events
//             if (wedding.events.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Events:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   ...wedding.events.map((e) => Text('${e['date']} - ${e['name']} at ${e['venue']}')),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // Vendors
//             if (wedding.vendors.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Vendors:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   ...wedding.vendors.map((v) => Text('${v['type']}: ${v['name']}')),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // Themes
//             if (wedding.themes.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Themes:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   Wrap(
//                     spacing: 8,
//                     children: wedding.themes.map((t) => Chip(label: Text(t))).toList(),
//                   ),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // Outfits, special moments, photographer, makeup, decor
//             Text('Bride Outfit: ${wedding.brideOutfit}'),
//             Text('Groom Outfit: ${wedding.groomOutfit}'),
//             Text('Special Moments: ${wedding.specialMoments}'),
//             Text('Photographer: ${wedding.photographer}'),
//             Text('Makeup: ${wedding.makeup}'),
//             Text('Decor: ${wedding.decor}'),
//             SizedBox(height: 12),
//
//             // Additional Credits
//             if (wedding.additionalCredits.isNotEmpty)
//               Text('Credits: ${wedding.additionalCredits.join(', ')}'),
//
//             SizedBox(height: 16),
//
//             // Highlight Photos
//             if (wedding.highlightPhotos.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('Highlight Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   SizedBox(height: 8),
//                   SizedBox(
//                     height: 120,
//                     child: ListView.separated(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: wedding.highlightPhotos.length,
//                       separatorBuilder: (_, __) => SizedBox(width: 8),
//                       itemBuilder: (context, index) => ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           wedding.highlightPhotos[index],
//                           width: 120,
//                           height: 120,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => Container(
//                             width: 120,
//                             height: 120,
//                             color: Colors.grey[300],
//                             child: Icon(Icons.broken_image),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // All Photos
//             if (wedding.allPhotos.isNotEmpty)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text('All Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
//                   SizedBox(height: 8),
//                   SizedBox(
//                     height: 120,
//                     child: ListView.separated(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: wedding.allPhotos.length,
//                       separatorBuilder: (_, __) => SizedBox(width: 8),
//                       itemBuilder: (context, index) => ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           wedding.allPhotos[index],
//                           width: 120,
//                           height: 120,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) => Container(
//                             width: 120,
//                             height: 120,
//                             color: Colors.grey[300],
//                             child: Icon(Icons.broken_image),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 12),
//                 ],
//               ),
//
//             // Created & Updated Dates
//             Text('Created At: ${wedding.createdAt.toLocal().toString().split(' ')[0]}',
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//             Text('Updated At: ${wedding.updatedAt.toLocal().toString().split(' ')[0]}',
//                 style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//           ],
//         ),
//       ),
//     );
//   }
// }
//

class RealWedding {
  final int id;
  final String title;
  final String slug;
  final String weddingDate;
  final String city;
  final List<String> venues;
  final String brideName;
  final String brideBio;
  final String groomName;
  final String groomBio;
  final String story;
  final List<Map<String, String>> events;
  final List<Map<String, String>> vendors;
  final String? coverPhoto;
  final List<String> highlightPhotos;
  final List<String> allPhotos;
  final List<String> themes;
  final String brideOutfit;
  final String groomOutfit;
  final String specialMoments;
  final String photographer;
  final String makeup;
  final String decor;
  final List<String> additionalCredits;
  final String status;
  final bool featured;
  final int userId;
  final String userEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  RealWedding({
    required this.id,
    required this.title,
    required this.slug,
    required this.weddingDate,
    required this.city,
    required this.venues,
    required this.brideName,
    required this.brideBio,
    required this.groomName,
    required this.groomBio,
    required this.story,
    required this.events,
    required this.vendors,
    this.coverPhoto,
    required this.highlightPhotos,
    required this.allPhotos,
    required this.themes,
    required this.brideOutfit,
    required this.groomOutfit,
    required this.specialMoments,
    required this.photographer,
    required this.makeup,
    required this.decor,
    required this.additionalCredits,
    required this.status,
    required this.featured,
    required this.userId,
    required this.userEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RealWedding.fromJson(Map<String, dynamic> json) {
    // Helper to safely decode stringified JSON lists
    List<String> parseStringOrList(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return List<String>.from(decoded.map((e) => e.toString()));
          } else {
            return [value];
          }
        } catch (_) {
          return [value];
        }
      } else if (value is List) {
        return List<String>.from(value.map((e) => e.toString()));
      }
      return [];
    }

    // Helper for list of maps (events/vendors)
    List<Map<String, String>> parseListOfMaps(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => Map<String, String>.from(e)).toList();
          }
        } catch (_) {}
        return [];
      } else if (value is List) {
        return value.map((e) => Map<String, String>.from(e)).toList();
      }
      return [];
    }

    return RealWedding(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      weddingDate: json['wedding_date'] ?? '',
      city: json['city'] ?? '',
      venues: parseStringOrList(json['venues']),
      brideName: json['bride_name'] ?? '',
      brideBio: json['bride_bio'] ?? '',
      groomName: json['groom_name'] ?? '',
      groomBio: json['groom_bio'] ?? '',
      story: json['story'] ?? '',
      events: parseListOfMaps(json['events']),
      vendors: parseListOfMaps(json['vendors']),
      // coverPhoto: json['cover_photo'] != null
      //     ? "https://happywedz.com${json['cover_photo']}"
      //     : null,
      // highlightPhotos: parseStringOrList(json['highlight_photos'])
      //     .map((e) => "https://happywedz.com$e")
      //     .toList(),
      // allPhotos: parseStringOrList(json['all_photos'])
      //     .map((e) => "https://happywedz.com$e")
      //     .toList(),

      // ✅ FIXED — use URL directly (API already gives full URL)
      coverPhoto: json['cover_photo'],

      // ✅ FIXED — no prefix added
      highlightPhotos: parseStringOrList(json['highlight_photos']),

      // ✅ FIXED — no prefix added
      allPhotos: parseStringOrList(json['all_photos']),
      themes: parseStringOrList(json['themes']),
      brideOutfit: json['bride_outfit'] ?? '',
      groomOutfit: json['groom_outfit'] ?? '',
      specialMoments: json['special_moments'] ?? '',
      photographer: json['photographer'] ?? '',
      makeup: json['makeup'] ?? '',
      decor: json['decor'] ?? '',
      additionalCredits: parseStringOrList(json['additional_credits']),
      status: json['status'] ?? '',
      featured: json['featured'] ?? false,
      userId: json['user_id'] ?? 0,
      userEmail: json['user_email'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

}


