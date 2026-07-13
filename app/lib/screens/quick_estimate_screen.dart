import 'package:exit_engine/exit_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';
import 'wizard_screen.dart';

/// 30-second quick estimate (the competitors' entry funnel): a fast
/// severance range from four inputs, with a CTA into the full net
/// comparison. Reachable directly from onboarding.
class QuickEstimateScreen extends ConsumerStatefulWidget {
  const QuickEstimateScreen({super.key});

  @override
  ConsumerState<QuickEstimateScreen> createState() => _QuickEstimateScreenState();
}

class _QuickEstimateScreenState extends ConsumerState<QuickEstimateScreen> {
  // Start empty – no example figures.
  int _grossMonthEuro = 0;
  int _tenureYears = 0;
  int _age = 0;
  NegotiationStrength _strength = NegotiationStrength.standard;
  bool _smallBusiness = false;

  bool get _ready => _grossMonthEuro > 0 && _tenureYears > 0 && _age > 0;

  SeveranceEstimate get _estimate => estimateSeverance(
        grossMonthCents: _grossMonthEuro * 100,
        tenureYears: _tenureYears,
        age: _age,
        strength: _strength,
        smallBusiness: _smallBusiness,
      );

  void _startDetailed() {
    final e = _estimate;
    final now = DateTime.now();
    ref.read(wizardProvider.notifier).update(
          (d) => d.copyWith(
            grossMonthEuro: _grossMonthEuro,
            birthYear: now.year - _age,
            entryDate: DateTime(now.year - _tenureYears, now.month, 1),
            severanceGrossEuro: (e.pointCents / 100).round(),
          ),
        );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WizardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = _estimate;

    final accent = abfindungAccent(context);

    return GroupedPage(
      title: 'Abfindung schätzen',
      footer: const DisclaimerFooter(),
      children: [
        AppHero(
          accent: accent,
          eyebrow: 'Schnell-Check',
          headline: _ready
              ? '${euroFromCents(e.lowCents, withDecimals: false)} – '
                  '${euroFromCents(e.highCents, withDecimals: false)}'
              : '—',
          caption: _ready
              ? 'Realistische Bandbreite · Mittelwert '
                  '${euroFromCents(e.pointCents, withDecimals: false)}'
              : 'Realistische Bandbreite – trage deine Werte ein',
        ),
        const SectionLabel('Deine Eckdaten'),
        AppCard(
          child: Column(
            children: [
              _NumberField(
                label: 'Bruttomonatsgehalt (€)',
                value: _grossMonthEuro,
                onChanged: (v) => setState(() => _grossMonthEuro = v),
              ),
              const SizedBox(height: 6),
              _NumberField(
                label: 'Beschäftigungsjahre',
                value: _tenureYears,
                onChanged: (v) => setState(() => _tenureYears = v),
              ),
              const SizedBox(height: 6),
              _NumberField(
                label: 'Alter',
                value: _age,
                onChanged: (v) => setState(() => _age = v),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child:
                    Text('Verhandlungsposition', style: theme.textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<NegotiationStrength>(
                  segments: const [
                    ButtonSegment(value: NegotiationStrength.schwach, label: Text('Schwach')),
                    ButtonSegment(value: NegotiationStrength.standard, label: Text('Standard')),
                    ButtonSegment(value: NegotiationStrength.stark, label: Text('Stark')),
                  ],
                  selected: {_strength},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _strength = s.first),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _smallBusiness,
                onChanged: (v) => setState(() => _smallBusiness = v),
                title: const Text('Kleinbetrieb (unter 10 Mitarbeiter)'),
              ),
            ],
          ),
        ),
        const SectionLabel('So kommt die Zahl zustande'),
        AppCard(
          child: Text(
            _ready
                ? 'Regelabfindung (§ 1a) '
                    '${euroFromCents(e.regelabfindungCents, withDecimals: false)}'
                    '${e.cappedByKschG10 ? ' · gekappt auf ${e.kschG10CapMonths} Monatsgehälter (§ 10 KSchG)' : ''}. '
                    'Orientierung nach der Faustformel – kein Rechtsanspruch, die '
                    'tatsächliche Höhe hängt vom Einzelfall ab.'
                : 'Trage Gehalt, Beschäftigungsjahre und Alter ein – dann '
                    'schätzen wir die Bandbreite nach der Faustformel '
                    '(Orientierung, kein Rechtsanspruch).',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _startDetailed,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Detaillierten Netto-Vergleich starten'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Blank rather than a fake "0" so the check starts empty.
      initialValue: value == 0 ? '' : value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (t) => onChanged(int.tryParse(t) ?? 0),
    );
  }
}
