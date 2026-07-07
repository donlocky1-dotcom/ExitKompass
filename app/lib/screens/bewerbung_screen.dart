import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../content/bewerbung.dart';
import '../pdf/workbook_pdf.dart';
import '../state/workbook.dart';
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
                const _WorkbookExport(),
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
          const SizedBox(height: 12),
          _WorkbookField(questionId: question.id),
        ],
      ),
    );
  }
}

/// Two export buttons: a blank workbook (to print and fill in offline) and a
/// filled workbook (with the saved answers).
class _WorkbookExport extends ConsumerWidget {
  const _WorkbookExport();

  Future<void> _share(WidgetRef ref, {required bool empty}) async {
    final answers = ref.read(workbookProvider);
    final bytes = await buildWorkbookPdf(
      answers: answers,
      empty: empty,
      regularTtf: await rootBundle.load('assets/fonts/DejaVuSans.ttf'),
      boldTtf: await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'),
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: empty ? 'workbook-leer.pdf' : 'workbook-ausgefuellt.pdf',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Workbook als PDF', style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Text(
              'Leer zum Ausdrucken und offline Ausfüllen – oder ausgefüllt mit '
              'deinen gespeicherten Antworten.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Leeres Workbook'),
                  onPressed: () => _share(ref, empty: true),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Ausgefülltes Workbook'),
                  onPressed: () => _share(ref, empty: false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Persisted "your own answer" field (workbook). Saves on change; syncs
/// external resets (e.g. "Daten löschen") when not focused.
class _WorkbookField extends ConsumerStatefulWidget {
  const _WorkbookField({required this.questionId});

  final String questionId;

  @override
  ConsumerState<_WorkbookField> createState() => _WorkbookFieldState();
}

class _WorkbookFieldState extends ConsumerState<_WorkbookField> {
  late final TextEditingController _controller = TextEditingController(
      text: ref.read(workbookProvider)[widget.questionId] ?? '');
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(workbookProvider)[widget.questionId] ?? '';
    if (!_focus.hasFocus && _controller.text != saved) {
      _controller.text = saved;
    }
    return TextField(
      controller: _controller,
      focusNode: _focus,
      minLines: 2,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Deine Antwort (wird lokal gespeichert)',
        alignLabelWithHint: true,
      ),
      onChanged: (t) =>
          ref.read(workbookProvider.notifier).setAnswer(widget.questionId, t),
    );
  }
}
