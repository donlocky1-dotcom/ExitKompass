import 'package:flutter/material.dart';

/// Mandatory disclaimer footer shown on result/detail screens (spec §9,
/// CLAUDE.md): estimates only, no tax or legal advice. Kept slim so it doesn't
/// eat much screen height.
class DisclaimerFooter extends StatelessWidget {
  const DisclaimerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style =
        theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Schätzungen für 2026, keine Steuer- oder Rechtsberatung.',
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An unobtrusive one-line disclaimer for the hub screens, placed at the end of
/// the scrolling content instead of as a fixed bar (which permanently covered a
/// large slice of the screen).
class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
      child: Text(
        'Alle Ergebnisse sind Schätzwerte für 2026, keine Steuer- oder '
        'Rechtsberatung.',
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
