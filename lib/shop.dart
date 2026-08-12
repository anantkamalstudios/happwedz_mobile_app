// import 'package:flutter/material.dart';
//
//
// class ShopScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFFF6B9D),
//               Color(0xFFFF8FA3),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               _buildHeader(),
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(0),
//                       topRight: Radius.circular(0),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       _buildCategoryTabs(),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               _buildBridalWearSection(),
//                               _buildJewellerySection(),
//                             ],
//                           ),
//                         ),
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
//   Widget _buildHeader() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 Icons.arrow_back_ios,
//                 color: Colors.white,
//                 size: 20,
//               ),
//               SizedBox(width: 8),
//               Text(
//                 'Nashik',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           Text(
//             'Shop',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           SizedBox(width: 40), // For balance
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCategoryTabs() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildCategoryTab('Bridal Wear', 'assets/bridal_icon.png', true),
//           _buildCategoryTab('Jewellery', 'assets/jewellery_icon.png', false),
//           _buildCategoryTab('Makeup', 'assets/makeup_icon.png', false),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCategoryTab(String title, String iconPath, bool isSelected) {
//     return Column(
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             color: isSelected ? Color(0xFFFF6B9D) : Color(0xFFF8F8F8),
//             borderRadius: BorderRadius.circular(15),
//           ),
//           child: Center(
//             child: Container(
//               width: 35,
//               height: 35,
//               decoration: BoxDecoration(
//                 color: isSelected ? Colors.white : Color(0xFFE0E0E0),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Icon(
//                 Icons.shopping_bag_outlined,
//                 color: isSelected ? Color(0xFFFF6B9D) : Colors.grey[600],
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: isSelected ? Color(0xFFFF6B9D) : Colors.grey[600],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildBridalWearSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.symmetric(horizontal: 20),
//           child: Text(
//             'Bridal Wear',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//         SizedBox(height: 20),
//         _buildHeroCard(),
//         SizedBox(height: 20),
//         _buildSubCategories(),
//       ],
//     );
//   }
//
//   Widget _buildHeroCard() {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 20),
//       height: 250,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Color(0xFFF5E6D3),
//             Color(0xFFE8D5C1),
//           ],
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           Positioned(
//             left: 0,
//             bottom: 0,
//             child: Container(
//               width: 120,
//               height: 200,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(20),
//                 ),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.only(
//                   bottomLeft: Radius.circular(20),
//                 ),
//                 child: Container(
//                   color: Colors.green[200],
//                   child: Icon(
//                     Icons.nature,
//                     size: 60,
//                     color: Colors.green[400],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             right: 20,
//             top: 20,
//             bottom: 20,
//             child: Container(
//               width: 180,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(15),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Color(0xFFFFF5F0),
//                         Color(0xFFFFE4E1),
//                       ],
//                     ),
//                   ),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: BoxDecoration(
//                             color: Color(0xFFFF6B9D),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.person,
//                             color: Colors.white,
//                             size: 40,
//                           ),
//                         ),
//                         SizedBox(height: 10),
//                         Container(
//                           width: 100,
//                           height: 60,
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Color(0xFFFF6B9D),
//                                 Color(0xFFFFB6C1),
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 30,
//             left: 20,
//             right: 20,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Text(
//                   'I believes in love',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.black87,
//                   ),
//                 ),
//                 SizedBox(height: 5),
//                 Text(
//                   'Browse our curated bridal shopping',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSubCategories() {
//     List<Map<String, dynamic>> categories = [
//       {'title': 'Mehendi', 'color': Color(0xFFFF6B9D)},
//       {'title': 'Sangeet', 'color': Color(0xFF8B4513)},
//       {'title': 'Cocktail', 'color': Color(0xFFDAA520)},
//       {'title': 'Bridesmaids', 'color': Color(0xFFFF6B9D)},
//     ];
//
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: categories.map((category) {
//           return _buildSubCategory(category['title'], category['color']);
//         }).toList(),
//       ),
//     );
//   }
//
//   Widget _buildSubCategory(String title, Color color) {
//     return Column(
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           decoration: BoxDecoration(
//             color: color.withValues(alpha: 0.1),
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: color.withValues(alpha: 0.3),
//               width: 2,
//             ),
//           ),
//           child: Container(
//             width: 45,
//             height: 45,
//             decoration: BoxDecoration(
//               color: color,
//               shape: BoxShape.circle,
//             ),
//             margin: EdgeInsets.all(8),
//           ),
//         ),
//         SizedBox(height: 8),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildJewellerySection() {
//     return Container(
//       padding: EdgeInsets.all(20),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             'Jewellery',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//               color: Colors.black87,
//             ),
//           ),
//           Container(
//             width: 50,
//             height: 50,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFFFF6B9D),
//                   Color(0xFFFF8FA3),
//                 ],
//               ),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.diamond,
//               color: Colors.white,
//               size: 24,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // Additional Custom Widgets for enhanced functionality
// class AnimatedCategoryCard extends StatefulWidget {
//   final String title;
//   final IconData icon;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const AnimatedCategoryCard({
//     Key? key,
//     required this.title,
//     required this.icon,
//     required this.isSelected,
//     required this.onTap,
//   }) : super(key: key);
//
//   @override
//   _AnimatedCategoryCardState createState() => _AnimatedCategoryCardState();
// }
//
// class _AnimatedCategoryCardState extends State<AnimatedCategoryCard>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 200),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
//       CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => _controller.forward(),
//       onTapUp: (_) => _controller.reverse(),
//       onTapCancel: () => _controller.reverse(),
//       onTap: widget.onTap,
//       child: AnimatedBuilder(
//         animation: _scaleAnimation,
//         builder: (context, child) {
//           return Transform.scale(
//             scale: _scaleAnimation.value,
//             child: Column(
//               children: [
//                 AnimatedContainer(
//                   duration: Duration(milliseconds: 300),
//                   width: 60,
//                   height: 60,
//                   decoration: BoxDecoration(
//                     gradient: widget.isSelected
//                         ? LinearGradient(
//                       colors: [Color(0xFFFF6B9D), Color(0xFFFF8FA3)],
//                     )
//                         : null,
//                     color: widget.isSelected ? null : Color(0xFFF8F8F8),
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: widget.isSelected
//                         ? [
//                       BoxShadow(
//                         color: Color(0xFFFF6B9D).withValues(alpha: 0.3),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ]
//                         : null,
//                   ),
//                   child: Center(
//                     child: Icon(
//                       widget.icon,
//                       color: widget.isSelected ? Colors.white : Colors.grey[600],
//                       size: 24,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   widget.title,
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                     color: widget.isSelected ? Color(0xFFFF6B9D) : Colors.grey[600],
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
//
// // Shimmer Loading Effect for better UX
// class ShimmerWidget extends StatefulWidget {
//   final Widget child;
//
//   const ShimmerWidget({Key? key, required this.child}) : super(key: key);
//
//   @override
//   _ShimmerWidgetState createState() => _ShimmerWidgetState();
// }
//
// class _ShimmerWidgetState extends State<ShimmerWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(seconds: 1),
//       vsync: this,
//     )..repeat();
//     _animation = Tween<double>(begin: -1.0, end: 1.0).animate(_controller);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _animation,
//       builder: (context, child) {
//         return ShaderMask(
//           shaderCallback: (bounds) {
//             return LinearGradient(
//               colors: [
//                 Colors.grey[300]!,
//                 Colors.grey[100]!,
//                 Colors.grey[300]!,
//               ],
//               stops: [0.0, 0.5, 1.0],
//               begin: Alignment(-1.0 + _animation.value, 0.0),
//               end: Alignment(1.0 + _animation.value, 0.0),
//             ).createShader(bounds);
//           },
//           child: widget.child,
//         );
//       },
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }


import 'package:flutter/material.dart';



class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
              // Custom App Bar
              Row(
                children: [
                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  SizedBox(width: 8),

                  Spacer(),
                  Text(
                    'Shop',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.search, color: Colors.white, size: 22),
                  ),
                ],
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),

                      // Main Categories
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMainCategory(
                              'assets/bridal.png',
                              'Bridal Wear',
                              Colors.pink[100]!,
                            ),
                            _buildMainCategory(
                              'assets/jewellery.png',
                              'Jewellery',
                              Colors.orange[100]!,
                            ),
                            _buildMainCategory(
                              'assets/makeup.png',
                              'Makeup',
                              Colors.red[100]!,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 30),

                      // Bridal Wear Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Bridal Wear',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Hero Bridal Image
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        height: 300,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink[50]!,
                              Colors.orange[50]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.pink[100]!.withValues(alpha: 0.7),
                                      Colors.orange[100]!.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 30,
                              left: 30,
                              right: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lehengas to love',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black.withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Browse our new collection of lehengas',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black.withValues(alpha: 0.3),
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

                      SizedBox(height: 25),

                      // Bridal Categories
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSubCategory('Mehendi', Colors.green[200]!),
                            _buildSubCategory('Sangeet', Colors.purple[200]!),
                            _buildSubCategory('Cocktail', Colors.blue[200]!),
                            _buildSubCategory('Bridesmaids', Colors.pink[200]!),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Jewellery Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Jewellery',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Jewellery Hero Image
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange[100]!,
                              Colors.amber[100]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 30,
                              left: 30,
                              right: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Necklace that make us swoon',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black.withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'A little bling never hurt',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 16,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black.withValues(alpha: 0.3),
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

                      SizedBox(height: 25),

                      // Jewellery Categories
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSubCategory('Bridal Sets', Colors.green[100]!),
                            _buildSubCategory('Bangles', Colors.red[200]!),
                            _buildSubCategory('Earrings', Colors.blue[100]!),
                            _buildSubCategory('Matha Patti', Colors.purple[200]!),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Makeup Section
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Makeup',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Makeup Hero Image
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink[100]!,
                              Colors.red[100]!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              bottom: 30,
                              left: 30,
                              right: 30,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Looking Gorgeous!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.black.withValues(alpha: 0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Best steal choices to create a complete bridal makeup',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black.withValues(alpha: 0.3),
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

                      SizedBox(height: 25),

                      // Makeup Categories
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSubCategory('Lipstick', Colors.red[300]!),
                            _buildSubCategory('Blush', Colors.pink[200]!),
                            _buildSubCategory('Foundation', Colors.orange[200]!),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategory(String imagePath, String title, Color backgroundColor) {
    return Container(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getIconForCategory(title),
              color: Colors.grey[700],
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategory(String title, Color color) {
    return Container(
      width: 70,
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(27.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getIconForSubCategory(title),
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Bridal Wear':
        return Icons.person_outline;
      case 'Jewellery':
        return Icons.diamond_outlined;
      case 'Makeup':
        return Icons.face_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  IconData _getIconForSubCategory(String category) {
    switch (category) {
      case 'Mehendi':
        return Icons.palette_outlined;
      case 'Sangeet':
        return Icons.music_note_outlined;
      case 'Cocktail':
        return Icons.local_bar_outlined;
      case 'Bridesmaids':
        return Icons.group_outlined;
      case 'Bridal Sets':
        return Icons.diamond_outlined;
      case 'Bangles':
        return Icons.circle_outlined;
      case 'Earrings':
        return Icons.earbuds_outlined;
      case 'Matha Patti':
        return Icons.star_outlined;
      case 'Lipstick':
        return Icons.colorize_outlined;
      case 'Blush':
        return Icons.brush_outlined;
      case 'Foundation':
        return Icons.face_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}