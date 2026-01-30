import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const int kDefaultMonthlyBudget = 1500;

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final List<_CategoryBudget> _categories = [
    const _CategoryBudget(name: 'Food', limit: 300),
    const _CategoryBudget(name: 'Transport', limit: 300),
    const _CategoryBudget(name: 'Shopping', limit: 300),
    const _CategoryBudget(name: 'Entertainment', limit: 300),
  ];

  int _monthlyBudget = kDefaultMonthlyBudget;

  @override
  void initState() {
    super.initState();
    _loadMonthlyBudget();
  }

  Future<void> _loadMonthlyBudget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final raw = doc.data()?['monthly budget'];
    final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
    if (value != null && value > 0 && mounted) {
      setState(() {
        _monthlyBudget = value;
      });
    }
  }

  Future<void> _saveMonthlyBudget(int value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'monthly budget': value},
      SetOptions(merge: true),
    );
  }

  Future<void> _addCategory() async {
    final result = await _showCategoryDialog();
    if (result == null) {
      return;
    }
    setState(() {
        _categories.add(
          _CategoryBudget(name: result.name, limit: result.amount),
        );
    });
  }

  Future<void> _editCategory(int index) async {
    final existing = _categories[index];
    final result = await _showCategoryDialog(existing: existing);
    if (result == null) {
      return;
    }
    setState(() {
      _categories[index] = _CategoryBudget(
        name: result.name,
        limit: result.amount,
      );
    });
  }

  Future<void> _editMonthlyBudget() async {
    final controller = TextEditingController(text: _monthlyBudget.toString());
    final updated = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Monthly Budget'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '\$',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed == null || parsed <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount')),
                );
                return;
              }
              Navigator.pop(context, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == null) {
      return;
    }

    setState(() {
      _monthlyBudget = updated;
    });
    await _saveMonthlyBudget(updated);
  }

  Future<_CategoryEditResult?> _showCategoryDialog({
    _CategoryBudget? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing?.limit.toStringAsFixed(0) ?? '',
    );

    return showDialog<_CategoryEditResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount =
                  double.tryParse(amountController.text.trim());
              if (name.isEmpty || amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a name and amount')),
                );
                return;
              }
              Navigator.pop(
                context,
                _CategoryEditResult(name: name, amount: amount),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Please sign in to view your budget.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('date', isLessThan: Timestamp.fromDate(monthEnd))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load budget'));
        }

        final docs = snapshot.data?.docs ?? [];
        final spentByCategory = {
          for (final category in _categories) category.name: 0.0,
        };

        for (final doc in docs) {
          final data = doc.data();
          final category = (data['category'] as String?) ?? 'Other';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          if (spentByCategory.containsKey(category)) {
            spentByCategory[category] =
                (spentByCategory[category] ?? 0) + amount;
          }
        }

        final totalSpent = spentByCategory.values.fold<double>(
          0,
          (sum, value) => sum + value,
        );
        final remaining = _monthlyBudget - totalSpent;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Budget',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: _addCategory,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _editMonthlyBudget,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6FA97A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Budget',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatCurrency(_monthlyBudget.toDouble()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Remaining\n${_formatCurrency(remaining < 0 ? 0 : remaining)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ..._categories.asMap().entries.map(
                    (entry) => _CategoryCard(
                      category: entry.value,
                      spent: spentByCategory[entry.value.name] ?? 0,
                      onTap: () => _editCategory(entry.key),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryBudget {
  const _CategoryBudget({
    required this.name,
    required this.limit,
  });

  final String name;
  final double limit;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.spent,
    required this.onTap,
  });

  final _CategoryBudget category;
  final double spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = category.limit <= 0 ? 0.0 : spent / category.limit;
    final overBudget = ratio > 1;
    final displayRatio = ratio.clamp(0.0, 1.0);
    final barColor = overBudget ? const Color(0xFFCB6659) : const Color(0xFF6FA97A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatCurrency(spent)} / ${_formatCurrency(category.limit)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: overBudget ? const Color(0xFFCB6659) : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: displayRatio,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overBudget
                  ? 'Over budget by ${_formatCurrency(spent - category.limit)}'
                  : 'On track',
              style: TextStyle(
                fontSize: 12,
                color: overBudget ? const Color(0xFFCB6659) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryEditResult {
  const _CategoryEditResult({required this.name, required this.amount});

  final String name;
  final double amount;
}

String _formatCurrency(double value) {
  return '\$${value.toStringAsFixed(0)}';
}
