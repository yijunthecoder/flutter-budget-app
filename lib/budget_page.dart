import 'package:flutter/material.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final List<_CategoryBudget> _categories = [
    const _CategoryBudget(name: 'Food', spent: 450, limit: 300),
    const _CategoryBudget(name: 'Transport', spent: 200, limit: 300),
    const _CategoryBudget(name: 'Shopping', spent: 120, limit: 300),
    const _CategoryBudget(name: 'Entertainment', spent: 150, limit: 300),
  ];

  int _monthlyBudget = 1500;

  Future<void> _addCategory() async {
    final result = await _showCategoryDialog();
    if (result == null) {
      return;
    }
    setState(() {
      _categories.add(
        _CategoryBudget(name: result.name, spent: 0, limit: result.amount),
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
        spent: existing.spent,
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
  }

  Future<_CategoryEditResult?> _showCategoryDialog({
    _CategoryBudget? existing,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final amountController = TextEditingController(
      text: existing?.limit.toString() ?? '',
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
              final amount = int.tryParse(amountController.text.trim());
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
    final totalSpent = _categories.fold<int>(0, (sum, item) => sum + item.spent);
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    '\$$_monthlyBudget',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Remaining\n\$${remaining < 0 ? 0 : remaining}',
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
                  onTap: () => _editCategory(entry.key),
                ),
              ),
        ],
      ),
    );
  }
}

class _CategoryBudget {
  const _CategoryBudget({
    required this.name,
    required this.spent,
    required this.limit,
  });

  final String name;
  final int spent;
  final int limit;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _CategoryBudget category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = category.spent / category.limit;
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
                  '\$${category.spent} / \$${category.limit}',
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
                  ? 'Over budget by \$${category.spent - category.limit}'
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
  final int amount;
}
