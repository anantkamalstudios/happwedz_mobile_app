// // Project: Happy Wedz — GuestList Feature
// // Language: Dart (Flutter)
// // Files included below — copy them into your Flutter project's lib/ folder respecting folders.
//
// /*
// pubspec.yaml (add these dependencies under dependencies:)
//
// dependencies:
//   flutter:
//     sdk: flutter
//   provider: ^6.0.5
//   hive: ^2.2.3
//   hive_flutter: ^1.1.0
//   path_provider: ^2.0.14
//   csv: ^5.0.0
//
// dev_dependencies:
//   hive_generator: ^2.0.0
//   build_runner: ^2.4.4
//
// Note: For Hive type adapters you can either use manual adapters (provided below) or generate using build_runner.
// */
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/main.dart
// ///////////////////////////////////////////////////////////////////////////////
//
// import 'dart:io';
//
// import 'package:csv/csv.dart';
// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';
//
//
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await Hive.initFlutter();
// //   Hive.registerAdapter(GuestAdapter());
// //   await HiveService.openBox();
// //
// //   runApp(const HappyWedzApp());
// // }
// //
// // class HappyWedzApp extends StatelessWidget {
// //   const HappyWedzApp({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MultiProvider(
// //       providers: [
// //         ChangeNotifierProvider(create: (_) => GuestProvider()),
// //       ],
// //       child: MaterialApp(
// //         title: 'Happy Wedz - GuestList',
// //         theme: ThemeData(
// //           primaryColor: const Color(0xFF5E4B56),
// //           scaffoldBackgroundColor: const Color(0xFFFFF5F8),
// //           colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFE7C6A8)),
// //           useMaterial3: true,
// //         ),
// //         home: const GuestListPage(),
// //       ),
// //     );
// //   }
// // }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/models/guest.dart
// ///////////////////////////////////////////////////////////////////////////////
//  // If you use build_runner to generate adapter. If not, manual adapter is below.
//
// @HiveType(typeId: 0)
// class Guest extends HiveObject {
//   @HiveField(0)
//   String id; // uuid or timestamp
//
//   @HiveField(1)
//   String name;
//
//   @HiveField(2)
//   String? phone;
//
//   @HiveField(3)
//   String? email;
//
//   @HiveField(4)
//   String? address;
//
//   @HiveField(5)
//   String group; // Family/Friends/Colleagues
//
//   @HiveField(6)
//   int adults;
//
//   @HiveField(7)
//   int children;
//
//   @HiveField(8)
//   RSVPStatus rsvp;
//
//   @HiveField(9)
//   List<String> events; // e.g. ['Sangeet','Wedding']
//
//   Guest({
//     required this.id,
//     required this.name,
//     this.phone,
//     this.email,
//     this.address,
//     this.group = 'Family',
//     this.adults = 1,
//     this.children = 0,
//     this.rsvp = RSVPStatus.invited,
//     List<String>? events,
//   }) : events = events ?? [];
// }
//
// enum RSVPStatus { invited, confirmed, declined, pending }
//
// // Manual adapter in case you're not using code generation
// class GuestAdapter extends TypeAdapter<Guest> {
//   @override
//   final int typeId = 0;
//
//   @override
//   Guest read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{};
//     for (var i = 0; i < numOfFields; i++) {
//       fields[reader.readByte()] = reader.read();
//     }
//     return Guest(
//       id: fields[0] as String,
//       name: fields[1] as String,
//       phone: fields[2] as String?,
//       email: fields[3] as String?,
//       address: fields[4] as String?,
//       group: fields[5] as String,
//       adults: fields[6] as int,
//       children: fields[7] as int,
//       rsvp: RSVPStatus.values[fields[8] as int],
//       events: (fields[9] as List).cast<String>(),
//     );
//   }
//
//   @override
//   void write(BinaryWriter writer, Guest obj) {
//     writer
//       ..writeByte(10)
//       ..writeByte(0)
//       ..write(obj.id)
//       ..writeByte(1)
//       ..write(obj.name)
//       ..writeByte(2)
//       ..write(obj.phone)
//       ..writeByte(3)
//       ..write(obj.email)
//       ..writeByte(4)
//       ..write(obj.address)
//       ..writeByte(5)
//       ..write(obj.group)
//       ..writeByte(6)
//       ..write(obj.adults)
//       ..writeByte(7)
//       ..write(obj.children)
//       ..writeByte(8)
//       ..write(obj.rsvp.index)
//       ..writeByte(9)
//       ..write(obj.events);
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/services/hive_service.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
// class HiveService {
//   static const String boxName = 'guestBox';
//
//   // ✅ Open box safely, only if not already open
//   static Future<void> openBox() async {
//     if (!Hive.isBoxOpen(boxName)) {
//       await Hive.openBox<Guest>(boxName);
//     }
//   }
//
//   static Box<Guest> getBox() {
//     if (!Hive.isBoxOpen(boxName)) {
//       throw Exception('GuestBox is not open yet. Call HiveService.openBox() first.');
//     }
//     return Hive.box<Guest>(boxName);
//   }
//
//   static Future<void> addGuest(Guest guest) async {
//     final box = getBox();
//     await box.put(guest.id, guest);
//   }
//
//   static Future<void> updateGuest(Guest guest) async {
//     final box = getBox();
//     await box.put(guest.id, guest);
//   }
//
//   static Future<void> deleteGuest(String id) async {
//     final box = getBox();
//     await box.delete(id);
//   }
//
//   static List<Guest> getAllGuests() {
//     final box = getBox();
//     return box.values.toList();
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/providers/guest_provider.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
// class GuestProvider extends ChangeNotifier {
//   List<Guest> _guests = [];
//   String _searchQuery = '';
//   String _groupFilter = 'All';
//
//   GuestProvider() {
//     // ✅ Load after ensuring the box is open
//     _init();
//   }
//
//   Future<void> _init() async {
//     await HiveService.openBox(); // safe: opens only if not already open
//     _load();
//   }
//
//   void _load() {
//     _guests = HiveService.getAllGuests();
//     notifyListeners();
//   }
//
//
//   List<Guest> get guests => _applyFilters();
//
//   int get totalGuests => _guests.fold(0, (sum, g) => sum + g.adults + g.children);
//   int get confirmedCount => _guests.where((g) => g.rsvp == RSVPStatus.confirmed).fold(0, (sum, g) => sum + g.adults + g.children);
//   int get pendingCount => _guests.where((g) => g.rsvp == RSVPStatus.pending || g.rsvp == RSVPStatus.invited).fold(0, (sum, g) => sum + g.adults + g.children);
//   int get declinedCount => _guests.where((g) => g.rsvp == RSVPStatus.declined).fold(0, (sum, g) => sum + g.adults + g.children);
//
//   // void _load() {
//   //   _guests = HiveService.getAllGuests();
//   //   notifyListeners();
//   // }
//
//   Future<void> addGuest(Guest guest) async {
//     // ensure id
//     if (guest.id.isEmpty) guest.id = const Uuid().v4();
//     await HiveService.addGuest(guest);
//     _load();
//   }
//
//   Future<void> updateGuest(Guest guest) async {
//     await HiveService.updateGuest(guest);
//     _load();
//   }
//
//   Future<void> deleteGuest(String id) async {
//     await HiveService.deleteGuest(id);
//     _load();
//   }
//
//   void setSearchQuery(String q) {
//     _searchQuery = q;
//     notifyListeners();
//   }
//
//   void setGroupFilter(String g) {
//     _groupFilter = g;
//     notifyListeners();
//   }
//
//   List<Guest> _applyFilters() {
//     var list = _guests;
//     if (_groupFilter != 'All') {
//       list = list.where((g) => g.group == _groupFilter).toList();
//     }
//     if (_searchQuery.isNotEmpty) {
//       final q = _searchQuery.toLowerCase();
//       list = list.where((g) => g.name.toLowerCase().contains(q) || (g.email ?? '').toLowerCase().contains(q) || (g.phone ?? '').contains(q)).toList();
//     }
//     // Sort by name
//     list.sort((a, b) => a.name.compareTo(b.name));
//     return list;
//   }
//
//   // Helper: unique groups
//   List<String> get groups {
//     final set = <String>{'All'}..addAll(_guests.map((g) => g.group));
//     return set.toList();
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/pages/guest_list_page.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
// class GuestListPage extends StatefulWidget {
//   const GuestListPage({Key? key}) : super(key: key);
//
//   @override
//   _GuestListPageState createState() => _GuestListPageState();
// }
//
// class _GuestListPageState extends State<GuestListPage> {
//   final _searchController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GuestProvider>(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Guest List — Happy Wedz'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.file_download),
//             onPressed: () async {
//               final guests = provider.guests;
//               final path = await ExportUtil.exportGuestsToCSV(guests);
//               if (path != null) {
//                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
//               }
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Column(
//             children: [
//               DashboardWidget(),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: _searchController,
//                       decoration: const InputDecoration(
//                         prefixIcon: Icon(Icons.search),
//                         hintText: 'Search by name, email or phone',
//                         border: OutlineInputBorder(),
//                         isDense: true,
//                       ),
//                       onChanged: provider.setSearchQuery,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   DropdownButton<String>(
//                     value: provider.groups.contains('All') ? 'All' : provider.groups.first,
//                     items: provider.groups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
//                     onChanged: (v) {
//                       if (v != null) provider.setGroupFilter(v);
//                     },
//                   )
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Expanded(
//                 child: Consumer<GuestProvider>(
//                   builder: (context, p, _) {
//                     final list = p.guests;
//                     if (list.isEmpty) {
//                       return Center(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Text('No guests yet', style: TextStyle(fontSize: 18)),
//                             const SizedBox(height: 8),
//                             ElevatedButton.icon(
//                               onPressed: () => _openAdd(context),
//                               icon: const Icon(Icons.person_add),
//                               label: const Text('Add your first guest'),
//                             )
//                           ],
//                         ),
//                       );
//                     }
//                     return ListView.builder(
//                       itemCount: list.length,
//                       itemBuilder: (context, index) {
//                         final guest = list[index];
//                         return GuestCard(guest: guest);
//                       },
//                     );
//                   },
//                 ),
//               )
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _openAdd(context),
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
//
//   void _openAdd(BuildContext context) {
//     Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddEditGuestPage()));
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/pages/add_edit_guest_page.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
// class AddEditGuestPage extends StatefulWidget {
//   final Guest? guest;
//   const AddEditGuestPage({Key? key, this.guest}) : super(key: key);
//
//   @override
//   _AddEditGuestPageState createState() => _AddEditGuestPageState();
// }
//
// class _AddEditGuestPageState extends State<AddEditGuestPage> {
//   final _formKey = GlobalKey<FormState>();
//   late String name;
//   String? phone;
//   String? email;
//   String? address;
//   String group = 'Family';
//   int adults = 1;
//   int children = 0;
//   RSVPStatus rsvp = RSVPStatus.invited;
//   List<String> events = [];
//
//   final availableEvents = ['Sangeet', 'Wedding', 'Reception'];
//   final availableGroups = ['Family', 'Friends', 'Colleagues', 'Outstation'];
//
//   @override
//   void initState() {
//     super.initState();
//     final g = widget.guest;
//     if (g != null) {
//       name = g.name;
//       phone = g.phone;
//       email = g.email;
//       address = g.address;
//       group = g.group;
//       adults = g.adults;
//       children = g.children;
//       rsvp = g.rsvp;
//       events = List.from(g.events);
//     } else {
//       name = '';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GuestProvider>(context, listen: false);
//
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.guest == null ? 'Add Guest' : 'Edit Guest')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 initialValue: name,
//                 decoration: const InputDecoration(labelText: 'Name'),
//                 validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
//                 onSaved: (v) => name = v!.trim(),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 initialValue: phone,
//                 decoration: const InputDecoration(labelText: 'Phone'),
//                 keyboardType: TextInputType.phone,
//                 onSaved: (v) => phone = v?.trim(),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 initialValue: email,
//                 decoration: const InputDecoration(labelText: 'Email'),
//                 keyboardType: TextInputType.emailAddress,
//                 onSaved: (v) => email = v?.trim(),
//               ),
//               const SizedBox(height: 8),
//               TextFormField(
//                 initialValue: address,
//                 decoration: const InputDecoration(labelText: 'Address (optional)'),
//                 onSaved: (v) => address = v?.trim(),
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: group,
//                 items: availableGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
//                 onChanged: (v) => setState(() => group = v ?? 'Family'),
//                 decoration: const InputDecoration(labelText: 'Group'),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       initialValue: adults.toString(),
//                       decoration: const InputDecoration(labelText: 'Adults'),
//                       keyboardType: TextInputType.number,
//                       onSaved: (v) => adults = int.tryParse(v ?? '1') ?? 1,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextFormField(
//                       initialValue: children.toString(),
//                       decoration: const InputDecoration(labelText: 'Children'),
//                       keyboardType: TextInputType.number,
//                       onSaved: (v) => children = int.tryParse(v ?? '0') ?? 0,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<RSVPStatus>(
//                 value: rsvp,
//                 items: RSVPStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.toString().split('.').last))).toList(),
//                 onChanged: (v) => setState(() => rsvp = v ?? RSVPStatus.invited),
//                 decoration: const InputDecoration(labelText: 'RSVP Status'),
//               ),
//               const SizedBox(height: 8),
//               const Text('Events'),
//               Wrap(
//                 spacing: 8,
//                 children: availableEvents.map((e) {
//                   final isSelected = events.contains(e);
//                   return FilterChip(
//                     label: Text(e),
//                     selected: isSelected,
//                     onSelected: (sel) {
//                       setState(() {
//                         if (sel) {
//                           events.add(e);
//                         } else {
//                           events.remove(e);
//                         }
//                       });
//                     },
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     _formKey.currentState!.save();
//                     final id = widget.guest?.id ?? const Uuid().v4();
//                     final newGuest = Guest(
//                       id: id,
//                       name: name,
//                       phone: phone,
//                       email: email,
//                       address: address,
//                       group: group,
//                       adults: adults,
//                       children: children,
//                       rsvp: rsvp,
//                       events: events,
//                     );
//                     if (widget.guest == null) {
//                       await provider.addGuest(newGuest);
//                     } else {
//                       await provider.updateGuest(newGuest);
//                     }
//                     Navigator.of(context).pop();
//                   }
//                 },
//                 child: Text(widget.guest == null ? 'Add Guest' : 'Save Changes'),
//               )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/widgets/guest_card.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
//
// class GuestCard extends StatelessWidget {
//   final Guest guest;
//   const GuestCard({Key? key, required this.guest}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GuestProvider>(context, listen: false);
//
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         title: Text(guest.name, style: const TextStyle(fontWeight: FontWeight.w600)),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text('${guest.group} • ${guest.adults + guest.children} pax'),
//             const SizedBox(height: 4),
//             Wrap(
//               spacing: 6,
//               children: guest.events.map((e) => Chip(label: Text(e), visualDensity: VisualDensity.compact)).toList(),
//             )
//           ],
//         ),
//         trailing: PopupMenuButton<String>(
//           onSelected: (val) async {
//             if (val == 'edit') {
//               Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddEditGuestPage(guest: guest)));
//             } else if (val == 'delete') {
//               final ok = await showDialog<bool>(
//                 context: context,
//                 builder: (c) => AlertDialog(
//                   title: const Text('Delete Guest?'),
//                   content: Text('Delete ${guest.name} from guest list?'),
//                   actions: [
//                     TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
//                     TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
//                   ],
//                 ),
//               );
//               if (ok == true) provider.deleteGuest(guest.id);
//             }
//           },
//           itemBuilder: (_) => [
//             const PopupMenuItem(value: 'edit', child: Text('Edit')),
//             const PopupMenuItem(value: 'delete', child: Text('Delete')),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/widgets/dashboard_widget.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
//
// class DashboardWidget extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GuestProvider>(context);
//
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             _StatColumn('Total', provider.totalGuests.toString()),
//             _StatColumn('Confirmed', provider.confirmedCount.toString()),
//             _StatColumn('Pending', provider.pendingCount.toString()),
//             _StatColumn('Declined', provider.declinedCount.toString()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _StatColumn(String label, String value) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         const SizedBox(height: 6),
//         Text(label),
//       ],
//     );
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // FILE: lib/utils/export_util.dart
// ///////////////////////////////////////////////////////////////////////////////
//
//
// class ExportUtil {
//   static Future<String?> exportGuestsToCSV(List<Guest> guests) async {
//     try {
//       final List<List<dynamic>> rows = [];
//       rows.add(['Name', 'Phone', 'Email', 'Address', 'Group', 'Adults', 'Children', 'RSVP', 'Events']);
//       for (var g in guests) {
//         rows.add([
//           g.name,
//           g.phone ?? '',
//           g.email ?? '',
//           g.address ?? '',
//           g.group,
//           g.adults,
//           g.children,
//           g.rsvp.toString().split('.').last,
//           g.events.join('|')
//         ]);
//       }
//
//       final csvData = const ListToCsvConverter().convert(rows);
//       final directory = await getApplicationDocumentsDirectory();
//       final path = '${directory.path}/happywedz_guestlist_${DateTime.now().millisecondsSinceEpoch}.csv';
//       final file = File(path);
//       await file.writeAsString(csvData);
//       return path;
//     } catch (e) {
//       return null;
//     }
//   }
// }
//
// ///////////////////////////////////////////////////////////////////////////////
// // Notes & Next Steps
// ///////////////////////////////////////////////////////////////////////////////
//
// /*
// - This code is a starting point and covers the requested features: add/edit/delete guests, groups, RSVP status, event assignment, summary dashboard, local persistence with Hive, and CSV export.
//
// - You can refine UI (colors/typography) to more closely match WedMeGood/WeddingWire. The color palette in main.dart matches the prompt.
//
// - For production:
//   - Consider Hive encrypted box (for privacy).
//   - Add validation and better error handling.
//   - Add invitation sending integration (WhatsApp/Email API) and server-side syncing.
//   - Add pagination and performance improvements for very large guest lists.
//
// - If you want, I can also generate:
//   1) A sample REST API contract for syncing RSVPs.
//   2) A WhatsApp share template feature to send bulk invites using the system share sheet.
//   3) A seat planner / seating chart UI using the same guest model.
//
// */

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final List<Guest> _allGuests = [
    Guest(
      id: '1',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '+1234567890',
      category: 'Family',
      rsvpStatus: 'accepted',
      plusOnes: 1,
    ),
    Guest(
      id: '2',
      name: 'Jane Smith',
      email: 'jane@example.com',
      phone: '+1234567891',
      category: 'Friends',
      rsvpStatus: 'pending',
      plusOnes: 0,
      dietaryRestrictions: 'Vegetarian',
    ),
    Guest(
      id: '3',
      name: 'Bob Johnson',
      email: 'bob@example.com',
      phone: '+1234567892',
      category: 'Colleagues',
      rsvpStatus: 'declined',
      plusOnes: 0,
    ),
    Guest(
      id: '4',
      name: 'Alice Brown',
      email: 'alice@example.com',
      phone: '+1234567893',
      category: 'Family',
      rsvpStatus: 'accepted',
      plusOnes: 2,
    ),
  ];

  final List<String> _categories = ['All', 'Family', 'Friends', 'Colleagues', 'Others'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (val) => val!.isEmpty ? 'Required' : null,
                  onSaved: (val) => name = val!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
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
                  decoration: const InputDecoration(labelText: 'RSVP Status'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Plus Ones'),
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
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newGuest = Guest(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  email: email,
                  phone: phone,
                  category: category,
                  rsvpStatus: rsvpStatus,
                  plusOnes: plusOnes,
                  dietaryRestrictions: dietaryRestrictions,
                  address: address,
                );
                setState(() => _allGuests.add(newGuest));
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
            icon: const Icon(Icons.filter_list, color: Colors.black87),
            onPressed: _showFilterSheet,
          ),
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
      body: Column(
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
        onPressed: _showAddGuestDialog,
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
          const Text(
            'Total Attendees',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '$_totalAttendees',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Guests', '${_allGuests.length}', Icons.people),
              _buildStatItem('Accepted', '$_totalAccepted', Icons.check_circle),
              _buildStatItem('Pending', '$_totalPending', Icons.schedule),
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
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'message', child: Text('Send Message')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) => _handleGuestAction(value.toString(), guest),
        ),
      ),
    );
  }


  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                  selectedColor: const Color(0xFFFF69B4),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
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

  void _handleGuestAction(String action, Guest guest) {
    switch (action) {
      case 'edit':
        _showEditGuestDialog(guest); // Opens a form to edit guest
        break;
      case 'message':
        _sendMessageToGuest(guest); // Sends a message (placeholder)
        break;
      case 'delete':
        _deleteGuest(guest); // Deletes guest from the list
        break;
    }
  }

// EDIT GUEST
  void _showEditGuestDialog(Guest guest) {
    final _formKey = GlobalKey<FormState>();
    String name = guest.name;
    String email = guest.email;
    String phone = guest.phone;
    String category = guest.category;
    String rsvpStatus = guest.rsvpStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Guest'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => name = val!,
              ),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
                onSaved: (val) => email = val!,
              ),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
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
                decoration: const InputDecoration(labelText: 'RSVP Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF69B4)),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                setState(() {
                  guest.name = name;
                  guest.email = email;
                  guest.phone = phone;
                  guest.category = category;
                  guest.rsvpStatus = rsvpStatus;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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

