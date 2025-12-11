import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/einvite1/CustomizeCard.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ViewAllScreen.dart';







// class WeddingInvitesScreen1 extends StatefulWidget {
//   const WeddingInvitesScreen1({super.key});
//
//   @override
//   State<WeddingInvitesScreen1> createState() => _WeddingInvitesScreen1State();
// }
//
// class _WeddingInvitesScreen1State extends State<WeddingInvitesScreen1> {
//   final Color pink = const Color(0xFFE91E63);
//
//   List<Map<String, String>> weddingCards = [];
//   bool isLoading = true;
//
//   /// ✅ Draft Data
//   String? selectedImage;
//   String? selectedTitle;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchWeddingCards().then((_) => loadDrafts());
//
//   }
//
//   Future<void> fetchWeddingCards() async {
//     final url = Uri.parse('https://happywedz.com/api/einvites/cards');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['success'] == true) {
//           final List<Map<String, String>> fetchedCards = [];
//           for (var item in data['data']) {
//             String imageUrl = item['thumbnailUrl'] ?? '';
//             if (imageUrl.contains('happywedz.com')) {
//               imageUrl = imageUrl.replaceFirst(
//                   'happywedz.com', 'happywedzbackend.happywedz.com');
//             }
//
//             fetchedCards.add({
//               'title': item['name'] ?? 'Card',
//               'image': imageUrl,
//               'backgroundUrl': item['backgroundUrl'] ?? '',
//             });
//           }
//           setState(() {
//             weddingCards = fetchedCards;
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       print("Error fetching wedding cards: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   /// ✅ SAVE DRAFT
//   Future<void> _saveDraft() async {
//     if (selectedImage == null) {
//       print("❌ selectedImage is NULL");
//       return;
//     }
//
//     final prefs = await SharedPreferences.getInstance();
//     List<String> drafts = prefs.getStringList("draftList") ?? [];
//
//     Map<String, String> draftData = {
//       "image": selectedImage!,
//       "title": selectedTitle ?? "",
//     };
//
//     print("💾 Saving draft: $draftData");
//
//     drafts.add(jsonEncode(draftData));
//
//     await prefs.setStringList("draftList", drafts);
//
//     print("✅ Final drafts list saved: $drafts");
//   }
//
//   List<Map<String, String>> draftList = [];
//
//   Future<void> loadDrafts() async {
//     final prefs = await SharedPreferences.getInstance();
//     List<String> raw = prefs.getStringList("draftList") ?? [];
//
//     print("📥 Loaded drafts from SharedPrefs: $raw");
//
//     List<Map<String, String>> parsedList = [];
//
//     for (var item in raw) {
//       try {
//         final decoded = jsonDecode(item);
//
//         if (decoded is Map) {
//           // Convert everything inside the map to String
//           final cleanMap = decoded.map<String, String>(
//                 (key, value) => MapEntry(key.toString(), value.toString()),
//           );
//
//           parsedList.add(cleanMap);
//         }
//       } catch (err) {
//         print("❌ Error parsing entry: $item");
//       }
//     }
//
//     // Assign final parsed list
//     draftList = parsedList;
//
//     print("📦 Final parsed draftList = $draftList");
//
//     setState(() {});
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),
//               Color(0xFFFFB6C1),
//               Colors.white,
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // ✅ Budget-style AppBar
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//                 color: Colors.transparent,
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     Align(
//                       alignment: Alignment.centerLeft,
//                       child: IconButton(
//                         icon: const Icon(Icons.arrow_back, color: Colors.white),
//                         onPressed: () => Navigator.pop(context),
//                       ),
//                     ),
//                     Text(
//                       "E-Invites",
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 20,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: IconButton(
//                         icon: const Icon(Icons.save, color: Colors.white),
//                         tooltip: "Save Draft",
//                         onPressed: () async {
//                           await _saveDraft();
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => const DraftListScreen()),
//                           );
//                         },
//                       ),
//                     ),
//
//                   ],
//                 ),
//               ),
//
//               Expanded(
//                 child: isLoading
//                     ? const Center(child: CircularProgressIndicator())
//                     : SingleChildScrollView(
//                   padding: const EdgeInsets.only(bottom: 80),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 10),
//
//                       /// ✅ SHOW DRAFT
//
//                       const SizedBox(height: 20),
//
//                       /// ✅ BUILT SECTIONS
//                       _buildSection(
//                         title: "Wedding Cards",
//                         cards: weddingCards,
//                         context: context,
//                         pink: pink,
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       _buildSection(
//                         title: "Video Invites",
//                         cards: const [],
//                         context: context,
//                         pink: pink,
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       _buildSection(
//                         title: "Save The Date Cards",
//                         cards: const [],
//                         context: context,
//                         pink: pink,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSection({
//     required String title,
//     required List<Map<String, String>> cards,
//     required BuildContext context,
//     required Color pink,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           /// Header
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 title,
//                 style: GoogleFonts.poppins(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//
//               /// View All
//               GestureDetector(
//                 onTap: () async {
//                   await Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => ViewAllScreen(
//                         categoryTitle: title,
//                         cards: cards,
//                       ),
//                     ),
//                   );
//                   loadDrafts();
//                 },
//                 child: Row(
//                   children: [
//                     Text(
//                       "View all",
//                       style: GoogleFonts.poppins(
//                         color: pink,
//                         fontWeight: FontWeight.w500,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const Icon(
//                       Icons.arrow_forward_ios,
//                       size: 12,
//                       color: Color(0xFFE91E63),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//
//           /// Horizontal list
//           SizedBox(
//             height: 180,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: cards.isEmpty ? 4 : cards.length,
//               itemBuilder: (context, index) {
//                 return Padding(
//                   padding: const EdgeInsets.only(right: 8),
//                   child: InkWell(
//                     onTap: () {
//                       if (title == "Wedding Cards" && cards.isNotEmpty) {
//                         setState(() {
//                           selectedImage = cards[index]['image']!;
//                           selectedTitle = cards[index]['title']!;
//                         });
//
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => CustomizeCardScreen(
//                               templateImage: cards[index]['image']!,
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           height: 130,
//                           width: 95,
//                           decoration: cards.isEmpty
//                               ? BoxDecoration(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(12),
//                             border: Border.all(
//                                 color: Colors.grey[300]!),
//                           )
//                               : null,
//                           child: cards.isEmpty
//                               ? null
//                               : ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: Image.network(
//                               cards[index]['image']!,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         SizedBox(
//                           width: 95,
//                           child: cards.isEmpty
//                               ? Container(
//                             height: 14,
//                             decoration: BoxDecoration(
//                               color: Colors.grey[300],
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                           )
//                               : Text(
//                             cards[index]['title']!,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.poppins(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
//
// class DraftListScreen extends StatefulWidget {
//   const DraftListScreen({super.key});
//
//   @override
//   State<DraftListScreen> createState() => _DraftListScreenState();
// }
//
// class _DraftListScreenState extends State<DraftListScreen> {
//   List<Map<String, String>> draftList = [];
//
//   @override
//   void initState() {
//     super.initState();
//     loadDrafts();
//   }
//
//   Future<void> loadDrafts() async {
//     final prefs = await SharedPreferences.getInstance();
//     final List<String> raw = prefs.getStringList("draftList") ?? [];
//
//     List<Map<String, String>> parsedList = [];
//
//     for (var item in raw) {
//       try {
//         final decoded = jsonDecode(item);
//         if (decoded is Map) {
//           // Convert all values to String to ensure type safety
//           parsedList.add(decoded.map<String, String>(
//                   (key, value) => MapEntry(key.toString(), value.toString())));
//         }
//       } catch (e) {
//         print("❌ Failed to parse draft: $item -> $e");
//       }
//     }
//
//     setState(() {
//       draftList = parsedList;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Saved Drafts"),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//         titleTextStyle: const TextStyle(
//             color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//       body: draftList.isEmpty
//           ? const Center(child: Text("No drafts saved"))
//           : ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: draftList.length,
//         itemBuilder: (context, index) {
//           final imageUrl = draftList[index]["image"] ?? "";
//           final title = draftList[index]["title"] ?? "Draft ${index + 1}";
//
//           return GestureDetector(
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) =>
//                       CustomizeCardScreen(templateImage: imageUrl),
//                 ),
//               );
//             },
//             child: Container(
//               margin: const EdgeInsets.only(bottom: 20),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.1),
//                     blurRadius: 6,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Image.network(
//                       imageUrl,
//                       height: 250,
//                       width: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(8.0),
//                     child: Text(
//                       title,
//                       style: const TextStyle(
//                           fontSize: 16, fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

















































