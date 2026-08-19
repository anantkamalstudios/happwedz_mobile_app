import 'package:flutter/material.dart';
import 'package:happy_wedz/movment_plus/upload_selfie_screen.dart';

import 'guest_token_screen.dart';
import 'movment_plus_dashboard.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({super.key});

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const Moment_plus_home(),
    const GuestTokenScreen(),
    const MomentPrivacyDialog(),
    // const LoginScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    // No fixed height here. BottomNavigationBar sizes itself to
    // kBottomNavigationBarHeight *plus* the bottom safe-area inset; pinning it
    // to 70px left the tiles ~10px to draw a 38px icon+label and overflowed by
    // the size of the gesture bar on devices that have one.
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF5FA2), // light pink
            Color(0xFFFF2E8A), // dark pink
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      // Labels here are fixed at 12px, but the system font-size setting still
      // scales them and is the other way these tiles overflow.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withValues(alpha: 0.7),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.key_outlined),
              activeIcon: Icon(Icons.key),
              label: 'Guest Token',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Upload Selfie',
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.menu),
            //   activeIcon: Icon(Icons.menu),
            //   label: 'Login',
            // ),
          ],
        ),
      ),
    );
  }
}
