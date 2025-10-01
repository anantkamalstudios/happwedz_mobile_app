// import 'package:flutter/material.dart';
//
// class Checklistscreen extends StatefulWidget {
//   @override
//   _ChecklistscreenState createState() => _ChecklistscreenState();
// }
//
// class _ChecklistscreenState extends State<Checklistscreen>
//     with TickerProviderStateMixin {
//   late AnimationController _progressController;
//   late AnimationController _fadeController;
//
//   Map<String, bool> checklistItems = {
//     'Check if your wedding date is on an auspicious day': false,
//     'Do you want a destination wedding?': false,
//     'Short list date options for all pre-wedding functions': false,
//     'Delegate responsibilities': false,
//     'Decide whether or not you\'d like to use a wedding planner': false,
//     'Download the HappyWeds App': false,
//   };
//
//   @override
//   void initState() {
//     super.initState();
//     _progressController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _fadeController = AnimationController(
//       duration: Duration(milliseconds: 800),
//       vsync: this,
//     );
//
//     // Start animations
//     _fadeController.forward();
//     Future.delayed(Duration(milliseconds: 300), () {
//       _progressController.forward();
//     });
//   }
//
//   @override
//   void dispose() {
//     _progressController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   int get completedItems => checklistItems.values.where((v) => v).length;
//   int get totalItems => checklistItems.length;
//
//   void toggleItem(String key) {
//     setState(() {
//       checklistItems[key] = !checklistItems[key]!;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFE91E63),
//               Color(0xFFF06292),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // App Bar
//               Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: Container(
//                         padding: EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Icon(
//                           Icons.arrow_back_ios,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: Text(
//                         'My Checklist',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 36), // Balance the back button
//                   ],
//                 ),
//               ),
//
//               // Progress Card
//               FadeTransition(
//                 opacity: _fadeController,
//                 child: Container(
//                   margin: EdgeInsets.symmetric(horizontal: 20),
//                   padding: EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                       colors: [
//                         Color(0xFFEC407A),
//                         Color(0xFFAD1457),
//                       ],
//                     ),
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               '$completedItems',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 32,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             Text(
//                               'Done',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.9),
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               '7 Days to go!',
//                               style: TextStyle(
//                                 color: Colors.white.withOpacity(0.8),
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Column(
//                         children: [
//                           Text(
//                             '$totalItems',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           Text(
//                             'To Do',
//                             style: TextStyle(
//                               color: Colors.white.withOpacity(0.9),
//                               fontSize: 14,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               SizedBox(height: 20),
//
//               // Checklist
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       topRight: Radius.circular(30),
//                     ),
//                   ),
//                   child: Column(
//                     children: [
//                       SizedBox(height: 30),
//                       Expanded(
//                         child: ListView(
//                           padding: EdgeInsets.symmetric(horizontal: 20),
//                           children: [
//                             _buildSectionHeader('12 Months to go'),
//                             SizedBox(height: 16),
//                             _buildChecklistItem(
//                               'Check if your wedding date is on an auspicious day',
//                               'This is important for many families',
//                               0,
//                             ),
//                             SizedBox(height: 20),
//
//                             _buildSectionHeader('11 Months to go'),
//                             SizedBox(height: 16),
//                             _buildChecklistItem(
//                               'Do you want a destination wedding?',
//                               'This will help with initial planning',
//                               1,
//                             ),
//                             SizedBox(height: 12),
//                             _buildChecklistItem(
//                               'Short list date options for all pre-wedding functions',
//                               'Plan ahead for better coordination',
//                               2,
//                             ),
//                             SizedBox(height: 12),
//                             _buildChecklistItem(
//                               'Delegate responsibilities',
//                               'Share the workload with family',
//                               3,
//                             ),
//                             SizedBox(height: 12),
//                             _buildChecklistItem(
//                               'Decide whether or not you\'d like to use a wedding planner',
//                               'Professional help can be valuable',
//                               4,
//                             ),
//                             SizedBox(height: 20),
//
//                             _buildSectionHeader('10 Months to go'),
//                             SizedBox(height: 16),
//                             _buildChecklistItem(
//                               'Download the HappyWeds App',
//                               'Your ultimate wedding companion',
//                               5,
//                             ),
//                             SizedBox(height: 20),
//
//                             _buildSectionHeader('9 Months to go'),
//                             SizedBox(height: 16),
//                             _buildChecklistItem(
//                               'Research Venue options',
//                               'Research Wedding Planners',
//                              4
//                             ),
//                             SizedBox(height: 40),
//                           ],
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
//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.w600,
//         color: Color(0xFF666666),
//       ),
//     );
//   }
//
//   Widget _buildSpecialChecklistItem(String title, String subtitle, int index) {
//     String key = checklistItems.keys.elementAt(index);
//     bool isChecked = checklistItems[key]!;
//
//     return AnimatedContainer(
//       duration: Duration(milliseconds: 300),
//       child: GestureDetector(
//         onTap: () => toggleItem(key),
//         child: Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: isChecked
//                   ? [Color(0xFFE91E63), Color(0xFFF48FB1)]
//                   : [Color(0xFFFFF3F8), Color(0xFFFCE4EC)],
//             ),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: Color(0xFFE91E63),
//               width: 2,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Color(0xFFE91E63).withOpacity(0.2),
//                 blurRadius: 10,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               AnimatedContainer(
//                 duration: Duration(milliseconds: 200),
//                 width: 28,
//                 height: 28,
//                 decoration: BoxDecoration(
//                   color: isChecked ? Colors.white : Color(0xFFE91E63),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isChecked ? Colors.white : Color(0xFFE91E63),
//                     width: 2,
//                   ),
//                 ),
//                 child: Icon(
//                   isChecked ? Icons.favorite : Icons.favorite_border,
//                   color: isChecked ? Color(0xFFE91E63) : Colors.white,
//                   size: 18,
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: isChecked ? Colors.white : Color(0xFFE91E63),
//                         decoration: isChecked ? TextDecoration.lineThrough : null,
//                       ),
//                     ),
//                     if (subtitle.isNotEmpty) ...[
//                       SizedBox(height: 4),
//                       Text(
//                         subtitle,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: isChecked ? Colors.white.withOpacity(0.9) : Color(0xFFE91E63).withOpacity(0.8),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildChecklistItem(String title, String subtitle, int index) {
//     String key = checklistItems.keys.elementAt(index);
//     bool isChecked = checklistItems[key]!;
//
//     return AnimatedContainer(
//       duration: Duration(milliseconds: 300),
//       child: GestureDetector(
//         onTap: () => toggleItem(key),
//         child: Container(
//           padding: EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: isChecked ? Color(0xFFF8F9FA) : Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isChecked ? Color(0xFFE91E63) : Color(0xFFE5E5E5),
//               width: isChecked ? 2 : 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 5,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               AnimatedContainer(
//                 duration: Duration(milliseconds: 200),
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: isChecked ? Color(0xFFE91E63) : Colors.transparent,
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(
//                     color: isChecked ? Color(0xFFE91E63) : Color(0xFFCCCCCC),
//                     width: 2,
//                   ),
//                 ),
//                 child: isChecked
//                     ? Icon(
//                   Icons.check,
//                   color: Colors.white,
//                   size: 16,
//                 )
//                     : null,
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w500,
//                         color: isChecked ? Color(0xFF333333) : Color(0xFF333333),
//                         decoration: isChecked ? TextDecoration.lineThrough : null,
//                       ),
//                     ),
//                     if (subtitle.isNotEmpty) ...[
//                       SizedBox(height: 4),
//                       Text(
//                         subtitle,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Color(0xFF888888),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Additional screens you might want to add
// class WeddingPlannerHome extends StatelessWidget {
//   const WeddingPlannerHome({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFE91E63), Color(0xFFF48FB1)],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               Padding(
//                 padding: EdgeInsets.all(20),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'HappyWeds',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     CircleAvatar(
//                       backgroundColor: Colors.white.withOpacity(0.2),
//                       child: Icon(Icons.person, color: Colors.white),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       topRight: Radius.circular(30),
//                     ),
//                   ),
//                   child: GridView.count(
//                     crossAxisCount: 2,
//                     padding: EdgeInsets.all(20),
//                     crossAxisSpacing: 16,
//                     mainAxisSpacing: 16,
//                     children: [
//                       _buildFeatureCard(
//                         'Checklist',
//                         Icons.check_box,
//                         Color(0xFFE91E63),
//                             () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => Checklistscreen(),
//                           ),
//                         ),
//                       ),
//                       _buildFeatureCard(
//                         'Budget',
//                         Icons.account_balance_wallet,
//                         Color(0xFF2196F3),
//                             () {},
//                       ),
//                       _buildFeatureCard(
//                         'Vendors',
//                         Icons.business,
//                         Color(0xFF4CAF50),
//                             () {},
//                       ),
//                       _buildFeatureCard(
//                         'Timeline',
//                         Icons.schedule,
//                         Color(0xFFFF9800),
//                             () {},
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
//   Widget _buildFeatureCard(String title, IconData icon, Color color, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 8,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: color, size: 32),
//             ),
//             SizedBox(height: 12),
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF333333),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeddingTimelinePage extends StatefulWidget {
  const WeddingTimelinePage({super.key});

  @override
  _WeddingTimelinePageState createState() => _WeddingTimelinePageState();
}

class _WeddingTimelinePageState extends State<WeddingTimelinePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Map<String, bool> checkedItems = {};
  DateTime? weddingDate;

  final List<TimelineItem> timelineData = WeddingTimelineData.timelineData;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();

    _loadLastWeddingDate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    if (weddingDate == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'wedding_${weddingDate!.toIso8601String()}_tasks';
    List<String> completedTasks =
    checkedItems.entries.where((e) => e.value).map((e) => e.key).toList();
    await prefs.setStringList(key, completedTasks);
  }

  Future<void> _loadProgress() async {
    if (weddingDate == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'wedding_${weddingDate!.toIso8601String()}_tasks';
    List<String>? completed = prefs.getStringList(key);
    setState(() {
      checkedItems.clear();
      if (completed != null) {
        for (var task in completed) {
          checkedItems[task] = true;
        }
      }
    });
  }

  Future<void> _saveLastWeddingDate() async {
    if (weddingDate == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_wedding_date', weddingDate!.toIso8601String());
  }

  Future<void> _loadLastWeddingDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDate = prefs.getString('last_wedding_date');
    if (lastDate != null) {
      setState(() {
        weddingDate = DateTime.parse(lastDate);
      });
      await _loadProgress();
    }
  }

  String getTimeframeLabel(int index) {
    if (weddingDate == null) {
      const labels = [
        "12 MONTHS OR MORE TO GO",
        "9 MONTHS TO GO",
        "6 MONTHS TO GO",
        "5 MONTHS TO GO",
        "4 MONTHS TO GO",
        "3 MONTHS TO GO",
        "2 MONTHS TO GO",
        "1 MONTH TO GO",
        "1 WEEK TO GO"
      ];
      return index < labels.length ? labels[index] : "This Week";
    }
    int totalItems = timelineData.length;
    int daysBeforeWedding = (totalItems - index) * 30;
    DateTime taskDate = weddingDate!.subtract(Duration(days: daysBeforeWedding));
    Duration difference = weddingDate!.difference(taskDate);
    if (difference.inDays >= 365) return "12 MONTHS OR MORE TO GO";
    if (difference.inDays >= 270) return "9 MONTHS TO GO";
    if (difference.inDays >= 180) return "6 MONTHS TO GO";
    if (difference.inDays >= 150) return "5 MONTHS TO GO";
    if (difference.inDays >= 120) return "4 MONTHS TO GO";
    if (difference.inDays >= 90) return "3 MONTHS TO GO";
    if (difference.inDays >= 60) return "2 MONTHS TO GO";
    if (difference.inDays >= 30) return "1 MONTH TO GO";
    if (difference.inDays >= 7) return "1 WEEK TO GO";
    return "This Week";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('Wedding Timeline'),
        backgroundColor: Color(0xFFFF7B9A),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF7B9A),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: weddingDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 730)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      weddingDate = pickedDate;
                    });
                    await _loadProgress();
                    await _saveLastWeddingDate();
                  }
                },
                child: Text(
                  weddingDate == null
                      ? "Select Wedding Date"
                      : "Wedding Date: ${weddingDate!.day}/${weddingDate!.month}/${weddingDate!.year}",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 20),

              ...timelineData.asMap().entries.map((entry) {
                int index = entry.key;
                TimelineItem item = entry.value;
                return _buildTimelineCard(item, index);
              }).toList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showProgressDialog,
        backgroundColor: Color(0xFFFF7B9A),
        child: Icon(Icons.analytics),
      ),
    );
  }

  Widget _buildTimelineCard(TimelineItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineConnector(index, item.icon, item.color),
          SizedBox(width: 16),
          Expanded(child: _buildTaskCard(item, index)),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(int index, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        if (index < timelineData.length - 1)
          Container(
            width: 2,
            height: 60,
            color: Colors.grey.shade300,
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
      ],
    );
  }

  Widget _buildTaskCard(TimelineItem item, int index) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                getTimeframeLabel(index),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 16),
            ...item.tasks.map((task) => _buildTaskItem(task)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String task) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (weddingDate == null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Select Wedding Date First'),
                    content:
                    Text('Please select your wedding date before marking tasks.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('OK'),
                      )
                    ],
                  ),
                );
                return;
              }

              if (checkedItems[task] == true) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Task already completed!'),
                  duration: Duration(seconds: 2),
                ));
                return;
              }

              setState(() {
                checkedItems[task] = true;
              });
              await _saveProgress();
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checkedItems[task] == true
                    ? Color(0xFFFF7B9A)
                    : Colors.transparent,
                border: Border.all(
                    color: checkedItems[task] == true
                        ? Color(0xFFFF7B9A)
                        : Colors.grey.shade400,
                    width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: checkedItems[task] == true
                  ? Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              task,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                decoration: checkedItems[task] == true
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showProgressDialog() {
    int totalTasks = timelineData.fold(0, (sum, item) => sum + item.tasks.length);
    int completedTasks = checkedItems.values.where((c) => c).length;
    double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Wedding Planning Progress',
          style: TextStyle(color: Color(0xFFFF7B9A), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7B9A)),
              strokeWidth: 6,
            ),
            SizedBox(height: 20),
            Text('${(progress * 100).toInt()}% Complete',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('$completedTasks of $totalTasks tasks completed',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: Color(0xFFFF7B9A))),
          )
        ],
      ),
    );
  }
}


