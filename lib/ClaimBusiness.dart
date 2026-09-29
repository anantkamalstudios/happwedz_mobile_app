// Business Claim Form — single-step port of the live website's form.
//
// Web source of truth (src (1)/src):
//   components/pages/BusinessClaimForm.jsx  (UI, copy)
//   hooks/useClaimForm.js                   (fields, input rules, validation, submit)
//   services/api/claimFormApi.js            (GET /vendor-services/{id}, JSON POST /business/claims)
//
// The web trimmed the form down to Business Information only: no claimant
// block, no social links, no documents, no declaration/date. The request is
// plain JSON `{...formData, vendor_id, vendor_subcategory_data_id}` where both
// ids come from the prefetched vendor service (vendor_id = service.vendor_id,
// vendor_subcategory_data_id = service.id). No login is required.
//
// The previous 5-step multipart/document implementation is kept, commented
// out, at the bottom of this file ("LEGACY 5-STEP CLAIM FORM").

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/config/api_config.dart';
import 'core/core.dart';

// ---------------------------------------------------------------------------
// Pure logic (mirrors useClaimForm.js) — public so it can be unit tested.
// ---------------------------------------------------------------------------

/// Form field keys, in the web's order. These are also the JSON keys sent.
const List<String> kClaimFieldKeys = [
  'businessName',
  'registeredAddress',
  'phoneNumber',
  'emailAddress',
  'website',
  'category',
  'registrationNumber',
];

/// Placeholders exactly as BusinessClaimForm.jsx renders them.
const Map<String, String> kClaimFieldPlaceholders = {
  'businessName': 'Business Name',
  'registeredAddress': 'Registered Business Address',
  'phoneNumber': 'Business Phone Number',
  'emailAddress': 'Business Email Address',
  'website': 'Business Website',
  'category': 'Business Category / Type',
  'registrationNumber': 'Business Registration Number (if applicable)',
};

/// Required fields and the labels used in "{Label} is required"
/// (useClaimForm.js `validateForm.requiredFields`, in order).
const Map<String, String> kClaimRequiredFields = {
  'businessName': 'Business Name',
  'registeredAddress': 'Registered Address',
  'phoneNumber': 'Business Phone Number',
  'emailAddress': 'Business Email',
  'category': 'Business Category',
};

const String kClaimSuccessMessage = 'Claim form submitted successfully!';
const String kClaimMissingVendorMessage =
    'We could not identify this business. Please reopen the form.';
const String kClaimSubmitFailedMessage =
    'Failed to submit claim. Please try again.';
const String kClaimUnexpectedErrorMessage =
    'An error occurred. Please try again.';
const String kClaimLoadFailedMessage = 'Failed to fetch vendor details';

final RegExp _claimEmailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final RegExp _claimTextRegex = RegExp(r"^[a-zA-Z\s.,'-]*$");
final RegExp _claimDigitsRegex = RegExp(r'^\d*$');

/// Per-keystroke rule from `handleInputChange`. Returns the toast message
/// when [value] must be rejected (the field keeps its previous value), or
/// null when it may be accepted. An empty value is always accepted.
String? claimInputError(String field, String value) {
  if (value.isEmpty) return null;
  if (const ['businessName', 'registeredAddress', 'category']
      .contains(field)) {
    if (!_claimTextRegex.hasMatch(value)) {
      return 'This field should only contain letters';
    }
  }
  if (field == 'registrationNumber') {
    if (!_claimDigitsRegex.hasMatch(value)) {
      return 'This field should only contain numbers';
    }
  }
  if (field == 'phoneNumber') {
    if (!_claimDigitsRegex.hasMatch(value) || value.length > 10) {
      return 'Please enter a valid 10-digit number';
    }
  }
  return null;
}

/// `validateForm` — first failing rule's message, or null when valid.
String? validateClaimForm(Map<String, String> form) {
  for (final entry in kClaimRequiredFields.entries) {
    final v = form[entry.key] ?? '';
    if (v.trim().isEmpty) return '${entry.value} is required';
  }
  if ((form['phoneNumber'] ?? '').length != 10) {
    return 'Business Phone Number must be exactly 10 digits';
  }
  if (!_claimEmailRegex.hasMatch(form['emailAddress'] ?? '')) {
    return 'Please enter a valid business email address';
  }
  return null;
}

String _str(dynamic v) {
  if (v == null) return '';
  final s = v.toString();
  return s;
}

/// Truthy-string helper matching JS `a || b || ""`.
String _firstNonEmpty(List<dynamic> values) {
  for (final v in values) {
    final s = _str(v);
    if (s.isNotEmpty) return s;
  }
  return '';
}

