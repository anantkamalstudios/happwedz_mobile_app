
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

// Guest Model
class Guest {
  final String id;
  String name;
  String email;
  String phone;
  String category;
  String rsvpStatus; // 'pending', 'accepted', 'declined'
  final int plusOnes;
  final String? dietaryRestrictions;
  final String? address;

  // New optional fields
  String? mealPreference;
  String? seat;
  String? notes;
  bool checkedIn;

  Guest({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.category,
    this.rsvpStatus = 'pending',
    this.plusOnes = 0,
    this.dietaryRestrictions,
    this.address,
    this.mealPreference,
    this.seat,
    this.notes,
    this.checkedIn = false,
  });
}

// Main Guest List Screen
class GuestListScreen extends StatefulWidget {
  const GuestListScreen({Key? key}) : super(key: key);

  @override
  State<GuestListScreen> createState() => _GuestListScreenState();
}

class _GuestListScreenState extends State<GuestListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Sample data - replace with API call later
  List<Guest> _allGuests = [];
  bool _isLoading = false;


  final List<String> _categories = ['All', 'Family', 'Friends', 'Colleagues', 'Others'];


  Future<void> fetchGuests() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://happywedz.com/api/guestlist/24');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['guest'] != null) {
          // handle single guest or list of guests
          final guestData = data['guest'];
          List<Guest> loadedGuests = [];

          if (guestData is List) {
            loadedGuests = guestData.map<Guest>((g) => Guest(
              id: g['id'].toString(),
              name: g['name'] ?? '',
              email: g['email'] ?? '',
              phone: '',
              category: g['group'] ?? 'Others',
              rsvpStatus: (g['status'] ?? 'pending').toLowerCase(),
              plusOnes: g['companions'] ?? 0,
              dietaryRestrictions: '',
              address: '',
              mealPreference: g['menu'],
              seat: g['seat_number'],
            )).toList();
          } else {
            // single guest
            loadedGuests = [
              Guest(
                id: guestData['id'].toString(),
                name: guestData['name'] ?? '',
                email: guestData['email'] ?? '',
                phone: '',
                category: guestData['group'] ?? 'Others',
                rsvpStatus: (guestData['status'] ?? 'pending').toLowerCase(),
                plusOnes: guestData['companions'] ?? 0,
                dietaryRestrictions: '',
                address: '',
                mealPreference: guestData['menu'],
                seat: guestData['seat_number'],
              )
            ];
          }

          setState(() => _allGuests = loadedGuests);
          print(response);
          print(response.body);
        }
      } else {
        print('Failed to fetch guests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching guests: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> addGuest(Map<String, dynamic> guestData) async {
    try {
      final response = await http.post(
        Uri.parse('https://happywedz.com/api/guestlist'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(guestData),
      );

      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Guest added successfully')),
          );
          fetchGuests(); // refresh list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add guest')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error ${response.statusCode} adding guest')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding guest: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    fetchGuests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddGuestDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String phone = '';
    String category = 'Family';
    String rsvpStatus = 'pending';
    int plusOnes = 0;
    String dietaryRestrictions = '';
    String address = '';
    String mealPreference = 'Vegetarian';
    String seat = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Guest'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Guest Name'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  onSaved: (val) => name = val!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Guest Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  onSaved: (val) => email = val!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  onSaved: (val) => phone = val!,
                ),
                DropdownButtonFormField(
                  value: category,
                  items: ['Family', 'Friends', 'Colleagues', 'Others']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => category = val.toString(),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                DropdownButtonFormField(
                  value: rsvpStatus,
                  items: ['pending', 'accepted', 'declined']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => rsvpStatus = val.toString(),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Companions'),
                  keyboardType: TextInputType.number,
                  onSaved: (val) => plusOnes = int.tryParse(val ?? '0') ?? 0,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Dietary Restrictions'),
                  onSaved: (val) => dietaryRestrictions = val ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Address'),
                  onSaved: (val) => address = val ?? '',
                ),
                DropdownButtonFormField(
                  value: mealPreference,
                  items: ['Vegetarian', 'Non-Veg', 'Vegan']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => mealPreference = val.toString(),
                  decoration: const InputDecoration(labelText: 'Meal Preference'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Seat/Table'),
                  onSaved: (val) => seat = val ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                final guestData = {
                  "name": name,
                  "email": email,
                  "group": category,
                  "status": rsvpStatus,
                  "type": "Adult",
                  "menu": mealPreference,
                  "companions": plusOnes,
                  "seat_number": seat,
                };

                await addGuest(guestData);
                Navigator.pop(context);
              }
            },

            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF69B4)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  List<Guest> get _filteredGuests {
    return _allGuests.where((guest) {
      final matchesSearch = guest.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          guest.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || guest.category == _selectedCategory;

      switch (_tabController.index) {
        case 1:
          return matchesSearch && matchesCategory && guest.rsvpStatus == 'accepted';
        case 2:
          return matchesSearch && matchesCategory && guest.rsvpStatus == 'pending';
        case 3:
          return matchesSearch && matchesCategory && guest.rsvpStatus == 'declined';
        default:
          return matchesSearch && matchesCategory;
      }
    }).toList();
  }

  int get _totalAccepted => _allGuests.where((g) => g.rsvpStatus == 'accepted').length;
  int get _totalPending => _allGuests.where((g) => g.rsvpStatus == 'pending').length;
  int get _totalDeclined => _allGuests.where((g) => g.rsvpStatus == 'declined').length;
  int get _totalAttendees => _allGuests.where((g) => g.rsvpStatus == 'accepted')
      .fold(0, (sum, g) => sum + 1 + g.plusOnes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Guest List',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: _showOptionsMenu,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF69B4),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF69B4),
              onTap: (index) => setState(() {}),
              tabs: [
                Tab(text: 'All (${_allGuests.length})'),
                Tab(text: 'Accepted ($_totalAccepted)'),
                Tab(text: 'Pending ($_totalPending)'),
                Tab(text: 'Declined ($_totalDeclined)'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
          : Column(
        children: [
          _buildStatsCard(),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (index) => _buildGuestList()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final loggedIn = await ensureLoggedIn(context);
          if (!loggedIn) return; // 🚫 Not logged in → go to SignInScreen

          _showAddGuestDialog(); // ✅ Continue if logged in
        },
        backgroundColor: const Color(0xFFFF69B4),
        icon: const Icon(Icons.add),
        label: const Text('Add Guest'),
      ),

    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFF9B7EF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF69B4).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

          const SizedBox(height: 8),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Guests', '${_allGuests.length}', Icons.people),
              _buildStatItem('Adults', '$_totalAccepted', Icons.check_circle),
              _buildStatItem('Attending', '$_totalPending', Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search guests...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.grey),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildGuestList() {
    final guests = _filteredGuests;

    if (guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No guests found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Add guests to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: guests.length,
      itemBuilder: (context, index) => _buildGuestCard(guests[index]),
    );
  }

  Widget _buildGuestCard(Guest guest) {
    Color statusColor;
    IconData statusIcon;

    switch (guest.rsvpStatus) {
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'declined':
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF69B4).withOpacity(0.1),
          child: Text(guest.name[0].toUpperCase(), style: const TextStyle(color: Color(0xFFFF69B4), fontWeight: FontWeight.bold)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(guest.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(guest.rsvpStatus.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (guest.email.isNotEmpty)
              Row(children: [Icon(Icons.email, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Text(guest.email, style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
            const SizedBox(height: 4),
            if (guest.phone.isNotEmpty)
              Row(children: [Icon(Icons.phone, size: 14, color: Colors.grey[600]), const SizedBox(width: 4), Text(guest.phone, style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(guest.category, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
                if (guest.plusOnes > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('+${guest.plusOnes}', style: const TextStyle(color: Colors.pink, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                ],
              ],
            ),
            if (guest.seat != null && guest.seat!.isNotEmpty) Text('Seat/Table: ${guest.seat}', style: const TextStyle(fontSize: 12)),
            if (guest.mealPreference != null && guest.mealPreference!.isNotEmpty) Text('Meal: ${guest.mealPreference}', style: const TextStyle(fontSize: 12)),
            if (guest.notes != null && guest.notes!.isNotEmpty) Text('Notes: ${guest.notes}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            // Center(child: QrImage(data: guest.id, version: QrVersions.auto, size: 80.0)),
            // const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Checked In', style: const TextStyle(fontSize: 12)),
                Switch(
                  value: guest.checkedIn,
                  onChanged: (val) => setState(() => guest.checkedIn = val),
                  activeColor: Colors.pink,
                ),
              ],
            ),
          ],
        ),

      ),
    );
  }




  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import from CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import CSV feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Guest List'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Bulk Email'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email feature coming soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



// EDIT GUEST


// DELETE GUEST
  void _deleteGuest(Guest guest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guest'),
        content: Text('Are you sure you want to delete ${guest.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _allGuests.remove(guest));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

// SEND MESSAGE
  void _sendMessageToGuest(Guest guest) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: 180,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.green),
                title: const Text('Send WhatsApp'),
                onTap: () {
                  _launchWhatsApp(guest.phone);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text('Send Email'),
                onTap: () {
                  _launchEmail(guest.email);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

// Launch WhatsApp
  void _launchWhatsApp(String phone) async {
    final whatsappUrl = Uri.parse("https://wa.me/$phone?text=Hello!");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open WhatsApp")),
      );
    }
  }

// Launch Email
  void _launchEmail(String email) async {
    final emailUrl = Uri.parse("mailto:$email?subject=Hello&body=Hi!");
    if (await canLaunchUrl(emailUrl)) {
      await launchUrl(emailUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Email app")),
      );
    }
  }

}