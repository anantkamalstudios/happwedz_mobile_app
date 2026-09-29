// Native port of the website's /terms page (TermsCondition.jsx, live chunk
// TermsCondition-B2l5kzcQ.js). Text lives in legal_content.dart.

import 'package:flutter/material.dart';

import 'contact_us_page.dart';
import 'info_page_widgets.dart';
import 'legal_content.dart';

/// "Terms & Condition" in the web footer. The page itself is titled
/// "Legal Terms & Policies" and holds five sections (Terms of Service,
/// Privacy Policy, Cookie Policy, Intellectual Property Policy, Disclaimer of
/// Liability).
class TermsPage extends StatelessWidget {
  const TermsPage({super.key, this.initialSectionId});

  /// Optional section key to open first (`terms`, `privacy`, `cookies`,
  /// `intellectual`, `disclaimer`).
  final String? initialSectionId;

  static const String title = 'Legal Terms & Policies';
  static const String subtitle =
      'Please review our policies carefully before using the platform.';

  @override
  Widget build(BuildContext context) {
    return LegalTabbedPage(
      title: title,
      subtitle: subtitle,
      sections: termsSections,
      initialSectionId: initialSectionId,
      footerBuilder: (context, section) => InfoSentence(
        parts: [
          // Web: "Have questions about our{" "}{title.toLowerCase()}?"
          'Have questions about our ${section.title.toLowerCase()}?',
          // Web: <a href="/contact-us">Contact Support</a>.
          InfoLink(
            label: 'Contact Support',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContactUsPage()),
            ),
          ),
        ],
      ),
    );
  }
}
