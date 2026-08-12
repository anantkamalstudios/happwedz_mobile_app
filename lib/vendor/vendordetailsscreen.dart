import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:imageview360/imageview360.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import '../ClaimBusiness.dart';
import '../Review.dart';
import '../ai_chat_screen/ai_chat_screen.dart';
import '../chat_page_new.dart';
import '../core/core.dart';

// Final VendorServicesScreen — pagination, grid/list toggle, search, filters,
// wishlist toggle, phone/WhatsApp/message actions, safe image handling.
//
// The API layer below is unchanged: same endpoints, same query params, same
// response parsing. Only the presentation has been rebuilt on the design
// system.

class VendorServicesScreen extends StatefulWidget {
  final String subcategoryName;

  const VendorServicesScreen({super.key, required this.subcategoryName});

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  // Raw data storage (all fetched pages)
  final List<dynamic> allServices = [];
  // Filtered & displayed list
  List<dynamic> services = [];

  // Pagination
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;

  /// Set when the initial load fails so an [ErrorState] can be shown.
  Object? _loadError;

  String? currentUserId;
  Set<String> favouriteVendors = {};

  final ScrollController _scrollController = ScrollController();
  bool isList = true;

  // Search & Filters
  final TextEditingController searchController = TextEditingController();
  String filterCity = '';
  double filterMinPrice = 0;
  double filterMaxPrice = 100000;
  double filterMinRating = 0;
  String selectedCity = "";
  double minPrice = 0;
  double maxPrice = 200000;
  double selectedRating = 0;

  String? selectedSubCategory;
  String? selectedVendorType;

  /// Debounces the search field so filtering does not run on every keystroke.
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchAllServices();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // API — unchanged endpoints and parsing
  // ---------------------------------------------------------------------------

