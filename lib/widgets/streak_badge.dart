import 'package:flutter/material.dart';

class StreakBadge extends StatelessWidget {
  final int longestStreak;
  const StreakBadge({super.key, required this.longestStreak});

  @override
  Widget build(BuildContext context) {
    final milestone = _milestoneFor(longestStreak);
    if (milestone == null) return const SizedBox.shrink();

    final color = _colorFor(milestone);
    final label = '${milestone}d';

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Milestone Achieved!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You reached a ${milestone}-day streak! 🎉'),
                const SizedBox(height: 12),
                const Text('Milestones'),
                const SizedBox(height: 8),
                _milestoneList(),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _milestoneList() {
    final milestones = [7, 30, 100, 365];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: milestones.map((m) {
        final achieved = longestStreak >= m;
        return ListTile(
          leading: Icon(achieved ? Icons.check_circle : Icons.radio_button_unchecked, color: achieved ? Colors.green : Colors.grey),
          title: Text('$m-day streak'),
          subtitle: achieved ? const Text('Achieved') : const Text('Not yet'),
        );
      }).toList(),
    );
  }

  int? _milestoneFor(int days) {
    if (days >= 365) return 365;
    if (days >= 100) return 100;
    if (days >= 30) return 30;
    if (days >= 7) return 7;
    return null;
  }

  Color _colorFor(int milestone) {
    switch (milestone) {
      case 7:
        return const Color(0xFFFFA726); // orange
      case 30:
        return const Color(0xFFFF7043); // deep orange
      case 100:
        return const Color(0xFF7E57C2); // purple
      case 365:
        return const Color(0xFF26A69A); // teal
      default:
        return Colors.grey;
    }
  }
}
