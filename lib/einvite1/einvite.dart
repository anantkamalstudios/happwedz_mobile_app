import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/einvite1/CustomizeCard.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'ViewAllScreen.dart';

import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';






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






























import 'package:flutter/material.dart';

// Rich_EInvitation_UI.dart
// A single-file Flutter screen that implements a rich & professional UI
// for E-Invitations and Wedding Website templates with horizontal cards.

// class EInvitationScreen extends StatelessWidget {
//   const EInvitationScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F7F9),
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         foregroundColor: Colors.black87,
//         title: const Text('Create Your E-Invitation', style: TextStyle(fontWeight: FontWeight.w700)),
//         centerTitle: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 8),
//
//             // Section header: Choose Your Invitation Type
//             _SectionHeader(
//               title: 'Choose Your Invitation Type',
//               subtitle: 'Select from our beautiful collection of invitation templates',
//             ),
//
//             const SizedBox(height: 12),
//
//             // Horizontal list of invitation types
//             SizedBox(
//               height: 250,
//               child: ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: invitationItems.length,
//                 separatorBuilder: (_, __) => const SizedBox(width: 12),
//                 itemBuilder: (context, index) {
//                   final item = invitationItems[index];
//                   return InvitationCard(item: item);
//                 },
//               ),
//             ),
//
//
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ======= Section header widget =======
// class _SectionHeader extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   const _SectionHeader({required this.title, required this.subtitle});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
//         const SizedBox(height: 4),
//         Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.black54)),
//       ],
//     );
//   }
// }
//
// // ======= Models & sample data =======
// class InvitationItem {
//   final String title;
//   final String short;
//   final String description;
//   final String image;
//
//   InvitationItem({required this.title, required this.short, required this.description, required this.image});
// }
//
// final List<InvitationItem> invitationItems = [
//   InvitationItem(
//     title: 'Wedding E-Invitations',
//     short: 'Wedding E-Invitations',
//     description: 'Beautiful digital wedding invitation cards',
//     image: 'assets/invite1.jpg',
//   ),
//   InvitationItem(
//     title: 'Video Invitations',
//     short: 'Video Invitations',
//     description: 'Dynamic video invitation templates',
//     image: 'assets/commingsoon2.jpg',
//   ),
//   InvitationItem(
//     title: 'Save the Date',
//     short: 'Save the Date',
//     description: 'Save the date card templates',
//     image: 'assets/std3.jpg',
//   ),
// ];
//
//
// // ======= Invitation card widget =======
// class InvitationCard extends StatelessWidget {
//   final InvitationItem item;
//   const InvitationCard({Key? key, required this.item}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final cardWidth = MediaQuery.of(context).size.width * 0.62;
//
//     return GestureDetector(
//       onTap: () {
//         // handle selection
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(item.title),
//             content: Text(item.description),
//             actions: [
//               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
//             ],
//           ),
//         );
//       },
//       child: SizedBox(
//         width: cardWidth,
//         child: Card(
//           elevation: 6,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           clipBehavior: Clip.antiAlias,
//           child: Stack(
//             children: [
//               // Background image
//               Positioned.fill(
//                 child: Image.asset(
//                   item.image,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//
//               // Gradient overlay
//               Positioned.fill(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [Colors.transparent, Colors.black45.withOpacity(0.6)],
//                     ),
//                   ),
//                 ),
//               ),
//
//               // Content
//               Positioned(
//                 left: 14,
//                 right: 14,
//                 bottom: 14,
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(item.short, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
//                           const SizedBox(height: 4),
//                           Text(item.description, style: const TextStyle(color: Colors.white70, fontSize: 12)),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     // _SelectButton()
//                   ],
//                 ),
//               ),
//
//               // Top-left badge
//               // Positioned(
//               //   left: 12,
//               //   top: 12,
//               //   child: Container(
//               //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               //     decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(8)),
//               //     child: const Text('Featured', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
//               //   ),
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // class _SelectButton extends StatelessWidget {
// //   const _SelectButton({Key? key}) : super(key: key);
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return ElevatedButton(
// //       onPressed: () {},
// //       style: ElevatedButton.styleFrom(
// //         elevation: 4,
// //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
// //         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
// //       ),
// //       child: const Text('Choose', style: TextStyle(fontWeight: FontWeight.w700)),
// //     );
// //   }
// // }
//
// // ======= Website template card =======
//
// // ======= End of file =======
class EInvitationScreen extends StatelessWidget {
  const EInvitationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Create Your E-Invitation',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              _SectionHeader(
                title: 'Choose Your Invitation Type',
                subtitle: 'Select from our beautiful collection of invitation templates',
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: invitationTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = invitationTypes[index];
                    return CategoryCard(item: item);
                  },
                ),
              ),



              const SizedBox(height: 24),

              /// ----------------------
              /// SECTION 2: Wedding Website Templates
              /// ----------------------
              const _SectionHeader(
                title: 'Choose Your Wedding Website Template',
                subtitle: 'Select the perfect design to tell your love story',
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 260,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weddingWebsiteTemplates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = weddingWebsiteTemplates[index];
                    return WeddingWebsiteCard(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final List<Map<String, String>> weddingWebsiteTemplates = [
  {
    "title": "Royal Theme",
    "subtitle": "Elegant gold and white wedding theme.",
    "image": "assets/index1.png",
      "url": "https://happywedz.com/wedding-form/royal",
  },
  {
    "title": "Floral Theme",
    "subtitle": "Soft romantic floral design.",
    "image": "assets/floral2.png",
  "url": "https://happywedz.com/wedding-form/floral",

  },
  {
    "title": "Modern Theme",
    "subtitle": "Modern and sleek design.",
    "image": "assets/mordern3.png",
  "url": "https://happywedz.com/wedding-form/modern",

  },
];

class WeddingWebsiteCard extends StatelessWidget {
  final Map<String, String> item;

  const WeddingWebsiteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.62;

    return GestureDetector(
      onTap: () async {
        final Uri uri = Uri.parse(item["url"]!);

        try {
          bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (!launched) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Unable to open browser")));
        }
      },
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  item["image"]!,
                  fit: BoxFit.cover,
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),

              Positioned(
                left: 14,
                bottom: 40,
                child: Text(
                  item["title"]!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Positioned(
                left: 14,
                bottom: 18,
                child: Text(
                  item["subtitle"]!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),

              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Click to Select",
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class EInviteCard {
  final String id;
  final String name;
  final String cardType;
  final String thumbnailUrl;
  final String backgroundUrl;
  final List<EInviteEditableField> editableFields;

  EInviteCard({
    required this.id,
    required this.name,
    required this.cardType,
    required this.thumbnailUrl,
    required this.backgroundUrl,
    required this.editableFields,
  });

  factory EInviteCard.fromJson(Map<String, dynamic> json) {
    return EInviteCard(
      id: json['id'],
      name: json['name'],
      cardType: json['cardType'],
      thumbnailUrl: json['thumbnailUrl'],
      backgroundUrl: json['backgroundUrl'],
      editableFields: (json['editableFields'] as List)
          .map((e) => EInviteEditableField.fromJson(e))
          .toList(),
    );
  }
}


final einviteProvider = FutureProvider<List<EInviteCard>>((ref) async {
  final url = Uri.parse('https://happywedz.com/api/einvites/cards');
  final res = await http.get(url);

  if (res.statusCode != 200) {
    throw Exception("Failed to load E-Invite cards");
  }

  final body = jsonDecode(res.body);

  if (body['success'] != true) {
    throw Exception("API returned success: false");
  }

  final List rawData = body['data'];

  final List<EInviteCard> cards = rawData.map((item) {
    // Fix incorrect image domain for thumbnail
    String thumb = (item['thumbnailUrl'] ?? "").replaceFirst(
      "happywedz.com",
      "happywedzbackend.happywedz.com",
    );

    // Fix domain for background image
    String bg = (item['backgroundUrl'] ?? "").replaceFirst(
      "happywedz.com",
      "happywedzbackend.happywedz.com",
    );

    // Parse editable fields
    final List<EInviteEditableField> fields =
    (item['editableFields'] as List)
        .map((f) => EInviteEditableField.fromJson(f))
        .toList();

    return EInviteCard(
      id: item['id'] ?? "",
      name: item['name'] ?? "Card",
      cardType: item['cardType'] ?? "",
      thumbnailUrl: thumb,
      backgroundUrl: bg,
      editableFields: fields,
    );
  }).toList();

  return cards;
});


final List<Map<String, String>> invitationTypes = [
  {"title": "Wedding E-Invitations", "type": "wedding_einvite", "image": "assets/invite1.jpg"},
  {"title": "Save The Date", "type": "save_the_date", "image": "assets/std3.jpg"},
  {"title": "Video Invitations", "type": "video_invitation", "image": "assets/commingsoon2.jpg"},
];
class CategoryCard extends StatelessWidget {
  final Map<String, String> item;
  const CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.62;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TemplateListByTypeScreen(cardType: item["type"]!, title: item["title"]!),
          ),
        );
      },
      child: SizedBox(
        width: cardWidth,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  item["image"]!,
                  fit: BoxFit.cover,
                ),
              ),

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black45],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 14,
                bottom: 14,
                child: Text(
                  item["title"]!,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}


class TemplateListByTypeScreen extends ConsumerWidget {
  final String cardType;
  final String title;

  const TemplateListByTypeScreen({required this.cardType, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCards = ref.watch(einviteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(Icons.drafts_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DraftListScreen()),
              );
            },
          ),
        ],
      ),
      body: asyncCards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
        data: (cards) {
          final filtered = cards.where((c) => c.cardType == cardType).toList();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                "Coming Soon!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = filtered[index];
              return EInviteTemplateCard(item: item);
            },
          );
        },
      ),
    );
  }
}



