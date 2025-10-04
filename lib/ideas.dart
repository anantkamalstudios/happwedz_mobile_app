import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  final List<String> _subTabs = ['Photos', 'Stories', 'Real Weddings'];

  @override
  void initState() {
    super.initState();
    _selectedSubTabIndex = widget.initialSubTabIndex; // 👈 set selected tab
    _tabController = TabController(
      length: _subTabs.length,
      vsync: this,
      initialIndex: widget.initialSubTabIndex, // 👈 set controller to same index
    );
    _storiesFuture = fetchStories();
  }
// Fetch stories from API
  Future<List<Map<String, dynamic>>> fetchStories() async {
    final response = await http.get(Uri.parse('https://happywedz.com/api/blog-deatils/all'));

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
    final response = await http.get(Uri.parse('https://happywedz.com/api/realwedding'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      print(data);
      print(response);
      print(response.body);
      return data.map((json) => RealWedding.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load real weddings');
    }
  }

  // String getFullImageUrl(String? path) {
  //   if (path == null || path.isEmpty) {
  //     return 'https://via.placeholder.com/300x200.png'; // fallback
  //   }
  //
  //   print('Path: $path');
  //
  //   // Already a full URL
  //   if (path.startsWith('http')) {
  //     return path;
  //   }
  //
  //   // Attach domain only
  //   return 'https://happywedz.com${path.startsWith('/') ? '' : '/'}$path';
  //
  // }
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

  // void _onSubTabTapped(int index) {
  //   setState(() {
  //     _selectedSubTabIndex = index;
  //     _tabController.animateTo(index);
  //   });
  // }
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

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.grey[400], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: _selectedSubTabIndex == 0
                    ? 'Search Photos...'
                    : _selectedSubTabIndex == 1
                    ? 'Search Stories...'
                    : 'Search Real Weddings...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
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
          return Center(child: Text('No stories found'));

        final stories = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            final title = story['title'] ?? 'No Title';
            final imageUrl = story['image'] ?? '';
            final postDate = formatDate(story['postDate'] ?? '');
            final blogId = story['id']; // 👈 make sure this matches your API

            return Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    print('Story tapped with blogId: $blogId');
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final fullBlog = await fetchBlogDetail(blogId);
                      print('Fetched blog detail: ${fullBlog['title']}');
                      Navigator.pop(context); // remove loading dialog

                      _navigateToBlogPage(
                        fullBlog['title'],
                        formatDate(fullBlog['date']),
                        fullBlog['readTime'],
                        fullBlog['images'],
                        fullBlog['content'],
                      );
                    } catch (e) {
                      Navigator.pop(context);
                      print('Failed to load blog detail: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to load blog: $e')),
                      );
                    }
                  },
                  child: _buildStoryCard(title, postDate, '5 min read', imageUrl, () {}),
                ),
                SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }





  // Widget _buildStoriesTab() {
  //   return ListView(
  //     padding: EdgeInsets.symmetric(horizontal: 16),
  //     children: [
  //       _buildStoryCard(
  //         'Bridal busaj we\'re crushing on! outfits & Accessories That deserve a spot in your.',
  //         '10 Sep 2025',
  //         '2min read',
  //         'https://images.unsplash.com/photo-1594736797933-d0701ba0c4bb?w=400&h=180&fit=crop',
  //             () => _navigateToBlogPage(
  //           'Bridal busaj we\'re crushing on! outfits & Accessories That deserve a spot in your.',
  //           '10 Sep 2025',
  //           '2min read',
  //           'https://images.unsplash.com/photo-1594736797933-d0701ba0c4bb?w=400&h=180&fit=crop',
  //           _getBridalBusajContent(),
  //         ),
  //       ),
  //       SizedBox(height: 16),
  //       _buildStoryCard(
  //         'Top 10 Wedding Photography Poses Every Couple Should Try',
  //         '8 Sep 2025',
  //         '3min read',
  //         'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=400&h=180&fit=crop',
  //             () => _navigateToBlogPage(
  //           'Top 10 Wedding Photography Poses Every Couple Should Try',
  //           '8 Sep 2025',
  //           '3min read',
  //           'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=400&h=180&fit=crop',
  //           _getPhotographyContent(),
  //         ),
  //       ),
  //       SizedBox(height: 16),
  //       _buildStoryCard(
  //         'Modern Mehendi Designs That Are Trending This Season',
  //         '5 Sep 2025',
  //         '4min read',
  //         'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400&h=180&fit=crop',
  //             () => _navigateToBlogPage(
  //           'Modern Mehendi Designs That Are Trending This Season',
  //           '5 Sep 2025',
  //           '4min read',
  //           'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?w=400&h=180&fit=crop',
  //           _getMehendiContent(),
  //         ),
  //       ),
  //       SizedBox(height: 16),
  //       _buildPartialStoryCard(),
  //     ],
  //   );
  // }
  // Real Weddings Tab Content
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

  Widget _buildStoryCard(String title, String date, String readTime, String imageUrl, VoidCallback onTap) {
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

  void _navigateToBlogPage(
      String title,
      String date,
      String readTime,
      List<String> images,
      String content,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlogDetailPage(
          title: title,
          date: date,
          readTime: readTime,
          images: images,
          content: content,
        ),
      ),
    );
  }

