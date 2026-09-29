import 'dart:async';

import 'package:flutter/material.dart';

import '../core/core.dart';
import 'blog_api.dart';
import 'blog_article_page.dart';

/// The website's blog list (BlogLists.jsx):
/// * "Search Wedding Articles" — at 2+ characters (300 ms debounce) asks
///   `/blogs/search`; its results replace the list when there are any,
///   otherwise the loaded list is filtered by title, as on the website.
/// * "I am looking for" — "Wedding Vendors" (a word of the author starting
///   with it) and "Select Date" (post date), applied on the loaded list.
/// * 6 cards per page with numbered pagination (hidden while showing search
///   results). Opening a search result reports `increment-search`.
class BlogListView extends StatefulWidget {
  const BlogListView({super.key, this.api});

  final BlogApi? api;

  @override
  State<BlogListView> createState() => _BlogListViewState();
}

class _BlogListViewState extends State<BlogListView> {
  static const int blogsPerPage = 6;

  late final BlogApi _api = widget.api ?? BlogApi();
  final _search = TextEditingController();
  final _vendor = TextEditingController();
  Timer? _debounce;
  int _searchRequest = 0;

  List<BlogSummary> _blogs = const [];
  List<BlogSummary> _searchResults = const [];
  bool _loading = true;
  bool _searching = false;
  Object? _error;
  DateTime? _date;
  int _page = 1;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _vendor.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final blogs = await _api.fetchAll();
      if (!mounted) return;
      setState(() => _blogs = blogs);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    setState(() => _page = 1);
    final q = value.trim();
    final request = ++_searchRequest;
    if (q.length < 2) {
      setState(() {
        _searchResults = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      List<BlogSummary> results = const [];
      try {
        results = await _api.search(q);
      } catch (_) {}
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _searchResults = results;
        _searching = false;
      });
    });
  }

  bool get _showingSearchResults =>
      _searchResults.isNotEmpty && _search.text.trim().length >= 2;

  List<BlogSummary> get _filtered {
    final q = _search.text.toLowerCase();
    final vendor = _vendor.text.toLowerCase();
    return _blogs.where((b) {
      final titleMatch = b.title.toLowerCase().contains(q);
      final vendorMatch = vendor.isEmpty ||
          b.author
              .toLowerCase()
              .split(' ')
              .any((w) => w.startsWith(vendor));
      final posted = DateTime.tryParse(b.postDate)?.toLocal();
      final dateMatch = _date == null ||
          (posted != null && DateUtils.isSameDay(posted, _date));
      return titleMatch && vendorMatch && dateMatch;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 2),
      helpText: 'Select Date',
    );
    if (picked != null && mounted) {
      setState(() {
        _date = picked;
        _page = 1;
      });
    }
  }

  void _open(BlogSummary b) {
    if (_showingSearchResults) _api.incrementSearch(b.id);
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: BlogArticlePage(blogId: b.id, preview: b, api: _api),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Skeletons.listCards(count: 3, height: 280),
      );
    }
    if (_error != null && _blogs.isEmpty) {
      return ErrorState(error: _error, onRetry: _load);
    }

    final filtered = _filtered;
    final totalPages = (filtered.length / blogsPerPage).ceil();
    final page = _page.clamp(1, totalPages < 1 ? 1 : totalPages);
    final pageItems = filtered
        .skip((page - 1) * blogsPerPage)
        .take(blogsPerPage)
        .toList();
    final items = _showingSearchResults ? _searchResults : pageItems;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl,
        ),
        children: [
          AppTextField(
            controller: _search,
            hint: 'Search Wedding Articles',
            prefixIcon: Icons.search_rounded,
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          _filtersCard(),
          const SizedBox(height: AppSpacing.md),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: Icons.article_outlined,
                title: _blogs.isEmpty ? 'No articles yet' : 'No articles found',
                message: _blogs.isEmpty
                    ? 'Wedding articles will appear here once they are published.'
                    : 'Try a different search or clear the filters.',
              ),
            )
          else
            for (final b in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _BlogCard(blog: b, onTap: () => _open(b)),
              ),
          if (!_showingSearchResults && totalPages > 1)
            _pagination(page, totalPages),
        ],
      ),
    );
  }

  Widget _filtersCard() {
    final active = _vendor.text.isNotEmpty || _date != null;
    return AppCard.outlined(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            onTap: () => setState(() => _showFilters = !_showFilters),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'I am looking for',
                      style: AppText.bodyStrong.copyWith(
                        color: active ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  Icon(
                    _showFilters
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.md,
              ),
              child: Column(
                children: [
                  AppTextField(
                    controller: _vendor,
                    hint: 'Wedding Vendors',
                    onChanged: (_) => setState(() => _page = 1),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Pressable(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: AppRadii.rMd),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.md,
                        ),
                        suffixIcon: _date == null
                            ? const Icon(Icons.calendar_today_outlined)
                            : IconButton(
                                tooltip: 'Clear date',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => setState(() => _date = null),
                              ),
                      ),
                      child: Text(
                        _date == null
                            ? 'Select Date'
                            : blogDate(_date!.toIso8601String()),
                        style: _date == null
                            ? AppText.body.copyWith(color: AppColors.textTertiary)
                            : AppText.body,
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

  Widget _pagination(int page, int totalPages) {
    Widget btn(Widget child, VoidCallback? onTap, {bool active = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Material(
            color: active ? AppColors.primary : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.rSm,
              side: const BorderSide(color: AppColors.divider),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadii.rSm,
              child: SizedBox(
                width: 38,
                height: 38,
                child: Center(child: child),
              ),
            ),
          ),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: AppSpacing.xs,
      children: [
        btn(
          const Icon(Icons.chevron_left_rounded, size: 20),
          page > 1 ? () => setState(() => _page = page - 1) : null,
        ),
        for (var i = 1; i <= totalPages; i++)
          btn(
            Text(
              '$i',
              style: AppText.label.copyWith(
                color: i == page ? Colors.white : AppColors.textPrimary,
              ),
            ),
            () => setState(() => _page = i),
            active: i == page,
          ),
        btn(
          const Icon(Icons.chevron_right_rounded, size: 20),
          page < totalPages ? () => setState(() => _page = page + 1) : null,
        ),
      ],
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.blog, required this.onTap});

  final BlogSummary blog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imgs = blog.images;
    Widget image;
    if (imgs.length > 1) {
      image = Row(
        children: [
          Expanded(child: NetworkImageWidget(url: imgs[0], height: 200)),
          Expanded(child: NetworkImageWidget(url: imgs[1], height: 200)),
        ],
      );
    } else {
      image = NetworkImageWidget(
        url: imgs.isEmpty ? '' : imgs.first,
        height: 200,
        width: double.infinity,
      );
    }
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadii.lg),
            ),
            child: image,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(blog.title, style: AppText.sectionTitle),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.xs,
                    runSpacing: 2,
                    children: [
                      Text(blog.byline, style: AppText.caption),
                      Text('|', style: AppText.caption),
                      Text(blogDate(blog.postDate), style: AppText.caption),
                      Text('|', style: AppText.caption),
                      Text(blog.readTime, style: AppText.caption),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(blog.excerpt, style: AppText.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
