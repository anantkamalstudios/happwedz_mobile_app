import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({Key? key}) : super(key: key);

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}



class _BudgetPageState extends State<BudgetPage> {
  bool isLoading = true;
  int? userId;
  List<Expense> expenses = [];


  bool isSubcatLoading = false;
  List<BudgetCategory> categories = [];
  Map<int, List<SubCategory>> subcategoriesMap = {};



  final String baseUrl = 'https://happywedz.com/api/budgets';



  // ✅ Corrected Budget Calculations (match your reference screen)
  double get totalEstimated => expenses.fold(0, (sum, e) => sum + e.estimatedBudget);
  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.paid);
  double get remaining => totalEstimated - totalSpent;
  double get totalFinalCost => expenses.fold(0, (sum, e) => sum + e.finalCost);


  @override
  void initState() {
    super.initState();
    _initUserAndLoadBudgets();
    _loadSubcategories(); // 👈 Add this

  }

  Future<void> _loadSubcategories() async {
    setState(() => isSubcatLoading = true);
    print('🔄 Fetching vendor types and subcategories...');

    try {
      final response = await http.get(
        Uri.parse('https://happywedz.com/api/vendor-types/with-subcategories/all'),
      );
      print('🌐 Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print('✅ Found ${data.length} vendor types from API');
        final List<BudgetCategory> tempCategories = [];
        final Map<int, List<SubCategory>> tempMap = {};

        for (var v in data) {
          final int vendorTypeId = v['id'];
          final String name = v['name'] ?? 'Unknown';
          final List subList = v['subcategories'] ?? [];

          final subcats = subList.map((s) => SubCategory.fromJson(s)).toList();
          tempMap[vendorTypeId] = subcats;
          tempCategories.add(BudgetCategory(name: name, vendorTypeId: vendorTypeId));

          print('📂 $name ($vendorTypeId) → ${subcats.length} subcategories');
        }

        setState(() {
          categories = tempCategories;
          subcategoriesMap = tempMap;
        });

        print('✅ Categories loaded: ${categories.length}');
        print('✅ Subcategories Map Keys: ${subcategoriesMap.keys.toList()}');
      } else {
        print('❌ Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error while loading vendor types: $e');
    }

    setState(() => isSubcatLoading = false);
    print('✅ Finished loading all vendor types');
  }




  Future<void> _initUserAndLoadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getInt('user_id');
    if (storedUserId == null) {
      _showError('User not logged in');
      setState(() => isLoading = false);
      return;
    }
    setState(() => userId = storedUserId);
    await _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    if (userId == null) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',  // ✅ Include token here
        },
      );

      print('🔹 GET $baseUrl/user/$userId -> ${response.statusCode}');
      print('Response body: ${response.body}');

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
                vendorSubcategoryId: item['vendor_subcategory_id'] ?? 1,
              );
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            expenses = [];
            isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          expenses = [];
          isLoading = false;
        });
      } else {
        _showError('Failed to load budgets: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading budgets: $e');
      _showError('Failed to load budgets');
      setState(() => isLoading = false);
    }
  }

  Future<void> _createBudget(Expense e) async {
    if (userId == null) {
      print('⚠️ userId is null – cannot create budget');
      _showError('User ID not found');
      return;
    }

    try {
      final body = json.encode({
        'userId': userId, // ✅ Correct key name
        'vendor_type_id': e.vendorTypeId,
        'vendor_subcategory_id': e.vendorSubcategoryId,
        'estimated_budget': e.estimatedBudget,
        'final_cost': e.finalCost,
        'paid_amount': e.paid,
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('⚠️ No auth token found');
        _showError('Please log in again');
        return;
      }

      print('🔹 POST $baseUrl');
      print('🔹 Headers: Authorization: Bearer $token');
      print('🔹 Body: $body');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('Response: ${response.statusCode}, Body: ${response.body}');
      final data = json.decode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('⚠️ No auth token found');
        _showError('Please log in again');
        return;
      }

      final body = json.encode({
        'vendor_type_id': e.vendorTypeId,
        'vendor_subcategory_id': e.vendorSubcategoryId,
        'estimated_budget': e.estimatedBudget,
        'final_cost': e.finalCost,
        'paid_amount': e.paid,
      });

      print('🔹 PUT $baseUrl/${e.id}');
      print('🔹 Headers: Authorization: Bearer $token');
      print('🔹 Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/${e.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('Response: ${response.statusCode}, Body: ${response.body}');
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSuccess('Budget updated successfully');
        await _loadBudgets();
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        print('⚠️ No auth token found');
        _showError('Please log in again');
        return;
      }

      print('🗑 DELETE $baseUrl/$id');
      print('🔹 Headers: Authorization: Bearer $token');

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DELETE Response: ${response.statusCode}, Body: ${response.body}');
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

  @override
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
              // 🌸 Custom AppBar
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
                      'Budget',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadBudgets,
                    ),
                  ],
                ),
              ),

              // 🌸 Body
              Expanded(
                child: isLoading
                    ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                )
                    : RefreshIndicator(
                  onRefresh: _loadBudgets,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        _buildPieChart(),
                        _buildExpenseList(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Estimated Budget', totalEstimated, Colors.blue),
              _summaryItem('Total Spent', totalSpent, Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem('Remaining', remaining, Colors.green),
              _summaryItem('Final Cost', totalFinalCost, Colors.pink),
            ],
          ),
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
          const Text(
            'Expense Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: dataMap.entries.map((e) {
                  final index = dataMap.keys.toList().indexOf(e.key);
                  final percentage = (e.value / totalFinalCost) * 100;

                  return PieChartSectionData(
                    value: e.value,
                    color: colors[index % colors.length],
                    title: '${percentage.toStringAsFixed(1)}%',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
            const Padding(padding: EdgeInsets.all(20), child: Text('No expenses added'))
          else
            ...expenses.map((e) => ListTile(
              title: Text(e.category),
              subtitle: Text('Estimated ₹${e.estimatedBudget.toStringAsFixed(0)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₹${e.finalCost.toStringAsFixed(0)}'),
                  IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showEditExpenseDialog(e)),
                  IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteBudget(e.id)),
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
    print('🟢 Opening Add Expense Dialog');
    print('   → subcategoriesMap keys: ${subcategoriesMap.keys.toList()}');
    if (isSubcatLoading) {
      print('⚠️ Tried to open while subcategories are still loading');
      _showError('Please wait, loading categories...');
      return;
    }
    _showExpenseDialog(title: 'Add Expense', onSave: _createBudget);
  }


  void _showEditExpenseDialog(Expense expense) => _showExpenseDialog(title: 'Edit Expense', existing: expense, onSave: _updateBudget);

  void _showExpenseDialog({
    required String title,
    Expense? existing,
    required Function(Expense) onSave,
  }) {
    int selectedCat = existing == null
        ? 0
        : categories.indexWhere((c) => c.vendorTypeId == existing.vendorTypeId);
    int? selectedSubcatId = existing?.vendorSubcategoryId;

    final estCtrl = TextEditingController(text: existing?.estimatedBudget.toString() ?? '');
    final finalCtrl = TextEditingController(text: existing?.finalCost.toString() ?? '');
    final paidCtrl = TextEditingController(text: existing?.paid.toString() ?? '');

    List<SubCategory> getSubcatsForSelectedCat() {
      if (selectedCat < 0 || selectedCat >= categories.length) return [];
      final vendorTypeId = categories[selectedCat].vendorTypeId;
      print('🔎 Getting subcategories for vendorTypeId: $vendorTypeId');
      return subcategoriesMap[vendorTypeId] ?? [];
    }




    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: selectedCat >= 0 ? selectedCat : null,
                  items: categories
                      .asMap()
                      .entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.name)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedCat = v!;
                      selectedSubcatId = null;
                    });
                    print('📍 Category changed → ${categories[selectedCat].name} (vendorTypeId: ${categories[selectedCat].vendorTypeId})');
                    print('📦 Available subcats for this: ${subcategoriesMap[categories[selectedCat].vendorTypeId]?.length ?? 0}');
                  },


                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 10),

                // 👇 New Subcategory Dropdown
                // 👇 Improved Subcategory Dropdown (always visible)
                Builder(
                  builder: (context) {
                    final subcats = getSubcatsForSelectedCat();
                    print('🟣 Building Subcategory Dropdown → ${subcats.length} found');
                    if (isSubcatLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return DropdownButtonFormField<int>(
                      value: subcats.any((s) => s.id == selectedSubcatId) ? selectedSubcatId : null,
                      items: subcats
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: subcats.isEmpty
                          ? null
                          : (v) => setState(() {
                        selectedSubcatId = v;
                        print('✅ Subcategory selected: $v');
                      }),
                      decoration: const InputDecoration(labelText: 'Subcategory'),
                      hint: const Text('Select Subcategory'),
                    );
                  },
                ),





                const SizedBox(height: 10),
                TextField(
                    controller: estCtrl,
                    decoration: const InputDecoration(labelText: 'Estimated ₹'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(
                    controller: finalCtrl,
                    decoration: const InputDecoration(labelText: 'Final Cost ₹'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(
                    controller: paidCtrl,
                    decoration: const InputDecoration(labelText: 'Paid ₹'),
                    keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final estBudget = double.tryParse(estCtrl.text);
                final finalCost = double.tryParse(finalCtrl.text);
                final paid = double.tryParse(paidCtrl.text);

                if (estBudget == null || finalCost == null || paid == null) {
                  _showError('Please fill all fields correctly');
                  return;
                }

                if (selectedSubcatId == null) {
                  _showError('Please select a subcategory');
                  return;
                }

                final cat = categories[selectedCat];
                final exp = Expense(
                  id: existing?.id ?? 0,
                  category: cat.name,
                  estimatedBudget: estBudget,
                  finalCost: finalCost,
                  paid: paid,
                  vendorTypeId: cat.vendorTypeId,
                  vendorSubcategoryId: selectedSubcatId!,
                );

                Navigator.pop(context);
                onSave(exp);
              },
              child: const Text('Save'),
            ),
          ],
        ),
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

class SubCategory {
  final int id;
  final String name;

  SubCategory({required this.id, required this.name});

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
    );
  }
}

