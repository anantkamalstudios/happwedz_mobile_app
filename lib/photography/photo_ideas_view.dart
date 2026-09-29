import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../core/core.dart';
import 'photography_api.dart';

/// The Ideas → Photos tab, fed by the website's photography endpoints
/// (TopSlider.jsx + GridImages.jsx): an "All" chip plus one chip per
/// `/photography-types` row, a two-column grid of active photos, and a
/// detail page (PhotographyDetails.jsx) on tap.
class PhotoIdeasView extends StatefulWidget {
  const PhotoIdeasView({super.key, this.api});

  final PhotographyApi? api;

  @override
  State<PhotoIdeasView> createState() => _PhotoIdeasViewState();
}

class _PhotoIdeasViewState extends State<PhotoIdeasView> {
  late final PhotographyApi _api = widget.api ?? PhotographyApi();

  List<PhotographyType> _types = const [];
  List<InspirationPhoto> _photos = const [];
  int? _typeId; // null = All
  bool _loading = true;
  Object? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _loadPhotos();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _api.fetchTypes();
      if (mounted) setState(() => _types = types);
    } catch (_) {
      // Chips are optional; the "All" grid still works without them.
    }
  }

  Future<void> _loadPhotos() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final photos = await _api.fetchPhotos(typeId: _typeId);
      if (!mounted || request != _request) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _selectType(int? id) {
    if (_typeId == id) return;
    setState(() => _typeId = id);
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_types.isNotEmpty) _typeChips(),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _typeChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _chip('All', null),
          for (final t in _types) _chip(t.name, t.id),
        ],
      ),
    );
  }

  Widget _chip(String label, int? id) {
    final selected = _typeId == id;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm, bottom: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _selectType(id),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        labelStyle: AppText.label.copyWith(
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.divider),
        showCheckmark: false,
      ),
    );
  }

  Widget _body() {
    if (_loading && _photos.isEmpty) {
      return Skeletons.grid(count: 6, aspectRatio: 0.8);
    }
    if (_error != null && _photos.isEmpty) {
      return ErrorState(error: _error, onRetry: _loadPhotos);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadPhotos,
      child: _photos.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xxl),
                  child: EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'No photos yet',
                    message: 'Wedding inspiration photos will appear here once they are published.',
                  ),
                ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xxxl,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, i) => _PhotoCard(
                photo: _photos[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InspirationPhotoPage(photo: _photos[i]),
                  ),
                ),
              ),
            ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.photo, required this.onTap});

  final InspirationPhoto photo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkImageWidget(
                url: photo.coverUrl,
                fit: BoxFit.cover,
                heroTag: 'inspiration_${photo.id}',
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Text(
                    photo.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One inspiration photo (PhotographyDetails.jsx): images, title,
/// photographer, city, tags and description. Tapping an image opens it
/// full screen with pinch-zoom.
class InspirationPhotoPage extends StatefulWidget {
  const InspirationPhotoPage({super.key, required this.photo});

  final InspirationPhoto photo;

  @override
  State<InspirationPhotoPage> createState() => _InspirationPhotoPageState();
}

class _InspirationPhotoPageState extends State<InspirationPhotoPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    final images = photo.allImages;
    final byline = [
      if (photo.photographerName.isNotEmpty) 'By ${photo.photographerName}',
      if (photo.cityName.isNotEmpty) photo.cityName,
    ].join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(photo.title, style: AppText.pageTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _FullScreenPhotos(images: images, index: i),
                      ),
                    ),
                    child: NetworkImageWidget(
                      url: images[i],
                      fit: BoxFit.cover,
                      heroTag: i == 0 ? 'inspiration_${photo.id}' : null,
                    ),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_index + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(photo.title, style: AppText.sectionTitle),
                if (byline.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(byline, style: AppText.bodySm),
                ],
                if (photo.tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final tag in photo.tags)
                        Chip(
                          label: Text('#$tag', style: AppText.labelSm),
                          backgroundColor: AppColors.surface,
                          side: const BorderSide(color: AppColors.divider),
                        ),
                    ],
                  ),
                ],
                if (photo.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(photo.description, style: AppText.body),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenPhotos extends StatelessWidget {
  const _FullScreenPhotos({required this.images, required this.index});

  final List<String> images;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: index),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[i]),
              minScale: PhotoViewComputedScale.contained,
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
