// Native port of the website's /contact-us page (pages/Contactus.jsx +
// hooks/useContact.js, live chunk Contactus-C9iF_K0Z.js).
//
// Submission mirrors the web exactly: POST {API_BASE_URL}/contact with a JSON
// body of the five fields, sent through the shared axios instance — which
// adds `Authorization: Bearer <token>` only when the visitor is signed in.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/core/config/api_config.dart';
import 'package:happy_wedz/core/core.dart';

import 'info_page_widgets.dart';

// ---------------------------------------------------------------------------
// Form model + validation (web: Contactus.jsx handleSubmit)
// ---------------------------------------------------------------------------

class ContactFormData {
  const ContactFormData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.message,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String message;

  /// Body sent by `useContact.submitContact` — values are sent as typed
  /// (the web does not trim them).
  Map<String, String> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'message': message,
      };
}

/// A failed client-side check, shown the way the web's SweetAlert shows it.
class ContactValidationError {
  const ContactValidationError({this.title, required this.message});

  final String? title;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ContactValidationError &&
      other.title == title &&
      other.message == message;

  @override
  int get hashCode => Object.hash(title, message);

  @override
  String toString() => 'ContactValidationError($title, $message)';
}

final RegExp contactEmailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp contactPhoneRegex = RegExp(r'^\d{10}$');

/// Returns null when the form may be submitted. Same order and copy as the
/// web: required → email → phone.
ContactValidationError? validateContactForm(ContactFormData f) {
  if (f.firstName.trim().isEmpty ||
      f.lastName.trim().isEmpty ||
      f.email.trim().isEmpty ||
      f.phone.trim().isEmpty ||
      f.message.trim().isEmpty) {
    return const ContactValidationError(
      title: 'Incomplete Form',
      message: 'Please fill out all fields.',
    );
  }
  if (!contactEmailRegex.hasMatch(f.email)) {
    return const ContactValidationError(
      title: 'Invalid Email',
      message: 'Please enter a valid email address.',
    );
  }
  if (!contactPhoneRegex.hasMatch(f.phone)) {
    return const ContactValidationError(
      message: 'Please enter a valid 10-digit phone number.',
    );
  }
  return null;
}

// ---------------------------------------------------------------------------
// API (web: hooks/useContact.js)
// ---------------------------------------------------------------------------

class ContactSubmitException implements Exception {
  const ContactSubmitException(this.message, {this.statusCode});

  /// Server `message` when it sent one, otherwise the generic fallback.
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ContactSubmitException($statusCode): $message';
}

class ContactApi {
  ContactApi({
    http.Client? client,
    Future<String?> Function()? tokenReader,
    String? baseUrl,
    this.timeout = const Duration(seconds: 30),
  })  : _client = client,
        _tokenReader = tokenReader ?? _readSavedToken,
        _baseUrl = baseUrl ?? ApiConfig.apiBase;

  final http.Client? _client;
  final Future<String?> Function() _tokenReader;
  final String _baseUrl;

  /// axios instance timeout on the web.
  final Duration timeout;

  static const String fallbackError =
      'Failed to submit form. Please try again.';

  static Future<String?> _readSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Uri get endpoint => Uri.parse('$_baseUrl/contact');

  /// POSTs the form. Completes normally on any 2xx; otherwise throws
  /// [ContactSubmitException].
  Future<void> submit(ContactFormData form) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await _tokenReader();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final client = _client ?? http.Client();
    http.Response res;
    try {
      res = await client
          .post(endpoint, headers: headers, body: jsonEncode(form.toJson()))
          .timeout(timeout);
    } catch (_) {
      throw const ContactSubmitException(fallbackError);
    } finally {
      if (_client == null) client.close();
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ContactSubmitException(
      _serverMessage(res.body) ?? fallbackError,
      statusCode: res.statusCode,
    );
  }

  static String? _serverMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        final m = (decoded['message'] as String).trim();
        if (m.isNotEmpty) return m;
      }
    } catch (_) {}
    return null;
  }
}

// ---------------------------------------------------------------------------
// Static content (live chunk)
// ---------------------------------------------------------------------------

class ContactCardInfo {
  const ContactCardInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.email,
  });

  final IconData icon;
  final String title;
  final String description;
  final String email;
}

const List<ContactCardInfo> contactCards = [
  ContactCardInfo(
    icon: Icons.work_outline_rounded,
    title: 'Vendors',
    description:
        'Are you an expert vendor eager to expand your business opportunities? Connect with us and discover the ideal platform to grow.',
    email: 'support@happywedz.com',
  ),
  ContactCardInfo(
    icon: Icons.trending_up_rounded,
    title: 'Marketing Collaborations',
    description:
        'For direct collaborations—including promotional events, shoots, or paid opportunities—reach out to us.',
    email: 'support@happywedz.com',
  ),
  ContactCardInfo(
    icon: Icons.favorite_border_rounded,
    title: 'Wedding Submissions',
    description:
        "We're passionate about celebrating weddings on happywedz.com! Share your wedding story, photos, and vendor details with us.",
    email: 'support@happywedz.com',
  ),
  ContactCardInfo(
    icon: Icons.people_outline_rounded,
    title: 'Careers',
    description:
        "We have a team of dedicated professionals on the network, and we're always on the lookout for new talent. Join us today!",
    email: 'support@happywedz.com',
  ),
  ContactCardInfo(
    icon: Icons.mail_outline_rounded,
    title: 'Customers',
    description:
        'We aim to connect you with the very best in premium vendors. Share your feedback or concerns to help us improve.',
    email: 'support@happywedz.com',
  ),
];

