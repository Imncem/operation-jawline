import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.recommendation});

  final String recommendation;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.24),
            const Color(0xFF0E1B25),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Protocol Activated',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Maintain discipline. Sharpness increasing.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}
