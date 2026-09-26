// // guest_list_screen.dart
// import 'dart:convert';
// import 'dart:math';
// import 'package:flutter/material.dart';

import '../core/core.dart';
// import 'package:happy_wedz/profile.dart';
// import 'package:http/http.dart' as http;
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// import '../main.dart'; // for ensureLoggedIn() and BottomBars etc if used
//
// // -----------------------------
// // Constants (change keys if your app uses different ones)
// // -----------------------------
// const String AUTH_TOKEN_KEY = 'auth_token';
// const String USER_ID_KEY = 'user_id';
// const String GROUPS_KEY = 'guest_groups';
//
// // -----------------------------
// // Guest model (maps API response)
// // -----------------------------
// class Guest {
//   final int? id;
//   final int userId;
//   final String name;
//   final String email;
//   final String group;
//   String status;
//   final String type;
//   final String menu;
//   final int companions;
//   final String seatNumber;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;
//
//   // NEW FIELD
//   final String phoneNumber;
//
//   Guest({
//     this.id,
//     required this.userId,
//     required this.name,
//     required this.email,
//     required this.group,
//     required this.status,
//     required this.type,
//     required this.menu,
//     required this.companions,
//     required this.seatNumber,
//     required this.phoneNumber,  // 👈 NEW
//     this.createdAt,
//     this.updatedAt,
//   });
//
//   factory Guest.fromJson(Map<String, dynamic> json) {
//     return Guest(
//       id: json['id'],
//       userId: json['userId'] ?? 0,
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       group: json['group'] ?? '',
//       status: json['status'] ?? 'Pending',
//       type: json['type'] ?? '',
//       menu: json['menu'] ?? '',
//       companions: json['companions'] ?? 0,
//       seatNumber: json['seat_number'] ?? '',
//       phoneNumber: json['phone_number']?.toString() ?? '', // 👈 NEW
//       createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
//       updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
//     );
//   }
// }
//
// // -----------------------------
// // Guest List Screen
// // -----------------------------
// class GuestListScreen extends StatefulWidget {
//   const GuestListScreen({Key? key}) : super(key: key);
//
//   @override
//   State<GuestListScreen> createState() => _GuestListScreenState();
// }
//
// class _GuestListScreenState extends State<GuestListScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   String _searchQuery = '';
//   String _selectedCategory = 'All';
//
//   List<Guest> _allGuests = [];
//   bool _isLoading = false;
//
//   // groups saved locally
//   List<String> _groups = [];
//
//   final List<String> _categories = ['All', 'Family', 'Friends', 'Colleagues', 'Other'];
//   String phoneNumber = "";
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this);
//     _loadLocalGroups();
//     fetchGuests();
//   }
//   Future<bool> ensureUserReady(BuildContext context) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final token = prefs.getString('auth_token');
//     bool profileDone = prefs.getBool('profile_completed') ?? false;
//
//     if (token == null) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const SignInScreen()),
//       );
//       return false;
//     }
//
//     if (!profileDone) {
//       // fallback check
//       final phone = prefs.getString('user_phone') ?? '';
//       if (phone.isNotEmpty) {
//         await prefs.setBool('profile_completed', true);
//         return true;
//       }
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
//       );
//       return false;
//     }
//
//     return true;
//   }
//
//   void _showSnack(BuildContext context, String msg, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: isError ? Colors.red : Colors.green,
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//   Future<void> sendSMS(String phone) async {
//     if (phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("No phone number")),
//       );
//       return;
//     }
//
//     final smsUrl = Uri.parse("sms:$phone?body=Hello! You are invited 🥳");
//     if (await canLaunchUrl(smsUrl)) {
//       await launchUrl(smsUrl, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Could not open SMS")),
//       );
//     }
//   }
//   Future<void> sendWhatsApp(String phone) async {
//     if (phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Phone not available")),
//       );
//       return;
//     }
//
//     final whatsappUrl = Uri.parse("https://wa.me/$phone?text=Hello! You are invited 🎉");
//
//     if (await canLaunchUrl(whatsappUrl)) {
//       await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Could not open WhatsApp")),
//       );
//     }
//   }
//
//   // ---------------- Local Groups ----------------
//   Future<void> _loadLocalGroups() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(GROUPS_KEY);
//     if (raw != null) {
//       try {
//         final List<dynamic> arr = jsonDecode(raw);
//         _groups = arr.map((e) => e.toString()).toList();
//       } catch (_) {
//         _groups = [];
//       }
//     } else {
//       _groups = ['Other']; // default group
//     }
//     setState(() {});
//   }
//
//
//   // ---------------- API: Delete Guest ----------------
//   Future<void> deleteGuest(int guestId) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("auth_token");
//
//     if (token == null) {
//       _toast("Please login again");
//       return;
//     }
//
//     print("🗑️ DELETE https://happywedz.com/api/guestlist/$guestId");
//
//     final response = await http.delete(
//       Uri.parse("https://happywedz.com/api/guestlist/$guestId"),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Accept": "application/json",
//       },
//     );
//
//     print("🔹 DELETE status: ${response.statusCode}");
//     print("🔸 DELETE body: ${response.body}");
//
//     if (response.statusCode == 200) {
//       _toast("Guest deleted successfully", success: true);
//       await fetchGuests(); // refresh list
//     } else {
//       try {
//         final data = jsonDecode(response.body);
//         _toast(data["message"] ?? "Failed to delete guest");
//       } catch (_) {
//         _toast("Failed to delete guest");
//       }
//     }
//   }
//
//
//   Future<void> _saveLocalGroups() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(GROUPS_KEY, jsonEncode(_groups));
//   }
//
//   void _showCreateGroupDialog() {
//     final ctrl = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Create New Group'),
//         content: TextField(
//           controller: ctrl,
//           decoration: const InputDecoration(hintText: 'Group Name'),
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               final name = ctrl.text.trim();
//               if (name.isEmpty) return;
//               if (!_groups.contains(name)) {
//                 setState(() => _groups.add(name));
//                 _saveLocalGroups();
//               }
//               Navigator.pop(context);
//             },
//             child: const Text('Create Group'),
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF69B4), foregroundColor: Colors.white),
//           ),
//         ]
//       ),
//     );
//   }
//
//   // ---------------- API: Fetch Guests ----------------
//   Future<void> fetchGuests() async {
//     setState(() => _isLoading = true);
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("auth_token");
//     final userId = prefs.getInt("user_id");
//
//     if (token == null || userId == null) {
//       print("❌ No token or userId found");
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     final url = "https://happywedz.com/api/guestlist/user/$userId";
//
//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         "Authorization": "Bearer $token",
//         "Accept": "application/json",
//       },
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       if (data["success"] == true) {
//         final List guests = data["guests"] ?? [];
//         setState(() {
//           _allGuests = guests.map((e) => Guest.fromJson(e)).toList();
//         });
//       }
//     }
//
//     setState(() => _isLoading = false);
//   }
//
//
//
//
//
//
//   // ---------------- API: Add Guest ----------------
//   Future<void> addGuest(Map<String, dynamic> guestData) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("auth_token");
//     final userId = prefs.getInt("user_id");
//
//     if (token == null || userId == null) {
//       print("❌ No token or userId");
//       _toast("Please login again");
//       return;
//     }
//
//     guestData["userId"] = userId;
//
//     print("📤 POST https://happywedz.com/api/guestlist");
//     print("📦 payload: $guestData");
//
//     final response = await http.post(
//       Uri.parse("https://happywedz.com/api/guestlist"),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//       body: jsonEncode(guestData),
//     );
//
//     print("🔹 POST status: ${response.statusCode}");
//     print("🔸 POST body: ${response.body}");
//
//     // ✅ Accept 200, 201 as success
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       print("✅ GUEST SAVED SUCCESSFULLY");
//       _toast("Guest added successfully", success: true);
//
//       // refresh list
//       await fetchGuests();
//     } else if (response.statusCode == 401) {
//       print("❌ Unauthorized → Token expired");
//       _toast("Session expired. Please login again");
//     } else {
//       print("❌ ERROR => ${response.statusCode}");
//       try {
//         final data = jsonDecode(response.body);
//         _toast(data["message"] ?? "Failed to save guest");
//       } catch (_) {
//         _toast("Failed to save guest");
//       }
//     }
//   }
//
//
//
//   void _toast(String msg, {bool success = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: success ? Colors.green : Colors.red,
//       ),
//     );
//   }
//
//
//   // ---------------- UI / Helpers ----------------
//   List<Guest> get _filteredGuests {
//     final q = _searchQuery.toLowerCase().trim();
//
//     // Filter guests by search and tab selection
//     List<Guest> filtered = _allGuests.where((guest) {
//       final matchesSearch = q.isEmpty || guest.name.toLowerCase().contains(q);
//       final matchesGroup = _selectedCategory == 'All' || guest.group == _selectedCategory;
//
//       switch (_tabController.index) {
//         case 1: // Attending
//           return matchesSearch && matchesGroup && guest.status.toLowerCase() == 'attending';
//         case 2: // Pending
//           return matchesSearch && matchesGroup && guest.status.toLowerCase() == 'pending';
//         case 3: // Not Attending
//           return matchesSearch && matchesGroup && guest.status.toLowerCase() == 'not attending';
//         default: // All
//           return matchesSearch && matchesGroup;
//       }
//     }).toList();
//
//     // Sort alphabetically by guest name
//     filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
//
//     return filtered;
//   }
//
//
//   int get _totalAccepted => _allGuests.where((g) => g.status.toLowerCase() == 'attending').length;
//
//   int get _totalPending => _allGuests.where((g) => g.status.toLowerCase() == 'pending').length;
//   int get _totalDeclined => _allGuests.where((g) => g.status.toLowerCase() == 'Not Attending').length;
//   int get _totalGuests => _allGuests.length;
//
//   // ---------------- Add Guest dialog (fields per screenshot) ----------------
//   void _showAddGuestDialog() {
//     final _formKey = GlobalKey<FormState>();
//
//     String name = '';
//     String email = '';
//     int companions = 0;
//     String group = _groups.isNotEmpty ? _groups.first : 'Other';
//     String type = 'Adult';
//     String menu = 'Veg';
//     String seat = '';
//     String phoneNumber = "";
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setStateSB) {
//             return AlertDialog(
//               title: const Text('Add New Guest'),
//               content: SingleChildScrollView(
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//
//                       TextFormField(
//                         decoration: const InputDecoration(
//                             labelText: 'Guest Name',
//                             hintText: 'e.g., John Doe'
//                         ),
//                         validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//                         onSaved: (v) => name = v!.trim(),
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       TextFormField(
//                         decoration: const InputDecoration(labelText: 'Guest Email'),
//                         keyboardType: TextInputType.emailAddress,
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) return 'Required';
//                           // ✅ Simple email regex
//                           final emailRegEx = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
//                           if (!emailRegEx.hasMatch(v.trim())) return 'Enter a valid email';
//                           return null;
//                         },
//                         onSaved: (v) => email = v!.trim(),
//                       ),
//                       SizedBox(height: 12),
//                       TextFormField(
//                         decoration: const InputDecoration(
//                             labelText: 'Phone Number',
//                             hintText: 'e.g., 9876543210'
//                         ),
//                         keyboardType: TextInputType.phone,
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) return 'Required';
//                           if (v.length < 10) return 'Invalid phone';
//                           return null;
//                         },
//                         onSaved: (v) => phoneNumber = v!.trim(),
//                       ),
//
//
//                       const SizedBox(height: 12),
//
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Companions',
//                           hintText: '0',
//                         ),
//                         keyboardType: TextInputType.number,
//                         onSaved: (v) => companions = int.tryParse(v ?? '0') ?? 0,
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       /// ✅ GROUP
//                       InputDecorator(
//                         decoration: const InputDecoration(labelText: 'Group'),
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: group,
//                             isExpanded: true,
//                             items: _groups
//                                 .map((g) => DropdownMenuItem(
//                               value: g,
//                               child: Text(g),
//                             ))
//                                 .toList(),
//                             onChanged: (v) {
//                               setStateSB(() => group = v!);
//                             },
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 12),
//
//
//                       InputDecorator(
//                         decoration: const InputDecoration(labelText: 'Type'),
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: type,
//                             isExpanded: true,
//                             items: ['Adult', 'Child']
//                                 .map((t) => DropdownMenuItem(
//                               value: t,
//                               child: Text(t),
//                             ))
//                                 .toList(),
//                             onChanged: (v) {
//                               setStateSB(() => type = v!);
//                             },
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       /// ✅ MENU
//                       InputDecorator(
//                         decoration: const InputDecoration(labelText: 'Menu Preference'),
//                         child: DropdownButtonHideUnderline(
//                           child: DropdownButton<String>(
//                             value: menu,
//                             isExpanded: true,
//                             items: ['Veg', 'NonVeg', 'All']
//                                 .map((m) => DropdownMenuItem(
//                               value: m,
//                               child: Text(m),
//                             ))
//                                 .toList(),
//                             onChanged: (v) {
//                               setStateSB(() => menu = v!);
//                             },
//                           ),
//                         ),
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       TextFormField(
//                         decoration: const InputDecoration(
//                           labelText: 'Seat Number',
//                           hintText: 'e.g., A12',
//                         ),
//                         onSaved: (v) => seat = v?.trim() ?? '',
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (!_formKey.currentState!.validate()) return;
//                     _formKey.currentState!.save();
//
//                     final loggedIn = await ensureLoggedIn(context);
//                     if (!loggedIn) return;
//
//                     final payload = {
//                       "companions": companions,
//                       "email": email,
//                       "group": group,
//                       "menu": menu,
//                       "name": name,
//                       "seat_number": seat,
//                       "status": "Pending",
//                       "type": type,
//                       "phone_number": phoneNumber,
//                     };
//                       print(payload);
//                     await addGuest(payload);
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFFF69B4),foregroundColor: Colors.white
//                   ),
//                   child: const Text('Save Guest'),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//
//   // ---------------- UI Build ----------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4), // Hot Pink
//               Color(0xFFFFB6C1), // Light Pink
//               Colors.white,      // White
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Custom AppBar
//               Container(
//                 color: Colors.transparent, // Gradient shows behind AppBar
//                 child: Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           IconButton(
//                             icon: const Icon(Icons.arrow_back, color: Colors.white),
//                             onPressed: () => Navigator.pop(context),
//                           ),
//                           const Text(
//                             'Guest List',
//                             style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 20),
//                           ),
//                           Row(
//                             children: [
//                               IconButton(
//                                 icon: const Icon(Icons.group_add, color: Colors.white),
//                                 onPressed: _showCreateGroupDialog,
//                               ),
//                               IconButton(
//                                 icon: const Icon(Icons.more_vert, color: Colors.white),
//                                 onPressed: _showOptionsMenu,
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     // TabBar
//                     Container(
//                       color: Colors.transparent,
//                       child: TabBar(
//                         controller: _tabController,
//                         labelColor: Colors.white,
//                         unselectedLabelColor: Colors.white70,
//                         indicatorColor: Colors.white,
//                         onTap: (index) => setState(() {}),
//                         tabs: [
//                           Tab(text: 'All (${_allGuests.length})'),
//                           Tab(text: 'Attending ($_totalAccepted)'),
//                           Tab(text: 'Pending ($_totalPending)'),
//                           Tab(text: 'Not Attending ($_totalDeclined)'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               // Body content
//               Expanded(
//                 child: _isLoading
//                     ? const Center(
//                     child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
//                     : Column(
//                   children: [
//                     _buildStatsCard(),
//                     _buildSearchAndCreateRow(),
//                     Expanded(
//                       child: TabBarView(
//                         controller: _tabController,
//                         children: List.generate(4, (index) => _buildGuestList()),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           final loggedIn = await ensureLoggedIn(context);
//           if (!loggedIn) return;
//           _showAddGuestDialog();
//         },
//         backgroundColor: const Color(0xFFFF69B4),
//         icon: const Icon(Icons.add,color: Colors.white,),
//             label: const Text('Add Guest',style: TextStyle(color: Colors.white),),
//       ),
//     );
//   }
//
//
//   Widget _buildStatsCard() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(colors: [Color(0xFFFF69B4), Color(0xFF9B7EF5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [BoxShadow(color: const Color(0xFFFF69B4).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatItem('Guests', '$_totalGuests', Icons.people),
//           _buildStatItem('Attending', '$_totalAccepted', Icons.check_circle),
//           _buildStatItem('Pending', '$_totalPending', Icons.schedule),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatItem(String label, String value, IconData icon) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.white, size: 20),
//         const SizedBox(height: 6),
//         Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
//         Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
//       ],
//     );
//   }
//
//   Widget _buildSearchAndCreateRow() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.05),
//                     blurRadius: 8,
//                     offset: const Offset(0, 2),
//                   )
//                 ],
//               ),
//               child: TextField(
//                 onChanged: (v) => setState(() => _searchQuery = v),
//                 decoration: InputDecoration(
//                   prefixIcon: Padding(
//                     padding: const EdgeInsets.only(left: 12, right: 8),
//                     child: Icon(Icons.search, color: Colors.pink),
//                   ),
//                   prefixIconConstraints: const BoxConstraints(
//                     minWidth: 0,
//                     minHeight: 0,
//                   ),
//                   hintText: 'Search guests...',
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
//                 ),
//               ),
//             ),
//           ),
//
//           // const SizedBox(width: 12),
//           // ElevatedButton.icon(
//           //   onPressed: () => _showAddGuestDialog(),
//           //   icon: const Icon(Icons.person_add_alt_1),
//           //   label: const Text('Add Guest'),
//           //   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF69B4),foregroundColor: Colors.white),
//           // ),
//           const SizedBox(width: 8),
//           OutlinedButton.icon(
//             onPressed: _showCreateGroupDialog,
//             icon: const Icon(Icons.group,color: Colors.black,),
//             label: const Text('Create Group',style: TextStyle(color: Colors.black),),
//             style: OutlinedButton.styleFrom(
//               foregroundColor: Colors.white, // ✅ sets text & icon color to white
//               side: const BorderSide(color: Colors.pink), // optional: white border
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildGuestList() {
//     final guests = _filteredGuests;
//
//     return RefreshIndicator(
//       color: Color(0xFFFF69B4),
//       onRefresh: () async {
//         await fetchGuests();
//       },
//       child: guests.isEmpty
//           ? ListView(
//         children: [
//           SizedBox(
//             height: 400,
//             child: Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.people_outline,
//                       size: 80, color: Colors.grey),
//                   SizedBox(height: 12),
//                   Text("No guests found",
//                       style: TextStyle(
//                           fontSize: 18, color: Colors.grey)),
//                 ],
//               ),
//             ),
//           )
//         ],
//       )
//           : ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: guests.length,
//         itemBuilder: (context, index) =>
//             _buildGuestCard(guests[index]),
//       ),
//     );
//   }
//
//
//   Widget _buildGuestCard(Guest guest) {
//     final statusLower = guest.status.toLowerCase();
//     Color statusColor;
//     IconData statusIcon;
//
//     switch (statusLower) {
//       case 'attending':
//         statusColor = Colors.green;
//         statusIcon = Icons.check_circle;
//         break;
//       case 'not attending':
//         statusColor = Colors.red;
//         statusIcon = Icons.cancel;
//         break;
//       default:
//         statusColor = Colors.orange;
//         statusIcon = Icons.schedule;
//     }
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         onTap: () async {
//           final updated = await Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => GuestDetailsScreen(guest: guest),
//             ),
//           );
//
//           if (updated == true) setState(() {});
//         },
//
//         contentPadding: const EdgeInsets.all(16),
//
//         // ---------------------------------------------
//         // Avatar
//         // ---------------------------------------------
//         leading: CircleAvatar(
//           backgroundColor: const Color(0xFFFF69B4).withValues(alpha: 0.12),
//           child: Text(
//             guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
//             style: const TextStyle(
//               color: Color(0xFFFF69B4),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//
//         // ---------------------------------------------
//         // Title + Status
//         // ---------------------------------------------
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 guest.name,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: statusColor.withValues(alpha: 0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(statusIcon, size: 14, color: statusColor),
//                   const SizedBox(width: 6),
//                   Text(
//                     guest.status.toUpperCase(),
//                     style: TextStyle(
//                       color: statusColor,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//
//         // ---------------------------------------------
//         // Subtitle Content
//         // ---------------------------------------------
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 8),
//
//             // Email
//             if (guest.email.isNotEmpty)
//               Row(
//                 children: [
//                   Icon(Icons.email, size: 14, color: Colors.grey[600]),
//                   const SizedBox(width: 6),
//                   Text(
//                     guest.email,
//                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                   ),
//                 ],
//               ),
//
//             const SizedBox(height: 6),
//
//             // Group + Companions
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     guest.group,
//                     style: const TextStyle(
//                       color: Colors.blue,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.pink.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     '+${guest.companions}',
//                     style: const TextStyle(
//                       color: Colors.pink,
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//
//             // Seat
//             if (guest.seatNumber.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(top: 6),
//                 child: Text(
//                   'Seat/Table: ${guest.seatNumber}',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ),
//
//             // Meal
//             if (guest.menu.isNotEmpty)
//               Text(
//                 'Meal: ${guest.menu}',
//                 style: const TextStyle(fontSize: 12),
//               ),
//
//             const SizedBox(height: 10),
//
//             // ---------------------------------------------
//             // Action Icons Row
//             // ---------------------------------------------
//             Row(
//               children: [
//                 // EMAIL
//                 IconButton(
//                   icon: const Icon(Icons.email_outlined, color: Colors.blue),
//                   onPressed: () async {
//                     if (!await ensureUserReady(context)) return;
//
//                     final prefs = await SharedPreferences.getInstance();
//                     final int? userId = prefs.getInt('user_id');
//
//                     if (userId == null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text("Please login again")),
//                       );
//                       return;
//                     }
//
//                     await sendGuestEmail(
//                       toEmail: guest.email,
//                       subject: "Wedding Invitation",
//                       message: "Dear ${guest.name}, you are invited 💖",
//                       userId: userId,
//                       context: context,
//                     );
//                   },
//                 ),
//
//
//
//                 // WHATSAPP
//                 IconButton(
//                   icon: const Icon(Icons.sms, color: Colors.green),
//                   onPressed: () async {
//                     if (!await ensureUserReady(context)) return;
//                     sendWhatsApp(guest.phoneNumber);
//                   },
//
//
//                 ),
//
//                 // E-INVITE
//                 IconButton(
//                   icon: const Icon(Icons.card_giftcard, color: Colors.pink),
//                   onPressed: () {
//                     // sendInvite(guest);
//                   },
//                 ),
//               ],
//             ),
//
//             // ---------------------------------------------
//             // Delete Button
//             // ---------------------------------------------
//             Align(
//               alignment: Alignment.bottomRight,
//               child: TextButton.icon(
//                 icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
//                 label: const Text("Delete", style: TextStyle(color: Colors.red)),
//                 onPressed: () async {
//                   final confirm = await showDialog<bool>(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: const Text("Confirm Delete"),
//                       content: Text("Are you sure you want to delete ${guest.name}?"),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context, false),
//                           child: const Text("Cancel"),
//                         ),
//                         ElevatedButton(
//                           onPressed: () => Navigator.pop(context, true),
//                           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                           child: const Text("Delete"),
//                         ),
//                       ],
//                     ),
//                   );
//
//                   if (confirm == true && guest.id != null) {
//                     await deleteGuest(guest.id!);
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> sendGuestEmail({
//     required String toEmail,
//     required String message,
//     required String subject,
//     required int userId,
//     required BuildContext context,
//   }) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("auth_token");
//
//       if (token == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please login again")),
//         );
//         return;
//       }
//
//       final url = Uri.parse("https://happywedz.com/api/guestlist/send-guestlist-email");
//
//       final body = {
//         "toEmail": [toEmail],
//         "message": message,
//         "subject": subject,
//         "userId": userId.toString(),
//       };
//
//       final response = await http.post(
//         url,
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: jsonEncode(body),
//       );
//
//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Email sent successfully!")),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed: ${response.body}")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $e")),
//       );
//     }
//   }
//
//
//   void _showOptionsMenu() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(mainAxisSize: MainAxisSize.min, children: [
//           ListTile(leading: const Icon(Icons.upload_file), title: const Text('Import from CSV'), onTap: () => Navigator.pop(context)),
//           ListTile(leading: const Icon(Icons.download), title: const Text('Export Guest List'), onTap: () => Navigator.pop(context)),
//           ListTile(leading: const Icon(Icons.email), title: const Text('Send Bulk Email'), onTap: () => Navigator.pop(context)),
//         ]),
//       ),
//     );
//   }
//
//   // ---------------- Launch helpers ----------------
//   void _launchWhatsApp(String phone) async {
//     if (phone.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
//       return;
//     }
//     final whatsappUrl = Uri.parse("https://wa.me/$phone?text=Hello!");
//     if (await canLaunchUrl(whatsappUrl)) {
//       await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open WhatsApp")));
//     }
//   }
//
//   void _launchEmail(String email) async {
//     if (email.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email available')));
//       return;
//     }
//     final emailUrl = Uri.parse("mailto:$email?subject=Hello&body=Hi!");
//     if (await canLaunchUrl(emailUrl)) {
//       await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Email app")));
//     }
//   }
// }
//
//
// class GuestDetailsScreen extends StatefulWidget {
//   final Guest guest;
//
//   const GuestDetailsScreen({Key? key, required this.guest}) : super(key: key);
//
//   @override
//   State<GuestDetailsScreen> createState() => _GuestDetailsScreenState();
// }
//
// class _GuestDetailsScreenState extends State<GuestDetailsScreen> {
//   String selectedStatus = "";
//   bool isUpdating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     selectedStatus = widget.guest.status; // initial value
//   }
//
//
//
//   Future<void> updateGuestStatus(String newStatus) async {
//     setState(() => isUpdating = true);
//
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("auth_token");
//
//     if (token == null) return;
//
//     final url =
//         "https://happywedz.com/api/guestlist/${widget.guest.id}";
//
//     print("📤 PUT $url");
//     print("📦 Payload: {status: $newStatus}");
//
//     final response = await http.put(
//       Uri.parse(url),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//         "Accept": "application/json"
//       },
//       body: jsonEncode({"status": newStatus}),
//     );
//
//     print("🔹 Status: ${response.statusCode}");
//     print("🔸 Body: ${response.body}");
//
//     if (response.statusCode == 200) {
//       setState(() {
//         selectedStatus = newStatus;
//         widget.guest.status = newStatus;   // update local model
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("✅ Status updated"),
//           backgroundColor: Colors.green,
//         ),
//       );
//
//       Navigator.pop(context, true); // ✅ pass `true` back to list screen
//     }
//     else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("❌ Failed: ${response.statusCode}"),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//
//     setState(() => isUpdating = false);
//   }
//
//
//
//   @override
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         title: Text(
//           widget.guest.name,
//           style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//
//       body: Container(
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),
//               Color(0xFFFFB6C1),
//               Colors.white,
//             ],
//             stops: [0.0, 0.35, 0.8],
//           ),
//         ),
//         child: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               children: [
//
//                 // Avatar
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundColor: Colors.white.withValues(alpha: 0.3),
//                   child: Text(
//                     widget.guest.name.isNotEmpty
//                         ? widget.guest.name[0].toUpperCase()
//                         : "?",
//                     style: const TextStyle(
//                       fontSize: 40,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 14),
//
//                 Text(
//                   widget.guest.name,
//                   style: const TextStyle(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//
//                 const SizedBox(height: 6),
//
//                 Text(
//                   widget.guest.email,
//                   style: const TextStyle(fontSize: 15, color: Colors.white70),
//                 ),
//
//
//                 const SizedBox(height: 6),
//
//                 Text(
//                   widget.guest.phoneNumber,
//                   style: const TextStyle(fontSize: 15, color: Colors.white70),
//                 ),
//
//
//                 const SizedBox(height: 20),
//
//                 // DETAILS CARD
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(18),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(18),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withValues(alpha: 0.08),
//                         blurRadius: 10,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     children: [
//                       _detailTile(Icons.group, "Group", widget.guest.group),
//                       _detailTile(Icons.person_outline, "Type", widget.guest.type),
//                       _detailTile(Icons.fastfood, "Meal", widget.guest.menu),
//                       _detailTile(Icons.people_alt, "Companions",
//                           widget.guest.companions.toString()),
//                       _detailTile(Icons.event_seat, "Seat Number",
//                           widget.guest.seatNumber),
//                       _detailTile(Icons.tag, "User ID",
//                           widget.guest.userId.toString()),
//
//                       const SizedBox(height: 10),
//
//                       /// STATUS + DROPDOWN
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             "Status",
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.grey,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.pinkAccent),
//                             ),
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButton<String>(
//                                 value: selectedStatus,
//                                 items: const [
//                                   DropdownMenuItem(
//                                       value: "Pending", child: Text("Pending")),
//                                   DropdownMenuItem(
//                                       value: "Attending",
//                                       child: Text("Attending")),
//                                   DropdownMenuItem(
//                                       value: "Not Attending", child: Text("Not Attending")),
//                                 ],
//                                 onChanged: isUpdating
//                                     ? null
//                                     : (value) {
//                                   if (value != null) {
//                                     updateGuestStatus(value);
//                                   }
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//
//                       const SizedBox(height: 12),
//
//                       if (widget.guest.createdAt != null)
//                         _detailTile(Icons.calendar_month, "Created",
//                             widget.guest.createdAt.toString()),
//
//                       if (widget.guest.updatedAt != null)
//                         _detailTile(Icons.update, "Updated",
//                             widget.guest.updatedAt.toString()),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 25),
//               ],
//             ),
//           ),
//         ),
//       ),
//
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ElevatedButton(
//           onPressed: () => Navigator.pop(context),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.pinkAccent,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//           child: const Text(
//             "Close",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.white, // ✅ white text color added
//             ),
//           ),
//
//         ),
//       ),
//     );
//   }
//
//
//   // =======================================================
//   //   DETAIL TILE
//   // =======================================================
//   Widget _detailTile(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.pink.withValues(alpha: 0.15),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, color: Colors.pink, size: 22),
//           ),
//           const SizedBox(width: 14),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   label,
//                   style: const TextStyle(
//                     fontSize: 13,
//                     color: Colors.grey,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Text(
//                   value,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
// }
//
//
//
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:happy_wedz/core/config/api_config.dart';

import '../authservice.dart';
import '../main.dart';
import '../profile.dart';

/// ----------------------------------
/// SHARED ENUMS — must match the website exactly
/// ----------------------------------
/// The website's `statusOptions` / `typeOptions` / `menuOptions`
/// (`Guests.jsx:72-74`). These are compared by exact string on both
/// platforms — the space in "Not Attending" is load-bearing.
const List<String> kGuestStatusOptions = [
  'Attending',
  'Not Attending',
  'Pending',
];

const List<String> kGuestTypeOptions = ['Adult', 'Child'];

/// AUDIT FIX: the app previously offered only Veg / NonVeg / All. A guest
/// created on the website as "Jain", "Vegan" or "Eggetarian" therefore had a
/// menu value that no DropdownMenuItem matched, which throws
/// "There should be exactly one item with DropdownButton's value".
const List<String> kGuestMenuOptions = [
  'Veg',
  'NonVeg',
  'Jain',
  'Vegan',
  'Eggetarian',
  'All',
];

/// Coerces whatever the API returns onto one of [options]. Guards every
/// dropdown on this screen: an unrecognised value would otherwise assert.
String normalizeGuestOption(String? raw, List<String> options, String fallback) {
  if (raw == null) return fallback;
  final trimmed = raw.trim();
  for (final option in options) {
    if (option.toLowerCase() == trimmed.toLowerCase()) return option;
  }
  return fallback;
}

/// ----------------------------------
/// GROUP MODEL — `GET /groups`
/// ----------------------------------
class GuestGroup {
  final String id;
  final String name;

  const GuestGroup({required this.id, required this.name});

  factory GuestGroup.fromJson(Map json) => GuestGroup(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

/// ----------------------------------
/// GUEST MODEL
/// ----------------------------------
class Guest {
  final int? id;
  final String name;

  /// Legacy free-text group label. Written only by the website's bulk import,
  /// which sets `city` and `group` to the same string.
  final String group;

  /// The website's bulk import writes the group name here too, and its display
  /// fallback ranks `city` ABOVE `groupId` — so this has to be read, or a
  /// bulk-imported guest buckets differently in the app than on the web.
  final String city;

  /// Name of the eager-loaded `groupData` relation, when the API sends one.
  final String groupDataName;

  /// FK into `GET /groups`. Kept as a String so a numeric or string id from
  /// the API compares consistently — the website's strict `===` on this is a
  /// known source of guests silently falling into "Other".
  final String groupId;

  String status;
  final int companions;
  final String type;
  final String menu;
  final String phoneNumber;
  final String email;
  final String seatNumber;

  Guest({
    this.id,
    required this.name,
    required this.group,
    required this.status,
    required this.companions,
    required this.type,
    required this.menu,
    required this.phoneNumber,
    required this.email,
    this.seatNumber = '',
    this.city = '',
    this.groupDataName = '',
    this.groupId = '',
  });

  /// AUDIT FIX: every field used to be an unguarded implicit cast —
  /// `json['companions'] ?? 0` into a non-nullable `int` throws if the API
  /// ever sends `"2"`, and that throw happened inside `.map()` in
  /// `fetchGuests`, so one odd row turned the whole list into a generic
  /// error. Every field is now coerced.
  factory Guest.fromJson(Map<String, dynamic> json) {
    final groupData = json['groupData'];
    return Guest(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      group: json['group']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      groupDataName: groupData is Map
          ? (groupData['name']?.toString() ?? '')
          : '',
      groupId: json['groupId']?.toString() ?? '',
      status: normalizeGuestOption(
        json['status']?.toString(),
        kGuestStatusOptions,
        'Pending',
      ),
      companions: _asInt(json['companions']) ?? 0,
      type: normalizeGuestOption(
        json['type']?.toString(),
        kGuestTypeOptions,
        'Adult',
      ),
      menu: normalizeGuestOption(
        json['menu']?.toString(),
        kGuestMenuOptions,
        'Veg',
      ),
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      // Was previously sent on create but never parsed back, so it silently
      // vanished from the app the moment the list re-fetched.
      seatNumber: json['seat_number']?.toString() ?? '',
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// The edit body the website sends (`Guests.jsx:402-416`): 9 fields, with
  /// `groupId` sent as null when unset (unlike create, which omits the key).
  Map<String, dynamic> toUpdateJson() => {
        'name': name.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
        'phone_number':
            phoneNumber.trim().isEmpty ? null : phoneNumber.trim(),
        'groupId': groupId.isEmpty ? null : groupId,
        'status': status,
        'type': type,
        'menu': menu,
        'companions': companions,
        'seat_number': seatNumber.trim().isEmpty ? null : seatNumber.trim(),
      };
}


/// ----------------------------------
/// MAIN SCREEN
/// ----------------------------------
class GuestListDashboard extends StatefulWidget {
  const GuestListDashboard({Key? key, this.debugInitialGuests})
      : super(key: key);

  /// Seeds the list and skips the initial fetch.
  ///
  /// Exists purely as a testing seam. Without it the screen can only ever be
  /// rendered empty in a widget test — every request fails in the test
  /// binding — which meant the layout tests were passing at 320px while the
  /// guest *card* itself overflowed, because no card was ever built.
  @visibleForTesting
  final List<Guest>? debugInitialGuests;

  @override
  State<GuestListDashboard> createState() => _GuestListDashboardState();
}

class _GuestListDashboardState extends State<GuestListDashboard> {

  Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();

    final mobile = prefs.getString('user_mobile');
    final venue = prefs.getString('wedding_venue');
    final date = prefs.getString('wedding_date');

    return mobile != null && mobile.isNotEmpty &&
        venue != null && venue.isNotEmpty &&
        date != null && date.isNotEmpty;
  }
  /// Auth only — what adding, editing, deleting and RSVP-ing actually need.
  ///
  /// AUDIT FIX: these all used to go through [ensureUserReady], which also
  /// demands a complete profile (mobile + venue + wedding date) and pushes
  /// Profile Settings when anything is missing. Combined with the broken
  /// profile fetch in `main.dart` — which hit a 404 and so never wrote those
  /// three keys — that check could never pass, and a signed-in user was sent
  /// to Profile Settings every time they tapped Add Guest.
  ///
  /// The website gates its guest list on authentication alone
  /// (`UserPrivateRoute`); there is no profile-completeness requirement
  /// anywhere in `Guests.jsx`. Managing a guest list plainly does not need a
  /// venue, so this now matches.
  Future<bool> ensureSignedIn(BuildContext context) async {
    return ensureLoggedIn(context);
  }

  /// Auth **plus** a complete profile. Kept only for the two actions that
  /// genuinely embed the wedding details in what they send: the WhatsApp and
  /// Email invitations. A guest is prompted to fill those in once, rather
  /// than being blocked from every action on the screen.
  Future<bool> ensureUserReady(BuildContext context) async {
    // Session first — AuthGate takes over and shows login if it has gone.
    if (!await ensureLoggedIn(context)) return false;
    if (!context.mounted) return false;

    final complete = await isProfileComplete();
    // There is a `context.mounted` check above, but it is before this await —
    // the screen can be gone by the time the prefs read returns.
    if (!context.mounted) return false;

    if (!complete) {
      // Ask, rather than showing a snackbar and pushing a route in the same
      // frame. That combination inserts into the overlay while a route
      // transition is starting on it, and it swapped the screen out from
      // under the user with no way to decline.
      final goToProfile = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Add your wedding details'),
          content: const Text(
            'Invitations include your wedding date and venue. Add them to '
            'your profile first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Add details'),
            ),
          ],
        ),
      );

      if (goToProfile == true && context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
        );
      }
      return false;
    }

    return true; // ✅ Profile complete → proceed
  }
  // Future<bool> ensureUserReady(BuildContext context) async {
  //   final prefs = await SharedPreferences.getInstance();
  //
  //   final token = prefs.getString('auth_token');
  //   final profileDone = prefs.getBool('profile_completed') ?? false;
  //
  //   if (token == null) {
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (_) => const SignInScreen()),
  //     );
  //     return false;
  //   }
  //
  //   if (!profileDone) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
  //     );
  //     return false;
  //   }
  //
  //   return true;
  // }

  List<Guest> guests = [];
  bool isLoading = false;

  /// AUDIT FIX: holds the last failure from [fetchGuests] so the body can show
  /// a real error with a retry instead of the misleading "No guests found".
  Object? _loadError;

  Set<int> selectedGuestIds = {};

  /// Persisted groups from `GET /groups`, the same entity the website's
  /// group dropdown is built from.
  List<GuestGroup> availableGroups = [];

  /// Search + filter state. All three are applied client-side, exactly as the
  /// website does — the list endpoint takes no query parameters.
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  String _selectedGroup = 'All';
  String _selectedStatus = 'All';

  /// Guest ids with a mutation in flight, so a row can disable its own
  /// controls without freezing the list.
  final Set<int> _busyGuestIds = {};

  bool _isGeneratingPdf = false;
  bool _isPrinting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// AUDIT FIX (blank invitations): this read `family_name`, `bride_name`,
  /// `groom_name` and `venue` — **none of which is written anywhere in the
  /// app**. Verified by a repo-wide grep: the only writes are
  /// `wedding_venue`, `wedding_date` and `user_mobile` (`main.dart:490-492`,
  /// `profile.dart:302-304`). Every WhatsApp and email invitation therefore
  /// went out with an empty bride, groom and venue, and the literal word
  /// "Our" as the family name. Note `isProfileComplete()` in this same class
  /// already used the correct `wedding_venue` key.
  ///
  /// Bride/groom have no stored field anywhere in the app, so rather than
  /// print an empty "💍 *&*" line the invite builder now omits what it does
  /// not have (see [buildWeddingInvite]).
  Future<Map<String, String>> _getWeddingDetails() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'family': prefs.getString(UserPrefs.userNameKey) ?? '',
      'bride': prefs.getString('bride_name') ?? '',
      'groom': prefs.getString('groom_name') ?? '',
      'date': prefs.getString(UserPrefs.weddingDateKey) ?? '',
      'venue': prefs.getString(UserPrefs.weddingVenueKey) ?? '',
    };
  }

  /// The website's 5-level group-name fallback (`Guests.jsx:199-213`):
  /// city → group → groupData.name → lookup groupId in /groups → "Other".
  /// Ported verbatim so a guest buckets under the same heading on both
  /// platforms, with one deliberate fix: the id comparison is done on
  /// strings, because the web's strict `===` silently drops every guest into
  /// "Other" whenever the API types `id` and `groupId` differently.
  String guestGroupName(Guest g) {
    if (g.city.trim().isNotEmpty) return g.city.trim();
    if (g.group.trim().isNotEmpty) return g.group.trim();
    if (g.groupDataName.trim().isNotEmpty) return g.groupDataName.trim();
    if (g.groupId.isNotEmpty) {
      for (final group in availableGroups) {
        if (group.id == g.groupId && group.name.isNotEmpty) return group.name;
      }
    }
    return 'Other';
  }

  /// Search + group filter + status filter, ANDed — same as the website's
  /// `filteredAndGroupedGuests` memo.
  List<Guest> get _filteredGuests {
    final term = _searchTerm.trim().toLowerCase();
    return guests.where((g) {
      final groupName = guestGroupName(g);

      if (_selectedGroup != 'All' &&
          groupName.toLowerCase() != _selectedGroup.toLowerCase()) {
        return false;
      }
      if (_selectedStatus != 'All' && g.status != _selectedStatus) {
        return false;
      }
      if (term.isEmpty) return true;

      // The website searches name, derived group name and phone. Phone is
      // matched on digits only so "9876543210" finds "+91 98765 43210",
      // which the web's raw `includes` misses.
      final digits = term.replaceAll(RegExp(r'[^0-9]'), '');
      return g.name.toLowerCase().contains(term) ||
          groupName.toLowerCase().contains(term) ||
          g.email.toLowerCase().contains(term) ||
          (digits.isNotEmpty &&
              g.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '').contains(digits));
    }).toList();
  }

  /// Every group heading present in the data, plus the ones defined server
  /// side. The website builds its filter only from `/groups`, so a bulk
  /// imported `city` shows as a heading but can never be filtered to.
  List<String> get _groupFilterOptions {
    final names = <String>{};
    for (final g in guests) {
      names.add(guestGroupName(g));
    }
    for (final group in availableGroups) {
      if (group.name.isNotEmpty) names.add(group.name);
    }
    final sorted = names.toList()..sort();
    return ['All', ...sorted];
  }

  Widget _buildGuestCard(Guest guest) {
    final statusColor = guest.status == "Attending"
        ? Colors.green
        : guest.status == "Not Attending"
        ? Colors.red
        : Colors.orange;
    final busy = guest.id != null && _busyGuestIds.contains(guest.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox(
          //   value: selectedGuestIds.contains(guest.id),
          //   onChanged: (v) {
          //     setState(() {
          //       v == true
          //           ? selectedGuestIds.add(guest.id!)
          //           : selectedGuestIds.remove(guest.id);
          //     });
          //   },
          // ),

          /// HEADER
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.pink.withValues(alpha: 0.15),
                // AUDIT FIX: this was `guest.name[0]`, which throws a
                // RangeError on an empty name — and `fromJson` defaults name
                // to '' while the add form accepted whitespace-only input, so
                // one blank name crashed the entire list.
                child: Text(
                  guest.name.trim().isEmpty
                      ? '?'
                      : guest.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.pink, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  guest.name.trim().isEmpty ? 'Unnamed guest' : guest.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              // AUDIT FIX (overflow): an unconstrained pill next to an
              // Expanded name. "Not Attending" at the 1.2x text-scale clamp
              // is wide enough to push this row past a 320px card. Flexible
              // lets it give way instead of overflowing.
              Flexible(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    guest.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// INFO ROW — type and menu are editable in place, matching the
          /// website's inline row dropdowns.
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _infoChip("Group", guestGroupName(guest)),
              _inlinePicker(
                label: "Type",
                value: guest.type,
                options: kGuestTypeOptions,
                busy: busy,
                onChanged: (v) => _changeGuestField(guest, 'type', v),
              ),
              _inlinePicker(
                label: "Menu",
                value: guest.menu,
                options: kGuestMenuOptions,
                busy: busy,
                onChanged: (v) => _changeGuestField(guest, 'menu', v),
              ),
              _infoChip("Companions", guest.companions.toString()),
              if (guest.seatNumber.isNotEmpty)
                _infoChip("Seat", guest.seatNumber),
            ],
          ),

          const SizedBox(height: 10),

          /// PHONE
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(guest.phoneNumber,
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const Divider(height: 24),

          /// ACTIONS
          ///
          /// AUDIT FIX (overflow): the dropdown used to be a hard
          /// `SizedBox(width: 140)` followed by a `Spacer()` and four
          /// full-size `IconButton`s (48px each). That is ~332px of fixed
          /// content, which overflows a card on any 320px-wide phone — and it
          /// tipped over when the Edit button and the busy spinner were
          /// added. The dropdown is now `Expanded` so it absorbs the slack
          /// and shrinks when there isn't any, and the icons are compact.
          Row(
            children: [
              /// STATUS DROPDOWN — the value is normalized in `fromJson`, so
              /// it always matches one of the items and can never assert.
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: guest.status,
                    isExpanded: true,
                    items: kGuestStatusOptions
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) {
                            if (v == null) return;
                            _changeGuestField(guest, 'status', v);
                          },
                  ),
                ),
              ),

              if (busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),

              _cardActionButton(
                tooltip: "Edit",
                icon: const Icon(Icons.edit_outlined,
                    color: Colors.pink, size: 20),
                onPressed: busy ? null : () => _openEditGuest(guest),
              ),

              _cardActionButton(
                tooltip: "WhatsApp",
                icon: Image.asset(
                  'assets/whatsapp.png',
                  width: 20,
                  height: 20,
                ),
                onPressed: () async {
                  if (!await ensureUserReady(context)) return;
                  await sendWhatsApp(guest: guest);
                },
              ),

              _cardActionButton(
                tooltip: "Email",
                icon: const Icon(Icons.email_outlined,
                    color: Colors.blue, size: 20),
                onPressed: () async {
                  if (!await ensureUserReady(context)) return;

                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getInt(UserPrefs.userIdKey);
                  if (userId == null) return;

                  final details = await _getWeddingDetails();
                  if (!mounted) return;

                  final emailMessage = buildWeddingInvite(
                    familyName: details['family']!,
                    brideName: details['bride']!,
                    groomName: details['groom']!,
                    date: details['date']!,
                    venue: details['venue']!,
                    guestName: guest.name,
                  );

                  // Subject degrades with the data: the couple's names are
                  // not stored anywhere in the app, so "Wedding Invitation –
                  //  & " was the old, always-broken result.
                  final couple = [details['bride']!, details['groom']!]
                      .where((n) => n.trim().isNotEmpty)
                      .join(' & ');

                  await sendGuestEmail(
                    toEmail: guest.email,
                    subject: couple.isEmpty
                        ? "Wedding Invitation"
                        : "Wedding Invitation – $couple",
                    message: emailMessage,
                    userId: userId,
                  );
                },
              ),

              _cardActionButton(
                tooltip: "Delete",
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                // AUDIT FIX: was `deleteGuest(guest.id!)` — a force-unwrap
                // that crashes on a guest with no id, fired immediately with
                // no confirmation and no undo.
                onPressed: busy || guest.id == null
                    ? null
                    : () => _confirmDeleteGuest(guest),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  void initState() {
    super.initState();

    final seeded = widget.debugInitialGuests;
    if (seeded != null) {
      guests = List.of(seeded);
      return;
    }

    // Groups first: the group-name fallback resolves `groupId` against this
    // list, so loading it after the guests would render them as "Other" for
    // a frame.
    fetchGroups();
    fetchGuests();
  }

  /// AUDIT FIX (infinite loader + no error state): this method had **no
  /// try/catch at all**. `http.get` throws on a dropped connection, a DNS
  /// failure or a timeout, and that exception escaped past the final
  /// `setState(() => isLoading = false)` — so `isLoading` stayed `true` and the
  /// guest list sat on its shimmer forever, with no message and no way to
  /// retry. A non-200 response was equally silent: the screen fell through to
  /// "No guests found", telling the user their guest list was empty when the
  /// request had actually failed.
  ///
  /// The request itself, its URL, headers and parsing are unchanged.
  Future<void> fetchGuests() async {
    setState(() {
      isLoading = true;
      _loadError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token");
      final userId = prefs.getInt("user_id");
      if (!mounted) return;

      if (token == null || userId == null) {
        // Not signed in: AuthGate handles routing, so just stop loading.
        setState(() => isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.apiBase}/guestlist/user/$userId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );
      if (!mounted) return;

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        final List list = data["guests"] ?? [];

        setState(() {
          guests = list.map((e) => Guest.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('fetchGuests failed: $e');
      if (!mounted) return;
      setState(() => _loadError = e);
    } finally {
      // Guarded: runs on every exit path, and the screen may already be gone.
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// AUDIT FIX: this used to interpolate every value unconditionally, and
  /// because bride/groom/venue were read from prefs keys nothing ever wrote,
  /// every invitation went out reading literally
  /// "the *Our family* ... 💍 ** & ** ... 📍 *Venue:*".
  ///
  /// Each line is now emitted only when there is something to put in it, so
  /// a missing field means a shorter invite rather than a broken one.
  String buildWeddingInvite({
    required String familyName,
    required String brideName,
    required String groomName,
    required String date,
    required String venue,
    required String guestName,
  }) {
    final buffer = StringBuffer('🌸 Wedding Invitation 🌸\n\n');

    final couple = [brideName.trim(), groomName.trim()]
        .where((n) => n.isNotEmpty)
        .join(' & ');

    if (familyName.trim().isNotEmpty) {
      buffer.writeln('We, the *${familyName.trim()} family*,');
      buffer.writeln('warmly invite you to celebrate with us');
    } else {
      buffer.writeln('We warmly invite you to celebrate with us');
    }

    if (couple.isNotEmpty) {
      buffer.writeln('\n💍 *$couple*');
    }
    if (date.trim().isNotEmpty) {
      buffer.writeln('\n📅 *Date:* ${date.trim()}');
    }
    if (venue.trim().isNotEmpty) {
      buffer.writeln('📍 *Venue:* ${venue.trim()}');
    }

    final greeting = guestName.trim().isEmpty ? 'Hello' : 'Dear ${guestName.trim()}';
    buffer.writeln('\n$greeting,');
    buffer.writeln('Your presence will truly make our celebration special.');

    buffer.writeln('\nWith love,');
    buffer.writeln(
      familyName.trim().isEmpty ? 'The family' : '${familyName.trim()} Family',
    );

    return buffer.toString();
  }


  Future<void> sendWhatsApp({required Guest guest}) async {
    // Same corrected keys as `_getWeddingDetails` — these previously read
    // `family_name` / `bride_name` / `groom_name` / `venue`, none of which
    // the app ever writes.
    final details = await _getWeddingDetails();

    final phone =
    guest.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      if (mounted) {
        AppSnackbar.warning(context, 'This guest has no phone number.');
      }
      return;
    }

    final message = buildWeddingInvite(
      familyName: details['family']!,
      brideName: details['bride']!,
      groomName: details['groom']!,
      date: details['date']!,
      venue: details['venue']!,
      guestName: guest.name,
    );

    final encodedMessage = Uri.encodeComponent(message);

    final uri = Uri.parse(
      "https://wa.me/$phone?text=$encodedMessage",
    );

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('WhatsApp launch failed: $e');
      if (!mounted) return;
      AppSnackbar.error(context, "We couldn't open WhatsApp on this device.");
    }
  }


  /// Uses this State's own `context`, not a passed-in one — the caller used
  /// to hand in a `BuildContext` that `mounted` could not vouch for, so every
  /// snackbar here was an unguarded use across an async gap.
  Future<void> sendGuestEmail({
    required String toEmail,
    required String subject,
    required String message,
    required int userId,
  }) async {
    if (toEmail.trim().isEmpty) {
      if (mounted) {
        AppSnackbar.warning(context, 'This guest has no email address.');
      }
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey);
      if (token == null) return;

      final response = await http.post(
        Uri.parse(
          "${ApiConfig.apiBase}/guestlist/send-guestlist-email",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "toEmail": [toEmail.trim()],
          "subject": subject,
          "message": message,
          // The website sends this as a number (`Guests.jsx:606`); the app
          // was stringifying it.
          "userId": userId,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppSnackbar.success(context, 'Email sent.');
      } else {
        // AUDIT FIX: a non-200 used to be completely silent — the user
        // tapped Email, nothing happened, and nothing said why.
        debugPrint('sendGuestEmail failed: HTTP ${response.statusCode}');
        AppSnackbar.error(context, "We couldn't send that email. Please try again.");
      }
    } catch (e) {
      debugPrint('sendGuestEmail error: $e');
      if (!mounted) return;
      AppSnackbar.error(context, "We couldn't send that email. Please try again.");
    }
  }
  /// AUDIT FIX: this had no try/catch and never looked at the response — the
  /// guest was removed from the list whether or not the server accepted it,
  /// so a 500 or a dropped connection silently desynced the app from the
  /// backend with no message. Now optimistic with a real rollback, and the
  /// caller confirms first.
  Future<void> deleteGuest(int guestId) async {
    if (_busyGuestIds.contains(guestId)) return;

    final index = guests.indexWhere((g) => g.id == guestId);
    if (index < 0) return;
    final removed = guests[index];

    setState(() {
      _busyGuestIds.add(guestId);
      guests.removeAt(index);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey);
      if (token == null) throw Exception('No session');

      final res = await http.delete(
        Uri.parse("${ApiConfig.apiBase}/guestlist/$guestId"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception('HTTP ${res.statusCode}');
      }

      if (!mounted) return;
      AppSnackbar.success(context, 'Guest removed.');
    } catch (e) {
      debugPrint('deleteGuest failed: $e');
      if (!mounted) return;
      setState(() {
        guests.insert(index <= guests.length ? index : guests.length, removed);
      });
      AppSnackbar.error(context, "We couldn't remove that guest. Please try again.");
    } finally {
      if (mounted) setState(() => _busyGuestIds.remove(guestId));
    }
  }

  /// Confirmation before a destructive, un-undoable action. The website uses
  /// a native `window.confirm` here; the app had no confirmation at all — one
  /// stray tap deleted a guest outright.
  Future<void> _confirmDeleteGuest(Guest guest) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove guest?'),
        content: Text(
          '${guest.name.trim().isEmpty ? 'This guest' : guest.name} will be '
          'removed from your guest list. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && guest.id != null) {
      await deleteGuest(guest.id!);
    }
  }

  /// `GET /groups` — the persisted group entity the website's group dropdown
  /// is built from. Failure is non-fatal: the group filter and picker fall
  /// back to whatever names the guests themselves carry.
  Future<void> fetchGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey);
      if (token == null) return;

      final res = await http.get(
        Uri.parse("${ApiConfig.apiBase}/groups"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      if (data is! Map || data["success"] != true) return;

      final list = data["groups"];
      if (list is! List) return;

      if (!mounted) return;
      setState(() {
        availableGroups = list
            .whereType<Map>()
            .map(GuestGroup.fromJson)
            .where((g) => g.id.isNotEmpty)
            .toList();
      });
    } catch (e) {
      debugPrint('fetchGroups failed: $e');
    }
  }

  /// Compact icon button for the guest card's action row.
  ///
  /// A default [IconButton] reserves a 48x48 tap target plus 8px padding on
  /// each side. Four of those alongside the status dropdown do not fit on a
  /// 320px phone, which is what overflowed the row. 36x36 still clears the
  /// 36px minimum comfortable target while leaving room for the dropdown.
  Widget _cardActionButton({
    required String tooltip,
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      icon: icon,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      splashRadius: 20,
    );
  }

  /// An `_infoChip` that doubles as a picker — the app's equivalent of the
  /// website's inline `<select>` in each table row.
  Widget _inlinePicker({
    required String label,
    required String value,
    required List<String> options,
    required bool busy,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: busy
                ? null
                : (v) {
                    if (v != null) onChanged(v);
                  },
          ),
        ),
      ],
    );
  }

  /// Opens the shared guest form in edit mode. The form does the `PUT` and
  /// pops `true`, at which point the list is re-read so the row reflects
  /// whatever the server actually stored.
  Future<void> _openEditGuest(Guest guest) async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GuestFormScreen(
          existing: guest,
          availableGroups: availableGroups,
        ),
      ),
    );

    if (saved == true && mounted) {
      await fetchGroups();
      await fetchGuests();
    }
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  /// Sections built from the filtered set, grouped by the resolved group name
  /// and sorted alphabetically — the old code relied on `Map` insertion order,
  /// i.e. whatever order the server happened to return.
  Widget _buildGroupedList() {
    final visible = _filteredGuests;

    if (visible.isEmpty) {
      return const EmptyState(
        title: 'No matching guests',
        message: 'Try a different search or clear your filters.',
        icon: Icons.search_off_rounded,
      );
    }

    final groups = <String, List<Guest>>{};
    for (final g in visible) {
      groups.putIfAbsent(guestGroupName(g), () => []).add(g);
    }

    final sectionNames = groups.keys.toList()..sort();

    // Flattened to header/card rows so the whole thing can go through
    // ListView.builder — the old ListView(children:) built every card eagerly.
    final rows = <Widget>[];
    for (final name in sectionNames) {
      final sectionGuests = groups[name]!;
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "$name (${sectionGuests.length})",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
      rows.addAll(sectionGuests.map(_buildGuestCard));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i],
    );
  }

  /// Single-field `PUT /guestlist/{id}` — the same partial-body shape the
  /// website's inline dropdowns use for status, type and menu
  /// (`Guests.jsx:339-352`).
  ///
  /// AUDIT FIX: the old version discarded the return value entirely — no
  /// status check, no try/catch — and the caller flipped the UI regardless.
  /// A failed request left the row showing a value the server never accepted,
  /// with no error, until the next full refresh.
  Future<bool> _updateGuestField(
    int guestId,
    String field,
    String value,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey);
      if (token == null) return false;

      final res = await http.put(
        Uri.parse("${ApiConfig.apiBase}/guestlist/$guestId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({field: value}),
      );

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('updateGuestField($field) failed: $e');
      return false;
    }
  }

  /// Applies a status / type / menu change optimistically and rolls back if
  /// the server rejects it.
  Future<void> _changeGuestField(
    Guest guest,
    String field,
    String value,
  ) async {
    final id = guest.id;
    if (id == null || _busyGuestIds.contains(id)) return;

    final index = guests.indexWhere((g) => g.id == id);
    if (index < 0) return;
    final previous = guests[index];

    setState(() {
      _busyGuestIds.add(id);
      guests[index] = _guestWithField(previous, field, value);
    });

    final ok = await _updateGuestField(id, field, value);
    if (!mounted) return;

    setState(() {
      _busyGuestIds.remove(id);
      if (!ok) {
        // Re-resolve by id: the list may have been rebuilt by a refresh
        // while the request was in flight, so the captured index can be
        // stale. Writing to a stale index is how the checklist screen
        // corrupts the wrong row.
        final current = guests.indexWhere((g) => g.id == id);
        if (current >= 0) guests[current] = previous;
      }
    });

    if (!ok) {
      AppSnackbar.error(context, "We couldn't update that guest. Please try again.");
    }
  }

  Guest _guestWithField(Guest g, String field, String value) => Guest(
        id: g.id,
        name: g.name,
        group: g.group,
        city: g.city,
        groupDataName: g.groupDataName,
        groupId: g.groupId,
        status: field == 'status' ? value : g.status,
        companions: g.companions,
        type: field == 'type' ? value : g.type,
        menu: field == 'menu' ? value : g.menu,
        phoneNumber: g.phoneNumber,
        email: g.email,
        seatNumber: g.seatNumber,
      );

  /// ----------------------------------
  /// GROUP GUESTS
  /// ----------------------------------
  Map<String, List<Guest>> get groupedGuests {
    final map = <String, List<Guest>>{};
    for (final g in guests) {
      map.putIfAbsent(g.group, () => []).add(g);
    }
    return map;
  }
  int get totalGuests => guests.length;

  /// Actual heads expected: every guest plus their companions.
  ///
  /// Neither platform surfaced this — both count rows only, so a guest with
  /// five companions counted as one and the headline figure was wrong for
  /// anyone with a plus-one. The row count stays the headline (matching the
  /// website) and this is shown beneath it.
  int get totalHeadcount =>
      guests.fold<int>(0, (sum, g) => sum + 1 + g.companions);

  int get totalAdults =>
      guests.where((g) => g.type.toLowerCase() == 'adult').length;

  int get totalChildren =>
      guests.where((g) => g.type.toLowerCase() == 'child').length;

  int get attendingCount =>
      guests.where((g) => g.status == 'Attending').length;

  int get pendingCount =>
      guests.where((g) => g.status == 'Pending').length;

  int get notAttendingCount =>
      guests.where((g) => g.status == 'Not Attending').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Guest List"),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            onPressed: _isGeneratingPdf ? null : _handleDownloadPdf,
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Print',
            onPressed: _isPrinting ? null : _handlePrintPdf,
            icon: _isPrinting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
          ),
        ],
        // Bulk WhatsApp / Bulk Email / message template were here. They stay
        // commented out: both bulk methods guard on `selectedGuestIds`, and
        // the per-card selection Checkbox that would populate it is itself
        // commented out — so restoring these buttons alone would give three
        // controls that silently do nothing.
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit_note),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (_) => const MessageTemplateScreen()),
        //       );
        //     },
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.send),
        //     tooltip: "Bulk WhatsApp",
        //     onPressed: () => sendBulkWhatsApp(),
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.email),
        //     tooltip: "Bulk Email",
        //     onPressed: () => sendBulkEmail(),
        //   ),
        // ],
      ),

      floatingActionButton: _buildAddGuestButton(),
      body: isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Skeletons.listTiles(count: 6),
            )
          // AUDIT FIX: a failed load now says so and retries for real, rather
          // than rendering an empty list that reads as "you have no guests".
          : _loadError != null
              ? ErrorState(error: _loadError, onRetry: fetchGuests)
              : Column(
        children: [
          _buildStatsRow(),     // 👈 STATS
          if (guests.isNotEmpty) _buildSearchAndFilters(),
          Expanded(
            child: RefreshIndicator(
              color: Colors.pink,
              onRefresh: () async {
                await fetchGroups();
                await fetchGuests();
              },
              child: guests.isEmpty
                  ? ListView(
                      // Keeps pull-to-refresh working on an empty list.
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          title: 'No guests yet',
                          message:
                              'Add your first guest to start building the list.',
                          icon: Icons.people_outline_rounded,
                        ),
                      ],
                    )
                  : _buildGroupedList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Search box plus the two filters the website offers (Group and Status),
  /// all applied client-side — the list endpoint takes no query params.
  Widget _buildSearchAndFilters() {
    final groupOptions = _groupFilterOptions;
    // Guard the dropdown: the selected group can disappear when the last
    // guest in it is deleted or renamed.
    final groupValue =
        groupOptions.contains(_selectedGroup) ? _selectedGroup : 'All';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _searchTerm = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search name, group, phone or email',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchTerm.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchTerm = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  label: 'Group',
                  value: groupValue,
                  options: groupOptions,
                  onChanged: (v) => setState(() => _selectedGroup = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _filterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  options: const ['All', ...kGuestStatusOptions],
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(
                      o == 'All' ? 'All ${label}s' : o,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
  Future<void>  sendBulkEmail() async {
    if (selectedGuestIds.isEmpty) {
      AppSnackbar.warning(context, 'Select at least one guest first.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("auth_token");
    final userId = prefs.getInt("user_id");

    if (token == null || userId == null) return;

    final selectedGuests =
    guests.where((g) => selectedGuestIds.contains(g.id)).toList();

    final emails =
    selectedGuests.map((g) => g.email).where((e) => e.isNotEmpty).toList();

    if (emails.isEmpty) return;

    final message = await buildDynamicMessage(selectedGuests.first);

    await http.post(
      Uri.parse("${ApiConfig.apiBase}/guestlist/send-guestlist-email"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "toEmail": emails,
        "subject": "Wedding Invitation",
        "message": message,
        "userId": userId,
      }),
    );

    // NOTE: this method is currently unreachable — see the commented-out
    // AppBar actions and the commented-out per-card selection Checkbox.
    // `selectedGuestIds` can never be populated, so the guard above always
    // returns first. Guarded anyway so it is correct if it is wired back up.
    if (!mounted) return;
    AppSnackbar.success(context, 'Bulk email sent.');
  }

  Future<void> sendBulkWhatsApp() async {
    if (selectedGuestIds.isEmpty) return;

    final guestsToSend =
    guests.where((g) => selectedGuestIds.contains(g.id)).toList();

    for (final guest in guestsToSend) {
      final msg = await buildDynamicMessage(guest);
      final encodedMessage = Uri.encodeComponent(msg);
      final phone = guest.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

      final uri = Uri.parse("https://wa.me/$phone?text=$encodedMessage");

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<String> buildDynamicMessage(Guest guest) async {
    final prefs = await SharedPreferences.getInstance();

    String template = prefs.getString('invite_template') ?? '';

    return template
        .replaceAll('{{family}}', prefs.getString('family_name') ?? '')
        .replaceAll('{{bride}}', prefs.getString('bride_name') ?? '')
        .replaceAll('{{groom}}', prefs.getString('groom_name') ?? '')
        .replaceAll('{{date}}', prefs.getString('wedding_date') ?? '')
        .replaceAll('{{venue}}', prefs.getString('venue') ?? '')
        .replaceAll('{{guest}}', guest.name);
  }




  Widget _buildAddGuestButton() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.pink,
      icon: const Icon(Icons.person_add, color: Colors.white),
      label: const Text("Add Guest", style: TextStyle(color: Colors.white)),
      onPressed: () async {
        if (!await ensureSignedIn(context)) return;
        if (!mounted) return;

        final added = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => GuestFormScreen(availableGroups: availableGroups),
          ),
        );

        // AUDIT FIX: this called `fetchGuests()` without awaiting it and
        // without a mounted check after the push returned.
        if (added == true && mounted) {
          await fetchGroups(); // a group may have been created in the form
          if (mounted) await fetchGuests();
        }
      },
    );
  }



  // ---------------- PDF (download / print) ----------------
  // Mirrors the website's `GuestListPDF.jsx` — same branded header, the same
  // summary strip, and one table section per group. Entirely client-side:
  // there is no PDF endpoint on either platform. Built in the same style as
  // the wedding checklist's export so the two documents look like a set.

  pw.Widget _pdfHeaderCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
      );

  pw.Widget _pdfCell(String text, {PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8.5, color: color ?? PdfColors.black),
        ),
      );

  PdfColor _pdfStatusColor(String status) {
    switch (status) {
      case 'Attending':
        return PdfColors.green700;
      case 'Not Attending':
        return PdfColors.red700;
      default:
        return PdfColors.orange700;
    }
  }

  Future<Uint8List> _generateGuestListPdfBytes() async {
    final doc = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');

    // The website exports the FULL list, ignoring active filters. Matched
    // here so the two platforms produce the same document.
    final sections = <String, List<Guest>>{};
    for (final g in guests) {
      sections.putIfAbsent(guestGroupName(g), () => []).add(g);
    }
    final sectionNames = sections.keys.toList()..sort();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'HappyWedz',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink700,
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Guest List',
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generated: ${formatter.format(now)}',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.pink700, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Plan your dream wedding at www.happywedz.com',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.pink50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Guests: $totalGuests',
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.pink700)),
                pw.Text('Attending: $attendingCount',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Pending: $pendingCount',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Not Attending: $notAttendingCount',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('With +1s: $totalHeadcount',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          if (guests.isEmpty)
            pw.Text('No guests found in this wedding guest list.',
                style: const pw.TextStyle(fontSize: 11))
          else
            for (final name in sectionNames) ...[
              pw.Text(
                '$name (${sections[name]!.length})',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.pink700),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.4),
                  1: pw.FlexColumnWidth(1.3),
                  2: pw.FlexColumnWidth(2.4),
                  3: pw.FlexColumnWidth(1.6),
                  4: pw.FlexColumnWidth(1.0),
                  5: pw.FlexColumnWidth(1.2),
                  6: pw.FlexColumnWidth(0.7),
                  7: pw.FlexColumnWidth(1.0),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _pdfHeaderCell('Name'),
                      _pdfHeaderCell('Status'),
                      _pdfHeaderCell('Email'),
                      _pdfHeaderCell('Phone'),
                      _pdfHeaderCell('Type'),
                      _pdfHeaderCell('Menu'),
                      _pdfHeaderCell('+1s'),
                      _pdfHeaderCell('Seat'),
                    ],
                  ),
                  for (final g in sections[name]!)
                    pw.TableRow(
                      children: [
                        _pdfCell(g.name.trim().isEmpty
                            ? 'Unnamed guest'
                            : g.name),
                        _pdfCell(g.status,
                            color: _pdfStatusColor(g.status)),
                        _pdfCell(g.email.isEmpty ? '-' : g.email),
                        _pdfCell(
                            g.phoneNumber.isEmpty ? '-' : g.phoneNumber),
                        _pdfCell(g.type),
                        _pdfCell(g.menu),
                        _pdfCell(g.companions.toString()),
                        _pdfCell(
                            g.seatNumber.isEmpty ? '-' : g.seatNumber),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 12),
            ],
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _handleDownloadPdf() async {
    if (_isGeneratingPdf) return;
    if (guests.isEmpty) {
      AppSnackbar.info(context, 'No guests to download.');
      return;
    }
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generateGuestListPdfBytes();
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: 'guest-list.pdf');
    } catch (e) {
      debugPrint('Guest list PDF error: $e');
      if (mounted) {
        AppSnackbar.error(
            context, 'Unable to create the PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handlePrintPdf() async {
    if (_isPrinting) return;
    if (guests.isEmpty) {
      AppSnackbar.info(context, 'No guests to print.');
      return;
    }
    setState(() => _isPrinting = true);
    try {
      final bytes = await _generateGuestListPdfBytes();
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'guest-list.pdf',
      );
    } catch (e) {
      debugPrint('Guest list print error: $e');
      if (mounted) {
        AppSnackbar.error(
            context, 'Unable to print the guest list. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  /// ----------------------------------
  /// STATS CARDS
  /// ----------------------------------
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _statCard(
            value: totalGuests.toString(),
            title: "Guests",
            subtitle: totalHeadcount == totalGuests
                ? null
                : "With +1s: $totalHeadcount",
          ),
          const SizedBox(width: 12),
          _statCard(
            value: totalAdults.toString(),
            title: "Adults",
            subtitle: "Children: $totalChildren",
          ),
          const SizedBox(width: 12),
          _statCard(
            value: attendingCount.toString(),
            title: "Attending",
            subtitle:
            "Pending: $pendingCount\nNot Attending: $notAttendingCount",
          ),
        ],
      ),
    );
  }


  Widget _statCard({
    required String value,
    required String title,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // DEAD CODE (commented out, not deleted).
  //
  // An alternate table-based renderer: _buildGroupSection -> _tableHeader
  // + _guestRow. _buildGroupSection has no callers anywhere in lib/, so all
  // three are unreachable; the live list is built by _buildGroupedList().
  //
  // Commented out rather than left as-is because _guestRow called the old
  // fire-and-forget updateGuestStatus(), which no longer exists — status
  // changes now go through _changeGuestField(), which rolls back on
  // failure. It also carried two dead buttons with empty onPressed: () {}
  // (WhatsApp and Delete) that would silently do nothing if this renderer
  // were ever switched back on.
  // ---------------------------------------------------------------
  //   /// ----------------------------------
  //   /// GROUP SECTION
  //   /// ----------------------------------
  //   Widget _buildGroupSection(String group, List<Guest> guests) {
  //     return Container(
  //       margin: const EdgeInsets.only(bottom: 16),
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(14),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withValues(alpha: 0.05),
  //             blurRadius: 8,
  //           ),
  //         ],
  //       ),
  //       child: Column(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Align(
  //               alignment: Alignment.centerLeft,
  //               child: Text(
  //                 "$group (${guests.length})",
  //                 style:
  //                 const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //               ),
  //             ),
  //           ),
  //           _tableHeader(),
  //           const Divider(height: 1),
  //           ...guests.map(_guestRow).toList(),
  //         ],
  //       ),
  //     );
  //   }
  // 
  //   /// ----------------------------------
  //   /// TABLE HEADER
  //   /// ----------------------------------
  //   Widget _tableHeader() {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //       child: Row(
  //         children: const [
  //           Expanded(flex: 2, child: Text("Guest")),
  //           Expanded(child: Text("Status")),
  //           Expanded(child: Text("Comp")),
  //           Expanded(child: Text("Type")),
  //           Expanded(child: Text("Menu")),
  //           Expanded(flex: 2, child: Text("Phone")),
  //           SizedBox(width: 40),
  //         ],
  //       ),
  //     );
  //   }
  // 
  //   /// ----------------------------------
  //   /// GUEST ROW
  //   /// ----------------------------------
  //   Widget _guestRow(Guest guest) {
  //     return Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  //       child: Row(
  // 
  //         children: [
  //           Expanded(
  //             flex: 2,
  //             child: Text(
  //               guest.name,
  //               style: const TextStyle(fontWeight: FontWeight.w600),
  //             ),
  //           ),
  // 
  //           /// Status
  //           SizedBox(
  //             width: 140, // 👈 FIXED WIDTH = NO OVERFLOW
  //             child: DropdownButtonHideUnderline(
  //               child: DropdownButton<String>(
  //                 value: guest.status,
  //                 isExpanded: true,
  //                 items: const [
  //                   DropdownMenuItem(value: "Pending", child: Text("Pending")),
  //                   DropdownMenuItem(value: "Attending", child: Text("Attending")),
  //                   DropdownMenuItem(value: "Not Attending", child: Text("Not Attending")),
  //                 ],
  //                 onChanged: (v) async {
  //                   if (v == null) return;
  //                   await updateGuestStatus(guest.id!, v);
  //                   setState(() => guest.status = v);
  //                 },
  //               ),
  //             ),
  //           ),
  // 
  //           Expanded(child: Text(guest.companions.toString())),
  //           Expanded(child: Text(guest.type)),
  //           Expanded(child: Text(guest.menu)),
  //           Expanded(flex: 2, child: Text(guest.phoneNumber)),
  // 
  //           /// Actions
  //           Row(
  //             children: [
  //               IconButton(
  //                 onPressed: () {},
  //                 icon: Image.asset(
  //                   'assets/whatsapp.png',
  //                   width: 35,
  //                   height: 35,
  //                 ),
  //               ),
  // 
  //               IconButton(
  //                 icon: const Icon(Icons.delete, color: Colors.red),
  //                 onPressed: () {},
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     );
  //   }
}


/// "New group" prompt for the guest form's group picker.
///
/// Exists as a widget purely so the [TextEditingController] has an owner with
/// a real lifecycle. A controller created beside `showDialog` and disposed
/// after the await is disposed while the dialog is still animating out, and
/// the TextField then rebuilds against it — see the note in `_createGroup`.
class _NewGroupDialog extends StatefulWidget {
  const _NewGroupDialog();

  @override
  State<_NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends State<_NewGroupDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New group'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: "e.g. Bride's Family"),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Add **and** edit, in one screen.
///
/// The app previously had no edit path at all — a typo in a name, email or
/// phone could only be fixed by deleting the guest and re-adding them. The
/// website's edit modal sends the full 9-field `PUT /guestlist/{id}`
/// (`Guests.jsx:402-426`); [existing] switches this form into that mode.
class GuestFormScreen extends StatefulWidget {
  const GuestFormScreen({
    super.key,
    this.existing,
    this.availableGroups = const [],
  });

  /// Null for "add", populated for "edit".
  final Guest? existing;

  /// Groups from `GET /groups`, used to populate the picker.
  final List<GuestGroup> availableGroups;

  @override
  State<GuestFormScreen> createState() => _GuestFormScreenState();
}

/// Kept so older call sites and any external references keep compiling.
class AddGuestScreen extends StatelessWidget {
  const AddGuestScreen({super.key});

  @override
  Widget build(BuildContext context) => const GuestFormScreen();
}

class _GuestFormScreenState extends State<GuestFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companionsController;
  late final TextEditingController _seatController;

  late String type;
  late String menu;
  late String status;

  /// Empty string means "no group" — sent as null, matching the website.
  late String groupId;

  late List<GuestGroup> _groups;

  bool isSaving = false;
  bool _isCreatingGroup = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _groups = List.of(widget.availableGroups);

    _nameController = TextEditingController(text: g?.name ?? '');
    _emailController = TextEditingController(text: g?.email ?? '');
    _phoneController = TextEditingController(text: g?.phoneNumber ?? '');
    _companionsController =
        TextEditingController(text: (g?.companions ?? 0).toString());
    _seatController = TextEditingController(text: g?.seatNumber ?? '');

    type = normalizeGuestOption(g?.type, kGuestTypeOptions, 'Adult');
    menu = normalizeGuestOption(g?.menu, kGuestMenuOptions, 'Veg');
    status = normalizeGuestOption(g?.status, kGuestStatusOptions, 'Pending');

    final existingGroupId = g?.groupId ?? '';
    groupId = _groups.any((gr) => gr.id == existingGroupId)
        ? existingGroupId
        : '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companionsController.dispose();
    _seatController.dispose();
    super.dispose();
  }

  /// AUDIT FIX: `_saveGuest` had **no try/catch** around `http.post`. On a
  /// network error the exception escaped before
  /// `setState(() => isSaving = false)` ran, so the Save button stayed
  /// disabled with a spinner forever and the only way out was to leave the
  /// screen. (The same bug had already been fixed in `fetchGuests`.)
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey);
      final userId = prefs.getInt(UserPrefs.userIdKey);

      if (token == null || userId == null) {
        if (!mounted) return;
        setState(() => isSaving = false);
        // Was a bare `Navigator.pop(context)` — the form just closed with no
        // result and no explanation.
        AppSnackbar.error(context, 'Please sign in again to save this guest.');
        return;
      }

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final seat = _seatController.text.trim();
      final companions = int.tryParse(_companionsController.text.trim()) ?? 0;

      final http.Response response;

      if (_isEdit) {
        // Full 9-field body, exactly as the website's edit modal sends it.
        final body = {
          'name': name,
          'email': email.isEmpty ? null : email,
          'phone_number': phone.isEmpty ? null : phone,
          'groupId': groupId.isEmpty ? null : groupId,
          'status': status,
          'type': type,
          'menu': menu,
          'companions': companions,
          'seat_number': seat.isEmpty ? null : seat,
        };
        debugPrint('📤 PUT /guestlist/${widget.existing!.id} → ${jsonEncode(body)}');
        response = await http.put(
          Uri.parse("${ApiConfig.apiBase}/guestlist/${widget.existing!.id}"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
          body: jsonEncode(body),
        );
      } else {
        // Create body per `Guests.jsx:287-308`: `groupId` is OMITTED when
        // unset (not sent as null), and no `group`/`city` key is sent.
        final body = <String, dynamic>{
          'name': name,
          'email': email,
          'phone_number': phone.isEmpty ? null : phone,
          'userId': userId,
          'status': 'Pending',
          'type': type,
          'menu': menu,
          'companions': companions,
          'seat_number': seat.isEmpty ? null : seat,
        };
        if (groupId.isNotEmpty) body['groupId'] = groupId;

        debugPrint('📤 POST /guestlist → ${jsonEncode(body)}');
        response = await http.post(
          Uri.parse("${ApiConfig.apiBase}/guestlist"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
            "Accept": "application/json",
          },
          body: jsonEncode(body),
        );
      }

      debugPrint('📥 ${response.statusCode} ${response.body}');
      if (!mounted) return;
      setState(() => isSaving = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        AppSnackbar.error(context, _serverMessage(response) ??
            (_isEdit
                ? "We couldn't save those changes. Please try again."
                : "We couldn't add that guest. Please try again."));
      }
    } catch (e) {
      debugPrint('Save guest failed: $e');
      if (!mounted) return;
      setState(() => isSaving = false);
      AppSnackbar.error(
        context,
        "We couldn't reach the server. Check your connection and try again.",
      );
    }
  }

  /// Surfaces the API's own `message` when it sends one — the old code threw
  /// the response body away entirely.
  String? _serverMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        final message = (decoded['message'] as String).trim();
        if (message.isNotEmpty) return message;
      }
    } catch (_) {
      // Non-JSON body; fall back to the generic message.
    }
    return null;
  }

  /// `POST /groups/add` — the website's inline "Create Group" form.
  Future<void> _createGroup() async {
    // The controller is owned by [_NewGroupDialog], not created here.
    //
    // AUDIT FIX: this used to build the TextField against a controller
    // created in this method and disposed immediately after `showDialog`
    // returned. But `showDialog` completes as soon as `Navigator.pop` is
    // called — the dialog's *exit transition* is still running, and the
    // TextField keeps rebuilding against the controller throughout it. So
    // the dispose landed mid-animation and the next frame threw
    // "A TextEditingController was used after being disposed", which then
    // cascaded into a second assertion while the overlay tore down.
    //
    // A StatefulWidget that owns its own controller disposes it when the
    // route is actually gone, which is the only point that is safe.
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewGroupDialog(),
    );

    if (name == null || name.isEmpty || !mounted) return;

    setState(() => _isCreatingGroup = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey);
      if (token == null) return;

      final res = await http.post(
        Uri.parse("${ApiConfig.apiBase}/groups/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({"name": name}),
      );

      if (!mounted) return;

      final decoded = res.statusCode == 200 || res.statusCode == 201
          ? jsonDecode(res.body)
          : null;

      if (decoded is Map &&
          decoded['success'] == true &&
          decoded['group'] is Map) {
        final created = GuestGroup.fromJson(decoded['group'] as Map);
        if (created.id.isNotEmpty) {
          setState(() {
            _groups = [..._groups, created];
            groupId = created.id;
          });
          AppSnackbar.success(context, 'Group created.');
          return;
        }
      }

      AppSnackbar.error(context, "We couldn't create that group. Please try again.");
    } catch (e) {
      debugPrint('createGroup failed: $e');
      if (!mounted) return;
      AppSnackbar.error(context, "We couldn't create that group. Please try again.");
    } finally {
      if (mounted) setState(() => _isCreatingGroup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? "Edit Guest" : "Add Guest"),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Keyboard-safe: the Save button stays reachable with the keyboard up.
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _input(
                  label: "Guest Name",
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? "Guest name is required."
                      : null,
                ),
                _input(
                  label: _isEdit ? "Email (optional)" : "Email",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  // The website requires a valid email on create but allows an
                  // empty one on edit; matched here rather than "invented".
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) {
                      return _isEdit ? null : "Email is required.";
                    }
                    final emailRegex =
                        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    return emailRegex.hasMatch(value)
                        ? null
                        : "Please enter a valid email address.";
                  },
                ),
                _input(
                  label: "Phone (optional)",
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final digits =
                        (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                    if (digits.isEmpty) return null;
                    return digits.length < 10
                        ? "Enter at least 10 digits."
                        : null;
                  },
                ),

                _groupPicker(),

                _dropdown("Type", type, kGuestTypeOptions,
                    (v) => setState(() => type = v)),

                _dropdown("Menu", menu, kGuestMenuOptions,
                    (v) => setState(() => menu = v)),

                // Status is only editable when editing — the website's add
                // form has no status control and always creates "Pending".
                if (_isEdit)
                  _dropdown("RSVP Status", status, kGuestStatusOptions,
                      (v) => setState(() => status = v)),

                _input(
                  label: "Companions",
                  controller: _companionsController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return null;
                    final parsed = int.tryParse(value);
                    if (parsed == null) return "Enter a number.";
                    return parsed < 0 ? "Cannot be negative." : null;
                  },
                ),

                _input(
                  label: "Seat Number (optional)",
                  controller: _seatController,
                  hint: "e.g. Table-1, A12",
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: isSaving ? null : _save,
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEdit ? "Save Changes" : "Save Guest",
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Group picker backed by `GET /groups`, with an inline create. Replaces
  /// the old hardcoded `["Family","Friends","Colleagues","Other"]`, which
  /// could never match a group the user had made on the website.
  Widget _groupPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: groupId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: '', child: Text('No group')),
                ..._groups.map(
                  (g) => DropdownMenuItem(
                    value: g.id,
                    child: Text(g.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => groupId = v ?? ''),
              decoration: InputDecoration(
                labelText: 'Group',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Create group',
            onPressed: _isCreatingGroup ? null : _createGroup,
            icon: _isCreatingGroup
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline, color: Colors.pink),
          ),
        ],
      ),
    );
  }

  /// ---------------- UI HELPERS ----------------
  Widget _input({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _dropdown(
      String label,
      String value,
      List<String> items,
      Function(String) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) =>
            DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}


class MessageTemplateScreen extends StatefulWidget {
  const MessageTemplateScreen({Key? key}) : super(key: key);

  @override
  State<MessageTemplateScreen> createState() => _MessageTemplateScreenState();
}

class _MessageTemplateScreenState extends State<MessageTemplateScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    // Was never disposed — a TextEditingController leak on every open.
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    _controller.text = prefs.getString('invite_template') ??
        '''We, the family of {{family}},
warmly invite you to the wedding of
{{bride}} & {{groom}}

Date: {{date}}
Venue: {{venue}}

Your presence means a lot to us.''';
  }

  Future<void> _saveTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invite_template', _controller.text);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Invite Message")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Edit your invitation message",
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveTemplate,
              child: const Text("Save Template"),
            )
          ],
        ),
      ),
    );
  }
}
