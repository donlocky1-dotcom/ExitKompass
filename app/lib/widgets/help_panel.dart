import 'package:flutter/material.dart';

import '../content/help_resources.dart';
import 'disclaimer_footer.dart';

/// A discreet, collapsed-by-default panel that points to real-world help
/// (lawyer, legal-cost insurance, Agentur für Arbeit, health insurance …).
///
/// It is deliberately low-key and carries a clear "no ads, no broking" note:
/// unlike the competitor apps, ExitKompass earns nothing here and tracks
/// nothing. Entries relevant to the user's [flagCodes] are moved to the top
/// and get a subtle badge.
class HelpPanel extends StatelessWidget {
  const HelpPanel({required this.flagCodes, super.key});

  /// The union of [RiskFlag] codes across the computed scenarios.
  final Set<String> flagCodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resources = rankedHelpResources(flagCodes);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.support_outlined),
        title: const Text('Passende Hilfe finden'),
        subtitle: Text(
          'Neutrale Anlaufstellen – keine Werbung, keine Vermittlung.',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (final r in resources)
            ListTile(
              dense: true,
              title: Text(r.title),
              subtitle: Text(r.when),
              trailing: r.isHighlightedFor(flagCodes)
                  ? Tooltip(
                      message: 'Passt zu deiner Situation',
                      child: Icon(Icons.push_pin_outlined,
                          size: 18, color: theme.colorScheme.primary),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (_) => HelpResourceScreen(resource: r)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Detail view for a single [HelpResource]: what it is, where to turn to,
/// legal sources and the mandatory disclaimer.
class HelpResourceScreen extends StatelessWidget {
  const HelpResourceScreen({required this.resource, super.key});

  final HelpResource resource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Passende Hilfe')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(resource.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                Text(resource.body, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text('Wo du dich hinwenden kannst',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(resource.whereToTurn, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                if (resource.sources.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Rechtsgrundlagen', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final source in resource.sources)
                        Chip(
                          label: Text(source),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Text('Stand: $helpResourcesReviewedOn. ExitKompass verdient '
                    'nichts an diesen Hinweisen und vermittelt keine Anbieter.',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
