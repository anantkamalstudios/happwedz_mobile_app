import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  TextEditingController mobileController = TextEditingController();
  TextEditingController whatsappController = TextEditingController();
  bool updatesOnWhatsapp = false;

  String userName = '';
  String userEmail = '';
  String userPhoto = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ✅ Load saved user info from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? '';
      userEmail = prefs.getString('user_email') ?? '';
      userPhoto = prefs.getString('user_photo') ?? '';
      mobileController.text = prefs.getString('user_mobile') ?? '';
    });
  }

  // ✅ Logout function (clears Firebase + Google + SharedPreferences)
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();

      _showSnackBar('Logged out successfully');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
            (route) => false,
      );
    } catch (e) {
      _showSnackBar('Logout failed: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFE91E63),
      ),
    );
  }

  void _showChangePasswordDialog() {
    TextEditingController oldPassController = TextEditingController();
    TextEditingController newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              decoration: const InputDecoration(
                hintText: 'Enter Previous Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(
                hintText: 'Enter New Password',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Save', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 50),

              // ✅ Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: userPhoto.isNotEmpty
                        ? NetworkImage(userPhoto)
                        : const NetworkImage('https://www.wedmegood.com/images/placeholder-profile.png'),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName.isNotEmpty ? userName : 'User',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail.isNotEmpty ? userEmail : 'example@mail.com',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),
              const Divider(),

              // Mobile Number
              ListTile(
                title: Text(
                  'Mobile Number',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter your mobile number',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const Divider(),

              // Password
              ListTile(
                title: Text(
                  'Password',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('••••••••••'),
                trailing: TextButton(
                  onPressed: _showChangePasswordDialog,
                  child: Text('Change', style: GoogleFonts.poppins(color: Colors.pink)),
                ),
              ),
              const Divider(),

              // WhatsApp Updates
              SwitchListTile(
                title: Text(
                  'Get Updates on WhatsApp',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                value: updatesOnWhatsapp,
                onChanged: (val) {
                  setState(() {
                    updatesOnWhatsapp = val;
                  });
                },
                subtitle: TextField(
                  controller: whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter WhatsApp number',
                    border: InputBorder.none,
                  ),
                  enabled: updatesOnWhatsapp,
                ),
              ),
              const Divider(),

              // Logout
              ListTile(
                leading: const Icon(Icons.logout_outlined, color: Colors.red),
                title: Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: _logout,
              ),
              const Divider(),

              // Delete Account (future API)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete my account', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: () {
                  _showSnackBar('Delete account feature coming soon');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
