import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'home_content.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Happy_Weds',
//           style: TextStyle(
//             fontFamily: 'PlayfairDisplay',
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 24,
//           ),
//         ),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.black),
//           onPressed: () {},
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 12),
//             child: CircleAvatar(
//               backgroundImage: AssetImage('assets/images/user_avatar.png'),
//               radius: 18,
//             ),
//           ),
//         ],
//       ),
//       body: const HomeContent(),
//     );
//   }
// }




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCity = 'Select Location';
  List<String> cities = [
    'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata',
    'Pune', 'Ahmedabad', 'Jaipur', 'Lucknow'
  ];


  Future<void> _useCurrentLocation() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }

      // Request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          print("Location permission denied forever.");
          return;
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String cityName = placemarks.first.locality ?? "Unknown City";

      setState(() {
        selectedCity = cityName;
      });

      print("📍 Current city: $cityName");
    } catch (e) {
      print("Location error: $e");
    }
  }

  void _showCityDropdown() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // allows more height if needed
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView( // ✅ make it scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // shrink to fit content
              children: [
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: const Text("Use Current Location"),
                  onTap: () {
                    Navigator.pop(context);
                    _useCurrentLocation();
                  },
                ),
                const Divider(),
                ...cities.map((city) {
                  return ListTile(
                    title: Text(city),
                    onTap: () {
                      setState(() {
                        selectedCity = city;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: InkWell(
          onTap: _showCityDropdown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 6),
              Text(selectedCity, style: const TextStyle(fontSize: 16)),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.pink[200],
        elevation: 1,
      ),
      body: HomeContent(),
    );
  }
}



//https://elements.envato.com/hotel-booking-app-KYFYXHQ