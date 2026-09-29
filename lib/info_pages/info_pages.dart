/// Static info / legal pages ported natively from the website.
///
/// ```dart
/// import 'package:happy_wedz/info_pages/info_pages.dart';
///
/// for (final page in InfoPage.values)
///   ListTile(
///     leading: Icon(page.icon),
///     title: Text(page.title),
///     onTap: () => page.open(context),
///   );
/// ```
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/core.dart';

import 'about_us_page.dart';
import 'cancellation_policy_page.dart';
import 'careers_page.dart';
import 'contact_us_page.dart';
import 'privacy_policy_page.dart';
import 'terms_page.dart';

export 'about_us_page.dart' show AboutUsPage;
export 'cancellation_policy_page.dart' show CancellationPolicyPage;
export 'careers_page.dart' show CareersPage, CareerTab;
export 'contact_us_page.dart'
    show
        ContactUsPage,
        ContactApi,
        ContactFormData,
        ContactSubmitException,
        ContactValidationError,
        validateContactForm;
export 'privacy_policy_page.dart' show PrivacyPolicyPage;
export 'terms_page.dart' show TermsPage;

/// The info pages in web-footer order, with the label, icon and web route of
/// each.
enum InfoPage {
  aboutUs('About HappyWedz', Icons.info_outline_rounded, '/about-us'),
  careers('Careers', Icons.work_outline_rounded, '/careers'),
  contactUs('Contact Us', Icons.support_agent_rounded, '/contact-us'),
  privacyPolicy('Privacy Policy', Icons.shield_outlined, '/privacy'),
  terms('Terms & Condition', Icons.description_outlined, '/terms'),
  cancellationPolicy(
    'Cancellation Policy',
    Icons.event_busy_outlined,
    '/cancellation',
  );

  const InfoPage(this.title, this.icon, this.webPath);

  final String title;
  final IconData icon;

  /// The route this page lives at on happywedz.com.
  final String webPath;

  Widget build(BuildContext context) => switch (this) {
        InfoPage.aboutUs => const AboutUsPage(),
        InfoPage.careers => const CareersPage(),
        InfoPage.contactUs => const ContactUsPage(),
        InfoPage.privacyPolicy => const PrivacyPolicyPage(),
        InfoPage.terms => const TermsPage(),
        InfoPage.cancellationPolicy => const CancellationPolicyPage(),
      };

  /// The live website pages. Privacy Policy (product decision 2026-09-28),
  /// Cancellation Policy, Terms & Condition, About Us, Careers and Contact Us
  /// (2026-09-29) open the website itself rather than the native copy, so the
  /// app always shows the current, maintained text.
  static final Uri aboutUsUrl = Uri.parse('https://happywedz.com/about-us');
  static final Uri careersUrl = Uri.parse('https://happywedz.com/careers');
  static final Uri contactUsUrl = Uri.parse('https://happywedz.com/contact-us');
  static final Uri privacyPolicyUrl = Uri.parse('https://happywedz.com/privacy');
  static final Uri termsUrl = Uri.parse('https://happywedz.com/terms');
  static final Uri cancellationPolicyUrl =
      Uri.parse('https://happywedz.com/cancellation');

  /// The website URL this page opens instead of its native screen, or null
  /// when it is shown natively.
  Uri? get externalUrl => switch (this) {
        InfoPage.aboutUs => aboutUsUrl,
        InfoPage.careers => careersUrl,
        InfoPage.contactUs => contactUsUrl,
        InfoPage.privacyPolicy => privacyPolicyUrl,
        InfoPage.terms => termsUrl,
        InfoPage.cancellationPolicy => cancellationPolicyUrl,
        // _ => null, // every page opens the website now (2026-09-29)
      };

  /// Pushes this page on the nearest navigator — except pages with an
  /// [externalUrl], which open in the browser — currently all of them. The
  /// native pages ([AboutUsPage], [CareersPage], [ContactUsPage],
  /// [PrivacyPolicyPage], [TermsPage], [CancellationPolicyPage]) are kept
  /// (unused) in case they are wanted back.
  Future<void> open(BuildContext context) async {
    final url = externalUrl;
    if (url != null) {
      final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppSnackbar.error(context, "We couldn't open the $title.");
      }
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: build));
  }

  /// Maps a website path (e.g. from a deep link or an in-content `href`) to
  /// its native page, or null when it isn't one of these pages.
  static InfoPage? fromWebPath(String path) {
    final p = path.split('?').first.split('#').first;
    for (final page in InfoPage.values) {
      if (page.webPath == p) return page;
    }
    return null;
  }
}

/// Convenience namespace for callers that prefer a class over the enum.
class InfoPages {
  const InfoPages._();

  static List<InfoPage> get all => InfoPage.values;

  static Future<void> open(BuildContext context, InfoPage page) =>
      page.open(context);
}
