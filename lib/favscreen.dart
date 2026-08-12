import 'package:flutter/material.dart';

import 'core/core.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabs = ['Photos', 'Ideas', 'Real Weddings'];

  late TabController _tabController;
  int _selectedIndex = 0;

  /// Currently applied sort/filter, shown in the app-bar action.
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedIndex) {
        setState(() => _selectedIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: const AppBackButton(),
        title: Text('Favourites', style: AppText.pageTitle),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Pressable(
              onTap: () => _showFilterBottomSheet(context),
              borderRadius: AppRadii.rPill,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pinkSurface,
                  borderRadius: AppRadii.rPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filter,
                      style: AppText.buttonSm.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar with an animated indicator.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _buildTabItem(_tabs[i], i),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Add More
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PremiumButton.outlined(
              label: 'Add More',
              icon: Icons.add_rounded,
              onPressed: () => _showAddMoreOptions(context),
            ),
          ),

          Expanded(
            child: EmptyState(
              title: 'Nothing saved yet',
              message:
                  "We don't have anything matching your query right now. "
                  'Browse photos and ideas to start building your favourites.',
              icon: Icons.favorite_border_rounded,
              actionLabel: 'Try Again',
              onAction: _refreshContent,
              secondaryActionLabel: 'Browse ideas',
              onSecondaryAction: () => _showAddMoreOptions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: Pressable(
        scale: 0.98,
        onTap: () {
          setState(() => _selectedIndex = index);
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            style: isSelected
                ? AppText.bodyStrong.copyWith(color: AppColors.textPrimary)
                : AppText.body.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
            child: Text(title, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Filter by',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in const ['All', 'Recent', 'Most Liked', 'Oldest'])
            _buildFilterOption(option, option == _filter),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return Pressable(
      onTap: () {
        setState(() => _filter = title);
        Navigator.pop(context);
      },
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: isSelected
                    ? AppText.bodyStrong.copyWith(color: AppColors.primary)
                    : AppText.body,
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMoreOptions(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Add to favourites',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAddOption(Icons.photo_library_outlined, 'Browse Photos'),
          _buildAddOption(Icons.lightbulb_outline_rounded, 'Explore Ideas'),
          _buildAddOption(Icons.favorite_border_rounded, 'Real Weddings'),
        ],
      ),
    );
  }

  Widget _buildAddOption(IconData icon, String title) {
    return Pressable(
      onTap: () => Navigator.pop(context),
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.pinkSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: AppText.body)),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  void _refreshContent() {
    setState(() {
      // Nothing to reload yet — this tab has no API behind it.
    });
    AppSnackbar.info(context, 'Refreshing your favourites…');
  }
}