/// `prefillFormData` — values the form is seeded with from
/// GET /vendor-services/{id}. registrationNumber is never prefilled.
Map<String, String> claimPrefillFrom(Map<String, dynamic> data) {
  final vendor = data['vendor'] is Map
      ? Map<String, dynamic>.from(data['vendor'] as Map)
      : const <String, dynamic>{};
  final attributes = data['attributes'] is Map
      ? Map<String, dynamic>.from(data['attributes'] as Map)
      : const <String, dynamic>{};
  final location = attributes['location'] is Map
      ? Map<String, dynamic>.from(attributes['location'] as Map)
      : const <String, dynamic>{};
  final vendorType = vendor['vendorType'] is Map
      ? Map<String, dynamic>.from(vendor['vendorType'] as Map)
      : const <String, dynamic>{};

  return {
    'businessName':
        _firstNonEmpty([attributes['vendor_name'], vendor['businessName']]),
    'registeredAddress': _firstNonEmpty([location['address']]),
    'phoneNumber': _firstNonEmpty([vendor['phone']]),
    'emailAddress': _firstNonEmpty([vendor['email'], attributes['email']]),
    'website': _firstNonEmpty([attributes['cta_url']]),
    'category':
        _firstNonEmpty([vendorType['name'], attributes['vendor_type']]),
  };
}

/// Name shown in the "Claiming Business:" banner.
String claimBusinessDisplayName(Map<String, dynamic> data) {
  final vendor = data['vendor'] is Map ? data['vendor'] as Map : const {};
  final attributes =
      data['attributes'] is Map ? data['attributes'] as Map : const {};
  return _firstNonEmpty([vendor['businessName'], attributes['vendor_name']]);
}

/// The JSON body: `{...formData, vendor_id: vendorData.vendor_id,
/// vendor_subcategory_data_id: vendorData.id}`.
Map<String, dynamic> buildClaimPayload(
  Map<String, String> form,
  Map<String, dynamic> vendorData,
) {
  return {
    for (final k in kClaimFieldKeys) k: form[k] ?? '',
    'vendor_id': vendorData['vendor_id'],
    'vendor_subcategory_data_id': vendorData['id'],
  };
}

/// Server message from an error body, falling back to [fallback].
String claimServerMessage(String body, String fallback) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map && decoded['message'] != null) {
      final m = decoded['message'].toString();
      if (m.isNotEmpty) return m;
    }
  } catch (_) {}
  return fallback;
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

class BusinessClaimForm extends StatefulWidget {
  /// Vendor account id. Kept for constructor compatibility; the id actually
  /// sent as `vendor_id` is the one returned by GET /vendor-services/{id},
  /// exactly as the web does.
  final String vendorId;

  /// Legacy: the listing's `vendor_subcategory_id` (category type). NOT the
  /// `vendor_subcategory_data_id` the API expects — kept only so existing
  /// callers compile. Not sent.
  final String vendorSubcategoryId;

  /// Optional full vendor-service map; its `id` is used as the service id
  /// when [vendorServiceId] is not given.
  final dynamic service;

  /// The vendor-service (listing) id — web `vendorServiceId` /
  /// `venueData.id`. Used to prefetch the listing; its `id` becomes
  /// `vendor_subcategory_data_id`.
  final String? vendorServiceId;

  /// Injected for tests; defaults to a fresh [http.Client].
  final http.Client? httpClient;

  const BusinessClaimForm({
    super.key,
    required this.vendorId,
    required this.vendorSubcategoryId,
    this.service,
    this.vendorServiceId,
    this.httpClient,
  });

  @override
  State<BusinessClaimForm> createState() => _BusinessClaimFormState();
}

class _BusinessClaimFormState extends State<BusinessClaimForm> {
  late final http.Client _client = widget.httpClient ?? http.Client();
  bool get _ownsClient => widget.httpClient == null;

  final Map<String, TextEditingController> _controllers = {
    for (final k in kClaimFieldKeys) k: TextEditingController(),
  };

  /// Last accepted value per field (web `formData`).
  final Map<String, String> _formData = {
    for (final k in kClaimFieldKeys) k: '',
  };

  Map<String, dynamic>? _vendorData;
  bool _loading = false;
  bool _submitting = false;

