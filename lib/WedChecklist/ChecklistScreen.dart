import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class WeddingTimelinePage extends StatefulWidget {
  const WeddingTimelinePage({super.key});

  @override
  State<WeddingTimelinePage> createState() => _WeddingTimelinePageState();
}

class _WeddingTimelinePageState extends State<WeddingTimelinePage>
    with TickerProviderStateMixin {
  // Dates
  DateTime? startDate;
  DateTime? weddingDate;

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
  String _selectedCategory = 'Mehendi Artists';
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();

    // controllers: short stagger
    _cardController1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _cardController2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    _cardController3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 720));
    _daysController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

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

  // Calculate days difference between startDate and weddingDate
  int get _differenceDays {
    if (startDate == null || weddingDate == null) return 0;
    return weddingDate!.difference(startDate!).inDays;
  }

  int get _completedCount => _tasks.where((t) => t.done).length;
  int get _totalCount => _tasks.length;
  double get _progress => _totalCount == 0 ? 0.0 : _completedCount / _totalCount;

  // Add a new task (animated insert)
  void _addTask() {
    final text = _taskController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter task name')));
      return;
    }
    final task = _TaskItem(title: text, category: _selectedCategory);
    setState(() {
      _tasks.insert(0, task);
    });
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 450));
    _taskController.clear();
    print('➕ Task added: ${task.title} [${task.category}]');
  }

  // Toggle done
  void _toggleDone(int index) {
    setState(() {
      _tasks[index].done = !_tasks[index].done;
    });
    print('✅ Task toggled: ${_tasks[index].title} -> ${_tasks[index].done}');
  }

  // Remove task
  void _removeTask(int index) {
    final removed = _tasks.removeAt(index);
    _listKey.currentState?.removeItem(index, (context, animation) {
      return SizeTransition(
        sizeFactor: animation,
        axis: Axis.vertical,
        child: _buildTaskTile(removed, index, anim: animation),
      );
    }, duration: const Duration(milliseconds: 380));
    print('🗑️ Task removed: ${removed.title}');
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
      print('📅 Start Date set: $picked');
      // animate days box re-bounce
      _daysController.forward(from: 0.0);
    }
  }

  Future<void> _pickWeddingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: weddingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFFE91E63))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => weddingDate = picked);
      print('💍 Wedding Date set: $picked');
      _daysController.forward(from: 0.0);
    }
  }

  // ---------------- UI BUILDERS ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE9F1),
      appBar: AppBar(
        title: const Text('Wedding Timeline'),
        centerTitle: true,
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // CARD 1: Task Status (unchanged visual)
              SlideTransition(position: _slide1, child: FadeTransition(opacity: _fade1, child: _taskStatusCard())),

              const SizedBox(height: 20),

              // CARD 2: Wedding Timeline (dates + days box)
              SlideTransition(position: _slide2, child: FadeTransition(opacity: _fade2, child: _timelineCard())),

              const SizedBox(height: 20),

              // CARD 3: Wedding Checklist (premium)
              SlideTransition(position: _slide3, child: FadeTransition(opacity: _fade3, child: _checklistCard())),
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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
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
      title: '📅 WEDDING TIMELINE',
    );
  }

  // Checklist card (premium)
// -------------- BEAUTIFUL CHECKLIST CARD (NEW DESIGN) --------------
// Replace your existing _checklistCard() with this implementation.

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download started')),
                  );
                },
                icon: const Icon(Icons.download_rounded, color: Colors.black87),
              ),

              // Print Icon Button
              IconButton(
                tooltip: "Print",
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Print dialog opened')),
                  );
                },
                icon: const Icon(Icons.print_rounded, color: Colors.black87),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ===== OVERALL PROGRESS =====
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                  const AlwaysStoppedAnimation(Color(0xFFE91E63)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$_completedCount completed',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('$_totalCount total tasks',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('${(_progress * 100).round()}% complete',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ===== ADD NEW TASK =====
        Container(
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.pink.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.pink.shade100.withOpacity(0.3),
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

              // --- Category, Task, Add ---
              Row(
                children: [
                  // Category dropdown
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: const Text('Category',
                              style: TextStyle(fontSize: 4)),
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                                value: 'Mehendi Artists',
                                child: Text('Mehendi Artists')),
                            DropdownMenuItem(
                                value: 'Caterers', child: Text('Caterers')),
                            DropdownMenuItem(
                                value: 'Photographers',
                                child: Text('Photographers')),
                            DropdownMenuItem(
                                value: 'Decorators', child: Text('Decorators')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedCategory = v);
                            }
                          },

                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Task name
                  Expanded(
                    flex: 4,
                    child: Container(
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
                              hintText: 'Task name'),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (_) => _addTask(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Add button
                  GestureDetector(
                    onTap: _addTask,
                    child: Container(
                      height: 44,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.shade200.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Time allocation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pink.shade100),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Allocation',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFE91E63),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Wedding too near (<8 days)',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
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
                color: Colors.black.withOpacity(0.04),
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
                  Icon(Icons.list_alt,
                      size: 42, color: Colors.pinkAccent),
                  SizedBox(height: 8),
                  Text('No tasks yet — add a task above',
                      style: TextStyle(color: Colors.black54)),
                  SizedBox(height: 12),
                ],
              )
                  : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final t = _tasks[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: t.done,
                          onChanged: (_) => _toggleDone(index),
                          activeColor: const Color(0xFFE91E63),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: t.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.category,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.black45),
                          onPressed: () => _removeTask(index),
                        ),
                      ],
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
              color: Colors.pink.shade100.withOpacity(0.25),
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


  Widget _emptyTasksView() {
    return Center(
      child: Column(
        children: const [
          SizedBox(height: 10),
          Icon(Icons.list_alt, size: 48, color: Colors.pinkAccent),
          SizedBox(height: 8),
          Text('No tasks yet — add your first task!', style: TextStyle(color: Colors.black54)),
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

    print('📏 Days difference computed: $days ($message)');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 6))]),
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
  String title;
  String category;
  bool done;

  _TaskItem({required this.title, required this.category, this.done = false});
}
