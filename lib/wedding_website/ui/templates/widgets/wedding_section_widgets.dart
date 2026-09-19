/// Shared section widgets used by all three Wedding Website templates
/// (royal / floral / modern).
///
/// Mirrors `src/templates/components/` in the source: the three template
/// trees under `src/templates/{royal,floral,modern}/index.jsx` render the
/// same section order — Navbar → Hero → Countdown → Couple → Story (love
/// story) → People (wedding party) → Location (when & where) → Gallery →
/// Rsvp → Footer — and only differ in colour/typography, not in what data
/// each section shows. That sharing is reproduced here: one widget per
/// section, themed by the [WeddingTemplateTheme] each template file passes
/// in, instead of three near-duplicate screens.
///
/// Deliberately not ported: the "Gift" section
/// (`src/templates/components/gift/index.jsx`) is a static stock-photo
/// carousel with no wedding data behind it, and two of the three templates
/// (royal, modern) already comment it out of their own render — only floral
/// renders it, and even there it carries nothing user-entered. Skipped as
/// decorative dead weight rather than a real gap.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/core.dart';
import '../../../models/wedding_website_models.dart';

/// Per-template colour/type accents. The section widgets below take one of
/// these and never hardcode a brand colour themselves.
class WeddingTemplateTheme {
  const WeddingTemplateTheme({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.headingFont,
  });

  final String name;
  final Color primary;
  final Color secondary;
  final Color background;

  /// Google Fonts family used for section headings — the one place the three
  /// templates read visually distinct, matching the source's own
  /// Georgia-serif (royal), rounded-script (floral) and sans (modern) themes.
  final TextStyle Function({required double fontSize, required FontWeight fontWeight})
  headingFont;

  static final royal = WeddingTemplateTheme(
    name: 'Royal',
    primary: const Color(0xFFC89C74),
    secondary: const Color(0xFF7A5C3E),
    background: const Color(0xFFFFFDF7),
    headingFont: ({required fontSize, required fontWeight}) =>
        GoogleFonts.playfairDisplay(fontSize: fontSize, fontWeight: fontWeight),
  );

  static final floral = WeddingTemplateTheme(
    name: 'Floral',
    primary: const Color(0xFFE9A6C1),
    secondary: const Color(0xFFB5566F),
    background: const Color(0xFFFFF6F9),
    headingFont: ({required fontSize, required fontWeight}) =>
        GoogleFonts.dancingScript(fontSize: fontSize + 6, fontWeight: fontWeight),
  );

  static final modern = WeddingTemplateTheme(
    name: 'Modern',
    primary: const Color(0xFF2C3E50),
    secondary: const Color(0xFF667EEA),
    background: const Color(0xFFF5F7FA),
    headingFont: ({required fontSize, required fontWeight}) =>
        GoogleFonts.montserrat(fontSize: fontSize, fontWeight: fontWeight, letterSpacing: 0.4),
  );

  static WeddingTemplateTheme forId(WeddingWebsiteTemplate template) => switch (template) {
    WeddingWebsiteTemplate.royal => royal,
    WeddingWebsiteTemplate.floral => floral,
    WeddingWebsiteTemplate.modern => modern,
  };
}

/// A section heading, styled with the template's own heading font — every
/// section in the source starts with `<Sectiontitle section="..." />`.
class WeddingSectionTitle extends StatelessWidget {
  const WeddingSectionTitle({super.key, required this.title, required this.theme});