const String playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.happy.happy_wedz&pcampaignid=web_share';
const String appStoreUrl =
    'https://apps.apple.com/in/app/happy-wedz/id6756042192';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key, this.api});

  /// Injected in tests; defaults to the real endpoint.
  final ContactApi? api;

  static const String title = 'Contact Us';

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  late final ContactApi _api = widget.api ?? ContactApi();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = ContactFormData(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      message: _message.text,
    );
    final invalid = validateContactForm(form);
    if (invalid != null) {
      AppSnackbar.error(context, invalid.message, title: invalid.title);
      return;
    }

    setState(() => _loading = true);
    try {
      await _api.submit(form);
      if (!mounted) return;
      AppSnackbar.success(context, 'Form submitted successfully!');
      for (final c in [_firstName, _lastName, _email, _phone, _message]) {
        c.clear();
      }
    } on ContactSubmitException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message, title: 'Error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoPageScaffold(
      title: ContactUsPage.title,
      children: [
        _formCard(),
        AppSpacing.h32,
        Text(
          'Get In Touch',
          textAlign: TextAlign.center,
          style: AppText.displaySm.copyWith(color: const Color(0xFF1F2937)),
        ),
        AppSpacing.h8,
        Text(
          "We'd love to hear from you",
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: const Color(0xFF6B7280)),
        ),
        AppSpacing.h24,
        for (final card in contactCards) _contactCard(card),
        AppSpacing.h24,
        Text(
          'Connect us to get best Deals',
          style: AppText.sectionTitle.copyWith(color: AppColors.primary),
        ),
        AppSpacing.h12,
        _infoBox(
          'For Vendors',
          _iconRow(
            Icons.mail_outline_rounded,
            InfoLink(
              label: 'support@happywedz.com',
              style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700),
              onTap: () => _mail('support@happywedz.com'),
            ),
          ),
        ),
        _infoBox(
          'For Users',
          _iconRow(
            Icons.mail_outline_rounded,
            InfoLink(
              label: 'support@happywedz.com',
              style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700),
              onTap: () => _mail('support@happywedz.com'),
            ),
          ),
        ),
        _infoBox(
          'Registered Address',
          _iconRow(
            Icons.location_on_outlined,
            Text(
              'Pune, India',
              style: AppText.bodyStrong.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        _appBanner(),
      ],
    );
  }

  void _mail(String email) =>
      openInfoLink(context, Uri(scheme: 'mailto', path: email));

  Widget _formCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CONTACT US',
            textAlign: TextAlign.center,
            style: AppText.pageTitle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.h20,
          _field('First Name', _firstName, key: 'contact-firstName',
              capitalization: TextCapitalization.words),
          _field('Last Name', _lastName, key: 'contact-lastName',
              capitalization: TextCapitalization.words),
          _field('Email', _email,
              key: 'contact-email', keyboard: TextInputType.emailAddress),
          _field('Phone', _phone,
              key: 'contact-phone', keyboard: TextInputType.phone),
          _field('Message', _message,
              key: 'contact-message',
              maxLines: 4,
              minLines: 3,
              keyboard: TextInputType.multiline,
              capitalization: TextCapitalization.sentences),
          AppSpacing.h8,
          PremiumButton(
            key: const ValueKey('contact-submit'),
            label: _loading ? 'SUBMITTING...' : 'SUBMIT',
            onPressed: _loading ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required String key,
    TextInputType? keyboard,
    int maxLines = 1,
    int? minLines,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppTextField(
        key: ValueKey(key),
        controller: controller,
        label: label,
        hint: label,
        keyboardType: keyboard,
        maxLines: maxLines,
        minLines: minLines,
        enabled: !_loading,
        textCapitalization: capitalization,
        fillColor: AppColors.pinkSurface,
      ),
    );
  }

  Widget _contactCard(ContactCardInfo card) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      border: Border.all(color: const Color(0xFFF3F4F6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              borderRadius: AppRadii.rMd,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
              ),
            ),
            child: Icon(card.icon, color: Colors.white, size: 24),
          ),
          AppSpacing.h16,
          Text(
            card.title,
            style: AppText.sectionTitle.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
          AppSpacing.h8,
          Text(
            card.description,
            style: AppText.body.copyWith(color: const Color(0xFF6B7280)),
          ),
          AppSpacing.h16,
          InfoLink(
            icon: Icons.mail_outline_rounded,
            label: card.email,
            style: AppText.bodyStrong.copyWith(color: const Color(0xFFE41F81)),
            onTap: () => _mail(card.email),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, Widget child) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      radius: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 5),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEC4C9C))),
            ),
            child: Text(
              title,
              style: AppText.bodyLg.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AppSpacing.h16,
          child,
        ],
      ),
    );
  }

  Widget _iconRow(IconData icon, Widget child) {
    return Row(
      children: [
        Icon(icon, size: 25, color: AppColors.primary),
        AppSpacing.w8,
        Flexible(child: child),
      ],
    );
  }

  Widget _appBanner() {
    Widget button(String label, IconData icon, String url, String semantics) {
      return Semantics(
        button: true,
        label: semantics,
        child: InkWell(
          borderRadius: AppRadii.rSm,
          onTap: () => openInfoLink(context, Uri.parse(url)),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadii.rSm,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                AppSpacing.w8,
                Flexible(
                  child: Text(
                    label,
                    style: AppText.button.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE83581), Color(0xFFC2185B)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59C2185B),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          button(
            'Play Store',
            Icons.rate_review_outlined,
            playStoreUrl,
            'HappyWedz App on Google Play Store',
          ),
          button(
            'Apple Store',
            Icons.phone_iphone_rounded,
            appStoreUrl,
            'HappyWedz App on Apple App Store',
          ),
        ],
      ),
    );
  }
}
