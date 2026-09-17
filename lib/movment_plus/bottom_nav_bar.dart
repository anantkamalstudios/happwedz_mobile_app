import 'package:flutter/material.dart';
import 'package:happy_wedz/movment_plus/upload_selfie_screen.dart';

import 'custome_theme.dart';
import 'guest_token_screen.dart';
import 'guest_token_store.dart';
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
    const _UploadSelfieTab(),
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

/// The "Upload Selfie" tab needs to know which gallery to match against.
/// Unlike the other two tabs it has no token of its own to work with, so it
/// reads the last one the guest verified via [GuestTokenStore] (set by
/// `GuestTokenScreen` on a successful lookup) and either drops straight into
/// the real selfie flow or, for a guest who hasn't entered a code yet, asks
/// for one first — same guard the website applies before this screen.
class _UploadSelfieTab extends StatefulWidget {
  const _UploadSelfieTab();

  @override
  State<_UploadSelfieTab> createState() => _UploadSelfieTabState();
}

class _UploadSelfieTabState extends State<_UploadSelfieTab> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = GuestTokenStore.read();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: MpTheme.primaryColor),
            ),
          );
        }

        final token = snapshot.data;
        if (token != null) {
          return MomentPrivacyDialog(token: token);
        }

        return Scaffold(
          body: Container(
            decoration:
                const BoxDecoration(gradient: MpTheme.backgroundGradient),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.key_outlined,
                          size: 48, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        "Enter your gallery access code first",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "We need to know which wedding gallery to search for you in.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GuestTokenScreen(),
                            ),
                          );
                          // The token screen may have saved one while it was
                          // on top — re-check so this tab reflects it without
                          // the guest having to tap away and back.
                          setState(() {
                            _tokenFuture = GuestTokenStore.read();
                          });
                        },
                        child: Text(
                          "Enter Access Code",
                          style: TextStyle(color: MpTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
