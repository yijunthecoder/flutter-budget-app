import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spendly/edit_transactions.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Food': Icons.lunch_dining,
    'Transport': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
  };

  DateTime _startOfWeekMonday(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final weekday = dayStart.weekday; // 1 = Monday
    return dayStart.subtract(Duration(days: weekday - DateTime.monday));
  }

  String _formatWeekLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    return 'Week of ${_formatDate(weekStart)} - ${_formatDate(end)}';
  }

  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  Future<void> _addTransaction(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to add transactions.')),
        );
      }
      return;
    }
    debugPrint('Current UID: ${user.uid}');
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = _categories.first;
    DateTime selectedDate = DateTime.now();

    Future<void> pickDate() async {
      final date = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (date != null) {
        selectedDate = date;
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add transaction'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: r'$',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Icon(
                                    _categoryIcons[cat] ?? Icons.receipt_long,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          category = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${_formatDate(selectedDate)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await pickDate();
                            setDialogState(() {});
                          },
                          child: const Text('Pick date'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    final title = titleController.text.trim();
    final amount = double.tryParse(amountController.text.trim());
    if (title.isEmpty || amount == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a title and valid amount.'),
          ),
        );
      }
      return;
    }

    try {
      final collection = _collection!;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      final docRef = await collection.add({
        'title': title,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(selectedDate),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Transaction added: ${docRef.path}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction added'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      final errorText = e.toString();
      debugPrint('Transaction add error: $errorText');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add failed: $errorText')),
        );
      }
    }
  }

  void _showDetails(BuildContext context, _TransactionItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditTransactionPage(
          transactionId: item.id,
          initialTitle: item.title,
          initialAmount: item.amount,
          initialCategory: item.category,
          initialDate: item.date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = _collection;
    if (collection == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Please sign in to view transactions.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    debugPrint('Loading transactions for UID: ${FirebaseAuth.instance.currentUser?.uid}');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _addTransaction(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black54, width: 1.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: collection
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final errorText = snapshot.error?.toString() ?? 'Unknown error';
                    debugPrint('Transactions load error: $errorText');
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load\n$errorText',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No transactions yet'),
                    );
                  }
                  final items = docs
                      .map((doc) => _TransactionItem.fromDoc(doc))
                      .toList();

                  final Map<DateTime, List<_TransactionItem>> grouped = {};
                  for (final item in items) {
                    final weekStart = _startOfWeekMonday(item.date);
                    grouped.putIfAbsent(weekStart, () => []).add(item);
                  }

                  final weekStarts = grouped.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  final List<Widget> listChildren = [];
                  for (final weekStart in weekStarts) {
                    listChildren.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _formatWeekLabel(weekStart),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                    final weekItems = grouped[weekStart] ?? [];
                    for (final item in weekItems) {
                      listChildren.add(
                        _TransactionTile(
                          item: item,
                          onTap: () => _showDetails(context, item),
                          icon:
                              _categoryIcons[item.category] ??
                                  Icons.receipt_long,
                        ),
                      );
                      listChildren.add(const SizedBox(height: 8));
                    }
                  }

                  return ListView.builder(
                    itemCount: listChildren.length,
                    itemBuilder: (context, index) => listChildren[index],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.onTap,
    required this.icon,
  });

  final _TransactionItem item;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54, width: 1.5),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category} - ${_formatDate(item.date)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '-\$${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionItem {
  const _TransactionItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  factory _TransactionItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    return _TransactionItem(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Untitled',
      amount: amount,
      category: (data['category'] as String?) ?? 'Other',
      date: date,
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}
