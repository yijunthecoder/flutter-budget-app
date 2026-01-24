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
                Text(
                  '$_streak',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _last30.map(_DayTick.new).toList(),
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
      width: 22,
      height: 34,
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
