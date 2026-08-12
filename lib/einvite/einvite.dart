// import 'package:flutter/material.dart';
// import 'package:happy_wedz/einvite/WeddingCard.dart';
//
// class WeddingInvitesScreen extends StatefulWidget {
//   const WeddingInvitesScreen({Key? key}) : super(key: key);
//
//   @override
//   State<WeddingInvitesScreen> createState() => _WeddingInvitesScreenState();
// }
//
// class _WeddingInvitesScreenState extends State<WeddingInvitesScreen> {
//   @override
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // ❌ Remove backgroundColor here
//       // backgroundColor: Colors.grey[50],
//
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'E-Invites',
//           style: TextStyle(
//             color: Colors.black87,
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.search, color: Colors.black54),
//             onPressed: () {},
//           ),
//           PopupMenuButton(
//             icon: const Icon(Icons.more_vert, color: Colors.black54),
//             itemBuilder: (context) => [
//               const PopupMenuItem(
//                 value: 'sort',
//                 child: Text('Sort by'),
//               ),
//               const PopupMenuItem(
//                 value: 'filter',
//                 child: Text('Filter'),
//               ),
//             ],
//           ),
//         ],
//       ),
//
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF69B4),   // Hot Pink
//               Color(0xFFFFB6C1),   // Light Pink
//               Colors.white,        // White
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildSectionHeader('Wedding Cards', onViewAll: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const WeddingCardsScreen()),
//                 );
//               }),
//               const SizedBox(height: 12),
//               _buildHorizontalCardList(_getWeddingCards()),
//
//               const SizedBox(height: 32),
//               _buildSectionHeader('Video Invites', onViewAll: () {}),
//               const SizedBox(height: 12),
//               _buildHorizontalCardList(_getVideoInvites()),
//
//               const SizedBox(height: 32),
//               _buildSectionHeader('Save The Date Cards', onViewAll: () {}),
//               const SizedBox(height: 12),
//               _buildHorizontalCardList(_getSaveTheDateCards()),
//
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   Widget _buildSectionHeader(String title, {required VoidCallback onViewAll}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//             color: Colors.black87,
//           ),
//         ),
//         TextButton(
//           onPressed: onViewAll,
//           child: const Text(
//             'View All >',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.blue,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildHorizontalCardList(List<InviteCard> cards) {
//     return SizedBox(
//       height: 200,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: cards.length,
//         itemBuilder: (context, index) {
//           final card = cards[index];
//           return Container(
//             width: 140,
//             margin: EdgeInsets.only(
//               right: index == cards.length - 1 ? 0 : 12,
//             ),
//             child: _buildInviteCard(card),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildInviteCard(InviteCard card) {
//     return GestureDetector(
//       onTap: () {
//         // Handle card tap
//         _showCardPreview(card);
//       },
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             height: 140,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               gradient: card.gradient,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.1),
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Stack(
//               children: [
//                 // Background pattern/decoration
//                 Positioned.fill(
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       gradient: card.gradient,
//                     ),
//                     child: card.isVideo
//                         ? const Center(
//                       child: Icon(
//                         Icons.play_circle_fill,
//                         color: Colors.white,
//                         size: 40,
//                       ),
//                     )
//                         : _buildCardPattern(card.pattern),
//                   ),
//                 ),
//                 // Content overlay
//                 Positioned.fill(
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [
//                           Colors.transparent,
//                           Colors.black.withValues(alpha: 0.3),
//                         ],
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         if (card.isVideo)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6,
//                               vertical: 2,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black54,
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               card.duration ?? '',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             card.title,
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w500,
//               color: Colors.black87,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 4),
//           Row(
//             children: [
//               Text(
//                 card.price,
//                 style: TextStyle(
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   color: card.isFree ? Colors.green : Colors.orange[700],
//                 ),
//               ),
//               if (!card.isFree) ...[
//                 const SizedBox(width: 4),
//                 Text(
//                   card.originalPrice ?? '',
//                   style: const TextStyle(
//                     fontSize: 10,
//                     decoration: TextDecoration.lineThrough,
//                     color: Colors.grey,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCardPattern(String pattern) {
//     switch (pattern) {
//       case 'floral':
//         return Stack(
//           children: [
//             Positioned(
//               top: 10,
//               right: 10,
//               child: Container(
//                 width: 20,
//                 height: 20,
//                 decoration: const BoxDecoration(
//                   color: Colors.white30,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 20,
//               left: 15,
//               child: Container(
//                 width: 15,
//                 height: 15,
//                 decoration:  BoxDecoration(
//                   color: Colors.white70,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//           ],
//         );
//       case 'geometric':
//         return CustomPaint(
//           painter: GeometricPatternPainter(),
//         );
//       case 'traditional':
//         return Container(
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.white30, width: 1),
//           ),
//           margin: const EdgeInsets.all(8),
//         );
//       default:
//         return Container();
//     }
//   }
//
//   void _showCardPreview(InviteCard card) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: 400,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     Container(
//                       height: 200,
//                       decoration: BoxDecoration(
//                         gradient: card.gradient,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Center(
//                         child: card.isVideo
//                             ? const Icon(Icons.play_circle_fill,
//                             color: Colors.white, size: 60)
//                             : Text(
//                           card.title,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       card.title,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       card.price,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: card.isFree ? Colors.green : Colors.orange[700],
//                       ),
//                     ),
//                     const Spacer(),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           // Handle customize action
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         child: const Text(
//                           'Customize',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<InviteCard> _getWeddingCards() {
//     return [
//       InviteCard(
//         title: 'Floral Elegance',
//         price: 'Free',
//         isFree: true,
//         gradient: const LinearGradient(
//           colors: [Color(0xFFFFB6C1), Color(0xFFFF69B4)],
//         ),
//         pattern: 'floral',
//       ),
//       InviteCard(
//         title: 'Royal Heritage',
//         price: '₹149',
//         originalPrice: '₹299',
//         gradient: const LinearGradient(
//           colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
//         ),
//         pattern: 'traditional',
//       ),
//       InviteCard(
//         title: 'Garden Bliss',
//         price: '₹99',
//         originalPrice: '₹199',
//         gradient: const LinearGradient(
//           colors: [Color(0xFF98FB98), Color(0xFF90EE90)],
//         ),
//         pattern: 'floral',
//       ),
//     ];
//   }
//
//   List<InviteCard> _getVideoInvites() {
//     return [
//       InviteCard(
//         title: 'Royal Engagement',
//         price: '₹249',
//         originalPrice: '₹499',
//         duration: '0:45',
//         isVideo: true,
//         gradient: const LinearGradient(
//           colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
//         ),
//       ),
//       InviteCard(
//         title: 'We Found You',
//         price: '₹199',
//         originalPrice: '₹399',
//         duration: '0:30',
//         isVideo: true,
//         gradient: const LinearGradient(
//           colors: [Color(0xFF98FB98), Color(0xFF32CD32)],
//         ),
//       ),
//       InviteCard(
//         title: 'Ganesh Fiber',
//         price: '₹299',
//         originalPrice: '₹599',
//         duration: '1:00',
//         isVideo: true,
//         gradient: const LinearGradient(
//           colors: [Color(0xFFFF8C00), Color(0xFFFF6347)],
//         ),
//       ),
//     ];
//   }
//
//   List<InviteCard> _getSaveTheDateCards() {
//     return [
//       InviteCard(
//         title: 'Tropical Vibes',
//         price: 'Free',
//         isFree: true,
//         gradient: const LinearGradient(
//           colors: [Color(0xFF00CED1), Color(0xFF20B2AA)],
//         ),
//         pattern: 'geometric',
//       ),
//       InviteCard(
//         title: 'At Last',
//         price: '₹79',
//         originalPrice: '₹159',
//         gradient: const LinearGradient(
//           colors: [Color(0xFF4682B4), Color(0xFF1E90FF)],
//         ),
//         pattern: 'geometric',
//       ),
//       InviteCard(
//         title: 'Royal Celebration',
//         price: '₹129',
//         originalPrice: '₹259',
//         gradient: const LinearGradient(
//           colors: [Color(0xFFDC143C), Color(0xFFB22222)],
//         ),
//         pattern: 'traditional',
//       ),
//     ];
//   }
// }
//
// class InviteCard {
//   final String title;
//   final String price;
//   final String? originalPrice;
//   final bool isFree;
//   final String? duration;
//   final bool isVideo;
//   final LinearGradient gradient;
//   final String pattern;
//
//   InviteCard({
//     required this.title,
//     required this.price,
//     this.originalPrice,
//     this.isFree = false,
//     this.duration,
//     this.isVideo = false,
//     required this.gradient,
//     this.pattern = 'default',
//   });
// }
//
// class GeometricPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withValues(alpha: 0.2)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;
//
//     // Draw some geometric lines
//     canvas.drawLine(
//       Offset(0, size.height * 0.3),
//       Offset(size.width * 0.6, 0),
//       paint,
//     );
//
//     canvas.drawLine(
//       Offset(size.width * 0.4, size.height),
//       Offset(size.width, size.height * 0.7),
//       paint,
//     );
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }