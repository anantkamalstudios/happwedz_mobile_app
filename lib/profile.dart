import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  TextEditingController mobileController = TextEditingController();
  TextEditingController whatsappController = TextEditingController();
  bool updatesOnWhatsapp = false;

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
              // TODO: Handle password change
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
              SizedBox(height:50),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                      'https://www.wedmegood.com/images/placeholder-profile.png',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harshada',
                        style: GoogleFonts.poppins(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ChoiceChip(
                            label: Text('Male'),
                            selected: false,
                            onSelected: (val) {},
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('Female'),
                            selected: true,
                            onSelected: (val) {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Email Section
              ListTile(
                title: Text(
                  'Email Address',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'harshada.anantkamalstudios@gmail.com',
                  style: GoogleFonts.poppins(color: Colors.grey.shade700),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Verified', style: GoogleFonts.poppins(fontSize: 12)),
                ),
              ),
              const Divider(),

              // Set Mobile Number
              ListTile(
                title: Text(
                  'Set Mobile Number',
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

              // Set Password
              ListTile(
                title: Text(
                  'Set Password',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('XXXXXXXXXX'),
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
                    hintText: 'Enter your mobile number',
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
                onTap: () {
                  // TODO: Logout action
                },
              ),
              const Divider(),

              // Delete Account
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete my account', style: GoogleFonts.poppins(color: Colors.red)),
                onTap: () {
                  // TODO: Delete account action
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
