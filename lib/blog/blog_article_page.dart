import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/core.dart';
import 'blog_api.dart';

/// Full blog post, loaded from `GET /blogs/:id` — the website's
/// BlogDetails.jsx. The old app screen only showed the list excerpt it was
/// handed; this one shows the whole article: category badge, title, byline,
/// summary, every paragraph with its image, trailing images, tags, the
/// "Love this wedding?" toggle, share buttons and the author card.
class BlogArticlePage extends StatefulWidget {
  const BlogArticlePage({super.key, required this.blogId, this.preview, this.api});

  final String blogId;

  /// Row from the list, shown in the header while the article loads.
  final BlogSummary? preview;
  final BlogApi? api;

  @override
  State<BlogArticlePage> createState() => _BlogArticlePageState();
}

class _BlogArticlePageState extends State<BlogArticlePage> {
  late final BlogApi _api = widget.api ?? BlogApi();
  BlogArticle? _article;
  bool _loading = true;
  Object? _error;

  /// Local only, like the website's `liked` state (never sent anywhere).
  bool _liked = false;

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
    try {
      final a = await _api.fetchById(widget.blogId);
      if (!mounted) return;
      setState(() => _article = a);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) AppSnackbar.error(context, "We couldn't open that link.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text('Blog', style: AppText.pageTitle),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Skeletons.detail(heroHeight: 220),
      );
    }
    if (_error != null) {
      return ErrorState(error: _error, onRetry: _load);
    }
    final a = _article;
    if (a == null) {
      return EmptyState(
        icon: Icons.article_outlined,
        title: 'Blog not found',
        actionLabel: 'Back to Blogs',
        onAction: () => Navigator.of(context).maybePop(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxxl,
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: PremiumButton.outlined(
            label: '← Back to Blogs',
            expanded: false,
            size: PremiumButtonSize.small,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (a.category.trim().isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.pinkSurface,
                borderRadius: AppRadii.rPill,
              ),
              child: Text(
                a.category.toUpperCase(),
                style: AppText.labelSm.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(a.title, textAlign: TextAlign.center, style: AppText.display),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _meta(Icons.person_outline_rounded, 'BY ${a.authorName}'),
            Text('|', style: AppText.caption),
            _meta(Icons.calendar_today_outlined, blogDate(a.createdDate)),
            Text('|', style: AppText.caption),
            _meta(Icons.schedule_rounded, a.readLabel),
          ],
        ),
        if (a.shortDescription.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            a.shortDescription,
            textAlign: TextAlign.center,
            style: AppText.bodyLg.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < a.paragraphs.length; i++) ...[
          if (i < a.images.length) _image(a.images[i]),
          Html(
            data: a.paragraphs[i],
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(15.5),
                lineHeight: const LineHeight(1.7),
                textAlign: TextAlign.justify,
                color: AppColors.textSecondary,
              ),
            },
            onLinkTap: (url, _, _) {
              if (url != null) _open(url);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final img in a.trailingImages) _image(img),
        const SizedBox(height: AppSpacing.xl),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: AppSpacing.md),
            Icon(Icons.favorite_rounded, color: AppColors.primary, size: 28),
            SizedBox(width: AppSpacing.md),
            Icon(Icons.favorite_border_rounded, color: AppColors.primary, size: 28),
          ],
        ),
        if (a.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Related Tags', textAlign: TextAlign.center, style: AppText.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final t in a.tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: AppRadii.rPill,
                    border: Border.all(color: AppColors.divider),
                  ),
                  // Tags arrive with or without "#"; the website prefixes one.
                  child: Text(
                    t.startsWith('#') ? t : '#$t',
                    style: AppText.labelSm,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: PremiumButton(
            label: _liked ? 'Liked!' : 'Love this wedding?',
            icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            expanded: false,
            onPressed: () => setState(() => _liked = !_liked),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        const Divider(color: AppColors.divider),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Share this beautiful wedding story',
          textAlign: TextAlign.center,
          style: AppText.bodyStrong,
        ),
        const SizedBox(height: AppSpacing.md),
        _shareButtons(a),
        const SizedBox(height: AppSpacing.xxl),
        AppCard.outlined(
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Text(
                  a.authorName.characters.first.toUpperCase(),
                  style: AppText.display.copyWith(color: Colors.white, fontSize: 24),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Written by ${a.authorName}', style: AppText.sectionTitle),
              const SizedBox(height: AppSpacing.xxs),
              Text('Wedding Story Curator at HappyWedz', style: AppText.caption),
            ],
          ),
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(text, style: AppText.caption),
        ],
      );

  Widget _image(String url) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: ClipRRect(
          borderRadius: AppRadii.rMd,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: NetworkImageWidget(url: url, width: double.infinity, fit: BoxFit.cover),
          ),
        ),
      );

  /// The website's four share links, opened outside the app.
  Widget _shareButtons(BlogArticle a) {
    final url = Uri.encodeComponent(a.shareUrl);
    final title = Uri.encodeComponent(
      a.title.isEmpty ? 'Beautiful Wedding Story' : a.title,
    );
    final links = {
      'Facebook': 'https://www.facebook.com/sharer/sharer.php?u=$url',
      'Twitter': 'https://twitter.com/intent/tweet?text=$title&url=$url',
      'Pinterest':
          'https://pinterest.com/pin/create/button/?url=$url&description=$title',
      'WhatsApp': 'https://api.whatsapp.com/send?text=$title%20$url',
    };
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final e in links.entries)
          PremiumButton.outlined(
            label: e.key,
            expanded: false,
            size: PremiumButtonSize.small,
            onPressed: () => _open(e.value),
          ),
      ],
    );
  }
}
