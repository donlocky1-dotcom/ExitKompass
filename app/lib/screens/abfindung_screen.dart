import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coach/coach_engine.dart';
import '../state/intake.dart';
import '../state/wizard.dart';
import '../util/format.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';
import 'coach_screen.dart';
import 'finanzen_screen.dart';
import 'quick_estimate_screen.dart';
import 'tools_screen.dart';
import 'wizard_screen.dart';

/// The money/exit pillar: what you walk away with, netto gerechnet. Leads with
/// the best-scenario figure, then the calculators, the KI negotiation practice
/// and the extra tools. Every deeper screen is reused as-is.
class AbfindungScreen extends ConsumerWidget {
  const AbfindungScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(wizardProvider);
    final intake = ref.watch(intakeProvider);
    final accent = abfindungAccent(context);

    void push(Widget screen) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));

    final Widget hero;
    if (intake.done) {
      final result = data.compute();
      final best = result.bestScenario;
      final bestNet = result.scenarios[best]!.cumulativeNetCents;
      final delta = result.deltaToBaselineCents(best);
      hero = AppHero(
        accent: accent,
        eyebrow: 'Dein bestes Szenario',
        headline: euroFromCents(bestNet, withDecimals: false),
        caption: 'kumuliert netto über ${result.horizonMonths} Monate',
        big: true,
        onTap: () => push(const FinanzenScreen()),
        trailing: delta == 0
            ? null
            : _DeltaPill(
                text: '${signedEuroFromCents(delta)} gegenüber „bleiben"',
                positive: delta >= 0,
              ),
      );
    } else {
      hero = AppHero(
        accent: accent,
        eyebrow: 'Loslegen',
        headline: 'Rechne deine Szenarien durch',
        caption: 'Ein paar Angaben genügen – Gehalt, Frist, Abfindung.',
        onTap: () => push(const WizardScreen()),
      );
    }

    return HubScaffold(
      title: 'Abfindung',
      slivers: [
        hero,
        const SectionLabel('Rechnen'),
        AppGroup(children: [
          AppRow(
            accent: accent,
            icon: Icons.bar_chart_rounded,
            title: 'Netto-Szenarien & Fristen',
            subtitle: intake.done
                ? 'Bleiben · Aufhebung · Kündigung im Vergleich'
                : 'Zuerst deine Angaben – dann der Vergleich',
            // Ask for the data when it's needed: no analysis without inputs.
            onTap: () =>
                push(intake.done ? const FinanzenScreen() : const WizardScreen()),
          ),
          AppRow(
            accent: accent,
            icon: Icons.bolt_outlined,
            title: 'Schnell-Check',
            subtitle: 'Abfindung in 30 Sekunden schätzen',
            onTap: () => push(const QuickEstimateScreen()),
          ),
          // Editing only once data exists – for a first run the analysis rows
          // above already lead into the input form.
          if (intake.done)
            AppRow(
              accent: accent,
              icon: Icons.tune_rounded,
              title: 'Angaben bearbeiten',
              subtitle: 'Gehalt, Kündigungsfrist, Steuer – für den Vergleich',
              onTap: () => push(const WizardScreen()),
            ),
        ]),
        const SectionLabel('Üben & mehr'),
        AppGroup(children: [
          AppRow(
            accent: accent,
            icon: Icons.forum_outlined,
            title: 'Verhandlung üben',
            badge: 'KI',
            subtitle: 'Rollenspiel mit der Personalleitung',
            onTap: () =>
                push(const CoachScreen(initialMode: CoachMode.negotiation)),
          ),
          AppRow(
            accent: accent,
            icon: Icons.calculate_outlined,
            title: 'Weitere Rechner',
            subtitle: 'Resturlaub · Karenzentschädigung · Zeugnis',
            onTap: () => push(const ToolsScreen()),
          ),
        ]),
        const DisclaimerNote(),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({required this.text, required this.positive});
  final String text;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = positive
        ? (theme.brightness == Brightness.dark
            ? const Color(0xFF46C98B)
            : const Color(0xFF1F9D5A))
        : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 15, color: color),
          const SizedBox(width: 6),
          Text(text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
