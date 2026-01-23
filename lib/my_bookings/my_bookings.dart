import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
                const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: "Upcoming"),
                    Tab(text: "Past"),
                  ],
                ),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// =============================================================
// ✅ UPCOMING TAB WITH API + PRINTS
// =============================================================
class UpcomingBookingsTab extends StatefulWidget {
  const UpcomingBookingsTab({super.key});

  @override
  State<UpcomingBookingsTab> createState() => _UpcomingBookingsTabState();
}

class _UpcomingBookingsTabState extends State<UpcomingBookingsTab> {
  bool loading = true;
  List<dynamic> upcomingBookings = [];
  List<dynamic> pastBookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    print("🔐 Retrieved token: $token");

    if (token == null) {
      print("⚠️ No token found. Redirecting to login...");
      if (mounted) Navigator.pushNamed(context, "/customer-login");
      return;
    }

    try {
      print("📡 Fetching bookings from API...");
      final res = await http.get(
        Uri.parse("https://happywedz.com/api/request-pricing/user/quotations"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("✅ API Response status: ${res.statusCode}");
      print("🧾 Raw response body: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("📦 Parsed JSON: $data");

        if (data["success"] == true) {
          final List<dynamic> allBookings = data["quotations"] ?? [];
          print("📅 Total bookings found: ${allBookings.length}");

          DateTime now = DateTime.now();

          for (var b in allBookings) {
            String? dateStr = b["eventDate"];  // ✅ FIXED

            if (dateStr != null && dateStr.isNotEmpty) {
              try {
                DateTime bookingDate = DateTime.parse(dateStr);

                if (bookingDate.isAfter(now)) {
                  upcomingBookings.add(b);
                } else {
                  pastBookings.add(b);
                }
              } catch (e) {
                print("⚠️ Error parsing eventDate '$dateStr': $e");
              }
            } else {
              print("⚠️ Missing eventDate for booking: $b");
            }
          }

          print("✅ Upcoming: ${upcomingBookings.length}");
          print("✅ Past: ${pastBookings.length}");
        } else {
          print("❌ API returned success=false");
        }
      } else {
        print("❌ Failed with status ${res.statusCode}");
      }
    } catch (e) {
      print("💥 Exception during fetch: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (upcomingBookings.isEmpty) {
      return const Center(child: Text("No upcoming bookings"));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: upcomingBookings.map((b) {
            return BookingCard(
              imageUrl: b["vendor"]?["cover_photo"] ??
                  "https://happywedz.com/images/no-image.jpg",
              vendorName: b["vendor"]?["businessName"] ?? "Vendor",
              serviceName: b["vendor"]?["category"] ?? "Service",
              price: "₹ ${b["quote"]?["price"] ?? "N/A"}",
              bookingDate: b["eventDate"] ?? "",   // ✅ FIXED
              address: b["vendor"]?["address"] ?? "No address provided",
              rating: double.tryParse(b["vendor"]?["rating"].toString() ?? "0") ?? 0,
              reviewCount: b["vendor"]?["reviewCount"] ?? 0,
            );
          }).toList(),
        ),
      ),
    );
  }
}


// =============================================================
// ✅ PAST TAB (reads from UpcomingBookingsTab data)
// =============================================================
class PastBookingsTab extends StatefulWidget {
  const PastBookingsTab({super.key});

  @override
  State<PastBookingsTab> createState() => _PastBookingsTabState();
}

class _PastBookingsTabState extends State<PastBookingsTab> {
  bool loading = true;
  List<dynamic> pastBookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) {
      if (mounted) Navigator.pushNamed(context, "/customer-login");
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("https://happywedz.com/api/request-pricing/user/quotations"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["success"] == true) {
          final List<dynamic> allBookings = data["quotations"] ?? [];
          DateTime now = DateTime.now();

          for (var b in allBookings) {
            String? dateStr = b["eventDate"];     // ✅ FIXED

            if (dateStr != null && dateStr.isNotEmpty) {
              try {
                DateTime bookingDate = DateTime.parse(dateStr);

                if (bookingDate.isBefore(now)) {
                  pastBookings.add(b);
                }
              } catch (e) {
                print("⚠️ Error parsing '$dateStr': $e");
              }
            }
          }
        }
      }
    } catch (e) {
      print("💥 Exception during fetch: $e");
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (pastBookings.isEmpty) {
      return const Center(child: Text("No past bookings yet."));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: pastBookings.map((b) {
            return BookingCard(
              imageUrl: b["vendor"]?["cover_photo"] ??
                  "https://happywedz.com/images/no-image.jpg",
              vendorName: b["vendor"]?["businessName"] ?? "Vendor",
              serviceName: b["vendor"]?["category"] ?? "Service",
              price: "₹ ${b["quote"]?["price"] ?? "N/A"}",
              bookingDate: b["eventDate"] ?? "",   // ✅ FIXED
              address: b["vendor"]?["address"] ?? "No address provided",
              rating: double.tryParse(b["vendor"]?["rating"].toString() ?? "0") ?? 0,
              reviewCount: b["vendor"]?["reviewCount"] ?? 0,
            );
          }).toList(),
        ),
      ),
    );
  }
}


// =============================================================
// ✅ BOOKING CARD COMPONENT
// =============================================================

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 IMAGE with overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, size: 60),
                      ),
                    ),
                  ),

                  /// 🔹 Rating Tag
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.yellow),
                          Text(
                            "$rating ($reviewCount)",
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// 🔹 Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Name
                    Text(
                      vendorName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// Service Name
                    Text(
                      serviceName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// 🔹 Price Chip
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "₹$price",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),

                    /// Booking Date
                    Text(
                      "📅 Date: $bookingDate",
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 6),

                    /// Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18),
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// 🔹 Attractive Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Service Booked",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

