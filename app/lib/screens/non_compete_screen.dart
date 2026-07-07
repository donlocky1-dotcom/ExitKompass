import 'package:exit_engine/exit_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../widgets/disclaimer_footer.dart';

/// Calculator for the Karenzentschädigung of a post-contractual non-compete
/// (§§ 74 ff. HGB). Inputs are transient; the salary is prefilled from the
/// wizard. General information, not legal advice.
class NonCompeteScreen extends ConsumerStatefulWidget {
  const NonCompeteScreen({super.key});

  @override
  ConsumerState<NonCompeteScreen> createState() => _NonCompeteScreenState();
}

class _NonCompeteScreenState extends ConsumerState<NonCompeteScreen> {
  late int _benefitsEuro = ref.read(wizardProvider).grossMonthEuro;
  int _durationMonths = 24;
  int _otherIncomeEuro = 0;
  bool _relocation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = nonCompeteCompensation(
      lastMonthlyBenefitsCents: _benefitsEuro * 100,
      durationMonths: _durationMonths,
      otherMonthlyIncomeCents: _otherIncomeEuro * 100,
      relocationForced: _relocation,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Karenzentschädigung')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Ein nachvertragliches Wettbewerbsverbot bindet dich nur, '
                  'wenn der Arbeitgeber für die Dauer mindestens die Hälfte '
                  'deiner zuletzt bezogenen Bezüge zahlt (§ 74 Abs. 2 HGB).',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                _EuroField(
                  label: 'Letzte Bezüge / Monat (€)',
                  value: _benefitsEuro,
                  onChanged: (v) => setState(() => _benefitsEuro = v),
                ),
                const SizedBox(height: 12),
                _EuroField(
                  label: 'Dauer des Verbots (Monate)',
                  value: _durationMonths,
                  onChanged: (v) => setState(() => _durationMonths = v),
                ),
                const SizedBox(height: 12),
                _EuroField(
                  label: 'Anderweitiges Einkommen / Monat (€)',
                  value: _otherIncomeEuro,
                  onChanged: (v) => setState(() => _otherIncomeEuro = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _relocation,
                  onChanged: (v) => setState(() => _relocation = v),
                  title: const Text('Verbot erzwingt einen Umzug'),
                  subtitle: const Text('erhöht die Anrechnungsgrenze auf 125 %'),
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Mindest-Entschädigung / Monat (50 %)',
                            euroFromCents(r.minMonthlyCompensationCents, withDecimals: false),
                            theme, emphasise: true),
                        if (r.reducedByCredit) ...[
                          _row('Anrechnung / Monat (§ 74c)',
                              '− ${euroFromCents(r.creditPerMonthCents, withDecimals: false)}',
                              theme),
                          _row('Nach Anrechnung / Monat',
                              euroFromCents(r.monthlyCompensationAfterCreditCents,
                                  withDecimals: false),
                              theme),
                        ],
                        const Divider(),
                        _row(
                          'Gesamt über $_durationMonths Monate',
                          r.reducedByCredit
                              ? euroFromCents(r.totalAfterCreditCents, withDecimals: false)
                              : euroFromCents(r.totalCompensationCents, withDecimals: false),
                          theme,
                          emphasise: true,
                        ),
                      ],
                    ),
                  ),
                ),
                if (r.exceedsMaxDuration)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ein Wettbewerbsverbot ist höchstens zwei Jahre '
                            'verbindlich (§ 74a Abs. 1 HGB). Für den darüber '
                            'hinausgehenden Teil bist du in der Regel nicht '
                            'gebunden.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '„Bezüge" sind die zuletzt bezogenen vertragsmäßigen '
                  'Leistungen (auch regelmäßige variable Anteile, Sachbezüge). '
                  'Orientierung, keine Rechtsberatung – im Zweifel Fachanwalt.',
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

  Widget _row(String label, String value, ThemeData theme, {bool emphasise = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value,
              style: (emphasise
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Whole-number field that keeps its own controller.
class _EuroField extends StatefulWidget {
  const _EuroField({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_EuroField> createState() => _EuroFieldState();
}

class _EuroFieldState extends State<_EuroField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_focus.hasFocus && (int.tryParse(_controller.text) ?? -1) != widget.value) {
      _controller.text = widget.value.toString();
    }
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      decoration: InputDecoration(labelText: widget.label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (t) => widget.onChanged(int.tryParse(t) ?? 0),
    );
  }
}
