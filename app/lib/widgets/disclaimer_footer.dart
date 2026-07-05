import 'package:flutter/material.dart';

/// Mandatory disclaimer footer shown on every result/detail screen
/// (spec §9, CLAUDE.md): estimates only, no tax or legal advice.
class DisclaimerFooter extends StatelessWidget {
  const DisclaimerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Alle Werte sind Schätzungen für das Jahr 2026 und keine Steuer- oder '
              'Rechtsberatung. Im Zweifel Fachanwalt oder Steuerberater fragen.',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
