import 'package:flutter/material.dart';
import 'package:h_w_a/services/shop_screen.dart';
import 'package:h_w_a/services/signup.dart';
import 'package:h_w_a/services/vendor_screen.dart';
import 'package:h_w_a/services/venue_screen.dart';
import 'ai_screen.dart';
import 'home_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
     HomeScreen(),
    VenueScreen(),
    VendorPage(),
    ShopScreen(),
    SignupPage()
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
            selectedItemColor: Colors.pink[100],
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.place),
                label: 'Venue',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_box_rounded),
                label: 'Vendor',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                label: 'Shop',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        ),

        // 🔮 Floating AI + Astrology icons
        Positioned(
          bottom: 70, // just above bottom nav
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'astrology',
                backgroundColor: Colors.purple,
                onPressed: () {
                  // Navigate to astrology chat or open dialog
                },
                tooltip: 'Astrology Talk',
                child: const Icon(Icons.smart_toy, size: 20),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.small(
                heroTag: 'ai',
                backgroundColor: Colors.blueGrey,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  AiChatScreen()),
                  );
                },
                tooltip: 'AI Talk',
                child:  Icon(Icons.auto_awesome, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
