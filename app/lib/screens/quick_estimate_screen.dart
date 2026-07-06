import 'package:exit_engine/exit_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../widgets/disclaimer_footer.dart';
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
  int _grossMonthEuro = 4500;
  int _tenureYears = 8;
  int _age = 42;
  NegotiationStrength _strength = NegotiationStrength.standard;
  bool _smallBusiness = false;

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

    return Scaffold(
      appBar: AppBar(title: const Text('Abfindung schätzen')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('In 30 Sekunden zur Bandbreite', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _NumberField(
                  label: 'Bruttomonatsgehalt (€)',
                  value: _grossMonthEuro,
                  onChanged: (v) => setState(() => _grossMonthEuro = v),
                ),
                const SizedBox(height: 12),
                _NumberField(
                  label: 'Beschäftigungsjahre',
                  value: _tenureYears,
                  onChanged: (v) => setState(() => _tenureYears = v),
                ),
                const SizedBox(height: 12),
                _NumberField(
                  label: 'Alter',
                  value: _age,
                  onChanged: (v) => setState(() => _age = v),
                ),
                const SizedBox(height: 16),
                Text('Verhandlungsposition', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                SegmentedButton<NegotiationStrength>(
                  segments: const [
                    ButtonSegment(value: NegotiationStrength.schwach, label: Text('Schwach')),
                    ButtonSegment(value: NegotiationStrength.standard, label: Text('Standard')),
                    ButtonSegment(value: NegotiationStrength.stark, label: Text('Stark')),
                  ],
                  selected: {_strength},
                  onSelectionChanged: (s) => setState(() => _strength = s.first),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _smallBusiness,
                  onChanged: (v) => setState(() => _smallBusiness = v),
                  title: const Text('Kleinbetrieb (unter 10 Mitarbeiter)'),
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Realistische Bandbreite',
                            style: theme.textTheme.labelLarge),
                        Text(
                          '${euroFromCents(e.lowCents, withDecimals: false)} – '
                          '${euroFromCents(e.highCents, withDecimals: false)}',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mittelwert ${euroFromCents(e.pointCents, withDecimals: false)} · '
                          'Regelabfindung (§ 1a) ${euroFromCents(e.regelabfindungCents, withDecimals: false)}'
                          '${e.cappedByKschG10 ? ' · gekappt auf ${e.kschG10CapMonths} Monatsgehälter (§ 10 KSchG)' : ''}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Orientierung nach der Faustformel – kein Rechtsanspruch. Die '
                  'tatsächliche Höhe hängt vom Einzelfall ab.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _startDetailed,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Detaillierten Netto-Vergleich starten'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
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

class _NumberField extends StatelessWidget {
  const _NumberField({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (t) => onChanged(int.tryParse(t) ?? 0),
    );
  }
}
