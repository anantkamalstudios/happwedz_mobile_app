import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/core.dart';
import '../core/config/api_config.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class WeddingTimelinePage extends StatefulWidget {
  const WeddingTimelinePage({super.key});

  @override
  State<WeddingTimelinePage> createState() => _WeddingTimelinePageState();
}

class _WeddingTimelinePageState extends State<WeddingTimelinePage>
    with TickerProviderStateMixin {
  // ---- Config ----
  final String baseUrl = ApiConfig.apiBase;

  // Dates
  DateTime? startDate;
  DateTime? weddingDate;

  // Auth + user
  String? _authToken;
  String? _userId; // stored as string for URI use

  // Cards animation controllers
  late final AnimationController _cardController1;
  late final AnimationController _cardController2;
  late final AnimationController _cardController3;
  late final AnimationController _daysController;

  // Animations
  late final Animation<Offset> _slide1;
  late final Animation<double> _fade1;
  late final Animation<Offset> _slide2;
  late final Animation<double> _fade2;
  late final Animation<Offset> _slide3;
  late final Animation<double> _fade3;
  late final Animation<double> _scaleDays;

  // Checklist state
  final List<_TaskItem> _tasks = [];
  final _taskController = TextEditingController();

  // Vendor subcategories from API
  final List<_VendorSubcategory> _subcategories = [];
  String _selectedCategory = '';

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();



  @override
  void initState() {
    super.initState();
    loadWeddingDate();



    // controllers: short stagger
    _cardController1 =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _cardController2 =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _cardController3 =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    _daysController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _fade1 = CurvedAnimation(parent: _cardController1, curve: Curves.easeOut);
    _slide1 = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade1);

    _fade2 = CurvedAnimation(parent: _cardController2, curve: Curves.easeOut);
    _slide2 = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade2);

    _fade3 = CurvedAnimation(parent: _cardController3, curve: Curves.easeOut);
    _slide3 = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade3);

    _scaleDays = CurvedAnimation(parent: _daysController, curve: Curves.elasticOut);

    // start sequence
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _cardController1.forward();
      await _cardController2.forward();
      await _daysController.forward();
      await _cardController3.forward();
    });

    // load auth/user from SharedPreferences and then remote data
    _loadAuthAndData();
  }

  Future<void> _loadAuthAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('user_id');
    final token = prefs.getString('auth_token');

    if (uid != null) {
      _userId = uid.toString();
      debugPrint('🔐 Loaded user_id from prefs: $_userId');
    } else {
      debugPrint('⚠️ No user_id found in SharedPreferences (key: user_id)');
    }

    if (token != null && token.isNotEmpty) {
      _authToken = token;
      debugPrint('🔐 Loaded auth_token (length ${token.length}) from prefs');
    } else {
      debugPrint('⚠️ No auth_token found in SharedPreferences (key: auth_token)');
    }

    // fetch categories and checklist (they will gracefully handle missing token/user)
    await _fetchCategories();
    await _fetchChecklist();
  }

  Future<void> loadWeddingDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString('wedding_date');

    setState(() {
      weddingDate = dateStr != null ? DateTime.parse(dateStr) : null;
    });
  }



  // Helper to provide headers (include token if available)
  Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Calculate days difference between startDate and weddingDate
  int get _differenceDays {
    if (startDate == null || weddingDate == null) return 0;
    return weddingDate!.difference(startDate!).inDays;
  }

  int get _completedCount => _tasks.where((t) => t.done).length;
  int get _totalCount => _tasks.length;
  double get _progress => _totalCount == 0 ? 0.0 : _completedCount / _totalCount;





  /// ✅ Total days between start & wedding
  int get _totalDays {
    if (startDate == null || weddingDate == null) return 0;
    final diff = weddingDate!.difference(startDate!).inDays;
    return diff > 0 ? diff : 0;
  }

  /// ✅ Days per task (USER-CREATED TASKS ONLY)
  int get _daysPerTask {
    if (_tasks.isEmpty) return 0;
    if (_totalDays == 0) return 0;

    return (_totalDays / _tasks.length).floor();
  }


  /// 🔹 Distributed task data (same as React distributedTasks)
  List<_DistributedTask> get _distributedTasks {
    if (startDate == null || weddingDate == null || _tasks.isEmpty) return [];

    final List<_DistributedTask> result = [];
    final perTaskDays = _daysPerTask <= 0 ? 1 : _daysPerTask;

    DateTime currentDate = startDate!;

    for (final task in _tasks) {
      final start = currentDate;
      final end = currentDate.add(Duration(days: perTaskDays - 1));

      result.add(
        _DistributedTask(
          task: task,
          days: perTaskDays,
          start: start,
          end: end,
        ),
      );

      currentDate = currentDate.add(Duration(days: perTaskDays));
    }

    return result;
  }
















  // ---------------- API CALLS ----------------

  // Fetch vendor types + subcategories -> flatten to subcategories list
  Future<void> _fetchCategories() async {
    try {
      final uri = Uri.parse("${ApiConfig.apiBase}/vendor-types/with-subcategories/all");
      debugPrint('📡 GET categories -> $uri');

      final res = await http.get(uri, headers: _headers());

      debugPrint('GET categories response status: ${res.statusCode}');
      // AUDIT FIX (security): response bodies carry user data and are readable
      // via `adb logcat` in a release build — debug only.
      if (kDebugMode) debugPrint('GET categories response body: ${res.body}');

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);

        _subcategories.clear();

        for (final item in data) {
          final List subs = item["subcategories"] ?? [];

          for (final s in subs) {
            _subcategories.add(
              _VendorSubcategory(
                id: s["id"].toString(),
                name: s["name"].toString(),
              ),
            );
          }
        }

        if (!mounted) return;
        setState(() {
          if (_subcategories.isNotEmpty) {
            _selectedCategory = _subcategories.first.id;
          }
        });
      } else {
        debugPrint("❌ Category fetch failed ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Category fetch error: $e");
    }
  }


  // Fetch checklist for the user
  Future<void> _fetchChecklist() async {
    try {
      debugPrint("🔎 Fetching checklist…");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("auth_token") ?? "";
      final userId = prefs.getInt("user_id");

      debugPrint("🔐 Loaded user_id: $userId");
      debugPrint("🔐 Token length: ${token.length}");

      if (userId == null) {
        debugPrint("❌ No user ID found");
        return;
      }

      final url = "$baseUrl/new-checklist/newChecklist/user/$userId";
      debugPrint("📡 GET → $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("✅ GET status: ${response.statusCode}");
      if (kDebugMode) debugPrint("📦 GET body: ${response.body}");

      if (response.statusCode != 200) {
        debugPrint("❌ Failed GET checklist");
        return;
      }

      final body = json.decode(response.body);
      final list = body["data"] ?? [];

      _tasks.clear();

      for (final item in list) {
        final text = item["text"]?.toString() ?? "";
        final status = item["status"]?.toString() ?? "";
        final subId = item["vendor_subcategory_id"]?.toString() ?? "";

        // find category name based on vendor_subcategory_id
        String categoryName = "Unknown";
        for (final s in _subcategories) {
          if (s.id == subId) {
            categoryName = s.name;
            break;
          }
        }

        _tasks.add(
          _TaskItem(
            id: item["id"].toString(), // 🔥 REQUIRED
            title: text,
            category: categoryName,
            done: status == "completed",
          ),
        );

      }

      debugPrint("✅ Loaded tasks count: ${_tasks.length}");

      // Guarded: the user can leave the checklist while the request runs.
      if (!mounted) return;
      setState(() {});

    } catch (e) {
      debugPrint("❌ Checklist fetch error: $e");
    }
  }


  // Helper: format DateTime to yyyy-MM-dd (API expects this)
  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "$y-$m-$dd";
  }

  Future<void> saveUserSession(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setInt('user_id', userId);
    debugPrint("✅ Token saved: $token");
    debugPrint("✅ UserID saved: $userId");
  }



  // POST create new checklist
  Future<bool> _createChecklistOnServer({
    required String text,
    required String startDateString,
    required String weddingDateString,
    required String vendorSubcategoryId,
  }) async {
    try {
      if (_userId == null) {
        debugPrint('❌ Cannot create checklist: userId null');
        return false;
      }

      final body = {
        "start_date": startDateString,
        "wedding_date": weddingDateString,
        "status": "pending",
        "text": text,
        "user_id": _userId!,
        "vendor_subcategory_id": vendorSubcategoryId,
      };


      debugPrint("📤 POST BODY → ${json.encode(body)}");

      final uri = Uri.parse("$baseUrl/new-checklist/create");
      final res = await http.post(
        uri,
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: json.encode(body),
      );


      debugPrint("✅ CREATE RESPONSE status: ${res.statusCode}");
      if (kDebugMode) debugPrint("✅ CREATE RESPONSE body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Create checklist error: $e");
      return false;
    }
  }

  // ---------------- UI / Task logic (preserve original design) ----------------

  // Add a new task (animated insert + POST to server)
  void _addTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) {
      AppSnackbar.warning(context, 'Please enter a task name.');
      return;
    }
    if (startDate == null || weddingDate == null) {
      AppSnackbar.warning(context, 'Please select both dates.');
      return;
    }
    if (_selectedCategory.isEmpty) {
      AppSnackbar.warning(context, 'Please select a category.');
      return;
    }

    final start = _fmtDate(startDate!);
    final wed = _fmtDate(weddingDate!);
    final vendorSubId = _selectedCategory;

    // Optimistically insert task locally
    final sub = _subcategories.firstWhere(
          (s) => s.id == vendorSubId,
      orElse: () => _VendorSubcategory(id: vendorSubId, name: vendorSubId),
    );

    final task = _TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      category: sub.name,
    );
    setState(() {
      _tasks.insert(0, task);
      _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 450));
    });

    // Clear input
    _taskController.clear();

    // Show feedback: "Adding task..."
    AppSnackbar.info(context, 'Adding task…');

    // Post to server
    final ok = await _createChecklistOnServer(
      text: text,
      startDateString: start,
      weddingDateString: wed,
      vendorSubcategoryId: vendorSubId,
    );

    if (ok) {
      AppSnackbar.success(context, 'Task added to your checklist.');
      await _fetchChecklist(); // refresh tasks from server
    } else {
      // Remove optimistic insert if failed
      final idx = _tasks.indexWhere((t) => t.title == text && t.category == sub.name);
      if (idx != -1) {
        final removed = _tasks.removeAt(idx);
        _listKey.currentState?.removeItem(
          idx,
              (context, animation) => SizeTransition(
            sizeFactor: animation,
            axis: Axis.vertical,
            child: _buildTaskTile(removed, idx, anim: animation),
          ),
          duration: const Duration(milliseconds: 380),
        );
      }
      AppSnackbar.error(context, "We couldn't add that task. Please try again.");
    }
  }


  // Toggle done
  void _toggleDone(int index) {
    setState(() {
      _tasks[index].done = !_tasks[index].done;
    });
    debugPrint('✅ Task toggled: ${_tasks[index].title} -> ${_tasks[index].done}');
  }
  Future<bool> _deleteChecklistOnServer(String taskId) async {
    try {
      final uri = Uri.parse("$baseUrl/new-checklist/delete/$taskId");

      final res = await http.delete(
        uri,
        headers: _headers(),
      );

      debugPrint("🗑️ DELETE status: ${res.statusCode}");
      if (kDebugMode) debugPrint("🗑️ DELETE body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint("❌ Delete checklist error: $e");
      return false;
    }
  }


  // Remove task
  void _removeTask(int index) async {
    final removed = _tasks[index];

    // Optimistic UI remove
    setState(() {
      _tasks.removeAt(index);
    });

    _listKey.currentState?.removeItem(
      index,
          (context, animation) => SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        child: _buildTaskTile(removed, index, anim: animation),
      ),
      duration: const Duration(milliseconds: 380),
    );

    debugPrint('🗑️ Task removed locally: ${removed.title}');

    // 🔥 DELETE FROM BACKEND
    final ok = await _deleteChecklistOnServer(removed.id);

    if (!ok) {
      // rollback if API fails
      setState(() {
        _tasks.insert(index, removed);
        _listKey.currentState?.insertItem(index);
      });

      AppSnackbar.error(context, "We couldn't delete that task. Please try again.");
    }
  }

  // Date pickers with prints
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => startDate = picked);
      debugPrint('📅 Start Date set: $picked');
      // animate days box re-bounce
      _daysController.forward(from: 0.0);
    }
  }

  Future<void> _pickWeddingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: weddingDate ?? (startDate ?? DateTime.now()),
      firstDate: startDate ?? DateTime(2020), // ← prevent before start date
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      if (startDate != null && picked.isBefore(startDate!)) {
        // Just in case, extra safeguard
        AppSnackbar.warning(context, 'The wedding date cannot be before the start date.');
        return;
      }

      setState(() => weddingDate = picked);
      debugPrint('💍 Wedding Date set: $picked');
      _daysController.forward(from: 0.0);
    }
  }


  // ---------------- UI BUILDERS ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF69B4), // Hot Pink
              Color(0xFFFFB6C1), // Light Pink
              Colors.white,      // White
            ],
            stops: [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // 🌸 Custom AppBar (same as Budget Screen)
              Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Wedding Checklist',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // for symmetry
                  ],
                ),
              ),

              // 🌸 Body (with your animated cards)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // CARD 1
                      SlideTransition(
                        position: _slide1,
                        child: FadeTransition(
                          opacity: _fade1,
                          child: _taskStatusCard(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CARD 2
                      SlideTransition(
                        position: _slide2,
                        child: FadeTransition(
                          opacity: _fade2,
                          child: _timelineCard(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CARD 3
                      SlideTransition(
                        position: _slide3,
                        child: FadeTransition(
                          opacity: _fade3,
                          child: _checklistCard(),
                        ),
                      ),

                      const SizedBox(height: 100),
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


  // Task status card
  Widget _taskStatusCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // big count and label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${_completedCount}/${_totalCount}', style: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Tasks done', style: TextStyle(color: Colors.black54)),
              ]),
              // small circular icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // progress card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 10,
                    backgroundColor: Colors.pink.shade50,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFE91E63)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_completedCount} completed', style: const TextStyle(fontSize: 12)),
                    Text('${_totalCount} total tasks', style: const TextStyle(fontSize: 12)),
                    Text('${(_progress * 100).round()}% complete', style: const TextStyle(fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
      title: '🕒 TASK STATUS',
    );
  }

  // Timeline card (dates + days)
  Widget _timelineCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📆 Start Date', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _datePickerField(value: startDate, label: 'Select start date', onTap: _pickStartDate),
          const SizedBox(height: 12),
          const Text('💖 Wedding Date', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _datePickerField(value: weddingDate, label: 'Select wedding date', onTap: _pickWeddingDate),
          const SizedBox(height: 18),
          ScaleTransition(scale: _scaleDays, child: _fullWidthDaysBox()),


        ],
      ),
      title: '📅 WEDDING CHECKLIST',
    );
  }

  // Widget _buildTimeAllocationCard() {
  //   // Use startDate and weddingDate from the Wedding Timeline section
  //   if (startDate == null || weddingDate == null) {
  //     return Padding(
  //       padding: const EdgeInsets.only(top: 10),
  //       child: Text(
  //         "Please select both Start and Wedding Dates to view time allocation.",
  //         style: TextStyle(color: Colors.grey[700]),
  //       ),
  //     );
  //   }
  //
  //   final Duration requiredDuration = const Duration(days: 2);
  //   final DateTime endDate = startDate!.add(requiredDuration);
  //   final int bufferDays = weddingDate!.difference(endDate).inDays;
  //
  //   String formatDate(DateTime d) =>
  //       "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  //
  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.only(top: 15),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: const Color(0xFFFFF0F5), // light pink background
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: const Color(0xFFFFC0CB)), // pink border
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           "Time Allocation",
  //           style: TextStyle(
  //             color: Color(0xFFB30059),
  //             fontWeight: FontWeight.bold,
  //             fontSize: 16,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text("• 2 days required",
  //             style: const TextStyle(color: Colors.black87, fontSize: 14)),
  //         Text("• Start: ${formatDate(startDate!)}",
  //             style: const TextStyle(color: Colors.black87, fontSize: 14)),
  //         Text("• End: ${formatDate(endDate)}",
  //             style: const TextStyle(color: Colors.black87, fontSize: 14)),
  //         Text("• Remaining buffer: ${bufferDays} days",
  //             style: const TextStyle(color: Colors.black87, fontSize: 14)),
  //       ],
  //     ),
  //   );
  // }


  // Checklist card (premium)
  Widget _checklistCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== HEADER ROW =====
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Wedding Checklist',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Download Icon Button
              IconButton(
                tooltip: "Download",
                onPressed: () {
                  AppSnackbar.info(context, 'Download started.');
                },
                icon: const Icon(Icons.download_rounded, color: Colors.black87),
              ),

              // Print Icon Button
              IconButton(
                tooltip: "Print",
                onPressed: () {
                  AppSnackbar.info(context, 'Opening the print dialog…');
                },
                icon: const Icon(Icons.print_rounded, color: Colors.black87),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ===== OVERALL PROGRESS =====


        const SizedBox(height: 18),

        // ===== ADD NEW TASK =====
        Container(
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.pink.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade100.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Task',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE91E63),
                ),
              ),


              const SizedBox(height: 12),

              // 🔹 CATEGORY FIRST
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: _subcategories.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Loading categories...', style: TextStyle(fontSize: 13)),
                    ),
                  )
                      : DropdownButton<String>(
                    value: _selectedCategory.isEmpty
                        ? _subcategories.first.id
                        : _selectedCategory,
                    hint: const Text('Category', style: TextStyle(fontSize: 12)),
                    isExpanded: true,
                    items: _subcategories.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedCategory = v);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 TASK INPUT BELOW CATEGORY
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Task name',
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 ADD BUTTON BELOW BOTH
              GestureDetector(
                onTap: _addTask,
                child: Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.shade200.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 REMAINING SAME
              // _buildTimeAllocationCard(),
            ],
          ),
        ),




        // ===== TASK LIST =====
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your Tasks',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              _tasks.isEmpty
                  ? Column(
                children: const [
                  SizedBox(height: 14),
                  Icon(Icons.list_alt, size: 42, color: Colors.pinkAccent),
                  SizedBox(height: 8),
                  Text('No tasks yet — add a task above',
                      style: TextStyle(color: Colors.black54)),
                  SizedBox(height: 12),
                ],
              )
                  : AnimatedList(
                key: _listKey,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                initialItemCount: _tasks.length,
                itemBuilder: (context, index, animation) {
                  final t = _tasks[index];
                  final int daysAssigned = _daysPerTask;

                  return SizeTransition(
                    sizeFactor: animation,
                    axis: Axis.vertical,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB71C5E),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  t.title,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    decoration:
                                    t.done ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => _toggleDone(index),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                    color: t.done
                                        ? Colors.pink.shade50
                                        : Colors.grey.shade100,
                                  ),
                                  child: Icon(
                                    t.done
                                        ? Icons.check
                                        : Icons.radio_button_unchecked,
                                    color:
                                    t.done ? Colors.pink : Colors.grey.shade400,
                                    size: 18,
                                  ),
                                ),
                              ),

                              // ✅ ONLY CALCULATION — NO AUTO TASKS
                              Text(
                                daysAssigned > 0 ? '$daysAssigned days' : '--',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              Row(
                                children: [
                                  _iconCircleButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () => _showEditDialog(index),
                                  ),
                                  const SizedBox(width: 8),
                                  _iconCircleButton(
                                    icon: Icons.delete_outline,
                                    onTap: () => _confirmDelete(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },


              ),
            ],
          ),
        ),

        const SizedBox(height: 22),
      ],
    );
  }



  // ---------- REFINED TASK TILE ----------
  Widget _buildTaskTile(_TaskItem task, int index, {Animation<double>? anim}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.pink.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.shade100.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Checkbox(
              value: task.done,
              onChanged: (_) => _toggleDone(index),
              activeColor: const Color(0xFFE91E63),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? Colors.black54 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.category,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black38),
              onPressed: () => _removeTask(index),
            ),
          ],
        ),
      ),
    );
  }


  // small circular icon button used in row
  Widget _iconCircleButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.white,
        ),
        child: Icon(icon, size: 16, color: Colors.black54),
      ),
    );
  }

