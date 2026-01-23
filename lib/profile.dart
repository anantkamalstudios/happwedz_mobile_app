import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/Bottombars/HomeScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'authservice.dart';
import 'main.dart';


class ProfileSettingsScreen extends StatefulWidget {
  const  ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  TextEditingController mobileController = TextEditingController();
  TextEditingController weddingVenueController = TextEditingController();
  TextEditingController weddingDateController = TextEditingController();

  String userName = '';
  String userEmail = '';
  String userPhoto = '';
  int? userId;

  List<String> _cities = [];
  bool _isLoadingCities = false;
  bool _isSaving = false;

  // Validation Errors
  String? mobileError;
  String? venueError;
  String? weddingDateError;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // -----------------------------------------------------
  // LOGIN CHECK
  // -----------------------------------------------------
  Future<bool> ensureLoggedIn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) return true;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );

    return result == true;
  }

  // -----------------------------------------------------
  // LOAD USER DATA
  // -----------------------------------------------------
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    userName = prefs.getString("user_name") ?? "";
    userEmail = prefs.getString("user_email") ?? "";
    userPhoto = prefs.getString("user_photo") ?? "";
    userId = prefs.getInt("user_id");

    mobileController.text = prefs.getString("user_mobile") ?? "";
    weddingVenueController.text = prefs.getString("wedding_venue") ?? "";
    weddingDateController.text = prefs.getString("wedding_date") ?? "";

    setState(() {});
  }

  // -----------------------------------------------------
  // VALIDATIONS
  // -----------------------------------------------------
  String? validateMobile(String m) {
    if (m.isEmpty) return "Mobile number is required";
    if (!RegExp(r'^[0-9]{10}$').hasMatch(m)) return "Enter a valid 10-digit number";
    if (!RegExp(r'^[6-9]').hasMatch(m)) return "Must start with 6, 7, 8, or 9";
    return null;
  }

  String? validateVenue(String v) {
    if (v.isEmpty) return "Wedding venue is required";
    return null;
  }

  String? validateWeddingDate(String date) {
    if (date.isEmpty) return "Wedding date is required";

    DateTime today = DateTime.now();
    DateTime selected = DateTime.tryParse(date) ?? today;

    DateTime minDate = DateTime(today.year - 1);
    DateTime maxDate = DateTime(today.year + 5);

    if (selected.isBefore(minDate)) return "Wedding date is too old";
    if (selected.isAfter(maxDate)) return "Wedding date is too far in the future";

    return null;
  }

  // -----------------------------------------------------
  // LOAD CITIES
  // -----------------------------------------------------
  Future<void> _loadCities() async {
    setState(() => _isLoadingCities = true);
    try {
      final response = await http.get(Uri.parse(
          'https://countriesnow.space/api/v0.1/countries/state/cities/q?country=India&state=Maharashtra'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['error'] == false && data['data'] != null) {
          setState(() {
            _cities = List<String>.from(data['data']);
            _cities.sort();
          });
        }
      }
    } catch (e) {
      print('🚨 City loading error: $e');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  // -----------------------------------------------------
  // CITY SEARCH
  // -----------------------------------------------------
  Future<void> _showCityPicker() async {
    if (_cities.isEmpty) await _loadCities();

    final selected = await showSearch<String>(
      context: context,
      delegate: _CitySearchDelegate(_cities),
    );

    if (selected != null && selected.isNotEmpty) {
      setState(() {
        weddingVenueController.text = selected;
      });
    }
  }

  // -----------------------------------------------------
  // DATE PICKER
  // -----------------------------------------------------
  Future<void> _pickWeddingDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Select Wedding Date',
    );

    if (picked != null) {
      String formatted = picked.toIso8601String().split('T')[0];
      weddingDateController.text = formatted;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wedding_date', formatted);
    }
  }

  // -----------------------------------------------------
  // UPDATE PROFILE
  // -----------------------------------------------------
  Future<void> _updateUserProfile() async {
    // RUN VALIDATIONS
    setState(() {
      mobileError = validateMobile(mobileController.text.trim());
      venueError = validateVenue(weddingVenueController.text.trim());
      weddingDateError = validateWeddingDate(weddingDateController.text.trim());
    });

    if (mobileError != null || venueError != null || weddingDateError != null) {
      _showSnackBar("Please fix the errors before saving");
      return;
    }

    final loggedIn = await ensureLoggedIn(context);
    if (!loggedIn) return;

    if (userId == null) return _showSnackBar('User ID missing');

    setState(() => _isSaving = true);

    final url = 'https://happywedz.com/api/user/$userId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': mobileController.text.trim(),
          'weddingVenue': weddingVenueController.text.trim(),
          'weddingDate': weddingDateController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          final user = data['user'];

          prefs.setString('user_mobile', user['phone'] ?? '');
          prefs.setString('wedding_venue', user['weddingVenue'] ?? '');
          prefs.setString('wedding_date', user['weddingDate'] ?? '');

          _showSnackBar('Profile updated successfully ✔️');
        } else {
          _showSnackBar('Update failed');
        }
      } else {
        _showSnackBar('Server error ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // -----------------------------------------------------
  // LOGOUT
  // -----------------------------------------------------
  Future<void> _logout() async {
    await UserPrefs.clear();
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
          (route) => false,
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.pink),
    );
  }

  // -----------------------------------------------------
  // FULL PROFESSIONAL UI
  // -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF4F9A), Color(0xFFFFB7D5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: InkWell(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WeddingHomePage()),
                        (route) => false,
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [

                  const SizedBox(height: 20),

                  // PROFILE CARD
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 43,
                          backgroundImage: userPhoto.isNotEmpty
                              ? NetworkImage(userPhoto)
                              : NetworkImage(
                              "https://www.wedmegood.com/images/placeholder-profile.png"),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userName.isNotEmpty ? userName : "Your Name",
                                    style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                  userEmail.isNotEmpty
                                      ? userEmail
                                      : "example@mail.com",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.grey[700]),
                                )
                              ]),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // SETTINGS CONTAINER
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildField(
                          label: "Mobile Number",
                          controller: mobileController,
                          icon: Icons.phone_android,
                          keyboard: TextInputType.phone,
                          error: mobileError,
                        ),

                        SizedBox(height: 20),

                        _buildField(
                          label: "Wedding Venue (City)",
                          controller: weddingVenueController,
                          icon: Icons.location_on_outlined,
                          readOnly: true,
                          onTap: _showCityPicker,
                          error: venueError,
                        ),

                        SizedBox(height: 20),

                        _buildField(
                          label: "Wedding Date",
                          controller: weddingDateController,
                          icon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: _pickWeddingDate,
                          error: weddingDateError,
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _updateUserProfile,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.all(15),
                              backgroundColor: _isSaving
                                  ? Colors.grey
                                  : Colors.pinkAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _isSaving ? "Saving..." : "Save Changes",
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Divider(),

                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.redAccent),
                          title: Text(
                            "Logout",
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.red),
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // BEAUTIFUL INPUT FIELD WITH ERROR
  // -----------------------------------------------------
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? error,
    TextInputType? keyboard,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),

        const SizedBox(height: 6),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: error != null
                ? Border.all(color: Colors.redAccent)
                : null,
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboard,
            onTap: onTap,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.pinkAccent),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }
}


class _CitySearchDelegate extends SearchDelegate<String> {
  final List<String> cities;
  _CitySearchDelegate(this.cities);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) {
    final results = cities
        .where((city) => city.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(results[i]),
        onTap: () => close(context, results[i]),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}
