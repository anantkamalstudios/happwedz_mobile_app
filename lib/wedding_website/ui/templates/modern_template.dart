/// Modern theme — mirrors `src/templates/modern/index.jsx`'s section order:
/// Navbar → Hero → Countdown → Couple ("Modern Couple") → Story → People
/// ("Modern People") → Location → Gallery → Rsvp ("Modern Rsvp") → Footer.
/// The source comments out its plain `People`/`Rsvp`/`Gift` in favour of the
/// "Modern *" variants; the shared section widgets already cover both, so no
/// separate modern-only widget is needed here.
library;

import 'package:flutter/material.dart';

import '../../models/wedding_website_models.dart';
import 'widgets/wedding_section_widgets.dart';

class ModernWeddingTemplate extends StatelessWidget {
  const ModernWeddingTemplate({super.key, required this.data});

  final WeddingWebsiteDetail data;

  @override
  Widget build(BuildContext context) {
    final theme = WeddingTemplateTheme.modern;
    return Container(
      color: theme.background,
      child: Column(
        children: [
          WeddingNavbarSection(bride: data.bride, groom: data.groom, theme: theme),
          WeddingHeroSection(
            sliderImages: data.sliderImages,
            weddingDate: data.weddingDate,
            theme: theme,
          ),
          WeddingCountdownSection(weddingDate: data.weddingDate, theme: theme),
          WeddingCoupleSection(bride: data.bride, groom: data.groom, theme: theme),
          WeddingLoveStorySection(entries: data.loveStory, theme: theme),
          WeddingPartySection(members: data.weddingParty, theme: theme),
          WeddingLocationSection(events: data.whenWhere, theme: theme),
          WeddingGallerySection(images: data.galleryImages, theme: theme),
          WeddingRsvpSection(theme: theme),
          WeddingFooterSection(sliderImages: data.sliderImages, theme: theme),
        ],
      ),
    );
  }
}
