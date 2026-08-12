// business_claim_form.dart
// Full working Business Claim Form
// - Rich UI (card-style sections and step progress)
// - Multi-step validation (all required fields enforced)
// - File picker for required documents (shows file name preview)
// - Date picker for dateSigned
// - Multipart API integration to the endpoint: https://happywedz.com/api/business/claims
// - Loading indicator and success / error handling

// business_claim_form.dart
// Full working Business Claim Form (Option A - constructor-driven vendor IDs, signature as file upload)

import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import 'core/core.dart';
import 'package:happy_wedz/vendor/vendordetailsscreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';


import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// PDF + Printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'Bottombars/HomeScreen.dart';

class BusinessClaimForm extends StatefulWidget {
  final String vendorId;
  final String vendorSubcategoryId;
  final dynamic service; // ⭐ ADD THIS

  const BusinessClaimForm({
    Key? key,
    required this.vendorId,
    required this.vendorSubcategoryId, this.service,
  }) : super(key: key);

  @override
  State<BusinessClaimForm> createState() => _BusinessClaimFormState();
}

class _BusinessClaimFormState extends State<BusinessClaimForm> {
  // Steps
  int currentStep = 0;

  // Loading / submission state
  bool _submitting = false;

  // Form keys for stepwise validation
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  final _formKeyStep4 = GlobalKey<FormState>();
  final _formKeyStep5 = GlobalKey<FormState>();

  // Text controllers (all fields used in API)
  final businessName = TextEditingController();
  final registeredAddress = TextEditingController();
  final phoneNumber = TextEditingController();
  final emailAddress = TextEditingController();
  final website = TextEditingController();
  final category = TextEditingController();
  final registrationNumber = TextEditingController();

  final claimantFullName = TextEditingController();
  final claimantRole = TextEditingController();
  final claimantMobile = TextEditingController();
  final claimantEmail = TextEditingController();

  final businessDescription = TextEditingController();
  final facebookLink = TextEditingController();
  final instagramLink = TextEditingController();
  final linkedinLink = TextEditingController();
  final contactMethod = TextEditingController();

  // Date signed controller (ISO UTC string stored)
  final dateSigned = TextEditingController();

  // Files map: store picked File against a key (labels used in UI)
  final Map<String, File> filePaths = {};

  // Required file keys and labels (used for UI + API names)
  // Note: signature is included as a required file upload (apiKey 'signatureFile')
  final List<_DocSpec> requiredDocs = [
    _DocSpec(label: "Aadhar Card", apiKey: "aadharCard"),
    _DocSpec(label: "PAN Card", apiKey: "panCard"),
    _DocSpec(label: "Shop Act / Trade License", apiKey: "shopLicense"),
    _DocSpec(label: "Udyam Registration Certificate", apiKey: "udyamCertificate"),
    _DocSpec(label: "GST Registration Certificate", apiKey: "gstCertificate"),
    _DocSpec(label: "Proof of Business Address", apiKey: "addressProof"),
    _DocSpec(label: "Recent Photograph of Business Premises", apiKey: "businessPhoto"),
    _DocSpec(label: "Other Business Document (optional)", apiKey: "additionalDocuments", optional: true),
  ];

  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "Business Claim Report",
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text("Business Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text("Business Name: ${businessName.text}"),
          pw.Text("Address: ${registeredAddress.text}"),
          pw.Text("Phone: ${phoneNumber.text}"),
          pw.Text("Email: ${emailAddress.text}"),
          pw.Text("Website: ${website.text}"),
          pw.Text("Category: ${category.text}"),
          pw.Text("Registration No: ${registrationNumber.text}"),

          pw.SizedBox(height: 20),

          pw.Text("Claimant Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text("Full Name: ${claimantFullName.text}"),
          pw.Text("Role: ${claimantRole.text}"),
          pw.Text("Phone: ${claimantMobile.text}"),
          pw.Text("Email: ${claimantEmail.text}"),

          pw.SizedBox(height: 20),

          pw.Text("Business Description", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text(businessDescription.text),

          pw.SizedBox(height: 20),

          pw.Text("Uploaded Documents", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),

          ...requiredDocs.map((doc) {
            final file = filePaths[doc.label];
            return pw.Text("${doc.label}: ${file != null ? file.path.split('/').last : 'Not provided'}");
          }).toList(),

          pw.SizedBox(height: 20),

          pw.Text("Declaration", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Divider(),
          pw.Text("Date Signed: ${dateSigned.text}"),
          pw.Text("Agreed: Yes"),
        ],
      ),
    );

    return pdf.save();
  }

