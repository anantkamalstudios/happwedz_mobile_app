/// "Quick Inquiry" — a port of the website's
/// `src/components/layouts/QuickInquiryModal.jsx`.
///
/// A guest flow: no login, no auth header on the request. Name + phone +
/// event date go to `POST /request-pricing` with a throwaway guest email and
/// `isGuestInquiry: true`, then a conversation is attempted best-effort
/// (the web's `messagesApi.createConversation({vendorId, requestId})`, which
/// normally fails for guests and is ignored there too).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../core/core.dart';

/// Opens the quick-inquiry sheet. Works signed out.
Future<void> showQuickInquirySheet(
  BuildContext context, {
  required String vendorId,
  required String vendorName,
  http.Client? client,
}) {
  return AppBottomSheet.show(
    context,
    title: 'Quick Inquiry',
    child: QuickInquiryForm(vendorId: vendorId, vendorName: vendorName, client: client),
  );
}

/// The sheet body; public so it can be widget-tested.
class QuickInquiryForm extends StatefulWidget {
  const QuickInquiryForm({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.client,
    this.onSent,
  });

  final String vendorId;
  final String vendorName;
  final http.Client? client;

  /// Called after a successful submit instead of the default
  /// close-sheet-and-show-popup behaviour (used by tests).
  final VoidCallback? onSent;

  @override
  State<QuickInquiryForm> createState() => _QuickInquiryFormState();
}

class _QuickInquiryFormState extends State<QuickInquiryForm> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _dateDisplay = TextEditingController();
  DateTime? _eventDate;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _dateDisplay.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? today,
      firstDate: today, // DayPicker.jsx:102 — minDate={dayjs()}
      lastDate: today.add(const Duration(days: 365 * 3)),
      helpText: 'Select event date',
    );
    if (picked == null) return;
    setState(() {
      _eventDate = picked;
      _dateDisplay.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    });
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _name.text;
    final phone = _phone.text;

    // QuickInquiryModal.jsx:27-45 — same checks, same order, same copy.
    if (name.isEmpty || phone.isEmpty || _eventDate == null) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (phone.length < 10) {
      setState(() => _error = 'Please enter a valid phone number.');
      return;
    }
    final vendorIdInt = int.tryParse(widget.vendorId.trim());
    if (vendorIdInt == null || vendorIdInt <= 0) {
      setState(() => _error = 'Could not identify the vendor. Please try again.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    // QuickInquiryModal.jsx:51-53: first word is the first name, the rest
    // (after the first space) the last name.
    final trimmed = name.trim();
    final space = trimmed.indexOf(' ');
    final firstName = space < 0 ? trimmed : trimmed.substring(0, space);
    final lastName = space < 0 ? '' : trimmed.substring(space + 1);

    final client = widget.client ?? http.Client();
    try {
      final res = await client
          .post(
            Uri.parse('${ApiConfig.apiBase}/request-pricing'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vendorId': vendorIdInt,
              'firstName': firstName,
              'lastName': lastName,
              'email': 'guest_${DateTime.now().millisecondsSinceEpoch}@happywedz.com',
              'phone': phone,
              'eventDate': _isoDate(_eventDate!),
              'message': 'Quick inquiry from listing page',
              'isGuestInquiry': true,
            }),
          )
          .timeout(const Duration(seconds: 20));

      Object? result;
      try {
        result = jsonDecode(res.body);
      } catch (_) {
        result = null;
      }
      final ok = res.statusCode >= 200 && res.statusCode < 300;
      if (!ok || result is! Map) {
        final msg = result is Map ? result['message'] : null;
        throw _InquiryError(msg is String && msg.trim().isNotEmpty ? msg : 'Something went wrong.');
      }

      // Best-effort conversation (QuickInquiryModal.jsx:86-98).
      final data = result['data'];
      final request = result['request'];
      final requestId = (data is Map ? data['id'] : null) ??
          (request is Map ? request['id'] : null) ??
          result['id'];
      if (requestId != null) {
        await _createConversation(client, vendorIdInt, requestId);
      }

      if (!mounted) return;
      _name.clear();
      _phone.clear();
      _dateDisplay.clear();
      _eventDate = null;

      if (widget.onSent != null) {
        widget.onSent!();
        return;
      }
      final vendor = widget.vendorName.trim().isNotEmpty ? widget.vendorName : 'The vendor';
      final navigator = Navigator.of(context);
      final popupContext = navigator.context;
      navigator.pop();
      if (!popupContext.mounted) return;
      SuccessPopup.show(
        popupContext,
        title: 'Inquiry Sent!',
        message: '$vendor will contact you soon at $phone',
      );
    } on _InquiryError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('[QuickInquiry] submit failed: $e');
      if (mounted) setState(() => _error = 'Something went wrong.');
    } finally {
      if (widget.client == null) client.close();
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Mirrors `ChatService.createOrGetConversation` (chat_page_new.dart):
  /// form-encoded body to `/messages/user/conversations`, Bearer token when
  /// one exists. Failures are logged only.
  Future<void> _createConversation(http.Client client, int vendorId, Object requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.authTokenKey) ?? '';
      final res = await client
          .post(
            Uri.parse('${ApiConfig.apiBase}/messages/user/conversations'),
            headers: {
              'Accept': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: {'vendorId': '$vendorId', 'requestId': '$requestId'},
          )
          .timeout(const Duration(seconds: 15));
      if (kDebugMode) debugPrint('[QuickInquiry] conversation status ${res.statusCode}');
    } catch (e) {
      debugPrint('[QuickInquiry] createConversation warning: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.vendorName.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(12),
              border: const Border(left: BorderSide(color: AppColors.primary, width: 5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inquiring about:', style: AppText.caption),
                Text(widget.vendorName, style: AppText.cardTitle),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('⚠️ $_error', style: AppText.error),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppTextField(
          controller: _name,
          label: 'Your Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          enabled: !_submitting,
          required: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phone,
          label: 'Phone Number',
          hint: '+91 98765 43210',
          helperText: "📱 We'll share this with the vendor to contact you",
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          enabled: !_submitting,
          required: true,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _dateDisplay,
          label: 'Event Date',
          hint: 'DD/MM/YYYY',
          prefixIcon: Icons.calendar_today_rounded,
          readOnly: true,
          enabled: !_submitting,
          required: true,
          onTap: _submitting ? null : _pickDate,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '✨ No account needed! The vendor will contact you directly.',
          style: AppText.caption,
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          label: _submitting ? 'Sending...' : 'Send Quick Inquiry',
          // Web shows "Sending..." next to a spinner; PremiumButton's loading
          // state hides the label, so the button is disabled with the text instead.
          icon: _submitting ? Icons.hourglass_top_rounded : Icons.send_rounded,
          enabled: !_submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _InquiryError implements Exception {
  const _InquiryError(this.message);
  final String message;
}
