import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/ratgeber_content.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/help_panel.dart';

/// Ratgeber tab: articles grouped by category (spec §2.1 knowledge
/// snippets). General legal information only.
class RatgeberTab extends StatelessWidget {
  const RatgeberTab({this.showHelpPanel = false, super.key});

  /// When true, the neutral "Passende Hilfe" panel is appended. Used on the
  /// standalone [RatgeberScreen] (the info-only entry), where no scenario
  /// comparison exists to carry the panel. In the post-wizard HomeShell the
  /// panel lives in the comparison tab, so this stays false there.
  final bool showHelpPanel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final category in ArticleCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(category.label, style: theme.textTheme.titleMedium),
          ),
          for (final article in ratgeberArticles.where((a) => a.category == category))
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(article.title),
                subtitle: Text(article.teaser),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ArticleScreen(article: article)),
                ),
              ),
            ),
        ],
        if (showHelpPanel) ...[
          const SizedBox(height: 8),
          // No computed scenarios in the info-only path → neutral order.
          const HelpPanel(flagCodes: {}),
        ],
        const SizedBox(height: 8),
        Text(
          'Stand: $contentReviewedOn. Allgemeine Informationen, keine Rechtsberatung '
          'im Einzelfall.',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Standalone Ratgeber screen (opened directly from onboarding, without
/// running the calculator).
class RatgeberScreen extends StatelessWidget {
  const RatgeberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ratgeber')),
      body: const Column(
        children: [
          Expanded(child: RatgeberTab(showHelpPanel: true)),
          DisclaimerFooter(),
        ],
      ),
    );
  }
}

/// Article detail with sections, sources and the disclaimer footer.
class ArticleScreen extends StatelessWidget {
  const ArticleScreen({required this.article, super.key});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(article.category.label)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(article.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 16),
                for (final section in article.sections) ...[
                  Text(section.heading, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(section.body, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Text('Rechtsgrundlagen', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final source in article.sources)
                      Chip(
                        label: Text(source),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Stand: $contentReviewedOn', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