  Future<void> fetchAllServices() async {
    setState(() {
      isLoading = true;
      _loadError = null;
      allServices.clear();
      services.clear();
    });

    try {
      final sub = Uri.encodeComponent(widget.subcategoryName.toLowerCase());

      final url = Uri.parse(
        "https://happywedz.com/api/vendor-services?subCategory=$sub&limit=5000",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final raw = data["data"];

        List<dynamic> list = [];

        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          list = [raw];
        }

        if (!mounted) return;
        setState(() {
          allServices.addAll(list);
        });

        _applyFiltersAndSearch();
      } else {
        if (!mounted) return;
        setState(() => _loadError = 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error loading ALL services: $e");
      if (!mounted) return;
      setState(() => _loadError = e);
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void setupPaginationListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMore) {
        fetchMoreServices();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }

  Future<void> fetchServices() async {
    setState(() => isLoading = true);

    Map<String, String> queryParams = {};

    if (selectedCity.isNotEmpty) queryParams["city"] = selectedCity;
    if (selectedSubCategory != null) {
      queryParams["subCategory"] = selectedSubCategory!;
    }
    if (selectedVendorType != null) {
      queryParams["vendorType"] = selectedVendorType!;
    }

    queryParams["minPrice"] = minPrice.toInt().toString();
    queryParams["maxPrice"] = maxPrice.toInt().toString();
    queryParams["minRating"] = selectedRating.toString();

    final uri = Uri.https("happywedz.com", "/api/vendor-services", queryParams);

    try {
      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (!mounted) return;
        setState(() {
          vendorList = data["data"];
        });
      }
    } catch (e) {
      debugPrint("Error fetching services: $e");
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> fetchMoreServices() async {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    try {
      currentPage++;

      final encodedSubcategory = Uri.encodeComponent(
        widget.subcategoryName.toLowerCase(),
      );

      final url = Uri.parse(
        "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory&page=$currentPage&limit=9",
      );

      final response = await http.get(
        url,
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawData = data['data'];

        List<dynamic> list = [];

        if (rawData is List) {
          list = rawData;
        } else if (rawData is Map<String, dynamic>) {
          list = [rawData]; // wrap single object into a list
        } else {
          list = []; // null or unexpected format
        }

        final pagination = data['pagination'] ?? {};

        totalPages = (pagination['totalPages'] ?? 1) is int
            ? pagination['totalPages']
            : int.tryParse('${pagination['totalPages']}') ?? totalPages;
        hasMore = currentPage < totalPages;

        if (!mounted) return;
        setState(() {
          allServices.addAll(list);
        });

        _applyFiltersAndSearch();
      } else {
        debugPrint('More API error ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('fetchMoreServices error $e');
      debugPrint('$st');
    }

    if (!mounted) return;
    setState(() => isLoadingMore = false);
  }

  Future<void> applyFilters() async {
    setState(() {
      filterCity = selectedCity;
      filterMinPrice = minPrice;
      filterMaxPrice = maxPrice;
      filterMinRating = selectedRating;
    });

    _applyFiltersAndSearch(); // local filtering
  }

  void _applyFiltersAndSearch() {
    final q = searchController.text.trim().toLowerCase();

    final filtered = allServices.where((service) {
      final attr = service['attributes'] ?? {};
      final vendor = service['vendor'] ?? {};

      final name =
          (vendor['businessName'] ?? attr['vendor_name'] ?? attr['Name'] ?? '')
              .toString()
              .toLowerCase();

      final city = (vendor['city'] ?? attr['city'] ?? '')
          .toString()
          .toLowerCase();

      // Price extraction
      double price = 0;
      final pText = (attr['veg_price'] ?? attr['PriceRange'] ?? '')
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), '');
      if (pText.isNotEmpty) price = double.tryParse(pText) ?? 0.0;

      // Rating
      final rating =
          double.tryParse(
            (attr['rating'] ?? attr['averageRating'] ?? '0').toString(),
          ) ??
          0;

      return
      // SEARCH (name + city)
      (q.isEmpty || name.contains(q) || city.contains(q)) &&
          // City filter
          (filterCity.isEmpty || city.contains(filterCity.toLowerCase())) &&
          // Price filter
          price >= filterMinPrice &&
          price <= filterMaxPrice &&
          // Rating filter
          rating >= filterMinRating;
    }).toList();

    setState(() {
      services = filtered;
    });
  }

  /// Debounced entry point used by the search field.
  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) _applyFiltersAndSearch();
    });
  }

  Future<void> _toggleFavourite(String vendorServiceId) async {
    if (currentUserId == null) {
      AppSnackbar.info(context, 'Please sign in to manage your wishlist.');
      return;
    }

    final isFav = favouriteVendors.contains(vendorServiceId);
    setState(() {
      if (isFav) {
        favouriteVendors.remove(vendorServiceId);
      } else {
        favouriteVendors.add(vendorServiceId);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
      final body = jsonEncode({
        'user_id': currentUserId.toString(),
        'vendor_services_id': vendorServiceId.toString(),
      });

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final m = jsonDecode(res.body);
        final msg = m['message'] ?? 'Wishlist updated';
        AppSnackbar.success(context, msg.toString());
      } else if (res.statusCode == 401) {
        // Roll the optimistic update back — the request did not land.
        setState(() {
          if (isFav) {
            favouriteVendors.add(vendorServiceId);
          } else {
            favouriteVendors.remove(vendorServiceId);
          }
        });
        AppSnackbar.error(context, 'Session expired. Please log in again.');
      }
    } catch (e) {
      debugPrint('wishlist api error $e');
      if (!mounted) return;
      setState(() {
        if (isFav) {
          favouriteVendors.add(vendorServiceId);
        } else {
          favouriteVendors.remove(vendorServiceId);
        }
      });
      AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    }
  }

  Future<void> _launchPhone(String phone) async {
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    // ensure number is in international format if needed; here we assume API gives proper number
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openChat(String vendorId, String name) async {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: VendorDetailsScreen(
          service: {
            'vendor': {'id': vendorId, 'businessName': name},
          },
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  Set<String> allSubCategories = {};
  Set<String> allVendorTypes = {};

  void extractFilters(List vendors) {
    for (var v in vendors) {
      if (v["subcategory"] != null) {
        allSubCategories.add(v["subcategory"]["name"]);
      }
      if (v["vendor"]?["vendorType"] != null) {
        allVendorTypes.add(v["vendor"]["vendorType"]["name"]);
      }
    }
  }

  List<dynamic> vendorList = [];

  Future<void> fetchVendors(String query) async {
    final url = Uri.parse(
      "https://happywedz.com/api/vendor-services?search=$query",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (!mounted) return;
      setState(() {
        vendorList = data['data']; // Adjust based on API response
      });
    } else {
      debugPrint("Error fetching vendors: ${response.statusCode}");
    }
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  /// True when any filter differs from its default — drives the badge on the
  /// filter button.
  bool get _hasActiveFilters =>
      filterCity.isNotEmpty ||
      filterMinPrice > 0 ||
      filterMaxPrice < 200000 ||
      filterMinRating > 0;

  void _openFilterSheet() {
    // Work on drafts so dismissing the sheet does not mutate live filters.
    String draftCity = selectedCity;
    double draftMin = minPrice;
    double draftMax = maxPrice;
    double draftRating = selectedRating;

    final cityController = TextEditingController(text: draftCity);

    AppBottomSheet.show(
      context,
      title: 'Filters',
      child: StatefulBuilder(
        builder: (sheetContext, setStateSheet) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: cityController,
                label: 'City',
                hint: 'Enter city',
                prefixIcon: Icons.location_on_outlined,
                textInputAction: TextInputAction.done,
                onChanged: (value) => draftCity = value.trim(),
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Price range', style: AppText.formLabel),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '₹${draftMin.toInt()}  –  ₹${draftMax.toInt()}',
                style: AppText.bodyStrong.copyWith(color: AppColors.primary),
              ),
              RangeSlider(
                values: RangeValues(draftMin, draftMax),
                min: 0,
                max: 200000,
                divisions: 50,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.pinkSurface,
                labels: RangeLabels(
                  "₹${draftMin.toInt()}",
                  "₹${draftMax.toInt()}",
                ),
                onChanged: (values) {
                  setStateSheet(() {
                    draftMin = values.start;
                    draftMax = values.end;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              Text('Minimum rating', style: AppText.formLabel),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    draftRating == 0
                        ? 'Any rating'
                        : '${draftRating.toStringAsFixed(0)}+ stars',
                    style: AppText.bodyStrong,
                  ),
                ],
              ),
              Slider(
                value: draftRating,
                min: 0,
                max: 5,
                divisions: 5,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.pinkSurface,
                label: draftRating.toStringAsFixed(0),
                onChanged: (value) => setStateSheet(() => draftRating = value),
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: PremiumButton.outlined(
                      label: 'Reset',
                      onPressed: () {
                        setState(() {
                          selectedCity = "";
                          minPrice = 0;
                          maxPrice = 200000;
                          selectedRating = 0;
                          filterCity = "";
                          filterMinPrice = 0;
                          filterMaxPrice = 200000;
                          filterMinRating = 0;
                        });
                        Navigator.pop(sheetContext);
                        _applyFiltersAndSearch();
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: 'Apply',
                      onPressed: () {
                        setState(() {
                          selectedCity = draftCity;
                          minPrice = draftMin;
                          maxPrice = draftMax;
                          selectedRating = draftRating;
                        });
                        Navigator.pop(sheetContext);
                        applyFilters();
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ).whenComplete(cityController.dispose);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildToolbar(),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Text(
              widget.subcategoryName,
              textAlign: TextAlign.center,
              style: AppText.pageTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: isList ? 'Grid view' : 'List view',
            icon: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Icon(
                isList ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
                key: ValueKey(isList),
                color: AppColors.textSecondary,
              ),
            ),
            onPressed: () => setState(() => isList = !isList),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: AppColors.divider),
                boxShadow: AppColors.shadowSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: AppText.body,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search vendors, city, name…',
                        hintStyle: AppText.body.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    Pressable(
                      onTap: () {
                        searchController.clear();
                        _applyFiltersAndSearch();
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Pressable(
            onTap: () => Navigator.push(
              context,
              AnimatedPageRoute(
                page: const AiChatScreen(),
                style: PageTransitionStyle.slideUp,
              ),
            ),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradientH,
                boxShadow: AppColors.shadowBrand,
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/shadiai-unscreen.gif',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (!isLoading)
            Expanded(
              child: Text(
                services.length == 1
                    ? '1 result'
                    : '${services.length} results',
                style: AppText.labelSm,
              ),
            )
          else
            const Spacer(),
          Pressable(
            onTap: _openFilterSheet,
            borderRadius: AppRadii.rPill,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: _hasActiveFilters
                    ? AppColors.pinkSurface
                    : AppColors.surface,
                borderRadius: AppRadii.rPill,
                border: Border.all(
                  color: _hasActiveFilters
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: _hasActiveFilters
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Filters',
                    style: AppText.buttonSm.copyWith(
                      color: _hasActiveFilters
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: isList
            ? Skeletons.listCards(count: 4, height: 210)
            : Skeletons.grid(count: 6, aspectRatio: 0.78),
      );
    }

    if (_loadError != null && services.isEmpty) {
      return ErrorState(error: _loadError, onRetry: fetchAllServices);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: fetchAllServices,
      child: services.isEmpty
          ? ListView(
              // RefreshIndicator needs a scrollable child.
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                EmptyState(
                  title: 'No vendors found',
                  message: 'Try changing your search or filters.',
                  icon: Icons.storefront_outlined,
                  actionLabel: _hasActiveFilters || searchController.text.isNotEmpty
                      ? 'Clear filters'
                      : null,
                  onAction:
                      _hasActiveFilters || searchController.text.isNotEmpty
                      ? () {
                          searchController.clear();
                          setState(() {
                            selectedCity = '';
                            minPrice = 0;
                            maxPrice = 200000;
                            selectedRating = 0;
                            filterCity = '';
                            filterMinPrice = 0;
                            filterMaxPrice = 200000;
                            filterMinRating = 0;
                          });
                          _applyFiltersAndSearch();
                        }
                      : null,
                ),
              ],
            )
          : isList
          ? _buildListView()
          : _buildGridView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        // Tuned for the compact card: 16:9 image + two text lines.
        childAspectRatio: 0.78,
      ),
      itemCount: services.length + (isLoadingMore ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= services.length) {
          return const SkeletonBox(height: double.infinity, radius: AppRadii.lg);
        }
        return FadeSlideIn(
          delay: AppMotion.staggerFor(index),
          child: _buildServiceCard(services[index], compact: true),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: services.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index >= services.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: AppLoader(),
          );
        }
        return FadeSlideIn(
          delay: AppMotion.staggerFor(index),
          child: _buildServiceCard(services[index]),
        );
      },
    );
  }

  /// Resolves the first usable image for a service. Unchanged field priority —
  /// media list → media string → media.coverImage → attributes.Portfolio.
  String _resolveImageUrl(dynamic service, Map attributes) {
    String imageUrl = '';
    final media = service['media'];
    if (media != null) {
      if (media is List && media.isNotEmpty) {
        final first = media[0];
        imageUrl = first is String ? first : (first['url'] ?? '').toString();
      } else if (media is String && media.isNotEmpty) {
        imageUrl = media;
      } else if (media is Map && media['coverImage'] != null) {
        imageUrl = media['coverImage'].toString();
      }
    }

    if (imageUrl.isEmpty) {
      final portfolio =
          attributes['Portfolio'] ??
          attributes['portfolio_urls'] ??
          attributes['portfolio'] ??
          '';
      if (portfolio is String && portfolio.isNotEmpty) {
        // portfolio might be pipe separated; take first
        imageUrl = portfolio.split('|').first;
      }
    }

    return imageUrl;
  }

  Widget _buildServiceCard(dynamic service, {bool compact = false}) {
    final attributes = service['attributes'] ?? {};
    final vendor = service['vendor'] ?? {};

    final String vendorServiceId = (service['id'] ?? '').toString();
    final String businessName =
        (vendor['businessName'] ??
                attributes['vendor_name'] ??
                attributes['Name'] ??
                '')
            .toString();
    final String city =
        (vendor['city'] ?? attributes['city'] ?? attributes['address'] ?? '')
            .toString();
    final String phone = (vendor['phone'] ?? attributes['Phone'] ?? '')
        .toString();

    // rating
    final double rating =
        double.tryParse(
          (attributes['rating'] ?? attributes['averageRating'] ?? '0')
              .toString()
              .replaceAll(',', ''),
        ) ??
        0.0;

    // price parsing
    String vegRaw =
        (attributes['veg_price'] ??
                attributes['PriceRange'] ??
                attributes['vegPrice'] ??
                '')
            .toString();
    vegRaw = vegRaw.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    final priceValue = double.tryParse(vegRaw) ?? 0.0;

    final String priceText = priceValue > 0
        ? '₹${priceValue.toInt()} / Day'
        : '—';

    final imageUrl = _resolveImageUrl(service, attributes);

    void openDetails() => Navigator.push(
      context,
      AnimatedPageRoute(
        page: VendorDetailsScreen(service: service),
        style: PageTransitionStyle.slideRight,
      ),
    );

    return AppCard(
      onTap: openDetails,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with wishlist, city and rating overlays.
          Stack(
            children: [
              NetworkImageWidget(
                url: imageUrl,
                aspectRatio: 16 / 9,
                width: double.infinity,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                memCacheWidth: compact ? 420 : 720,
                scrim: true,
              ),
              Positioned(
                right: AppSpacing.sm,
                top: AppSpacing.sm,
                child: FavoriteButton(
                  isFavorite: favouriteVendors.contains(vendorServiceId),
                  onTap: () => _toggleFavourite(vendorServiceId),
                ),
              ),
              if (city.trim().isNotEmpty)
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  right: rating > 0 ? 72 : AppSpacing.sm,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(
                          city,
                          style: AppText.caption.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (rating > 0)
                Positioned(
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successDark,
                      borderRadius: AppRadii.rSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  businessName.isEmpty ? 'Vendor' : businessName,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        city.isEmpty ? '—' : city,
                        style: AppText.cardSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      priceText,
                      style: compact ? AppText.priceSm : AppText.price,
                      maxLines: 1,
                    ),
                  ],
                ),

                // The action row is list-only: in the grid there is not enough
                // height for it, and cramming it in caused overflow.
                if (!compact) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      _ActionChip(
                        icon: const Icon(
                          Icons.call_rounded,
                          color: AppColors.successDark,
                          size: 18,
                        ),
                        label: 'Call',
                        onTap: () => _launchPhone(phone),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionChip(
                        icon: Image.asset(
                          'assets/whatsapp.png',
                          height: 20,
                          width: 20,
                        ),
                        label: 'WhatsApp',
                        onTap: () => _launchWhatsApp(phone),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ActionChip(
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.info,
                          size: 18,
                        ),
                        label: 'Message',
                        onTap: () => _openChat(
                          vendor['id']?.toString() ?? '',
                          businessName,
                        ),
                      ),
                      const Spacer(),
                      PremiumButton.text(
                        label: 'View',
                        onPressed: openDetails,
                        size: PremiumButtonSize.small,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small circular icon + caption used for the call / WhatsApp / message row.
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(child: icon),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}


// class VendorServicesScreen extends StatefulWidget {
//   final String subcategoryName;
//
//   const VendorServicesScreen({Key? key, required this.subcategoryName})
//       : super(key: key);
//
//   @override
//   State<VendorServicesScreen> createState() => _VendorServicesScreenState();
// }
//
// class _VendorServicesScreenState extends State<VendorServicesScreen> {
//   List<dynamic> services = [];
//   bool isLoading = true;
//   String? currentUserId;
//   Set<String> favouriteVendors = {};
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCurrentUser();
//     fetchServices();
//   }
//
//   Future<void> _loadCurrentUser() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       currentUserId = prefs.getInt('user_id')?.toString();
//     });
//   }
//
//   Future<void> fetchServices() async {
//     try {
//       final encodedSubcategory =
//       Uri.encodeComponent(widget.subcategoryName.toLowerCase());
//       final url = Uri.parse(
//           "https://happywedz.com/api/vendor-services?subCategory=$encodedSubcategory");
//       print("🔍 Fetching services from: $url");
//
//       final response =
//       await http.get(url, headers: {"Accept": "application/json"});
//
//       if (response.statusCode == 200) {
//         final dynamic data = json.decode(response.body);
//
//         List<dynamic> servicesList = [];
//         if (data is List) {
//           servicesList = data;
//         } else if (data is Map) {
//           if (data['data'] != null && data['data'] is List) {
//             servicesList = data['data'];
//           } else if (data['services'] != null && data['services'] is List) {
//             servicesList = data['services'];
//           } else {
//             servicesList = [data];
//           }
//         }
//
//         print("✅ Found ${servicesList.length} services");
//
//         setState(() {
//           services = servicesList;
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//         print("❌ Error fetching services: ${response.statusCode}");
//       }
//     } catch (e, stackTrace) {
//       setState(() => isLoading = false);
//       print("💥 API Error: $e");
//       print("Stack trace: $stackTrace");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildAppBar(),
//               _buildSearchBar(),
//               Expanded(
//                 child: isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : services.isEmpty
//                     ? const Center(child: Text("No services found"))
//                     : SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: services
//                         .map((service) => _buildServiceCard(service))
//                         .toList(),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAppBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           Expanded(
//             child: Text(
//               widget.subcategoryName,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 48),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.9),
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: const TextField(
//           decoration: InputDecoration(
//             hintText: 'Search services...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildServiceCard(dynamic service) {
//     final attributes = service['attributes'] ?? {};
//     final vendor = service['vendor'] ?? {};
//
//     final String businessName = vendor['businessName'] ??
//         vendor['vendor_name'] ??
//         attributes['name'] ??
//         attributes['vendor_name'] ??
//         'Unnamed Venue';
//
//     final String city =
//         vendor['city'] ?? attributes['city'] ?? 'Unknown Location';
//
//     final double rating = double.tryParse(
//         (vendor['rating'] ?? attributes['rating'] ?? '0').toString()) ??
//         0.0;
//
//     final String phone =
//         vendor['phone']?.toString() ?? attributes['Phone']?.toString() ?? '';
//
//     String priceText = '';
//     final vegPrice = attributes['veg_price']?.toString() ?? '';
//     final startingPrice = attributes['starting_price']?.toString() ?? '';
//     final photoPackagePrice = attributes['photo_package_price']?.toString() ??
//         attributes['PhotoPackage_Price']?.toString() ??
//         '';
//
//     if (vegPrice.isNotEmpty) {
//       priceText = '₹$vegPrice per plate';
//     } else if (startingPrice.isNotEmpty) {
//       priceText = '₹$startingPrice onwards';
//     } else if (photoPackagePrice.isNotEmpty) {
//       priceText = photoPackagePrice;
//     }
//
//     String imageUrl = 'https://via.placeholder.com/400x300';
//     final media = service['media'];
//     if (media != null) {
//       if (media is Map && media['coverImage'] != null) {
//         imageUrl = media['coverImage'].toString();
//       } else if (media is List && media.isNotEmpty) {
//         final first = media[0];
//         if (first is Map && first['url'] != null) {
//           imageUrl = first['url'];
//         } else if (first is String) {
//           imageUrl = first;
//         }
//       }
//       if (imageUrl.startsWith('/uploads/')) {
//         imageUrl = "https://happywedzbackend.happywedz.com$imageUrl";
//       }
//     }
//
//     final vendorServiceId = service['id']?.toString() ?? '';
//
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => VendorDetailsScreen(service: service),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.08),
//               blurRadius: 8,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🖼 IMAGE & OVERLAYS
//             Stack(
//               children: [
//                 ClipRRect(
//                   borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(8), topRight: Radius.circular(8)),
//                   child: Image.network(
//                     imageUrl,
//                     height: 200,
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (context, error, stackTrace) => Container(
//                       height: 200,
//                       color: Colors.grey[300],
//                       child: const Icon(Icons.image,
//                           size: 50, color: Colors.white),
//                     ),
//                   ),
//                 ),
//                 // 📍 Location
//                 Positioned(
//                   bottom: 8,
//                   left: 8,
//                   child: Container(
//                     padding:
//                     const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.6),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const Icon(Icons.location_on,
//                             color: Colors.white, size: 12),
//                         const SizedBox(width: 4),
//                         Text(
//                           city,
//                           style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 11,
//                               fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // ⭐ Rating
//                 if (rating > 0)
//                   Positioned(
//                     top: 8,
//                     right: 48,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text(
//                             rating.toStringAsFixed(1),
//                             style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(width: 2),
//                           const Icon(Icons.star,
//                               color: Colors.white, size: 12),
//                         ],
//                       ),
//                     ),
//                   ),
//                 // ❤️ Favourite Button
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: InkWell(
//                     onTap: () => _toggleFavourite(vendorServiceId),
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.85),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         favouriteVendors.contains(vendorServiceId)
//                             ? Icons.favorite
//                             : Icons.favorite_border,
//                         color: Colors.pinkAccent,
//                         size: 20,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // 🧾 Details Section
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     businessName,
//                     style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black87),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   if (priceText.isNotEmpty)
//                     Text(
//                       priceText,
//                       style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Color(0xFFE91E63)),
//                     ),
//                   const SizedBox(height: 12),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () async {
//                             final loggedIn = await ensureLoggedIn(context);
//                             if (!loggedIn) return;
//
//                             final vendorId = service['vendor_id']?.toString() ??
//                                 vendor['id']?.toString() ??
//                                 attributes['vendor_id']?.toString() ??
//                                 '';
//
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (_) => ChatPage(
//                                   currentUid: currentUserId ?? '',
//                                   otherUid: vendorId,
//                                   otherName: businessName,
//                                 ),
//                               ),
//                             );
//                           },
//                           icon: const Icon(Icons.message, size: 16),
//                           label: const Text('Message'),
//                           style: OutlinedButton.styleFrom(
//                             foregroundColor: const Color(0xFFE91E63),
//                             side: const BorderSide(color: Color(0xFFE91E63)),
//                             padding:
//                             const EdgeInsets.symmetric(vertical: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       _iconButton(
//                         icon: Icons.chat,
//                         color: const Color(0xFF25D366),
//                         onPressed: () async {
//                           final loggedIn = await ensureLoggedIn(context);
//                           if (!loggedIn) return;
//                           if (phone.isNotEmpty) {
//                             final uri = Uri.parse("https://wa.me/$phone");
//                             launchUrl(uri);
//                           }
//                         },
//                       ),
//                       const SizedBox(width: 8),
//                       _iconButton(
//                         icon: Icons.phone,
//                         color: Colors.green,
//                         onPressed: () {
//                           if (phone.isNotEmpty) {
//                             final uri = Uri(scheme: 'tel', path: phone);
//                             launchUrl(uri);
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _iconButton(
//       {required IconData icon,
//         required Color color,
//         required VoidCallback onPressed}) {
//     return Container(
//       height: 40,
//       width: 40,
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: IconButton(
//         icon: Icon(icon, color: Colors.white, size: 18),
//         onPressed: onPressed,
//         padding: EdgeInsets.zero,
//       ),
//     );
//   }
//
//   Future<void> _toggleFavourite(String vendorServiceId) async {
//     if (currentUserId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please sign in first")),
//       );
//       return;
//     }
//
//     final isFav = favouriteVendors.contains(vendorServiceId);
//     setState(() {
//       if (isFav) {
//         favouriteVendors.remove(vendorServiceId);
//       } else {
//         favouriteVendors.add(vendorServiceId);
//       }
//     });
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token') ?? '';
//
//     print('🟢 Current userId: $currentUserId');
//     print('🔑 Token (first 20 chars): ${token.isNotEmpty ? token.substring(0, 20) : "EMPTY"}...');
//     print('⭐ Vendor Service ID: $vendorServiceId');
//
//     if (token.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Please login again')));
//       return;
//     }
//
//     final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
//     final body = {
//       'user_id': currentUserId.toString(),
//       'vendor_services_id': vendorServiceId.toString(),
//     };
//
//     try {
//       print('🌍 Sending POST → $url');
//       print('📦 Headers: {Content-Type: application/json, Authorization: Bearer $token}');
//       print('📦 Body: $body');
//
//       final response = await http.post(
//         url,
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: jsonEncode(body), // ✅ match JSON structure
//       );
//
//       print('📬 Response status: ${response.statusCode}');
//       print('📬 Response body: ${response.body}');
//
//       if (response.statusCode == 200) {
//         final res = jsonDecode(response.body);
//         final msg = res['message'] ?? 'Wishlist updated';
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//       } else if (response.statusCode == 401) {
//         print('🚫 401 Unauthorized → Token invalid or expired.');
//         ScaffoldMessenger.of(context)
//             .showSnackBar(const SnackBar(content: Text('Session expired. Please log in again.')));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${response.statusCode}')),
//         );
//       }
//     } catch (e) {
//       print('❌ Exception in toggleFavourite: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Something went wrong')),
//       );
//     }
//   }
//
//   Future<bool> ensureLoggedIn(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('auth_token');
//     if (token == null || token.isEmpty) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(const SnackBar(content: Text('Please login first')));
//       return false;
//     }
//     return true;
//   }
// }






// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Put this file in your lib/ folder and import where needed.
// Make sure pubspec.yaml includes:
//  http, shared_preferences, carousel_slider, flutter_html, url_launcher, share_plus
// And add an asset for whatsapp at assets/icons/whatsapp.png (optional)


class VendorDetailsScreen extends StatefulWidget {
  final dynamic service;
  final String? slug;
  const VendorDetailsScreen({Key? key, this.service, this.slug}) : super(key: key);

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen>
    with SingleTickerProviderStateMixin {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentCarouselIndex = 0;
  bool _aboutExpanded = false;
  DateTime? _selectedDate;
  bool _isShortlisted = false;
  String? currentUserId;
  bool isPageLoading = false;
  dynamic fetchedService;

  // Reviews
  bool isReviewsLoading = false;
  bool reviewsError = false;
  double apiAverageRating = 0.0;
  int apiTotalReviews = 0;
  List<Map<String, dynamic>> reviews = [];


  bool isClaimLoading = true;
  bool hasClaim = false;
  bool canSubmit = true;
  String claimStatus = "";
  String? rejectionReason;
  int? claimId;


  @override
  void initState() {
    super.initState();
    loadFavouritesFromLocal();
    _loadCurrentUser();

    String? serviceId;
    if (widget.service != null) {
      final idVal = widget.service['id'] ?? widget.service['vendor_services_id'] ?? widget.service['attributes']?['id'];
      if (idVal != null) {
        serviceId = idVal.toString();
      }
    }

    if (serviceId != null && serviceId.isNotEmpty) {
      fetchServiceById(serviceId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchReviewsFromApi();
      });
      checkClaimStatus();
    } else if (widget.slug != null && widget.slug!.isNotEmpty) {
      fetchServiceBySlug(widget.slug!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchReviewsFromApi();
      });
      checkClaimStatus();
    }
  }

  Future<void> fetchServiceById(String id) async {
    final bool showFullPageLoader = widget.service == null || widget.service.isEmpty;

    if (showFullPageLoader) {
      setState(() {
        isPageLoading = true;
      });
    }

    try {
      final url = Uri.parse('https://happywedz.com/api/vendor-services/$id');
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final bodyData = jsonDecode(response.body);
        if (bodyData is Map) {
          setState(() {
            fetchedService = bodyData;
          });
          // Re-trigger review and claim check with the full fetched data
          fetchReviewsFromApi();
          checkClaimStatus();
        }
      }
    } catch (e) {
      print("Error fetching by ID: $e");
    }

    if (showFullPageLoader) {
      setState(() {
        isPageLoading = false;
      });
    }
  }

  Future<void> fetchServiceBySlug(String slug) async {
    setState(() {
      isPageLoading = true;
    });

    // 1. Try to extract ID from slug (ends with -[id])
    String? serviceId;
    final parts = slug.split('-');
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      if (int.tryParse(lastPart) != null) {
        serviceId = lastPart;
      }
    }

    dynamic foundService;

    if (serviceId != null) {
      try {
        final url = Uri.parse('https://happywedz.com/api/vendor-services/$serviceId');
        final response = await http.get(url, headers: {'Accept': 'application/json'});
        if (response.statusCode == 200) {
          final bodyData = jsonDecode(response.body);
          if (bodyData is Map) {
            foundService = bodyData;
          }
        }
      } catch (e) {
        print("Error fetching by ID: $e");
      }
    }

    // 2. If not found, try searching by slug
    if (foundService == null) {
      try {
        final url = Uri.parse('https://happywedz.com/api/vendor-services?search=$slug');
        final response = await http.get(url, headers: {'Accept': 'application/json'});
        if (response.statusCode == 200) {
          final bodyData = jsonDecode(response.body);
          final dataList = bodyData['data'];
          if (dataList is List && dataList.isNotEmpty) {
            // Find matching slug
            foundService = dataList.firstWhere(
              (element) {
                final elemSlug = element['slug']?.toString() ?? element['attributes']?['slug']?.toString() ?? '';
                return elemSlug.toLowerCase() == slug.toLowerCase();
              },
              orElse: () => dataList.first,
            );
          }
        }
      } catch (e) {
        print("Error fetching by slug search: $e");
      }
    }

    if (foundService != null) {
      setState(() {
        fetchedService = foundService;
        isPageLoading = false;
      });
      // Now that the service is loaded, trigger review fetch and claim status check
      fetchReviewsFromApi();
      checkClaimStatus();
    } else {
      setState(() {
        isPageLoading = false;
      });
    }
  }
  Future<void> checkClaimStatus() async {
    final service = fetchedService ?? widget.service;
    if (service == null || service['id'] == null) return;

    final url = Uri.parse(
        "https://happywedz.com/api/business/claims/check-status?"
            "vendor_id=${service['id']}&vendor_subcategory_data_id=${service['vendor_subcategory_id']}"
    );

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          hasClaim = data["hasClaim"];
          canSubmit = data["canSubmit"];
          claimStatus = data["claimStatus"] ?? "";
          claimId = data["claimId"];
          rejectionReason = data["rejectionReason"];
          isClaimLoading = false;
        });
      } else {
        setState(() => isClaimLoading = false);
      }
    } catch (e) {
      print("STATUS ERROR: $e");
      setState(() => isClaimLoading = false);
    }
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getInt('user_id')?.toString();
    });
  }

  // ---------------------------
  // Helper parsers (kept from your code)
  // ---------------------------
  String normalizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';

    if (url.startsWith('//')) {
      return 'https:$url';
    }

    if (url.startsWith('/uploads/')) {
      return "https://happywedzbackend.happywedz.com$url";
    }

    return url;
  }

  List<String> extractImages(dynamic media, dynamic vendor, dynamic attributes, bool imageExists) {
    final Set<String> images = {};

    void add(String? url) {
      if (url == null || url.trim().isEmpty) return;
      final u = normalizeUrl(url);
      if (u.startsWith('http')) {
        images.add(u);
      }
    }

    if (imageExists) {
      // media as List
      if (media is List) {
        for (final item in media) {
          if (item is String) {
            add(item);
          } else if (item is Map) {
            add(item['original_url']);
            add(item['url']);
            add(item['thumb']);
          }
        }
      }

      // media as Map
      if (media is Map) {
        add(media['original_url']);
        add(media['url']);
        add(media['coverImage']);
      }

      // portfolio fallback from attributes
      if (images.isEmpty && attributes is Map) {
        final portfolio = attributes['Portfolio'] ?? attributes['portfolio_urls'] ?? attributes['portfolio'] ?? '';
        if (portfolio is String && portfolio.isNotEmpty) {
          for (final item in portfolio.split('|')) {
            add(item);
          }
        }
      }
    }

    // fallback to vendor profile image
    if (images.isEmpty && vendor is Map) {
      add(vendor['profileImage']);
    }

    // final fallback
    if (images.isEmpty) {
      images.add(
        'https://via.placeholder.com/1200x700?text=No+Image',
      );
    }

    return images.toList();
  }

  List<Map<String, String>> parseArea(String areaRaw) {
    final parts = <String>[];
    if (areaRaw == null) return [];
    if (areaRaw.trim().isEmpty) return [];
    for (var p in areaRaw.split(RegExp(r',\s*'))) {
      final cleaned = p.trim();
      if (cleaned.isNotEmpty) parts.add(cleaned);
    }
    final List<Map<String, String>> out = [];
    for (var p in parts) {
      final seatingMatch =
      RegExp(r'(\d+)\s*Seating', caseSensitive: false).firstMatch(p);
      final floatMatch =
      RegExp(r'(\d+)\s*Floating', caseSensitive: false).firstMatch(p);
      final titleCandidate =
          RegExp(r'^[A-Za-z0-9\s\-&():]+').stringMatch(p) ?? p;
      out.add({
        'title': titleCandidate.trim(),
        'seating': seatingMatch?.group(1) ?? '',
        'floating': floatMatch?.group(1) ?? '',
        'raw': p,
      });
    }
    return out;
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is num) return value > 0;
    return true;
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) {
      AppSnackbar.info(context, 'Phone number not available for this vendor.');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppSnackbar.error(context, "We couldn't start the call on this device.");
    }
  }

  Future<void> _launchWhatsApp(String phone, {String? text}) async {
    if (phone.isEmpty || phone == '0000000000') {
      AppSnackbar.info(context, 'WhatsApp is not available for this vendor.');
      return;
    }
    final encoded = Uri.encodeComponent(text ?? "Hi, I'm interested in your services.");
    final url = Uri.parse("https://wa.me/$phone?text=$encoded");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      AppSnackbar.error(context, "We couldn't open WhatsApp on this device.");
    }
  }

  // ---------------------------
  // Reviews API fetch
  // ---------------------------
  Future<void> fetchReviewsFromApi({int page = 1, int limit = 20}) async {
    // Try to determine vendorId from service passed in
    final service = fetchedService ?? widget.service ?? {};
    final vendorMap = (service['vendor'] is Map) ? Map<String, dynamic>.from(service['vendor']) : <String, dynamic>{};
    final attributes = (service['attributes'] is Map) ? Map<String, dynamic>.from(service['attributes']) : <String, dynamic>{};
    final String vendorId = (vendorMap['id'] ?? attributes['vendor_id'] ?? '').toString();

    if (vendorId.isEmpty) {
      setState(() {
        reviewsError = true;
        isReviewsLoading = false;
      });
      return;
    }

    setState(() {
      isReviewsLoading = true;
      reviewsError = false;
    });

    try {
      // <-- Adjust endpoint if your backend uses a different path/params -->
      final url = Uri.parse(
          "https://happywedz.com/api/vendor-reviews?vendorId=$vendorId&page=$page&limit=$limit");
      final res = await http.get(url, headers: {'Accept': 'application/json'});

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(res.body);

        // Expecting structure: { data: [reviews...], meta: { avgRating, totalReviews } }
        final List<dynamic> list = jsonData['data'] ?? jsonData['reviews'] ?? [];
        final meta = jsonData['meta'] ?? jsonData['pagination'] ?? jsonData['summary'] ?? {};

        final parsed = list.map<Map<String, dynamic>>((item) {
          // normalize common fields if backend varies
          return {
            'id': item['id'] ?? item['review_id'] ?? '',
            'rating': (item['rating'] ?? item['rate'] ?? 0).toString(),
            'title': item['title'] ?? '',
            'comment': item['comment'] ?? item['review'] ?? item['description'] ?? '',
            'userName': item['userName'] ?? item['user_name'] ?? item['user'] ?? 'Guest',
            'createdAt': item['createdAt'] ?? item['created_at'] ?? item['date'] ?? '',
          };
        }).toList();

        setState(() {
          reviews = parsed;
          apiAverageRating =
              double.tryParse((meta['avgRating'] ?? meta['averageRating'] ?? meta['average_rating'] ?? '0').toString()) ?? 0.0;
          apiTotalReviews = int.tryParse((meta['totalReviews'] ?? meta['total_reviews'] ?? meta['count'] ?? parsed.length).toString()) ?? parsed.length;
          isReviewsLoading = false;
          reviewsError = false;
        });
      } else {
        setState(() {
          reviewsError = true;
          isReviewsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        reviewsError = true;
        isReviewsLoading = false;
      });
      debugPrint("Reviews API error: $e");
    }
  }
  Widget claimButton(String vendorId, String vendorSubcategoryId) {
    if (isClaimLoading) {
      return ElevatedButton(
        onPressed: () {},
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // APPROVED
    if (claimStatus == "approved") {
      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Business Claim Approved"),
              content: Text("Your claim is approved. You cannot submit again."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"))
              ],
            ),
          );
        },
        icon: Icon(Icons.check_circle, color: Colors.white),
        label: Text("Approved",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // PENDING
    if (claimStatus == "pending") {
      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Pending Review"),
              content: Text("Your claim is under review."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"))
              ],
            ),
          );
        },
        icon: Icon(Icons.hourglass_top, color: Colors.white),
        label: Text("Pending",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // REJECTED
    if (claimStatus == "rejected") {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessClaimForm(
                vendorId: vendorId,
                vendorSubcategoryId: vendorSubcategoryId,
              ),
            ),
          );
        },
        icon: Icon(Icons.cancel, color: Colors.white),
        label: Text("Rejected – Resubmit",style: TextStyle(color: Colors.white),),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    // DEFAULT — SHOW CLAIM FORM BUTTON
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessClaimForm(
              vendorId: vendorId,
              vendorSubcategoryId: vendorSubcategoryId,
            ),
          ),
        );
      },
      icon: Icon(Icons.business_center_outlined, color: Colors.white),
      label: Text("Claim Your Business",style: TextStyle(color: Colors.white),),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.pink,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  // ---------------------------
  // Wishlist toggle (placeholder — wire to your backend)
  // ---------------------------
  // Future<void> toggleWishlist() async {
  //   setState(() => _isShortlisted = !_isShortlisted);
  //   // TODO: call your API to persist wishlist state
  //   // Example:
  //   // await http.post(Uri.parse('https://your.api/wishlist'), body: {...});
  // }
  Set<String> favouriteVendors = {};
  Future<void> saveFavouritesToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList("favourite_vendors", favouriteVendors.toList());
  }

  Future<void> loadFavouritesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList("favourite_vendors") ?? [];
    setState(() {
      favouriteVendors = savedList.toSet();
    });
  }

  Future<void> toggleWishlist(String vendorServiceId) async {
    if (currentUserId == null) {
      AppSnackbar.info(context, 'Please sign in to manage your wishlist.');
      return;
    }

    final isFav = favouriteVendors.contains(vendorServiceId);

    setState(() {
      if (isFav)
        favouriteVendors.remove(vendorServiceId);
      else
        favouriteVendors.add(vendorServiceId);
    });

    // SAVE LOCALLY
    saveFavouritesToLocal();

    // Optional: Call API
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isEmpty) return;

      final url = Uri.parse('https://happywedz.com/api/wishlist/toggle');
      final body = jsonEncode({
        'user_id': currentUserId.toString(),
        'vendor_services_id': vendorServiceId,
      });

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
    } catch (e) {
      print("Wishlist API error: $e");
    }
  }



  void open360Viewer(
      BuildContext context,
      List<ImageProvider> images,
      ) {
    if (images.length < 2) {
      AppSnackbar.info(context, 'A 360° view is not available for this vendor.');
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) {
        bool autoRotate = true;

        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Stack(
                  children: [
                    // ✅ 360 VIEW
                    Center(
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: ImageView360(
                          key: UniqueKey(),
                          imageList: images,
                          autoRotate: autoRotate,
                          rotationCount: images.length,
                          swipeSensitivity: 2,
                          allowSwipeToRotate: true,
                        ),
                      ),
                    ),

                    // ✅ CLOSE
                    Positioned(
                      top: 12,
                      left: 12,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // ✅ PLAY / PAUSE
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              autoRotate
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 44,
                            ),
                            onPressed: () {
                              setState(() => autoRotate = !autoRotate);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    if (isPageLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Skeletons.detail(heroHeight: 300)),
      );
    }

    final service = fetchedService ?? widget.service ?? <String, dynamic>{};
    final String vendorServiceId = (service['id'] ?? '').toString();

    final attributes = (service['attributes'] is Map) ? Map<String, dynamic>.from(service['attributes']) : <String, dynamic>{};
    final vendor = (service['vendor'] is Map) ? Map<String, dynamic>.from(service['vendor']) : <String, dynamic>{};
    // final media = (service['media'] is List) ? List.from(service['media']) : [];
    //
    // // Build images list
    // final List<String> images = [];
    // for (var item in media) {
    //   if (item is String && item.isNotEmpty) {
    //     images.add(normalizeUrl(item));
    //   } else if (item is Map && item['url'] != null) {
    //     images.add(normalizeUrl(item['url'].toString()));
    //   }
    // }
    // if (images.isEmpty) images.add('https://via.placeholder.com/1200x700?text=No+Image');
    final rawImageExists = service['image_exists'] ?? attributes['image_exists'];
    final bool imageExists = rawImageExists != false && rawImageExists != 'false';
    final List<String> images = extractImages(service['media'], vendor, attributes, imageExists);
    print("IMAGES COUNT: ${images.length}");
    images.forEach(print);

    final String vendorId = (vendor['id'] ?? attributes['vendor_id'] ?? '').toString();
    final String vendorSubcategoryId = (service['vendor_subcategory_id'] ?? attributes['vendor_subcategory_id'] ?? '').toString();
    final String vendorName = (attributes['vendor_name'] ?? attributes['Name'] ?? vendor['businessName'] ?? 'No Name').toString();
    final String city = (attributes['city'] ?? vendor['city'] ?? '').toString();
    final String address = (attributes['address'] ?? attributes['Address'] ?? '').toString();
    final String aboutRaw = (attributes['about_us'] ?? attributes['Aboutus'] ?? '').toString();
    final String about = aboutRaw.replaceAll(r'\n', '').replaceAll(r'\"', '"').replaceAll(r'\\', '').trim();
    final String phone = (vendor['phone'] ?? attributes['Phone'] ?? '').toString();

    print("Vendor ID: $vendorId");
    print("Vendor Subcategory ID: $vendorSubcategoryId");
    final double rating =
        double.tryParse((vendor['rating'] ?? attributes['rating'] ?? apiAverageRating ?? '0').toString()) ?? apiAverageRating;
    final int reviewCount = int.tryParse((vendor['review_count'] ?? attributes['review_count'] ?? apiTotalReviews ?? '0').toString()) ?? apiTotalReviews;
    final String vendorType = (vendor['vendorType']?['name'] ?? attributes['vendor_type'] ?? '').toString();

    final String vegPrice = (attributes['veg_price'] ?? '').toString();
    final String nonVegPrice = (attributes['non_veg_price'] ?? '').toString();

    final seatingList = parseArea((attributes['area'] ?? ''));

    // Visual theme colors
    final primaryAccent = Colors.pink.shade600;

    // // Parse lat & lng carefully (they might be num or String)
    // dynamic latRaw = attributes['latitude'] ?? attributes['lat'] ?? attributes['Latitude'] ?? attributes['LATITUDE'];
    // dynamic lngRaw = attributes['longitude'] ?? attributes['lng'] ?? attributes['lon'] ?? attributes['Longitude'] ?? attributes['LONGITUDE'];
    //
    // double? latitude;
    // double? longitude;
    //
    // if (latRaw != null) {
    //   if (latRaw is num) latitude = latRaw.toDouble();
    //   else if (latRaw is String) latitude = double.tryParse(latRaw);
    // }
    //
    // if (lngRaw != null) {
    //   if (lngRaw is num) longitude = lngRaw.toDouble();
    //   else if (lngRaw is String) longitude = double.tryParse(lngRaw);
    // }
    double? latitude;
    double? longitude;

// 1️⃣ From attributes
    dynamic latRaw = attributes['latitude'] ??
        attributes['lat'] ??
        attributes['Latitude'] ??
        attributes['LATITUDE'];

    dynamic lngRaw = attributes['longitude'] ??
        attributes['lng'] ??
        attributes['lon'] ??
        attributes['Longitude'] ??
        attributes['LONGITUDE'];

// 2️⃣ From vendor
    latRaw ??= vendor['latitude'] ?? vendor['lat'];
    lngRaw ??= vendor['longitude'] ?? vendor['lng'];

// 3️⃣ From service root
    latRaw ??= service['latitude'] ?? service['lat'];
    lngRaw ??= service['longitude'] ?? service['lng'];

// 4️⃣ From attributes.location
    if (latRaw == null || lngRaw == null) {
      final location = attributes['location'] ?? vendor['location'];
      if (location is Map) {
        latRaw ??= location['latitude'];
        lngRaw ??= location['longitude'];
      }
    }

// 5️⃣ From lat_lng string
    if (latRaw == null || lngRaw == null) {
      final latLng =
          attributes['lat_lng'] ??
              vendor['lat_lng'] ??
              service['lat_lng'];
      if (latLng is String && latLng.contains(',')) {
        final parts = latLng.split(',');
        latRaw ??= parts[0];
        lngRaw ??= parts[1];
      }
    }

// ✅ Parse safely
    if (latRaw is num) latitude = latRaw.toDouble();
    if (lngRaw is num) longitude = lngRaw.toDouble();

    if (latRaw is String) latitude ??= double.tryParse(latRaw.trim());
    if (lngRaw is String) longitude ??= double.tryParse(lngRaw.trim());

    print("✅ FINAL LAT LNG => $latitude , $longitude");

    Future<void> openMap(double lat, double lng) async {
      final Uri geoUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");

      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        // fallback to browser
        final webUrl = Uri.parse("https://maps.google.com/?q=$lat,$lng");
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
    final String? panoramaImage = attributes['panorama_image'] as String?;
    final bool hasPanorama = panoramaImage != null && panoramaImage.isNotEmpty;



    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar overlay on carousel
                    Stack(
                      children: [
                        // Carousel
                        CarouselSlider.builder(
                          carouselController: _controller,
                          itemCount: images.length,
                          itemBuilder: (context, index, real) {
                            final img = images[index];
                            return NetworkImageWidget(
                              url: img,
                              width: double.infinity,
                              height: 300,
                              memCacheWidth: 1080,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1,
                            autoPlay: images.length > 1,
                            onPageChanged: (i, r) => setState(() => _currentCarouselIndex = i),
                          ),
                        ),
                        // Positioned(
                        //   right: 16,
                        //   bottom: 20,
                        //   child: ElevatedButton.icon(
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: Colors.black.withOpacity(0.7),
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        //     ),
                        //     icon: const Icon(Icons.threed_rotation, color: Colors.white),
                        //     label: const Text("360° View", style: TextStyle(color: Colors.white)),
                        //     onPressed: () {
                        //       final List<ImageProvider> providers =
                        //       images.map((e) => NetworkImage(e)).toList();
                        //
                        //       open360Viewer(context, providers);
                        //     },
                        //
                        //
                        //   ),
                        // ),

                        // Top controls
                        Positioned(
                          top: 8,
                          left: 6,
                          right: 6,
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.black.withOpacity(0.45),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              const Spacer(),
                              // Share
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black.withOpacity(0.45),
                                child: IconButton(
                                  icon: const Icon(Icons.share, color: Colors.white, size: 20),
                                  onPressed: () {
                                    final shareLink = attributes['URL']?.toString() ?? attributes['url']?.toString() ?? '';
                                    if (shareLink.isNotEmpty) {
                                      Share.share(shareLink);
                                    } else {
                                      AppSnackbar.info(context, 'There is no link to share yet.');
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // WhatsApp icon (asset fallback to Icon)
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.green.shade600,
                                child: IconButton(
                                  icon: Image.asset(
                                    'assets/icons/whatsapp.png',
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (ctx, e, st) => const Icon(Icons.sms, color: Colors.white),
                                  ),
                                  onPressed: () => _launchWhatsApp(phone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Wishlist toggle
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white.withOpacity(0.85),
                                child: IconButton(
                                  icon: Icon(
                                    favouriteVendors.contains(vendorServiceId)
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: primaryAccent,
                                  ),
                                  onPressed: () => toggleWishlist(vendorServiceId),
                                ),

                              ),
                            ],
                          ),
                        ),

                        // bottom-left overlay info
                        Positioned(
                          left: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vendorName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, color: Colors.white.withOpacity(0.85), size: 14),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 180,
                                          child: Text(
                                            city,
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star, color: Colors.orange.shade700, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        rating > 0 ? rating.toStringAsFixed(1) : (apiAverageRating > 0 ? apiAverageRating.toStringAsFixed(1) : '—'),
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // dots indicator
                    if (images.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: images.asMap().entries.map((e) {
                              final active = _currentCarouselIndex == e.key;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: active ? 26 : 8,
                                decoration: BoxDecoration(
                                  color: active ? Colors.black87 : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    // Main content card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // name + actions row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(vendorName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade700),
                                        const SizedBox(width: 6),
                                        Expanded(child: Text('$city ${address.isNotEmpty ? "· $address" : ""}', style: TextStyle(color: Colors.grey.shade700))),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  // Price preview
                                  if (_hasValue(vegPrice) || _hasValue(nonVegPrice))
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 6)],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(_hasValue(vegPrice) ? '₹$vegPrice' : _hasValue(nonVegPrice) ? '₹$nonVegPrice' : '--',
                                              style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 4),
                                          const Text('Per plate', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // chips / quick info
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _infoChip(vendorType, Icons.business),
                              if (_hasValue(vegPrice)) _infoChip('₹$vegPrice / plate', Icons.restaurant),
                              if (_hasValue(nonVegPrice)) _infoChip('Non-veg ₹$nonVegPrice', Icons.fastfood),
                              if (seatingList.isNotEmpty) _infoChip('${seatingList.length} spaces', Icons.people),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Claim / contact actions
                          Row(
                            children: [
                              Expanded(child: claimButton(vendorId, vendorSubcategoryId)),

                              // Expanded(
                              //   child:
                              //   ElevatedButton.icon(
                              //
                              //     onPressed: () {
                              //       // claim
                              //       Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //           builder: (_) => BusinessClaimForm(
                              //             vendorId: vendorId,
                              //             vendorSubcategoryId: vendorSubcategoryId,
                              //
                              //           ),
                              //         ),
                              //       );
                              //
                              //     },
                              //     icon: const Icon(Icons.business_center_outlined,color: Colors.white,),
                              //     label: const Text('Claim Your Business',style: TextStyle(color: Colors.white),),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: primaryAccent,
                              //       padding: const EdgeInsets.symmetric(vertical: 12),
                              //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: IconButton(
                  tooltip: 'View on map',
                  icon: const Icon(Icons.location_on_sharp),
                    onPressed: () async {
                      if (latitude != null && longitude != null) {
                        await openMap(latitude!, longitude!);
                      } else if (address.isNotEmpty || city.isNotEmpty) {
                        final query = Uri.encodeComponent("$vendorName $address $city");
                        final fallback = Uri.parse(
                          "geo:0,0?q=$query",
                        );
                        await launchUrl(
                          fallback,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        AppSnackbar.info(context, 'Location not available for this vendor.');
                      }
                    }
                ),
              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Pricing card
                          if (_hasValue(vegPrice) || _hasValue(nonVegPrice))
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      const Text('Pricing', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      if (_hasValue(vegPrice)) Text('Veg: ₹$vegPrice / plate', style: const TextStyle(color: Colors.grey)),
                                      if (_hasValue(nonVegPrice)) Text('Non-veg: ₹$nonVegPrice / plate', style: const TextStyle(color: Colors.grey)),
                                    ]),
                                    // const Spacer(),
                                    // ElevatedButton(
                                    //   onPressed: () async {
                                    //     final picked = await showDatePicker(
                                    //       context: context,
                                    //       initialDate: _selectedDate ?? DateTime.now(),
                                    //       firstDate: DateTime.now(),
                                    //       lastDate: DateTime(DateTime.now().year + 2),
                                    //     );
                                    //     if (picked != null) {
                                    //       setState(() => _selectedDate = picked);
                                    //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checked availability: ${picked.day}/${picked.month}/${picked.year}')));
                                    //     }
                                    //   },
                                    //   child: const Text('Check availability',style: TextStyle(color: Colors.white),),
                                    //   style: ElevatedButton.styleFrom(
                                    //     backgroundColor: primaryAccent,
                                    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    //   ),
                                    // )
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Portfolio (thumbnails)
                          if (images.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 110,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    itemBuilder: (ctx, idx) {
                                      return Container(
                                        width: 150,
                                        margin: EdgeInsets.only(right: idx == images.length - 1 ? 0 : 10),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          image: DecorationImage(image: NetworkImage(images[idx]), fit: BoxFit.cover),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // About
                          if (_hasValue(about))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                AnimatedCrossFade(
                                  firstChild: SizedBox(
                                    height: 140,
                                    child: SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: Html(
                                        data: about,
                                        style: {
                                          "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero, fontSize: FontSize(15), color: Colors.black87),
                                        },
                                      ),
                                    ),
                                  ),
                                  secondChild: Html(data: about),
                                  crossFadeState: _aboutExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 250),
                                ),
                                if ((about.length) > 250)
                                  TextButton(onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded), child: Text(_aboutExpanded ? 'Read less' : 'Read more')),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // Policies (if any)
                          if (_hasValue(attributes['decor_policy']) || _hasValue(attributes['catering_policy']))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Policies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                if (_hasValue(attributes['decor_policy'])) Text('• Decor: ${attributes['decor_policy']}', style: const TextStyle(height: 1.4)),
                                if (_hasValue(attributes['catering_policy'])) Text('• Catering: ${attributes['catering_policy']}', style: const TextStyle(height: 1.4)),
                              ],
                            ),

                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                                color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: IconButton(
                              tooltip: 'Write a review',
                              icon: const Icon(Icons.rate_review_outlined),
                              onPressed: ()  {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecommendVendorScreen(
                                      vendorId: vendorId,
                                      vendorName: vendorName,
                                      vendorImage: images.isNotEmpty ? images[0] : null,
                                      currentUserId: currentUserId,
                                    ),
                                  ),
                                );
                                print('Reviews');
                                print("Vendor ID: $vendorId");
                                  print(currentUserId);
                                  print(vendorName);

                              },
                            ),
                          )



                          // Ratings summary + call to fetch reviews
                          // Card(
                          //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(12),
                          //     child: Column(
                          //       children: [
                          //         Row(
                          //           children: [
                          //             Column(
                          //               crossAxisAlignment: CrossAxisAlignment.start,
                          //               children: [
                          //                 Text(
                          //                   apiAverageRating > 0 ? apiAverageRating.toStringAsFixed(1) : rating > 0 ? rating.toStringAsFixed(1) : '—',
                          //                   style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.pink),
                          //                 ),
                          //                 Row(
                          //                   children: [
                          //                     Icon(Icons.star, color: Colors.pink.shade400),
                          //                     const SizedBox(width: 6),
                          //                     Text('${apiTotalReviews > 0 ? apiTotalReviews : reviewCount} Reviews', style: const TextStyle(color: Colors.black54)),
                          //                   ],
                          //                 ),
                          //               ],
                          //             ),
                          //             const Spacer(),
                          //             ElevatedButton(
                          //               onPressed: () {
                          //                 fetchReviewsFromApi();
                          //                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Refreshing reviews...')));
                          //               },
                          //               child: const Text('Refresh reviews'),
                          //               style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                          //             )
                          //           ],
                          //         ),
                          //         const SizedBox(height: 12),
                          //         if (isReviewsLoading)
                          //           const Center(child: CircularProgressIndicator())
                          //         else if (reviewsError)
                          //           Center(child: Text('Failed to load reviews', style: TextStyle(color: Colors.red.shade400)))
                          //         else if (reviews.isEmpty)
                          //             const Center(child: Text('No reviews yet'))
                          //           else
                          //             Column(
                          //               children: reviews.take(3).map((r) {
                          //                 final rRating = double.tryParse(r['rating']?.toString() ?? '0') ?? 0.0;
                          //                 final rName = r['userName'] ?? 'Guest';
                          //                 final rComment = r['comment'] ?? '';
                          //                 final rDate = r['createdAt'] ?? '';
                          //                 return ListTile(
                          //                   contentPadding: EdgeInsets.zero,
                          //                   leading: CircleAvatar(child: Text(rName.isNotEmpty ? rName[0].toUpperCase() : 'G')),
                          //                   title: Row(
                          //                     children: [
                          //                       Text(rName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          //                       const SizedBox(width: 8),
                          //                       Container(
                          //                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          //                         decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                          //                         child: Row(
                          //                           children: [
                          //                             Icon(Icons.star, size: 14, color: Colors.orange.shade700),
                          //                             const SizedBox(width: 4),
                          //                             Text(rRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w600)),
                          //                           ],
                          //                         ),
                          //                       )
                          //                     ],
                          //                   ),
                          //                   subtitle: Column(
                          //                     crossAxisAlignment: CrossAxisAlignment.start,
                          //                     children: [
                          //                       const SizedBox(height: 6),
                          //                       Text(rComment, maxLines: 2, overflow: TextOverflow.ellipsis),
                          //                       const SizedBox(height: 6),
                          //                       Text(rDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          //                     ],
                          //                   ),
                          //                 );
                          //               }).toList(),
                          //             ),
                          //
                          //         // 'View all reviews' button
                          //         if (!isReviewsLoading && reviews.isNotEmpty)
                          //           TextButton(
                          //             onPressed: () {
                          //               // navigate to full reviews screen if you have one
                          //             },
                          //             child: const Text('View all reviews'),
                          //           )
                          //       ],
                          //     ),
                          //   ),
                          // ),
                          //
                          // const SizedBox(height: 80), // space for bottom bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Sticky bottom bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SafeArea(
          child: Row(
            children: [
              // Message (chat)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (currentUserId == null || currentUserId!.isEmpty) {
                      // redirect to sign in
                      AppSnackbar.info(context, 'Please sign in to send a message.');
                      return;
                    }
                    final int uid = int.parse(currentUserId!);
                    final int vendor = int.parse(vendorId);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          currentUid: uid,
                          otherUid: vendor,
                          otherName: vendorName,
                          vendorId: vendor,
                        ),
                      ),
                    );
                    print("Vendor ID: $vendorId");
                    print(currentUserId);
                    print(vendor);
                    print(vendorName);

                    },

                  icon: const Icon(Icons.message, color: Colors.pink),
                  label: const Text('Message', style: TextStyle(color: Colors.pink)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.pink.shade200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Call now (primary)
              SizedBox(
                width: 120,
                child: ElevatedButton.icon(
                  onPressed: () => _call(phone),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // small helper chip used in UI
  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [
        BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6),
      ]),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey.shade800),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}


