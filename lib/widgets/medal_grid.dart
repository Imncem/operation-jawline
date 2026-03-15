import 'package:flutter/material.dart';

import '../models/medal.dart';

class MedalGrid extends StatelessWidget {
  const MedalGrid({
    super.key,
    required this.medals,
    required this.onTap,
  });

  final List<Medal> medals;
  final ValueChanged<Medal> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medals.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final medal = medals[index];
        return InkWell(
          onTap: () => onTap(medal),
          child: Card(
            margin: EdgeInsets.zero,
            color: medal.isUnlocked
                ? scheme.primaryContainer.withValues(alpha: 0.18)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconFor(medal.iconKey),
                    color: medal.isUnlocked ? scheme.primary : scheme.outline,
                  ),
                  const Spacer(),
                  Text(
                    medal.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(medal.category),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'radio':
        return Icons.radio_outlined;
      case 'link':
      case 'chain7':
      case 'chain30':
        return Icons.link;
      case 'play':
        return Icons.play_arrow_rounded;
      case 'perfect':
        return Icons.verified_outlined;
      case 'resolve':
        return Icons.shield_outlined;
      case 'recovery':
        return Icons.self_improvement_outlined;
      case 'promotion':
      case 'promotion5':
        return Icons.military_tech_outlined;
      case 'elite':
        return Icons.workspace_premium_outlined;
      case 'calendar':
      case 'week4':
        return Icons.event_available_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }
}
