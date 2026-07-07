import 'package:flutter/material.dart';

import '../content/bewerbung.dart';
import '../widgets/disclaimer_footer.dart';

/// On-device interview preparation: STAR method + a question bank grouped by
/// theme. General guidance, not individual application coaching.
class BewerbungScreen extends StatelessWidget {
  const BewerbungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bewerbungstraining')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Die STAR-Methode', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(starMethodExplainer, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Grundhaltung: Verkauf dich über deinen Wert',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final p in valueSellingPrinciples)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          Text(p.body, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                for (final category in InterviewCategory.values) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(category.label, style: theme.textTheme.titleMedium),
                  ),
                  for (final q in interviewQuestions.where((q) => q.category == category))
                    _QuestionTile(question: q),
                ],
                const SizedBox(height: 12),
                Text('Brainteaser & Case-Fragen', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(brainteaserIntro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                for (final s in brainteaserSteps)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          Text(s.body, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Stand: $bewerbungReviewedOn. Allgemeine Tipps, keine '
                  'individuelle Bewerbungs- oder Karriereberatung.',
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

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({required this.question});

  final InterviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        title: Text('„${question.question}"'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('So gehst du ran', style: theme.textTheme.labelLarge),
          ),
          const SizedBox(height: 4),
          Text(question.approach, style: theme.textTheme.bodyMedium),
          if (question.tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final tip in question.tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(tip, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
