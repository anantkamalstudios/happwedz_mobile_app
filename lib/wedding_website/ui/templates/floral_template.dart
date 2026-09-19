/// Floral theme — mirrors `src/templates/floral/index.jsx`'s section order:
/// Navbar → Hero → Countdown → Couple → Story → People → Location → Gallery
/// → Rsvp → Footer. The source's `Gift` carousel (static stock photos, no
/// wedding data) is skipped here — see the note in
/// `widgets/wedding_section_widgets.dart`.
library;

import 'package:flutter/material.dart';

import '../../models/wedding_website_models.dart';
import 'widgets/wedding_section_widgets.dart';

class FloralWeddingTemplate extends StatelessWidget {
  const FloralWeddingTemplate({super.key, required this.data});

  final WeddingWebsiteDetail data;

  @override
  Widget build(BuildContext context) {
    final theme = WeddingTemplateTheme.floral;
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
