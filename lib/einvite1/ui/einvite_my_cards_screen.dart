/// "Your cards" — the customer's saved invitations, port of the website's
/// `EinviteMyCards` (route `/einvites/my-cards`).
///
/// Same data and filters as the web: `GET einvites/:userId/einvites`, split
/// into All / Published (`isActive`) / Drafts. Each card is drawn from its
/// own saved design rather than a thumbnail, so what is listed is what guests
/// will see.
///
/// There is deliberately no delete: the website's delete only clears drafts
/// kept in the browser and never calls the server, and its server delete
/// endpoint is unauthenticated. Porting it would invent behaviour the web
/// does not have.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/core.dart';
import '../data/einvite_api.dart';
import '../data/einvite_design.dart';
import '../einvite.dart' show DraftListScreen;
import 'einvite_editor_screen.dart';
import 'einvite_page_view.dart';
import 'einvite_share_sheet.dart';

enum _Filter { all, published, drafts }

class EinviteMyCardsScreen extends StatefulWidget {
  const EinviteMyCardsScreen({super.key, this.api});

  /// Injected in tests.
  final EinviteApi? api;

  @override
  State<EinviteMyCardsScreen> createState() => _EinviteMyCardsScreenState();
}

class _EinviteMyCardsScreenState extends State<EinviteMyCardsScreen> {
  late final EinviteApi _api = widget.api ?? EinviteApi();

  List<Map<String, dynamic>> _cards = const [];
  bool _loading = true;
  Object? _error;
  _Filter _filter = _Filter.all;

  /// Drafts the previous editor kept only on this phone (`draft_*` keys).
  /// Still reachable so nobody loses them, but no longer created.
  bool _hasLocalDrafts = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    var hasLocal = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      hasLocal = prefs.getKeys().any((k) => k.startsWith('draft_'));
    } catch (_) {}

    try {
      final cards = await _api.getMyCards();
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _hasLocalDrafts = hasLocal;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _hasLocalDrafts = hasLocal;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _visible {
    switch (_filter) {
      case _Filter.published:
        return _cards.where((c) => c['isActive'] == true).toList();
      case _Filter.drafts:
        return _cards.where((c) => c['isActive'] != true).toList();
      case _Filter.all:
        return _cards;
    }
  }

  Future<void> _open(Map<String, dynamic> card) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EinviteEditorScreen(cardId: '${card['id']}'),
      ),
    );
    // The card may have been renamed or edited — show the saved version.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Your cards', style: AppText.pageTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoader();

    if (_error != null) {
      final error = _error;
      final message = error is EinviteApiException
          ? error.message
          : 'Failed to load your cards';
      return ListView(
        children: [
          ErrorState(
            title: "Couldn't load your cards",
            message: message,
            onRetry: _load,
          ),
          if (_hasLocalDrafts) _localDraftsTile(),
        ],
      );
    }

    if (_cards.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          EmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No cards yet',
            message: 'Create your first e-invitation to get started',
            actionLabel: 'Browse Templates',
            onAction: () => Navigator.of(context).maybePop(),
          ),
          if (_hasLocalDrafts) _localDraftsTile(),
        ],
      );
    }

    final visible = _visible;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _chip(_Filter.all, 'All', _cards.length),
                _chip(
                  _Filter.published,
                  'Published',
                  _cards.where((c) => c['isActive'] == true).length,
                ),
                _chip(
                  _Filter.drafts,
                  'Drafts',
                  _cards.where((c) => c['isActive'] != true).length,
                ),
              ],
            ),
          ),
        ),
        if (_hasLocalDrafts)
          SliverToBoxAdapter(child: _localDraftsTile()),
        if (visible.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(
                'Nothing here yet.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                // Card (1 : 1.4) plus the caption row beneath it.
                childAspectRatio: 0.56,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _CardTile(
                  card: visible[index],
                  onOpen: () => _open(visible[index]),
                  onShare: () => showEinviteShareSheet(
                    context,
                    cardId: '${visible[index]['id']}',
                    cardName: '${visible[index]['name'] ?? ''}',
                  ),
                ),
                childCount: visible.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(_Filter filter, String label, int count) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }

  Widget _localDraftsTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadii.rMd,
        child: ListTile(
          leading: const Icon(Icons.phone_android_rounded),
          title: const Text('Older drafts on this phone'),
          subtitle: const Text('Saved before cards were kept in your account'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DraftListScreen()),
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.onOpen,
    required this.onShare,
  });

  final Map<String, dynamic> card;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final pages = getCardPages(card);
    final published = card['isActive'] == true;
    final name = card['name'] is String && (card['name'] as String).isNotEmpty
        ? card['name'] as String
        : 'Untitled card';

    return GestureDetector(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: AppRadii.rMd,
            child: pages.isEmpty
                ? const AspectRatio(
                    aspectRatio: 1 / kCardAspect,
                    child: ColoredBox(color: AppColors.blush),
                  )
                : IgnorePointer(child: EinvitePageView(page: pages.first)),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.labelSm,
                    ),
                    Text(
                      published ? 'Published' : 'Draft',
                      style: AppText.caption.copyWith(
                        color: published
                            ? AppColors.successDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Share',
                visualDensity: VisualDensity.compact,
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
