// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class Homescreen extends StatefulWidget {
//   const Homescreen({super.key});
//
//   @override
//   State<Homescreen> createState() => _HomescreenState();
// }
//
// class _HomescreenState extends State<Homescreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//     body:SingleChildScrollView(
//       child: Column(
//         children: [
//           Container(
//             width: 430,
//             height: 112,
//             clipBehavior: Clip.hardEdge,
//             decoration: const BoxDecoration(
//               color: Color(0xFFE83580),
//               boxShadow: [
//                 BoxShadow(
//                   color: Color(0x3FB8B8B8),
//                   spreadRadius: 0,
//                   offset: Offset(0, 4),
//                   blurRadius: 4,
//                 )
//               ],
//             ),
//           ),
//           Container(
//             width: 430,
//             height: 142,
//             clipBehavior: Clip.hardEdge,
//             decoration: const BoxDecoration(
//               color: Color(0x0CE83580),
//             ),
//           ),
//           SizedBox(height: 10,),
//
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               'Wedding Planning tools',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.getFont(
//                 'Poltawski Nowy',
//                 color: Colors.black,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//           SizedBox(height: 10,),
//           Row(
//             children: [
//               Container(
//                 width: 122,
//                 height: 106,
//                 clipBehavior: Clip.hardEdge,
//                 decoration: const BoxDecoration(
//                   color: Color(0x117732FF),
//                 ),
//               ),
//               SizedBox(width: 10,),
//               Container(
//                 width: 122,
//                 height: 106,
//                 clipBehavior: Clip.hardEdge,
//                 decoration: const BoxDecoration(
//                   color: Color(0x38FBAA47),
//                 ),
//               ),
//               SizedBox(width: 10,),
//               Container(
//                 width: 122,
//                 height: 106,
//                 clipBehavior: Clip.hardEdge,
//                 decoration: const BoxDecoration(
//                   color: Color(0x38FBAA47),
//                 ),
//               )
//             ],
//           ),
//           SizedBox(height: 10,),
//
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               'Venues in your city',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.getFont(
//                 'Poltawski Nowy',
//                 color: Colors.black,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//           SizedBox(height: 10,),
//           Row(
//             children: [
//               Container(
//                 width: 202,
//                 height: 238,
//                 clipBehavior: Clip.hardEdge,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   border: Border.all(
//                     color: const Color(0x11E83580),
//                   ),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x3F000000),
//                       spreadRadius: 0,
//                       offset: Offset(0, 4),
//                       blurRadius: 4,
//                     )
//                   ],
//                 ),
//               ),
//               SizedBox(width: 10,),
//               Container(
//                 width: 202,
//                 height: 238,
//                 clipBehavior: Clip.hardEdge,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   border: Border.all(
//                     color: const Color(0x11E83580),
//                   ),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x3F000000),
//                       spreadRadius: 0,
//                       offset: Offset(0, 4),
//                       blurRadius: 4,
//                     )
//                   ],
//                 ),
//               )
//             ],
//           ),
//           SizedBox(height: 10,),
//           Container(
//             width: 382,
//             height: 48,
//             clipBehavior: Clip.hardEdge,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(
//                 color: const Color(0xFFE83580),
//               ),
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.white,
//                   spreadRadius: 0,
//                   offset: Offset(0, 4),
//                   blurRadius: 4,
//                 )
//               ],
//             ),
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     gradient: const LinearGradient(
//                       colors: [Color(0x1EFFFFFF), Color(0x00FFFFFF)],
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   left: 139,
//                   top: 13,
//                   child: Text(
//                     'View all venues ',
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.getFont(
//                       'Inter',
//                       color: const Color(0xFFA60F93),
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       letterSpacing: -0.1,
//                       height: 1.4,
//                     ),
//                   ),
//                 ),
//
//               ],
//             ),
//           ),
//           SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               'Photographer for you',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.getFont(
//                 'Poltawski Nowy',
//                 color: Colors.black,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//           SizedBox(height: 10,),
//             Row(
//               children: [
//                 Container(
//                   width: 202,
//                   height: 238,
//                   clipBehavior: Clip.hardEdge,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(
//                       color: const Color(0x11E83580),
//                     ),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x3F000000),
//                         spreadRadius: 0,
//                         offset: Offset(0, 4),
//                         blurRadius: 4,
//                       )
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 10,),
//                 Container(
//                   width: 202,
//                   height: 238,
//                   clipBehavior: Clip.hardEdge,
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border.all(
//                       color: const Color(0x11E83580),
//                     ),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x3F000000),
//                         spreadRadius: 0,
//                         offset: Offset(0, 4),
//                         blurRadius: 4,
//                       )
//                     ],
//                   ),
//                 )
//               ],
//             ),
//           SizedBox(height: 10,),
//           Container(
//             width: 382,
//             height: 48,
//             clipBehavior: Clip.hardEdge,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(
//                 color: const Color(0xFFE83580),
//               ),
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.white,
//                   spreadRadius: 0,
//                   offset: Offset(0, 4),
//                   blurRadius: 4,
//                 )
//               ],
//             ),
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     gradient: const LinearGradient(
//                       colors: [Color(0x1EFFFFFF), Color(0x00FFFFFF)],
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   left: 114,
//                   top: 13,
//                   child: Text(
//                     'View all photographers ',
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.getFont(
//                       'Inter',
//                       color: const Color(0xFFA60F93),
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       letterSpacing: -0.1,
//                       height: 1.4,
//                     ),
//                   ),
//                 )
//               ],
//             ),
//           ),
//           SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               'Wedding checklist',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.getFont(
//                 'Poltawski Nowy',
//                 color: Colors.black,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//           SizedBox(height: 10,),
//          Column(
//            children: [
//              Container(
//                width: 382,
//                height: 135,
//                clipBehavior: Clip.hardEdge,
//                decoration: BoxDecoration(
//                  borderRadius: BorderRadius.circular(10),
//                  gradient: const LinearGradient(
//                    colors: [Color(0xFFB52963), Color(0xFFE83580), Color(0xFFF96909)],
//                    stops: [0, 0.50, 1],
//                  ),
//                ),
//              ),
//              Container(
//                width: 347,
//                height: 68,
//                clipBehavior: Clip.hardEdge,
//                decoration: BoxDecoration(
//                  color: Colors.white,
//                  borderRadius: BorderRadius.circular(10),
//                  boxShadow: const [
//                    BoxShadow(
//                      color: Color(0x3F000000),
//                      spreadRadius: 0,
//                      offset: Offset(0, 4),
//                      blurRadius: 4,
//                    )
//                  ],
//                ),
//              )
//            ],
//          ),
// SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.topLeft,
//           child: Text(
//             'Trending Today',
//             textAlign: TextAlign.center,
//             style: GoogleFonts.getFont(
//               'Poltawski Nowy',
//               color: Colors.black,
//               fontSize: 15,
//             ),
//           )
//           ),
//
//           SizedBox(height: 10,),
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               '#ivory-lehenga',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.getFont(
//                 'Poltawski Nowy',
//                 color: const Color(0xFFE83580),
//                 fontSize: 12,
//               ),
//             ),
//           ),
//           Row(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 clipBehavior: Clip.hardEdge,
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda4c02d79fd1200f156daf70739c11a60188ce59Rectangle%20266.png?alt=media&token=f0bcb045-bd2c-4242-82b4-91c11fa4fe6d',
//                   width: 202,
//                   height: 302,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               SizedBox(width: 10,),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(10),
//                 clipBehavior: Clip.hardEdge,
//                 child: Image.network(
//                   'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda4c02d79fd1200f156daf70739c11a60188ce59Rectangle%20266.png?alt=media&token=f0bcb045-bd2c-4242-82b4-91c11fa4fe6d',
//                   width: 202,
//                   height: 302,
//                   fit: BoxFit.cover,
//                 ),
//               )
//             ],
//           ),
//           SizedBox(height: 10,),
//           Container(
//             width: 382,
//             height: 59,
//             clipBehavior: Clip.hardEdge,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               border: Border.all(
//                 color: const Color(0xFFE83580),
//               ),
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.white,
//                   spreadRadius: 0,
//                   offset: Offset(0, 4),
//                   blurRadius: 4,
//                 )
//               ],
//             ),
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     gradient: const LinearGradient(
//                       colors: [Color(0x1EFFFFFF), Color(0x00FFFFFF)],
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   left: 115,
//                   top: 19,
//                   child: Text(
//                     'View all treading today ',
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.getFont(
//                       'Inter',
//                       color: const Color(0xFFA60F93),
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       letterSpacing: -0.1,
//                       height: 1.4,
//                     ),
//                   ),
//                 )
//               ],
//             ),
//           ),
//           SizedBox(height: 10,),
//
//           Align(
//             alignment: Alignment.topLeft,
//             child: Text(
//               'HappyWeds Services',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.getFont(
//                 'Poltawski Nowy',
//                 color: Colors.black,
//                 fontSize: 15,
//               ),
//             ),
//           )
//         ],
//       ),
//     )
//
//     );
//   }
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// class Rectangle267 extends StatelessWidget {
//   const Rectangle267({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 319,
//       height: 238,
//       clipBehavior: Clip.hardEdge,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(
//           color: const Color(0x11E83580),
//         ),
//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x3F000000),
//             spreadRadius: 0,
//             offset: Offset(0, 4),
//             blurRadius: 4,
//           )
//         ],
//       ),
//     );
//   }
// }
//
//
// class Vector extends StatelessWidget {
//   const Vector({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Image.network(
//       'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F8bf61fc9-24e3-4962-a04b-6cf4139fa10e.png',
//       width: 8,
//       height: 10,
//       fit: BoxFit.contain,
//     );
//   }
// }
//
//
// class WaddingPlanners extends StatelessWidget {
//   const WaddingPlanners({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 84,
//       child: Text(
//         'Wadding Planners ',
//         textAlign: TextAlign.center,
//         style: GoogleFonts.getFont(
//           'Inter',
//           color: Colors.black,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }
// }
//
//
// class Rectangle265 extends StatelessWidget {
//   const Rectangle265({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 122,
//       height: 106,
//       clipBehavior: Clip.hardEdge,
//       decoration: const BoxDecoration(
//         color: Color(0x38FBAA47),
//       ),
//     );
//   }
// }
//
//
// class Rectangle3 extends StatelessWidget {
//   const Rectangle3({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 66,
//       height: 2,
//       clipBehavior: Clip.hardEdge,
//       decoration: const BoxDecoration(),
//     );
//   }
// }
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//
//   // ---- Data ----
//   final List<Map<String, String>> categories = [
//     {
//       'label': 'Wedding Planners',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bEllipse%202.png?alt=media&token=126f43e7-fd80-4323-8f94-13f102b01688'
//     },
//     {
//       'label': 'Photographer',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cEllipse%203.png?alt=media&token=50dae8bf-2c7d-4b69-a847-a88432b235b6'
//     },
//     {
//       'label': 'Venues',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F138e7fc800113229c148bb8e1c42d934b661828bEllipse%204.png?alt=media&token=cdb01134-472d-448c-8530-ae7557a78233'
//     },
//     {
//       'label': 'Bridal makeup',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Ellipse%205.png?alt=media&token=5c7554ea-e064-4a0e-9fac-9fe9a779da08'
//     },
//     {
//       'label': 'All Categories',
//       'image':
//       'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F74d0bec9-682b-4ea0-8c61-f23d309a3de7.png'
//     },
//   ];
//
//   final List<Map<String, String>> venueCards = [
//     {
//       'title': 'Fort Jadhavgadh, Pune',
//       'sub': 'Saswad',
//       'price': '₹ 2,899 per plate',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=e95fe0b1-9f12-41d3-b034-384776687509'
//     },
//     {
//       'title': 'Gharkul Lawns',
//       'sub': 'Erandwane',
//       'price': '₹ 899 per plate',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F0601b946dc3b99b0aa992f4edf934ffc69ee254cRectangle%20266.png?alt=media&token=489fdb30-84e0-4f11-9a27-629eb6f5c2cc'
//     },
//   ];
//
//   final List<Map<String, String>> photographerCards = [
//     {
//       'title': 'Fearless Pheras',
//       'sub': 'Pune',
//       'price': '₹ 55,000 per Day',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=b58eea4b-0ec1-4562-bdce-af7fd3a2dc96'
//     },
//     {
//       'title': 'Firefly Photography',
//       'sub': 'Pune',
//       'price': '₹ 55,000 per Day',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F0601b946dc3b99b0aa992f4edf934ffc69ee254cRectangle%20266.png?alt=media&token=28367d39-ef9a-4d56-ada5-d49683b3d515'
//     },
//   ];
//
//   final List<Map<String, String>> trendingCards = [
//     {
//       'title': 'Bridal busy we’re crushing on! outfits',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F34ea5a1fe5bd5adb6c68ba2f0e1fa6bcc8470ba0Rectangle%20268.png?alt=media&token=847a1794-95a5-4fb4-961d-e2642efc2a63'
//     },
//     {
//       'title': 'A Beachside Wedding Dipped In Pastels',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=bd975947-2c06-40c6-8c0b-11482c43b783'
//     },
//   ];
//
//   final List<Map<String, String>> readCards = [
//     {
//       'title': 'Bridal busy we’re crushing on! outfits & Accessories',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F34ea5a1fe5bd5adb6c68ba2f0e1fa6bcc8470ba0Rectangle%20266.png?alt=media&token=bd975947-2c06-40c6-8c0b-11482c43b783'
//     },
//     {
//       'title':
//       'A Beachside Wedding Dipped In Pastels, Sunshine & A Decade Of Love',
//       'image':
//       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=cb4544a5-d80b-4d6b-807f-20024e958026'
//     },
//   ];
//
//   // ---- Helpers ----
//   double clampDouble(double value, double min, double max) =>
//       value < min ? min : (value > max ? max : value);
//
//   Widget buildCategoryItem(double circleSize, Map<String, String> item) {
//     return SizedBox(
//       width: circleSize + 20,
//       child: Column(
//         children: [
//           Container(
//             width: circleSize,
//             height: circleSize,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(width: 2, color: const Color(0xFFFBAA47)),
//               image: DecorationImage(
//                 image: NetworkImage(item['image']!),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Flexible(
//             child: Text(
//               item['label'] ?? '',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.inter(fontSize: 12),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget buildCardItemHorizontal(
//       Map<String, String> card,
//       double cardWidth, {
//         double? cardHeightOverride,
//       }) {
//     final double cardHeight = cardHeightOverride ?? 220;
//
//     return SizedBox(
//       width: cardWidth,
//       height: cardHeight,
//       child: Container(
//         margin: const EdgeInsets.only(right: 12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: const Color(0x11E83580)),
//           boxShadow: const [
//             BoxShadow(color: Color(0x3F000000), offset: Offset(0, 4), blurRadius: 4),
//           ],
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(
//               height: 120,
//               width: double.infinity,
//               child: ClipRRect(
//                 borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
//                 child: Image.network(
//                   card['image'] ?? '',
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
//                 ),
//               ),
//             ),
//
//             Padding(
//               padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     card['title'] ?? '',
//                     style: GoogleFonts.getFont(
//                       'Poltawski Nowy',
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     card['sub'] ?? '',
//                     style: GoogleFonts.poppins(
//                       fontSize: 13,
//                       color: Colors.grey[800],
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     card['price'] ?? '',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
//   Widget _smallToolCard({
//     required String title,
//     required String subtitle,
//     required String image,
//     required double width,
//   }) {
//     return Container(
//       width: width,
//       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: const Color(0x11E83580)),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(width: 56, height: 56, child: Image.network(image)),
//           const SizedBox(height: 6),
//           Flexible(
//             fit: FlexFit.loose,
//             child: Text(
//               title,
//               style: GoogleFonts.poppins(fontSize: 11),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             subtitle,
//             style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _readCardHorizontal(
//       {required String title, required String image, required double width}) {
//     return Container(
//       width: width,
//       margin: const EdgeInsets.only(right: 12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(color: Color(0x3F000000), offset: Offset(0, 4), blurRadius: 4)
//         ],
//         color: Colors.white,
//       ),
//       child: Row(
//         children: [
//           ClipRRect(
//             borderRadius:
//             const BorderRadius.horizontal(left: Radius.circular(10)),
//             child:
//             Image.network(image, width: width * 0.36, height: 100, fit: BoxFit.cover),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Text(title,
//                   style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14),
//                   maxLines: 3,
//                   overflow: TextOverflow.ellipsis),
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   // ---- Build ----
//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final circleSize = clampDouble(width * 0.14, 50, 80);
//     // final width = MediaQuery.of(context).size.width;
//     final height = MediaQuery.of(context).size.height;
//     // final smallCardW = clampDouble(width * 0.42, 140, 260);
//     final trendingCardW = clampDouble(width * 0.72, 200, 380);
//     final readCardW = clampDouble(width * 0.72, 220, 380);
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double smallCardW = (screenWidth * 0.62).clamp(180.0, 260.0);
//     const double cardH = 220;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('HappyWeds', style: GoogleFonts.poppins()),
//         backgroundColor: const Color(0xFFE83580),
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(
//                 height: circleSize + 46,
//                 child: ListView.separated(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: categories.length,
//                   separatorBuilder: (_, __) => const SizedBox(width: 12),
//                   itemBuilder: (context, index) =>
//                       buildCategoryItem(circleSize, categories[index]),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Text('Wedding Planning tools',
//                   style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: 120,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   children: [
//                     _smallToolCard(
//                       title: 'Build your Digital E-invites',
//                       subtitle: 'Let’s get started',
//                       image:
//                       'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F0a9710d1-dcde-45a6-8b5e-35c944279b1f.png',
//                       width: 140,
//                     ),
//                     const SizedBox(width: 12),
//                     _smallToolCard(
//                       title: 'Your shortlisted vendor',
//                       subtitle: 'Browse vendors',
//                       image:
//                       'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2Fa10c8360-0438-45ee-914b-52837cb3d480.png',
//                       width: 140,
//                     ),
//                     const SizedBox(width: 12),
//                     _smallToolCard(
//                       title: 'Your Favourite ideas',
//                       subtitle: 'Add a favourite',
//                       image:
//                       'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F57c23620-f845-42ed-9092-416ab6f7859d.png',
//                       width: 140,
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 18),
//               Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Venues in your city',
//                         style: GoogleFonts.getFont('Poltawski Nowy',
//                             fontSize: 16)),
//                     TextButton(
//                       onPressed: () {
//
//                       },
//                       child: Text('View all',
//                           style: GoogleFonts.inter(
//                               color: const Color(0xFFA60F93))),
//                     )
//                   ]),
//               const SizedBox(height: 8),
//             SizedBox(
//               height: cardH,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: venueCards.length,
//                 itemBuilder: (context, i) => buildCardItemHorizontal(
//                   venueCards[i],
//                   smallCardW,
//                   cardHeightOverride: cardH,
//                 ),
//               ),
//             ),
//               const SizedBox(height: 18),
//               Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Photographer for you',
//                         style: GoogleFonts.getFont('Poltawski Nowy',
//                             fontSize: 16)),
//                     TextButton(
//                       onPressed: () {},
//                       child: Text('View all',
//                           style: GoogleFonts.inter(
//                               color: const Color(0xFFA60F93))),
//                     )
//                   ]),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: smallCardW * 0.9,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: photographerCards.length,
//                   itemBuilder: (context, i) =>
//                       buildCardItemHorizontal(photographerCards[i], smallCardW),
//                 ),
//               ),
//                const SizedBox(height: 18),
//               // Container(
//               //   height: 120,
//               //   decoration: BoxDecoration(
//               //     gradient: const LinearGradient(
//               //       colors: [Color(0xFFB52963), Color(0xFFE83580), Color(0xFFF96909)],
//               //       stops: [0, 0.5, 1],
//               //     ),
//               //     borderRadius: BorderRadius.circular(10),
//               //   ),
//               //   padding: const EdgeInsets.all(12),
//               //   child: Column(
//               //       crossAxisAlignment: CrossAxisAlignment.start,
//               //       children: [
//               //         Text('0/73',
//               //             style: GoogleFonts.getFont('Poltawski Nowy',
//               //                 color: Colors.white, fontSize: 18)),
//               //         Text('Task done',
//               //             style: GoogleFonts.getFont('Poltawski Nowy',
//               //                 color: Colors.white, fontSize: 12)),
//               //         const Spacer(),
//               //         Text('Upcoming tasks',
//               //             style: GoogleFonts.getFont('Poltawski Nowy',
//               //                 color: Colors.white, fontSize: 10)),
//               //         const SizedBox(height: 6),
//               //         Text('Browse and save outfit photos',
//               //             style: GoogleFonts.poppins(
//               //                 color: Colors.white, fontSize: 10)),
//               //       ]),
//               // ),
//
//                   Container(
//                       width: double.infinity,
//                       height: height * 0.20,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFFd8366f), Color(0xFFf97316)], // Pink → Orange
//                           begin: Alignment.centerLeft,
//                           end: Alignment.centerRight,
//                         ),
//                       ),
//                       child:Padding(
//                           padding: const EdgeInsets.all(20.0),
//                           child: Stack(
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     "0/73",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: width * 0.07,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 6),
//                                   const Text(
//                                     "Task done",
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: Container(
//                             width: 60,
//                             height: 60,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.8),
//                                 width: 3,
//                               ),
//                             ),
//                             child: const Center(
//                               child: Text(
//                                 "0%",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                             ],
//                           ),
//                       )
//                   ),
//               SizedBox(height: 20),
//               Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.08),
//                         blurRadius: 12,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child:Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Upcoming tasks",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         children: const [
//                           Icon(Icons.circle, size: 12, color: Colors.pink),
//                           SizedBox(width: 10),
//                           Text(
//                             "Browse and save outfit photos",
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Icon(Icons.circle, size: 12, color: Colors.grey[400]),
//                           const SizedBox(width: 10),
//                           const Text(
//                             "Research venue options",
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   )
//
//
//
//
//
//
//
//
//               ),
//
//
//               const SizedBox(height: 18),
//               Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('Trending Today',
//                         style: GoogleFonts.getFont('Poltawski Nowy',
//                             fontSize: 16)),
//                     Text('#ivory-lehenga',
//                         style: GoogleFonts.getFont('Poltawski Nowy',
//                             color: const Color(0xFFE83580))),
//                   ]),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: trendingCardW * 0.9,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: trendingCards.length,
//                   itemBuilder: (context, i) =>
//                       buildCardItemHorizontal(trendingCards[i], trendingCardW),
//                 ),
//               ),
//               const SizedBox(height: 18),
//               Container(
//                 width: double.infinity,
//                 height: 140,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(10),
//                   image: const DecorationImage(
//                     image: NetworkImage(
//                         'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Rectangle%20269.png?alt=media&token=ab82efe7-34cd-404b-9da2-01515f372f47'),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   alignment: Alignment.bottomLeft,
//                   decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       gradient: LinearGradient(
//                           colors: [Colors.black.withOpacity(0.35), Colors.transparent])),
//                   child: Column(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('HappyWeds Services',
//                             style: GoogleFonts.getFont('Poltawski Nowy',
//                                 color: Colors.white, fontSize: 16)),
//                         Text('plan your dream wedding in your budget',
//                             style: GoogleFonts.poppins(
//                                 color: Colors.white, fontSize: 12)),
//                       ]),
//                 ),
//               ),
//               const SizedBox(height: 18),
//               Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: Image.network(
//                       'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F1056d056a37e91a97da6758a70e2dada5d0a4f38Rectangle%20266.png?alt=media&token=36044e03-5eab-492d-8ed5-0e1fbf35dfd0',
//                       height: 140,
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Wedding ideas',
//                             style: GoogleFonts.getFont('Poltawski Nowy',
//                                 fontSize: 16)),
//                         const SizedBox(height: 6),
//                         Text('Wedding day bridal portrait',
//                             style: GoogleFonts.getFont('Poltawski Nowy',
//                                 fontSize: 14)),
//                         const SizedBox(height: 6),
//                         Text('Romantic couple shot',
//                             style: GoogleFonts.getFont('Poltawski Nowy',
//                                 fontSize: 14)),
//                       ]),
//                 ),
//               ]),
//               const SizedBox(height: 18),
//               Text('Interesting reads',
//                   style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
//               const SizedBox(height: 8),
//               SizedBox(
//                 height: 120,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: readCards.length,
//                   itemBuilder: (context, i) => _readCardHorizontal(
//                       title: readCards[i]['title']!,
//                       image: readCards[i]['image']!,
//                       width: readCardW),
//                 ),
//               ),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//
//       bottomNavigationBar: Container(
//       width: double.infinity,
//       height: 83,
//       decoration: const BoxDecoration(
//         color: Color(0xFFE83580),
//       ),
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(
//             left: 10,
//             top: 13,
//             child: Column(
//               children: [
//                 Container(
//                   width: 86,
//                   height: 58,
//                   child: Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       Positioned(
//                         left: 8,
//                         top: 0,
//                         child: Container(
//                           width: 66,
//                           height: 2,
//                           color: Colors.white,
//                         ),
//                       ),
//                       Positioned(
//                         left: 31,
//                         top: 9,
//                         child: Image.asset(
//                           'assets/homeicon.png',
//                           width: 20,
//                           height: 22,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                       Positioned(
//                         left: 22,
//                         top: 37,
//                         child: Text(
//                           'Home',
//                           style: GoogleFonts.poppins(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                             height: 1.3,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Positioned(
//             left: 122,
//             top: 23,
//             child: Column(
//               children: [
//                 Image.network(
//                   'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F1dced8c6-3573-4028-b321-f23db1bbee87.png',
//                   width: 24,
//                   height: 24,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   'Venues',
//                   style: GoogleFonts.poppins(
//                     color: Colors.white,
//                     fontSize: 12,
//                     height: 1.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Positioned(
//             left: 187,
//             top: -18,
//             child: Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 image: const DecorationImage(
//                   image: NetworkImage(
//                     'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fd1f329981dae4ed57bd4c1a647951bd314f60a5fEllipse%20198.png?alt=media&token=ce69c3a7-5d00-414e-b01e-0a2cc4e4b888',
//                   ),
//                   fit: BoxFit.cover,
//                 ),
//                 border: Border.all(width: 4, color: const Color(0xFFE83580)),
//                 borderRadius: BorderRadius.circular(28),
//                 boxShadow: const [
//                   BoxShadow(
//                     color: Color(0x3F000000),
//                     spreadRadius: 0,
//                     offset: Offset(0, 4),
//                     blurRadius: 4,
//                   )
//                 ],
//               ),
//             ),
//           ),
//
//           Positioned(
//             left: 255,
//             top: 15,
//             child: Column(
//               children: [
//                 Image.network(
//                   'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F16930dff-c4ab-4c18-b9a6-f52c3bdb8430.png',
//                   width: 24,
//                   height: 24,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   'Vendors',
//                   style: GoogleFonts.poppins(
//                     color: Colors.white,
//                     fontSize: 12,
//                     height: 1.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           Positioned(
//             left: 336,
//             top: 15,
//             child: Column(
//               children: [
//                 Image.network(
//                   'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2Fd897a830-de2f-412b-901a-2c08c4fdde3d.png',
//                   width: 24,
//                   height: 24,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   'More',
//                   style: GoogleFonts.poppins(
//                     color: Colors.white,
//                     fontSize: 12,
//                     height: 1.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//
//     );
//   }
// }



// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:happy_wedz/login.dart';
import 'package:happy_wedz/packages.dart';
import 'package:happy_wedz/shop.dart';
import 'package:http/http.dart' as http;

import '../DecorationScreen.dart';
import '../WedChecklist/ChecklistScreen.dart';
import '../favscreen.dart';
import '../ideas.dart';
import '../vendor/makeup.dart';
import '../vendor/photographer.dart';
import '../venuedetails.dart';
import 'Vendor.dart';
import 'VenuesScreen.dart';
import 'VirtualStudio.dart';
import 'morescreen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _selectedCity = "Nashik"; // default city

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  // ---- Data (provided by you) ----
  final List<Map<String, String>> categories = [
    {
      'label': 'Wedding Planners',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F16f94e39e234e6b289ab14b5e39c8bf7094fe42bEllipse%202.png?alt=media&token=126f43e7-fd80-4323-8f94-13f102b01688'
    },
    {
      'label': 'Photographer',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F2289effba6425753bdc3f31d0c8ad1733a49f17cEllipse%203.png?alt=media&token=50dae8bf-2c7d-4b69-a847-a88432b235b6'
    },
    {
      'label': 'Venues',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F138e7fc800113229c148bb8e1c42d934b661828bEllipse%204.png?alt=media&token=cdb01134-472d-448c-8530-ae7557a78233'
    },
    {
      'label': 'Bridal makeup',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Ellipse%205.png?alt=media&token=5c7554ea-e064-4a0e-9fac-9fe9a779da08'
    },
    {
      'label': 'All Categories',
      'image':
      'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F74d0bec9-682b-4ea0-8c61-f23d309a3de7.png'
    },
  ];

  final List<Map<String, String>> venueCards = [
    {
      'title': 'Fort Jadhavgadh, Pune',
      'sub': 'Saswad',
      'price': '₹ 2,899 per plate',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=e95fe0b1-9f12-41d3-b034-384776687509'
    },
    {
      'title': 'Gharkul Lawns',
      'sub': 'Erandwane',
      'price': '₹ 899 per plate',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F0601b946dc3b99b0aa992f4edf934ffc69ee254cRectangle%20266.png?alt=media&token=489fdb30-84e0-4f11-9a27-629eb6f5c2cc'
    },
  ];

  final List<Map<String, String>> photographerCards = [
    {
      'title': 'Fearless Pheras',
      'sub': 'Pune',
      'price': '₹ 55,000 per Day',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=b58eea4b-0ec1-4562-bdce-af7fd3a2dc96'
    },
    {
      'title': 'Firefly Photography',
      'sub': 'Pune',
      'price': '₹ 55,000 per Day',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F0601b946dc3b99b0aa992f4edf934ffc69ee254cRectangle%20266.png?alt=media&token=28367d39-ef9a-4d56-ada5-d49683b3d515'
    },
  ];

  final List<Map<String, String>> trendingCards = [
    {
      'title': 'Bridal busy we’re crushing on! outfits',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F34ea5a1fe5bd5adb6c68ba2f0e1fa6bcc8470ba0Rectangle%20268.png?alt=media&token=847a1794-95a5-4fb4-961d-e2642efc2a63'
    },
    {
      'title': 'A Beachside Wedding Dipped In Pastels',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=bd975947-2c06-40c6-8c0b-11482c43b783'
    },
  ];

  final List<Map<String, String>> readCards = [
    {
      'title': 'Bridal busy we’re crushing on! outfits & Accessories',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F34ea5a1fe5bd5adb6c68ba2f0e1fa6bcc8470ba0Rectangle%20266.png?alt=media&token=bd975947-2c06-40c6-8c0b-11482c43b783'
    },
    {
      'title':
      'A Beachside Wedding Dipped In Pastels, Sunshine & A Decade Of Love',
      'image':
      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F3320dd2b76b74cf8a9f7aae754140bf4d9c7e3a0Rectangle%20266.png?alt=media&token=cb4544a5-d80b-4d6b-807f-20024e958026'
    },
  ];
  final List<Map<String, String>> _navItems = [
    {"label": "Home", "icon": "assets/icons/home.png"},
    {"label": "Vendors", "icon": "assets/icons/vendor.png"},
    {"label": "Inspiration", "icon": "assets/icons/inspiration.png"},
    {"label": "Shop", "icon": "assets/icons/shop.png"},
    {"label": "Profile", "icon": "assets/icons/profile.png"},
  ];
  // ---- Helpers ----

  // clamp double between min and max (simple utility)
  double clampDouble(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);

  // Build circular category item (image + label)
  Widget buildCategoryItem(double circleSize, Map<String, String> item) {
    return SizedBox(
      width: circleSize + 20,
      child: Column(
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2, color: const Color(0xFFFBAA47)),
              image: DecorationImage(
                image: NetworkImage(item['image']!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              item['label'] ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  // Generic horizontal card used for venues / trending / photographer
  Widget buildCardItemHorizontal(
      Map<String, String> card,
      double cardWidth, {
        double? cardHeightOverride,
      }) {
    final double cardHeight = cardHeightOverride ?? 220;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0x11E83580)),
          boxShadow: const [
            BoxShadow(color: Color(0x3F000000), offset: Offset(0, 4), blurRadius: 4),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image
            SizedBox(
              height: 120,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                child: Image.network(
                  card['image'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['title'] ?? '',
                    style: GoogleFonts.getFont(
                      'Poltawski Nowy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card['sub'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card['price'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _smallToolCard({
    required String title,
    required String subtitle,
    required String image,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x11E83580)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // 🔹 Main content
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 56, height: 56, child: Image.asset(image)),
              const SizedBox(height: 6),
              Flexible(
                fit: FlexFit.loose,
                child: Text(
                  title,
                  style: GoogleFonts.poppins(fontSize: 11),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          // 🔹 Arrow in top-right corner
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // // Small tool card (icon + title + subtitle)
  // Widget _smallToolCard({
  //   required String title,
  //   required String subtitle,
  //   required String image,
  //   required double width,
  // }) {
  //   return Container(
  //     width: width,
  //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       border: Border.all(color: const Color(0x11E83580)),
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         SizedBox(width: 56, height: 56, child: Image.network(image)),
  //         const SizedBox(height: 6),
  //         Flexible(
  //           fit: FlexFit.loose,
  //           child: Text(
  //             title,
  //             style: GoogleFonts.poppins(fontSize: 11),
  //             textAlign: TextAlign.center,
  //             maxLines: 2,
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           subtitle,
  //           style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
  //           maxLines: 1,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Read card used in 'Interesting reads'
  Widget _readCardHorizontal({
    required String title,
    required String image,
    required double width,
  }) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), offset: Offset(0, 4), blurRadius: 4)
        ],
        color: Colors.white,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
            child: Image.network(image, width: width * 0.36, height: 100, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(title,
                  style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
            ),
          )
        ],
      ),
    );
  }

  // ---- Build ----
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final circleSize = clampDouble(width * 0.14, 50, 80);
    final height = MediaQuery.of(context).size.height;
    final trendingCardW = clampDouble(width * 0.72, 200, 380);
    final readCardW = clampDouble(width * 0.72, 220, 380);
    final double screenWidth = width;
    final double smallCardW = (screenWidth * 0.62).clamp(180.0, 260.0);
    const double cardH = 220;

    return Scaffold(
      appBar: AppBar(
        title: Text('HappyWeds', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFFE83580),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category horizontal list (circular images)
              SizedBox(
                height: circleSize + 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      buildCategoryItem(circleSize, categories[index]),
                ),
              ),
              const SizedBox(height: 16),

              // Tools section
              Text('Wedding Planning tools',
                  style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _smallToolCard(
                      title: 'Build your Digital E-invites',
                      subtitle: 'Let’s get started',
                      image:'assets/tool1.png',
                      // 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F0a9710d1-dcde-45a6-8b5e-35c944279b1f.png',
                      width: 140,
                    ),
                    const SizedBox(width: 12),
                    _smallToolCard(
                      title: 'Your shortlisted vendor',
                      subtitle: 'Browse vendors',
                      image:'assets/tool2.png',
                      // 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2Fa10c8360-0438-45ee-914b-52837cb3d480.png',
                      width: 140,
                    ),
                    const SizedBox(width: 12),
                    _smallToolCard(
                      title: 'Your Favourite ideas',
                      subtitle: 'Add a favourite',
                      image:'assets/tool3.png',
                      // 'https://storage.googleapis.com/codeless-app.appspot.com/uploads%2Fimages%2F0S6hNdKIozJ1iLSN3vLs%2F57c23620-f845-42ed-9092-416ab6f7859d.png',
                      width: 140,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Venues heading and 'View all' button
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Venues in your city',
                    style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                TextButton(
                  onPressed: () {
                    // TODO: navigate to venues listing
                  },
                  child: Text('View all',
                      style: GoogleFonts.inter(color: const Color(0xFFA60F93))),
                )
              ]),
              const SizedBox(height: 8),

              // Venues horizontal cards
              SizedBox(
                height: cardH,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: venueCards.length,
                  itemBuilder: (context, i) => buildCardItemHorizontal(
                    venueCards[i],
                    smallCardW,
                    cardHeightOverride: cardH,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Photographer section
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Photographer for you',
                    style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                TextButton(
                  onPressed: () {
                    // TODO: navigate
                  },
                  child: Text('View all',
                      style: GoogleFonts.inter(color: const Color(0xFFA60F93))),
                )
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: smallCardW * 0.9,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photographerCards.length,
                  itemBuilder: (context, i) =>
                      buildCardItemHorizontal(photographerCards[i], smallCardW),
                ),
              ),
              const SizedBox(height: 18),
// 🔹 Wrap in a Stack so white card overlaps pink card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gradient progress panel (Tasks)
                  Container(
                    width: double.infinity,
                    height: height * 0.20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFd8366f), Color(0xFFf97316)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "0/73",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.07,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Task done",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 3,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  "0%",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Upcoming tasks white card (overlapping bottom)
                  Positioned(
                    bottom: -80, // 🔹 adjust overlap
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Upcoming tasks",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Icon(Icons.circle, size: 12, color: Colors.pink),
                              SizedBox(width: 10),
                              Text(
                                "Browse and save outfit photos",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 10),
                              const Text(
                                "Research venue options",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),



              const SizedBox(height: 18),

              // Trending Today
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Trending Today',
                    style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                Text('#ivory-lehenga',
                    style: GoogleFonts.getFont('Poltawski Nowy',
                        color: const Color(0xFFE83580))),
              ]),
              const SizedBox(height: 8),
              SizedBox(
                height: trendingCardW * 0.9,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: trendingCards.length,
                  itemBuilder: (context, i) =>
                      buildCardItemHorizontal(trendingCards[i], trendingCardW),
                ),
              ),
              const SizedBox(height: 18),

              // Promo image w/ text overlay
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2Fda0399cee2bfa8d62a8b2df83c21d7abf14fe7c0Rectangle%20269.png?alt=media&token=ab82efe7-34cd-404b-9da2-01515f372f47'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.35), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('HappyWeds Services',
                            style: GoogleFonts.getFont('Poltawski Nowy',
                                color: Colors.white, fontSize: 16)),
                        Text('plan your dream wedding in your budget',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
                      ]),
                ),
              ),
              const SizedBox(height: 18),

              // Two-column ideas section
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      'https://firebasestorage.googleapis.com/v0/b/codeless-app.appspot.com/o/projects%2F0S6hNdKIozJ1iLSN3vLs%2F1056d056a37e91a97da6758a70e2dada5d0a4f38Rectangle%20266.png?alt=media&token=36044e03-5eab-492d-8ed5-0e1fbf35dfd0',
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Wedding ideas',
                        style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Wedding day bridal portrait',
                        style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14)),
                    const SizedBox(height: 6),
                    Text('Romantic couple shot',
                        style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 14)),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),

              // Interesting reads horizontal cards
              Text('Interesting reads', style: GoogleFonts.getFont('Poltawski Nowy', fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: readCards.length,
                  itemBuilder: (context, i) => _readCardHorizontal(
                      title: readCards[i]['title']!, image: readCards[i]['image']!, width: readCardW),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // ---- Bottom Navigation Bar (custom styled to match design) ----
      bottomNavigationBar: Container(
        height: 83,
        decoration: const BoxDecoration(
          color: Color(0xFFE83580),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Home
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 0)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/homeicon.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 0 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Home',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 0 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Venues
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const VenuesScreen()),
                    // );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 1)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/venue.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 1 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Venues',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 1 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 1
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer for FAB
                const SizedBox(width: 56),

                // Vendors
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const VendorsScreen()),
                    // );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 2)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/vendor.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 2 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vendors',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 2 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 2
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                // More
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    // Navigator.pushReplacement(
                    //   context,
                    //   MaterialPageRoute(builder: (_) => const MoreScreen()),
                    // );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 3)
                        Container(width: 40, height: 2, color: Colors.white),
                      const SizedBox(height: 6),
                      Image.asset(
                        'assets/menuicon.png',
                        width: 24,
                        height: 24,
                        color: _selectedIndex == 3 ? Colors.white : Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'More',
                        style: GoogleFonts.poppins(
                          color: _selectedIndex == 3 ? Colors.white : Colors.white,
                          fontSize: 12,
                          fontWeight: _selectedIndex == 3
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Center floating avatar
            Positioned(
              top: -18,
              left: MediaQuery.of(context).size.width / 2 - 28,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/virtualstudio.jpg'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(width: 4, color: Color(0xFFE83580)),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),


      // bottomNavigationBar: BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   currentIndex: _selectedIndex,
      //   onTap: _onItemTapped,
      //   selectedItemColor: Colors.pink[400],
      //   unselectedItemColor: Colors.grey,
      //   showUnselectedLabels: true,
      //   items: _navItems.map((item) {
      //     return BottomNavigationBarItem(
      //       icon: Image.asset(
      //         item["icon"]!,
      //         width: 24,
      //         height: 24,
      //         color: Colors.grey,
      //       ),
      //       activeIcon: Image.asset(
      //         item["icon"]!,
      //         width: 26,
      //         height: 26,
      //         color: Colors.pink[400],
      //       ),
      //       label: item["label"],
      //     );
      //   }).toList(),
      // ),







    );
  }
}














































class WeddingHomePage extends StatefulWidget {
  const WeddingHomePage({super.key});

  @override
  State<WeddingHomePage> createState() => _WeddingHomePageState();
}

class _WeddingHomePageState extends State<WeddingHomePage> {
  int _selectedIndex = 0;




  // int _selectedIndex = 0;








  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // 👇 Add custom navigation logic here
    switch (index) {
      case 0:
      // Home tapped
        print("Home tapped");
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VenuesScreen()),
        );
        print("Venues tapped");
        break;
      case 2:
      // Virtual Studio tapped
        print("Virtual Studio tapped");
        break;
      case 3:
      // Vendors tapped
        print("Vendors tapped");
        break;
      case 4:
      // More tapped
        print("More tapped");
        break;
    }
  }
  bool _showSearch = false; // 👈 toggle state

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
          child: Column(
            children: [
              // Status Bar and Header
              _buildHeader(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Category Circles
                      _buildCategorySection(context),

                      const SizedBox(height: 30),

                      // Wedding Planning Tools
                      _buildPlanningToolsSection(),

                      const SizedBox(height: 30),

                      // Venues Section
                      _buildVenuesSection(),

                      const SizedBox(height: 20),

                      // View All Venues Button
                      _buildViewAllVenuesButton(context),

                      const SizedBox(height: 30),

                      // Photographer Section
                      _buildPhotographerSection(),
                      const SizedBox(height: 20),
                      _buildViewAllPhotographersButton(),
                      const SizedBox(height: 30),

                      _buildWeddingChecklistSection(),
                      const SizedBox(height: 30),
                      _buildTrendingTodaySection(),
                      SizedBox(height: 20),
                      _buildViewAllTrendingButton(),
                      const SizedBox(height: 30),
                      _buildHappyWedsServicesSection(),
                      const SizedBox(height: 30),
                      _buildWeddingIdeasSection(),
                      const SizedBox(height: 20),
                      _buildViewAllWeddingIdeasButton(),
                      const SizedBox(height: 30),
                      _buildFeaturedVideoSection(),
                      const SizedBox(height: 30),
                      _buildInterestingReadsSection(),
                      const SizedBox(height: 30),
                      _buildRealWeddingsSection(),
                      const SizedBox(height: 100), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              if (_showSearch) Container(
                width: 200, // adjust width as needed
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ) else Row(
                children:  [
                  Text(
                    'Nashik',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  InkWell(
                    onTap: (){
                      _showCitySelection(context);
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right Section
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showSearch = !_showSearch; // 👈 toggle search
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _showSearch ? Icons.close : Icons.search, // 👈 switch icon
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Widget _buildHeader() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const SizedBox(height: 20),
  //             Row(
  //               children: [
  //                 const Text(
  //                   'Nashik',
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 22,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 5),
  //                 const Icon(
  //                   Icons.keyboard_arrow_down,
  //                   color: Colors.white,
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.2),
  //                 shape: BoxShape.circle,
  //               ),
  //               child: const Icon(
  //                 Icons.search,
  //                 color: Colors.white,
  //                 size: 20,
  //               ),
  //             ),
  //             // const SizedBox(width: 10),
  //             // Container(
  //             //   padding: const EdgeInsets.all(8),
  //             //   decoration: BoxDecoration(
  //             //     color: Colors.white.withOpacity(0.2),
  //             //     shape: BoxShape.circle,
  //             //   ),
  //             //   child: const Icon(
  //             //     Icons.chat_bubble_outline,
  //             //     color: Colors.white,
  //             //     size: 20,
  //             //   ),
  //             // ),
  //             const SizedBox(width: 10),
  //             InkWell(
  //               onTap: (){
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(builder: (_) =>  LoginScreen()),
  //                 );
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.all(8),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.2),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(
  //                   Icons.person,
  //                   color: Colors.white,
  //                   size: 20,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Widget _circleIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildCategorySection(BuildContext context) {
    final categories = [
      {'name': 'Wedding\nVenues', 'image': 'assets/venues.jpg', 'page': const VenuesScreen()},
      {'name': 'Wedding\nPhotographer', 'image': 'assets/photographer.jpg', 'page': const PhotographerScreen()},
      {'name': 'Bridal\nmakeup', 'image': 'assets/makeup.jpg', 'page': const MakeupScreen()},
      {'name': 'Wedding\nDecorators','image':'assets/decorators.jpg', 'page': const WeddingDecoratorsScreen()},
      {'name': 'All\nCategories', 'icon': Icons.add, 'page': const VendorCategoriesScreen()},

    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isLast = index == categories.length - 1;

          return Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 15),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => category['page'] as Widget),
                    );
                  },
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLast ? Colors.white : Colors.grey[300],
                      border: isLast ? Border.all(color: Colors.pink, width: 2) : null,
                    ),
                    child: isLast
                        ? Icon(
                      category['icon'] as IconData,
                      color: Colors.pink,
                      size: 30,
                    )
                        : ClipOval(
                      child: Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category['name'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlanningToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wedding Planning tools',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildPlanningToolCard(
                'Build your\nDigital E-invites',
                'on app launch',
                Colors.purple[100]!,
                Icons.card_giftcard,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorCategoriesScreen()),
                  );
                },
                child : _buildPlanningToolCard(
                  'Your shortlisted\nvendor',
                  'Venue vendors',
                  Colors.orange[100]!,
                  Icons.favorite,
                  Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FavouritesScreen()),
                  );
                },
                child: _buildPlanningToolCard(
                  'Your Favourite\nblog',
                  'will it favourite',
                  Colors.pink[100]!,
                  Icons.bookmark,
                  Colors.pink,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlanningToolCard(String title, String subtitle, Color bgColor, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenuesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Venues in your city',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildVenueCard(
                'Fort Jadhavgadh, Pune',
                '₹50/000',
                '₹ 2,500 per plate',
                'assets/venue1.jpg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildVenueCard(
                'Gharful Lawns',
                'Lonekawne',
                '₹ 699 per plate',
                'assets/venue2.jpg',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVenueCard(String name, String location, String price, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Icon(
                Icons.image,
                color: Colors.grey,
                size: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllVenuesButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // 👇 Add navigation or action here
        print("View all venues tapped");
       Navigator.push(context, MaterialPageRoute(builder: (_) => VenuesScreen()));
      },
      borderRadius: BorderRadius.circular(25), // ripple effect with rounded edges
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all venues',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.pink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotographerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Photographer for you',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildPhotographerCard(
                'Fearless Pheras',
                'Pune',
                '₹ 55,000 per Day',
                'assets/photographer1.jpg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPhotographerCard(
                'Firefly Photography',
                'Pune',
                '₹ 55,000 per Day',
                'assets/photographer2.jpg',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotographerCard(String name, String location, String price, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Center(
              child: Icon(
                Icons.camera_alt,
                color: Colors.grey,
                size: 40,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllPhotographersButton() {
    return InkWell(
      onTap: () {
        // 👇 Add navigation or action here
        print("View all venues tapped");
        Navigator.push(context, MaterialPageRoute(builder: (_) => PhotographerScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all photographers',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.pink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeddingChecklistSection() {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_) => WeddingTimelinePage()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wedding checklist',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFFFF6B35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Decorative circles in background
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  right: 30,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                // Main content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '0/73',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Task done',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upcoming tasks',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Discuss ideas with partners',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Fix date venue',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingTodaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Trending Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Trendy themes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildTrendingCard(
                'assets/trending1.jpg',
                Colors.pink[50]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTrendingCard(
                'assets/trending2.jpg',
                Colors.orange[50]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendingCard(String imagePath, Color bgColor) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.image,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildViewAllTrendingButton() {
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all trending today',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.pink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHappyWedsServicesSection() {
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_) => PackagesScreen()));
      },

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HappyWeds Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          // Main service card
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.brown[200],
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        color: Colors.brown,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                // Overlay with text
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Myshrä',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Find your perfect match in seconds',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bottom service cards row
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  'Couple Services',
                  'Book your perfect shoot',
                  Colors.green[100]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildServiceCard(
                  'Couple Services',
                  'Book your perfect shoot',
                  Colors.orange[100]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(String title, String subtitle, Color bgColor) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: bgColor,
              child: const Center(
                child: Icon(
                  Icons.image,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ),
          // Overlay with text
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeddingIdeasSection() {
    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Ideas(initialSubTabIndex: 1), // 👈 open Stories tab
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wedding Ideas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildWeddingIdeaCard(
                  'Wedding day bridal portrait',
                  'assets/bridal_portrait.jpg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWeddingIdeaCard(
                  'Romantic couple shot',
                  'assets/couple_shot.jpg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeddingIdeaCard(String title, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.brown[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                width: double.infinity,
                color: Colors.brown[200],
                child: const Center(
                  child: Icon(
                    Icons.image,
                    color: Colors.brown,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewAllWeddingIdeasButton() {
    return InkWell(
      onTap: (){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Ideas(initialSubTabIndex: 1), // 👈 open Stories tab
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pink),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View all Wedding ideas',
              style: TextStyle(
                color: Colors.pink,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 5),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.pink,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedVideoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured video',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.green[200],
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                ),
              ),
              // Play button overlay
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.3),
                ),
                child:  Center(
                  child: Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.pink,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInterestingReadsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interesting reads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 15,),
        Row(
          children: [
            Container(
              height: 120,
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=300&h=200&fit=crop'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1594736797933-d0401ba4b718?w=300&h=200&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Bridal bling we\'re crushing on! outfits &\nAccessories That deserve a sport in your...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Ideas(initialSubTabIndex: 1 ), // 👈 open Stories tab
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE91E63)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'View all interesting reads >',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRealWeddingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Real weddings we love',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1519741497674-611481863552?w=300&h=400&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAHEK & ARYAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stunning leaf\nphotoshoot and decor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1606800052052-a08af7148866?w=300&h=400&fit=crop'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAHEK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stunning leaf\nphotoshoot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Ideas(initialSubTabIndex: 2  ), // 👈 open Stories tab
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE91E63)),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'View all real Weddings >',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
  String _selectedCity = "Nashik"; // default city
  List<String> _allCities = [
    "Mumbai",
    "Delhi",
    "Bengaluru",
    "Hyderabad",
    "Chennai",
    "Kolkata",
    "Pune",
    "Ahmedabad",
  ];
  List<String> _filteredCities = [];
  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_allCities); // start with all
  }


  void _showCitySelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔍 Search box
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search city...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        _filteredCities = _allCities
                            .where((city) => city
                            .toLowerCase()
                            .contains(value.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // 📍 List of cities
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredCities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.location_city,
                              color: Colors.pink),
                          title: Text(_filteredCities[index]),
                          onTap: () {
                            setState(() {
                              _selectedCity = _filteredCities[index];
                            });
                            Navigator.pop(context); // close sheet
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget _buildBottomNavigationBar() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
  //         begin: Alignment.topCenter,
  //         end: Alignment.bottomCenter,
  //       ),
  //     ),
  //     child: BottomNavigationBar(
  //       type: BottomNavigationBarType.fixed,
  //       backgroundColor: Colors.transparent,
  //       elevation: 0,
  //       selectedItemColor: Colors.white,
  //       unselectedItemColor: Colors.white.withOpacity(0.6),
  //       selectedFontSize: 12,
  //       unselectedFontSize: 12,
  //       // currentIndex: 0,
  //       currentIndex: _selectedIndex,   // ✅ dynamic index
  //       onTap: _onItemTapped,           // ✅ tap handler
  //       items: [
  //         const BottomNavigationBarItem(
  //           icon: Icon(Icons.home_filled),
  //           label: 'Home',
  //         ),
  //         const BottomNavigationBarItem(
  //           icon: Icon(Icons.location_on_outlined),
  //           label: 'Venues',
  //         ),
  //         BottomNavigationBarItem(
  //           icon: Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               shape: BoxShape.circle,
  //             ),
  //             child: const Icon(
  //               Icons.add,
  //               color: Colors.pink,
  //               size: 20,
  //             ),
  //           ),
  //           label: 'VirtualStudio',
  //         ),
  //         const BottomNavigationBarItem(
  //           icon: Icon(Icons.people_outline),
  //           label: 'Vendors',
  //         ),
  //         const BottomNavigationBarItem(
  //           icon: Icon(Icons.menu),
  //           label: 'More',
  //         ),
  //       ],
  //     ),
  //   );
  // }
}


























class BottomBars extends StatefulWidget {
  const BottomBars({super.key});

  @override
  State<BottomBars> createState() => _BottomBarsState();
}

class _BottomBarsState extends State<BottomBars> {
  int _selectedIndex = 0;

  // All screens for bottom nav
  final List<Widget> _screens = [
    const WeddingHomePage(),
    const VenuesScreen(),
     CreateYourLookScreen(),
    // FinalLookResultScreen(),
    const VendorCategoriesScreen(),
    MoreOptionsScreen()
    // VenueDetailsScreen()
    // const MoreScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF69B4), Color(0xFFFF1493)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        // currentIndex: 0,
        currentIndex: _selectedIndex,
        // ✅ dynamic index
        onTap: _onItemTapped,
        // ✅ tap handler
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'Venues',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.pink,
                size: 20,
              ),
            ),
            label: 'VirtualStudio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Vendors',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }


// Gradient progress panel (Tasks)
// Container(
//   width: double.infinity,
//   height: height * 0.20,
//   decoration: BoxDecoration(
//     borderRadius: BorderRadius.circular(20),
//     gradient: const LinearGradient(
//       colors: [Color(0xFFd8366f), Color(0xFFf97316)],
//       begin: Alignment.centerLeft,
//       end: Alignment.centerRight,
//     ),
//   ),
//   child: Padding(
//     padding: const EdgeInsets.all(20.0),
//     child: Stack(
//       children: [
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "0/73",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: width * 0.07,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 6),
//             const Text(
//               "Task done",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//         Align(
//           alignment: Alignment.centerRight,
//           child: Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.8),
//                 width: 3,
//               ),
//             ),
//             child: const Center(
//               child: Text(
//                 "0%",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     ),
//   ),
// ),
// const SizedBox(height: 20),
//
// // Upcoming tasks white card
// Container(
//   width: double.infinity,
//   padding: const EdgeInsets.all(20),
//   decoration: BoxDecoration(
//     color: Colors.white,
//     borderRadius: BorderRadius.circular(20),
//     boxShadow: [
//       BoxShadow(
//         color: Colors.black.withOpacity(0.08),
//         blurRadius: 12,
//         offset: const Offset(0, 4),
//       ),
//     ],
//   ),
//   child: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const Text(
//         "Upcoming tasks",
//         style: TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.w600,
//           color: Colors.black87,
//         ),
//       ),
//       const SizedBox(height: 16),
//       Row(
//         children: [
//           const Icon(Icons.circle, size: 12, color: Colors.pink),
//           const SizedBox(width: 10),
//           Text(
//             "Browse and save outfit photos",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//       const SizedBox(height: 12),
//       Row(
//         children: [
//           Icon(Icons.circle, size: 12, color: Colors.grey[400]),
//           const SizedBox(width: 10),
//           const Text(
//             "Research venue options",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.black54,
//             ),
//           ),
//         ],
//       ),
//     ],
//   ),
// ),
}




































class LocationService {
  static const String _baseUrl = "https://www.countriesnow.space/api/v0.1/countries/cities";

  static Future<List<String>> fetchCities(String country) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"country": country}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['error'] == false) {
        return List<String>.from(data['data']); // returns list of city names
      } else {
        throw Exception(data['msg'] ?? "Failed to fetch cities");
      }
    } else {
      throw Exception("HTTP Error: ${response.statusCode}");
    }
  }
}
