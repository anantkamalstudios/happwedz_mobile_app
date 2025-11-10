import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class BusinessClaimForm extends StatefulWidget {
  const BusinessClaimForm({Key? key}) : super(key: key);

  @override
  State<BusinessClaimForm> createState() => _BusinessClaimFormState();
}

class _BusinessClaimFormState extends State<BusinessClaimForm>
    with SingleTickerProviderStateMixin {
  int currentPage = 1;
  Map<String, String> selectedFiles = {};
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // -------------------- BUILD --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: _buildAppBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.05, 0.05), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: _getPage(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _bottomButtons(),
    );
  }

  // -------------------- PAGE NAV --------------------
  Widget _getPage() {
    switch (currentPage) {
      case 1:
        return _pageContainer(_page1());
      case 2:
        return _pageContainer(_page2());
      case 3:
        return _pageContainer(_page4());
      case 4:
        return _pageContainer(_page3());
      case 5:
        return _pageContainer(_page5());
      default:
        return _pageContainer(_page1());
    }
  }

  // -------------------- APPBAR --------------------
  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      toolbarHeight: 80,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFEC5E5), Color(0xFFFFE4E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
          BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
      ),
      title: const Text(
        "Business Claim Form",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
    );
  }

  // -------------------- PAGE CONTAINER --------------------
  Widget _pageContainer(Widget child) {
    return AnimatedContainer(
      key: ValueKey(currentPage),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  // -------------------- BOTTOM BUTTON --------------------
  Widget _bottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade100.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          currentPage == 5 ? Colors.green.shade400 : Colors.pink.shade400,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 0,
        ),
        onPressed: () {
          setState(() {
            if (currentPage < 5) {
              currentPage++;
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Form submitted successfully!"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                ),
              );
            }
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              currentPage == 5 ? "Submit" : "Next",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Icon(
              currentPage == 5 ? Icons.check_rounded : Icons.arrow_forward_rounded,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- PAGES --------------------
  Widget _page1() => _formSection("Policyholder Information", [
    _iconField(Icons.business, "Business Name"),
    _iconField(Icons.home_work, "Registered Business Address"),
    _iconField(Icons.phone, "Business Phone Number"),
    _iconField(Icons.email, "Business Email Address"),
    _iconField(Icons.language, "Business Website"),
    _iconField(Icons.category, "Business Category / Type"),
    _iconField(Icons.badge, "Business Registration Number (if applicable)"),
  ]);

  Widget _page2() => _formSection("Owner / Claimant Information", [
    _iconField(Icons.person, "Claimant full name"),
    _iconField(Icons.work_outline, "Claimant Role / Designation"),
    _iconField(Icons.phone_android, "Claimant Mobile Number"),
    _iconField(Icons.email_outlined, "Claimant Email Address"),
  ]);

  Widget _page3() => _formSection("Additional Information", [
    _iconField(Icons.description, "Business Description"),
    _iconField(Icons.facebook, "Facebook Link"),
    _iconField(Icons.camera_alt, "Instagram Link"),
    _iconField(Icons.link, "LinkedIn Link"),
    _iconField(Icons.upload, "Additional Documents / URLs"),
    _iconField(Icons.chat_bubble_outline, "Preferred Contact Method"),
  ]);

  Widget _page4() => _formSection("Proof of Ownership Documents", [
    _uploadCard("Upload Aadhar Card file"),
    _uploadCard("Upload PAN Card file"),
    _uploadCard("Upload Shop Act License / Trade License file"),
    _uploadCard("Upload Udyam Registration Certificate file"),
    _uploadCard("Upload GST Registration Certificate file"),
    _uploadCard("Upload Other Business Registration Document file"),
    _uploadCard("Upload Proof of Business Address file"),
    _uploadCard("Upload Recent Photograph of Business Premises file"),
  ]);

  Widget _page5() {
    TextEditingController dateController = TextEditingController();
    return _formSection("Declaration / Authorization", [
      const Text(
        "I hereby declare that the information provided is true to the best of my knowledge. Any false information may lead to rejection of the claim.",
        style: TextStyle(fontSize: 14, height: 1.4),
      ),
      const SizedBox(height: 16),
      _sectionLabel("Policyholder's Signature"),
      _frostedCard(const Text("Add Signature",
          style: TextStyle(color: Colors.pink))),
      const SizedBox(height: 20),
      _sectionLabel("Date Signed"),
      _datePicker(dateController),
    ]);
  }

  // -------------------- FORM COMPONENTS --------------------
  Widget _formSection(String title, List<Widget> children) {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFEFF5), Color(0xFFFDFCFB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade100.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconField(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.pink.shade400),
          labelText: label,
          floatingLabelStyle:
          TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: Colors.pink.shade300, width: 1.8),
          ),
        ),
      ),
    );
  }

  Widget _uploadCard(String title) {
    return GestureDetector(
      onTap: () => pickFile(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.pink.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.pink.shade100.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined,
                color: Colors.pink.shade400, size: 32),
            const SizedBox(height: 10),
            Text(title,
                textAlign: TextAlign.center,
                style:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            if (selectedFiles[title] != null) ...[
              const SizedBox(height: 8),
              Text(selectedFiles[title]!,
                  style: TextStyle(
                      color: Colors.pink.shade400,
                      fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _datePicker(TextEditingController dateController) {
    return TextField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: "Select Date",
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          dateController.text = "${date.day}-${date.month}-${date.year}";
        }
      },
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
  );

  Widget _frostedCard(Widget child) {
    return Container(
      height: 55,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
              color: Colors.pink.shade100.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: child,
    );
  }

  // -------------------- FILE PICKER --------------------
  Future<void> pickFile(String title) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    );
    if (result != null) {
      setState(() => selectedFiles[title] = result.files.single.name);
    }
  }
}