class TimelineItem {
  final List<String> tasks;
  final IconData icon;
  final Color color;

  TimelineItem({
    required this.tasks,
    required this.icon,
    required this.color,
  });
}

class WeddingTimelineData {
  // This is the dynamic list of timeline items
  static List<TimelineItem> timelineData = [
    TimelineItem(
      tasks: ["Browse and save outfit photos"],
      icon: Icons.favorite,
      color: Color(0xFFFF7B9A),
    ),
    TimelineItem(
      tasks: [
        "Decide wedding budget",
        "Research venue options",
        "Research wedding planners"
      ],
      icon: Icons.account_balance_wallet,
      color: Color(0xFFFFB3C1),
    ),
    TimelineItem(
      tasks: [
        "Book your photographer",
        "Book your venue",
        "Book your makeup artist",
        "Hire Caterers"
      ],
      icon: Icons.camera_alt,
      color: Color(0xFFFF7B9A),
    ),
    TimelineItem(
      tasks: [
        "Renew passports",
        "Reserve flights and book a hotel for your honeymoon",
        "Browse invitation ideas"
      ],
      icon: Icons.flight,
      color: Color(0xFFFF7B9A),
    ),
    TimelineItem(
      tasks: [
        "Hire wedding decorator",
        "Research bridal wear stores",
        "Order wedding invites"
      ],
      icon: Icons.rotate_90_degrees_ccw_outlined,
      color: Color(0xFFFF7B9A),
    ),
    TimelineItem(
      tasks: [
        "Order bridal wear",
        "Order groom wear",
        "Book DJ",
        "Book mehendi artist"
      ],
      icon: Icons.shopping_bag,
      color: Color(0xFFFFB3C1),
    ),
    TimelineItem(
      tasks: [
        "Book mehendi artist",
        "Buy favors to distribute on Mehendi",
        "Book your pre-wedding shoot photographer",
        "Find sangeet choreographer",
        "Book family makeup services for your relatives",
        "Order sweets or favors for wedding invitations",
        "Have a food tasting",
        "Research sangeet songs and start practicing"
      ],
      icon: Icons.palette,
      color: Color(0xFFFF7B9A),
    ),
    TimelineItem(
      tasks: [
        "Book wedding cake",
        "Book trousseau packer",
        "Buy groom and bride accessories",
        "Start pre-bridal skin care packages"
      ],
      icon: Icons.cake,
      color: Color(0xFFFF7B9A),
    ),
    TimelineItem(
      tasks: [
        "Book your vidal vehicle",
        "Pack your honeymoon",
        "Give yourself a spa day",
        "Reconfirm time with vendors"
      ],
      icon: Icons.directions_car,
      color: Color(0xFFFF7B9A),
    ),
  ];
}





