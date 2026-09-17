import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../authservice.dart';
import '../core/core.dart';
import '../core/config/api_config.dart';

class WeddingTimelinePage extends StatefulWidget {
  const WeddingTimelinePage({super.key});

  @override
  State<WeddingTimelinePage> createState() => _WeddingTimelinePageState();
}

class _WeddingTimelinePageState extends State<WeddingTimelinePage>
    with TickerProviderStateMixin {
  // ---- Config ----
  final String baseUrl = ApiConfig.apiBase;

  /// Checklist-scoped "planning start date" — there is no app-wide field for
  /// this (unlike [UserPrefs.weddingDateKey], which every other screen also
  /// reads/writes), so it gets its own key, mirroring the website's own
  /// `saved_start_date` localStorage entry.
  static const String _startDatePrefsKey = 'checklist_start_date';

  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');

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

  // Loading / in-flight guards (prevent duplicate taps -> duplicate API calls)
  bool _isLoadingCategories = false;
  bool _isLoadingChecklist = false;
  bool _isAddingTask = false;
  bool _isGeneratingPdf = false;
  bool _isPrinting = false;

  /// Task ids currently mid status-change / edit / delete, so their row can
  /// disable its own controls without freezing the rest of the list.
  final Set<String> _updatingTaskIds = {};

  @override
  void initState() {
    super.initState();
    _loadDates();

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

  @override
  void dispose() {
    _cardController1.dispose();
    _cardController2.dispose();
    _cardController3.dispose();
    _daysController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt(UserPrefs.userIdKey);
    final token = prefs.getString(UserPrefs.tokenKey);

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

  /// Loads both the wedding date (the same app-wide value every other screen
  /// reads via [UserPrefs.weddingDateKey]) and this screen's own start date.
  /// AUDIT FIX: the previous version never persisted or reloaded a start
  /// date at all — it reset to null on every visit. If a previously saved
  /// combination is already invalid (wedding before start), that is
  /// surfaced once the widget can show a snackbar, rather than silently
  /// feeding bad dates into the allocation math (see `_hasValidDateRange`).
  Future<void> _loadDates() async {
    final prefs = await SharedPreferences.getInstance();
    final weddingStr = prefs.getString(UserPrefs.weddingDateKey);
    final startStr = prefs.getString(_startDatePrefsKey);

    final loadedWedding =
        (weddingStr != null && weddingStr.isNotEmpty) ? DateTime.tryParse(weddingStr) : null;
    final loadedStart =
        (startStr != null && startStr.isNotEmpty) ? DateTime.tryParse(startStr) : null;

    if (!mounted) return;
    setState(() {
      weddingDate = loadedWedding;
      startDate = loadedStart;
    });

    if (loadedStart != null && loadedWedding != null && loadedWedding.isBefore(loadedStart)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppSnackbar.warning(
            context,
            'Your saved wedding date is before your start date. Please correct it.',
          );
        }
      });
    }
  }

  // Helper to provide headers (include token if available)
  Map<String, String> _headers() {
    final headers = <String, String>{'Accept': 'application/json'};
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ---------------------------------------------------------------------
  // Centralized progress / allocation getters (spec: single source of
  // truth — nothing below should be recomputed ad hoc inside a widget).
  // ---------------------------------------------------------------------

  int get _completedCount => _tasks.where((t) => t.isCompleted).length;
  int get _totalCount => _tasks.length;
  int get _pendingCount => _tasks.where((t) => t.status == 'pending').length;
  int get _inProgressCount => _tasks.where((t) => t.status == 'in_progress').length;

  int get _remainingCount {
    final remaining = _totalCount - _completedCount;
    return remaining > 0 ? remaining : 0;
  }

  double get _progress => _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

  String get _progressLabel => '${(_progress * 100).round()}% Complete';

  /// True only when both dates are set and the wedding date is not before
  /// the start date. Every allocation / countdown / buffer figure below
  /// requires this — an invalid combination must never silently produce
  /// misleading zeros.
  bool get _hasValidDateRange =>
      startDate != null && weddingDate != null && !weddingDate!.isBefore(startDate!);

  /// Total whole days between the start date and the wedding date. The
  /// wedding day itself is treated as the event, not a planning day.
  int get _totalDays {
    if (!_hasValidDateRange) return 0;
    final diff = weddingDate!.difference(startDate!).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Fair, remainder-aware day distribution across every task (largest
  /// remainder method).
  ///
  /// AUDIT FIX: the previous implementation used
  /// `(totalDays / taskCount).floor()` for every task, which silently threw
  /// away `totalDays % taskCount` days — 17 available days across 5 tasks
  /// used to allocate only 15 of them (3 days each). This distributes every
  /// day: the first `remainder` tasks get one extra day, so 17 days / 5
  /// tasks -> 4, 4, 3, 3, 3, summing back to exactly 17.
  List<_DistributedTask> get _taskAllocations {
    if (!_hasValidDateRange || _tasks.isEmpty) return [];

    final int totalAvailable = _totalDays;
    final int n = _tasks.length;
    final int base = totalAvailable ~/ n;
    final int remainder = totalAvailable % n;

    final List<_DistributedTask> result = [];
    DateTime cursor = startDate!;

    for (int i = 0; i < n; i++) {
      final int days = base + (i < remainder ? 1 : 0);
      final DateTime start = cursor;
      final DateTime end = days > 0 ? start.add(Duration(days: days - 1)) : start;
      result.add(_DistributedTask(task: _tasks[i], days: days, start: start, end: end));
      cursor = start.add(Duration(days: days));
    }

    return result;
  }

  int get _totalAllocatedDays =>
      _taskAllocations.fold<int>(0, (sum, a) => sum + a.days);

  /// Available window minus what tasks actually consume. Zero tasks means
  /// nothing has been allocated yet, so the whole window counts as buffer.
  /// Never negative — the allocation above can never exceed `_totalDays`.
  int get _unallocatedBufferDays {
    if (!_hasValidDateRange) return 0;
    if (_tasks.isEmpty) return _totalDays;
    final buffer = _totalDays - _totalAllocatedDays;
    return buffer > 0 ? buffer : 0;
  }

  /// Countdown from *today* to the wedding date — distinct from
  /// `_totalDays` (start date -> wedding date). Never negative.
  int get _remainingCountdownDays {
    if (weddingDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final wedding = DateTime(weddingDate!.year, weddingDate!.month, weddingDate!.day);
    final diff = wedding.difference(today).inDays;
    return diff > 0 ? diff : 0;
  }

  bool get _weddingDateHasPassed {
    if (weddingDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final wedding = DateTime(weddingDate!.year, weddingDate!.month, weddingDate!.day);
    return wedding.isBefore(today);
  }

  // ---------------- API CALLS ----------------

  // Fetch vendor types + subcategories -> flatten to subcategories list
  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() => _isLoadingCategories = true);

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
          if (_subcategories.isNotEmpty && _selectedCategory.isEmpty) {
            _selectedCategory = _subcategories.first.id;
          }
        });
      } else {
        debugPrint("❌ Category fetch failed ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Category fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  // Fetch checklist for the user
  Future<void> _fetchChecklist() async {
    if (!mounted) return;
    setState(() => _isLoadingChecklist = true);

    try {
      debugPrint("🔎 Fetching checklist…");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(UserPrefs.tokenKey) ?? "";
      final userId = prefs.getInt(UserPrefs.userIdKey);

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

      String? fallbackStart;
      String? fallbackWedding;

      for (final item in list) {
        final text = item["text"]?.toString() ?? "";
        final status = item["status"]?.toString() ?? "";
        final subId = item["vendor_subcategory_id"]?.toString() ?? "";

        fallbackStart ??= item["start_date"]?.toString();
        fallbackWedding ??= item["wedding_date"]?.toString();

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
            status: status,
          ),
        );
      }

      debugPrint("✅ Loaded tasks count: ${_tasks.length}");

      // Only used when the user has never picked dates on this device —
      // mirrors the website's own fallback in `Check.jsx`.
      if (startDate == null && fallbackStart != null && fallbackStart.isNotEmpty) {
        startDate = DateTime.tryParse(fallbackStart.split('T').first);
      }
      if (weddingDate == null && fallbackWedding != null && fallbackWedding.isNotEmpty) {
        weddingDate = DateTime.tryParse(fallbackWedding.split('T').first);
      }

      // Guarded: the user can leave the checklist while the request runs.
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint("❌ Checklist fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingChecklist = false);
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
    await prefs.setString(UserPrefs.tokenKey, token);
    await prefs.setInt(UserPrefs.userIdKey, userId);
    // AUDIT FIX (security): debugPrint is not compiled out of release builds,
    // so logging the raw token wrote a live session credential to the device
    // log on every app. Only presence/length is logged now, matching the
    // pattern already used elsewhere in this file.
    debugPrint("✅ Token saved: length=${token.length}");
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

  // PUT update (text and/or status) — the one real update endpoint the
  // backend exposes; edit and status-change both funnel through this.
  Future<bool> _updateChecklistOnServer(String id, Map<String, dynamic> fields) async {
    try {
      final uri = Uri.parse("$baseUrl/new-checklist/update/$id");
      final res = await http.put(
        uri,
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: json.encode(fields),
      );

      debugPrint("✏️ UPDATE status: ${res.statusCode}");
      if (kDebugMode) debugPrint("✏️ UPDATE body: ${res.body}");

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("❌ Update checklist error: $e");
      return false;
    }
  }

  Future<bool> _updateChecklistStatusOnServer(String id, String status) {
    return _updateChecklistOnServer(id, {'status': status});
  }

  Future<bool> _updateChecklistTextOnServer(String id, String text) {
    return _updateChecklistOnServer(id, {'text': text});
  }

  /// Best-effort persistence of both dates to the backend, mirroring the
  /// website's `PUT /new-checklist/update-wedding-date` call. Non-blocking:
  /// a failure here just means the dates stay local for now, same as the
  /// website's own try/catch-and-warn.
  Future<void> _updateWeddingDatesOnServer() async {
    if (_userId == null || startDate == null || weddingDate == null) return;
    try {
      final uri = Uri.parse("$baseUrl/new-checklist/update-wedding-date");
      await http.put(
        uri,
        headers: {..._headers(), 'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'weddingDate': _fmtDate(weddingDate!),
          'startDate': _fmtDate(startDate!),
        }),
      );
    } catch (e) {
      debugPrint('⚠️ Could not save dates to backend: $e');
    }
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

  // ---------------- UI / Task logic (preserve original design) ----------------

  // Add a new task (animated insert + POST to server)
  void _addTask() async {
    if (_isAddingTask) return; // prevent duplicate taps -> duplicate creates

    if (_selectedCategory.isEmpty) {
      AppSnackbar.warning(context, 'Please select a vendor category.');
      return;
    }

    final text = _taskController.text.trim();
    if (text.isEmpty) {
      AppSnackbar.warning(context, 'Please enter a task name.');
      return;
    }
    if (startDate == null || weddingDate == null) {
      AppSnackbar.warning(context, 'Please select both dates.');
      return;
    }
    if (!_hasValidDateRange) {
      AppSnackbar.warning(context, 'Wedding date cannot be before start date.');
      return;
    }

    // AUDIT: confirmed live against the real backend — `/new-checklist/create`
    // returns 400 "Wedding is too near (less than 8 days left)" once the
    // wedding date is inside that window, matching the website's own
    // pre-check in `Check.jsx`. Checked here too so the user gets this
    // specific reason instead of the generic "couldn't add" failure message.
    final daysToWedding = weddingDate!.difference(DateTime.now()).inDays;
    if (daysToWedding < 8) {
      AppSnackbar.warning(
        context,
        'Your wedding is too near to add new checklist tasks (less than 8 days left).',
      );
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

    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final task = _TaskItem(id: tempId, title: text, category: sub.name);

    setState(() {
      _isAddingTask = true;
      _tasks.insert(0, task);
      _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 450));
    });

    // Clear input
    _taskController.clear();

    // Post to server
    final ok = await _createChecklistOnServer(
      text: text,
      startDateString: start,
      weddingDateString: wed,
      vendorSubcategoryId: vendorSubId,
    );

    if (!mounted) return;

    if (ok) {
      AppSnackbar.success(context, 'Task added successfully.');
      await _fetchChecklist(); // refresh tasks from server (real id, allocation, etc.)
    } else {
      // Remove optimistic insert if failed — matched by the temp id, not by
      // title/category (two tasks can share both).
      final idx = _tasks.indexWhere((t) => t.id == tempId);
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

    if (mounted) setState(() => _isAddingTask = false);
  }

  /// Status change (Pending / In Progress / Done) — optimistic update, then
  /// the real update API; rolled back on failure so the UI can never end up
  /// showing something the backend doesn't actually have.
  Future<void> _changeTaskStatus(_TaskItem task, String newStatus) async {
    if (_updatingTaskIds.contains(task.id)) return;

    final normalized = _TaskItem._normalizeStatus(newStatus);
    if (task.status == normalized) return;

    final oldStatus = task.status;
    setState(() {
      _updatingTaskIds.add(task.id);
      task.status = normalized;
    });

    final ok = await _updateChecklistStatusOnServer(task.id, normalized);

    if (!mounted) return;

    if (ok) {
      AppSnackbar.success(context, 'Task status updated.');
    } else {
      setState(() => task.status = oldStatus);
      AppSnackbar.error(context, 'Unable to update task status. Please try again.');
    }

    setState(() => _updatingTaskIds.remove(task.id));
  }

  // Remove task
  Future<void> _removeTask(int index) async {
    if (index < 0 || index >= _tasks.length) return;
    final removed = _tasks[index];
    if (_updatingTaskIds.contains(removed.id)) return;

    // Optimistic UI remove
    setState(() {
      _updatingTaskIds.add(removed.id);
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

    if (!mounted) return;

    if (ok) {
      AppSnackbar.success(context, 'Task deleted successfully.');
      setState(() => _updatingTaskIds.remove(removed.id));
    } else {
      // rollback if API fails — restore at (as close as possible to) its
      // original position, including its allocation via the recomputed
      // `_taskAllocations` getter (there is nothing extra to restore there,
      // it derives from `_tasks` automatically).
      final restoreIndex = index <= _tasks.length ? index : _tasks.length;
      setState(() {
        _tasks.insert(restoreIndex, removed);
        _updatingTaskIds.remove(removed.id);
      });
      _listKey.currentState?.insertItem(restoreIndex);
      AppSnackbar.error(context, "We couldn't delete that task. Please try again.");
    }
  }

  // Date pickers with validation + best-effort persistence
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
    if (picked == null || !mounted) return;

    // AUDIT FIX: the previous version never checked the start date against
    // an already-selected wedding date, so a start date after the wedding
    // date was silently accepted (see spec item: date validation).
    if (weddingDate != null && picked.isAfter(weddingDate!)) {
      AppSnackbar.warning(context, 'Start date cannot be after the wedding date.');
      return;
    }

    setState(() => startDate = picked);
    debugPrint('📅 Start Date set: $picked');
    // animate days box re-bounce
    _daysController.forward(from: 0.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_startDatePrefsKey, _fmtDate(picked));
    await _updateWeddingDatesOnServer();
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

    if (picked == null || !mounted) return;

    if (startDate != null && picked.isBefore(startDate!)) {
      // Just in case, extra safeguard
      AppSnackbar.warning(context, 'The wedding date cannot be before the start date.');
      return;
    }

    setState(() => weddingDate = picked);
    debugPrint('💍 Wedding Date set: $picked');
    _daysController.forward(from: 0.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(UserPrefs.weddingDateKey, _fmtDate(picked));
    await _updateWeddingDatesOnServer();
  }

  // ---------------- PDF (download / print) ----------------

  pw.Widget _pdfHeaderCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
    ),
  );

  pw.Widget _pdfCell(String text, {PdfColor? color}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(text, style: pw.TextStyle(fontSize: 8.5, color: color ?? PdfColors.black)),
  );

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Done';
      case 'in_progress':
        return 'In Progress';
      default:
        return 'Pending';
    }
  }

  PdfColor _statusPdfColor(String status) {
    switch (status) {
      case 'completed':
        return PdfColors.green700;
      case 'in_progress':
        return PdfColors.blue700;
      default:
        return PdfColors.amber700;
    }
  }

  /// Builds the checklist PDF entirely on-device (no backend PDF endpoint
  /// exists — mirrors the website's own client-side `@react-pdf/renderer`
  /// generation in `ChecklistPDF.jsx`, using this project's existing `pdf`
  /// dependency instead).
  Future<Uint8List> _generateChecklistPdfBytes() async {
    final doc = pw.Document();
    final allocations = _taskAllocations;
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'HappyWedz',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Wedding Checklist', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Generated: ${_displayDateFormat.format(now)}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.pink700, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Plan your dream wedding at www.happywedz.com',
            style: pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          if (startDate != null)
            pw.Text('Start Date: ${_displayDateFormat.format(startDate!)}', style: const pw.TextStyle(fontSize: 9.5)),
          if (weddingDate != null)
            pw.Text('Wedding Date: ${_displayDateFormat.format(weddingDate!)}', style: const pw.TextStyle(fontSize: 9.5)),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(color: PdfColors.pink50, borderRadius: pw.BorderRadius.circular(4)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Tasks: $_totalCount', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
                pw.Text('Completed: $_completedCount', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Remaining: $_remainingCount', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Progress: ${(_progress * 100).round()}%', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          if (_tasks.isEmpty)
            pw.Text('No tasks found in this wedding checklist.', style: const pw.TextStyle(fontSize: 11))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.3),
                1: pw.FlexColumnWidth(3.2),
                2: pw.FlexColumnWidth(2.1),
                3: pw.FlexColumnWidth(1.0),
                4: pw.FlexColumnWidth(1.4),
                5: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _pdfHeaderCell('Status'),
                    _pdfHeaderCell('Task'),
                    _pdfHeaderCell('Category'),
                    _pdfHeaderCell('Days'),
                    _pdfHeaderCell('Start'),
                    _pdfHeaderCell('End'),
                  ],
                ),
                for (int i = 0; i < _tasks.length; i++)
                  pw.TableRow(
                    children: [
                      _pdfCell(_statusLabel(_tasks[i].status), color: _statusPdfColor(_tasks[i].status)),
                      _pdfCell(_tasks[i].title),
                      _pdfCell(_tasks[i].category),
                      _pdfCell(i < allocations.length && allocations[i].days > 0 ? '${allocations[i].days}' : 'N/A'),
                      _pdfCell(i < allocations.length ? _displayDateFormat.format(allocations[i].start) : '—'),
                      _pdfCell(i < allocations.length ? _displayDateFormat.format(allocations[i].end) : '—'),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('About HappyWedz', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.pink700)),
                pw.SizedBox(height: 3),
                pw.Text(
                  "HappyWedz is India's favourite one-stop wedding planning platform - discover verified "
                  "vendors, and manage guest lists, e-invitations, checklists and budgets, all in one place.",
                  style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _handleDownloadPdf() async {
    if (_isGeneratingPdf) return;
    if (_tasks.isEmpty) {
      AppSnackbar.info(context, 'No tasks to download.');
      return;
    }
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generateChecklistPdfBytes();
      if (!mounted) return;
      await Printing.sharePdf(bytes: bytes, filename: 'wedding-checklist.pdf');
    } catch (e) {
      debugPrint('❌ PDF generation error: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Unable to generate PDF. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    if (_tasks.isEmpty) {
      AppSnackbar.info(context, 'No tasks to print.');
      return;
    }
    setState(() => _isPrinting = true);
    try {
      final bytes = await _generateChecklistPdfBytes();
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'wedding-checklist.pdf',
      );
    } catch (e) {
      debugPrint('❌ Print error: $e');
      if (mounted) {
        AppSnackbar.error(context, 'Unable to print the checklist. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
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
      title: '🕒 TASK STATUS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // big count and label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$_completedCount/$_totalCount', style: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold)),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusCountChip('Pending', _pendingCount, const Color(0xFF92400E), const Color(0xFFFEF3C7)),
                    _statusCountChip('In Progress', _inProgressCount, const Color(0xFF0369A1), const Color(0xFFE0F2FE)),
                    _statusCountChip('Done', _completedCount, const Color(0xFF15803D), const Color(0xFFDCFCE7)),
                  ],
                ),
                const SizedBox(height: 14),
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
                    Text('$_completedCount completed', style: const TextStyle(fontSize: 12)),
                    Text('$_totalCount total tasks', style: const TextStyle(fontSize: 12)),
                    Text(_progressLabel, style: const TextStyle(fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusCountChip(String label, int count, Color textColor, Color bgColor) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Text('$count', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  /// Shown wherever a set-but-invalid date combination would otherwise
  /// produce misleading zeros (countdown, buffer, allocation).
  Widget _invalidDateRangeBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your wedding date is before the start date. Please correct the dates above — '
                  'the countdown and task allocation cannot be calculated until they do.',
              style: TextStyle(color: Color(0xFF991B1B), fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Timeline card (dates + days)
  Widget _timelineCard() {
    return _cardWrapper(
      title: '📅 WEDDING CHECKLIST',
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
          if (startDate != null && weddingDate != null && !_hasValidDateRange) ...[
            const SizedBox(height: 12),
            _invalidDateRangeBanner(),
          ],
          const SizedBox(height: 18),
          ScaleTransition(scale: _scaleDays, child: _fullWidthDaysBox()),
        ],
      ),
    );
  }

  /// The web version's "Estimated Time Allocation" block — start / end /
  /// remaining countdown / unallocated buffer. Recomputed on every build
  /// from the centralized getters above, so it updates automatically
  /// whenever a date, add, delete, or status change touches them.
  Widget _buildTimeAllocationCard(List<_DistributedTask> allocations) {
    if (startDate == null || weddingDate == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.pink.shade100),
        ),
        child: Text(
          'Select both the start date and wedding date above to see the estimated time allocation.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
        ),
      );
    }

    if (!_hasValidDateRange) {
      return _invalidDateRangeBanner();
    }

    final countdownText = _weddingDateHasPassed
        ? 'Wedding date passed'
        : 'Remaining countdown: $_remainingCountdownDays day${_remainingCountdownDays == 1 ? '' : 's'}';

    final bufferText = _tasks.isEmpty
        ? 'Unallocated buffer: $_unallocatedBufferDays day${_unallocatedBufferDays == 1 ? '' : 's'} (no tasks added yet)'
        : 'Unallocated buffer: $_unallocatedBufferDays day${_unallocatedBufferDays == 1 ? '' : 's'} '
        '($_totalAllocatedDays days allocated across ${_tasks.length} task${_tasks.length == 1 ? '' : 's'})';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFFE91E63)),
              SizedBox(width: 6),
              Text(
                'Estimated Time Allocation',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB30059), fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('•  Start: ${_displayDateFormat.format(startDate!)}', style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 3),
          Text('•  End: ${_displayDateFormat.format(weddingDate!)}', style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 3),
          Text('•  $countdownText', style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
          const SizedBox(height: 3),
          Text('•  $bufferText', style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
        ],
      ),
    );
  }

  // Checklist card (premium)
  Widget _checklistCard() {
    final allocations = _taskAllocations;

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
                tooltip: "Download PDF",
                onPressed: (_isGeneratingPdf || _tasks.isEmpty) ? null : _handleDownloadPdf,
                icon: _isGeneratingPdf
                    ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded, color: Colors.black87),
              ),

              // Print Icon Button
              IconButton(
                tooltip: "Print",
                onPressed: (_isPrinting || _tasks.isEmpty) ? null : _handlePrint,
                icon: _isPrinting
                    ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_rounded, color: Colors.black87),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // ===== OVERALL TASK COMPLETION =====
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFCE7F3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Overall Task Completion', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE91E63), borderRadius: BorderRadius.circular(20)),
                    child: Text(_progressLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: Colors.pink.shade50,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFE91E63)),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _statPill('$_completedCount', 'Tasks Completed', const Color(0xFF10B981)),
                  _statPill('$_totalCount', 'Total Tasks', const Color(0xFF0F172A)),
                  _statPill('$_remainingCount', 'Tasks Remaining', const Color(0xFFED1173)),
                  _statPill('$_unallocatedBufferDays', 'Unallocated Buffer', const Color(0xFF3B82F6)),
                ],
              ),
            ],
          ),
        ),

        if (startDate != null && weddingDate != null && !_hasValidDateRange) ...[
          const SizedBox(height: 14),
          _invalidDateRangeBanner(),
        ],

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

              const Text('Vendor Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 6),

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
                  child: _isLoadingCategories
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Loading categories...', style: TextStyle(fontSize: 13)),
                    ),
                  )
                      : _subcategories.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select Vendor Category', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    ),
                  )
                      : DropdownButton<String>(
                    value: _selectedCategory.isEmpty ? null : _selectedCategory,
                    hint: const Text('Select Vendor Category', style: TextStyle(fontSize: 13)),
                    isExpanded: true,
                    items: _subcategories.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }).toList(),
                    onChanged: _isAddingTask
                        ? null
                        : (v) {
                      if (v != null) {
                        setState(() => _selectedCategory = v);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Text('Task Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
              const SizedBox(height: 6),

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
                    enabled: !_isAddingTask,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Enter task description',
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🔹 ADD BUTTON BELOW BOTH
              GestureDetector(
                onTap: _isAddingTask ? null : _addTask,
                child: Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: _isAddingTask
                          ? [Colors.grey.shade400, Colors.grey.shade400]
                          : const [Color(0xFFE91E63), Color(0xFFF06292)],
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
                  child: Center(
                    child: _isAddingTask
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Text('Adding…', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    )
                        : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Add Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 ESTIMATED TIME ALLOCATION
              _buildTimeAllocationCard(allocations),
            ],
          ),
        ),

        const SizedBox(height: 18),

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
              if (_isLoadingChecklist)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_tasks.isEmpty)
                const Column(
                  children: [
                    SizedBox(height: 14),
                    Icon(Icons.list_alt, size: 42, color: Colors.pinkAccent),
                    SizedBox(height: 8),
                    Text('No tasks yet — add a task above',
                        style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 12),
                  ],
                )
              else
                AnimatedList(
                  key: _listKey,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  initialItemCount: _tasks.length,
                  itemBuilder: (context, index, animation) {
                    if (index >= _tasks.length) return const SizedBox.shrink();
                    final task = _tasks[index];
                    final allocation = index < allocations.length ? allocations[index] : null;

                    return SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.vertical,
                      child: _buildTaskCard(task, index, allocation),
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

  /// One task row: status dropdown, title, category, allocated timeline,
  /// edit + delete. Mirrors the website's table row, laid out as a card so
  /// it never has to force a desktop table onto a phone width.
  Widget _buildTaskCard(_TaskItem task, int index, _DistributedTask? allocation) {
    final busy = _updatingTaskIds.contains(task.id);
    final hasAllocation = allocation != null && _hasValidDateRange;

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusDropdown(task),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted ? Colors.black45 : Colors.black87,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 14, color: Color(0xFFB71C5E)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.category,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFB71C5E), fontSize: 12.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.blueGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hasAllocation
                      ? '${allocation.days} Day${allocation.days == 1 ? '' : 's'} Allocated  •  '
                      '${_displayDateFormat.format(allocation.start)} - ${_displayDateFormat.format(allocation.end)}'
                      : 'Set both dates to see the allocated timeline',
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                ],
                _iconCircleButton(
                  icon: Icons.edit_outlined,
                  onTap: busy ? null : () => _showEditDialog(index),
                ),
                const SizedBox(width: 8),
                _iconCircleButton(
                  icon: Icons.delete_outline,
                  onTap: busy ? null : () => _confirmDelete(index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pill-styled dropdown for Pending / In Progress / Done, colour-matched
  /// to the website's own status colours.
  Widget _buildStatusDropdown(_TaskItem task) {
    final busy = _updatingTaskIds.contains(task.id);
    final colors = _statusColors(task.status);

    return Opacity(
      opacity: busy ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: task.status,
            isDense: true,
            icon: Icon(Icons.arrow_drop_down, color: colors.text, size: 18),
            style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w700),
            dropdownColor: Colors.white,
            onChanged: busy
                ? null
                : (value) {
              if (value != null) _changeTaskStatus(task, value);
            },
            items: const [
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'completed', child: Text('Done')),
            ],
          ),
        ),
      ),
    );
  }

  _StatusColors _statusColors(String status) {
    switch (status) {
      case 'completed':
        return const _StatusColors(Color(0xFFDCFCE7), Color(0xFF15803D), Color(0xFF86EFAC));
      case 'in_progress':
        return const _StatusColors(Color(0xFFE0F2FE), Color(0xFF0369A1), Color(0xFF93C5FD));
      default:
        return const _StatusColors(Color(0xFFFEF3C7), Color(0xFF92400E), Color(0xFFFDE047));
    }
  }

  Widget _statPill(String value, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  // ---------- REFINED TASK TILE (used only as the AnimatedList
  // insert/remove animation placeholder) ----------
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
            Icon(
              task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.isCompleted ? const Color(0xFFE91E63) : Colors.grey.shade400,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.black54 : Colors.black87,
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
          ],
        ),
      ),
    );
  }

  // small circular icon button used in row
  Widget _iconCircleButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
          color: onTap == null ? Colors.grey.shade50 : Colors.white,
        ),
        child: Icon(icon, size: 16, color: onTap == null ? Colors.black26 : Colors.black54),
      ),
    );
  }

  // Edit dialog: renames a task AND persists it to the backend.
  void _showEditDialog(int index) {
    if (index < 0 || index >= _tasks.length) return;
    final task = _tasks[index];
    final controller = TextEditingController(text: task.title);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> save() async {
              final newText = controller.text.trim();
              if (newText.isEmpty) {
                AppSnackbar.warning(context, 'Please enter a task name.');
                return;
              }
              if (newText == task.title) {
                Navigator.pop(dialogContext);
                return;
              }

              setDialogState(() => isSaving = true);
              final oldTitle = task.title;
              setState(() => task.title = newText);

              final ok = await _updateChecklistTextOnServer(task.id, newText);

              if (!mounted) return;
              Navigator.pop(dialogContext);

              if (ok) {
                AppSnackbar.success(context, 'Task updated successfully.');
              } else {
                setState(() => task.title = oldTitle);
                AppSnackbar.error(context, "We couldn't update that task. Please try again.");
              }
            }

            return AlertDialog(
              title: const Text('Edit task'),
              content: TextField(
                controller: controller,
                autofocus: true,
                enabled: !isSaving,
                decoration: const InputDecoration(hintText: 'Task name'),
                onSubmitted: (_) => save(),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving ? null : save,
                  child: isSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // full width days box (difference of start and wedding dates)
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
          Text(value == null ? label : _displayDateFormat.format(value), style: const TextStyle(color: Colors.black87)),
          const Icon(Icons.calendar_month, color: Colors.grey),
        ]),
      ),
    );
  }

  // AUDIT: superseded by the status dropdown (`_changeTaskStatus`), which
  // also persists to the backend — this only ever flipped the local model.
  // Kept commented rather than deleted per project convention.
  // void _toggleDone(int index) {
  //   setState(() {
  //     _tasks[index].done = !_tasks[index].done;
  //   });
  //   debugPrint('✅ Task toggled: ${_tasks[index].title} -> ${_tasks[index].done}');
  // }
}

