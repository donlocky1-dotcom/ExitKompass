import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../content/bewerbung.dart';
import '../pdf/workbook_pdf.dart';
import '../state/workbook.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';
import 'coach_screen.dart';
import 'unterlagen_screen.dart';

/// On-device interview preparation: STAR method + a question bank grouped by
/// theme. General guidance, not individual application coaching.
class BewerbungScreen extends StatelessWidget {
  const BewerbungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = bewerbenAccent(context);
    return GroupedPage(
      title: 'Bewerbungstraining',
      footer: const DisclaimerFooter(),
      children: [
        const SectionLabel('Werkzeuge', topPad: 8),
        AppGroup(children: const [
          _CoachRow(),
          _UnterlagenRow(),
        ]),
        const SectionLabel('Die STAR-Methode'),
        AppCard(
          child: Text(starMethodExplainer, style: theme.textTheme.bodyMedium),
        ),
        const SectionLabel('Workbook als PDF'),
        const _WorkbookExport(),
        const SizedBox(height: 18),
        Text('Grundhaltung: Verkauf dich über deinen Wert',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final p in valueSellingPrinciples)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(p.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        for (final category in InterviewCategory.values) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(category.label,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          for (final q in interviewQuestions.where((q) => q.category == category))
            _QuestionTile(question: q),
        ],
        const SizedBox(height: 18),
        Text('Brainteaser & Case-Fragen',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(brainteaserIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        for (final s in brainteaserSteps)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(s.body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Stand: $bewerbungReviewedOn. Allgemeine Tipps, keine individuelle '
            'Bewerbungs- oder Karriereberatung.',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Entry point to the interview chat simulation.
class _CoachRow extends StatelessWidget {
  const _CoachRow();

  @override
  Widget build(BuildContext context) {
    return AppRow(
      accent: bewerbenAccent(context),
      icon: Icons.forum_outlined,
      title: 'Gesprächssimulation',
      badge: 'KI',
      subtitle: 'Übe das Bewerbungsgespräch im Dialog',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CoachScreen()),
      ),
    );
  }
}

/// Entry point to the CV ↔ job-ad document check.
class _UnterlagenRow extends StatelessWidget {
  const _UnterlagenRow();

  @override
  Widget build(BuildContext context) {
    return AppRow(
      accent: bewerbenAccent(context),
      icon: Icons.description_outlined,
      title: 'Unterlagen-Check',
      badge: 'KI',
      subtitle: 'Lebenslauf mit der Stellenanzeige abgleichen',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const UnterlagenScreen()),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          shape: const Border(),
          leading: Icon(Icons.help_outline, color: bewerbenAccent(context)),
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workbook als PDF', style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            'Leer zum Ausdrucken und offline Ausfüllen – oder ausgefüllt mit '
            'deinen gespeicherten Antworten.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
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
    // Only sync EXTERNAL changes (e.g. "Daten löschen"), and never while the
    // field is focused. Reassigning controller.text during a rebuild on every
    // keystroke breaks IME composition on iOS Safari (characters get eaten),
    // so we listen instead of watch – typing no longer rebuilds the field.
    ref.listen<String>(
      workbookProvider.select((m) => m[widget.questionId] ?? ''),
      (previous, next) {
        if (!_focus.hasFocus && _controller.text != next) {
          _controller.text = next;
        }
      },
    );
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
