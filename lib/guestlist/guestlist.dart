// guest_list_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart'; // for ensureLoggedIn() and BottomBars etc if used

// -----------------------------
// Constants (change keys if your app uses different ones)
// -----------------------------
const String AUTH_TOKEN_KEY = 'auth_token';
const String USER_ID_KEY = 'user_id';
const String GROUPS_KEY = 'guest_groups';

// -----------------------------
// Guest model (maps API response)
// -----------------------------
class Guest {
  final int? id;
  final int userId;
  final String name;
  final String email;
  final String group;
  String status;  // Pending / Accepted / Declined etc
  final String type; // Adult/Child
  final String menu; // Veg / Non-Veg / All etc
  final int companions;
  final String seatNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // optional UI fields
  String phone = '';

  String? notes;

  Guest({
    this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.group,
    required this.status,
    required this.type,
    required this.menu,
    required this.companions,
    required this.seatNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Guest(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? null),
      userId: (json['userId'] is int) ? json['userId'] : int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      group: (json['group'] ?? json['groupName'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      type: (json['type'] ?? '').toString(),
      menu: (json['menu'] ?? '').toString(),
      companions: (json['companions'] is int) ? json['companions'] : int.tryParse(json['companions']?.toString() ?? '') ?? 0,
      seatNumber: (json['seat_number'] ?? json['seatNumber'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

// -----------------------------
// Guest List Screen
// -----------------------------
class GuestListScreen extends StatefulWidget {
  const GuestListScreen({Key? key}) : super(key: key);

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Guest> _allGuests = [];
  bool _isLoading = false;

  // groups saved locally
  List<String> _groups = [];

  final List<String> _categories = ['All', 'Family', 'Friends', 'Colleagues', 'Other'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLocalGroups();
    fetchGuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  Future<void> sendSMS(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number")),
      );
      return;
    }

    final smsUrl = Uri.parse("sms:$phone?body=Hello! You are invited 🥳");
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open SMS")),
      );
    }
  }
  Future<void> sendWhatsApp(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone not available")),
      );
      return;
    }

    final whatsappUrl = Uri.parse("https://wa.me/$phone?text=Hello! You are invited 🎉");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }

  // ---------------- Local Groups ----------------
  Future<void> _loadLocalGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(GROUPS_KEY);
    if (raw != null) {
      try {
        final List<dynamic> arr = jsonDecode(raw);
        _groups = arr.map((e) => e.toString()).toList();
      } catch (_) {
        _groups = [];
      }
    } else {
      _groups = ['Other']; // default group
    }
    setState(() {});
  }


  // ---------------- API: Delete Guest ----------------
  Future<void> deleteGuest(int guestId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) {
      _toast("Please login again");
      return;
    }

    print("🗑️ DELETE https://happywedz.com/api/guestlist/$guestId");

    final response = await http.delete(
      Uri.parse("https://happywedz.com/api/guestlist/$guestId"),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print("🔹 DELETE status: ${response.statusCode}");
    print("🔸 DELETE body: ${response.body}");

    if (response.statusCode == 200) {
      _toast("Guest deleted successfully", success: true);
      await fetchGuests(); // refresh list
    } else {
      try {
        final data = jsonDecode(response.body);
        _toast(data["message"] ?? "Failed to delete guest");
      } catch (_) {
        _toast("Failed to delete guest");
      }
    }
  }


  Future<void> _saveLocalGroups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(GROUPS_KEY, jsonEncode(_groups));
  }

