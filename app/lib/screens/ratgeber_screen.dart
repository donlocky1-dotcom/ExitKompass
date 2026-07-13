import 'package:flutter/material.dart';

import '../content/models.dart';
import '../content/ratgeber_content.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/help_panel.dart';
import '../widgets/ui_kit.dart';
import 'bewerbung_screen.dart';
import 'non_compete_screen.dart';
import 'vacation_screen.dart';
import 'zeugnis_decoder_screen.dart';

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
    final abf = abfindungAccent(context);
    final bew = bewerbenAccent(context);
    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        const SectionLabel('Werkzeuge', topPad: 8),
        AppGroup(children: [
          AppRow(
            accent: bew,
            icon: Icons.translate,
            title: 'Zeugnis-Decoder',
            subtitle: 'Zeugnissprache in Klartext / Schulnote übersetzen',
            onTap: () => push(const ZeugnisDecoderScreen()),
          ),
          AppRow(
            accent: bew,
            icon: Icons.record_voice_over_outlined,
            title: 'Bewerbungstraining',
            subtitle: 'Interview-Fragen & Gehaltsverhandlung üben',
            onTap: () => push(const BewerbungScreen()),
          ),
          AppRow(
            accent: abf,
            icon: Icons.gavel_outlined,
            title: 'Karenzentschädigung',
            subtitle: 'Wettbewerbsverbot: was steht dir zu? (§§ 74 ff. HGB)',
            onTap: () => push(const NonCompeteScreen()),
          ),
          AppRow(
            accent: abf,
            icon: Icons.beach_access_outlined,
            title: 'Resturlaub abgelten',
            subtitle: 'Offene Urlaubstage auszahlen (§ 7 BUrlG)',
            onTap: () => push(const VacationScreen()),
          ),
        ]),
        for (final category in ArticleCategory.values) ...[
          SectionLabel(category.label),
          AppGroup(children: [
            for (final article
                in ratgeberArticles.where((a) => a.category == category))
              _ArticleRow(article: article),
          ]),
        ],
        if (showHelpPanel) ...[
          const SizedBox(height: 12),
          // No computed scenarios in the info-only path → neutral order.
          const HelpPanel(flagCodes: {}),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Stand: $contentReviewedOn. Allgemeine Informationen, keine '
            'Rechtsberatung im Einzelfall.',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// One tappable article row inside a grouped list (no leading icon – the title
/// carries it).
class _ArticleRow extends StatelessWidget {
  const _ArticleRow({required this.article});
  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ArticleScreen(article: article)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(article.title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(article.teaser,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right,
                size: 20,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
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
      backgroundColor: groupedBackground(context),
      appBar: AppBar(
        title: const Text('Ratgeber'),
        backgroundColor: groupedBackground(context),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
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
    return GroupedPage(
      title: article.category.label,
      footer: const DisclaimerFooter(),
      children: [
        const SizedBox(height: 6),
        Text(article.title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < article.sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                Text(article.sections[i].heading,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(article.sections[i].body,
                    style: theme.textTheme.bodyLarge),
              ],
            ],
          ),
        ),
        const SectionLabel('Rechtsgrundlagen'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text('Stand: $contentReviewedOn',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