  void _showSuccessPopup(Uint8List pdfBytes) async {
    String? savedPath;

    try {
      savedPath = await savePdfSafely(pdfBytes);
    } catch (e) {
      print("PDF save error: $e");
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 90, color: Colors.green.shade600),
                SizedBox(height: 15),
                Text(
                  "Claim Submitted Successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 10),
                Text(
                  "Your PDF has been saved in the Downloads folder.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),

                SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    if (savedPath != null) {
                      OpenFilex.open(savedPath);
                    }
                  },
                  icon: Icon(Icons.picture_as_pdf),
                  label: Text("Open PDF",style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WeddingHomePage()
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Go to Homepage",style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // Future<bool> _requestStoragePermission() async {
  //   if (await Permission.manageExternalStorage.isGranted) return true;
  //
  //   final status = await Permission.manageExternalStorage.request();
  //
  //   return status.isGranted;
  // }
  Future<String> savePdfSafely(Uint8List pdfBytes) async {
    final directory = await getApplicationDocumentsDirectory();

    final filePath = "${directory.path}/BusinessClaim.pdf";
    final file = File(filePath);

    await file.writeAsBytes(pdfBytes);

    return filePath;
  }

  // Endpoint constant
  final String endpoint = "https://happywedz.com/api/business/claims";

  @override
  void dispose() {
    // Dispose controllers
    businessName.dispose();
    registeredAddress.dispose();
    phoneNumber.dispose();
    emailAddress.dispose();
    website.dispose();
    category.dispose();
    registrationNumber.dispose();

    claimantFullName.dispose();
    claimantRole.dispose();
    claimantMobile.dispose();
    claimantEmail.dispose();

    businessDescription.dispose();
    facebookLink.dispose();
    instagramLink.dispose();
    linkedinLink.dispose();
    contactMethod.dispose();

    dateSigned.dispose();
    super.dispose();
  }

  // ======= PICK FILE =======
// ===== FILE PICKER =====
  Future<void> pickFile(String label) async {
    try {
      File? file;

      // First ask user what they want to pick
      final choice = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Select File"),
          content: const Text("Choose file type"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, "image"), child: const Text("Image")),
            TextButton(onPressed: () => Navigator.pop(context, "pdf"), child: const Text("PDF")),
          ],
        ),
      );

      if (choice == null) return;

      if (choice == "image") {
        // Uses Android photo picker → NO PERMISSION NEEDED
        final pickedImage = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (pickedImage == null) return;
        file = File(pickedImage.path);
      } else {
        // Pick PDF using file_selector → NO PERMISSION NEEDED
        final XTypeGroup pdfType = XTypeGroup(
          extensions: ['pdf'],
        );

        final selectedPdf = await openFile(acceptedTypeGroups: [pdfType]);

        if (selectedPdf == null) return;

        file = File(selectedPdf.path);
      }

      // Validate MIME
      final mimeType = lookupMimeType(file!.path);
      if (mimeType == null ||
          !['image/jpeg', 'image/png', 'application/pdf'].contains(mimeType)) {
        AppSnackbar.warning(context, 'Only JPG, PNG or PDF files are allowed.');
        return;
      }

      setState(() {
        filePaths[label] = file!;
      });

      AppSnackbar.success(context, '$label selected.');
    } catch (e) {
      AppSnackbar.error(context, "We couldn't open that file. Please try another one.");
    }
  }  // ======= DATE PICKER =======
  Future<void> _pickDateSigned() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      // store ISO UTC format expected by backend (e.g. 2025-11-15T10:30:00.000Z)
      dateSigned.text = DateFormat("yyyy-MM-dd'T'HH:mm:ss.000'Z'").format(picked.toUtc());
      setState(() {});
    }
  }

  // ======= VALIDATION HELPERS =======
  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _formKeyStep1.currentState?.validate() ?? false;
      case 1:
        return _formKeyStep2.currentState?.validate() ?? false;
      case 2:
        return _formKeyStep3.currentState?.validate() ?? false;
      case 3:
      // ensure required docs selected
        for (final doc in requiredDocs) {
          if (doc.optional) continue;
          if (filePaths[doc.label] == null) {
            AppSnackbar.warning(context, 'Please upload: ${doc.label}');
            return false;
          }
        }
        return _formKeyStep4.currentState?.validate() ?? true;
      case 4:
        return _formKeyStep5.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    if (currentStep < 4) {
      setState(() => currentStep++);
      return;
    }
    // final step -> submit
    _submitAll();
  }

  void _prevStep() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  // ======= BUILD UI =======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 84,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFEC5E5), Color(0xFFFFE4E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
          ),
        ),
        title: const Text(
          "Business Claim Form",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          child: Column(
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 12),
              Expanded(child: _buildStepContent()),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Back"),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _submitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: currentStep == 4 ? Colors.green.shade600 : Colors.pink.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text("Submitting...")
                  ],
                )
                    : Text(currentStep == 4 ? "Submit Claim" : "Next", style: const TextStyle(fontSize: 16,color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step indicator UI
  Widget _buildStepIndicator() {
    final titles = ["Business Info", "Claimant", "Additional", "Documents", "Declaration"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(titles.length, (i) {
        bool done = i < currentStep;
        bool active = i == currentStep;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: active ? 18 : 14,
                backgroundColor: done || active ? Colors.pink.shade400 : Colors.grey.shade300,
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text("${i + 1}", style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(
                titles[i],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: active ? Colors.black87 : Colors.grey.shade600),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Content switcher
  Widget _buildStepContent() {
    switch (currentStep) {
      case 0:
        return _stepBusinessInfo();
      case 1:
        return _stepClaimantInfo();
      case 2:
        return _stepAdditionalInfo();
      case 3:
        return _stepDocuments();
      case 4:
        return _stepDeclaration();
      default:
        return _stepBusinessInfo();
    }
  }

  // ---------- Step 1: Business Info ----------
  Widget _stepBusinessInfo() {
    return _card(
      child: Form(
        key: _formKeyStep1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Policyholder Information"),
            const SizedBox(height: 8),
            _labelWithRequired("Business Name"),
            _textField(controller: businessName, hint: "e.g. N Mehndi", validator: _requiredValidator),
            const SizedBox(height: 10),
            _labelWithRequired("Registered Business Address"),
            _textField(controller: registeredAddress, hint: "Full address", validator: _requiredValidator, maxLines: 2),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _labelWithRequired("Business Phone")),
                const SizedBox(width: 12),
                Expanded(child: _labelWithRequired("Business Email")),
              ],
            ),
            Row(
              children: [
                Expanded(child: _textField(controller: phoneNumber, hint: "10-digit mobile", keyboard: TextInputType.phone, validator: _phoneValidator)),
                const SizedBox(width: 12),
                Expanded(child: _textField(controller: emailAddress, hint: "email@example.com", keyboard: TextInputType.emailAddress, validator: _emailValidator)),
              ],
            ),
            const SizedBox(height: 10),
            _labelWithRequired("Business Website"),
            _textField(controller: website, hint: "https://example.com", validator: _requiredValidator),
            const SizedBox(height: 10),
            _labelWithRequired("Business Category / Type"),
            _textField(controller: category, hint: "e.g. Mehndi venue", validator: _requiredValidator),
            const SizedBox(height: 10),
            _labelWithRequired("Business Registration Number"),
            _textField(controller: registrationNumber, hint: "Registration number", validator: _requiredValidator),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------- Step 2: Claimant Info ----------
  Widget _stepClaimantInfo() {
    return _card(
      child: Form(
        key: _formKeyStep2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Owner / Claimant Information"),
            const SizedBox(height: 8),
            _labelWithRequired("Claimant Full Name"),
            _textField(controller: claimantFullName, hint: "Full name", validator: _requiredValidator),
            const SizedBox(height: 10),
            _labelWithRequired("Claimant Role / Designation"),
            _textField(controller: claimantRole, hint: "Owner / Manager", validator: _requiredValidator),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _labelWithRequired("Claimant Mobile")),
                const SizedBox(width: 12),
                Expanded(child: _labelWithRequired("Claimant Email")),
              ],
            ),
            Row(
              children: [
                Expanded(child: _textField(controller: claimantMobile, hint: "10-digit mobile", keyboard: TextInputType.phone, validator: _phoneValidator)),
                const SizedBox(width: 12),
                Expanded(child: _textField(controller: claimantEmail, hint: "email@example.com", keyboard: TextInputType.emailAddress, validator: _emailValidator)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Step 3: Additional Info ----------
  Widget _stepAdditionalInfo() {
    return _card(
      child: Form(
        key: _formKeyStep3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Additional Information"),
            const SizedBox(height: 8),
            _labelWithRequired("Business Description"),
            _textField(controller: businessDescription, hint: "Describe business (facilities, capacity, etc.)", validator: _requiredValidator, maxLines: 4),
            const SizedBox(height: 10),
            _label("Facebook Link (optional)"),
            _textField(controller: facebookLink, hint: "https://facebook.com/yourpage"),
            const SizedBox(height: 10),
            _label("Instagram Link (optional)"),
            _textField(controller: instagramLink, hint: "https://instagram.com/yourpage"),
            const SizedBox(height: 10),
            _label("LinkedIn Link (optional)"),
            _textField(controller: linkedinLink, hint: "https://linkedin.com/your-profile"),
            const SizedBox(height: 10),
            _labelWithRequired("Preferred Contact Method"),
            _textField(controller: contactMethod, hint: "email / phone", validator: _requiredValidator),
          ],
        ),
      ),
    );
  }

  // ---------- Step 4: Upload Documents ----------
  Widget _stepDocuments() {
    return _card(
      child: Form(
        key: _formKeyStep4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Proof of Ownership Documents"),
            const SizedBox(height: 8),
            ...requiredDocs.map((doc) {
              final bool isOptional = doc.optional;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelWithRequired(doc.label, optional: isOptional),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => pickFile(doc.label),
                          icon: const Icon(Icons.upload_file),
                          label: Text(filePaths[doc.label] != null ? "Change file" : "Upload File"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          filePaths[doc.label] != null ? _shortFileName(filePaths[doc.label]!) : (isOptional ? "Optional" : "Required"),
                          style: TextStyle(
                            fontSize: 13,
                            color: filePaths[doc.label] != null ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
            const SizedBox(height: 6),
            Text(
              "Accepted: JPG, PNG, PDF, DOC, DOCX (max ~10 MB each)",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Step 5: Declaration ----------
  Widget _stepDeclaration() {
    return _card(
      child: Form(
        key: _formKeyStep5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Declaration / Authorization"),
            const SizedBox(height: 8),
            const Text(
              "I hereby declare that the information provided is true.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 18),

            /// DATE SIGNED
            _labelWithRequired("Date Signed"),
            const SizedBox(height: 6),
            OutlinedButton(
              onPressed: _pickDateSigned,
              child: Text(
                dateSigned.text.isEmpty
                    ? "Select Date"
                    : DateFormat('dd-MM-yyyy')
                    .format(DateTime.parse(dateSigned.text)),
              ),
            ),
            if (dateSigned.text.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text("Date is required",
                    style: TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 18),
            const Text(
              "Signature will be automatically included in additional documents upload.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }



  // ======= SMALL UI HELPERS =======
  Widget _card({required Widget child}) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.pink.shade50.withOpacity(0.6), blurRadius: 10, offset: const Offset(0, 6))],
        ),
        child: child,
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
  );

  Widget _labelWithRequired(String text, {bool optional = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(width: 6),
        Text(optional ? "(optional)" : "*", style: TextStyle(color: optional ? Colors.grey : Colors.red)),
      ],
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  String _shortFileName(File f) {
    final name = f.path.split('/').last;
    if (name.length > 30) return "${name.substring(0, 28)}...";
    return name;
  }

  // ======= VALIDATORS =======
  String? _requiredValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "This field is required";
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Email is required";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(v.trim())) return "Enter a valid email";
    return null;
  }

  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return "Phone is required";
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return "Enter a valid 10-digit phone number";
    return null;
  }

  // ======= SUBMIT (API) =======
// ======= SUBMIT (API) =======
  Future<void> _submitAll() async {
    if (!_validateCurrentStep()) return;

    print("====== BUSINESS CLAIM API START ======");
    setState(() => _submitting = true);

    try {
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest("POST", uri);

      // ----- TEXT FIELDS -----
      request.fields.addAll({
        "businessName": businessName.text.trim(),
        "registeredAddress": registeredAddress.text.trim(),
        "phoneNumber": phoneNumber.text.trim(),
        "emailAddress": emailAddress.text.trim(),
        "website": website.text.trim(),
        "category": category.text.trim(),
        "registrationNumber": registrationNumber.text.trim(),

        "claimantFullName": claimantFullName.text.trim(),
        "claimantRole": claimantRole.text.trim(),
        "claimantMobile": claimantMobile.text.trim(),
        "claimantEmail": claimantEmail.text.trim(),

        "businessDescription": businessDescription.text.trim(),
        "facebookLink": facebookLink.text.trim(),
        "instagramLink": instagramLink.text.trim(),
        "linkedinLink": linkedinLink.text.trim(),
        "contactMethod": contactMethod.text.trim(),

        "agreed": "true",
        "dateSigned": dateSigned.text.trim(),

        "vendor_id": widget.vendorId,
        "vendor_subcategory_data_id": widget.vendorSubcategoryId,
      });

      // ----- FILES -----
      for (var doc in requiredDocs) {
        final file = filePaths[doc.label];
        if (file != null && await file.exists()) {
          final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
          final parts = mimeType.split('/');

          request.files.add(await http.MultipartFile.fromPath(
            doc.apiKey,
            file.path,
            contentType: MediaType(parts[0], parts[1]),
          ));
        }
      }

      print("Sending request...");
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print("STATUS: ${response.statusCode}");
      print("BODY: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final pdfBytes = await _generatePdf();
        _showSuccessPopup(pdfBytes);

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text("Claim submitted successfully"),
        //     backgroundColor: Colors.green,
        //   ),
        // );
      } else {
        debugPrint("Server error ${response.statusCode}: $responseBody");
        if (mounted) {
          await ErrorPopup.show(
            context,
            title: AppErrorMessage.serverTitle,
            message: AppErrorMessage.serverBody,
          );
        }
      }
    } catch (e) {
      print("ERROR: $e");
      if (mounted) {
        await ErrorPopup.show(
          context,
          title: AppErrorMessage.titleFor(e),
          message: AppErrorMessage.bodyFor(e),
        );
      }
    } finally {
      setState(() => _submitting = false);
      print("====== END BUSINESS CLAIM API ======");
    }
  }
}

// Small helper class to describe document requirements
class _DocSpec {
  final String label;
  final String apiKey;
  final bool optional;
  const _DocSpec({required this.label, required this.apiKey, this.optional = false});
}
