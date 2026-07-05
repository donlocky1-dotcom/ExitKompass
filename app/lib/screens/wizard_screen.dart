import 'package:exit_engine/exit_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/wizard.dart';
import '../util/labels.dart';
import 'result_screen.dart';

/// Four-step wizard (spec §4 screens 2–5): situation, person & tax, job,
/// offer. Inputs are stored in [wizardProvider].
class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(wizardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Deine Angaben')),
      body: Stepper(
        currentStep: _step,
        onStepTapped: (s) => setState(() => _step = s),
        onStepContinue: () {
          if (_step < 3) {
            setState(() => _step++);
          } else {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ResultScreen()),
            );
          }
        },
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) {
          if (details.stepIndex != _step) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
            children: [
              FilledButton(
                onPressed: details.onStepContinue,
                child: Text(_step == 3 ? 'Szenarien vergleichen' : 'Weiter'),
              ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                      onPressed: details.onStepCancel, child: const Text('Zurück')),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Situation'),
            isActive: _step >= 0,
            content: _SituationStep(data: data),
          ),
          Step(
            title: const Text('Person & Steuer'),
            isActive: _step >= 1,
            content: _PersonStep(data: data),
          ),
          Step(
            title: const Text('Job'),
            isActive: _step >= 2,
            content: _JobStep(data: data),
          ),
          Step(
            title: const Text('Angebot'),
            isActive: _step >= 3,
            content: _OfferStep(data: data),
          ),
        ],
      ),
    );
  }
}

class _SituationStep extends ConsumerWidget {
  const _SituationStep({required this.data});
  final WizardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const options = {
      Situation.kuendigungErhalten: 'Ich habe eine Kündigung erhalten',
      Situation.aufhebungAngeboten: 'Mir wurde ein Aufhebungsvertrag angeboten',
      Situation.ueberlegeZuKuendigen: 'Ich überlege selbst zu kündigen',
      Situation.nurInfo: 'Ich möchte mich nur informieren',
    };
    return RadioGroup<Situation>(
      groupValue: data.situation,
      onChanged: (v) =>
          ref.read(wizardProvider.notifier).update((d) => d.copyWith(situation: v)),
      child: Column(
        children: [
          for (final entry in options.entries)
            RadioListTile<Situation>(
              contentPadding: EdgeInsets.zero,
              value: entry.key,
              title: Text(entry.value),
            ),
        ],
      ),
    );
  }
}

class _PersonStep extends ConsumerWidget {
  const _PersonStep({required this.data});
  final WizardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wizardProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntField(
          label: 'Geburtsjahr',
          value: data.birthYear,
          onChanged: (v) => notifier.update((d) => d.copyWith(birthYear: v)),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TaxClass>(
          initialValue: data.taxClass,
          decoration: const InputDecoration(labelText: 'Steuerklasse'),
          items: [
            for (final c in TaxClass.values)
              DropdownMenuItem(value: c, child: Text('Klasse ${taxClassLabel(c)}')),
          ],
          onChanged: (v) => notifier.update((d) => d.copyWith(taxClass: v)),
        ),
        const SizedBox(height: 12),
        _IntField(
          label: 'Kinder unter 25 (für Pflegeversicherung & ALG)',
          value: data.childrenUnder25,
          onChanged: (v) => notifier.update((d) => d.copyWith(
                childrenUnder25: v,
                hasChildForAlg: v > 0,
                childAllowanceFactor: v.toDouble(),
              )),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: data.hasChildForAlg,
          onChanged: (v) => notifier.update((d) => d.copyWith(hasChildForAlg: v)),
          title: const Text('Erhöhter ALG-Satz (67 %) mit Kind'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: data.churchMember,
          onChanged: (v) => notifier.update((d) => d.copyWith(churchMember: v)),
          title: const Text('Kirchensteuerpflichtig'),
        ),
        DropdownButtonFormField<Bundesland>(
          initialValue: data.state,
          decoration: const InputDecoration(labelText: 'Bundesland'),
          items: [
            for (final b in Bundesland.values)
              DropdownMenuItem(value: b, child: Text(bundeslandLabel(b))),
          ],
          onChanged: (v) => notifier.update((d) => d.copyWith(state: v)),
        ),
        const SizedBox(height: 12),
        _DoubleField(
          label: 'GKV-Zusatzbeitrag (%)',
          value: data.healthAdditionalRatePercent,
          onChanged: (v) =>
              notifier.update((d) => d.copyWith(healthAdditionalRatePercent: v)),
        ),
      ],
    );
  }
}

class _JobStep extends ConsumerWidget {
  const _JobStep({required this.data});
  final WizardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wizardProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntField(
          label: 'Bruttomonatsgehalt (€)',
          value: data.grossMonthEuro,
          onChanged: (v) => notifier.update((d) => d.copyWith(grossMonthEuro: v)),
        ),
        const SizedBox(height: 12),
        _IntField(
          label: 'Sonderzahlungen pro Jahr (€, z. B. 13. Gehalt)',
          value: data.annualExtrasEuro,
          onChanged: (v) => notifier.update((d) => d.copyWith(annualExtrasEuro: v)),
        ),
        const SizedBox(height: 12),
        _DateField(
          label: 'Eintrittsdatum',
          value: data.entryDate,
          onChanged: (v) => notifier.update((d) => d.copyWith(entryDate: v)),
        ),
        _DateField(
          label: 'Frühestes reguläres Ende (ordentliche Kündigungsfrist)',
          value: data.regularEndDate,
          onChanged: (v) => notifier.update((d) => d.copyWith(regularEndDate: v)),
        ),
      ],
    );
  }
}

class _OfferStep extends ConsumerWidget {
  const _OfferStep({required this.data});
  final WizardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wizardProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntField(
          label: 'Abfindung brutto (€)',
          value: data.severanceGrossEuro,
          onChanged: (v) => notifier.update((d) => d.copyWith(severanceGrossEuro: v)),
        ),
        const SizedBox(height: 12),
        _DateField(
          label: 'Austrittsdatum laut Angebot',
          value: data.exitDate,
          onChanged: (v) => notifier.update((d) => d.copyWith(exitDate: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: data.paidRelease,
          onChanged: (v) => notifier.update((d) => d.copyWith(paidRelease: v)),
          title: const Text('Bezahlte Freistellung bis zum regulären Ende'),
        ),
        const SizedBox(height: 12),
        _IntField(
          label: 'Resturlaub-/Bonus-Abgeltung (€)',
          value: data.settlementsEuro,
          onChanged: (v) => notifier.update((d) => d.copyWith(settlementsEuro: v)),
        ),
        const SizedBox(height: 12),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 12, label: Text('12 Mon.')),
            ButtonSegment(value: 24, label: Text('24 Mon.')),
            ButtonSegment(value: 36, label: Text('36 Mon.')),
          ],
          selected: {data.horizonMonths},
          onSelectionChanged: (s) =>
              notifier.update((d) => d.copyWith(horizonMonths: s.first)),
        ),
        const SizedBox(height: 4),
        Text('Betrachtungszeitraum', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _IntField extends StatelessWidget {
  const _IntField({required this.label, required this.value, required this.onChanged});
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

class _DoubleField extends StatelessWidget {
  const _DoubleField({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (t) => onChanged(double.tryParse(t.replaceAll(',', '.')) ?? value),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    // Numeric-only pattern → no locale symbol data needed.
    final fmt = DateFormat('dd.MM.yyyy');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: Text(fmt.format(value)),
      trailing: const Icon(Icons.calendar_today, size: 20),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(1980),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
