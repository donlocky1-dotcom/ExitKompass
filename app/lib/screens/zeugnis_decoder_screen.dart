import 'package:flutter/material.dart';

import '../content/zeugnis.dart';
import '../widgets/disclaimer_footer.dart';

/// Decodes the coded language of an Arbeitszeugnis. General information
/// (§ 109 GewO), grouped by part of the reference.
class ZeugnisDecoderScreen extends StatelessWidget {
  const ZeugnisDecoderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Zeugnis-Decoder')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Arbeitszeugnisse müssen wohlwollend sein (§ 109 GewO), '
                  'deshalb steckt die eigentliche Bewertung oft in festen '
                  'Formulierungen. Hier die gängigen Codes – als Orientierung, '
                  'nicht als rechtliche Bewertung deines Zeugnisses.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                for (final category in ZeugnisCategory.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(category.label, style: theme.textTheme.titleMedium),
                  ),
                  for (final p in zeugnisPhrases.where((p) => p.category == category))
                    _PhraseCard(phrase: p),
                ],
                const SizedBox(height: 8),
                Text(
                  'Stand: $zeugnisReviewedOn. Konventionen der '
                  'Arbeitsgerichtsbarkeit, kein Gesetzestext. Im Zweifel ein '
                  'Fachanwalt prüfen lassen.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({required this.phrase});

  final ZeugnisPhrase phrase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (phrase.grade != null) ...[
              _GradeBadge(grade: phrase.grade!),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('„${phrase.phrase}"',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 4),
                  Text(phrase.meaning, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});

  final int grade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1–2 good (green), 3–4 mid (amber), 5–6 poor (red).
    final Color color = grade <= 2
        ? Colors.green.shade700
        : (grade <= 4 ? Colors.amber.shade800 : theme.colorScheme.error);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Text('$grade',
          style: theme.textTheme.titleMedium?.copyWith(
              color: color, fontWeight: FontWeight.bold)),
    );
  }
}
