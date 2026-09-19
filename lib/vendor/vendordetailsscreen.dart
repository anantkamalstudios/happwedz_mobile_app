import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:imageview360/imageview360.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import '../ClaimBusiness.dart';
import '../authservice.dart';
import '../Review.dart';
import '../ai_chat_screen/ai_chat_screen.dart';
import '../chat_page_new.dart';
import 'request_pricing_sheet.dart';
import 'master_facilities_section.dart';
import '../core/core.dart';
import 'package:happy_wedz/core/config/api_config.dart';
import '../core/services/response_cache.dart';

// Final VendorServicesScreen — pagination, grid/list toggle, search, filters,
// wishlist toggle, phone/WhatsApp/message actions, safe image handling.
//
// The API layer below is unchanged: same endpoints, same query params, same
// response parsing. Only the presentation has been rebuilt on the design
// system.

class VendorServicesScreen extends StatefulWidget {
  final String subcategoryName;

  /// City to pre-apply, so opening this from a city-scoped list keeps the
  /// same scope instead of resetting to every city.
  final String? initialCity;

  /// The vendor type ("Venues", "Photographers" …) — the web's `vendorType`
  /// filter. With it the list is exact and several times faster than the
  /// loose `subCategory` text match on its own.
  final String? vendorType;

  /// False lists the whole [vendorType] ("View all Venues"), with
  /// [subcategoryName] as the title only.
  final bool filterBySubcategory;

  const VendorServicesScreen({
    super.key,
    required this.subcategoryName,
    this.initialCity,
    this.vendorType,
    this.filterBySubcategory = true,
  });

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

  /// Server-side page size: the list used to download every vendor in the
  /// category at once (`limit=5000` — 62 MB and ~30 s for photographers).
  static const int _pageSize = 12;

  /// Upper end of the price slider; a max at the cap means "no max".
  static const double _priceCap = 200000;

  /// Matches `pagination.total`, for the result count.
  int _total = 0;

  /// Bumped per fresh load, so a slow answer for an old search/filter set
  /// cannot overwrite the current one.
  int _generation = 0;
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
  // double filterMaxPrice = 100000;
  // The slider and Reset both use the cap; starting at 1 lakh silently hid
  // every vendor priced above it and lit the filter badge on open.
  double filterMaxPrice = _priceCap;
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
    // Seed the city filter before the first fetch so the initial render is
    // already scoped; the filter chip stays editable as usual.
    selectedCity = widget.initialCity ?? '';
    filterCity = selectedCity;
    _loadCurrentUser();
    // Pages load as the list nears its end (the listener existed but was
    // never attached, since everything was fetched up front).
    setupPaginationListener();
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

  /// The `/vendor-services` page with every filter applied on the server —
  /// the web's `useInfiniteScroll` query.
  Uri _pageUri(int page) {
    final search = searchController.text.trim();
    return Uri.parse('${ApiConfig.apiBase}/vendor-services').replace(
      queryParameters: {
        if ((widget.vendorType ?? '').isNotEmpty) 'vendorType': widget.vendorType!,
        if (widget.filterBySubcategory && widget.subcategoryName.isNotEmpty)
          'subCategory': widget.subcategoryName,
        if (filterCity.isNotEmpty) 'city': filterCity,
        if (search.isNotEmpty) 'search': search,
        if (filterMinPrice > 0) 'minPrice': filterMinPrice.toInt().toString(),
        if (filterMaxPrice < _priceCap)
          'maxPrice': filterMaxPrice.toInt().toString(),
        if (filterMinRating > 0) 'minRating': filterMinRating.toString(),
        'page': '$page',
        'limit': '$_pageSize',
      },
    );
  }

  static List<dynamic> _rowsOf(dynamic decoded) {
    final raw = decoded is Map ? decoded['data'] : null;
    if (raw is List) return raw;
    if (raw is Map) return [raw];
    return const [];
  }

  void _readPagination(dynamic decoded) {
    final pagination = decoded is Map ? decoded['pagination'] : null;
    if (pagination is! Map) {
      hasMore = false;
      return;
    }
    totalPages = int.tryParse('${pagination['totalPages']}') ?? 1;
    _total = int.tryParse('${pagination['total']}') ?? _total;
    hasMore = currentPage < totalPages;
  }

