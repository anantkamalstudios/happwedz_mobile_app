/// Picks the right template widget for a website's `templateId` — shared by
/// the guest-facing public view and the owner's preview so both render the
/// exact same thing.
library;

import 'package:flutter/material.dart';

import '../../models/wedding_website_models.dart';
import 'floral_template.dart';
import 'modern_template.dart';
import 'royal_template.dart';

class WeddingTemplateView extends StatelessWidget {
  const WeddingTemplateView({super.key, required this.data});

  final WeddingWebsiteDetail data;

  @override
  Widget build(BuildContext context) {
    switch (data.template) {
      case WeddingWebsiteTemplate.floral:
        return FloralWeddingTemplate(data: data);
      case WeddingWebsiteTemplate.modern:
        return ModernWeddingTemplate(data: data);
      case WeddingWebsiteTemplate.royal:
        return RoyalWeddingTemplate(data: data);
    }
  }
}