  String? get _serviceId {
    final explicit = widget.vendorServiceId?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final s = widget.service;
    if (s is Map && s['id'] != null) {
      final id = s['id'].toString().trim();
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (_serviceId != null) _fetchVendorDetails();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    if (_ownsClient) _client.close();
    super.dispose();
  }

  Future<void> _fetchVendorDetails() async {
    setState(() => _loading = true);
    try {
      final res = await _client
          .get(Uri.parse('${ApiConfig.apiBase}/vendor-services/$_serviceId'));
      if (!mounted) return;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          _vendorData = data;
          _applyPrefill(claimPrefillFrom(data));
        } else {
          AppSnackbar.error(context, kClaimLoadFailedMessage);
        }
      } else {
        AppSnackbar.error(
          context,
          claimServerMessage(res.body, kClaimLoadFailedMessage),
        );
      }
    } catch (e) {
      debugPrint('[CLAIM] vendor details error: $e');
      if (mounted) AppSnackbar.error(context, kClaimLoadFailedMessage);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyPrefill(Map<String, String> prefill) {
    prefill.forEach((k, v) {
      _formData[k] = v;
      _controllers[k]!.text = v;
    });
  }

  void _onChanged(String field, String value) {
    final error = claimInputError(field, value);
    if (error == null) {
      _formData[field] = value;
      return;
    }
    // Reject the keystroke, like the web's controlled input does.
    final previous = _formData[field] ?? '';
    _controllers[field]!.value = TextEditingValue(
      text: previous,
      selection: TextSelection.collapsed(offset: previous.length),
    );
    AppSnackbar.error(context, error);
  }

  void _resetForm() {
    for (final k in kClaimFieldKeys) {
      _formData[k] = '';
      _controllers[k]!.clear();
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();

    final error = validateClaimForm(_formData);
    if (error != null) {
      AppSnackbar.error(context, error);
      return;
    }

    setState(() => _submitting = true);
    try {
      final vendorData = _vendorData;
      if (vendorData == null) {
        AppSnackbar.error(context, kClaimMissingVendorMessage);
        return;
      }

      final payload = buildClaimPayload(_formData, vendorData);
      http.Response res;
      try {
        res = await _client.post(
          Uri.parse('${ApiConfig.apiBase}/business/claims'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      } catch (e) {
        // claimFormApi.js turns any request failure into this message.
        debugPrint('[CLAIM] submit error: $e');
        if (mounted) AppSnackbar.error(context, kClaimSubmitFailedMessage);
        return;
      }
      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        AppSnackbar.success(context, kClaimSuccessMessage);
        _resetForm();
        Navigator.of(context).pop(true);
      } else {
        AppSnackbar.error(
          context,
          claimServerMessage(res.body, kClaimSubmitFailedMessage),
        );
      }
    } catch (e) {
      debugPrint('[CLAIM] unexpected error: $e');
      if (mounted) AppSnackbar.error(context, kClaimUnexpectedErrorMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  TextInputType _keyboardFor(String field) {
    switch (field) {
      case 'phoneNumber':
        return TextInputType.phone;
      case 'emailAddress':
        return TextInputType.emailAddress;
      case 'website':
        return TextInputType.url;
      case 'registrationNumber':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Business Claim Form'),
      body: SafeArea(
        child: _loading ? _buildLoading() : _buildForm(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          Text('Loading vendor details...', style: AppText.body),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final vendorData = _vendorData;
    final claimingName =
        vendorData == null ? '' : claimBusinessDisplayName(vendorData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Business Claim Form', style: AppText.pageTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please take a moment to fill out this form in complete detail.',
              style: AppText.bodySm,
            ),
            if (vendorData != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Claiming Business: ',
                        style: AppText.bodyStrong,
                      ),
                      TextSpan(text: claimingName, style: AppText.body),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Business Information', style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            for (final field in kClaimFieldKeys) ...[
              AppTextField(
                key: ValueKey('claim_$field'),
                controller: _controllers[field],
                hint: kClaimFieldPlaceholders[field],
                keyboardType: _keyboardFor(field),
                onChanged: (v) => _onChanged(field, v),
                enabled: !_submitting,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'By submitting this form you confirm that the information above '
              'is true and accurate to the best of your knowledge, and that '
              'you are authorised to claim this business.',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            PremiumButton(
              key: const ValueKey('claim_submit'),
              label: _submitting ? 'Submitting...' : 'Submit',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// LEGACY 5-STEP CLAIM FORM — replaced 2026-09-28 by the single-step web port
// above. The web no longer collects claimant details, social links,
// documents or a declaration, and posts JSON (not multipart). Kept commented
// out per project rule (never delete code).
// ===========================================================================
// // business_claim_form.dart
// // Full working Business Claim Form
// // - Rich UI (card-style sections and step progress)
// // - Multi-step validation (all required fields enforced)
// // - File picker for required documents (shows file name preview)
// // - Date picker for dateSigned
// // - Multipart API integration to the endpoint: https://happywedz.com/api/business/claims
// // - Loading indicator and success / error handling
//
// // business_claim_form.dart
// // Full working Business Claim Form (Option A - constructor-driven vendor IDs, signature as file upload)
//
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:file_selector/file_selector.dart';
// import 'package:flutter/material.dart';
//
// import 'core/config/api_config.dart';
// import 'core/core.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
//
//
// import 'package:mime/mime.dart';
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:path_provider/path_provider.dart';
//
// // PDF + Printing
// import 'package:pdf/widgets.dart' as pw;
//
// import 'Bottombars/HomeScreen.dart';
//
// class BusinessClaimForm extends StatefulWidget {
//   final String vendorId;
//   final String vendorSubcategoryId;
//   final dynamic service; // ⭐ ADD THIS
//
//   const BusinessClaimForm({
//     Key? key,
//     required this.vendorId,
//     required this.vendorSubcategoryId, this.service,
//   }) : super(key: key);
//
//   @override
//   State<BusinessClaimForm> createState() => _BusinessClaimFormState();
// }
//
// class _BusinessClaimFormState extends State<BusinessClaimForm> {
//   // Steps
//   int currentStep = 0;
//
//   // Loading / submission state
//   bool _submitting = false;
//
//   // Form keys for stepwise validation
//   final _formKeyStep1 = GlobalKey<FormState>();
//   final _formKeyStep2 = GlobalKey<FormState>();
//   final _formKeyStep3 = GlobalKey<FormState>();
//   final _formKeyStep4 = GlobalKey<FormState>();
//   final _formKeyStep5 = GlobalKey<FormState>();
//
//   // Text controllers (all fields used in API)
//   final businessName = TextEditingController();
//   final registeredAddress = TextEditingController();
//   final phoneNumber = TextEditingController();
//   final emailAddress = TextEditingController();
//   final website = TextEditingController();
//   final category = TextEditingController();
//   final registrationNumber = TextEditingController();
//
//   final claimantFullName = TextEditingController();
//   final claimantRole = TextEditingController();
//   final claimantMobile = TextEditingController();
//   final claimantEmail = TextEditingController();
//
//   final businessDescription = TextEditingController();
//   final facebookLink = TextEditingController();
//   final instagramLink = TextEditingController();
//   final linkedinLink = TextEditingController();
//   final contactMethod = TextEditingController();
//
//   // Date signed controller (ISO UTC string stored)
//   final dateSigned = TextEditingController();
//
//   // Files map: store picked File against a key (labels used in UI)
//   final Map<String, File> filePaths = {};
//
//   // Required file keys and labels (used for UI + API names)
//   // Note: signature is included as a required file upload (apiKey 'signatureFile')
//   final List<_DocSpec> requiredDocs = [
//     _DocSpec(label: "Aadhar Card", apiKey: "aadharCard"),
//     _DocSpec(label: "PAN Card", apiKey: "panCard"),
//     _DocSpec(label: "Shop Act / Trade License", apiKey: "shopLicense"),
//     _DocSpec(label: "Udyam Registration Certificate", apiKey: "udyamCertificate"),
//     _DocSpec(label: "GST Registration Certificate", apiKey: "gstCertificate"),
//     _DocSpec(label: "Proof of Business Address", apiKey: "addressProof"),
//     _DocSpec(label: "Recent Photograph of Business Premises", apiKey: "businessPhoto"),
//     _DocSpec(label: "Other Business Document (optional)", apiKey: "additionalDocuments", optional: true),
//   ];
//
//   Future<Uint8List> _generatePdf() async {
//     final pdf = pw.Document();
//
//     pdf.addPage(
//       pw.MultiPage(
//         build: (context) => [
//           pw.Header(
//             level: 0,
//             child: pw.Text(
//               "Business Claim Report",
//               style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
//             ),
//           ),
//
//           pw.SizedBox(height: 10),
//
//           pw.Text("Business Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.Divider(),
//           pw.Text("Business Name: ${businessName.text}"),
//           pw.Text("Address: ${registeredAddress.text}"),
//           pw.Text("Phone: ${phoneNumber.text}"),
//           pw.Text("Email: ${emailAddress.text}"),
//           pw.Text("Website: ${website.text}"),
//           pw.Text("Category: ${category.text}"),
//           pw.Text("Registration No: ${registrationNumber.text}"),
//
//           pw.SizedBox(height: 20),
//
//           pw.Text("Claimant Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.Divider(),
//           pw.Text("Full Name: ${claimantFullName.text}"),
//           pw.Text("Role: ${claimantRole.text}"),
//           pw.Text("Phone: ${claimantMobile.text}"),
//           pw.Text("Email: ${claimantEmail.text}"),
//
//           pw.SizedBox(height: 20),
//
//           pw.Text("Business Description", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.Divider(),
//           pw.Text(businessDescription.text),
//
//           pw.SizedBox(height: 20),
//
//           pw.Text("Uploaded Documents", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.Divider(),
//
//           ...requiredDocs.map((doc) {
//             final file = filePaths[doc.label];
//             return pw.Text("${doc.label}: ${file != null ? file.path.split('/').last : 'Not provided'}");
//           }).toList(),
//
//           pw.SizedBox(height: 20),
//
//           pw.Text("Declaration", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
//           pw.Divider(),
//           pw.Text("Date Signed: ${dateSigned.text}"),
//           pw.Text("Agreed: Yes"),
//         ],
//       ),
//     );
//
//     return pdf.save();
//   }
//
//   void _showSuccessPopup(Uint8List pdfBytes) async {
//     String? savedPath;
//
//     try {
//       savedPath = await savePdfSafely(pdfBytes);
//     } catch (e) {
//       debugPrint("PDF save error: $e");
//     }
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//           child: Padding(
//             padding: const EdgeInsets.all(22),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(Icons.check_circle, size: 90, color: Colors.green.shade600),
//                 SizedBox(height: 15),
//                 Text(
//                   "Claim Submitted Successfully!",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//
//                 SizedBox(height: 10),
//                 Text(
//                   "Your PDF has been saved in the Downloads folder.",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                 ),
//
//                 SizedBox(height: 20),
//
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     if (savedPath != null) {
//                       OpenFilex.open(savedPath);
//                     }
//                   },
//                   icon: Icon(Icons.picture_as_pdf),
//                   label: Text("Open PDF",style: TextStyle(color: Colors.white),),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.pink.shade400,
//                     minimumSize: Size(double.infinity, 48),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                 ),
//
//                 SizedBox(height: 12),
//
//                 ElevatedButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => WeddingHomePage()
//                       ),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green.shade600,
//                     minimumSize: Size(double.infinity, 48),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: Text("Go to Homepage",style: TextStyle(color: Colors.white),),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//   // Future<bool> _requestStoragePermission() async {
//   //   if (await Permission.manageExternalStorage.isGranted) return true;
//   //
//   //   final status = await Permission.manageExternalStorage.request();
//   //
//   //   return status.isGranted;
//   // }
//   Future<String> savePdfSafely(Uint8List pdfBytes) async {
//     final directory = await getApplicationDocumentsDirectory();
//
//     final filePath = "${directory.path}/BusinessClaim.pdf";
//     final file = File(filePath);
//
//     await file.writeAsBytes(pdfBytes);
//
//     return filePath;
//   }
//
//   // Endpoint constant
//   final String endpoint = "${ApiConfig.apiBase}/business/claims";
//
//   @override
//   void dispose() {
//     // Dispose controllers
//     businessName.dispose();
//     registeredAddress.dispose();
//     phoneNumber.dispose();
//     emailAddress.dispose();
//     website.dispose();
//     category.dispose();
//     registrationNumber.dispose();
//
//     claimantFullName.dispose();
//     claimantRole.dispose();
//     claimantMobile.dispose();
//     claimantEmail.dispose();
//
//     businessDescription.dispose();
//     facebookLink.dispose();
//     instagramLink.dispose();
//     linkedinLink.dispose();
//     contactMethod.dispose();
//
//     dateSigned.dispose();
//     super.dispose();
//   }
//
//   // ======= PICK FILE =======
// // ===== FILE PICKER =====
//   Future<void> pickFile(String label) async {
//     try {
//       File? file;
//
//       // First ask user what they want to pick
//       final choice = await showDialog<String>(
//         context: context,
//         builder: (_) => AlertDialog(
//           title: const Text("Select File"),
//           content: const Text("Choose file type"),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(context, "image"), child: const Text("Image")),
//             TextButton(onPressed: () => Navigator.pop(context, "pdf"), child: const Text("PDF")),
//           ],
//         ),
//       );
//
//       if (choice == null) return;
//
//       if (choice == "image") {
//         // Uses Android photo picker → NO PERMISSION NEEDED
//         final pickedImage = await ImagePicker().pickImage(
//           source: ImageSource.gallery,
//         );
//         if (pickedImage == null) return;
//         file = File(pickedImage.path);
//       } else {
//         // Pick PDF using file_selector → NO PERMISSION NEEDED
//         final XTypeGroup pdfType = XTypeGroup(
//           extensions: ['pdf'],
//         );
//
//         final selectedPdf = await openFile(acceptedTypeGroups: [pdfType]);
//
//         if (selectedPdf == null) return;
//
//         file = File(selectedPdf.path);
//       }
//
//       // Validate MIME
//       final mimeType = lookupMimeType(file!.path);
//       if (mimeType == null ||
//           !['image/jpeg', 'image/png', 'application/pdf'].contains(mimeType)) {
//         AppSnackbar.warning(context, 'Only JPG, PNG or PDF files are allowed.');
//         return;
//       }
//
//       setState(() {
//         filePaths[label] = file!;
//       });
//
//       AppSnackbar.success(context, '$label selected.');
//     } catch (e) {
//       AppSnackbar.error(context, "We couldn't open that file. Please try another one.");
//     }
//   }  // ======= DATE PICKER =======
//   Future<void> _pickDateSigned() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null) {
//       // store ISO UTC format expected by backend (e.g. 2025-11-15T10:30:00.000Z)
//       dateSigned.text = DateFormat("yyyy-MM-dd'T'HH:mm:ss.000'Z'").format(picked.toUtc());
//       setState(() {});
//     }
//   }
//
//   // ======= VALIDATION HELPERS =======
//   bool _validateCurrentStep() {
//     switch (currentStep) {
//       case 0:
//         return _formKeyStep1.currentState?.validate() ?? false;
//       case 1:
//         return _formKeyStep2.currentState?.validate() ?? false;
//       case 2:
//         return _formKeyStep3.currentState?.validate() ?? false;
//       case 3:
//       // ensure required docs selected
//         for (final doc in requiredDocs) {
//           if (doc.optional) continue;
//           if (filePaths[doc.label] == null) {
//             AppSnackbar.warning(context, 'Please upload: ${doc.label}');
//             return false;
//           }
//         }
//         return _formKeyStep4.currentState?.validate() ?? true;
//       case 4:
//         return _formKeyStep5.currentState?.validate() ?? false;
//       default:
//         return false;
//     }
//   }
//
//   void _nextStep() {
//     if (!_validateCurrentStep()) return;
//     if (currentStep < 4) {
//       setState(() => currentStep++);
//       return;
//     }
//     // final step -> submit
//     _submitAll();
//   }
//
//   void _prevStep() {
//     if (currentStep > 0) setState(() => currentStep--);
//   }
//
//   // ======= BUILD UI =======
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FB),
//       appBar: AppBar(
//         elevation: 0,
//         toolbarHeight: 84,
//         backgroundColor: Colors.transparent,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFFEC5E5), Color(0xFFFFE4E1)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
//           ),
//         ),
//         title: const Text(
//           "Business Claim Form",
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
//           child: Column(
//             children: [
//               _buildStepIndicator(),
//               const SizedBox(height: 12),
//               Expanded(child: _buildStepContent()),
//             ],
//           ),
//         ),
//       ),
//       bottomSheet: Container(
//         color: Colors.transparent,
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         child: Row(
//           children: [
//             if (currentStep > 0)
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: _submitting ? null : _prevStep,
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text("Back"),
//                 ),
//               ),
//             if (currentStep > 0) const SizedBox(width: 12),
//             Expanded(
//               flex: 2,
//               child: ElevatedButton(
//                 onPressed: _submitting ? null : _nextStep,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   backgroundColor: currentStep == 4 ? Colors.green.shade600 : Colors.pink.shade400,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: _submitting
//                     ? Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: const [
//                     SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
//                     SizedBox(width: 12),
//                     Text("Submitting...")
//                   ],
//                 )
//                     : Text(currentStep == 4 ? "Submit Claim" : "Next", style: const TextStyle(fontSize: 16,color: Colors.white)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Step indicator UI
//   Widget _buildStepIndicator() {
//     final titles = ["Business Info", "Claimant", "Additional", "Documents", "Declaration"];
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: List.generate(titles.length, (i) {
//         bool done = i < currentStep;
//         bool active = i == currentStep;
//         return Expanded(
//           child: Column(
//             children: [
//               CircleAvatar(
//                 radius: active ? 18 : 14,
//                 backgroundColor: done || active ? Colors.pink.shade400 : Colors.grey.shade300,
//                 child: done
//                     ? const Icon(Icons.check, color: Colors.white, size: 16)
//                     : Text("${i + 1}", style: const TextStyle(color: Colors.white)),
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 titles[i],
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 11, color: active ? Colors.black87 : Colors.grey.shade600),
//               ),
//             ],
//           ),
//         );
//       }),
//     );
//   }
//
//   // Content switcher
//   Widget _buildStepContent() {
//     switch (currentStep) {
//       case 0:
//         return _stepBusinessInfo();
//       case 1:
//         return _stepClaimantInfo();
//       case 2:
//         return _stepAdditionalInfo();
//       case 3:
//         return _stepDocuments();
//       case 4:
//         return _stepDeclaration();
//       default:
//         return _stepBusinessInfo();
//     }
//   }
//
//   // ---------- Step 1: Business Info ----------
//   Widget _stepBusinessInfo() {
//     return _card(
//       child: Form(
//         key: _formKeyStep1,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Policyholder Information"),
//             const SizedBox(height: 8),
//             _labelWithRequired("Business Name"),
//             _textField(controller: businessName, hint: "e.g. N Mehndi", validator: _requiredValidator),
//             const SizedBox(height: 10),
//             _labelWithRequired("Registered Business Address"),
//             _textField(controller: registeredAddress, hint: "Full address", validator: _requiredValidator, maxLines: 2),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(child: _labelWithRequired("Business Phone")),
//                 const SizedBox(width: 12),
//                 Expanded(child: _labelWithRequired("Business Email")),
//               ],
//             ),
//             Row(
//               children: [
//                 Expanded(child: _textField(controller: phoneNumber, hint: "10-digit mobile", keyboard: TextInputType.phone, validator: _phoneValidator)),
//                 const SizedBox(width: 12),
//                 Expanded(child: _textField(controller: emailAddress, hint: "email@example.com", keyboard: TextInputType.emailAddress, validator: _emailValidator)),
//               ],
//             ),
//             const SizedBox(height: 10),
//             _labelWithRequired("Business Website"),
//             _textField(controller: website, hint: "https://example.com", validator: _requiredValidator),
//             const SizedBox(height: 10),
//             _labelWithRequired("Business Category / Type"),
//             _textField(controller: category, hint: "e.g. Mehndi venue", validator: _requiredValidator),
//             const SizedBox(height: 10),
//             _labelWithRequired("Business Registration Number"),
//             _textField(controller: registrationNumber, hint: "Registration number", validator: _requiredValidator),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------- Step 2: Claimant Info ----------
//   Widget _stepClaimantInfo() {
//     return _card(
//       child: Form(
//         key: _formKeyStep2,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Owner / Claimant Information"),
//             const SizedBox(height: 8),
//             _labelWithRequired("Claimant Full Name"),
//             _textField(controller: claimantFullName, hint: "Full name", validator: _requiredValidator),
//             const SizedBox(height: 10),
//             _labelWithRequired("Claimant Role / Designation"),
//             _textField(controller: claimantRole, hint: "Owner / Manager", validator: _requiredValidator),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Expanded(child: _labelWithRequired("Claimant Mobile")),
//                 const SizedBox(width: 12),
//                 Expanded(child: _labelWithRequired("Claimant Email")),
//               ],
//             ),
//             Row(
//               children: [
//                 Expanded(child: _textField(controller: claimantMobile, hint: "10-digit mobile", keyboard: TextInputType.phone, validator: _phoneValidator)),
//                 const SizedBox(width: 12),
//                 Expanded(child: _textField(controller: claimantEmail, hint: "email@example.com", keyboard: TextInputType.emailAddress, validator: _emailValidator)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------- Step 3: Additional Info ----------
//   Widget _stepAdditionalInfo() {
//     return _card(
//       child: Form(
//         key: _formKeyStep3,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Additional Information"),
//             const SizedBox(height: 8),
//             _labelWithRequired("Business Description"),
//             _textField(controller: businessDescription, hint: "Describe business (facilities, capacity, etc.)", validator: _requiredValidator, maxLines: 4),
//             const SizedBox(height: 10),
//             _label("Facebook Link (optional)"),
//             _textField(controller: facebookLink, hint: "https://facebook.com/yourpage"),
//             const SizedBox(height: 10),
//             _label("Instagram Link (optional)"),
//             _textField(controller: instagramLink, hint: "https://instagram.com/yourpage"),
//             const SizedBox(height: 10),
//             _label("LinkedIn Link (optional)"),
//             _textField(controller: linkedinLink, hint: "https://linkedin.com/your-profile"),
//             const SizedBox(height: 10),
//             _labelWithRequired("Preferred Contact Method"),
//             _textField(controller: contactMethod, hint: "email / phone", validator: _requiredValidator),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------- Step 4: Upload Documents ----------
//   Widget _stepDocuments() {
//     return _card(
//       child: Form(
//         key: _formKeyStep4,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Proof of Ownership Documents"),
//             const SizedBox(height: 8),
//             ...requiredDocs.map((doc) {
//               final bool isOptional = doc.optional;
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _labelWithRequired(doc.label, optional: isOptional),
//                   const SizedBox(height: 6),
//                   Row(
//                     children: [
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           onPressed: () => pickFile(doc.label),
//                           icon: const Icon(Icons.upload_file),
//                           label: Text(filePaths[doc.label] != null ? "Change file" : "Upload File"),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.pink.shade400,
//                             padding: const EdgeInsets.symmetric(vertical: 12),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Text(
//                           filePaths[doc.label] != null ? _shortFileName(filePaths[doc.label]!) : (isOptional ? "Optional" : "Required"),
//                           style: TextStyle(
//                             fontSize: 13,
//                             color: filePaths[doc.label] != null ? Colors.green.shade700 : Colors.grey.shade600,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                 ],
//               );
//             }).toList(),
//             const SizedBox(height: 6),
//             Text(
//               "Accepted: JPG, PNG, PDF, DOC, DOCX (max ~10 MB each)",
//               style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ---------- Step 5: Declaration ----------
//   Widget _stepDeclaration() {
//     return _card(
//       child: Form(
//         key: _formKeyStep5,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _sectionTitle("Declaration / Authorization"),
//             const SizedBox(height: 8),
//             const Text(
//               "I hereby declare that the information provided is true.",
//               style: TextStyle(fontSize: 14),
//             ),
//             const SizedBox(height: 18),
//
//             /// DATE SIGNED
//             _labelWithRequired("Date Signed"),
//             const SizedBox(height: 6),
//             OutlinedButton(
//               onPressed: _pickDateSigned,
//               child: Text(
//                 dateSigned.text.isEmpty
//                     ? "Select Date"
//                     : DateFormat('dd-MM-yyyy')
//                     .format(DateTime.parse(dateSigned.text)),
//               ),
//             ),
//             if (dateSigned.text.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.only(top: 6),
//                 child: Text("Date is required",
//                     style: TextStyle(color: Colors.red)),
//               ),
//
//             const SizedBox(height: 18),
//             const Text(
//               "Signature will be automatically included in additional documents upload.",
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//
//   // ======= SMALL UI HELPERS =======
//   Widget _card({required Widget child}) {
//     return SingleChildScrollView(
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [BoxShadow(color: Colors.pink.shade50.withValues(alpha: 0.6), blurRadius: 10, offset: const Offset(0, 6))],
//         ),
//         child: child,
//       ),
//     );
//   }
//
//   Widget _sectionTitle(String title) => Padding(
//     padding: const EdgeInsets.only(bottom: 6),
//     child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
//   );
//
//   Widget _label(String text) => Padding(
//     padding: const EdgeInsets.only(bottom: 6),
//     child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
//   );
//
//   Widget _labelWithRequired(String text, {bool optional = false}) => Padding(
//     padding: const EdgeInsets.only(bottom: 6),
//     child: Row(
//       children: [
//         Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
//         const SizedBox(width: 6),
//         Text(optional ? "(optional)" : "*", style: TextStyle(color: optional ? Colors.grey : Colors.red)),
//       ],
//     ),
//   );
//
//   Widget _textField({
//     required TextEditingController controller,
//     String? hint,
//     String? Function(String?)? validator,
//     TextInputType keyboard = TextInputType.text,
//     int maxLines = 1,
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         child: TextFormField(
//           controller: controller,
//           validator: validator,
//           keyboardType: keyboard,
//           maxLines: maxLines,
//           decoration: InputDecoration(
//             hintText: hint,
//             border: InputBorder.none,
//             contentPadding: const EdgeInsets.symmetric(vertical: 14),
//           ),
//         ),
//       ),
//     );
//   }
//
//   String _shortFileName(File f) {
//     final name = f.path.split('/').last;
//     if (name.length > 30) return "${name.substring(0, 28)}...";
//     return name;
//   }
//
//   // ======= VALIDATORS =======
//   String? _requiredValidator(String? v) {
//     if (v == null || v.trim().isEmpty) return "This field is required";
//     return null;
//   }
//
//   String? _emailValidator(String? v) {
//     if (v == null || v.trim().isEmpty) return "Email is required";
//     final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//     if (!emailRegex.hasMatch(v.trim())) return "Enter a valid email";
//     return null;
//   }
//
//   String? _phoneValidator(String? v) {
//     if (v == null || v.trim().isEmpty) return "Phone is required";
//     final digits = v.replaceAll(RegExp(r'\D'), '');
//     if (digits.length != 10) return "Enter a valid 10-digit phone number";
//     return null;
//   }
//
//   // ======= SUBMIT (API) =======
// // ======= SUBMIT (API) =======
//   Future<void> _submitAll() async {
//     if (!_validateCurrentStep()) return;
//
//     debugPrint("====== BUSINESS CLAIM API START ======");
//     setState(() => _submitting = true);
//
//     try {
//       final uri = Uri.parse(endpoint);
//       final request = http.MultipartRequest("POST", uri);
//
//       // ----- TEXT FIELDS -----
//       request.fields.addAll({
//         "businessName": businessName.text.trim(),
//         "registeredAddress": registeredAddress.text.trim(),
//         "phoneNumber": phoneNumber.text.trim(),
//         "emailAddress": emailAddress.text.trim(),
//         "website": website.text.trim(),
//         "category": category.text.trim(),
//         "registrationNumber": registrationNumber.text.trim(),
//
//         "claimantFullName": claimantFullName.text.trim(),
//         "claimantRole": claimantRole.text.trim(),
//         "claimantMobile": claimantMobile.text.trim(),
//         "claimantEmail": claimantEmail.text.trim(),
//
//         "businessDescription": businessDescription.text.trim(),
//         "facebookLink": facebookLink.text.trim(),
//         "instagramLink": instagramLink.text.trim(),
//         "linkedinLink": linkedinLink.text.trim(),
//         "contactMethod": contactMethod.text.trim(),
//
//         "agreed": "true",
//         "dateSigned": dateSigned.text.trim(),
//
//         "vendor_id": widget.vendorId,
//         "vendor_subcategory_data_id": widget.vendorSubcategoryId,
//       });
//
//       // ----- FILES -----
//       for (var doc in requiredDocs) {
//         final file = filePaths[doc.label];
//         if (file != null && await file.exists()) {
//           final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
//           final parts = mimeType.split('/');
//
//           request.files.add(await http.MultipartFile.fromPath(
//             doc.apiKey,
//             file.path,
//             contentType: MediaType(parts[0], parts[1]),
//           ));
//         }
//       }
//
//       debugPrint("Sending request...");
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//
//       debugPrint("STATUS: ${response.statusCode}");
//       debugPrint("BODY: $responseBody");
//
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final pdfBytes = await _generatePdf();
//         _showSuccessPopup(pdfBytes);
//
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   const SnackBar(
//         //     content: Text("Claim submitted successfully"),
//         //     backgroundColor: Colors.green,
//         //   ),
//         // );
//       } else {
//         debugPrint("Server error ${response.statusCode}: $responseBody");
//         if (mounted) {
//           await ErrorPopup.show(
//             context,
//             title: AppErrorMessage.serverTitle,
//             message: AppErrorMessage.serverBody,
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("ERROR: $e");
//       if (mounted) {
//         await ErrorPopup.show(
//           context,
//           title: AppErrorMessage.titleFor(e),
//           message: AppErrorMessage.bodyFor(e),
//         );
//       }
//     } finally {
//       setState(() => _submitting = false);
//       debugPrint("====== END BUSINESS CLAIM API ======");
//     }
//   }
// }
//
// // Small helper class to describe document requirements
// class _DocSpec {
//   final String label;
//   final String apiKey;
//   final bool optional;
//   const _DocSpec({required this.label, required this.apiKey, this.optional = false});
// }
