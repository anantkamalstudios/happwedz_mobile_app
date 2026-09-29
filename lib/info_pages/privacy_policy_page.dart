// Native port of the website's /privacy page (PrivacyPolicy.jsx, live chunk
// PrivacyPolicy-B1twQiTj.js). Text lives in legal_content.dart.

import 'package:flutter/material.dart';

import 'package:happy_wedz/core/core.dart';

import 'contact_us_page.dart';
import 'info_page_widgets.dart';
import 'legal_content.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key, this.initialSectionId});

  /// Optional section key to open first (`overview`, `collect`, `use`,
  /// `sharing`, `cookies`, `payments`, `retention`, `rights`, `contact`).
  final String? initialSectionId;

  static const String title = 'Privacy Policy';
  static const String subtitle =
      'How HappyWedz collects, uses and protects the personal data of '
      'couples, their guests and our vendors.';

  @override
  Widget build(BuildContext context) {
    return LegalTabbedPage(
      title: title,
      subtitle: subtitle,
      sections: privacyPolicySections,
      initialSectionId: initialSectionId,
      footerBuilder: (context, _) => InfoSentence(
        parts: [
          'Questions about your privacy? Write to',
          InfoLink(
            label: 'privacy@happywedz.com',
            onTap: () => openInfoLink(
              context,
              Uri.parse('mailto:privacy@happywedz.com'),
            ),
          ),
          'or',
          // Web: <a href="/contact-us">contact support</a>.
          InfoLink(
            label: 'contact support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactUsPage()),
            ),
          ),
          Text(
            '.',
            style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