// Edit dialog to rename a task (updates local model)
  void _showEditDialog(int index) {
    final t = _tasks[index];
    final controller = TextEditingController(text: t.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit task'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Task name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                setState(() {
                  t.title = newText;
                });
                // optionally: send update to server here if API exists
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

// Confirm delete dialog (reuses your _removeTask function)
  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This will remove the task from your checklist.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeTask(index);
              // optionally: call server delete if available
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }


  // full width days box (difference of start and weddinwedding dates)
  Widget _fullWidthDaysBox() {
    String message = 'Select both dates';
    int days = 0;
    if (startDate != null && weddingDate != null) {
      days = weddingDate!.difference(startDate!).inDays;
      if (days >= 0) {
        message = 'Days until wedding';
      } else {
        days = days.abs();
        message = 'Days since wedding';
      }
    }

    debugPrint('📏 Days difference computed: $days ($message)');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Text('$days', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // small reusable card wrapper with gradient header (keeps existing look)
  Widget _cardWrapper({required Widget child, required String title}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 6))]),
      child: Column(
        children: [
          // header gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF06292)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  // date picker small field
  Widget _datePickerField({DateTime? value, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(value == null ? label : '${value.day}/${value.month}/${value.year}', style: const TextStyle(color: Colors.black87)),
          const Icon(Icons.calendar_month, color: Colors.grey),
        ]),
      ),
    );
  }
}