// Content methods for different articles
  String _getBridalBusajContent() {
    return """
Wedding season is upon us, and brides are looking for that perfect blend of tradition and contemporary style. This season's bridal busaj trends are all about making a statement while honoring cultural heritage.

**The New Age Bridal Busaj**

Modern brides are gravitating towards busaj designs that offer versatility and comfort without compromising on elegance. The latest trends showcase:

• **Rich Textures**: Velvet, silk, and brocade fabrics are making a comeback
• **Contemporary Cuts**: A-line silhouettes with modern tailoring
• **Subtle Embellishments**: Delicate beadwork and thread embroidery

**Color Palette Trends**

This season, we're seeing a shift from traditional reds to:
- Deep burgundy and wine shades
- Emerald green with gold accents  
- Royal blue with silver detailing
- Blush pink with rose gold elements

**Styling Tips**

To complete your bridal busaj look:

1. **Jewelry**: Opt for statement pieces that complement the outfit's neckline
2. **Footwear**: Choose comfortable heels that match the color scheme
3. **Dupatta**: Experiment with different draping styles
4. **Hair & Makeup**: Keep it elegant and timeless

**Where to Shop**

Popular designers are showcasing their latest collections at bridal exhibitions across major cities. Don't miss out on the exclusive pieces that are flying off the racks!

Remember, your wedding day is about feeling confident and beautiful in your own skin. Choose a busaj that reflects your personality and makes you feel like the best version of yourself.
""";
  }

  String _getPhotographyContent() {
    return """
Your wedding photos will be treasured for generations, so getting the perfect shots is crucial. Here are the top 10 poses that every couple should consider for their special day.

**1. The Classic First Look**
Capture the raw emotion when the groom sees his bride for the first time. This intimate moment creates some of the most genuine expressions.

**2. Walking Hand in Hand**
A candid shot of you both walking together, laughing and enjoying each other's company. Perfect for showing your natural chemistry.

**3. The Dip Kiss**
A romantic pose where the groom dips the bride for a passionate kiss. It's dramatic and shows the romance between you two.

**4. Forehead Touch**
An intimate pose where you both close your eyes and touch foreheads. It conveys deep connection and tenderness.

**5. The Lift**
The groom lifts the bride off the ground in a joyful embrace. Great for showing celebration and happiness.

**6. Silhouette Against Sunset**
Create a dramatic silhouette shot during golden hour. The lighting creates a magical, dreamy atmosphere.

**7. Detail Shots of Hands**
Focus on your intertwined hands showing off the wedding rings. These detail shots are perfect for close-up memories.

**8. The Veil Shot**
Use the bride's veil as a prop to create movement and drama in the photos. Wind can create beautiful flowing effects.

**9. Candid Laughter**
Nothing beats genuine laughter and joy. These unposed moments often become the most cherished photos.

**10. The Exit Shot**
Capture your grand exit with sparklers, petals, or bubbles. It's a perfect way to end your photo session.

**Pro Tips:**
- Practice poses beforehand to feel more natural
- Trust your photographer's guidance
- Focus on each other, not the camera
- Have fun and let your personalities shine through

Remember, the best wedding photos capture authentic emotions and genuine moments between you and your partner.
""";
  }

  String _getMehendiContent() {
    return """
Mehendi ceremony is one of the most anticipated pre-wedding functions, and choosing the right design can make all the difference. This season brings fresh, contemporary patterns that blend tradition with modern aesthetics.

**Trending Mehendi Styles**

**Minimalist Patterns**
Less is more this season. Brides are opting for:
- Simple geometric patterns
- Delicate finger designs  
- Single motif on palms
- Clean, uncluttered look

**Floral Contemporary**
Modern floral designs featuring:
- Rose patterns with leaves
- Lotus motifs with modern twists  
- Vine patterns extending up the arm
- Mixed flower bouquets design

**Bridal Portraits**
A unique trend where:
- Groom's face is incorporated in the design
- Couple silhouettes on palms
- Wedding venue sketches
- Meaningful symbols and dates

**Arabic Fusion**
Combining Arabic and Indian styles:
- Bold, flowing patterns
- Negative space usage
- Geometric elements
- Less dense, more artistic

**Color Variations**
Beyond traditional brown henna:
- White henna for contrast
- Gold glitter accents
- Colored henna in red and black
- Metallic temporary tattoos mixed in

**Application Tips**

**Before Application:**
- Exfoliate hands and feet
- Avoid moisturizer on the day
- Keep hands clean and dry
- Choose comfortable clothing

**During Application:**
- Stay still and relaxed
- Keep the area warm
- Don't touch or smudge
- Take breaks if needed

**After Care:**
- Let it dry completely (2-4 hours)
- Apply lemon-sugar mixture
- Avoid water for 12 hours
- Use natural oils to maintain color

**Choosing Your Artist**
- Check portfolios and reviews
- Book well in advance
- Discuss design preferences
- Do a patch test for allergies

**Popular Motifs This Season:**
- Mandala patterns
- Peacock designs
- Heart shapes
- Infinity symbols
- Religious symbols

The key to perfect mehendi is choosing a design that resonates with your personal style while complementing your overall bridal look.
""";
  }
}
Future<Map<String, dynamic>> fetchBlogDetail(int blogId) async {
  final response = await http.get(Uri.parse('https://happywedz.com/api/blog-deatils/$blogId'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> decodedJson = json.decode(response.body);
    final data = decodedJson['data'];

    // Join fullDescription list into one text
    String content = "";
    if (data['fullDescription'] != null) {
      content = (data['fullDescription'] as List<dynamic>).join("\n\n");
    }

    // Prepare a cleaned-up map
    return {
      "id": data['id'],
      "title": data['title'],
      "date": data['createdDate'],
      "readTime": data['readTime'] ?? "5 min",
      "images": List<String>.from(data['images'] ?? []),
      "tags": List<String>.from(data['tags'] ?? []),
      "author": data['author'],
      "content": content,
    };
  } else {
    throw Exception('Failed to load blog details');
  }
}





class BlogDetailPage extends StatelessWidget {
  final String title;
  final String date;
  final String readTime;
  final List<String> images;
  final String content;

  const BlogDetailPage({
    Key? key,
    required this.title,
    required this.date,
    required this.readTime,
    required this.images,
    required this.content,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.white),
            flexibleSpace:FlexibleSpaceBar(
              background: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                    ),
                  );
                },
              ),
            ),

          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 6),
                      Text(
                        readTime,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 20),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 30),

                  // Engagement Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildEngagementButton(Icons.favorite_border, 'Like', 12),
                        _buildEngagementButton(Icons.bookmark_border, 'Save', 8),
                        _buildEngagementButton(Icons.share, 'Share', 5),
                        _buildEngagementButton(Icons.comment_outlined, 'Comment', 3),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Related Articles Section
                  Text(
                    'Related Articles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildRelatedArticle(
                    'Wedding Decor Ideas That Will Make Your Guests Wow',
                    '2min read',
                    'https://images.unsplash.com/photo-1519741497674-611481863552?w=300&h=160&fit=crop',
                  ),
                  SizedBox(height: 12),
                  _buildRelatedArticle(
                    'Budget-Friendly Wedding Planning Tips That Actually Work',
                    '3min read',
                    'https://images.unsplash.com/photo-1465495976277-4387d4b0e4a6?w=300&h=160&fit=crop',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton(IconData icon, String label, int count) {
    return Column(
      children: [
        Icon(icon, color: Colors.pink[400], size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedArticle(String title, String readTime, String imageUrl) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, size: 20, color: Colors.grey[600]),
                );
              },
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  readTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
      appBar: AppBar(
        title: Text(wedding.title),
        backgroundColor: Color(0xFFE91E63),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: wedding.coverPhoto != null
                  ? Image.network(
                wedding.coverPhoto!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, size: 50),
                ),
              )
                  : Container(
                width: double.infinity,
                height: 220,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 50),
              ),
            ),
            SizedBox(height: 16),

            // Basic Info
            Text(wedding.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('City: ${wedding.city}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            Text('Wedding Date: ${wedding.weddingDate}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            SizedBox(height: 12),

            // Venues
            if (wedding.venues.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Venues:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: wedding.venues.map((v) => Chip(label: Text(v))).toList(),
                  ),
                  SizedBox(height: 12),
                ],
              ),

            // Bride & Groom Info
            Text('Bride: ${wedding.brideName}', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(wedding.brideBio),
            SizedBox(height: 8),
            Text('Groom: ${wedding.groomName}', style: TextStyle(fontWeight: FontWeight.w600)),
            Text(wedding.groomBio),
            SizedBox(height: 12),

            // Story
            if (wedding.story.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Story:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(wedding.story),
                  SizedBox(height: 12),
                ],
              ),

            // Events
            if (wedding.events.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Events:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...wedding.events.map((e) => Text('${e['date']} - ${e['name']} at ${e['venue']}')),
                  SizedBox(height: 12),
                ],
              ),

            // Vendors
            if (wedding.vendors.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vendors:', style: TextStyle(fontWeight: FontWeight.w600)),
                  ...wedding.vendors.map((v) => Text('${v['type']}: ${v['name']}')),
                  SizedBox(height: 12),
                ],
              ),

            // Themes
            if (wedding.themes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Themes:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Wrap(
                    spacing: 8,
                    children: wedding.themes.map((t) => Chip(label: Text(t))).toList(),
                  ),
                  SizedBox(height: 12),
                ],
              ),

            // Outfits, special moments, photographer, makeup, decor
            Text('Bride Outfit: ${wedding.brideOutfit}'),
            Text('Groom Outfit: ${wedding.groomOutfit}'),
            Text('Special Moments: ${wedding.specialMoments}'),
            Text('Photographer: ${wedding.photographer}'),
            Text('Makeup: ${wedding.makeup}'),
            Text('Decor: ${wedding.decor}'),
            SizedBox(height: 12),

            // Additional Credits
            if (wedding.additionalCredits.isNotEmpty)
              Text('Credits: ${wedding.additionalCredits.join(', ')}'),

            SizedBox(height: 16),

            // Highlight Photos
            if (wedding.highlightPhotos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Highlight Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: wedding.highlightPhotos.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          wedding.highlightPhotos[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),

            // All Photos
            if (wedding.allPhotos.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: wedding.allPhotos.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          wedding.allPhotos[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              ),

            // Created & Updated Dates
            Text('Created At: ${wedding.createdAt.toLocal().toString().split(' ')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('Updated At: ${wedding.updatedAt.toLocal().toString().split(' ')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}


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
    return RealWedding(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      weddingDate: json['weddingDate'],
      city: json['city'],
      venues: List<String>.from(json['venues'] ?? []),
      brideName: json['brideName'],
      brideBio: json['brideBio'],
      groomName: json['groomName'],
      groomBio: json['groomBio'],
      story: json['story'],
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ?? [],
      vendors: (json['vendors'] as List<dynamic>?)
          ?.map((v) => Map<String, String>.from(v as Map))
          .toList() ?? [],
      coverPhoto: json['coverPhoto'] != null
          ? "https://happywedz.com${json['coverPhoto']}"
          : null,
      highlightPhotos: (json['highlightPhotos'] as List<dynamic>?)
          ?.map((e) => "https://happywedz.com$e")
          .toList() ?? [],
      allPhotos: (json['allPhotos'] as List<dynamic>?)
          ?.map((e) => "https://happywedz.com$e")
          .toList() ?? [],
      themes: List<String>.from(json['themes'] ?? []),
      brideOutfit: json['brideOutfit'],
      groomOutfit: json['groomOutfit'],
      specialMoments: json['specialMoments'],
      photographer: json['photographer'],
      makeup: json['makeup'],
      decor: json['decor'],
      additionalCredits: List<String>.from(json['additionalCredits'] ?? []),
      status: json['status'],
      featured: json['featured'] ?? false,
      userId: json['user_id'],
      userEmail: json['user_email'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

}