  /// Loads page 1 for the current filters. The last good first page for the
  /// same query shows at once, then the fresh one replaces it.
  Future<void> fetchAllServices() async {
    final generation = ++_generation;
    final url = _pageUri(1);
    setState(() {
      isLoading = true;
      _loadError = null;
      currentPage = 1;
      hasMore = false;
    });

    final cached = await ResponseCache.read(url.toString());
    if (!mounted || generation != _generation) return;
    if (cached != null) {
      try {
        final decoded = json.decode(cached);
        setState(() {
          allServices
            ..clear()
            ..addAll(_rowsOf(decoded));
          services = List<dynamic>.from(allServices);
          _readPagination(decoded);
          isLoading = allServices.isEmpty;
        });
      } catch (_) {}
    }

    try {
      final response = await http
          .get(url, headers: {"Accept": "application/json"})
          .timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          allServices
            ..clear()
            ..addAll(_rowsOf(decoded));
          services = List<dynamic>.from(allServices);
          currentPage = 1;
          _readPagination(decoded);
        });
        unawaited(ResponseCache.write(url.toString(), response.body));
      } else if (allServices.isEmpty) {
        setState(() => _loadError = 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error loading services: $e");
      if (!mounted || generation != _generation) return;
      // Keep a cached page on screen; only an empty list shows the error.
      if (allServices.isEmpty) setState(() => _loadError = e);
    }

    if (!mounted || generation != _generation) return;
    setState(() => isLoading = false);
  }

  // Previous loader, kept for reference: fetched the whole category in one
  // request and filtered on the phone.
  // Future<void> fetchAllServices() async {
  //   setState(() {
  //     isLoading = true;
  //     _loadError = null;
  //     allServices.clear();
  //     services.clear();
  //   });
  //
  //   try {
  //     final sub = Uri.encodeComponent(widget.subcategoryName.toLowerCase());
  //
  //     final url = Uri.parse(
  //       "${ApiConfig.apiBase}/vendor-services?subCategory=$sub&limit=5000",
  //     );
  //
  //     final response = await http.get(url);
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final raw = data["data"];
  //
  //       List<dynamic> list = [];
  //
  //       if (raw is List) {
  //         list = raw;
  //       } else if (raw is Map<String, dynamic>) {
  //         list = [raw];
  //       }
  //
  //       if (!mounted) return;
  //       setState(() {
  //         allServices.addAll(list);
  //       });
  //
  //       _applyFiltersAndSearch();
  //     } else {
  //       if (!mounted) return;
  //       setState(() => _loadError = 'HTTP ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     debugPrint("Error loading ALL services: $e");
  //     if (!mounted) return;
  //     setState(() => _loadError = e);
  //   }
  //
  //   if (!mounted) return;
  //   setState(() => isLoading = false);
  // }

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

    final uri = Uri.parse('${ApiConfig.apiBase}/vendor-services').replace(queryParameters: queryParams);

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

  /// The next page for the same filters, as the list nears its end.
  Future<void> fetchMoreServices() async {
    if (!hasMore || isLoadingMore || isLoading) return;
    final generation = _generation;
    final page = currentPage + 1;

    setState(() => isLoadingMore = true);

    try {
      final response = await http
          .get(_pageUri(page), headers: {"Accept": "application/json"})
          .timeout(const Duration(seconds: 30));
      if (!mounted || generation != _generation) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          currentPage = page;
          allServices.addAll(_rowsOf(decoded));
          services = List<dynamic>.from(allServices);
          _readPagination(decoded);
        });
      } else {
        debugPrint('More API error ${response.statusCode}');
      }
    } catch (e, st) {
      debugPrint('fetchMoreServices error $e');
      debugPrint('$st');
    }

    if (!mounted || generation != _generation) return;
    setState(() => isLoadingMore = false);
  }

  // Previous next-page loader, kept for reference:
  // Future<void> fetchMoreServices() async {
  //   if (!hasMore) return;
  //
  //   setState(() => isLoadingMore = true);
  //
  //   try {
  //     currentPage++;
  //
  //     final encodedSubcategory = Uri.encodeComponent(
  //       widget.subcategoryName.toLowerCase(),
  //     );
  //
  //     final url = Uri.parse(
  //       "${ApiConfig.apiBase}/vendor-services?subCategory=$encodedSubcategory&page=$currentPage&limit=9",
  //     );
  //
  //     final response = await http.get(
  //       url,
  //       headers: {"Accept": "application/json"},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body) as Map<String, dynamic>;
  //       final rawData = data['data'];
  //
  //       List<dynamic> list = [];
  //
  //       if (rawData is List) {
  //         list = rawData;
  //       } else if (rawData is Map<String, dynamic>) {
  //         list = [rawData]; // wrap single object into a list
  //       } else {
  //         list = []; // null or unexpected format
  //       }
  //
  //       final pagination = data['pagination'] ?? {};
  //
  //       totalPages = (pagination['totalPages'] ?? 1) is int
  //           ? pagination['totalPages']
  //           : int.tryParse('${pagination['totalPages']}') ?? totalPages;
  //       hasMore = currentPage < totalPages;
  //
  //       if (!mounted) return;
  //       setState(() {
  //         allServices.addAll(list);
  //       });
  //
  //       _applyFiltersAndSearch();
  //     } else {
  //       debugPrint('More API error ${response.statusCode}');
  //     }
  //   } catch (e, st) {
  //     debugPrint('fetchMoreServices error $e');
  //     debugPrint('$st');
  //   }
  //
  //   if (!mounted) return;
  //   setState(() => isLoadingMore = false);
  // }

  Future<void> applyFilters() async {
    setState(() {
      filterCity = selectedCity;
      filterMinPrice = minPrice;
      filterMaxPrice = maxPrice;
      filterMinRating = selectedRating;
    });

    // _applyFiltersAndSearch(); // local filtering
    fetchAllServices(); // the server filters now
  }

  /// Filters and search now run on the server, over every vendor rather than
  /// just the ones downloaded: this reloads page 1 for the current filters.
  void _applyFiltersAndSearch() => fetchAllServices();

  // Previous on-device filter, kept for reference:
  // ignore: unused_element
  void _applyFiltersLocally() {
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
    // Each search is a request now, so wait for a pause in typing.
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
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

      final url = Uri.parse('${ApiConfig.apiBase}/wishlist/toggle');
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
        // AUDIT FIX: this only showed a message and reverted the optimistic
        // toggle — the expired token stayed in storage, so every subsequent
        // authenticated action kept silently failing the same way instead of
        // returning the user to login.
        AuthSession.instance.signOut();
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
      "${ApiConfig.apiBase}/vendor-services?search=$query",
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
                // services.length == 1
                //     ? '1 result'
                //     : '${services.length} results',
                // The server's total, not just the pages loaded so far.
                (_total > services.length ? _total : services.length) == 1
                    ? '1 result'
                    : '${_total > services.length ? _total : services.length} results',
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
//           color: Colors.white.withValues(alpha: 0.9),
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
//               color: Colors.black.withValues(alpha: 0.08),
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
//                       color: Colors.black.withValues(alpha: 0.6),
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
//                         color: Colors.white.withValues(alpha: 0.85),
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
  String? currentUserId;
  bool isPageLoading = false;
  dynamic fetchedService;

  // Reviews
  bool isReviewsLoading = false;
  bool reviewsError = false;
  double apiAverageRating = 0.0;
  int apiTotalReviews = 0;
  List<Map<String, dynamic>> reviews = [];
  Map<String, double> reviewCategoryAverages = const {};


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
      final url = Uri.parse('${ApiConfig.apiBase}/vendor-services/$id');
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
      debugPrint("Error fetching by ID: $e");
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
        final url = Uri.parse('${ApiConfig.apiBase}/vendor-services/$serviceId');
        final response = await http.get(url, headers: {'Accept': 'application/json'});
        if (response.statusCode == 200) {
          final bodyData = jsonDecode(response.body);
          if (bodyData is Map) {
            foundService = bodyData;
          }
        }
      } catch (e) {
        debugPrint("Error fetching by ID: $e");
      }
    }

    // 2. If not found, try searching by slug
    if (foundService == null) {
      try {
        final url = Uri.parse('${ApiConfig.apiBase}/vendor-services?search=$slug');
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
        debugPrint("Error fetching by slug search: $e");
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
        "${ApiConfig.apiBase}/business/claims/check-status?"
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
      debugPrint("STATUS ERROR: $e");
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
      return "${ApiConfig.backendBaseUrl}$url";
    }

    return url;
  }

  // AUDIT FIX: this used to only run when `service.image_exists` was truthy,
  // so a listing whose backend flag was false hid its real uploaded photos
  // entirely (confirmed live: a vendor-uploaded listing with two valid
  // `media` URLs and `image_exists: false` fell straight through to the
  // vendor's profile-picture fallback below). `NetworkImageWidget` already
  // renders its own broken-image state per thumbnail, so there is no need to
  // gate the whole gallery on a flag that does not reliably track whether
  // the URLs actually resolve — every media/portfolio URL is attempted now,
  // and a genuinely broken one just shows its own error tile instead of
  // nothing.
  List<String> extractImages(dynamic media, dynamic vendor, dynamic attributes) {
    final Set<String> images = {};

    void add(String? url) {
      if (url == null || url.trim().isEmpty) return;
      final u = normalizeUrl(url);
      if (u.startsWith('http')) {
        images.add(u);
      }
    }

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

  /// `attributes.video` (list, pipe-separated string, or list of
  /// `{url: ...}` maps — the three shapes seen across categories) → a flat
  /// list of external video links (Pexels/YouTube/Vimeo/direct file). These
  /// are opened externally rather than played inline since most vendor
  /// listings link to a hosting page, not a raw video file.
  List<String> extractVideos(Map attributes) {
    final Set<String> videos = {};

    void add(String? url) {
      if (url == null) return;
      final u = url.trim();
      if (u.isEmpty) return;
      videos.add(normalizeUrl(u));
    }

    final raw = attributes['video'] ?? attributes['videos'] ?? attributes['Video'];
    if (raw is List) {
      for (final item in raw) {
        if (item is String) {
          add(item);
        } else if (item is Map) {
          add((item['url'] ?? item['link'])?.toString());
        }
      }
    } else if (raw is String && raw.isNotEmpty) {
      for (final part in raw.split('|')) {
        add(part);
      }
    }

    return videos.toList();
  }

  /// Active, non-expired entries from `attributes.deals` (promo codes a
  /// vendor has published — `code`, `title`, `value`/`type`, validity dates).
  List<Map<String, dynamic>> extractDeals(Map attributes) {
    final raw = attributes['deals'];
    if (raw is! List) return [];

    final now = DateTime.now();
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).where((deal) {
      if (deal['active'] == false || deal['active'] == 'false') return false;
      final endRaw = deal['endDate']?.toString();
      if (endRaw != null && endRaw.isNotEmpty) {
        final end = DateTime.tryParse(endRaw);
        if (end != null && end.isBefore(now)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _launchExternal(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final normalized = trimmed.startsWith('http') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppSnackbar.error(context, "We couldn't open that link.");
    }
  }

  List<Map<String, String>> parseArea(String areaRaw) {
    final parts = <String>[];
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

  /// `menu.items` comes back as a list containing one comma-separated string
  /// (e.g. `["Paneer Butter Masala, Dal Makhani, ..."]`), not one entry per
  /// dish — split it out so each dish becomes its own chip.
  List<String> _menuItems(Map<String, dynamic> menu) {
    final raw = menu['items'];
    if (raw is! List) return [];
    final items = <String>[];
    for (final entry in raw) {
      if (entry is! String) continue;
      items.addAll(
        entry.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }
    return items;
  }

  bool _isVegMenuType(String type) {
    final t = type.toLowerCase();
    return t.contains('veg') && !t.contains('non');
  }

  /// One "Vegetarian Menu" / "Non-Vegetarian Menu" card: coloured title,
  /// starting price, description, then every dish as its own chip.
  Widget _buildMenuCard(Map<String, dynamic> menu) {
    final type = (menu['type'] ?? '').toString();
    final isVeg = _isVegMenuType(type);
    final color = isVeg ? AppColors.successDark : AppColors.error;
    final title = (menu['title'] ?? '').toString().isNotEmpty
        ? menu['title'].toString()
        : (isVeg ? 'Vegetarian Menu' : 'Non-Vegetarian Menu');
    final subtitle = isVeg ? 'Pure Veg Options' : 'Includes Non-Veg Specialties';
    final description = (menu['description'] ?? '').toString();
    final price = (menu['price'] ?? '').toString();
    final items = _menuItems(menu);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 5, right: AppSpacing.sm),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppText.bodyStrong.copyWith(color: color),
                    ),
                    Text(subtitle, style: AppText.caption),
                  ],
                ),
              ),
              if (_hasValue(price)) ...[
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Starting From', style: AppText.caption),
                    Text(
                      '₹$price / plate',
                      style: AppText.bodyStrong.copyWith(
                        color: color,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (_hasValue(description)) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'MENU INCLUSIONS (${items.length} ITEM${items.length == 1 ? '' : 'S'})',
              style: AppText.labelSm.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final item in items)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: AppRadii.rPill,
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '✓ $item',
                      style: AppText.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
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
      // AUDIT FIX: this previously hit `/vendor-reviews?vendorId=` which the
      // backend answers with 404 "Route not found" for every vendor, so the
      // reviews section always fell back to its error/empty state. The real
      // route (confirmed live, matches the website's `ReviewSection.jsx`) is
      // `GET /api/reviews/:vendorId` — a path param, not a query string — and
      // it answers `{ success, reviews: [...] }` with five category ratings
      // per review (`rating_quality`, `rating_responsiveness`,
      // `rating_professionalism`, `rating_value`, `rating_flexibility`)
      // rather than one flat `rating`.
      //
      // vendorId here is the vendor *account* id (matches what the website
      // sends), but this vendor-service listing's own id is the one the
      // route actually keys reviews on for some legacy records, so both are
      // tried in order — the second call only fires if the first comes back
      // empty, keeping this a single round trip for the common case.
      Future<Map<String, dynamic>?> fetchFor(String id) async {
        final url = Uri.parse("${ApiConfig.apiBase}/reviews/$id");
        debugPrint("[REVIEWS] GET $url");
        final res = await http.get(url, headers: {'Accept': 'application/json'});
        debugPrint("[REVIEWS] response ${res.statusCode}");
        if (res.statusCode != 200) return null;
        final decoded = json.decode(res.body);
        return decoded is Map<String, dynamic> ? decoded : null;
      }

      Map<String, dynamic>? jsonData = await fetchFor(vendorId);
      List<dynamic> list =
          (jsonData?['reviews'] ?? jsonData?['data'] ?? []) as List<dynamic>;

      final String serviceId = (service['id'] ?? '').toString();
      if (list.isEmpty && serviceId.isNotEmpty && serviceId != vendorId) {
        final fallback = await fetchFor(serviceId);
        final fallbackList =
            (fallback?['reviews'] ?? fallback?['data'] ?? []) as List<dynamic>;
        if (fallbackList.isNotEmpty) {
          jsonData = fallback;
          list = fallbackList;
        }
      }

      if (jsonData != null) {
        double sumOf(dynamic item, List<String> keys) {
          for (final k in keys) {
            final v = item[k];
            if (v != null) return double.tryParse(v.toString()) ?? 0;
          }
          return 0;
        }

        final parsed = list.map<Map<String, dynamic>>((item) {
          // The category ratings are what the backend actually stores; a
          // single review's overall star rating is their average, matching
          // the "Quality of service / Responsiveness / ..." breakdown the
          // website shows above the review list.
          final categories = <String, double>{
            'quality': sumOf(item, ['rating_quality']),
            'responsiveness': sumOf(item, ['rating_responsiveness']),
            'professionalism': sumOf(item, ['rating_professionalism']),
            'value': sumOf(item, ['rating_value']),
            'flexibility': sumOf(item, ['rating_flexibility']),
          };
          final nonZero = categories.values.where((v) => v > 0).toList();
          final overall = nonZero.isEmpty
              ? (double.tryParse((item['rating'] ?? '0').toString()) ?? 0)
              : nonZero.reduce((a, b) => a + b) / nonZero.length;

          final user = item['user'];
          final userName = (user is Map ? user['name'] : null) ??
              item['userName'] ??
              item['user_name'] ??
              'Guest';

          return {
            'id': item['id'] ?? item['review_id'] ?? '',
            'rating': overall.toString(),
            'categories': categories,
            'title': item['title'] ?? '',
            'comment': item['comment'] ?? item['review'] ?? item['description'] ?? '',
            'userName': userName,
            'vendorReply': item['vendor_reply'] ?? item['vendorReply'] ?? '',
            'createdAt': item['createdAt'] ?? item['created_at'] ?? item['date'] ?? '',
          };
        }).toList();

        // The category summary bars average every review's own breakdown, so
        // they are computed here once rather than trusting a separate meta
        // block the endpoint does not actually return.
        final categoryAverages = <String, double>{};
        for (final key in ['quality', 'responsiveness', 'professionalism', 'value', 'flexibility']) {
          final values = parsed
              .map((r) => (r['categories'] as Map<String, double>)[key] ?? 0)
              .where((v) => v > 0)
              .toList();
          categoryAverages[key] =
              values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
        }

        final overallValues = parsed
            .map((r) => double.tryParse(r['rating'].toString()) ?? 0)
            .where((v) => v > 0)
            .toList();
        final computedAverage = overallValues.isEmpty
            ? 0.0
            : overallValues.reduce((a, b) => a + b) / overallValues.length;

        debugPrint("[REVIEWS] parsed ${parsed.length} review(s), avg ${computedAverage.toStringAsFixed(2)}");

        setState(() {
          reviews = parsed;
          reviewCategoryAverages = categoryAverages;
          apiAverageRating = computedAverage > 0 ? computedAverage : apiAverageRating;
          apiTotalReviews = parsed.length;
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
      debugPrint("[REVIEWS] error: $e");
      setState(() {
        reviewsError = true;
        isReviewsLoading = false;
      });
      debugPrint("Reviews API error: $e");
    }
  }
  /// Claim CTA. The four states (loading / approved / pending / rejected /
  /// unclaimed) and their navigation targets are unchanged — only the
  /// presentation moved onto the design system.
  Widget claimButton(
    String vendorId,
    String vendorSubcategoryId, {
    String vendorAccountStatus = '',
  }) {
    // The vendor account itself is already verified — this is a stronger,
    // account-level signal than `claimStatus` below, which only reflects
    // *this session's own* claim submission and stays empty (`hasClaim:
    // false`) even for an account an admin has already approved. Checked
    // first and unconditionally: an approved account never shows a "Claim
    // Your Business" button, no matter what `checkClaimStatus()` returns.
    if (vendorAccountStatus == 'approved') {
      return _ClaimStatusButton(
        icon: Icons.verified_rounded,
        label: 'Verified business',
        color: AppColors.successDark,
        onTap: () => SuccessPopup.show(
          context,
          title: 'Verified business',
          message: 'This business is verified and already claimed.',
        ),
      );
    }

    if (isClaimLoading) {
      return const PremiumButton(
        label: 'Checking…',
        isLoading: true,
        onPressed: null,
      );
    }

    // APPROVED
    if (claimStatus == "approved") {
      return _ClaimStatusButton(
        icon: Icons.verified_rounded,
        label: 'Approved',
        color: AppColors.successDark,
        onTap: () => SuccessPopup.show(
          context,
          title: 'Business claim approved',
          message: 'This business is already claimed and verified.',
        ),
      );
    }

    // PENDING
    if (claimStatus == "pending") {
      return _ClaimStatusButton(
        icon: Icons.hourglass_top_rounded,
        label: 'Pending',
        color: AppColors.warning,
        onTap: () => SuccessPopup.show(
          context,
          title: 'Claim under review',
          message:
              'We are reviewing your claim. You will hear from us shortly.',
        ),
      );
    }

    // REJECTED
    if (claimStatus == "rejected") {
      return _ClaimStatusButton(
        icon: Icons.refresh_rounded,
        label: 'Resubmit claim',
        color: AppColors.error,
        onTap: () => Navigator.push(
          context,
          AnimatedPageRoute(
            page: BusinessClaimForm(
              vendorId: vendorId,
              vendorSubcategoryId: vendorSubcategoryId,
            ),
            style: PageTransitionStyle.slideUp,
          ),
        ),
      );
    }

    // DEFAULT — SHOW CLAIM FORM BUTTON
    return PremiumButton(
      label: 'Claim Your Business',
      icon: Icons.business_center_outlined,
      size: PremiumButtonSize.medium,
      onPressed: () => Navigator.push(
        context,
        AnimatedPageRoute(
          page: BusinessClaimForm(
            vendorId: vendorId,
            vendorSubcategoryId: vendorSubcategoryId,
          ),
          style: PageTransitionStyle.slideUp,
        ),
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

      final url = Uri.parse('${ApiConfig.apiBase}/wishlist/toggle');
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

      if (!mounted) return;

      if (res.statusCode == 200) {
        AppSnackbar.success(
          context,
          isFav ? 'Removed from your wishlist.' : 'Saved to your wishlist.',
        );
      } else {
        _revertFavourite(vendorServiceId, wasFavourite: isFav);
        AppSnackbar.error(
          context,
          res.statusCode == 401
              ? 'Session expired. Please log in again.'
              : "We couldn't update your wishlist. Please try again.",
        );
        // AUDIT FIX: same expired-token gap as the other wishlist call above —
        // force sign-out so the stale token can't keep failing silently.
        if (res.statusCode == 401) {
          AuthSession.instance.signOut();
        }
      }
    } catch (e) {
      debugPrint("Wishlist API error: $e");
      if (!mounted) return;
      _revertFavourite(vendorServiceId, wasFavourite: isFav);
      AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    }
  }

  /// Undoes an optimistic wishlist toggle when the request did not land.
  void _revertFavourite(String vendorServiceId, {required bool wasFavourite}) {
    setState(() {
      if (wasFavourite) {
        favouriteVendors.add(vendorServiceId);
      } else {
        favouriteVendors.remove(vendorServiceId);
      }
    });
    saveFavouritesToLocal();
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
    final List<String> images = extractImages(service['media'], vendor, attributes);
    debugPrint("IMAGES COUNT: ${images.length}");
    images.forEach(print);

    final String vendorId = (vendor['id'] ?? attributes['vendor_id'] ?? '').toString();
    // Public "is this business already claimed and verified" flag, from the
    // vendor account's own `status` — separate from `checkClaimStatus()`
    // below, which tracks whether *this session's* claim submission has been
    // approved. A listing can be `vendor.status == "approved"` (an admin
    // marked the account verified) with zero rows in `business_claims`
    // (confirmed live against a test listing set up for exactly this: its
    // `check-status` call returns `hasClaim: false`) — so the two checks are
    // combined in `claimButton()` rather than one standing in for the other.
    final String vendorAccountStatus = (vendor['status'] ?? '').toString().toLowerCase();
    debugPrint("[CLAIM] vendor.status=$vendorAccountStatus");
    final String vendorSubcategoryId = (service['vendor_subcategory_id'] ?? attributes['vendor_subcategory_id'] ?? '').toString();
    final String vendorName = (attributes['vendor_name'] ?? attributes['Name'] ?? vendor['businessName'] ?? 'No Name').toString();
    final String city = (attributes['city'] ?? vendor['city'] ?? '').toString();
    final String address = (attributes['address'] ?? attributes['Address'] ?? '').toString();
    final String aboutRaw = (attributes['about_us'] ?? attributes['Aboutus'] ?? '').toString();
    final String about = aboutRaw.replaceAll(r'\n', '').replaceAll(r'\"', '"').replaceAll(r'\\', '').trim();
    final String phone = (vendor['phone'] ?? attributes['Phone'] ?? '').toString();
    final String email = (attributes['Email'] ?? attributes['email'] ?? vendor['email'] ?? '').toString();
    final String website = (attributes['website'] ?? attributes['Website'] ?? vendor['website'] ?? '').toString();
    final List<String> videos = extractVideos(attributes);
    final List<Map<String, dynamic>> deals = extractDeals(attributes);
    final socialLinks = <MapEntry<IconData, String>>[
      if (_hasValue(vendor['facebook_link'])) MapEntry(Icons.facebook_rounded, vendor['facebook_link'].toString()),
      if (_hasValue(vendor['instagram_link'])) MapEntry(Icons.camera_alt_rounded, vendor['instagram_link'].toString()),
      if (_hasValue(vendor['twitter_link'])) MapEntry(Icons.alternate_email_rounded, vendor['twitter_link'].toString()),
      if (_hasValue(vendor['pinterest_link'])) MapEntry(Icons.push_pin_rounded, vendor['pinterest_link'].toString()),
      if (_hasValue(vendor['linkedin_link'])) MapEntry(Icons.business_center_rounded, vendor['linkedin_link'].toString()),
      if (_hasValue(vendor['youtube_link'])) MapEntry(Icons.smart_display_rounded, vendor['youtube_link'].toString()),
      if (_hasValue(vendor['threads_link'])) MapEntry(Icons.tag_rounded, vendor['threads_link'].toString()),
    ];

    debugPrint("Vendor ID: $vendorId");
    debugPrint("Vendor Subcategory ID: $vendorSubcategoryId");
    final double rating =
        double.tryParse((vendor['rating'] ?? attributes['rating'] ?? apiAverageRating ?? '0').toString()) ?? apiAverageRating;
    final String vendorType = (vendor['vendorType']?['name'] ?? attributes['vendor_type'] ?? '').toString();

    final String vegPrice = (attributes['veg_price'] ?? '').toString();
    final String nonVegPrice = (attributes['non_veg_price'] ?? '').toString();

    // Structured per-menu breakdown (`attributes.menus`) — richer than the
    // flat veg/non-veg price above (title, description, item list per menu).
    // Only some categories/vendors have filled this in yet, so the flat
    // Pricing block above stays as the fallback when it's empty.
    final rawMenus = attributes['menus'];
    final List<Map<String, dynamic>> foodMenus = rawMenus is List
        ? rawMenus
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
        : [];

    final seatingList = parseArea((attributes['area'] ?? ''));

    // Dates the vendor has published as open, straight from
    // `attributes.available_slots` (`[{date: "YYYY-MM-DD"}, ...]`) — the same
    // field the website's Request Pricing calendar reads. Used to restrict
    // the date picker exactly like the website's `shouldDisableDate` does;
    // an empty list means the vendor has not published a calendar, in which
    // case any future date is accepted.
    final rawSlots = attributes['available_slots'];
    final List<DateTime> availableSlots = (rawSlots is List ? rawSlots : const [])
        .map((slot) {
          final raw = (slot is Map ? slot['date'] : slot)?.toString() ?? '';
          if (raw.isEmpty) return null;
          return DateTime.tryParse(raw.split('T').first);
        })
        .whereType<DateTime>()
        .toList();
    debugPrint("[AVAILABILITY] vendor=$vendorId slots=${availableSlots.length}");

    // Any attribute whose key ends in "_master" is the rich per-category
    // profile the vendor filled in through their dashboard (`venue_master`
    // today; `photographer_master`, `caterer_master`, etc. the same way once
    // a vendor in that category has one) — see `_MasterFacilitiesSection`.
    // Generic by design: one renderer covers every category's schema without
    // hand-porting each of the ~25 category-specific field sets.
    Map<String, dynamic>? masterAttrs;
    for (final entry in attributes.entries) {
      if (entry.key.endsWith('_master') && entry.value is Map) {
        masterAttrs = Map<String, dynamic>.from(entry.value as Map);
        break;
      }
    }
    // No vendor-filled `*_master` profile yet — fall back to whatever flat
    // legacy fields this listing already has, so the section still shows
    // something instead of nothing (see `buildFallbackMasterAttrs`).
    if (!MasterFacilitiesSection.hasContent(masterAttrs)) {
      final fallback = buildFallbackMasterAttrs(attributes);
      if (MasterFacilitiesSection.hasContent(fallback)) {
        masterAttrs = fallback;
      }
    }


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

    debugPrint("✅ FINAL LAT LNG => $latitude , $longitude");

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



    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ---------------- HERO ----------------
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
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
                              scrim: true,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(22),
                                bottomRight: Radius.circular(22),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1,
                            autoPlay: images.length > 1,
                            onPageChanged: (i, r) =>
                                setState(() => _currentCarouselIndex = i),
                          ),
                        ),

                        // Top controls
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          right: AppSpacing.md,
                          child: Row(
                            children: [
                              _GlassIconButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              _GlassIconButton(
                                icon: Icons.share_rounded,
                                onTap: () {
                                  final shareLink =
                                      attributes['URL']?.toString() ??
                                      attributes['url']?.toString() ??
                                      '';
                                  if (shareLink.isNotEmpty) {
                                    // AUDIT FIX (deprecation): see share_plus 12.
                                    SharePlus.instance.share(
                                      ShareParams(text: shareLink),
                                    );
                                  } else {
                                    AppSnackbar.info(
                                      context,
                                      'There is no link to share yet.',
                                    );
                                  }
                                },
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _GlassIconButton(
                                background: AppColors.successDark,
                                iconWidget: Image.asset(
                                  'assets/icons/whatsapp.png',
                                  width: 18,
                                  height: 18,
                                  errorBuilder: (ctx, e, st) => const Icon(
                                    Icons.chat_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                onTap: () => _launchWhatsApp(phone),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              _GlassIconButton(
                                background: Colors.white,
                                iconColor: AppColors.primary,
                                icon: favouriteVendors.contains(vendorServiceId)
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                onTap: () => toggleWishlist(vendorServiceId),
                              ),
                            ],
                          ),
                        ),

                        // Name / city / rating overlay
                        Positioned(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.lg,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      vendorName,
                                      style: AppText.sectionTitle.copyWith(
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (city.trim().isNotEmpty) ...[
                                      const SizedBox(height: AppSpacing.xxs),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.white70,
                                            size: 14,
                                          ),
                                          const SizedBox(
                                            width: AppSpacing.xxs,
                                          ),
                                          Expanded(
                                            child: Text(
                                              city,
                                              style: AppText.caption.copyWith(
                                                color: Colors.white70,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppRadii.rSm,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: AppColors.warning,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppSpacing.xxs),
                                    Text(
                                      rating > 0
                                          ? rating.toStringAsFixed(1)
                                          : (apiAverageRating > 0
                                                ? apiAverageRating
                                                      .toStringAsFixed(1)
                                                : '—'),
                                      style: AppText.label,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ---------------- CAROUSEL DOTS ----------------
                  if (images.length > 1)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0;
                                i < (images.length > 8 ? 8 : images.length);
                                i++)
                              AnimatedContainer(
                                duration: AppMotion.fast,
                                curve: AppMotion.standard,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                height: 7,
                                width: _currentCarouselIndex == i ? 22 : 7,
                                decoration: BoxDecoration(
                                  color: _currentCarouselIndex == i
                                      ? AppColors.primary
                                      : AppColors.divider,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // ---------------- BODY ----------------
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // --- Title + price ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    vendorName,
                                    style: AppText.display.copyWith(
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 15,
                                        color: AppColors.textTertiary,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          '$city${address.isNotEmpty ? " · $address" : ""}',
                                          style: AppText.bodySm,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (_hasValue(vegPrice) ||
                                _hasValue(nonVegPrice)) ...[
                              const SizedBox(width: AppSpacing.md),
                              AppCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _hasValue(vegPrice)
                                          ? '₹$vegPrice'
                                          : '₹$nonVegPrice',
                                      style: AppText.price,
                                    ),
                                    Text('Per plate', style: AppText.caption),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // --- Quick info chips ---
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (_hasValue(vendorType))
                              _infoChip(vendorType, Icons.business_rounded),
                            if (_hasValue(vegPrice))
                              _infoChip(
                                '₹$vegPrice / plate',
                                Icons.restaurant_rounded,
                              ),
                            if (_hasValue(nonVegPrice))
                              _infoChip(
                                'Non-veg ₹$nonVegPrice',
                                Icons.lunch_dining_rounded,
                              ),
                            if (seatingList.isNotEmpty)
                              _infoChip(
                                '${seatingList.length} spaces',
                                Icons.people_alt_rounded,
                              ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // --- Claim + map ---
                        Row(
                          children: [
                            Expanded(
                              child: claimButton(
                                vendorId,
                                vendorSubcategoryId,
                                vendorAccountStatus: vendorAccountStatus,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            _SquareIconButton(
                              icon: Icons.map_outlined,
                              tooltip: 'View on map',
                              onTap: () async {
                                if (latitude != null && longitude != null) {
                                  await openMap(latitude, longitude);
                                } else if (address.isNotEmpty ||
                                    city.isNotEmpty) {
                                  final query = Uri.encodeComponent(
                                    "$vendorName $address $city",
                                  );
                                  final fallback = Uri.parse("geo:0,0?q=$query");
                                  await launchUrl(
                                    fallback,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  if (!mounted) return;
                                  AppSnackbar.info(
                                    context,
                                    'Location not available for this vendor.',
                                  );
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _SquareIconButton(
                              icon: Icons.rate_review_outlined,
                              tooltip: 'Write a review',
                              onTap: () => Navigator.push(
                                context,
                                AnimatedPageRoute(
                                  page: RecommendVendorScreen(
                                    vendorId: vendorId,
                                    vendorName: vendorName,
                                    vendorImage: images.isNotEmpty
                                        ? images[0]
                                        : null,
                                    currentUserId: currentUserId,
                                  ),
                                  style: PageTransitionStyle.slideUp,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // --- Request Pricing & Availability ---
                        // Not a dummy CTA: opens a sheet whose date picker is
                        // constrained to `availableSlots` exactly like the
                        // website, and submits to the same
                        // `POST /api/request-pricing` endpoint.
                        SizedBox(
                          width: double.infinity,
                          child: PremiumButton.outlined(
                            label: 'Request Pricing & Availability',
                            icon: Icons.calendar_month_outlined,
                            onPressed: () {
                              if (currentUserId == null || currentUserId!.isEmpty) {
                                AppSnackbar.info(
                                  context,
                                  'Please sign in to request pricing & availability.',
                                );
                                return;
                              }
                              debugPrint(
                                "[PRICING] opening sheet for vendor=$vendorId "
                                "slots=${availableSlots.length}",
                              );
                              showRequestPricingSheet(
                                context,
                                vendorId: vendorId,
                                vendorName: vendorName,
                                availableSlots: availableSlots,
                              );
                            },
                          ),
                        ),

                        // --- Food & Catering Menus (structured, richer than
                        // the flat veg/non-veg price rows) ---
                        if (foodMenus.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Food & Catering Menus',
                            subtitle: 'Prices per plate / guest',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (final menu in foodMenus) _buildMenuCard(menu),
                        ],

                        // --- Pricing (fallback when there's no structured
                        // menu breakdown yet) ---
                        if (foodMenus.isEmpty &&
                            (_hasValue(vegPrice) || _hasValue(nonVegPrice))) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Pricing',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppCard.outlined(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_hasValue(vegPrice))
                                  _PriceRow(
                                    icon: Icons.eco_rounded,
                                    color: AppColors.successDark,
                                    label: 'Veg',
                                    value: '₹$vegPrice / plate',
                                  ),
                                if (_hasValue(vegPrice) &&
                                    _hasValue(nonVegPrice))
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: AppColors.divider,
                                    ),
                                  ),
                                if (_hasValue(nonVegPrice))
                                  _PriceRow(
                                    icon: Icons.lunch_dining_rounded,
                                    color: AppColors.error,
                                    label: 'Non-veg',
                                    value: '₹$nonVegPrice / plate',
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // --- Spaces / seating ---
                        if (seatingList.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Spaces',
                            subtitle:
                                '${seatingList.length} available at this venue',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final space in seatingList)
                                AppCard.outlined(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        space['name'] ?? 'Space',
                                        style: AppText.label,
                                      ),
                                      if ((space['capacity'] ?? '')
                                          .toString()
                                          .isNotEmpty)
                                        Text(
                                          space['capacity']!,
                                          style: AppText.caption,
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],

                        // --- Portfolio ---
                        if (images.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Portfolio',
                            subtitle: '${images.length} photos',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 112,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (ctx, idx) {
                                return Pressable(
                                  onTap: () => _openGallery(images, idx),
                                  borderRadius: AppRadii.rMd,
                                  child: NetworkImageWidget(
                                    url: images[idx],
                                    width: 150,
                                    height: 112,
                                    radius: AppRadii.md,
                                    memCacheWidth: 420,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // --- Videos ---
                        if (videos.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Videos',
                            subtitle: '${videos.length} video${videos.length == 1 ? '' : 's'}',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: videos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: AppSpacing.md),
                              itemBuilder: (ctx, idx) {
                                return Pressable(
                                  onTap: () => _launchExternal(videos[idx]),
                                  borderRadius: AppRadii.rMd,
                                  child: Container(
                                    width: 150,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: AppRadii.rMd,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          'Video ${idx + 1}',
                                          style: AppText.caption.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],

                        // --- Deals & Offers ---
                        if (deals.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Deals & Offers',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (var i = 0; i < deals.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: i == deals.length - 1 ? 0 : AppSpacing.md,
                              ),
                              child: AppCard.outlined(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pinkSurface,
                                        borderRadius: AppRadii.rSm,
                                      ),
                                      child: Text(
                                        deals[i]['type'] == 'percentage'
                                            ? '${deals[i]['value']}% OFF'
                                            : '₹${deals[i]['value']} OFF',
                                        style: AppText.labelSm.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_hasValue(deals[i]['title']))
                                            Text(
                                              '${deals[i]['title']}',
                                              style: AppText.bodyStrong,
                                            ),
                                          if (_hasValue(deals[i]['description']))
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                '${deals[i]['description']}',
                                                style: AppText.caption,
                                              ),
                                            ),
                                          if (_hasValue(deals[i]['code']))
                                            Padding(
                                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                                              child: Text(
                                                'Code: ${deals[i]['code']}',
                                                style: AppText.bodySm.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          if (_hasValue(deals[i]['endDate']))
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Valid till ${deals[i]['endDate']}',
                                                style: AppText.caption,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],

                        // --- About ---
                        if (_hasValue(about)) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'About',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AnimatedCrossFade(
                            firstChild: SizedBox(
                              height: 140,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Html(
                                  data: about,
                                  style: _htmlStyle,
                                ),
                              ),
                            ),
                            secondChild: Html(data: about, style: _htmlStyle),
                            crossFadeState: _aboutExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: AppMotion.normal,
                          ),
                          if (about.length > 250)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: PremiumButton.text(
                                label: _aboutExpanded
                                    ? 'Read less'
                                    : 'Read more',
                                trailingIcon: _aboutExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: PremiumButtonSize.small,
                                onPressed: () => setState(
                                  () => _aboutExpanded = !_aboutExpanded,
                                ),
                              ),
                            ),
                        ],

                        // --- Policies ---
                        if (_hasValue(attributes['decor_policy']) ||
                            _hasValue(attributes['catering_policy'])) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Policies',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppCard.outlined(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_hasValue(attributes['decor_policy']))
                                  _PolicyRow(
                                    icon: Icons.celebration_outlined,
                                    label: 'Decor',
                                    value: '${attributes['decor_policy']}',
                                  ),
                                if (_hasValue(attributes['decor_policy']) &&
                                    _hasValue(attributes['catering_policy']))
                                  const SizedBox(height: AppSpacing.md),
                                if (_hasValue(attributes['catering_policy']))
                                  _PolicyRow(
                                    icon: Icons.restaurant_menu_rounded,
                                    label: 'Catering',
                                    value: '${attributes['catering_policy']}',
                                  ),
                              ],
                            ),
                          ),
                        ],

                        // --- Facilities & Features (generic "*_master" renderer) ---
                        if (masterAttrs != null &&
                            MasterFacilitiesSection.hasContent(masterAttrs)) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Facilities & Features',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MasterFacilitiesSection(masterAttrs: masterAttrs),
                        ],

                        // --- Connect (email, website, social links) ---
                        if (_hasValue(email) ||
                            _hasValue(website) ||
                            socialLinks.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxl),
                          SectionHeader(
                            title: 'Connect',
                            accent: true,
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (_hasValue(website))
                                Pressable(
                                  onTap: () => _launchExternal(website),
                                  child: _infoChip(
                                    'Website',
                                    Icons.language_rounded,
                                  ),
                                ),
                              if (_hasValue(email))
                                Pressable(
                                  onTap: () => launchUrl(Uri(scheme: 'mailto', path: email)),
                                  child: _infoChip(
                                    email,
                                    Icons.email_outlined,
                                  ),
                                ),
                              for (final link in socialLinks)
                                Pressable(
                                  onTap: () => _launchExternal(link.value),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.divider),
                                    ),
                                    child: Icon(
                                      link.key,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],

                        // --- Reviews ---
                        const SizedBox(height: AppSpacing.xxl),
                        SectionHeader(
                          title: 'Reviews',
                          subtitle: apiTotalReviews > 0
                              ? '$apiTotalReviews from real couples'
                              : null,
                          accent: true,
                          padding: EdgeInsets.zero,
                          actionLabel: 'Write one',
                          onAction: () => Navigator.push(
                            context,
                            AnimatedPageRoute(
                              page: RecommendVendorScreen(
                                vendorId: vendorId,
                                vendorName: vendorName,
                                vendorImage: images.isNotEmpty
                                    ? images[0]
                                    : null,
                                currentUserId: currentUserId,
                              ),
                              style: PageTransitionStyle.slideUp,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildReviewsSection(),

                        // Breathing room above the sticky bar.
                        const SizedBox(height: AppSpacing.xl),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Sticky bottom bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Message (chat)
              Expanded(
                child: PremiumButton.outlined(
                  label: 'Message',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () {
                    if (currentUserId == null || currentUserId!.isEmpty) {
                      AppSnackbar.info(
                        context,
                        'Please sign in to send a message.',
                      );
                      return;
                    }
                    final int? uid = int.tryParse(currentUserId!);
                    final int? vendor = int.tryParse(vendorId);
                    if (uid == null || vendor == null) {
                      AppSnackbar.error(
                        context,
                        "We couldn't open this chat. Please try again.",
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      AnimatedPageRoute(
                        page: ChatPage(
                          currentUid: uid,
                          otherUid: vendor,
                          otherName: vendorName,
                          vendorId: vendor,
                        ),
                        style: PageTransitionStyle.slideRight,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Call now (primary)
              Expanded(
                child: PremiumButton(
                  label: 'Call',
                  icon: Icons.phone_rounded,
                  onPressed: () => _call(phone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared HTML styling for the About block so both crossfade children match.
  Map<String, Style> get _htmlStyle => {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(14.5),
      lineHeight: const LineHeight(1.55),
      color: AppColors.textSecondary,
      fontFamily: 'Poppins',
    ),
  };

  /// Full-screen swipeable gallery opened from a portfolio thumbnail.
  void _openGallery(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        style: PageTransitionStyle.fade,
        page: _GalleryViewer(images: images, initialIndex: initialIndex),
      ),
    );
  }

  /// Reviews list: shimmer while loading, friendly error with retry, empty
  /// state, otherwise the first three reviews. Uses the existing
  /// [fetchReviewsFromApi] data — no new endpoint.
  Widget _buildReviewsSection() {
    if (isReviewsLoading) {
      return Skeletons.listTiles(count: 2);
    }

    if (reviewsError) {
      return AppCard.outlined(
        child: ErrorState(
          compact: true,
          title: "Couldn't load reviews",
          message: 'Please try again in a moment.',
          onRetry: fetchReviewsFromApi,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      );
    }

    if (reviews.isEmpty) {
      return AppCard.outlined(
        child: EmptyState(
          compact: true,
          title: 'No reviews yet',
          message: 'Be the first to share your experience.',
          icon: Icons.rate_review_outlined,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      );
    }

    final shown = reviews.take(3).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rating summary
        AppCard.outlined(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        apiAverageRating > 0
                            ? apiAverageRating.toStringAsFixed(1)
                            : '—',
                        style: AppText.display.copyWith(color: AppColors.primary),
                      ),
                      Text(
                        '$apiTotalReviews review${apiTotalReviews == 1 ? '' : 's'}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            i <= apiAverageRating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 20,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Per-category breakdown (Quality / Responsiveness /
              // Professionalism / Value / Flexibility) — averaged client-side
              // from each review's own `rating_*` fields, since the reviews
              // endpoint does not return a pre-computed summary.
              if (reviewCategoryAverages.values.any((v) => v > 0)) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.md),
                for (final entry in const {
                  'quality': 'Quality of service',
                  'responsiveness': 'Responsiveness',
                  'professionalism': 'Professionalism',
                  'value': 'Value',
                  'flexibility': 'Flexibility',
                }.entries)
                  if ((reviewCategoryAverages[entry.key] ?? 0) > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(entry.value, style: AppText.bodySm),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: AppRadii.rSm,
                              child: LinearProgressIndicator(
                                value: (reviewCategoryAverages[entry.key] ?? 0) / 5,
                                minHeight: 6,
                                backgroundColor: AppColors.divider,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 28,
                            child: Text(
                              (reviewCategoryAverages[entry.key] ?? 0)
                                  .toStringAsFixed(1),
                              style: AppText.bodySm,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == shown.length - 1 ? 0 : AppSpacing.md,
            ),
            child: FadeSlideIn(
              delay: AppMotion.staggerFor(i),
              child: _ReviewTile(review: shown[i]),
            ),
          ),
      ],
    );
  }

  // small helper chip used in UI
  Widget _infoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(text, style: AppText.labelSm),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Presentational helpers for the detail page
// ---------------------------------------------------------------------------

/// Translucent circular control overlaid on the hero carousel.
class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    this.icon,
    this.iconWidget,
    required this.onTap,
    this.background,
    this.iconColor,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback onTap;
  final Color? background;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? Colors.black.withValues(alpha: 0.42),
        ),
        child: Center(
          child:
              iconWidget ??
              Icon(icon, size: 18, color: iconColor ?? Colors.white),
        ),
      ),
    );
  }
}

/// Bordered square icon action used beside the claim button.
class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.rMd,
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, child: button);
  }
}

/// Coloured status pill used for approved / pending / rejected claims.
class _ClaimStatusButton extends StatelessWidget {
  const _ClaimStatusButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadii.rMd,
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                style: AppText.button.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label, style: AppText.body)),
        Text(value, style: AppText.priceSm),
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: AppText.label),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: AppText.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}

/// One review card. Field names match the normalised shape produced by
/// [_VendorDetailsScreenState.fetchReviewsFromApi].
class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final name = (review['userName'] ?? 'Guest').toString();
    final comment = (review['comment'] ?? '').toString();
    final title = (review['title'] ?? '').toString();
    final ratingValue =
        double.tryParse(review['rating']?.toString() ?? '0') ?? 0.0;

    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppAvatar(name: name, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pinkSurface,
                  borderRadius: AppRadii.rSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      ratingValue.toStringAsFixed(1),
                      style: AppText.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (title.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppText.bodyStrong),
          ],
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              comment,
              style: AppText.bodySm,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if ((review['vendorReply'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadii.rSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Response from the owner',
                    style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review['vendorReply'].toString(),
                    style: AppText.bodySm,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen pinch-to-zoom gallery for the portfolio thumbnails.
class _GalleryViewer extends StatefulWidget {
  const _GalleryViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: NetworkImageWidget(
                  url: widget.images[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: AppRadii.rPill,
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.images.length}',
                      style: AppText.labelSm.copyWith(color: Colors.white),
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
}
