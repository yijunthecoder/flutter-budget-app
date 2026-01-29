import 'package:flutter/material.dart';

class StreaksPage extends StatefulWidget {
  const StreaksPage({super.key});

  @override
  State<StreaksPage> createState() => _StreaksPageState();
}

class _StreaksPageState extends State<StreaksPage> {
  int _streak = 0;
  int _best = 0;
  final List<_DayEntry> _last30 = List.generate(
    30,
    (index) => _DayEntry(date: DateTime.now().subtract(Duration(days: 29 - index))),
  );

  void _logDay({required bool underBudget}) {
    setState(() {
      if (underBudget) {
        _streak += 1;
        if (_streak > _best) {
          _best = _streak;
        }
      } else {
        _streak = 0;
      }

      _last30.removeAt(0);
      _last30.add(
        _DayEntry(
          date: DateTime.now(),
          underBudget: underBudget,
        ),
      );
    });
  }

  int _fireCountForStreak(int streak) {
    if (streak >= 30) return 3;
    if (streak >= 14) return 2;
    if (streak >= 7) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final cardGradient = LinearGradient(
      colors: [
        Colors.purple.shade200,
        Colors.pink.shade200,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_streak',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      List.filled(_fireCountForStreak(_streak), '🔥').join(' '),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Day Streak',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Best: $_best days',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Last 30 Days',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 20 / 30,
            ),
            itemCount: _last30.length,
            itemBuilder: (context, index) => _DayTick(_last30[index]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logDay(underBudget: true),
                  icon: const Icon(Icons.check),
                  label: const Text('Under Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FA97A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logDay(underBudget: false),
                  icon: const Icon(Icons.close),
                  label: const Text('Over Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCB6659),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayEntry {
  _DayEntry({required this.date, this.underBudget});

  final DateTime date;
  final bool? underBudget;
}

class _DayTick extends StatelessWidget {
  const _DayTick(this.entry);

  final _DayEntry entry;

  @override
  Widget build(BuildContext context) {
    final icon = entry.underBudget == null
        ? Icons.remove
        : entry.underBudget!
            ? Icons.check
            : Icons.close;
    final color = entry.underBudget == null
        ? Colors.grey
        : entry.underBudget!
            ? const Color(0xFF6FA97A)
            : const Color(0xFFCB6659);

    return Container(
      width: 20,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}