  void _showCreateGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Group'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Group Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              if (!_groups.contains(name)) {
                setState(() => _groups.add(name));
                _saveLocalGroups();
              }
              Navigator.pop(context);
            },
            child: const Text('Create Group'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF69B4), foregroundColor: Colors.white),
          ),
        ]
      ),
    );
  }

  // ---------------- API: Fetch Guests ----------------
  Future<void> fetchGuests() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userId = prefs.getInt("user_id");

    if (token == null || userId == null) {
      print("❌ No token or userId found");
      setState(() => _isLoading = false);
      return;
    }

    final url = "https://happywedz.com/api/guestlist/user/$userId";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        final List guests = data["guests"] ?? [];
        setState(() {
          _allGuests = guests.map((e) => Guest.fromJson(e)).toList();
        });
      }
    }

    setState(() => _isLoading = false);
  }






  // ---------------- API: Add Guest ----------------
  Future<void> addGuest(Map<String, dynamic> guestData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userId = prefs.getInt("user_id");

    if (token == null || userId == null) {
      print("❌ No token or userId");
      _toast("Please login again");
      return;
    }

    guestData["userId"] = userId;

    print("📤 POST https://happywedz.com/api/guestlist");
    print("📦 payload: $guestData");

    final response = await http.post(
      Uri.parse("https://happywedz.com/api/guestlist"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(guestData),
    );

    print("🔹 POST status: ${response.statusCode}");
    print("🔸 POST body: ${response.body}");

    // ✅ Accept 200, 201 as success
    if (response.statusCode == 200 || response.statusCode == 201) {
      print("✅ GUEST SAVED SUCCESSFULLY");
      _toast("Guest added successfully", success: true);

      // refresh list
      await fetchGuests();
    } else if (response.statusCode == 401) {
      print("❌ Unauthorized → Token expired");
      _toast("Session expired. Please login again");
    } else {
      print("❌ ERROR => ${response.statusCode}");
      try {
        final data = jsonDecode(response.body);
        _toast(data["message"] ?? "Failed to save guest");
      } catch (_) {
        _toast("Failed to save guest");
      }
    }
  }



  void _toast(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }


  // ---------------- UI / Helpers ----------------
  List<Guest> get _filteredGuests {
    final q = _searchQuery.toLowerCase().trim();

    // Filter guests by search and tab selection
    List<Guest> filtered = _allGuests.where((guest) {
      final matchesSearch = q.isEmpty || guest.name.toLowerCase().contains(q);
      final matchesGroup = _selectedCategory == 'All' || guest.group == _selectedCategory;

      switch (_tabController.index) {
        case 1: // Attending
          return matchesSearch && matchesGroup && guest.status.toLowerCase() == 'attending';
        case 2: // Pending
          return matchesSearch && matchesGroup && guest.status.toLowerCase() == 'pending';
        case 3: // Not Attending
          return matchesSearch && matchesGroup && guest.status.toLowerCase() == 'not attending';
        default: // All
          return matchesSearch && matchesGroup;
      }
    }).toList();

    // Sort alphabetically by guest name
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return filtered;
  }


  int get _totalAccepted => _allGuests.where((g) => g.status.toLowerCase() == 'attending').length;

  int get _totalPending => _allGuests.where((g) => g.status.toLowerCase() == 'pending').length;
  int get _totalDeclined => _allGuests.where((g) => g.status.toLowerCase() == 'Not Attending').length;
  int get _totalGuests => _allGuests.length;

  // ---------------- Add Guest dialog (fields per screenshot) ----------------
  void _showAddGuestDialog() {
    final _formKey = GlobalKey<FormState>();

    String name = '';
    String email = '';
    int companions = 0;
    String group = _groups.isNotEmpty ? _groups.first : 'Other';
    String type = 'Adult';
    String menu = 'Veg';
    String seat = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: const Text('Add New Guest'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Guest Name',
                            hintText: 'e.g., John Doe'
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        onSaved: (v) => name = v!.trim(),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Guest Email'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          // ✅ Simple email regex
                          final emailRegEx = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegEx.hasMatch(v.trim())) return 'Enter a valid email';
                          return null;
                        },
                        onSaved: (v) => email = v!.trim(),
                      ),


                      const SizedBox(height: 12),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Companions',
                          hintText: '0',
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (v) => companions = int.tryParse(v ?? '0') ?? 0,
                      ),

                      const SizedBox(height: 12),

                      /// ✅ GROUP
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Group'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: group,
                            isExpanded: true,
                            items: _groups
                                .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                                .toList(),
                            onChanged: (v) {
                              setStateSB(() => group = v!);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),


                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Type'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: type,
                            isExpanded: true,
                            items: ['Adult', 'Child']
                                .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t),
                            ))
                                .toList(),
                            onChanged: (v) {
                              setStateSB(() => type = v!);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// ✅ MENU
                      InputDecorator(
                        decoration: const InputDecoration(labelText: 'Menu Preference'),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: menu,
                            isExpanded: true,
                            items: ['Veg', 'NonVeg', 'All']
                                .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                                .toList(),
                            onChanged: (v) {
                              setStateSB(() => menu = v!);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Seat Number',
                          hintText: 'e.g., A12',
                        ),
                        onSaved: (v) => seat = v?.trim() ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();

                    final loggedIn = await ensureLoggedIn(context);
                    if (!loggedIn) return;

                    final payload = {
                      "companions": companions,
                      "email": email,
                      "group": group,
                      "menu": menu,
                      "name": name,
                      "seat_number": seat,
                      "status": "Pending",
                      "type": type,
                    };

                    await addGuest(payload);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF69B4),foregroundColor: Colors.white
                  ),
                  child: const Text('Save Guest'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // ---------------- UI Build ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4), // Hot Pink
              Color(0xFFFFB6C1), // Light Pink
              Colors.white,      // White
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Container(
                color: Colors.transparent, // Gradient shows behind AppBar
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Guest List',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.group_add, color: Colors.white),
                                onPressed: _showCreateGroupDialog,
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onPressed: _showOptionsMenu,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // TabBar
                    Container(
                      color: Colors.transparent,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        onTap: (index) => setState(() {}),
                        tabs: [
                          Tab(text: 'All (${_allGuests.length})'),
                          Tab(text: 'Attending ($_totalAccepted)'),
                          Tab(text: 'Pending ($_totalPending)'),
                          Tab(text: 'Not Attending ($_totalDeclined)'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body content
              Expanded(
                child: _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
                    : Column(
                  children: [
                    _buildStatsCard(),
                    _buildSearchAndCreateRow(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(4, (index) => _buildGuestList()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final loggedIn = await ensureLoggedIn(context);
          if (!loggedIn) return;
          _showAddGuestDialog();
        },
        backgroundColor: const Color(0xFFFF69B4),
        icon: const Icon(Icons.add,color: Colors.white,),
            label: const Text('Add Guest',style: TextStyle(color: Colors.white),),
      ),
    );
  }


  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF69B4), Color(0xFF9B7EF5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFFFF69B4).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Guests', '$_totalGuests', Icons.people),
          _buildStatItem('Attending', '$_totalAccepted', Icons.check_circle),
          _buildStatItem('Pending', '$_totalPending', Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSearchAndCreateRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(

                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.search, color: Colors.pink),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  hintText: 'Search guests...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              ),
            ),
          ),

          // const SizedBox(width: 12),
          // ElevatedButton.icon(
          //   onPressed: () => _showAddGuestDialog(),
          //   icon: const Icon(Icons.person_add_alt_1),
          //   label: const Text('Add Guest'),
          //   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF69B4),foregroundColor: Colors.white),
          // ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _showCreateGroupDialog,
            icon: const Icon(Icons.group,color: Colors.black,),
            label: const Text('Create Group',style: TextStyle(color: Colors.black),),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white, // ✅ sets text & icon color to white
              side: const BorderSide(color: Colors.pink), // optional: white border
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestList() {
    final guests = _filteredGuests;

    return RefreshIndicator(
      color: Color(0xFFFF69B4),
      onRefresh: () async {
        await fetchGuests();
      },
      child: guests.isEmpty
          ? ListView(
        children: [
          SizedBox(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 12),
                  Text("No guests found",
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
          )
        ],
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: guests.length,
        itemBuilder: (context, index) =>
            _buildGuestCard(guests[index]),
      ),
    );
  }


  Widget _buildGuestCard(Guest guest) {
    final statusLower = guest.status.toLowerCase();
    Color statusColor;
    IconData statusIcon;

    switch (statusLower) {
      case 'attending':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'not attending':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GuestDetailsScreen(guest: guest),
            ),
          );

          if (updated == true) setState(() {});
        },

        contentPadding: const EdgeInsets.all(16),

        // ---------------------------------------------
        // Avatar
        // ---------------------------------------------
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF69B4).withOpacity(0.12),
          child: Text(
            guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ---------------------------------------------
        // Title + Status
        // ---------------------------------------------
        title: Row(
          children: [
            Expanded(
              child: Text(
                guest.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(
                    guest.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),

        // ---------------------------------------------
        // Subtitle Content
        // ---------------------------------------------
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Email
            if (guest.email.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    guest.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),

            const SizedBox(height: 6),

            // Group + Companions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    guest.group,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${guest.companions}',
                    style: const TextStyle(
                      color: Colors.pink,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            // Seat
            if (guest.seatNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Seat/Table: ${guest.seatNumber}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),

            // Meal
            if (guest.menu.isNotEmpty)
              Text(
                'Meal: ${guest.menu}',
                style: const TextStyle(fontSize: 12),
              ),

            const SizedBox(height: 10),

            // ---------------------------------------------
            // Action Icons Row
            // ---------------------------------------------
            Row(
              children: [
                // EMAIL
                IconButton(
                  icon: const Icon(Icons.email_outlined, color: Colors.blue),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final int? userId = prefs.getInt('user_id');

                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Login again")),
                      );
                      return;
                    }

                    await sendGuestEmail(
                      toEmail: guest.email,
                      subject: "Wedding Invitation",
                      message: "Dear ${guest.name},\nYou are invited!",
                      userId: userId,
                      context: context,
                    );
                  },
                ),



                // WHATSAPP
                IconButton(
                  icon: const Icon(Icons.sms, color: Colors.green),
                  onPressed: () {
                    sendWhatsApp(guest.phone ?? "");
                  },
                ),

                // E-INVITE
                IconButton(
                  icon: const Icon(Icons.card_giftcard, color: Colors.pink),
                  onPressed: () {
                    // sendInvite(guest);
                  },
                ),
              ],
            ),

            // ---------------------------------------------
            // Delete Button
            // ---------------------------------------------
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                label: const Text("Delete", style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Delete"),
                      content: Text("Are you sure you want to delete ${guest.name}?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && guest.id != null) {
                    await deleteGuest(guest.id!);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> sendGuestEmail({
    required String toEmail,
    required String message,
    required String subject,
    required int userId,
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login again")),
        );
        return;
      }

      final url = Uri.parse("https://happywedz.com/api/guestlist/send-guestlist-email");

      final body = {
        "toEmail": [toEmail],
        "message": message,
        "subject": subject,
        "userId": userId.toString(),
      };

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email sent successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.upload_file), title: const Text('Import from CSV'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.download), title: const Text('Export Guest List'), onTap: () => Navigator.pop(context)),
          ListTile(leading: const Icon(Icons.email), title: const Text('Send Bulk Email'), onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  // ---------------- Launch helpers ----------------
  void _launchWhatsApp(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
      return;
    }
    final whatsappUrl = Uri.parse("https://wa.me/$phone?text=Hello!");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open WhatsApp")));
    }
  }

  void _launchEmail(String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email available')));
      return;
    }
    final emailUrl = Uri.parse("mailto:$email?subject=Hello&body=Hi!");
    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Email app")));
    }
  }
}


class GuestDetailsScreen extends StatefulWidget {
  final Guest guest;

  const GuestDetailsScreen({Key? key, required this.guest}) : super(key: key);

  @override
  State<GuestDetailsScreen> createState() => _GuestDetailsScreenState();
}

class _GuestDetailsScreenState extends State<GuestDetailsScreen> {
  String selectedStatus = "";
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.guest.status; // initial value
  }



  Future<void> updateGuestStatus(String newStatus) async {
    setState(() => isUpdating = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");

    if (token == null) return;

    final url =
        "https://happywedz.com/api/guestlist/${widget.guest.id}";

    print("📤 PUT $url");
    print("📦 Payload: {status: $newStatus}");

    final response = await http.put(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
        "Accept": "application/json"
      },
      body: jsonEncode({"status": newStatus}),
    );

    print("🔹 Status: ${response.statusCode}");
    print("🔸 Body: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        selectedStatus = newStatus;
        widget.guest.status = newStatus;   // update local model
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Status updated"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // ✅ pass `true` back to list screen
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed: ${response.statusCode}"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isUpdating = false);
  }



  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.guest.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4),
              Color(0xFFFFB6C1),
              Colors.white,
            ],
            stops: [0.0, 0.35, 0.8],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [

                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: Text(
                    widget.guest.name.isNotEmpty
                        ? widget.guest.name[0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  widget.guest.name,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.guest.email,
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),

                const SizedBox(height: 20),

                // DETAILS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _detailTile(Icons.group, "Group", widget.guest.group),
                      _detailTile(Icons.person_outline, "Type", widget.guest.type),
                      _detailTile(Icons.fastfood, "Meal", widget.guest.menu),
                      _detailTile(Icons.people_alt, "Companions",
                          widget.guest.companions.toString()),
                      _detailTile(Icons.event_seat, "Seat Number",
                          widget.guest.seatNumber),
                      _detailTile(Icons.tag, "User ID",
                          widget.guest.userId.toString()),

                      const SizedBox(height: 10),

                      /// STATUS + DROPDOWN
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Status",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.pinkAccent),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedStatus,
                                items: const [
                                  DropdownMenuItem(
                                      value: "Pending", child: Text("Pending")),
                                  DropdownMenuItem(
                                      value: "Attending",
                                      child: Text("Attending")),
                                  DropdownMenuItem(
                                      value: "Not Attending", child: Text("Not Attending")),
                                ],
                                onChanged: isUpdating
                                    ? null
                                    : (value) {
                                  if (value != null) {
                                    updateGuestStatus(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (widget.guest.createdAt != null)
                        _detailTile(Icons.calendar_month, "Created",
                            widget.guest.createdAt.toString()),

                      if (widget.guest.updatedAt != null)
                        _detailTile(Icons.update, "Updated",
                            widget.guest.updatedAt.toString()),
                    ],
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Close",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // ✅ white text color added
            ),
          ),

        ),
      ),
    );
  }


  // =======================================================
  //   DETAIL TILE
  // =======================================================
  Widget _detailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.pink, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

}



