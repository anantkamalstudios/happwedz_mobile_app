import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Wishlist/Wishlistscreen.dart';
import '../venuedetails.dart';

// class VenuesScreen extends StatelessWidget {
//   const VenuesScreen({Key? key}) : super(key: key);
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
//               _buildAppBar(context),
//               _buildSearchBar(),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildDestinationRatesSection(context),
//                       const SizedBox(height: 24),
//
//                       _buildDestinationRatesSection(context),
//                       const SizedBox(height: 24),
//
//                       _buildDestinationRatesSection(context),
//                       const SizedBox(height: 24),
//
//                       _buildDestinationRatesSection(context),
//                     ],
//                   ),
//                 ),
//               ),
//               // Positioned(
//               //   bottom: 24,
//               //   left: 0,
//               //   right: 0,
//               //   child: Row(
//               //     mainAxisAlignment: MainAxisAlignment.center,
//               //     children: [
//               //       _buildFloatingButton(Icons.filter_list, 'Filter'),
//               //       const SizedBox(width: 16),
//               //       _buildFloatingButton(Icons.favorite, 'Genie'),
//               //     ],
//               //   ),
//               // ),
//
//             ],
//           ),
//         )
//
//           ),
//
//
//     );
//   }
//
//   Widget _buildAppBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
//             onPressed: () => Navigator.pop(context),
//           ),
//           const Expanded(
//             child: Text(
//               'Venues',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: 48), // Balance the back button
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.9),
//           borderRadius: BorderRadius.circular(25),
//         ),
//         child: const TextField(
//           decoration: InputDecoration(
//             hintText: 'Search wedding venues...',
//             hintStyle: TextStyle(color: Colors.grey),
//             border: InputBorder.none,
//             prefixIcon: Icon(Icons.search, color: Colors.grey),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDestinationRatesSection(BuildContext context, Venue venue) {
//     final favouritesProvider = Provider.of<FavouritesProvider>(context, listen: false);
//     ValueNotifier<bool> isFav = ValueNotifier(
//         favouritesProvider.favouriteVenues.contains(venue.name)
//     );
//
//     return ValueListenableBuilder(
//       valueListenable: isFav,
//       builder: (context, bool fav, _) {
//         return Container(
//           margin: const EdgeInsets.only(bottom: 24),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Stack(
//                 children: [
//                   Container(
//                     height: 200,
//                     decoration: BoxDecoration(
//                       borderRadius: const BorderRadius.only(
//                         topLeft: Radius.circular(12),
//                         topRight: Radius.circular(12),
//                       ),
//                       image: DecorationImage(
//                         image: NetworkImage(venue.image),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     top: 8,
//                     right: 8,
//                     child: GestureDetector(
//                       onTap: () {
//                         isFav.value = !isFav.value;
//                         if (isFav.value) {
//                           favouritesProvider.addVenue(venue.name);
//                         } else {
//                           favouritesProvider.removeVenue(venue.name);
//                         }
//                       },
//                       child: CircleAvatar(
//                         backgroundColor: Colors.white.withOpacity(0.8),
//                         child: Icon(
//                           fav ? Icons.favorite : Icons.favorite_border,
//                           color: Colors.pink,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       venue.name,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       venue.price,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, size: 16, color: Colors.grey),
//                         const SizedBox(width: 4),
//                         Text(
//                           venue.pax,
//                           style: const TextStyle(fontSize: 12, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         const Icon(Icons.event, size: 16, color: Colors.grey),
//                         const SizedBox(width: 4),
//                         Text(
//                           venue.type,
//                           style: const TextStyle(fontSize: 12, color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//   // Widget _buildDestinationRatesSection(BuildContext context ) {
//   //   return InkWell(
//   //     onTap: (){
//   //       Navigator.push(
//   //         context,
//   //         MaterialPageRoute(builder: (context) => VenueDetailsScreen()),
//   //       );
//   //     },
//   //     child: Column(
//   //       crossAxisAlignment: CrossAxisAlignment.start,
//   //       children: [
//   //         //
//   //         Container(
//   //           decoration: BoxDecoration(
//   //             color: Colors.white,
//   //             borderRadius: BorderRadius.circular(12),
//   //             boxShadow: [
//   //               BoxShadow(
//   //                 color: Colors.black.withOpacity(0.1),
//   //                 blurRadius: 8,
//   //                 offset: const Offset(0, 2),
//   //               ),
//   //             ],
//   //           ),
//   //           child: Column(
//   //             crossAxisAlignment: CrossAxisAlignment.start,
//   //             children: [
//   //               Container(
//   //                 height: 200,
//   //                 decoration: const BoxDecoration(
//   //                   borderRadius: BorderRadius.only(
//   //                     topLeft: Radius.circular(12),
//   //                     topRight: Radius.circular(12),
//   //                   ),
//   //                   image: DecorationImage(
//   //                     image: NetworkImage('https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400&h=300&fit=crop'),
//   //                     fit: BoxFit.cover,
//   //                   ),
//   //                 ),
//   //               ),
//   //               Padding(
//   //                 padding: const EdgeInsets.all(16.0),
//   //                 child: Column(
//   //                   crossAxisAlignment: CrossAxisAlignment.start,
//   //                   children: [
//   //                     Row(
//   //                       children: [
//   //                         const Expanded(
//   //                           child: Column(
//   //                             crossAxisAlignment: CrossAxisAlignment.start,
//   //                             children: [
//   //                               Text(
//   //                                 'Seawood, Pune',
//   //                                 style: TextStyle(
//   //                                   fontSize: 12,
//   //                                   color: Colors.grey,
//   //                                 ),
//   //                               ),
//   //                               SizedBox(height: 4),
//   //                               Text(
//   //                                 'Fort Jadhavgadh, Pune',
//   //                                 style: TextStyle(
//   //                                   fontSize: 16,
//   //                                   fontWeight: FontWeight.bold,
//   //                                   color: Colors.black87,
//   //                                 ),
//   //                               ),
//   //                               SizedBox(height: 4),
//   //                               Text(
//   //                                 'veg',
//   //                                 style: TextStyle(
//   //                                   fontSize: 12,
//   //                                   color: Colors.grey,
//   //                                 ),
//   //                               ),
//   //                             ],
//   //                           ),
//   //                         ),
//   //                         Container(
//   //                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//   //                           decoration: BoxDecoration(
//   //                             color: Colors.orange,
//   //                             borderRadius: BorderRadius.circular(4),
//   //                           ),
//   //                           child: Row(
//   //                             mainAxisSize: MainAxisSize.min,
//   //                             children: [
//   //                               const Icon(Icons.star, color: Colors.white, size: 12),
//   //                               const SizedBox(width: 2),
//   //                               const Text(
//   //                                 '5.0(2)',
//   //                                 style: TextStyle(
//   //                                   color: Colors.white,
//   //                                   fontSize: 10,
//   //                                   fontWeight: FontWeight.bold,
//   //                                 ),
//   //                               ),
//   //                             ],
//   //                           ),
//   //                         ),
//   //                       ],
//   //                     ),
//   //                     const SizedBox(height: 12),
//   //                     const Text(
//   //                       '₹ 2,999 per plate',
//   //                       style: TextStyle(
//   //                         fontSize: 16,
//   //                         fontWeight: FontWeight.bold,
//   //                         color: Colors.black87,
//   //                       ),
//   //                     ),
//   //                     const SizedBox(height: 8),
//   //                     Row(
//   //                       children: [
//   //                         const Icon(Icons.location_on, size: 16, color: Colors.grey),
//   //                         const SizedBox(width: 4),
//   //                         const Text(
//   //                           '400 - 500 pax',
//   //                           style: TextStyle(fontSize: 12, color: Colors.grey),
//   //                         ),
//   //                         const SizedBox(width: 16),
//   //                         const Icon(Icons.event, size: 16, color: Colors.grey),
//   //                         const SizedBox(width: 4),
//   //                         const Text(
//   //                           'Banquet Halls, Wedding Resorts',
//   //                           style: TextStyle(fontSize: 12, color: Colors.grey),
//   //                         ),
//   //                       ],
//   //                     ),
//   //                     const SizedBox(height: 16),
//   //                     Row(
//   //                       children: [
//   //                         Expanded(
//   //                           child: Container(
//   //                             padding: const EdgeInsets.symmetric(vertical: 12),
//   //                             decoration: BoxDecoration(
//   //                               border: Border.all(color: const Color(0xFFE91E63)),
//   //                               borderRadius: BorderRadius.circular(6),
//   //                             ),
//   //                             child: const Row(
//   //                               mainAxisAlignment: MainAxisAlignment.center,
//   //                               children: [
//   //                                 Icon(Icons.message, color: Color(0xFFE91E63), size: 18),
//   //                                 SizedBox(width: 8),
//   //                                 Text(
//   //                                   'Message',
//   //                                   style: TextStyle(
//   //                                     color: Color(0xFFE91E63),
//   //                                     fontWeight: FontWeight.w600,
//   //                                   ),
//   //                                 ),
//   //                               ],
//   //                             ),
//   //                           ),
//   //                         ),
//   //                         const SizedBox(width: 12),
//   //                         Container(
//   //                           padding: const EdgeInsets.all(12),
//   //                           decoration: BoxDecoration(
//   //                             color: Colors.green,
//   //                             borderRadius: BorderRadius.circular(6),
//   //                           ),
//   //                           child: const Icon(Icons.message, color: Colors.white, size: 18),
//   //                         ),
//   //                         const SizedBox(width: 8),
//   //                         Container(
//   //                           padding: const EdgeInsets.all(12),
//   //                           decoration: BoxDecoration(
//   //                             color: Colors.green,
//   //                             borderRadius: BorderRadius.circular(6),
//   //                           ),
//   //                           child: const Icon(Icons.phone, color: Colors.white, size: 18),
//   //                         ),
//   //                       ],
//   //                     ),
//   //                   ],
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }
//
//   Widget _buildFilterSection() {
//     return Column(
//       children: [
//         Container(
//           height: 150,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             image: const DecorationImage(
//               image: NetworkImage('https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&h=200&fit=crop'),
//               fit: BoxFit.cover,
//             ),
//           ),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   Colors.transparent,
//                   Colors.black.withOpacity(0.5),
//                 ],
//               ),
//             ),
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE91E63),
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.filter_list, color: Colors.white, size: 18),
//                         SizedBox(width: 8),
//                         Text(
//                           'Filter',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE91E63),
//                       borderRadius: BorderRadius.circular(25),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.favorite, color: Colors.white, size: 18),
//                         SizedBox(width: 8),
//                         Text(
//                           'Genie',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//   Widget _buildFloatingButton(IconData icon, String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFE91E63),
//         borderRadius: BorderRadius.circular(25),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: Colors.white, size: 18),
//           const SizedBox(width: 8),
//           Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
// }
//
//
//
//
// class Venue {
//   final String name;
//   final String image;
//   final String price;
//   final String pax;
//   final String type;
//
//   Venue({
//     required this.name,
//     required this.image,
//     required this.price,
//     required this.pax,
//     required this.type,
//   });
// }



