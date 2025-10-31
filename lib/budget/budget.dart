import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BudgetPage extends StatefulWidget {
  final int userId;

  const BudgetPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool isLoading = true;
  List<Expense> expenses = [];

  final String baseUrl = 'https://happywedz.com/api/budgets';

  final List<BudgetCategory> categories = [
    BudgetCategory(name: 'Photographers', vendorTypeId: 1),
    BudgetCategory(name: 'Venues', vendorTypeId: 2),
    BudgetCategory(name: 'Makeup', vendorTypeId: 3),
    BudgetCategory(name: 'Planning & Decor', vendorTypeId: 4),
    BudgetCategory(name: 'Mehndi', vendorTypeId: 5),
    BudgetCategory(name: 'Jewellery & Accessories', vendorTypeId: 6),
    BudgetCategory(name: 'Caterers', vendorTypeId: 7),
    BudgetCategory(name: 'Music & Dance', vendorTypeId: 8),
    BudgetCategory(name: 'Invites & Gifts', vendorTypeId: 9),
    BudgetCategory(name: 'Bridal', vendorTypeId: 10),
    BudgetCategory(name: 'Groom', vendorTypeId: 11),
    BudgetCategory(name: 'Pre Wedding Shoot', vendorTypeId: 12),
    BudgetCategory(name: 'Florists', vendorTypeId: 13),
    BudgetCategory(name: 'Pandits', vendorTypeId: 14),
  ];

  double get totalEstimated => expenses.fold(0, (sum, e) => sum + e.estimatedBudget);
  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.finalCost);
  double get remaining => totalEstimated - totalSpent;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/user/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List items = data['data'] is List ? data['data'] : [data['data']];

          setState(() {
            expenses = items.map((item) {
              final cat = categories.firstWhere(
                    (c) => c.vendorTypeId == item['vendor_type_id'],
                orElse: () => BudgetCategory(name: 'Other', vendorTypeId: 0),
              );
              return Expense(
                id: item['id'],
                category: cat.name,
                estimatedBudget: (item['estimated_budget'] ?? 0).toDouble(),
                finalCost: (item['final_cost'] ?? 0).toDouble(),
                paid: (item['paid_amount'] ?? 0).toDouble(),
                vendorTypeId: item['vendor_type_id'],
                vendorSubcategoryId: item['vendor_subcategory_id'] ?? 0,
              );
            }).toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error loading budgets: $e');
      _showError('Failed to load budgets');
      setState(() => isLoading = false);
    }
  }

  Future<void> _createBudget(Expense e) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'vendor_type_id': e.vendorTypeId,
          'vendor_subcategory_id': e.vendorSubcategoryId,
          'estimated_budget': e.estimatedBudget,
          'final_cost': e.finalCost,
          'paid_amount': e.paid,
        }),
      );

      print('🔹 POST Response: ${response.statusCode}');
      print(response.body);

      final data = json.decode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        setState(() {
          e.id = data['data']['id'];
          expenses.add(e);
        });
        _showSuccess('Budget created successfully');
      } else {
        _showError(data['message'] ?? 'Failed to create budget');
      }
    } catch (e) {
      print('❌ Error creating budget: $e');
      _showError('Failed to create budget');
    }
  }

  Future<void> _updateBudget(Expense e) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${e.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'vendor_type_id': e.vendorTypeId,
          'vendor_subcategory_id': e.vendorSubcategoryId,
          'estimated_budget': e.estimatedBudget,
          'final_cost': e.finalCost,
          'paid_amount': e.paid,
        }),
      );

      print('🔹 PUT Response: ${response.statusCode}');
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSuccess('Budget updated successfully');
        _loadBudgets();
      } else {
        _showError(data['message'] ?? 'Failed to update budget');
      }
    } catch (e) {
      print('❌ Error updating budget: $e');
      _showError('Failed to update budget');
    }
  }

  Future<void> _deleteBudget(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() => expenses.removeWhere((x) => x.id == id));
        _showSuccess('Budget deleted successfully');
      } else {
        _showError(data['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      print('❌ Error deleting budget: $e');
      _showError('Failed to delete');
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  // ---------------- UI -----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffaf9fb),
      appBar: AppBar(
        title: const Text('Wedding Budget'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBudgets),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadBudgets,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSummaryCard(),
              _buildPieChart(),
              _buildExpenseList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _summaryItem('Estimated', totalEstimated, Colors.blue),
            _summaryItem('Spent', totalSpent, Colors.orange),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _summaryItem('Remaining', remaining, Colors.green),
            _summaryItem('Paid %', totalEstimated == 0 ? 0 : (totalSpent / totalEstimated * 100), Colors.pink),
          ]),
        ],
      ),
    );
  }

  Widget _summaryItem(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        Text(
          title == 'Paid %' ? '${value.toStringAsFixed(1)}%' : '₹${value.toStringAsFixed(0)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    if (expenses.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(40),
        decoration: _cardStyle(),
        child: const Center(child: Text('No expenses yet')),
      );
    }

    final colors = [
      Colors.pink,
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.amber,
      Colors.orange,
      Colors.red,
    ];

    final Map<String, double> dataMap = {};
    for (var e in expenses) {
      dataMap[e.category] = (dataMap[e.category] ?? 0) + e.finalCost;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardStyle(),
      child: Column(
        children: [
          const Text('Expense Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: dataMap.entries.map((e) {
                  final index = dataMap.keys.toList().indexOf(e.key);
                  return PieChartSectionData(
                    value: e.value,
                    color: colors[index % colors.length],
                    title: '${(e.value / totalSpent * 100).toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList(),
                centerSpaceRadius: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseList() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: _cardStyle(),
      child: Column(
        children: [
          const ListTile(
            title: Text('Your Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          if (expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No expenses added'),
            )
          else
            ...expenses.map((e) => ListTile(
              title: Text(e.category),
              subtitle: Text('Estimated ₹${e.estimatedBudget.toStringAsFixed(0)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${e.finalCost.toStringAsFixed(0)}'),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showEditExpenseDialog(e),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => _deleteBudget(e.id),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  BoxDecoration _cardStyle() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
  );

  void _showAddExpenseDialog() {
    _showExpenseDialog(title: 'Add Expense', onSave: (e) async => await _createBudget(e));
  }

  void _showEditExpenseDialog(Expense expense) {
    _showExpenseDialog(
      title: 'Edit Expense',
      existing: expense,
      onSave: (e) async => await _updateBudget(e),
    );
  }

  void _showExpenseDialog({required String title, Expense? existing, required Function(Expense) onSave}) {
    int selectedCat = existing == null
        ? 0
        : categories.indexWhere((c) => c.vendorTypeId == existing.vendorTypeId);
    final estCtrl = TextEditingController(text: existing?.estimatedBudget.toString() ?? '');
    final finalCtrl = TextEditingController(text: existing?.finalCost.toString() ?? '');
    final paidCtrl = TextEditingController(text: existing?.paid.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: selectedCat,
                items: categories.asMap().entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value.name));
                }).toList(),
                onChanged: (v) => selectedCat = v!,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 10),
              TextField(controller: estCtrl, decoration: const InputDecoration(labelText: 'Estimated ₹')),
              const SizedBox(height: 10),
              TextField(controller: finalCtrl, decoration: const InputDecoration(labelText: 'Final Cost ₹')),
              const SizedBox(height: 10),
              TextField(controller: paidCtrl, decoration: const InputDecoration(labelText: 'Paid ₹')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final cat = categories[selectedCat];
              final exp = Expense(
                id: existing?.id ?? 0,
                category: cat.name,
                estimatedBudget: double.tryParse(estCtrl.text) ?? 0,
                finalCost: double.tryParse(finalCtrl.text) ?? 0,
                paid: double.tryParse(paidCtrl.text) ?? 0,
                vendorTypeId: cat.vendorTypeId,
                vendorSubcategoryId: 1,
              );
              Navigator.pop(context);
              onSave(exp);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// Models
class BudgetCategory {
  final String name;
  final int vendorTypeId;
  BudgetCategory({required this.name, required this.vendorTypeId});
}

class Expense {
  int id;
  String category;
  double estimatedBudget;
  double finalCost;
  double paid;
  int vendorTypeId;
  int vendorSubcategoryId;
  Expense({
    required this.id,
    required this.category,
    required this.estimatedBudget,
    required this.finalCost,
    required this.paid,
    required this.vendorTypeId,
    required this.vendorSubcategoryId,
  });
}