// import 'package:flutter/material.dart';
//
//
// class WeddingTimelinePage extends StatefulWidget {
//   @override
//   _WeddingTimelinePageState createState() => _WeddingTimelinePageState();
// }
//
// class _WeddingTimelinePageState extends State<WeddingTimelinePage>
//     with TickerProviderStateMixin {
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   Map<String, bool> checkedItems = {};
//
//   final List<TimelineItem> timelineData = [
//     TimelineItem(
//       timeframe: "12 MONTHS OR MORE TO GO",
//       icon: Icons.favorite,
//       tasks: ["Browse and save outfit photos"],
//       color: Color(0xFFFF7B9A),
//     ),
//     TimelineItem(
//       timeframe: "9 MONTHS TO GO",
//       icon: Icons.account_balance_wallet,
//       tasks: [
//         "Decide wedding budget",
//         "Research venue options",
//         "Research wedding planners"
//       ],
//       color: Color(0xFFFFB3C1),
//     ),
//     TimelineItem(
//       timeframe: "6 MONTHS TO GO",
//       icon: Icons.camera_alt,
//       tasks: [
//         "Book your photographer",
//         "Book your venue",
//         "Book your makeup artist",
//         "Hire Caterers"
//       ],
//       color: Color(0xFFFF7B9A),
//     ),
//     TimelineItem(
//       timeframe: "5 MONTHS TO GO",
//       icon: Icons.flight,
//       tasks: [
//         "Renew passports",
//         "Reserve flights and book a hotel for your honeymoon",
//         "Browse invitation ideas"
//       ],
//       color: Color(0xFFFF7B9A),
//     ),
//     TimelineItem(
//       timeframe: "4 MONTHS TO GO",
//       icon: Icons.rotate_90_degrees_ccw_outlined,
//       tasks: [
//         "Hire wedding decorator",
//         "Research bridal wear stores",
//         "Order wedding invites"
//       ],
//       color: Color(0xFFFF7B9A),
//     ),
//     TimelineItem(
//       timeframe: "3 MONTHS TO GO",
//       icon: Icons.shopping_bag,
//       tasks: [
//         "Order bridal wear",
//         "Order groom wear",
//         "Book DJ",
//         "Book mehendi artist"
//       ],
//       color: Color(0xFFFFB3C1),
//     ),
//     TimelineItem(
//       timeframe: "2 MONTHS TO GO",
//       icon: Icons.palette,
//       tasks: [
//         "Book mehendi artist",
//         "Buy favors to distribute on Mehendi",
//         "Book your pre-wedding shoot photographer",
//         "Find sangeet choreographer",
//         "Book family makeup services for your relatives",
//         "Order sweets or favors for wedding invitations",
//         "Have a food tasting",
//         "Research sangeet songs and start practicing"
//       ],
//       color: Color(0xFFFF7B9A),
//     ),
//     TimelineItem(
//       timeframe: "1 MONTH TO GO",
//       icon: Icons.cake,
//       tasks: [
//         "Book wedding cake",
//         "Book trousseau packer",
//         "Buy groom and bride accessories",
//         "Start pre-bridal skin care packages"
//       ],
//       color: Color(0xFFFF7B9A),
//     ),
//     TimelineItem(
//       timeframe: "1 WEEK TO GO",
//       icon: Icons.directions_car,
//       tasks: [
//         "Book your vidal vehicle",
//         "Pack your honeymoon",
//         "Give yourself a spa day",
//         "Reconfirm time with vendors"
//       ],
//       color: Color(0xFFFF7B9A),
//     ),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       duration: Duration(milliseconds: 1500),
//       vsync: this,
//     );
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     ));
//     _animationController.forward();
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF8F8F8),
//       appBar: AppBar(
//         title: Text(
//           'Wedding Timeline',
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Color(0xFFFF7B9A),
//         elevation: 0,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.share),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text('Share timeline feature coming soon!')),
//               );
//             },
//           ),
//         ],
//       ),
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Social Media Icons
//               _buildSocialMediaIcons(),
//               SizedBox(height: 20),
//
//               // Timeline
//               ...timelineData.asMap().entries.map((entry) {
//                 int index = entry.key;
//                 TimelineItem item = entry.value;
//                 return _buildTimelineCard(item, index);
//               }).toList(),
//
//               // Congratulations Section
//               // _buildCongratulationsSection(),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           _showProgressDialog();
//         },
//         backgroundColor: Color(0xFFFF7B9A),
//         child: Icon(Icons.analytics),
//       ),
//     );
//   }
//
//   Widget _buildSocialMediaIcons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         _buildSocialIcon(Icons.facebook, Color(0xFF1877F2)),
//         SizedBox(width: 12),
//         _buildSocialIcon(Icons.sms, Color(0xFF1DA1F2)),
//         SizedBox(width: 12),
//         _buildSocialIcon(Icons.sms, Color(0xFFE60023)),
//       ],
//     );
//   }
//
//   Widget _buildSocialIcon(IconData icon, Color color) {
//     return Container(
//       width: 45,
//       height: 45,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.3),
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Icon(
//         icon,
//         color: Colors.white,
//         size: 24,
//       ),
//     );
//   }
//
//   Widget _buildTimelineCard(TimelineItem item, int index) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 20),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Timeline Connector
//           _buildTimelineConnector(index, item.icon, item.color),
//           SizedBox(width: 16),
//
//           // Content Card
//           Expanded(
//             child: AnimatedContainer(
//               duration: Duration(milliseconds: 500),
//               curve: Curves.easeInOut,
//               child: _buildTaskCard(item),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimelineConnector(int index, IconData icon, Color color) {
//     return Column(
//       children: [
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//             boxShadow: [
//               BoxShadow(
//                 color: color.withOpacity(0.4),
//                 blurRadius: 8,
//                 offset: Offset(0, 4),
//               ),
//             ],
//           ),
//           child: Icon(
//             icon,
//             color: Colors.white,
//             size: 24,
//           ),
//         ),
//         if (index < timelineData.length - 1)
//           Container(
//             width: 2,
//             height: 60,
//             color: Colors.grey.shade300,
//             margin: EdgeInsets.symmetric(vertical: 8),
//           ),
//       ],
//     );
//   }
//
//   Widget _buildTaskCard(TimelineItem item) {
//     return Card(
//       elevation: 6,
//       shadowColor: Colors.black26,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             colors: [item.color.withOpacity(0.1), Colors.white],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade600,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   item.timeframe,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // Tasks
//               ...item.tasks.map((task) => _buildTaskItem(task)).toList(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTaskItem(String task) {
//     return Container(
//       margin: EdgeInsets.only(bottom: 8),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 checkedItems[task] = !(checkedItems[task] ?? false);
//               });
//             },
//             child: AnimatedContainer(
//               duration: Duration(milliseconds: 200),
//               width: 20,
//               height: 20,
//               decoration: BoxDecoration(
//                 color: checkedItems[task] == true
//                     ? Color(0xFFFF7B9A)
//                     : Colors.transparent,
//                 border: Border.all(
//                   color: checkedItems[task] == true
//                       ? Color(0xFFFF7B9A)
//                       : Colors.grey.shade400,
//                   width: 2,
//                 ),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//               child: checkedItems[task] == true
//                   ? Icon(
//                 Icons.check,
//                 color: Colors.white,
//                 size: 14,
//               )
//                   : null,
//             ),
//           ),
//           SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               task,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade700,
//                 decoration: checkedItems[task] == true
//                     ? TextDecoration.lineThrough
//                     : null,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCongratulationsSection() {
//     return Container(
//       margin: EdgeInsets.only(top: 30, bottom: 20),
//       padding: EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFFF7B9A), Color(0xFFFFB3C1)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Color(0xFFFF7B9A).withOpacity(0.3),
//             blurRadius: 15,
//             offset: Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.favorite, color: Colors.white, size: 30),
//               SizedBox(width: 8),
//               Icon(Icons.people, color: Colors.white, size: 40),
//               SizedBox(width: 8),
//               Icon(Icons.favorite, color: Colors.white, size: 30),
//             ],
//           ),
//           SizedBox(height: 16),
//           Text(
//             'Congratulations!',
//             style: TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//           ),
//           SizedBox(height: 8),
//           Text(
//             'Get married to the love of your life',
//             style: TextStyle(
//               fontSize: 18,
//               color: Colors.white.withOpacity(0.9),
//               fontStyle: FontStyle.italic,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showProgressDialog() {
//     int totalTasks = timelineData.fold(0, (sum, item) => sum + item.tasks.length);
//     int completedTasks = checkedItems.values.where((completed) => completed).length;
//     double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
//
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: Text(
//             'Wedding Planning Progress',
//             style: TextStyle(
//               color: Color(0xFFFF7B9A),
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircularProgressIndicator(
//                 value: progress,
//                 backgroundColor: Colors.grey.shade200,
//                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF7B9A)),
//                 strokeWidth: 6,
//               ),
//               SizedBox(height: 20),
//               Text(
//                 '${(progress * 100).toInt()}% Complete',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 '$completedTasks of $totalTasks tasks completed',
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'Close',
//                 style: TextStyle(color: Color(0xFFFF7B9A)),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
//
// class TimelineItem {
//   final String timeframe;
//   final IconData icon;
//   final List<String> tasks;
//   final Color color;
//
//   TimelineItem({
//     required this.timeframe,
//     required this.icon,
//     required this.tasks,
//     required this.color,
//   });
// }