  final String title;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.headingFont(fontSize: 24, fontWeight: FontWeight.w700).copyWith(
              color: theme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(width: 60, height: 3, color: theme.primary),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navbar — src/templates/components/Navbar (bride/groom names)
// ---------------------------------------------------------------------------

class WeddingNavbarSection extends StatelessWidget {
  const WeddingNavbarSection({
    super.key,
    required this.bride,
    required this.groom,
    required this.theme,
  });

  final WeddingPerson bride;
  final WeddingPerson groom;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    final names = [
      bride.name,
      if (bride.name.isNotEmpty && groom.name.isNotEmpty) '&',
      groom.name,
    ].where((s) => s.isNotEmpty).join(' ');

    return Container(
      width: double.infinity,
      color: theme.primary,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      child: SafeArea(
        bottom: false,
        child: Text(
          names.isEmpty ? 'Our Wedding' : names,
          textAlign: TextAlign.center,
          style: theme.headingFont(fontSize: 18, fontWeight: FontWeight.w600).copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero — src/templates/components/HeroMain / hero2 / hero3 (slider images)
// ---------------------------------------------------------------------------

class WeddingHeroSection extends StatefulWidget {
  const WeddingHeroSection({
    super.key,
    required this.sliderImages,
    required this.weddingDate,
    required this.theme,
  });

  final List<String> sliderImages;
  final String weddingDate;
  final WeddingTemplateTheme theme;

  @override
  State<WeddingHeroSection> createState() => _WeddingHeroSectionState();
}

class _WeddingHeroSectionState extends State<WeddingHeroSection> {
  final _controller = PageController();
  int _page = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.sliderImages.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        _page = (_page + 1) % widget.sliderImages.length;
        _controller.animateToPage(
          _page,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.sliderImages;
    return SizedBox(
      height: 320,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (images.isEmpty)
            Container(color: widget.theme.primary.withValues(alpha: 0.25))
          else
            PageView.builder(
              controller: _controller,
              itemCount: images.length,
              onPageChanged: (i) => _page = i,
              itemBuilder: (_, i) => NetworkImageWidget(url: images[i], fit: BoxFit.cover),
            ),
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.imageScrim))),
          if (widget.weddingDate.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.lg,
              child: Text(
                widget.weddingDate,
                textAlign: TextAlign.center,
                style: widget.theme
                    .headingFont(fontSize: 16, fontWeight: FontWeight.w500)
                    .copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Countdown — src/templates/components/countdown (live in every template)
// ---------------------------------------------------------------------------

class WeddingCountdownSection extends StatefulWidget {
  const WeddingCountdownSection({super.key, required this.weddingDate, required this.theme});

  final String weddingDate;
  final WeddingTemplateTheme theme;

  @override
  State<WeddingCountdownSection> createState() => _WeddingCountdownSectionState();
}

class _WeddingCountdownSectionState extends State<WeddingCountdownSection> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  DateTime? _target;

  @override
  void initState() {
    super.initState();
    _target = _parseTarget(widget.weddingDate);
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  DateTime? _parseTarget(String weddingDate) {
    if (weddingDate.isEmpty) return null;
    try {
      final datePart = weddingDate.length >= 10 ? weddingDate.substring(0, 10) : weddingDate;
      return DateTime.parse('${datePart}T23:59:59');
    } catch (_) {
      return null;
    }
  }

  void _tick() {
    if (!mounted || _target == null) return;
    final diff = _target!.difference(DateTime.now());
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weddingDate.isEmpty) {
      return _wrap(context, Text('No wedding date set', style: AppText.bodySm));
    }
    if (_target == null) {
      return _wrap(context, Text('Invalid wedding date', style: AppText.bodySm));
    }
    if (_remaining == Duration.zero && _target!.isBefore(DateTime.now())) {
      return _wrap(
        context,
        Text("It's the wedding day! 🎉", style: AppText.sectionTitle.copyWith(color: widget.theme.secondary)),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return _wrap(
      context,
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _unit(days, 'Days'),
          _unit(hours, 'Hours'),
          _unit(minutes, 'Minutes'),
          _unit(seconds, 'Seconds'),
        ],
      ),
    );
  }

  Widget _wrap(BuildContext context, Widget child) {
    return Container(
      width: double.infinity,
      color: widget.theme.background,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'Countdown to Our Special Day', theme: widget.theme),
          child,
        ],
      ),
    );
  }

  Widget _unit(int value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.theme.background,
              border: Border.all(color: widget.theme.primary, width: 3),
            ),
            child: Text(
              value.toString().padLeft(2, '0'),
              style: AppText.sectionTitle.copyWith(color: widget.theme.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label.toUpperCase(), style: AppText.caption),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Couple — src/templates/components/couple, Modern Couple
// ---------------------------------------------------------------------------

class WeddingCoupleSection extends StatelessWidget {
  const WeddingCoupleSection({super.key, required this.bride, required this.groom, required this.theme});

  final WeddingPerson bride;
  final WeddingPerson groom;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.background,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'The Happy Couple', theme: theme),
          _personCard(bride, 'Bride'),
          const SizedBox(height: AppSpacing.xl),
          _personCard(groom, 'Groom'),
        ],
      ),
    );
  }

  Widget _personCard(WeddingPerson person, String role) {
    return Column(
      children: [
        AppAvatar(url: person.imageUrl, name: person.name, size: 96, borderColor: theme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          person.name.isEmpty ? role : person.name,
          style: theme.headingFont(fontSize: 18, fontWeight: FontWeight.w600).copyWith(color: theme.secondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(role, style: AppText.overline.copyWith(color: theme.primary)),
        if (person.description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(person.description, textAlign: TextAlign.center, style: AppText.bodySm),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Story — src/templates/components/story (loveStory[])
// ---------------------------------------------------------------------------

class WeddingLoveStorySection extends StatelessWidget {
  const WeddingLoveStorySection({super.key, required this.entries, required this.theme});

  final List<LoveStoryEntry> entries;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'Our Love Story', theme: theme),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: AppRadii.rMd,
                        child: NetworkImageWidget(url: e.imageUrl, height: 160, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(e.title, style: AppText.cardTitle.copyWith(color: theme.secondary)),
                    if (e.date.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(e.date, style: AppText.caption),
                    ],
                    if (e.description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(e.description, style: AppText.bodySm),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// People — src/templates/components/people, Modern People (weddingParty[])
// ---------------------------------------------------------------------------

class WeddingPartySection extends StatelessWidget {
  const WeddingPartySection({super.key, required this.members, required this.theme});

  final List<WeddingPartyMember> members;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    return Container(
      color: theme.background,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'Wedding Party', theme: theme),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              for (final m in members)
                SizedBox(
                  width: 110,
                  child: Column(
                    children: [
                      AppAvatar(url: m.imageUrl, name: m.name, size: 76, borderColor: theme.primary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        m.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyStrong,
                      ),
                      if (m.relation.isNotEmpty)
                        Text(m.relation, textAlign: TextAlign.center, style: AppText.caption),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location — src/templates/components/location (whenWhere[])
// ---------------------------------------------------------------------------

class WeddingLocationSection extends StatelessWidget {
  const WeddingLocationSection({super.key, required this.events, required this.theme});

  final List<WhenWhereEvent> events;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'When & Where', theme: theme),
          for (final e in events)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: AppCard.outlined(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: AppRadii.rMd,
                        child: NetworkImageWidget(url: e.imageUrl, height: 140, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(e.title, style: AppText.cardTitle.copyWith(color: theme.secondary)),
                    if (e.date.isNotEmpty || e.time.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text([e.date, e.time].where((s) => s.isNotEmpty).join(' · '), style: AppText.caption),
                      ),
                    if (e.location.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 15, color: theme.primary),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(child: Text(e.location, style: AppText.bodySm)),
                          ],
                        ),
                      ),
                    if (e.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(e.description, style: AppText.bodySm),
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

// ---------------------------------------------------------------------------
// Gallery — src/templates/components/gallery (galleryImages[])
// ---------------------------------------------------------------------------

class WeddingGallerySection extends StatelessWidget {
  const WeddingGallerySection({super.key, required this.images, required this.theme});

  final List<String> images;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Container(
      color: theme.background,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'Our Gallery', theme: theme),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: AppRadii.rSm,
              child: NetworkImageWidget(url: images[i], fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rsvp — src/templates/components/rsvp, Modern Rsvp
// ---------------------------------------------------------------------------

/// Honest RSVP form. `Rsvp`/`RsvpComponent` in the source validate the form
/// and then just clear it on submit — there is no `weddingWebsiteApi` call
/// or any other endpoint anywhere in the source for RSVP submission. Faking
/// a "you're confirmed" response here would be exactly the fabricated
/// success this app's dead-code/no-mock-data rule forbids, so this shows an
/// honest message instead once the form validates.
class WeddingRsvpSection extends StatefulWidget {
  const WeddingRsvpSection({super.key, required this.theme});

  final WeddingTemplateTheme theme;

  @override
  State<WeddingRsvpSection> createState() => _WeddingRsvpSectionState();
}

class _WeddingRsvpSectionState extends State<WeddingRsvpSection> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _attending;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          WeddingSectionTitle(title: 'Be Our Guest', theme: widget.theme),
          AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _name,
                    label: 'Your name',
                    required: true,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _email,
                    label: 'Your email',
                    keyboardType: TextInputType.emailAddress,
                    required: true,
                    validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your email' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _attending,
                    decoration: const InputDecoration(labelText: 'Will you attend?'),
                    items: const [
                      DropdownMenuItem(value: 'yes', child: Text('Joyfully attending')),
                      DropdownMenuItem(value: 'no', child: Text('Regretfully declining')),
                    ],
                    onChanged: (v) => setState(() => _attending = v),
                    validator: (v) => v == null ? 'Please select your response' : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_submitted)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.10),
                        borderRadius: AppRadii.rMd,
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "RSVP isn't connected yet — please contact the couple directly to confirm.",
                              style: AppText.bodySm,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    PremiumButton(
                      label: 'Send RSVP',
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          setState(() => _submitted = true);
                        }
                      },
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

// ---------------------------------------------------------------------------
// Footer — src/templates/components/footer (slider images strip)
// ---------------------------------------------------------------------------

class WeddingFooterSection extends StatelessWidget {
  const WeddingFooterSection({super.key, required this.sliderImages, required this.theme});

  final List<String> sliderImages;
  final WeddingTemplateTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: theme.secondary,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.favorite, color: Colors.white70, size: 20),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Made with love on HappyWedz',
            style: TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
