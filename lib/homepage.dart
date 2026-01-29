import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:spendly/budget_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _touchedPieIndex = -1;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _lastDocs;

  static const List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
  ];

  static const Map<String, Color> _categoryColors = {
    'Food': Colors.orange,
    'Transport': Colors.blue,
    'Shopping': Colors.purple,
    'Entertainment': Colors.green,
  };

  CollectionReference<Map<String, dynamic>>? _collectionForUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  DateTime _startOfWeekMonday(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final weekday = dayStart.weekday; // 1 = Monday
    return dayStart.subtract(Duration(days: weekday - DateTime.monday));
  }

  String _formatCurrency(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final withCommas = parts[0]
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
    return '\$${withCommas}.${parts[1]}';
  }

  String _budgetImageAsset(double ratio) {
    if (ratio >= 0.8) {
      return 'assets/images/sad_dino.png';
    }
    if (ratio >= 0.5) {
      return 'assets/images/worried_dino.png';
    }
    return 'assets/images/happy_dino.png';
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(12));
    const baseBalance = 2500.0;
    final collection = _collectionForUser();

    if (collection == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Please sign in to view your weekly summary.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final now = DateTime.now();
    final currentWeekStart = _startOfWeekMonday(now);
    final currentWeekEnd = currentWeekStart.add(const Duration(days: 7));
    final windowStart = currentWeekStart.subtract(const Duration(days: 7 * 11));
    final windowEnd = currentWeekEnd;
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart))
          .where('date', isLessThan: Timestamp.fromDate(windowEnd))
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _lastDocs = snapshot.data!.docs;
        }
        final docs = snapshot.data?.docs ?? _lastDocs ?? [];
        if (snapshot.connectionState == ConnectionState.waiting &&
            docs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load summary'));
        }

        final totalsThisWeek = {
          for (final cat in _categories) cat: 0.0,
        };
        final weeklyTotals = List<double>.filled(12, 0.0);
        double totalSpentThisWeek = 0;
        double totalSpentThisMonth = 0;

        for (final doc in docs) {
          final data = doc.data();
          final category = (data['category'] as String?) ?? 'Other';
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final date = (data['date'] as Timestamp?)?.toDate();
          if (date == null) continue;
          if (date.isBefore(windowStart) || !date.isBefore(windowEnd)) {
            continue;
          }

          final weekIndex =
              date.difference(windowStart).inDays ~/ 7; // 0..11
          if (weekIndex >= 0 && weekIndex < weeklyTotals.length) {
            weeklyTotals[weekIndex] += amount;
          }

          if (!date.isBefore(currentWeekStart) &&
              date.isBefore(currentWeekEnd) &&
              totalsThisWeek.containsKey(category)) {
            totalsThisWeek[category] =
                (totalsThisWeek[category] ?? 0) + amount;
            totalSpentThisWeek += amount;
          }

          if (!date.isBefore(monthStart) && date.isBefore(monthEnd)) {
            totalSpentThisMonth += amount;
          }
        }

        final totalForPie =
            totalsThisWeek.values.fold<double>(0, (sum, v) => sum + v);
        final maxWeekly = weeklyTotals.fold<double>(0, (a, b) => a > b ? a : b);
        final yInterval = maxWeekly <= 0 ? 1.0 : (maxWeekly / 4).ceilToDouble();
        final remainingBalance = baseBalance - totalSpentThisWeek;

        final budgetRatio = kDefaultMonthlyBudget <= 0
            ? 0.0
            : totalSpentThisMonth / kDefaultMonthlyBudget;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 1.5),
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        _budgetImageAsset(budgetRatio),
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                        semanticLabel: 'Budget status',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Total balance:',
                              value: _formatCurrency(remainingBalance),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Spent this week:',
                              value: _formatCurrency(totalSpentThisWeek),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 1.5),
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spending by category (this week)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      if (totalForPie == 0)
                        const Center(child: Text('No transactions this week'))
                      else
                        SizedBox(
                          height: 220,
                          child: RepaintBoundary(
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    if (!event.isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null) {
                                      setState(() => _touchedPieIndex = -1);
                                      return;
                                    }
                                    setState(() {
                                      _touchedPieIndex =
                                          response.touchedSection!
                                              .touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: _categories.map((cat) {
                                  final value = totalsThisWeek[cat] ?? 0;
                                  final color =
                                      _categoryColors[cat] ?? Colors.grey;
                                  final percent = totalForPie == 0
                                      ? 0
                                      : (value / totalForPie) * 100;
                                  final index = _categories.indexOf(cat);
                                  final isTouched = index == _touchedPieIndex;
                                  return PieChartSectionData(
                                    value: value,
                                    color: color,
                                    radius: isTouched ? 70 : 60,
                                    title:
                                        '${cat.substring(0, 1)} ${percent.toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    badgeWidget: isTouched
                                        ? _PieBadge(
                                            text:
                                                '$cat: ${_formatCurrency(value)}',
                                          )
                                        : null,
                                    badgePositionPercentageOffset: .98,
                                  );
                                }).toList(),
                              ),
                              swapAnimationDuration:
                                  const Duration(milliseconds: 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 1.5),
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Past 12 weeks',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: RepaintBoundary(
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: maxWeekly == 0 ? 4 : maxWeekly + yInterval,
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 36,
                                    interval: yInterval,
                                    getTitlesWidget: (value, meta) {
                                      if (value < 0) {
                                        return const SizedBox.shrink();
                                      }
                                      final label = value.toStringAsFixed(0);
                                      return Text(
                                        label,
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 3,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= weeklyTotals.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final labelDate = windowStart
                                          .add(Duration(days: index * 7));
                                      final label =
                                          '${labelDate.month}/${labelDate.day}';
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          label,
                                          style:
                                              const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              lineTouchData: const LineTouchData(enabled: true),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (var i = 0;
                                        i < weeklyTotals.length;
                                        i++)
                                      FlSpot(i.toDouble(), weeklyTotals[i]),
                                  ],
                                  isCurved: true,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.orange.withOpacity(0.2),
                                  ),
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                            duration: const Duration(milliseconds: 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black45),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieBadge extends StatelessWidget {
  const _PieBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