class EInviteTemplateCard extends StatelessWidget {
  final EInviteCard item;
  const EInviteTemplateCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditorScreen(
                card: item,
              ),
            ),
          );
        },


      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.network(
                item.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }
}


class EditorScreen extends StatefulWidget {
  final EInviteCard card;
  final List? prefilledFields;


  const EditorScreen({required this.card,this.prefilledFields, Key? key}) : super(key: key);

  @override
  _EditorScreenState createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  List<Map<String, dynamic>> fields = [];
  List<List<Map<String, dynamic>>> undoStack = [];
  GlobalKey previewKey = GlobalKey();

  Map<String, dynamic>? selectedField;

  @override
  void initState() {
    super.initState();
    loadEditableFields();
  }

  void loadEditableFields() {
    if (widget.prefilledFields != null) {
      // Load from saved draft
      fields = widget.prefilledFields!.map<Map<String, dynamic>>((f) {
        return {
          "id": f["id"],
          "x": f["x"],
          "y": f["y"],
          "text": f["text"],
          "color": f["color"],
          "fontSize": f["fontSize"].toDouble(),
          "fontFamily": f["fontFamily"],
          "fontWeight":
          f["fontWeight"] == "bold" ? FontWeight.bold : FontWeight.normal,
          "fontStyle":
          f["fontStyle"] == "italic" ? FontStyle.italic : FontStyle.normal,
        };
      }).toList();
    } else {
      // Load template fields (default values)
      fields = widget.card.editableFields.map((f) {
        return {
          "id": f.id,
          "x": f.x,
          "y": f.y,
          "text": f.defaultText,
          "color": f.color,
          "fontSize": f.fontSize.toDouble(),
          "fontFamily": f.fontFamily,

          // Templates never include bold/italic → set default values
          "fontWeight": FontWeight.normal,
          "fontStyle": FontStyle.normal,
        };
      }).toList();
    }

    setState(() {});
  }


