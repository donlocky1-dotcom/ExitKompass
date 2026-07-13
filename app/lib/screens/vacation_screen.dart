import 'package:exit_engine/exit_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';

/// Calculator for the Urlaubsabgeltung of open vacation days (§ 7 Abs. 4
/// BUrlG), with a pro-rata entitlement helper (§ 5 BUrlG). Inputs are
/// transient; the salary is prefilled from the wizard.
class VacationScreen extends ConsumerStatefulWidget {
  const VacationScreen({super.key});

  @override
  ConsumerState<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends ConsumerState<VacationScreen> {
  late int _grossEuro = ref.read(wizardProvider).grossMonthEuro;
  int _workDays = 5;
  int _remainingDays = 10;

  // Pro-rata helper.
  int _fullYearDays = 30;
  int _monthsEmployed = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = vacationCompensation(
      monthlyGrossCents: _grossEuro * 100,
      remainingDays: _remainingDays,
      workDaysPerWeek: _workDays.clamp(1, 7),
    );
    final proRata = proRataVacationDays(
      fullYearDays: _fullYearDays,
      monthsEmployed: _monthsEmployed,
    );

    final accent = abfindungAccent(context);

    return GroupedPage(
      title: 'Resturlaub abgelten',
      footer: const DisclaimerFooter(),
      children: [
        const SectionLabel('Deine Angaben', topPad: 8),
        AppCard(
          child: Column(
            children: [
              _IntField(
                label: 'Bruttomonatsgehalt (€)',
                value: _grossEuro,
                onChanged: (x) => setState(() => _grossEuro = x),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _IntField(
                      label: 'Arbeitstage / Woche',
                      value: _workDays,
                      onChanged: (x) => setState(() => _workDays = x),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IntField(
                      label: 'Offene Urlaubstage',
                      value: _remainingDays,
                      onChanged: (x) => setState(() => _remainingDays = x),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionLabel('Deine Abgeltung'),
        AppCard(
          child: Column(
            children: [
              StatRow(
                  label: 'Wert pro Urlaubstag',
                  value: euroFromCents(v.dailyValueCents)),
              Divider(height: 14, color: hairline(context)),
              StatRow(
                label: 'Abgeltung gesamt',
                value: euroFromCents(v.totalCents, withDecimals: false),
                accent: accent,
                emphasise: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            shape: const Border(),
            leading: Icon(Icons.calculate_outlined, color: accent),
            title: const Text('Wie viele Tage stehen mir anteilig zu?'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _IntField(
                      label: 'Vollurlaub / Jahr (Tage)',
                      value: _fullYearDays,
                      onChanged: (x) => setState(() => _fullYearDays = x),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _IntField(
                      label: 'Monate beschäftigt',
                      value: _monthsEmployed,
                      onChanged: (x) => setState(() => _monthsEmployed = x),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Anteiliger Anspruch: rund $proRata Tage '
                    '(§ 5 BUrlG, aufgerundet ab halbem Tag).',
                    style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Kannst du deinen Urlaub bis zum Ende nicht mehr nehmen, muss er '
            'ausgezahlt werden (§ 7 Abs. 4 BUrlG). Tageswert nach den letzten '
            '13 Wochen (§ 11 BUrlG). Mindesturlaub 20 Tage bei 5-Tage-Woche '
            '(§ 3 BUrlG) – Vertrag/Tarif können mehr vorsehen. Orientierung, '
            'keine Rechtsberatung.',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Whole-number field that keeps its own controller.
class _IntField extends StatefulWidget {
  const _IntField({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_IntField> createState() => _IntFieldState();
}

class _IntFieldState extends State<_IntField> {
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
