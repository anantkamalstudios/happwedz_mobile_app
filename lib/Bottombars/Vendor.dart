import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:happy_wedz/core/config/api_config.dart';
import 'package:happy_wedz/core/services/vendor_visibility.dart';

import '../core/core.dart';
import '../vendor/vendordetailsscreen.dart';
import '../vendor/vendor_row.dart' show vendorAbsoluteUrl;
import '../core/services/selected_city.dart';

class VendorCategoriesScreen extends StatefulWidget {
  const VendorCategoriesScreen({super.key});

  @override
  State<VendorCategoriesScreen> createState() => _VendorCategoriesScreenState();
}

class _VendorCategoriesScreenState extends State<VendorCategoriesScreen> {
  List<VendorCategory> categories = [];

  /// Expanded/collapsed state per category id.
  final Map<int, bool> expandedState = {};

  /// Subcategory ids whose services request is currently in flight.
  final Set<int> _loadingSubcategories = {};

  bool isLoading = true;
  Object? _error;

  /// FAQs under the categories, like the website's /vendors page
  /// (FaqsSection: `GET /faq`, every FAQ).
  List<Map<String, dynamic>> _faqs = const [];
  bool _faqError = false;
  int? _openFaq;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConfig.apiBase}/faq'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = json.decode(res.body);
      final list = body is Map ? body['faqs'] : null;
      if (!mounted) return;
      setState(() {
        _faqError = false;
        _faqs = list is List
            ? list
                .whereType<Map>()
                .where((f) => f['is_deleted'] != true)
                .map((f) => Map<String, dynamic>.from(f))
                .toList()
            : const [];
      });
    } catch (e) {
      debugPrint('FAQ load failed: $e');
      if (mounted) setState(() => _faqError = true);
    }
  }

  Widget _buildFaqs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Frequently Asked Questions', style: AppText.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        if (_faqError)
          Text("We couldn't load FAQ something went wrong.", style: AppText.bodySm)
        else
          for (var i = 0; i < _faqs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Pressable(
                      onTap: () => setState(() => _openFaq = _openFaq == i ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${i + 1}. ${_faqs[i]['question'] ?? ''}',
                                style: AppText.bodyStrong,
                              ),
                            ),
                            Icon(
                              _openFaq == i ? Icons.remove_rounded : Icons.add_rounded,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_openFaq == i)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_faqs[i]['answer'] ?? ''}',
                            style: AppText.bodySm,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> fetchSubcategoryServices(Subcategory subcategory) async {
    if (_loadingSubcategories.contains(subcategory.id)) return;
    _loadingSubcategories.add(subcategory.id);

    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.apiBase}/vendor-services?subCategory=${subcategory.name.toLowerCase()}",
        ),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = visibleVendors(json.decode(response.body));
        if (!mounted) return;
        setState(() {
          subcategory.services = data; // assign API data, hidden rows removed
        });
      } else {
        debugPrint(
          "Error fetching ${subcategory.name} services: ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("API Error for ${subcategory.name}: $e");
    } finally {
      _loadingSubcategories.remove(subcategory.id);
    }
  }

  Future<void> fetchCategories() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        _error = null;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.apiBase}/vendor-types/with-subcategories/all",
        ),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          categories = data.map((e) => VendorCategory.fromJson(e)).toList();
          for (final cat in categories) {
            expandedState.putIfAbsent(cat.id, () => false);
          }
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = 'HTTP ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      if (!mounted) return;
      setState(() {
        _error = e;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleCategory(VendorCategory cat) async {
    final nowExpanded = !(expandedState[cat.id] ?? false);
    setState(() => expandedState[cat.id] = nowExpanded);

    if (!nowExpanded) return;

    // Disabled: this fetched every subcategory's vendors one after another
    // (~8 s each on the server) on each expand, yet nothing on this screen
    // shows `sub.services` — and the body is a map, so the `List` cast threw
    // and the same requests re-ran on every expand. Tapping a subcategory
    // opens `VendorServicesScreen`, which loads its own page.
    // for (final sub in cat.subcategories) {
    //   if (sub.services == null) {
    //     await fetchSubcategoryServices(sub);
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ------------------ HEADER ------------------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  // 'Vendor Categories',
                  'Explore by Category', // website AllCategories heading
                  textAlign: TextAlign.center,
                  style: AppText.pageTitle.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),

              // ------------------ CATEGORY LIST ------------------
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Skeletons.listCards(count: 5, height: 108),
      );
    }

    if (_error != null && categories.isEmpty) {
      return ErrorState(error: _error, onRetry: fetchCategories);
    }

    if (categories.isEmpty) {
      return EmptyState(
        title: 'No categories yet',
        message: 'Vendor categories will appear here once they are published.',
        icon: Icons.storefront_outlined,
        actionLabel: 'Refresh',
        onAction: fetchCategories,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: fetchCategories,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: categories.length +
            ((_faqs.isNotEmpty || _faqError) ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= categories.length) return _buildFaqs();
          final cat = categories[index];
          return FadeSlideIn(
            delay: AppMotion.staggerFor(index),
            child: _CategoryCard(
              title: cat.name,
              subtitle: cat.description ?? '',
              image: cat.heroImage,
              isExpanded: expandedState[cat.id] ?? false,
              onTap: () => _toggleCategory(cat),
              subcategories: cat.subcategories.map((s) => s.name).toList(),
              onSubcategoryTap: (name) {
                Navigator.push(
                  context,
                  AnimatedPageRoute(
                    // Pass the exact subcategory name as returned from API
                    // page: VendorServicesScreen(subcategoryName: name),
                    // With its vendor type, so "Photographers" means the
                    // photographers — not every name containing the word.
                    // Scoped to the chosen city, as the website's
                    // `/vendors/{sub}/{city|all}` links are.
                    page: VendorServicesScreen(
                      subcategoryName: name,
                      vendorType: cat.name,
                      initialCity: SelectedCity.value,
                    ),
                    style: PageTransitionStyle.slideRight,
                  ),
                );
              },
              // Website "Explore {Type}": the whole vendor type.
              onExplore: () => Navigator.push(
                context,
                AnimatedPageRoute(
                  page: VendorServicesScreen(
                    subcategoryName: cat.name,
                    vendorType: cat.name,
                    filterBySubcategory: false,
                    initialCity: SelectedCity.value,
                  ),
                  style: PageTransitionStyle.slideRight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A single expandable vendor-category tile.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isExpanded,
    required this.onTap,
    required this.subcategories,
    required this.onSubcategoryTap,
    this.onExplore,
  });

  final VoidCallback? onExplore;

  final String title;
  final String subtitle;
  final String image;
  final bool isExpanded;
  final VoidCallback onTap;
  final List<String> subcategories;
  final ValueChanged<String> onSubcategoryTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            onTap: onTap,
            borderRadius: AppRadii.rLg,
            withRipple: true,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppText.sectionTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (subtitle.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            subtitle,
                            style: AppText.cardSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  NetworkImageWidget(
                    // url: "${ApiConfig.apiBase}/$image",
                    // `hero_image` is sometimes a full S3 URL, which the old
                    // host prefix turned into "https://api…/https://…".
                    url: vendorAbsoluteUrl(image),
                    width: 78,
                    height: 62,
                    radius: AppRadii.md,
                    memCacheWidth: 240,
                    backgroundColor: AppColors.pinkSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppExpandable(
            expanded: isExpanded,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final sub in subcategories)
                        if (sub.trim().isNotEmpty)
                          _SubcategoryRow(
                            label: sub,
                            highlighted: sub == 'View all Venues',
                            onTap: () => onSubcategoryTap(sub),
                          ),
                      if (onExplore != null)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: SizedBox(
                            width: double.infinity,
                            child: PremiumButton.outlined(
                              label: 'Explore $title',
                              size: PremiumButtonSize.small,
                              onPressed: onExplore,
                            ),
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

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({
    required this.label,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rSm,
      withRipple: true,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: highlighted
                    ? AppText.bodyStrong.copyWith(color: AppColors.primary)
                    : AppText.body.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: highlighted ? AppColors.primary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class VendorCategory {
  final int id;
  final String name;
  final String? description;
  final String heroImage;
  final List<Subcategory> subcategories;

  VendorCategory({
    required this.id,
    required this.name,
    this.description,
    required this.heroImage,
    required this.subcategories,
  });

  factory VendorCategory.fromJson(Map<String, dynamic> json) {
    return VendorCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      heroImage: json['hero_image'] ?? "",
      subcategories: (json['subcategories'] as List<dynamic>)
          .map((e) => Subcategory.fromJson(e))
          .toList(),
    );
  }
}

class Subcategory {
  final int id;
  final String name;
  List<dynamic>? services; // This will hold API response for this subcategory

  Subcategory({required this.id, required this.name, this.services});

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(id: json['id'], name: json['name']);
  }
}