  void pushUndo() {
    undoStack.add(fields.map((e) => Map<String, dynamic>.from(e)).toList());
  }

  void undoAction() {
    if (undoStack.isEmpty) return;
    setState(() => fields = undoStack.removeLast());
  }

  void saveDraft() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1️⃣ Generate preview image from canvas
    RenderRepaintBoundary boundary =
    previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    // 2️⃣ Save image file locally
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/draft_${widget.card.id}.png");
    await file.writeAsBytes(pngBytes);

    // 3️⃣ Save JSON draft + image path
    String jsonData = jsonEncode({
      "cardId": widget.card.id,
      "name": widget.card.name,
      "thumbnail": widget.card.thumbnailUrl,
      "background": widget.card.backgroundUrl,
      "fields": fields.map((f) {
        return {
          "id": f["id"],
          "x": f["x"],
          "y": f["y"],
          "text": f["text"],
          "color": f["color"],
          "fontSize": f["fontSize"],
          "fontFamily": f["fontFamily"],
          "fontWeight": f["fontWeight"] == FontWeight.bold ? "bold" : "normal",
          "fontStyle": f["fontStyle"] == FontStyle.italic ? "italic" : "normal",
        };
      }).toList(),
      "imagePath": file.path, // <<< IMPORTANT
    });

