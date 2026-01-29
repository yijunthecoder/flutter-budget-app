import 'package:flutter/material.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const badges = [
      _Badge(
        title: '30 days streak',
        icon: Icons.local_fire_department,
        accent: Color(0xFFEF6C00),
      ),
      _Badge(
        title: 'Hit the budget',
        icon: Icons.attach_money,
        accent: Color(0xFF2E7D32),
      ),
      _Badge(
        title: 'Saved \$100',
        icon: Icons.savings,
        accent: Color(0xFF1565C0),
      ),
      _Badge(
        title: 'No-spend week',
        icon: Icons.do_not_disturb_alt,
        accent: Color(0xFF6A1B9A),
      ),
      _Badge(
        title: 'First plan',
        icon: Icons.check_circle,
        accent: Color(0xFF00897B),
      ),
      _Badge(
        title: 'Budget boss',
        icon: Icons.emoji_events,
        accent: Color(0xFFF9A825),
      ),
      _Badge(
        title: 'Track 7 days',
        icon: Icons.calendar_today,
        accent: Color(0xFF6D4C41),
      ),
      _Badge(
        title: 'New category',
        icon: Icons.category,
        accent: Color(0xFF5C6BC0),
      ),
      _Badge(
        title: 'Saved \$500',
        icon: Icons.savings_outlined,
        accent: Color(0xFF1B5E20),
      ),
      _Badge(
        title: 'Zero late fees',
        icon: Icons.verified,
        accent: Color(0xFF00838F),
      ),
    ];

    const achievementsEarned = 3;
    final unlockedCount = achievementsEarned.clamp(0, badges.length);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              child: Column(
                children: [
                  const Text(
                    'Budget tracker',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$achievementsEarned/${badges.length} badges collected',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                final isUnlocked = index < unlockedCount;
                return _BadgeCard(
                  badge: badge,
                  isUnlocked: isUnlocked,
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.lock_outline),
              label: const Text('Locked'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.black54, width: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: child,
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.isUnlocked,
  });

  final _Badge badge;
  final bool isUnlocked;

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? badge.accent : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black54, width: 1.5),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        color: isUnlocked ? Colors.white : Colors.grey.shade200,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? Colors.black : Colors.black54,
            ),
          ),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                badge.icon,
                size: 34,
                color: color,
              ),
              if (!isUnlocked)
                const Positioned(
                  bottom: -2,
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.black45,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge {
  const _Badge({
    required this.title,
    required this.icon,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final Color accent;
}
