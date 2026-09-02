import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/api_config.dart';
import '../core/core.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: "Upcoming"),
                    Tab(text: "Past"),
                    Tab(text: "Shop Orders"),
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
                      children: [
                        UpcomingBookingsTab(),
                        PastBookingsTab(),
                        ShopOrdersTab(),
                      ],
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
    Uri.parse("${ApiConfig.apiBase}/request-pricing/user/quotations"),
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

/// Orders placed on the store (store.happywedz.com), a separate service with
/// its own database. The HappyWedz backend resolves which store customer
/// this user is and reshapes the orders before they arrive here, so this
/// fetch looks like [_fetchBookings] even though the data crossed a service
/// boundary to get here.
///
/// A user who has never shopped gets back `{success: true, orders: []}` (or
/// `linked: false`) — an empty list, not an error.
Future<List<dynamic>> _fetchShopOrders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("auth_token");

  if (token == null) throw _NotSignedIn();

  final res = await http.get(
    Uri.parse("${ApiConfig.apiBase}/store/orders/mine"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode}');
  }

  final data = jsonDecode(res.body);
  if (data["success"] == true) {
    return (data["orders"] as List<dynamic>?) ?? [];
  }
  return [];
}

/// Maps one quotation object onto a [BookingCard]. Field lookups unchanged.
BookingCard _cardFor(dynamic b) {
  return BookingCard(
    imageUrl:
        b["vendor"]?["cover_photo"] ?? "${ApiConfig.baseUrl}/images/no-image.jpg",
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
    this.cardBuilder = _cardFor,
  });

  final bool loading;
  final Object? error;
  final List<dynamic> bookings;
  final Future<void> Function() onRetry;
  final String emptyTitle;
  final String emptyMessage;

  /// Defaults to the vendor-quotation [BookingCard]; [ShopOrdersTab] passes
  /// [_shopOrderCardFor] instead since the fields don't match.
  final Widget Function(dynamic) cardBuilder;

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
          child: cardBuilder(bookings[index]),
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
// SHOP ORDERS TAB
// =============================================================
class ShopOrdersTab extends StatefulWidget {
  const ShopOrdersTab({super.key});

  @override
  State<ShopOrdersTab> createState() => _ShopOrdersTabState();
}

class _ShopOrdersTabState extends State<ShopOrdersTab> {
  bool loading = true;
  Object? error;
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (mounted) setState(() => error = null);
    try {
      final result = await _fetchShopOrders();
      if (!mounted) return;
      setState(() {
        orders = result;
        loading = false;
      });
    } on _NotSignedIn {
      if (mounted) Navigator.pushNamed(context, "/customer-login");
    } catch (e) {
      debugPrint("Exception during shop orders fetch: $e");
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
      bookings: orders,
      onRetry: fetchOrders,
      emptyTitle: 'No shop orders found',
      emptyMessage: "You haven't ordered anything from the HappyWedz store yet.",
      cardBuilder: _shopOrderCardFor,
    );
  }
}

Widget _shopOrderCardFor(dynamic order) => _ShopOrderCard(order: order);

// =============================================================
// SHOP ORDER STATUS
// =============================================================

/// The store's `Order.status` enum is exactly Pending / Processing /
/// Delivered / Cancel (not "Cancelled") — the other spellings are matched
/// too so a later widening of that enum still lands somewhere sensible.
class _ShopStatus {
  const _ShopStatus(this.label, this.color);
  final String label;
  final Color color;
}

_ShopStatus _shopStatusFor(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase() ?? '';
  switch (value) {
    case 'PENDING':
      return const _ShopStatus('Pending', AppColors.warning);
    case 'PROCESSING':
      return const _ShopStatus('Processing', AppColors.info);
    case 'DELIVERED':
      return const _ShopStatus('Delivered', AppColors.success);
    case 'CANCEL':
    case 'CANCELLED':
    case 'CANCELED':
      return const _ShopStatus('Cancelled', AppColors.error);
    default:
      return _ShopStatus(
        value.isEmpty ? 'Unknown' : value,
        AppColors.textTertiary,
      );
  }
}

// =============================================================
// SHOP ORDER CARD
// =============================================================

class _ShopOrderCard extends StatefulWidget {
  const _ShopOrderCard({required this.order});

  final dynamic order;

  @override
  State<_ShopOrderCard> createState() => _ShopOrderCardState();
}

class _ShopOrderCardState extends State<_ShopOrderCard> {
  static const String _storeUrl = 'https://store.happywedz.com';

  bool _expanded = false;

  String get _formattedPlacedAt {
    final placedAt = widget.order["placedAt"]?.toString();
    if (placedAt == null || placedAt.isEmpty) return 'Date not set';
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(placedAt));
    } catch (_) {
      return placedAt;
    }
  }

  /// "Rose Gold Garland +2 more" — names the thing the person actually
  /// recognises, then says how much else is in the box.
  String _itemSummary(List<dynamic> items) {
    if (items.isEmpty) return 'No items';
    final first = items.first;
    final rest = items.length - 1;
    final title = first["title"]?.toString() ?? 'Item';
    return rest > 0 ? '$title +$rest more' : title;
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order["items"] as List<dynamic>?) ?? [];
    final itemCount = order["itemCount"] ?? items.length;
    final status = _shopStatusFor(order["status"]);
    final discount = num.tryParse('${order["discount"] ?? 0}') ?? 0;
    final firstImage = items.isNotEmpty
        ? items.first["image"]?.toString()
        : null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.rSm,
                child: firstImage != null && firstImage.isNotEmpty
                    ? NetworkImageWidget(
                        url: firstImage,
                        height: 64,
                        width: 64,
                      )
                    : Container(
                        height: 64,
                        width: 64,
                        color: AppColors.pinkSurface,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order["invoice"] != null
                          ? 'Order #${order["invoice"]}'
                          : 'Shop Order',
                      style: AppText.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _itemSummary(items),
                      style: AppText.cardSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: AppRadii.rPill,
                  border: Border.all(color: status.color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  status.label,
                  style: AppText.caption.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            text: '$itemCount item${itemCount == 1 ? "" : "s"}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.payments_outlined,
            text: order["paymentMethod"]?.toString() ?? '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.local_shipping_outlined,
            text: order["shipTo"]?.toString() ?? '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.calendar_today_rounded, text: _formattedPlacedAt),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pinkSurface,
                  borderRadius: AppRadii.rSm,
                ),
                child: Text(
                  '₹${order["total"] ?? "—"}',
                  style: AppText.price,
                ),
              ),
              if (discount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '₹$discount off',
                  style: AppText.caption.copyWith(color: AppColors.successDark),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(_expanded ? 'Hide Items' : 'View Items'),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openStore,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Visit Store'),
              ),
            ],
          ),
          if (_expanded)
            Column(
              children: items.map((item) {
                final title = item["title"]?.toString() ?? 'Item';
                final quantity = item["quantity"] ?? 1;
                final price = item["price"] ?? 0;
                final lineTotal = item["lineTotal"] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$title  ·  $quantity × ₹$price',
                          style: AppText.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('₹$lineTotal', style: AppText.bodyStrong),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
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