    await prefs.setString("draft_${widget.card.id}", jsonData);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Draft Saved")));
  }

  void deleteField(Map field) {
    pushUndo();
    setState(() {
      fields.remove(field);
      selectedField = null;
    });
  }

  void exportAsImage() async {
    RenderRepaintBoundary boundary =
    previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 3);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    Uint8List pngBytes = byteData!.buffer.asUint8List();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalPreviewScreen(
          cardBytes: pngBytes,
          cardId: widget.card.id,
        ),
      ),
    );
  }

  void _requireSelection() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Select text first")));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.card.name),
        ),

        body: Column(
          children: [
            // Canvas Area
            Expanded(
              child: Center(
                child: RepaintBoundary(
                  key: previewKey,
                  child: AspectRatio(
                    aspectRatio: 0.60,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            widget.card.backgroundUrl,
                            fit: BoxFit.cover,
                          ),
                        ),

                        ...fields.map((field) {
                          final isSelected = selectedField == field;

                          return Positioned(
                            left: field["x"],
                            top: field["y"],
                            child: GestureDetector(
                              onPanStart: (_) {
                                selectedField = field;
                                pushUndo();
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  field["x"] += details.delta.dx;
                                  field["y"] += details.delta.dy;
                                });
                              },
                              onTap: () => setState(() {
                                selectedField = field;
                                openEditDialog(field);
                              }),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                    isSelected ? Colors.blue : Colors.pinkAccent,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  field["text"],
                                  style: TextStyle(
                                    fontFamily: field["fontFamily"],
                                    fontSize: field["fontSize"],
                                    fontWeight: field["fontWeight"],
                                    fontStyle: field["fontStyle"],
                                    color: Color(
                                      int.parse(field["color"]
                                          .substring(1, 7),
                                          radix: 16) +
                                          0xFF000000,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // TOOLBAR
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _toolbarButton("Edit", Icons.edit, () {
                        selectedField != null
                            ? openEditDialog(selectedField!)
                            : _requireSelection();
                      }),

                      // _toolbarButton("Size", Icons.text_fields, () {
                      //   selectedField != null
                      //       ? openSizeDialog(selectedField!)
                      //       : _requireSelection();
                      // }),

                      _toolbarButton("Delete", Icons.delete, () {
                        selectedField != null
                            ? deleteField(selectedField!)
                            : _requireSelection();
                      }),

                      _toolbarButton("Undo", Icons.undo, undoAction),
                      _toolbarButton("Save", Icons.save, saveDraft),
                    ],
                  ),

                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: exportAsImage,
                      child: Text("Next",style: TextStyle(color: Colors.white),),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black87),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // SIZE POPUP
  void openSizeDialog(Map field) {
    double size = field["fontSize"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Adjust Size"),
        content: Slider(
          min: 10,
          max: 90,
          value: size,
          onChanged: (v) => setState(() => size = v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel")),
          TextButton(
            onPressed: () {
              pushUndo();
              setState(() => field["fontSize"] = size);
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }
  TextStyle _getFontStyle(Map field) {
    final font = field["fontFamily"] ?? "Aguafina Script";

    switch (font) {
      case "Aladin":
        return GoogleFonts.aladin(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "Galada":
        return GoogleFonts.galada(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "WindSong":
        return GoogleFonts.windSong(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "Comforter":
        return GoogleFonts.comforter(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "Aguafina Script":
        return GoogleFonts.aguafinaScript(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "Abril Fatface":
        return GoogleFonts.abrilFatface(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "Chilanka":
        return GoogleFonts.chilanka(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      case "Acme":
        return GoogleFonts.acme(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );

      default:
        return GoogleFonts.aBeeZee(
          fontSize: field["fontSize"],
          fontWeight: field["fontWeight"],
          fontStyle: field["fontStyle"],
          color: _getColor(field),
        );
    }
  }

  Color _getColor(Map field) {
    return Color(
      int.parse(field["color"].substring(1, 7), radix: 16) + 0xFF000000,
    );
  }

  // EDIT POPUP FULL
  void openEditDialog(Map field) {
    TextEditingController controller =
    TextEditingController(text: field["text"]);

    double fontSize = field["fontSize"];
    Color currentColor = Color(
      int.parse(field["color"].substring(1, 7), radix: 16) + 0xFF000000,
    );

    bool isBold = field["fontWeight"] == FontWeight.bold;
    bool isItalic = field["fontStyle"] == FontStyle.italic;

    String fontFamily = field["fontFamily"];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setPop) {
          return AlertDialog(
            title: Text("Edit Text"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: controller),

                  SizedBox(height: 20),

                  /// COLOR PICKER
                  Row(
                    children: [
                      Text("Color: "),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text("Pick Color"),
                              content: BlockPicker(
                                pickerColor: currentColor,
                                onColorChanged: (c) =>
                                    setPop(() => currentColor = c),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: Text("Done"))
                              ],
                            ),
                          );
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: currentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    ],
                  ),

                  SizedBox(height: 20),

                  /// BOLD / ITALIC
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: Text("Bold"),
                        selected: isBold,
                        onSelected: (v) =>
                            setPop(() => isBold = v),
                      ),
                      SizedBox(width: 12),
                      ChoiceChip(
                        label: Text("Italic"),
                        selected: isItalic,
                        onSelected: (v) =>
                            setPop(() => isItalic = v),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  /// FONT SIZE
                  Text("Font Size: ${fontSize.toInt()}"),
                  Slider(
                    min: 10,
                    max: 90,
                    value: fontSize,
                    onChanged: (v) => setPop(() => fontSize = v),
                  ),

                  // SizedBox(height: 20),
                  //
                  // /// FONT FAMILY DROPDOWN
                  // DropdownButton<String>(
                  //   value: fontFamily,
                  //   items: [
                  //     "Aguafina Script",
                  //     "Comforter",
                  //     "Alex Brush",
                  //     "Abril Fatface",
                  //     "Aladin",
                  //     "Galada",
                  //     "WindSong",
                  //     "Chilanka",
                  //     "Acme",
                  //   ].map((f) => DropdownMenuItem(
                  //     value: f,
                  //     child: Text(f),
                  //   )).toList(),
                  //   onChanged: (v) => setPop(() => fontFamily = v!),
                  // )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel")),

              TextButton(
                onPressed: () {
                  pushUndo();
                  setState(() {
                    field["text"] = controller.text;
                    field["fontSize"] = fontSize;
                    field["fontFamily"] = fontFamily;
                    field["color"] =
                    "#${currentColor.value.toRadixString(16).substring(2)}";
                    field["fontWeight"] =
                    isBold ? FontWeight.bold : FontWeight.normal;
                    field["fontStyle"] =
                    isItalic ? FontStyle.italic : FontStyle.normal;
                  });
                  Navigator.pop(context);
                },
                child: Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
}


class EInviteEditableField {
  final double x;
  final double y;
  final String id;
  final String color;
  final String label;
  final double fontSize;
  final String fontFamily;
  final String defaultText;

  EInviteEditableField({
    required this.x,
    required this.y,
    required this.id,
    required this.color,
    required this.label,
    required this.fontSize,
    required this.fontFamily,
    required this.defaultText,
  });

  factory EInviteEditableField.fromJson(Map<String, dynamic> json) {
    return EInviteEditableField(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      id: json['id'],
      color: json['color'],
      label: json['label'],
      fontSize: (json['fontSize'] as num).toDouble(),
      fontFamily: json['fontFamily'],
      defaultText: json['defaultText'],
    );
  }
}
class DraftListScreen extends StatefulWidget {
  @override
  _DraftListScreenState createState() => _DraftListScreenState();
}

class _DraftListScreenState extends State<DraftListScreen> {
  List<Map<String, dynamic>> drafts = [];

  @override
  void initState() {
    super.initState();
    loadDrafts();
  }

  void loadDrafts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> temp = [];

    for (String key in prefs.getKeys()) {
      if (key.startsWith("draft_")) {
        String? raw = prefs.getString(key);
        if (raw != null) {
          temp.add(jsonDecode(raw));
        }
      }
    }

    setState(() => drafts = temp);
  }

  void deleteDraft(String cardId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("draft_$cardId");
    loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Saved Drafts")),

      body: drafts.isEmpty
          ? Center(child: Text("No drafts saved"))
          : ListView.builder(
        itemCount: drafts.length,
        itemBuilder: (context, index) {
          final d = drafts[index];

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Image.network(
                d["thumbnail"],
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),

              title: Text(d["name"]),
              subtitle: Text("Tap to edit draft"),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(
                      card: EInviteCard(
                        id: d["cardId"],
                        name: d["name"],
                        cardType: "",
                        thumbnailUrl: d["thumbnail"],
                        backgroundUrl: d["background"],
                        editableFields: [], // Not required
                      ),
                      prefilledFields: List<Map<String, dynamic>>.from(d["fields"]),
                    ),
                  ),
                );
              },

              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () async {
                      final file = File(d["imagePath"]);

                      if (!file.existsSync()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Image not found")),
                        );
                        return;
                      }

                      Share.shareXFiles(
                        [XFile(file.path)],
                        text: "My Invitation Card",
                      );
                    },
                  ),

                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteDraft(d["cardId"]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}





class DraftEditorScreen extends StatelessWidget {
  final String templateId;
  final List savedFields;

  const DraftEditorScreen({
    required this.templateId,
    required this.savedFields,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadOriginalCard(templateId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Scaffold(body: Center(child: CircularProgressIndicator()));

        final card = snapshot.data as EInviteCard;

        return EditorScreen(
          card: card,
          prefilledFields: savedFields,
        );
      },
    );
  }

  Future<EInviteCard> loadOriginalCard(String id) async {
    final url = Uri.parse("https://happywedz.com/api/einvites/cards/$id");
    final res = await http.get(url);
    final body = jsonDecode(res.body)["data"];
    return EInviteCard.fromJson(body);
  }

}
class FinalPreviewScreen extends StatelessWidget {
  final Uint8List cardBytes;
  final String cardId;

  const FinalPreviewScreen({
    Key? key,
    required this.cardBytes,
    required this.cardId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preview"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                padding: EdgeInsets.all(12),
                color: Colors.grey.shade200,
                child: Image.memory(cardBytes),
              ),
            ),
          ),

          // --- Bottom Buttons ---
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _actionButton(Icons.share, "Share", () {
                      Share.shareXFiles(
                        [XFile.fromData(cardBytes, mimeType: "image/png")],
                        text: "Here is my invitation card!",
                      );
                    }),

                    _actionButton(Icons.download, "Save", () async {
                      final dir = await getApplicationDocumentsDirectory();
                      final file = File("${dir.path}/invite_${cardId}.png");
                      await file.writeAsBytes(cardBytes);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Saved Successfully")),
                      );
                    }),
                  ],
                ),

                SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text("Done", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 30, color: Colors.black87),
          SizedBox(height: 6),
          Text(text, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}



class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({required this.url, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Wedding Website"),
      ),
      body: WebViewWidget(
        controller: WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(url)),
      ),
    );
  }
}
