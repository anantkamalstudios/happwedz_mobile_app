/// List screen — ports `src/components/pages/MyWeddingWebsites.jsx`.
///
/// Uses `WeddingWebsiteApi`'s `weddingwebsite/wedding-websites` prefix, not
/// this source file's own raw `fetch('/api/wedding-websites'...)` calls,
/// which were confirmed stale against the live backend — see the note at the
/// top of `lib/wedding_website/data/wedding_website_api.dart`. Everything
/// else (list, publish, share, delete UI/behaviour) is ported as-is.
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/core.dart';
import '../data/wedding_website_api.dart';
import '../models/wedding_website_models.dart';
import 'wedding_website_form_page.dart';
import 'wedding_website_preview_page.dart';

class MyWeddingWebsitesPage extends StatefulWidget {
  const MyWeddingWebsitesPage({super.key});

  @override
  State<MyWeddingWebsitesPage> createState() => _MyWeddingWebsitesPageState();
}

class _MyWeddingWebsitesPageState extends State<MyWeddingWebsitesPage> {
  final _api = WeddingWebsiteApi();

  bool _loading = true;
  Object? _error;
  List<WeddingWebsiteSummary> _websites = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final websites = await _api.fetchMyWebsites();
      if (!mounted) return;
      setState(() {
        _websites = websites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _createNew() async {
    final template = await _pickTemplate();
    if (template == null || !mounted) return;
    final created = await Navigator.of(context).push<bool>(
      AnimatedPageRoute(page: WeddingWebsiteFormPage(template: template)),
    );
    if (created == true) _load();
  }

  Future<WeddingWebsiteTemplate?> _pickTemplate() {
    return AppBottomSheet.show<WeddingWebsiteTemplate>(
      context,
      title: 'Choose a template',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final t in WeddingWebsiteTemplate.values)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              onTap: () => Navigator.of(context).pop(t),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.pinkSurface,
                      borderRadius: AppRadii.rMd,
                    ),
                    child: const Icon(Icons.favorite, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.label, style: AppText.bodyStrong),
                        Text(t.description, style: AppText.caption),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _edit(WeddingWebsiteSummary website) async {
    final template = WeddingWebsiteTemplateX.fromId(website.templateId);
    final updated = await Navigator.of(context).push<bool>(
      AnimatedPageRoute(
        page: WeddingWebsiteFormPage(template: template, editId: website.id),
      ),
    );
    if (updated == true) _load();
  }

  void _preview(WeddingWebsiteSummary website) {
    Navigator.of(context).push(
      AnimatedPageRoute(page: WeddingWebsitePreviewPage(id: website.id)),
    );
  }

  Future<void> _publish(WeddingWebsiteSummary website) async {
    setState(() => _busyId = website.id);
    try {
      final result = await _api.publishWebsite(website.id);
      if (!mounted) return;
      AppSnackbar.success(context, 'Website published successfully!');
      setState(() {
        _websites = _websites
            .map((w) => w.id == website.id
                ? WeddingWebsiteSummary(
                    id: w.id,
                    templateId: w.templateId,
                    weddingDate: w.weddingDate,
                    isPublished: true,
                    websiteUrl: result.websiteUrl,
                    brideName: w.brideName,
                    groomName: w.groomName,
                  )
                : w)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _share(WeddingWebsiteSummary website) {
    final url = WeddingWebsiteApi.publicUrlFor(website.websiteUrl);
    SharePlus.instance.share(ShareParams(text: 'Website link: $url'));
  }

  Future<void> _delete(WeddingWebsiteSummary website) async {
    final confirmed = await ConfirmPopup.show(
      context,
      title: 'Delete this wedding website?',
      message: 'This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed) return;

    setState(() => _busyId = website.id);
    try {
      await _api.deleteWebsite(website.id);
      if (!mounted) return;
      setState(() {
        _websites = _websites.where((w) => w.id != website.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, AppErrorMessage.bodyFor(e));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'My Wedding Websites',
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: _createNew),
        ],
      ),
      body: AsyncView(
        isLoading: _loading,
        error: _error,
        isEmpty: _websites.isEmpty,
        onRetry: _load,
        empty: EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'No wedding websites yet',
          message: 'Create your first wedding website to get started',
          actionLabel: 'Create Your First Website',
          onAction: _createNew,
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: _websites.length,
            itemBuilder: (context, i) => _WebsiteCard(
              website: _websites[i],
              busy: _busyId == _websites[i].id,
              onPreview: () => _preview(_websites[i]),
              onEdit: () => _edit(_websites[i]),
              onPublish: () => _publish(_websites[i]),
              onShare: () => _share(_websites[i]),
              onDelete: () => _delete(_websites[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebsiteCard extends StatelessWidget {
  const _WebsiteCard({
    required this.website,
    required this.busy,
    required this.onPreview,
    required this.onEdit,
    required this.onPublish,
    required this.onShare,
    required this.onDelete,
  });

  final WeddingWebsiteSummary website;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final names = [website.brideName, website.groomName].where((s) => s.isNotEmpty).join(' & ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  names.isEmpty ? 'Untitled website' : names,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppBadge(
                label: website.isPublished ? 'Published' : 'Draft',
                background: website.isPublished
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                foreground: website.isPublished ? AppColors.successDark : AppColors.warning,
                compact: true,
              ),
            ],
          ),
          if (website.weddingDate.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: AppSpacing.xxs),
                Text(website.weddingDate, style: AppText.caption),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: AppLoader(size: 20, padding: EdgeInsets.zero),
            )
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _actionChip(Icons.visibility_outlined, 'Preview', onPreview),
                _actionChip(Icons.edit_outlined, 'Edit', onEdit),
                if (!website.isPublished)
                  _actionChip(Icons.public_rounded, 'Publish', onPublish, color: AppColors.successDark)
                else
                  _actionChip(Icons.share_outlined, 'Share', onShare, color: AppColors.successDark),
                _actionChip(Icons.delete_outline_rounded, 'Delete', onDelete, color: AppColors.error),
              ],
            ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? AppColors.primary;
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.10),
          borderRadius: AppRadii.rPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: AppSpacing.xxs),
            Text(label, style: AppText.labelSm.copyWith(color: c)),
          ],
        ),
      ),
    );
  }
}
