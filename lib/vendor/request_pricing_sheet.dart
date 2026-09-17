/// Reusable "Request Pricing & Availability" flow, usable for any vendor
/// category (venues today; the same sheet works unchanged the moment another
/// category's detail screen calls it, since nothing here is venue-specific).
///
/// Mirrors the website's `PricingModal.jsx` + `DayPicker.jsx`:
///  - the event date is restricted to the vendor's own `available_slots`
///    when they have published any — exactly the website's
///    `shouldDisableDate` behaviour — and otherwise accepts any future date;
///  - submits to the same `POST /api/request-pricing` endpoint the website
///    posts to;
///  - on success, best-effort opens a chat conversation with the vendor so
///    the enquiry has somewhere to continue, non-fatal if it fails — the
///    website does the same around its own `createConversation` call.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../chat_page_new.dart' show ChatService;
import '../core/core.dart';

/// Opens the sheet for [vendorId]/[vendorName]. [availableSlots] should be
/// the vendor's `attributes.available_slots` dates, already parsed — pass an
/// empty list when the vendor has not published a calendar.
Future<void> showRequestPricingSheet(
  BuildContext context, {
  required String vendorId,
  required String vendorName,
  List<DateTime> availableSlots = const [],
}) {
  return AppBottomSheet.show(
    context,
    title: 'Request Pricing & Availability',
    child: _RequestPricingForm(
      vendorId: vendorId,
      vendorName: vendorName,
      availableSlots: availableSlots,
    ),
  );
}

class _RequestPricingForm extends StatefulWidget {
  const _RequestPricingForm({
    required this.vendorId,
    required this.vendorName,
    required this.availableSlots,
  });

  final String vendorId;
  final String vendorName;
  final List<DateTime> availableSlots;

  @override
  State<_RequestPricingForm> createState() => _RequestPricingFormState();
}

class _RequestPricingFormState extends State<_RequestPricingForm> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  final _dateDisplay = TextEditingController();

  DateTime? _eventDate;
  bool _submitting = false;
  String? _dateError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    _dateDisplay.dispose();
    super.dispose();
  }

  /// Pre-fills from the signed-in user's saved profile, the same way the
  /// website pre-fills the modal from the logged-in account.
  Future<void> _prefillFromProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('user_name') ?? '').trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      _firstName.text = parts.first;
      if (parts.length > 1) _lastName.text = parts.sublist(1).join(' ');
    }
    _email.text = prefs.getString('user_email') ?? '';
    _phone.text = prefs.getString('user_mobile') ?? '';
    if (mounted) setState(() {});
  }

  bool _isAvailableDay(DateTime day) {
    if (widget.availableSlots.isEmpty) return true;
    return widget.availableSlots.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime initialDate = _eventDate ?? today;
    DateTime lastDate = today.add(const Duration(days: 365 * 2));

    if (widget.availableSlots.isNotEmpty) {
      final sorted = List<DateTime>.from(widget.availableSlots)..sort();
      final firstSlot = sorted.first;
      initialDate = _eventDate ?? (firstSlot.isBefore(today) ? today : firstSlot);
      if (sorted.last.isAfter(lastDate)) lastDate = sorted.last;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      helpText: 'Select event date',
      selectableDayPredicate: widget.availableSlots.isEmpty ? null : _isAvailableDay,
    );
    if (picked == null) return;

    setState(() {
      _eventDate = picked;
      _dateDisplay.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      _dateError = null;
    });
  }

  bool _validate() {
    String? dateError;
    String? formError;

    if (_firstName.text.trim().isEmpty ||
        _lastName.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty) {
      formError = 'Please fill in all required fields.';
    }
    if (_eventDate == null) {
      dateError = 'Select an event date';
      formError = null;
    }

    setState(() {
      _dateError = dateError;
      _formError = formError;
    });
    return dateError == null && formError == null;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_validate()) return;

    final vendorIdInt = int.tryParse(widget.vendorId);
    if (vendorIdInt == null) {
      setState(() => _formError = "Could not identify the vendor. Please try again.");
      return;
    }

    setState(() {
      _submitting = true;
      _formError = null;
    });

    final date = _eventDate!;
    final eventDateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    try {
      final ok = await ChatService.sendPricingRequest(
        vendorId: vendorIdInt,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        eventDate: eventDateStr,
        message: _message.text.trim(),
      );

      if (!ok) {
        throw Exception('Request could not be submitted.');
      }

      // Best-effort — a conversation not being created must not make a
      // successfully-submitted request look like it failed.
      try {
        await ChatService.createOrGetConversation(vendorId: vendorIdInt);
      } catch (e) {
        debugPrint('[PRICING] conversation creation failed (non-fatal): $e');
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      SuccessPopup.show(
        context,
        title: 'Request sent',
        message:
            'Your request has been sent. ${widget.vendorName} will contact you soon.',
      );
    } catch (e) {
      debugPrint('[PRICING] submit failed: $e');
      if (!mounted) return;
      setState(() {
        _formError = "We couldn't send your request. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.availableSlots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              '${widget.availableSlots.length} date${widget.availableSlots.length == 1 ? '' : 's'} '
              'open with ${widget.vendorName} — only those are selectable below.',
              style: AppText.caption,
            ),
          ),

        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _firstName,
                label: 'First name',
                enabled: !_submitting,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppTextField(
                controller: _lastName,
                label: 'Last name',
                enabled: !_submitting,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          enabled: !_submitting,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phone,
          label: 'Phone',
          keyboardType: TextInputType.phone,
          enabled: !_submitting,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _dateDisplay,
          label: 'Event date',
          hint: 'DD/MM/YYYY',
          prefixIcon: Icons.calendar_today_rounded,
          readOnly: true,
          enabled: !_submitting,
          errorText: _dateError,
          onTap: _submitting ? null : _pickDate,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _message,
          label: 'Message (optional)',
          maxLines: 3,
          enabled: !_submitting,
        ),

        if (_formError != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_formError!, style: AppText.error),
        ],

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: 'Send request',
          isLoading: _submitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
