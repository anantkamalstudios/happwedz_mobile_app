import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                _buildAppBar(context),

                // TabBar
                const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: "Upcoming"),
                    Tab(text: "Past"),
                  ],
                ),

                // TabBarView content
                const Expanded(
                  child: TabBarView(
                    children: [
                      UpcomingBookingsTab(),
                      PastBookingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'My Bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }
}

class UpcomingBookingsTab extends StatelessWidget {
  const UpcomingBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 16),
            BookingCard(
              imageUrl: 'https://example.com/wedding_venue.jpg',
              vendorName: 'Saswad, Pune',
              serviceName: 'Fort Jadhavgadh, Pune',
              price: '₹ 50000',
              bookingDate: '20/09/2026',
              address: 'Banquet Halls, Marriage Garden',
              rating: 5.0,
              reviewCount: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class PastBookingsTab extends StatelessWidget {
  const PastBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No past bookings yet.'),
    );
  }
}

class BookingCard extends StatelessWidget {
  final String imageUrl;
  final String vendorName;
  final String serviceName;
  final String price;
  final String bookingDate;
  final String address;
  final double rating;
  final int reviewCount;

  const BookingCard({
    super.key,
    required this.imageUrl,
    required this.vendorName,
    required this.serviceName,
    required this.price,
    required this.bookingDate,
    required this.address,
    required this.rating,
    required this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$rating($reviewCount)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Service Name
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Price and Booking Date
                Row(
                  children: [
                    const Text(
                      'Price: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(price),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Booking Date: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(bookingDate),
                  ],
                ),
                const SizedBox(height: 8),
                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Service Booked Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text(
                      'Service Booked',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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
}

// class my_bookings extends StatefulWidget {
//   const my_bookings({super.key});
//
//   @override
//   State<my_bookings> createState() => _my_bookingsState();
// }
//
// class _my_bookingsState extends State<my_bookings> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),
//               Color(0xFFFFB6C1),
//               Colors.white,
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Column()
//         ),
//       ),
//     );
//   }
// }
