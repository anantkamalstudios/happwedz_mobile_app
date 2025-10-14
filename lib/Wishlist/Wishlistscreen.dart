import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../Bottombars/VenuesScreen.dart';

class Wishlistscreen extends StatefulWidget {
  const Wishlistscreen({super.key});

  @override
  State<Wishlistscreen> createState() => _WishlistscreenState();
}

class _WishlistscreenState extends State<Wishlistscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample wishlist items
  final List<Map<String, dynamic>> _wishlistItems = [
    {
      'title': 'Coffee Maker',
      'category': 'Kitchen',
      'price': 120,
      'quantity': 1,
      'imageUrl': 'https://via.placeholder.com/150',
      'isPurchased': false,
    },
    {
      'title': 'Travel Voucher',
      'category': 'Travel',
      'price': 500,
      'quantity': 1,
      'imageUrl': 'https://via.placeholder.com/150',
      'isPurchased': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterItems(String filter) {
    if (filter == 'All') return _wishlistItems;
    if (filter == 'Purchased') {
      return _wishlistItems.where((item) => item['isPurchased'] == true).toList();
    }
    if (filter == 'Pending') {
      return _wishlistItems.where((item) => item['isPurchased'] == false).toList();
    }
    return _wishlistItems;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wedding Wishlist'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Purchased'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ['All', 'Purchased', 'Pending'].map((filter) {
          final items = _filterItems(filter);
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item['imageUrl'],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                    ),
                  ),
                  title: Text(item['title']),
                  subtitle: Text(
                      '${item['category']} • \$${item['price']} x ${item['quantity']}'),
                  trailing: item['isPurchased']
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    // TODO: Open item details / edit
                  },
                ),
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Add Item Screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}





class FavouritesPage extends StatefulWidget {
  const FavouritesPage({Key? key}) : super(key: key);

  @override
  State<FavouritesPage> createState() => _FavouritesPageState();
}

class _FavouritesPageState extends State<FavouritesPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // 🌸 Gradient starts from very top of the page
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF69B4), // Hot pink
            Color(0xFFFFB6C1), // Light pink
            Colors.white,
          ],
          stops: [0.0, 0.3, 0.6],
        ),
      ),

      child: Scaffold(
        backgroundColor: Colors.transparent, // important for gradient
        appBar: AppBar(
          title: const Text(
            'Wishlist',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent, // make gradient visible behind AppBar
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Text(
                  'Favourites',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                      children: const [
                        TextSpan(
                            text:
                            'Keep all of your wedding favourites here! Click the '),
                        TextSpan(
                          text: '♥',
                          style: TextStyle(
                              color: Color(0xFFE91E63), fontSize: 18),
                        ),
                        TextSpan(
                            text:
                            '\nto save your favourite vendors, Real Weddings, and inspiration here.'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 🌷 Favourite Vendors Section
                _buildSectionHeader('Favourite Vendors'),
                const SizedBox(height: 20),

                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VenuesScreen(),
                            ),
                          );
                        },
                        child: _buildVendorCard(
                          icon: Icons.location_on,
                          label: 'Venues',
                          hasContent: true,
                        ),
                      ),
                      _buildVendorCard(
                        icon: Icons.camera_alt,
                        label: 'Photography and\nvideo',
                      ),
                      _buildVendorCard(
                        icon: Icons.restaurant,
                        label: 'Caterers',
                      ),
                      _buildVendorCard(
                        icon: Icons.card_giftcard,
                        label: 'Wedding planners',
                      ),
                      _buildVendorCard(
                        icon: Icons.diamond,
                        label: 'Jewellery',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 💡 My Inspiration Boards Section
                _buildSectionHeader('My inspiration boards'),
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildInspirationBoard('Real Weddings'),
                      const SizedBox(width: 16),
                      _buildInspirationBoard('Articles'),
                      const SizedBox(width: 16),
                      _buildInspirationBoard('Community'),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section Header Widget
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFF69B4), // 💖 PINK button
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Show all',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // Vendor Card Widget
  Widget _buildVendorCard({
    required IconData icon,
    required String label,
    bool hasContent = false,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: hasContent ? null : Colors.grey[100],
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
                image: hasContent
                    ? const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1519167758481-83f29da8c2b7?w=400',
                  ),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: !hasContent
                  ? Center(
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.grey[400],
                ),
              )
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Find',
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
          ),
        ],
      ),
    );
  }

  // Inspiration Board Widget
  Widget _buildInspirationBoard(String title) {
    return Expanded(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite_border,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get inspired!',
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
      ),
    );
  }
}



class FavouritesProvider extends ChangeNotifier {
  final List<String> _favouriteVenues = [];

  List<String> get favouriteVenues => _favouriteVenues;

  void toggleFavourite(String venueName) {
    if (_favouriteVenues.contains(venueName)) {
      _favouriteVenues.remove(venueName);
    } else {
      _favouriteVenues.add(venueName);
    }
    notifyListeners();
  }

  bool isFavourite(String venueName) {
    return _favouriteVenues.contains(venueName);
  }
}