class VenuesScreen extends StatelessWidget {
  const VenuesScreen({Key? key}) : super(key: key);

  // Example list of venues — can be replaced with API fetched data
  final List<Venue> venues = const [
    Venue(
      name: 'Fort Jadhavgadh, Pune',
      image:
      'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400&h=300&fit=crop',
      price: '₹ 2,999 per plate',
      pax: '400 - 500 pax',
      type: 'Banquet Halls, Wedding Resorts',
    ),
    Venue(
      name: 'Seawood Palace, Mumbai',
      image:
      'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=400&h=300&fit=crop',
      price: '₹ 3,500 per plate',
      pax: '300 - 400 pax',
      type: 'Luxury Halls',
    ),
    // Add more venues here or fetch dynamically
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Colors.white],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    return _buildDestinationRatesSection(context, venue);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AppBar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Venues',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Search wedding venues...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // Dynamic Venue Card
  Widget _buildDestinationRatesSection(BuildContext context, Venue venue) {
    return Consumer<FavouritesProvider>(
      builder: (context, favouritesProvider, child) {
        final isFav = favouritesProvider.isFavourite(venue.name);

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(venue.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => favouritesProvider.toggleFavourite(venue.name),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: Colors.pink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      venue.price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          venue.pax,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          venue.type,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

// Venue model
class Venue {
  final String name;
  final String image;
  final String price;
  final String pax;
  final String type;

  const Venue({
    required this.name,
    required this.image,
    required this.price,
    required this.pax,
    required this.type,
  });
}