/// Small immutable colour triple for a status pill/dropdown.
class _StatusColors {
  final Color background;
  final Color text;
  final Color border;
  const _StatusColors(this.background, this.text, this.border);
}

// Task model. `status` is now the primary state (spec: don't treat a bare
// `done` bool as the source of truth once the backend provides a real
// status field); `done` is kept as a compatibility getter/setter since a
// few places still read/write it as a boolean.
class _TaskItem {
  final String id;
  String title;
  String category;
  String _status;

  _TaskItem({
    required this.id,
    required this.title,
    required this.category,
    String status = 'pending',
  }) : _status = _normalizeStatus(status);

  String get status => _status;
  set status(String value) => _status = _normalizeStatus(value);

  bool get isCompleted => _status == 'completed';

  bool get done => isCompleted;
  set done(bool value) => status = value ? 'completed' : 'pending';

  /// The backend has returned "completed", "done", "in progress",
  /// "in_progress", "Pending", etc. across different call sites over time —
  /// normalize once here so every getter/UI branch can compare against
  /// exactly three canonical values.
  static String _normalizeStatus(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (normalized == 'completed' || normalized == 'done' || normalized == 'complete') {
      return 'completed';
    }
    if (normalized == 'in_progress' || normalized == 'inprogress' || normalized == 'progress') {
      return 'in_progress';
    }
    return 'pending';
  }
}

// vendor subcategory model
class _VendorSubcategory {
  final String id;
  final String name;

  _VendorSubcategory({required this.id, required this.name});
}

/// One task's computed slice of the planning timeline — `days` is the
/// AUDIT-FIXED, remainder-aware allocation (see `_taskAllocations` above),
/// and `start`/`end` are its inclusive date range (never past the wedding
/// date, since the allocations always sum to `_totalDays`).
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
