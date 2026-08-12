import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(context),
                TabBar(
                  labelColor: AppColors.textOnPrimary,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: AppColors.textOnPrimary,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelStyle: AppText.button,
                  unselectedLabelStyle: AppText.bodyStrong,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: "Upcoming"),
                    Tab(text: "Past"),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const TabBarView(
                      children: [UpcomingBookingsTab(), PastBookingsTab()],
                    ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const AppBackButton(color: AppColors.textOnPrimary),
          Expanded(
            child: Text(
              'My Bookings',
              textAlign: TextAlign.center,
              style: AppText.pageTitle.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

// =============================================================
// Shared booking fetch — same endpoint, same auth header, same parsing.
// =============================================================

/// Result of a bookings fetch, split into upcoming and past.
class _BookingsResult {
  const _BookingsResult(this.upcoming, this.past);

  final List<dynamic> upcoming;
  final List<dynamic> past;
}

/// Thrown when no auth token is stored, so the caller can route to login.
class _NotSignedIn implements Exception {}

Future<_BookingsResult> _fetchBookings() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("auth_token");

  if (token == null) throw _NotSignedIn();

  final res = await http.get(
    Uri.parse("https://happywedz.com/api/request-pricing/user/quotations"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }

  final data = jsonDecode(res.body);
  final upcoming = <dynamic>[];
  final past = <dynamic>[];

  if (data["success"] == true) {
    final List<dynamic> allBookings = data["quotations"] ?? [];
    final now = DateTime.now();

    for (final b in allBookings) {
      final String? dateStr = b["eventDate"];
      if (dateStr == null || dateStr.isEmpty) {
        debugPrint("Missing eventDate for booking: $b");
        continue;
      }
      try {
        final bookingDate = DateTime.parse(dateStr);
        if (bookingDate.isAfter(now)) {
          upcoming.add(b);
        } else {
          past.add(b);
        }
      } catch (e) {
        debugPrint("Error parsing eventDate '$dateStr': $e");
      }
    }
  }

  return _BookingsResult(upcoming, past);
}

/// Maps one quotation object onto a [BookingCard]. Field lookups unchanged.
BookingCard _cardFor(dynamic b) {
  return BookingCard(
    imageUrl:
        b["vendor"]?["cover_photo"] ?? "https://happywedz.com/images/no-image.jpg",
    vendorName: b["vendor"]?["businessName"] ?? "Vendor",
    serviceName: b["vendor"]?["category"] ?? "Service",
    price: "${b["quote"]?["price"] ?? "N/A"}",
    bookingDate: b["eventDate"] ?? "",
    address: b["vendor"]?["address"] ?? "No address provided",
    rating: double.tryParse(b["vendor"]?["rating"].toString() ?? "0") ?? 0,
    reviewCount: b["vendor"]?["reviewCount"] ?? 0,
  );
}

/// Shared list body: shimmer → error → empty → cards.
class _BookingsList extends StatelessWidget {
  const _BookingsList({
    required this.loading,
    required this.error,
    required this.bookings,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final bool loading;
  final Object? error;
  final List<dynamic> bookings;
  final Future<void> Function() onRetry;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Skeletons.listCards(count: 3, height: 300),
      );
    }

    if (error != null) {
      return ErrorState(error: error, onRetry: onRetry);
    }

    if (bookings.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: onRetry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            EmptyState(
              title: emptyTitle,
              message: emptyMessage,
              icon: Icons.event_note_outlined,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRetry,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        itemBuilder: (context, index) => FadeSlideIn(
          delay: AppMotion.staggerFor(index),
          child: _cardFor(bookings[index]),
        ),
      ),
    );
  }
}

// =============================================================
// UPCOMING TAB
// =============================================================
class UpcomingBookingsTab extends StatefulWidget {
  const UpcomingBookingsTab({super.key});

  @override
  State<UpcomingBookingsTab> createState() => _UpcomingBookingsTabState();
}

class _UpcomingBookingsTabState extends State<UpcomingBookingsTab> {
  bool loading = true;
  Object? error;
  List<dynamic> upcomingBookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    if (mounted) setState(() => error = null);
    try {
      final result = await _fetchBookings();
      if (!mounted) return;
      setState(() {
        upcomingBookings = result.upcoming;
        loading = false;
      });
    } on _NotSignedIn {
      if (mounted) Navigator.pushNamed(context, "/customer-login");
    } catch (e) {
      debugPrint("Exception during fetch: $e");
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BookingsList(
      loading: loading,
      error: error,
      bookings: upcomingBookings,
      onRetry: fetchBookings,
      emptyTitle: 'No upcoming bookings',
      emptyMessage: 'Bookings you make will show up here.',
    );
  }
}

// =============================================================
// PAST TAB
// =============================================================
class PastBookingsTab extends StatefulWidget {
  const PastBookingsTab({super.key});

  @override
  State<PastBookingsTab> createState() => _PastBookingsTabState();
}

class _PastBookingsTabState extends State<PastBookingsTab> {
  bool loading = true;
  Object? error;
  List<dynamic> pastBookings = [];

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    if (mounted) setState(() => error = null);
    try {
      final result = await _fetchBookings();
      if (!mounted) return;
      setState(() {
        pastBookings = result.past;
        loading = false;
      });
    } on _NotSignedIn {
      if (mounted) Navigator.pushNamed(context, "/customer-login");
    } catch (e) {
      debugPrint("Exception during fetch: $e");
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BookingsList(
      loading: loading,
      error: error,
      bookings: pastBookings,
      onRetry: fetchBookings,
      emptyTitle: 'No past bookings yet',
      emptyMessage: 'Completed bookings will be listed here.',
    );
  }
}

// =============================================================
// BOOKING CARD
// =============================================================

class BookingCard extends StatelessWidget {
  final String imageUrl;
  final String vendorName;
  final String serviceName;

  /// Bare amount — the ₹ symbol is added at render time.
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

  /// Formats the ISO event date for display, falling back to the raw string.
  String get _formattedDate {
    if (bookingDate.isEmpty) return 'Date not set';
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(bookingDate));
    } catch (_) {
      return bookingDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with rating overlay
          Stack(
            children: [
              NetworkImageWidget(
                url: imageUrl,
                height: 190,
                width: double.infinity,
                memCacheWidth: 900,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                scrim: true,
              ),
              if (rating > 0)
                Positioned(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: AppRadii.rPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewCount)',
                          style: AppText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serviceName,
                  style: AppText.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  vendorName,
                  style: AppText.cardSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.md),

                // Price chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSurface,
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Text('₹$price', style: AppText.price),
                ),

                const SizedBox(height: AppSpacing.md),

                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: _formattedDate,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(icon: Icons.location_on_rounded, text: address),

                const SizedBox(height: AppSpacing.lg),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: AppRadii.rMd,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.successDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Service Booked',
                        style: AppText.button.copyWith(
                          color: AppColors.successDark,
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppText.body)),
      ],
    );
  }
}