// simple model for task item
class _TaskItem {
  final String id;
  String title;
  String category;
  bool done;

  _TaskItem({    required this.id,
    required this.title, required this.category, this.done = false});
}

// vendor subcategory model
class _VendorSubcategory {
  final String id;
  final String name;

  _VendorSubcategory({required this.id, required this.name});
}


class _DistributedTask {
  final _TaskItem task;
  final int days;
  final DateTime start;
  final DateTime end;

  _DistributedTask({
    required this.task,
    required this.days,
    required this.start,
    required this.end,
  });
}




// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
//
// class WeddingTimelinePage extends StatefulWidget {
//   const WeddingTimelinePage({super.key});
//
//   @override
//   State<WeddingTimelinePage> createState() => _WeddingTimelinePageState();
// }
//
// class _WeddingTimelinePageState extends State<WeddingTimelinePage>
//     with TickerProviderStateMixin {
//   // ---- Config ----
//   final String baseUrl = "https://happywedz.com/api";
//
//   // Dates
//   DateTime? startDate;
//   DateTime? weddingDate;
//
//   // Auth + user
//   String? _authToken;
//   String? _userId; // stored as string for URI use
//
//   // Cards animation controllers
//   late final AnimationController _cardController1;
//   late final AnimationController _cardController2;
//   late final AnimationController _cardController3;
//   late final AnimationController _daysController;
//
//   // Animations
//   late final Animation<Offset> _slide1;
//   late final Animation<double> _fade1;
//   late final Animation<Offset> _slide2;
//   late final Animation<double> _fade2;
//   late final Animation<Offset> _slide3;
//   late final Animation<double> _fade3;
//   late final Animation<double> _scaleDays;
//
//   // Checklist state
//   final List<_TaskItem> _tasks = [];
//   final _taskController = TextEditingController();
//
//   // Vendor subcategories from API
//   final List<_VendorSubcategory> _subcategories = [];
//   String _selectedCategory = '';
//
//   final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
//
//   @override
//   void initState() {
//     super.initState();
//     loadWeddingDate();
//
//     // controllers: short stagger
//     _cardController1 =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
//     _cardController2 =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
//     _cardController3 =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
//     _daysController =
//         AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
//
//     _fade1 = CurvedAnimation(parent: _cardController1, curve: Curves.easeOut);
//     _slide1 = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade1);
//
//     _fade2 = CurvedAnimation(parent: _cardController2, curve: Curves.easeOut);
//     _slide2 = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade2);
//
//     _fade3 = CurvedAnimation(parent: _cardController3, curve: Curves.easeOut);
//     _slide3 = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade3);
//
//     _scaleDays = CurvedAnimation(parent: _daysController, curve: Curves.elasticOut);
//
//     // start sequence
//     SchedulerBinding.instance.addPostFrameCallback((_) async {
//       await _cardController1.forward();
//       await _cardController2.forward();
//       await _daysController.forward();
//       await _cardController3.forward();
//     });
//
//     // load auth/user from SharedPreferences and then remote data
//     _loadAuthAndData();
//   }
//
//   @override
//   void dispose() {
//     _cardController1.dispose();
//     _cardController2.dispose();
//     _cardController3.dispose();
//     _daysController.dispose();
//     _taskController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadAuthAndData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final uid = prefs.getInt('user_id');
//     final token = prefs.getString('auth_token');
//
//     if (uid != null) {
//       _userId = uid.toString();
//       print('🔐 Loaded user_id from prefs: $_userId');
//     } else {
//       print('⚠️ No user_id found in SharedPreferences (key: user_id)');
//     }
//
//     if (token != null && token.isNotEmpty) {
//       _authToken = token;
//       print('🔐 Loaded auth_token (length ${token.length}) from prefs');
//     } else {
//       print('⚠️ No auth_token found in SharedPreferences (key: auth_token)');
//     }
//
//     // fetch categories and checklist (they will gracefully handle missing token/user)
//     await _fetchCategories();
//     await _fetchChecklist();
//   }
//
//   Future<void> loadWeddingDate() async {
//     final prefs = await SharedPreferences.getInstance();
//     final dateStr = prefs.getString('wedding_date');
//
//     setState(() {
//       weddingDate = dateStr != null ? DateTime.parse(dateStr) : null;
//     });
//   }
//
//   // Helper to provide headers (include token if available)
//   Map<String, String> _headers() {
//     final headers = <String, String>{'Accept': 'application/json'};
//     if (_authToken != null && _authToken!.isNotEmpty) {
//       headers['Authorization'] = 'Bearer $_authToken';
//     }
//     return headers;
//   }
//
//   // Calculate total planning days (start -> wedding)
//   int get totalPlanningDays {
//     if (startDate == null || weddingDate == null) return 0;
//     return weddingDate!.difference(startDate!).inDays;
//   }
//
//   /// Distributes planning days equally across tasks
//   List<int> get perTaskDurations {
//     final int total = totalPlanningDays;
//     final int n = _tasks.length;
//
//     if (total <= 0 || n == 0) return [];
//
//     final int base = total ~/ n;
//     final int remainder = total % n;
//
//     return List<int>.generate(n, (i) => base + (i < remainder ? 1 : 0));
//   }
//
//   int get _completedCount => _tasks.where((t) => t.done).length;
//   int get _totalCount => _tasks.length;
//   double get _progress => _totalCount == 0 ? 0.0 : _completedCount / _totalCount;
//
//   // ---------------- API CALLS ----------------
//
//   // Fetch vendor types + subcategories -> flatten to subcategories list
//   Future<void> _fetchCategories() async {
//     try {
//       final uri = Uri.parse("https://happywedz.com/api/vendor-types/with-subcategories/all");
//       print('📡 GET categories -> $uri');
//
//       final res = await http.get(uri, headers: _headers());
//
//       print('GET categories response status: ${res.statusCode}');
//       print('GET categories response body: ${res.body}');
//
//       if (res.statusCode == 200) {
//         final List data = json.decode(res.body);
//
//         _subcategories.clear();
//
//         for (final item in data) {
//           final List subs = item["subcategories"] ?? [];
//
//           for (final s in subs) {
//             _subcategories.add(
//               _VendorSubcategory(
//                 id: s["id"].toString(),
//                 name: s["name"].toString(),
//               ),
//             );
//           }
//         }
//
//         setState(() {
//           if (_subcategories.isNotEmpty) {
//             _selectedCategory = _subcategories.first.id;
//           }
//         });
//       } else {
//         print("❌ Category fetch failed ${res.statusCode}");
//       }
//     } catch (e) {
//       print("❌ Category fetch error: $e");
//     }
//   }
//
//   // Fetch checklist for the user
//   Future<void> _fetchChecklist() async {
//     try {
//       print("🔎 Fetching checklist…");
//
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("auth_token") ?? "";
//       final userId = prefs.getInt("user_id");
//
//       print("🔐 Loaded user_id: $userId");
//       print("🔐 Token length: ${token.length}");
//
//       if (userId == null) {
//         print("❌ No user ID found");
//         return;
//       }
//
//       final url = "$baseUrl/new-checklist/newChecklist/user/$userId";
//       print("📡 GET → $url");
//
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         },
//       );
//
//       print("✅ GET status: ${response.statusCode}");
//       print("📦 GET body: ${response.body}");
//
//       if (response.statusCode != 200) {
//         print("❌ Failed GET checklist");
//         return;
//       }
//
//       final body = json.decode(response.body);
//       final list = body["data"] ?? [];
//
//       _tasks.clear();
//
//       for (final item in list) {
//         final text = item["text"]?.toString() ?? "";
//         final status = item["status"]?.toString() ?? "";
//         final subId = item["vendor_subcategory_id"]?.toString() ?? "";
//
//         // find category name based on vendor_subcategory_id
//         String categoryName = "Unknown";
//         for (final s in _subcategories) {
//           if (s.id == subId) {
//             categoryName = s.name;
//             break;
//           }
//         }
//
//         _tasks.add(
//           _TaskItem(
//             title: text,
//             category: categoryName,
//             done: status == "completed",
//           ),
//         );
//       }
//
//       print("✅ Loaded tasks count: ${_tasks.length}");
//
//       setState(() {});
//     } catch (e) {
//       print("❌ Checklist fetch error: $e");
//     }
//   }
//
//   // Helper: format DateTime to yyyy-MM-dd (API expects this)
//   String _fmtDate(DateTime d) {
//     final y = d.year.toString().padLeft(4, '0');
//     final m = d.month.toString().padLeft(2, '0');
//     final dd = d.day.toString().padLeft(2, '0');
//     return "$y-$m-$dd";
//   }
//
//   Future<void> saveUserSession(String token, int userId) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('auth_token', token);
//     await prefs.setInt('user_id', userId);
//     print("✅ Token saved: $token");
//     print("✅ UserID saved: $userId");
//   }
//
//   // POST create new checklist
//   Future<bool> _createChecklistOnServer({
//     required String text,
//     required String startDateString,
//     required String weddingDateString,
//     required String vendorSubcategoryId,
//   }) async {
//     try {
//       if (_userId == null) {
//         print('❌ Cannot create checklist: userId null');
//         return false;
//       }
//
//       final body = {
//         "start_date": startDateString,
//         "wedding_date": weddingDateString,
//         "status": "pending",
//         "text": text,
//         "user_id": _userId!,
//         "vendor_subcategory_id": vendorSubcategoryId,
//       };
//
//       print("📤 POST BODY → ${json.encode(body)}");
//
//       final uri = Uri.parse("$baseUrl/new-checklist/create");
//       final res = await http.post(
//         uri,
//         headers: {..._headers(), 'Content-Type': 'application/json'},
//         body: json.encode(body),
//       );
//
//       print("✅ CREATE RESPONSE status: ${res.statusCode}");
//       print("✅ CREATE RESPONSE body: ${res.body}");
//
//       return res.statusCode == 200 || res.statusCode == 201;
//     } catch (e) {
//       print("❌ Create checklist error: $e");
//       return false;
//     }
//   }
//
//   // ---------------- UI / Task logic (preserve original design) ----------------
//
//   // Add a new task (animated insert + POST to server)
//   void _addTask() async {
//     final text = _taskController.text.trim();
//     if (text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter task name')),
//       );
//       return;
//     }
//     if (startDate == null || weddingDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select dates')),
//       );
//       return;
//     }
//     if (_selectedCategory.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select category')),
//       );
//       return;
//     }
//
//     final start = _fmtDate(startDate!);
//     final wed = _fmtDate(weddingDate!);
//     final vendorSubId = _selectedCategory;
//
//     // Optimistically insert task locally
//     final sub = _subcategories.firstWhere(
//           (s) => s.id == vendorSubId,
//       orElse: () => _VendorSubcategory(id: vendorSubId, name: vendorSubId),
//     );
//
//     final task = _TaskItem(title: text, category: sub.name);
//     setState(() {
//       _tasks.insert(0, task);
//       _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 450));
//     });
//
//     // Clear input
//     _taskController.clear();
//
//     // Show feedback: "Adding task..."
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Adding task...'),
//         duration: Duration(seconds: 1),
//       ),
//     );
//
//     // Post to server
//     final ok = await _createChecklistOnServer(
//       text: text,
//       startDateString: start,
//       weddingDateString: wed,
//       vendorSubcategoryId: vendorSubId,
//     );
//
//     if (ok) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Task added successfully!'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       await _fetchChecklist(); // refresh tasks from server
//     } else {
//       // Remove optimistic insert if failed
//       final idx = _tasks.indexWhere((t) => t.title == text && t.category == sub.name);
//       if (idx != -1) {
//         final removed = _tasks.removeAt(idx);
//         _listKey.currentState?.removeItem(
//           idx,
//               (context, animation) => SizeTransition(
//             sizeFactor: animation,
//             axis: Axis.vertical,
//             child: _buildTaskTile(removed, idx, anim: animation),
//           ),
//           duration: const Duration(milliseconds: 380),
//         );
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Failed to add task! Please try again.'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//     }
//   }
//
//   // Toggle done
//   void _toggleDone(int index) {
//     setState(() {
//       _tasks[index].done = !_tasks[index].done;
//     });
//     print('✅ Task toggled: ${_tasks[index].title} -> ${_tasks[index].done}');
//   }
//
//   // Remove task
//   void _removeTask(int index) {
//     final removed = _tasks.removeAt(index);
//     _listKey.currentState?.removeItem(index, (context, animation) {
//       return SizeTransition(
//         sizeFactor: animation,
//         axis: Axis.vertical,
//         child: _buildTaskTile(removed, index, anim: animation),
//       );
//     }, duration: const Duration(milliseconds: 380));
//     print('🗑️ Task removed: ${removed.title}');
//   }
//
//   // Date pickers with prints
//   Future<void> _pickStartDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: startDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2035),
//       builder: (context, child) => Theme(
//         data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63))),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       setState(() => startDate = picked);
//       print('📅 Start Date set: $picked');
//       // animate days box re-bounce
//       _daysController.forward(from: 0.0);
//     }
//   }
//
//   Future<void> _pickWeddingDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: weddingDate ?? (startDate ?? DateTime.now()),
//       firstDate: startDate ?? DateTime(2020), // ← prevent before start date
//       lastDate: DateTime(2035),
//       builder: (context, child) => Theme(
//         data: ThemeData.light().copyWith(
//           colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63)),
//         ),
//         child: child!,
//       ),
//     );
//
//     if (picked != null) {
//       if (startDate != null && picked.isBefore(startDate!)) {
//         // Just in case, extra safeguard
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Wedding date cannot be before start date')),
//         );
//         return;
//       }
//
//       setState(() => weddingDate = picked);
//       print('💍 Wedding Date set: $picked');
//       _daysController.forward(from: 0.0);
//     }
//   }
//
//   // ---------------- UI BUILDERS ----------------
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
//               Colors.white, // White
//             ],
//             stops: [0.0, 0.3, 0.6],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // 🌸 Custom AppBar (same as Budget Screen)
//               Container(
//                 color: Colors.transparent,
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back, color: Colors.white),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const Text(
//                       'Wedding Checklist',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 48), // for symmetry
//                   ],
//                 ),
//               ),
//
//               // 🌸 Body (with your animated cards)
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // CARD 1
//                       SlideTransition(
//                         position: _slide1,
//                         child: FadeTransition(
//                           opacity: _fade1,
//                           child: _taskStatusCard(),
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // CARD 2
//                       SlideTransition(
//                         position: _slide2,
//                         child: FadeTransition(
//                           opacity: _fade2,
//                           child: _timelineCard(),
//                         ),
//                       ),
//
//                       const SizedBox(height: 20),
//
//                       // CARD 3
//                       SlideTransition(
//                         position: _slide3,
//                         child: FadeTransition(
//                           opacity: _fade3,
//                           child: _checklistCard(),
//                         ),
//                       ),
//
//                       const SizedBox(height: 100),
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
//   // Task status card
//   Widget _taskStatusCard() {
//     return _cardWrapper(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // big count and label
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text('${_completedCount}/${_totalCount}', style: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 4),
//                 const Text('Tasks done', style: TextStyle(color: Colors.black54)),
//               ]),
//               // small circular icon
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
//                 child: const Icon(Icons.check, color: Colors.white),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // progress card
//           Container(
//             padding: const EdgeInsets.all(14),
//             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600)),
//                 const SizedBox(height: 8),
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: LinearProgressIndicator(
//                     value: _progress,
//                     minHeight: 10,
//                     backgroundColor: Colors.pink.shade50,
//                     valueColor: const AlwaysStoppedAnimation(Color(0xFFE91E63)),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text('${_completedCount} completed', style: const TextStyle(fontSize: 12)),
//                     Text('${_totalCount} total tasks', style: const TextStyle(fontSize: 12)),
//                     Text('${(_progress * 100).round()}% complete', style: const TextStyle(fontSize: 12)),
//                   ],
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//       title: '🕒 TASK STATUS',
//     );
//   }
//
//   // Timeline card (dates + days)
//   Widget _timelineCard() {
//     return _cardWrapper(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('📆 Start Date', style: TextStyle(fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//           _datePickerField(value: startDate, label: 'Select start date', onTap: _pickStartDate),
//           const SizedBox(height: 12),
//           const Text('💖 Wedding Date', style: TextStyle(fontWeight: FontWeight.w600)),
//           const SizedBox(height: 8),
//           _datePickerField(value: weddingDate, label: 'Select wedding date', onTap: _pickWeddingDate),
//           const SizedBox(height: 18),
//           ScaleTransition(scale: _scaleDays, child: _fullWidthDaysBox()),
//         ],
//       ),
//       title: '📅 WEDDING CHECKLIST',
//     );
//   }
//
//   Widget _buildTimeAllocationCard() {
//     if (startDate == null || weddingDate == null) {
//       return Padding(
//         padding: const EdgeInsets.only(top: 10),
//         child: Text(
//           "Select start & wedding dates to calculate planning days.",
//           style: TextStyle(color: Colors.grey[700]),
//         ),
//       );
//     }
//
//     final int total = totalPlanningDays;
//
//     if (_tasks.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.only(top: 10),
//         child: Text(
//           "Add tasks to distribute planning days.",
//           style: TextStyle(color: Colors.grey[700]),
//         ),
//       );
//     }
//
//     final durations = perTaskDurations;
//
//     return Container(
//       padding: const EdgeInsets.all(16),
//       margin: const EdgeInsets.only(top: 12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: const Color(0xFFFFF0F5),
//         border: Border.all(color: Colors.pink.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "Time Allocation Summary",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFFE91E63),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text("Total Planning Days: $total"),
//           Text("Total Tasks: ${_tasks.length}"),
//           Text("Base Days Per Task: ${durations.first}"),
//           Text("Some tasks get +1 day for fair distribution"),
//         ],
//       ),
//     );
//   }
//
//   // Checklist card (premium)
//   Widget _checklistCard() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.stretch,
//       children: [
//         // ===== HEADER ROW =====
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             children: [
//               const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 22),
//               const SizedBox(width: 8),
//               const Expanded(
//                 child: Text(
//                   'Wedding Checklist',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black87,
//                   ),
//                 ),
//               ),
//
//               // Download Icon Button
//               IconButton(
//                 tooltip: "Download",
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Download started')),
//                   );
//                 },
//                 icon: const Icon(Icons.download_rounded, color: Colors.black87),
//               ),
//
//               // Print Icon Button
//               IconButton(
//                 tooltip: "Print",
//                 onPressed: () {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Print dialog opened')),
//                   );
//                 },
//                 icon: const Icon(Icons.print_rounded, color: Colors.black87),
//               ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 10),
//
//         // ===== ADD NEW TASK =====
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.pink.shade50,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: Colors.pink.shade100),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.pink.shade100.withValues(alpha: 0.3),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Add New Task',
//                 style: TextStyle(
//                   fontSize: 15,
//                   fontWeight: FontWeight.w700,
//                   color: Color(0xFFE91E63),
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               // 🔹 CATEGORY FIRST
//               Container(
//                 height: 44,
//                 padding: const EdgeInsets.symmetric(horizontal: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: DropdownButtonHideUnderline(
//                   child: _subcategories.isEmpty
//                       ? const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text('Loading categories...', style: TextStyle(fontSize: 13)),
//                     ),
//                   )
//                       : DropdownButton<String>(
//                     value: _selectedCategory.isEmpty ? _subcategories.first.id : _selectedCategory,
//                     hint: const Text('Category', style: TextStyle(fontSize: 12)),
//                     isExpanded: true,
//                     items: _subcategories.map((s) {
//                       return DropdownMenuItem(value: s.id, child: Text(s.name));
//                     }).toList(),
//                     onChanged: (v) {
//                       if (v != null) {
//                         setState(() => _selectedCategory = v);
//                       }
//                     },
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               // 🔹 TASK INPUT BELOW CATEGORY
//               Container(
//                 height: 44,
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade200),
//                 ),
//                 child: Center(
//                   child: TextField(
//                     controller: _taskController,
//                     decoration: const InputDecoration.collapsed(
//                       hintText: 'Task name',
//                     ),
//                     style: const TextStyle(fontSize: 13),
//                     onSubmitted: (_) => _addTask(),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 12),
//
//               // 🔹 ADD BUTTON BELOW BOTH
//               GestureDetector(
//                 onTap: _addTask,
//                 child: Container(
//                   height: 44,
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFFE91E63), Color(0xFFF06292)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.pink.shade200.withValues(alpha: 0.35),
//                         blurRadius: 8,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: const Center(
//                     child: Icon(Icons.add, color: Colors.white, size: 24),
//                   ),
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               // 🔹 TIME ALLOCATION + GANTT BELOW
//               // show both summary and gantt together
//               _buildTimeAllocationCard(),
//               const SizedBox(height: 12),
//               _buildGanttTimeline(),
//             ],
//           ),
//         ),
//
//         // ===== TASK LIST =====
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(14),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withValues(alpha: 0.04),
//                 blurRadius: 8,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           padding: const EdgeInsets.all(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Your Tasks', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
//               const SizedBox(height: 10),
//               _tasks.isEmpty
//                   ? Column(
//                 children: const [
//                   SizedBox(height: 14),
//                   Icon(Icons.list_alt, size: 42, color: Colors.pinkAccent),
//                   SizedBox(height: 8),
//                   Text('No tasks yet — add a task above', style: TextStyle(color: Colors.black54)),
//                   SizedBox(height: 12),
//                 ],
//               )
//                   : AnimatedList(
//                 key: _listKey,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 initialItemCount: _tasks.length,
//                 itemBuilder: (context, index, animation) {
//                   final t = _tasks[index];
//
//                   // compute fair per-task days (same logic used in Gantt)
//                   final int tpd = totalPlanningDays;
//                   final int n = _tasks.length;
//                   final int base = tpd ~/ n;
//                   final int remainder = tpd % n;
//                   final int perTaskDays = base + (index < remainder ? 1 : 0);
//
//
//                   return SizeTransition(
//                     sizeFactor: animation,
//                     axis: Axis.vertical,
//                     child: Container(
//                       padding: const EdgeInsets.all(14),
//                       margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withValues(alpha: 0.05),
//                             blurRadius: 6,
//                             offset: const Offset(0, 3),
//                           )
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // -------- Row 1: Category + Task --------
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 t.category,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Color(0xFFB71C5E),
//                                 ),
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   t.title,
//                                   textAlign: TextAlign.right,
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.w600,
//                                     color: Colors.black87,
//                                     decoration: t.done ? TextDecoration.lineThrough : null,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//
//                           const SizedBox(height: 10),
//
//                           // -------- Row 2: Status + Days + Actions --------
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               // Status toggle circle
//                               GestureDetector(
//                                 onTap: () => _toggleDone(index),
//                                 child: Container(
//                                   width: 34,
//                                   height: 34,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     border: Border.all(color: Colors.grey.shade300),
//                                     color: t.done ? Colors.pink.shade50 : Colors.grey.shade100,
//                                   ),
//                                   child: Icon(
//                                     t.done ? Icons.check : Icons.radio_button_unchecked,
//                                     color: t.done ? Colors.pink : Colors.grey.shade400,
//                                     size: 18,
//                                   ),
//                                 ),
//                               ),
//
//                               // Days assigned (fair distribution)
//                               Text(
//                                 '$perTaskDays days',
//                                 style: const TextStyle(
//                                   color: Colors.grey,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//
//                               // Actions: edit + delete
//                               Row(
//                                 children: [
//                                   _iconCircleButton(
//                                     icon: Icons.edit_outlined,
//                                     onTap: () => _showEditDialog(index),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   _iconCircleButton(
//                                     icon: Icons.delete_outline,
//                                     onTap: () => _confirmDelete(index),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//
//         const SizedBox(height: 22),
//       ],
//     );
//   }
//
//   // ---------- REFINED TASK TILE ----------
//   Widget _buildTaskTile(_TaskItem task, int index, {Animation<double>? anim}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.pink.shade100),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.pink.shade100.withValues(alpha: 0.25),
//               blurRadius: 6,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Checkbox(
//               value: task.done,
//               onChanged: (_) => _toggleDone(index),
//               activeColor: const Color(0xFFE91E63),
//             ),
//             const SizedBox(width: 6),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     task.title,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 14,
//                       decoration: task.done ? TextDecoration.lineThrough : null,
//                       color: task.done ? Colors.black54 : Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     task.category,
//                     style: const TextStyle(fontSize: 12, color: Colors.black54),
//                   ),
//                 ],
//               ),
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete_outline, color: Colors.black38),
//               onPressed: () => _removeTask(index),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // small circular icon button used in row
//   Widget _iconCircleButton({required IconData icon, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: 36,
//         height: 36,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(color: Colors.grey.shade300),
//           color: Colors.white,
//         ),
//         child: Icon(icon, size: 16, color: Colors.black54),
//       ),
//     );
//   }
//
//   // Edit dialog to rename a task (updates local model)
//   void _showEditDialog(int index) {
//     final t = _tasks[index];
//     final controller = TextEditingController(text: t.title);
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Edit task'),
//         content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Task name')),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               final newText = controller.text.trim();
//               if (newText.isNotEmpty) {
//                 setState(() {
//                   t.title = newText;
//                 });
//                 // optionally: send update to server here if API exists
//               }
//               Navigator.pop(context);
//             },
//             child: const Text('Save'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Confirm delete dialog (reuses your _removeTask function)
//   void _confirmDelete(int index) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete task?'),
//         content: const Text('This will remove the task from your checklist.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _removeTask(index);
//               // optionally: call server delete if available
//             },
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // full width days box (difference of start and wedding dates)
//   Widget _fullWidthDaysBox() {
//     if (startDate == null || weddingDate == null) {
//       return _daysBoxUI("—", "Select both dates");
//     }
//
//     final days = totalPlanningDays;
//
//     return _daysBoxUI(
//       "$days",
//       "Total Planning Days",
//     );
//   }
//
//   Widget _daysBoxUI(String number, String label) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 22),
//       decoration: BoxDecoration(
//         color: Colors.pinkAccent.shade100,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: [
//           Text(number,
//               style: const TextStyle(
//                   fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
//           const SizedBox(height: 6),
//           Text(label,
//               style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 15,
//                   fontWeight: FontWeight.w600)),
//         ],
//       ),
//     );
//   }
//
//   // small reusable card wrapper with gradient header (keeps existing look)
//   Widget _cardWrapper({required Widget child, required String title}) {
//     return Container(
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 6))]),
//       child: Column(
//         children: [
//           // header gradient
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF06292)], begin: Alignment.topLeft, end: Alignment.bottomRight),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
//           ),
//           Padding(padding: const EdgeInsets.all(16), child: child),
//         ],
//       ),
//     );
//   }
//
//   // date picker small field
//   Widget _datePickerField({DateTime? value, required String label, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(10),
//       child: Container(
//         height: 46,
//         padding: const EdgeInsets.symmetric(horizontal: 12),
//         decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300)),
//         child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
//           Text(value == null ? label : '${value.day}/${value.month}/${value.year}', style: const TextStyle(color: Colors.black87)),
//           const Icon(Icons.calendar_month, color: Colors.grey),
//         ]),
//       ),
//     );
//   }
//
//   // ---------------- GANTT TIMELINE ----------------
//   Widget _buildGanttTimeline() {
//     if (startDate == null || weddingDate == null || _tasks.isEmpty) {
//       return Padding(
//         padding: const EdgeInsets.only(top: 8.0),
//         child: Text(
//           "Gantt timeline will appear here once you select dates and add tasks.",
//           style: TextStyle(color: Colors.grey[700]),
//         ),
//       );
//     }
//
//     final int totalDays = totalPlanningDays;
//     final int n = _tasks.length;
//     if (totalDays <= 0 || n == 0) {
//       return Padding(
//         padding: const EdgeInsets.only(top: 8.0),
//         child: Text(
//           "Not enough planning days to build timeline.",
//           style: TextStyle(color: Colors.grey[700]),
//         ),
//       );
//     }
//
//     // Fair distribution of days with remainder handling
//     final int base = totalDays ~/ n;
//     final int remainder = totalDays % n;
//     final List<int> durations = List<int>.generate(n, (i) => base + (i < remainder ? 1 : 0));
//
//     // build start offsets (days from startDate)
//     final List<int> startOffsets = <int>[];
//     int acc = 0;
//     for (final d in durations) {
//       startOffsets.add(acc);
//       acc += d;
//     }
//
//     // Responsive width using LayoutBuilder
//     return LayoutBuilder(builder: (context, constraints) {
//       final double availableWidth = (constraints.maxWidth - 80).clamp(200.0, 1200.0); // allow room for labels
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 8),
//           const Text(
//             "Gantt Timeline",
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 10),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: SizedBox(
//               width: availableWidth + 120, // extra room
//               child: Column(
//                 children: List.generate(_tasks.length, (index) {
//                   final task = _tasks[index];
//                   final int dur = durations[index];
//                   final int start = startOffsets[index];
//
//                   // compute left offset & width
//                   final double leftFraction = totalDays > 0 ? (start / totalDays) : 0.0;
//                   final double widthFraction = totalDays > 0 ? (dur / totalDays) : 0.0;
//
//                   final double leftPx = leftFraction * availableWidth;
//                   final double barPx = (widthFraction * availableWidth).clamp(6.0, availableWidth);
//
//                   final DateTime taskStartDate = startDate!.add(Duration(days: start));
//                   final DateTime taskEndDate = taskStartDate.add(Duration(days: dur - 1));
//
//                   String fmt(DateTime d) => "${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}";
//
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8.0),
//                     child: SizedBox(
//                       height: 48,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             width: 120,
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(task.title, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w600)),
//                                 const SizedBox(height: 4),
//                                 Text("${fmt(taskStartDate)} – ${fmt(taskEndDate)}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Stack(
//                               children: [
//                                 // timeline background bar
//                                 Container(
//                                   height: 22,
//                                   decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
//                                 ),
//                                 Positioned(
//                                   left: leftPx,
//                                   child: Container(
//                                     height: 22,
//                                     width: barPx,
//                                     decoration: BoxDecoration(
//                                       gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFF06292)], begin: Alignment.centerLeft, end: Alignment.centerRight),
//                                       borderRadius: BorderRadius.circular(6),
//                                       boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                         ],
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }
//
// // simple model for task item
// class _TaskItem {
//   String title;
//   String category;
//   bool done;
//
//   _TaskItem({required this.title, required this.category, this.done = false});
// }
//
// // vendor subcategory model
// class _VendorSubcategory {
//   final String id;
//   final String name;
//
//   _VendorSubcategory({required this.id, required this.name});
// }
