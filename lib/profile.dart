import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'main.dart';


class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadUserData();

  }

  Future<bool> ensureLoggedIn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      return true; // ✅ already logged in
    }

    // 🚫 not logged in → go to SignInScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );

    return result == true; // ✅ if login succeeded
  }

  // 🧠 Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('user_name') ?? '';
      userEmail = prefs.getString('user_email') ?? '';
      userPhoto = prefs.getString('user_photo') ?? '';
      userId = prefs.getInt('user_id');
      mobileController.text = prefs.getString('user_mobile') ?? '';
      weddingVenueController.text = prefs.getString('wedding_venue') ?? '';
      weddingDateController.text = prefs.getString('wedding_date') ?? '';
    });

    print('📦 Loaded User Data → $userName | $userEmail | $userId');
  }

  // 🏙️ Load Cities
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
      print('🚨 Error loading cities: $e');
    } finally {
      setState(() => _isLoadingCities = false);
    }
  }

  // 🏙️ City picker
  Future<void> _showCityPicker() async {
    if (_cities.isEmpty && !_isLoadingCities) {
      await _loadCities();
    }

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



  // 📅 Wedding date picker
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

      setState(() {
        weddingDateController.text = formatted;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('wedding_date', formatted);

      print("✅ Saved wedding date → $formatted");
    }
  }


  // 🔁 Update profile
  Future<void> _updateUserProfile() async {
    // 🧠 Check login before allowing edit
    final loggedIn = await ensureLoggedIn(context);
    if (!loggedIn) {
      _showSnackBar('Please log in to update your profile.');
      return;
    }

    if (userId == null) {
      _showSnackBar('User ID missing');
      return;
    }

    setState(() => _isSaving = true);

    const String baseUrl = 'https://happywedz.com/api';
    final String url = '$baseUrl/user/$userId';

    print('🛰️ PATCH URL: $url');

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

      print('📡 [PATCH] Status: ${response.statusCode}');
      print('📡 [PATCH] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final user = data['user'];
          final prefs = await SharedPreferences.getInstance();

          await prefs.setString('user_mobile', user['phone'] ?? '');
          await prefs.setString('wedding_venue', user['weddingVenue'] ?? '');
          await prefs.setString('wedding_date', user['weddingDate'] ?? '');

          _showSnackBar('Profile updated successfully ✅');
        } else {
          _showSnackBar('Failed to update profile');
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Error updating profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }


  // 🚪 Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
            stops: [0.0, 0.3, 0.6],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 50),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: userPhoto.isNotEmpty
                          ? NetworkImage(userPhoto)
                          : const NetworkImage(
                          'https://www.wedmegood.com/images/placeholder-profile.png'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName.isNotEmpty ? userName : 'User',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail.isNotEmpty ? userEmail : 'example@mail.com',
                          style: GoogleFonts.poppins(
                              color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),

              // 📞 Mobile
              ListTile(
                title: Text('Mobile Number',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      hintText: 'Enter your mobile number',
                      border: InputBorder.none),
                ),
              ),
              const Divider(),

              // 🏙️ Wedding Venue
              ListTile(
                title: Text('Wedding Venue (City)',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: TextField(
                  controller: weddingVenueController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    hintText: 'Select your wedding city',
                    border: InputBorder.none,
                  ),
                  onTap: _showCityPicker,
                ),
              ),
              const Divider(),

              // 📅 Wedding Date
              ListTile(
                title: Text('Wedding Date',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: TextField(
                  controller: weddingDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                      hintText: 'Select wedding date',
                      border: InputBorder.none),
                  onTap: _pickWeddingDate,
                ),
              ),
              const Divider(),

              // 💾 Save
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isSaving ? Colors.grey : Colors.pinkAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving ? null : _updateUserProfile,
                  child: Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const Divider(),

              // 🚪 Logout
              ListTile(
                leading:
                const Icon(Icons.logout_outlined, color: Colors.redAccent),
                title: Text('Logout',
                    style: GoogleFonts.poppins(
                        color: Colors.red, fontSize: 15)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ),
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
