// Shared building blocks for the static info / legal pages ported from the
// website (About Us, Careers, Contact Us, Privacy, Terms, Cancellation).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:happy_wedz/core/core.dart';

import 'legal_content.dart';

/// Opens an external link (mailto:, tel:, http[s]:) outside the app.
///
/// Shows an error snackbar when no app can handle it instead of failing
/// silently.
Future<void> openInfoLink(BuildContext context, Uri uri) async {
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    AppSnackbar.error(context, 'Could not open ${_linkLabel(uri)}');
  }
}

String _linkLabel(Uri uri) => switch (uri.scheme) {
      'mailto' => uri.path,
      'tel' => uri.path,
      _ => uri.toString(),
    };

/// Scaffold for every info page: brand gradient header (back button, title,
/// optional subtitle) followed by a scrolling, text-selectable body.
class InfoPageScaffold extends StatelessWidget {
  const InfoPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.controller,
    this.header,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xl,
      AppSpacing.lg,
      AppSpacing.huge,
    ),
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final ScrollController? controller;

  /// Replaces the default gradient header (Careers uses a photo hero).
  final Widget? header;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SelectionArea(
        child: CustomScrollView(
          controller: controller,
          slivers: [
            SliverToBoxAdapter(
              child: header ?? InfoGradientHeader(title: title, subtitle: subtitle),
            ),
            SliverPadding(
              padding: padding,
              sliver: SliverList(delegate: SliverChildListDelegate(children)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient header with a back button, a centred title and a subtitle.
class InfoGradientHeader extends StatelessWidget {
  const InfoGradientHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AppBackButton centres itself; keep it at the leading edge.
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 48,
              height: 40,
              child: AppBackButton(color: AppColors.textOnPrimary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.sm,
              0,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.displaySm.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  AppSpacing.h8,
                  Text(
                    subtitle!,
                    style: AppText.body.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.92),
                    ),
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

/// Inline tappable link text (brand colour, bold), used in footers and cards.
class InfoLink extends StatelessWidget {
  const InfoLink({
    super.key,
    required this.label,
    required this.onTap,
    this.style,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle? style;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ??
        AppText.bodySm.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        );
    return Semantics(
      link: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.rXs,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: icon == null
              ? Text(label, style: textStyle)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: textStyle.color),
                    AppSpacing.w4,
                    Flexible(child: Text(label, style: textStyle)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A plain text fragment followed/preceded by [InfoLink]s, laid out as a
/// wrapping sentence (e.g. "Questions about your privacy? Write to …").
class InfoSentence extends StatelessWidget {
  const InfoSentence({super.key, required this.parts, this.style});

  /// Either [String]s (plain text) or widgets (usually [InfoLink]).
  final List<Object> parts;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ?? AppText.bodySm.copyWith(color: AppColors.textSecondary);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 2,
      children: [
        for (final p in parts)
          if (p is Widget) p else Text(p.toString(), style: textStyle),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Legal text renderer
// ---------------------------------------------------------------------------

enum LegalLineKind { heading, bullet, paragraph, spacer }

class LegalLine {
  const LegalLine(this.kind, this.text);
  final LegalLineKind kind;
  final String text;
}

final RegExp _numberedHeading = RegExp(r'^\d+\.\s');
final RegExp _letteredHeading = RegExp(r'^[a-z]\)\s');

/// Splits a legal template string exactly like the web formatter
/// (`formatContent` in PrivacyPolicy.jsx / TermsCondition.jsx):
///
/// * the whole string is trimmed, then split on `\n`; each line is trimmed;
/// * empty line → a `<br>` ([LegalLineKind.spacer]);
/// * `1. …` or `a) …` → an `<h5>` heading;
/// * a line starting with `•` → a bullet whose text is the rest, trimmed;
/// * anything else → a paragraph.
List<LegalLine> parseLegalContent(String content) {
  return content.trim().split('\n').map((raw) {
    final line = raw.trim();
    if (line.isEmpty) return const LegalLine(LegalLineKind.spacer, '');
    if (_numberedHeading.hasMatch(line) || _letteredHeading.hasMatch(line)) {
      return LegalLine(LegalLineKind.heading, line);
    }
    if (line.startsWith('•')) {
      return LegalLine(LegalLineKind.bullet, line.substring(1).trim());
    }
    return LegalLine(LegalLineKind.paragraph, line);
  }).toList();
}

/// Renders a [LegalSection.content] string.
class LegalContentView extends StatelessWidget {
  const LegalContentView({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final lines = parseLegalContent(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines) _line(line),
      ],
    );
  }

  Widget _line(LegalLine line) {
    switch (line.kind) {
      case LegalLineKind.spacer:
        return const SizedBox(height: AppSpacing.sm);
      case LegalLineKind.heading:
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Text(line.text, style: AppText.cardTitle),
        );
      case LegalLineKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '•',
                style: AppText.body.copyWith(color: AppColors.primary),
              ),
              AppSpacing.w8,
              Expanded(
                child: Text(
                  line.text,
                  style: AppText.body.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        );
      case LegalLineKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            line.text,
            style: AppText.body.copyWith(color: AppColors.textSecondary),
          ),
        );
    }
  }
}

/// The web's two-column legal layout (section nav + content card) collapsed
/// for mobile: a horizontally scrolling section selector (the web's mobile
/// `<select>`), then one card with the active section, then a footer.
class LegalTabbedPage extends StatefulWidget {
  const LegalTabbedPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    required this.footerBuilder,
    this.initialSectionId,
  });

  final String title;
  final String subtitle;
  final List<LegalSection> sections;

  /// Builds the card footer for the active section.
  final Widget Function(BuildContext context, LegalSection active)
      footerBuilder;

  /// Section to open first (defaults to the first one, as on the web).
  final String? initialSectionId;

  @override
  State<LegalTabbedPage> createState() => _LegalTabbedPageState();
}

class _LegalTabbedPageState extends State<LegalTabbedPage> {
  final ScrollController _scroll = ScrollController();
  late final List<GlobalKey> _chipKeys =
      List.generate(widget.sections.length, (_) => GlobalKey());
  late int _active;

  @override
  void initState() {
    super.initState();
    final i = widget.sections.indexWhere((s) => s.id == widget.initialSectionId);
    _active = i < 0 ? 0 : i;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (index == _active) return;
    setState(() => _active = index);
    final chipContext = _chipKeys[index].currentContext;
    if (chipContext != null) {
      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: AppMotion.normal,
      );
    }
    // Web: window.scrollTo({ top: 0, behavior: "smooth" }).
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: AppMotion.normal,
        curve: AppMotion.standard,
      );
    }
  }

  Widget _chip(int i) {
    final s = widget.sections[i];
    final selected = i == _active;
    return ChoiceChip(
      key: _chipKeys[i],
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => _select(i),
      avatar: Icon(
        s.icon,
        size: 16,
        color: selected ? Colors.white : AppColors.primary,
      ),
      label: Text(s.title),
      labelStyle: AppText.label.copyWith(
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      shape: const StadiumBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.sections[_active];
    return InfoPageScaffold(
      title: widget.title,
      subtitle: widget.subtitle,
      controller: _scroll,
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.huge,
      ),
      children: [
        // Not lazy: every chip exists, so the active one can always be
        // scrolled into view.
        SingleChildScrollView(
          key: const ValueKey('legal-section-selector'),
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < widget.sections.length; i++) ...[
                if (i > 0) AppSpacing.w8,
                _chip(i),
              ],
            ],
          ),
        ),
        AppSpacing.h16,
        Padding(
          padding: AppSpacing.page,
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          section.icon,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      AppSpacing.w12,
                      Expanded(
                        child: Text(section.title, style: AppText.sectionTitle),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: KeyedSubtree(
                    key: ValueKey('legal-content-${section.id}'),
                    child: LegalContentView(content: section.content),
                  ),
                ),
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: widget.footerBuilder(context, section),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
