import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // backgroundColor: Colors.pinkAccent,
        title: const Text("My Profile"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER
            Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage(
                      'assets/profile.jpg'), // your profile pic
                ),
                title: const Text(
                  "Jiya Sharma",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "jiya@email.com",
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: TextButton.icon(
                  onPressed: () {
                    // Navigate to edit profile screen
                  },
                  icon: const Icon(
                      Icons.edit, size: 18, color: Colors.pinkAccent),
                  label: const Text(
                    "Edit",
                    style: TextStyle(color: Colors.pinkAccent),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // MY ACTIVITY CARDS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _activityCard(Icons.favorite, "Shortlisted", "12"),
                  _activityCard(Icons.calendar_today, "Bookings", "3"),
                  _activityCard(Icons.star, "Reviews", "5"),
                ],
              ),
            ),

            const SizedBox(height: 16),
            _menuTile(context, Icons.edit, "Edit Profile",
                page:  EditProfilePage()),
            _menuTile(context, Icons.notifications, "Notifications",
                page: const NotificationsPage()),
            _menuTile(
                context, Icons.payment, "Payments", page: const PaymentPage()),
            _menuTile(context, Icons.settings, "Settings",
                page: const SettingsPage()),
            _menuTile(context, Icons.logout, "Logout", isLogout: true),

          ],
        ),
      ),
    );
  }

  static Widget _activityCard(IconData icon, String title, String count) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Colors.pinkAccent, size: 28),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(count, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _menuTile(BuildContext context,
      IconData icon,
      String title, {
        bool isLogout = false,
        Widget? page, // destination page
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.pinkAccent),
        title: Text(title,
            style: TextStyle(color: isLogout ? Colors.red : Colors.black)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (isLogout) {
            // Perform logout logic here
          } else if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          }
        },
      ),
    );
  }
}



class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: "Jiya Sharma");
    final emailController = TextEditingController(text: "jiya@email.com");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: () {
                // Save profile changes
              },
              child: const Text("Save Changes"),
            )
          ],
        ),
      ),
    );
  }
}


class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.pinkAccent),
            title: Text("Your booking with XYZ Venue is confirmed"),
            subtitle: Text("2 hours ago"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.pinkAccent),
            title: Text("New message from ABC Makeup Artist"),
            subtitle: Text("Yesterday"),
          ),
        ],
      ),
    );
  }
}


class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.payment, color: Colors.pinkAccent),
            title: Text("Razorpay - Wedding Decor"),
            subtitle: Text("₹25,000 • 15 Aug 2025"),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.payment, color: Colors.pinkAccent),
            title: Text("Cash - Photography"),
            subtitle: Text("₹40,000 • 10 Aug 2025"),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}



class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            activeColor: Colors.pinkAccent,
            value: true,
            onChanged: (val) {},
            title: const Text("Push Notifications"),
          ),
          SwitchListTile(
            activeColor: Colors.pinkAccent,
            value: false,
            onChanged: (val) {},
            title: const Text("Email Updates"),
          ),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.pinkAccent),
            title: const Text("Change Password"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
