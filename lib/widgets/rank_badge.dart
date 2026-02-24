import 'package:flutter/material.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.rank});

  final String rank;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.28),
            accent.withValues(alpha: 0.08)
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(
            rank,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
