import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/wizard.dart';
import '../timeline/timeline.dart';
import '../widgets/ui_kit.dart';

/// Fristen tab (spec §4 screen 10): the personalised deadline timeline
/// derived from the wizard inputs.
class TimelineTab extends ConsumerWidget {
  const TimelineTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(wizardProvider);
    final items = buildTimeline(data);
    final fmt = DateFormat('dd.MM.yyyy');
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        const SectionLabel('Fristen', topPad: 8),
        Text('Deine Fristen',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          'Aus deinen Angaben berechnet. Termine sind Orientierungswerte – im '
          'Zweifel bei Agentur für Arbeit oder Anwalt bestätigen lassen.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        for (final item in items) _TimelineCard(item: item, fmt: fmt),
      ],
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.item, required this.fmt});

  final TimelineItem item;
  final DateFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (item.urgency) {
      TimelineUrgency.critical => (theme.colorScheme.error, Icons.priority_high),
      TimelineUrgency.important => (theme.colorScheme.primary, Icons.event),
      TimelineUrgency.info => (theme.colorScheme.onSurfaceVariant, Icons.info_outline),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title, style: theme.textTheme.titleSmall),
                      ),
                      if (item.date != null)
                        Text(
                          fmt.format(item.date!),
                          style: theme.textTheme.titleSmall?.copyWith(color: color),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(item.source,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
