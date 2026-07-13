import 'package:exit_engine/exit_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/intake.dart';
import '../state/navigation.dart';
import '../state/wizard.dart';
import '../util/format.dart';
import '../util/labels.dart';
import '../widgets/ui_kit.dart';
import 'root_shell.dart';

/// Four-step wizard (spec §4 screens 2–5): situation, person & tax, job,
/// offer. Inputs are stored in [wizardProvider].
class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  /// Set once the user tried to finish without the core figures – shows the
  /// missing-fields hint.
  bool _showErrors = false;

  /// Done: only once the core figures are present. Marks the data as entered
  /// (so the hub shows real numbers instead of a prompt) and shows the results
  /// in the Abfindung area of the shell.
  void _finish() {
    final data = ref.read(wizardProvider);
    if (!data.hasCoreData) {
      setState(() => _showErrors = true);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Bitte fülle noch die markierten Pflichtangaben aus.'),
        ));
      return;
    }
    ref.read(intakeProvider.notifier).complete();
    ref.read(rootTabProvider.notifier).state = RootTab.abfindung;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.popUntil((r) => r.isFirst);
    } else {
      nav.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const RootShell()),
      );
    }
  }

  /// A short list of the still-missing core fields, for the hint under the
  /// button.
  String _missingCore(WizardData d) {
    final missing = <String>[
      if (d.grossMonthEuro <= 0) 'Bruttomonatsgehalt',
      if (d.birthYear <= 1900) 'Geburtsjahr',
      if (d.entryDate.year <= 1900) 'Eintrittsdatum',
      if (d.exitDate.year <= 1900) 'Austrittsdatum',
    ];
    return missing.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(wizardProvider);
    final theme = Theme.of(context);
    final showHint = _showErrors && !data.hasCoreData;
    return Scaffold(
      backgroundColor: groupedBackground(context),
      appBar: AppBar(
        backgroundColor: groupedBackground(context),
        surfaceTintColor: Colors.transparent,
        title: const Text('Deine Angaben'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Text(
              'Für die Abfindungs- und Steuer-Analyse brauchen wir zuerst deine '
              'Angaben. Pflicht sind Gehalt, Geburtsjahr und die beiden Daten – '
              'der Rest ist optional.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          const SectionLabel('Situation'),
          _Section(child: _SituationStep(data: data)),
          const SectionLabel('Person & Steuer'),
          _Section(child: _PersonStep(data: data, showErrors: _showErrors)),
          const SectionLabel('Job'),
          _Section(child: _JobStep(data: data, showErrors: _showErrors)),
          const SectionLabel('Angebot'),
          _Section(child: _OfferStep(data: data)),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _finish,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Szenarien vergleichen'),
          ),
          if (showHint)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
              child: Text(
                'Bitte noch ausfüllen: ${_missingCore(data)}.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

/// A white rounded panel that groups one section's fields on the grouped
/// background, so the long inputs form reads as tidy blocks instead of a
/// step-by-step funnel.
class _Section extends StatelessWidget {
  const _Section({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: groupedCard(context),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
        child: child,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<Situation>(
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
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<KuendigungsArt>(
          initialValue: data.kuendigungsArt,
          decoration: const InputDecoration(labelText: 'Kündigungsgrund (falls bekannt)'),
          items: [
            for (final k in KuendigungsArt.values)
              DropdownMenuItem(value: k, child: Text(k.label)),
          ],
          onChanged: (v) =>
              ref.read(wizardProvider.notifier).update((d) => d.copyWith(kuendigungsArt: v)),
        ),
      ],
    );
  }
}

class _PersonStep extends ConsumerWidget {
  const _PersonStep({required this.data, this.showErrors = false});
  final WizardData data;
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wizardProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntField(
          label: 'Geburtsjahr',
          value: data.birthYear,
          errorText: showErrors && data.birthYear <= 1900 ? 'Pflichtangabe' : null,
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
  const _JobStep({required this.data, this.showErrors = false});
  final WizardData data;
  final bool showErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wizardProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IntField(
          label: 'Bruttomonatsgehalt (€)',
          value: data.grossMonthEuro,
          errorText:
              showErrors && data.grossMonthEuro <= 0 ? 'Pflichtangabe' : null,
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
          errorText: showErrors && data.entryDate.year <= 1900
              ? 'Bitte wählen'
              : null,
          onChanged: (v) => notifier.update((d) => d.copyWith(entryDate: v)),
        ),
        const SizedBox(height: 12),
        _NoticePeriodCard(data: data),
        const SizedBox(height: 8),
        _DateField(
          label: 'Reguläres Ende der Kündigungsfrist (genaues Datum)',
          value: data.regularEndDate,
          errorText: showErrors && data.regularEndDate.year <= 1900
              ? 'Bitte wählen'
              : null,
          onChanged: (v) => notifier.update((d) => d.copyWith(regularEndDate: v)),
        ),
      ],
    );
  }
}

/// Notice-period helper: shows the statutory § 622 suggestion from tenure and
/// lets the user pick the period as whole months (which sets the exact end
/// date). Longer contractual/collective-agreement periods are entered as the
/// exact date below – they cannot be modelled automatically.
class _NoticePeriodCard extends ConsumerWidget {
  const _NoticePeriodCard({required this.data});
  final WizardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(wizardProvider.notifier);
    final theme = Theme.of(context);
    final anchor = data.noticeDate;
    final statMonths = statutoryNoticePeriodMonths(data.tenureYears);
    final selectedMonths = noticeMonthsBetween(anchor, data.regularEndDate);
    const options = [1, 2, 3, 4, 6, 7];

    void setMonths(int m) => notifier
        .update((d) => d.copyWith(regularEndDate: noticeEndDate(anchor, m)));

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kündigungsfrist', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Gesetzlich (§ 622 BGB) bei ${data.tenureYears} Jahren '
              'Betriebszugehörigkeit: $statMonths Monat(e) zum Monatsende.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final m in options)
                  ChoiceChip(
                    label: Text('$m Mon.'),
                    selected: selectedMonths == m,
                    onSelected: (_) => setMonths(m),
                  ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setMonths(statMonths),
                icon: const Icon(Icons.gavel, size: 16),
                label: Text('§ 622 übernehmen ($statMonths Mon.)'),
              ),
            ),
            Text(
              'Im Arbeits- oder Tarifvertrag (z. B. VAA in der Chemie) sind oft '
              'längere, nach Betriebszugehörigkeit gestaffelte Fristen vereinbart. '
              'Maßgeblich ist, was in deinem Vertrag steht – im Zweifel bei '
              'Gewerkschaft/Berufsverband erfragen und unten das genaue Enddatum '
              'eintragen.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
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
        const _SeveranceEstimator(),
        const SizedBox(height: 12),
        const _SeveranceField(),
        const SizedBox(height: 12),
        const _SeveranceTimingCard(),
        const SizedBox(height: 12),
        _DateField(
          label: 'Zugang der Kündigung / des Angebots',
          value: data.noticeDate,
          onChanged: (v) => notifier.update((d) => d.copyWith(noticeDate: v)),
        ),
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
        Builder(builder: (context) {
          final impliedByGround =
              data.kuendigungsArt == KuendigungsArt.betriebsbedingt;
          return SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: data.anticipatesOperationalDismissal || impliedByGround,
            // Already implied when the ground is "betriebsbedingt" – lock it on
            // so the two inputs can't contradict each other.
            onChanged: impliedByGround
                ? null
                : (v) => notifier.update(
                    (d) => d.copyWith(anticipatesOperationalDismissal: v)),
            title: const Text(
                'Aufhebungsvertrag nimmt eine betriebsbedingte Kündigung vorweg'),
            subtitle: Text(impliedByGround
                ? 'Bei Kündigungsgrund „betriebsbedingt" ist das bereits '
                    'angenommen: Zusammen mit gewahrter Kündigungsfrist und '
                    'maßvoller Abfindung (0,25–0,5 Monatsgehälter je Jahr) '
                    'entfällt die Sperrzeit meist (§ 159 SGB III).'
                : 'Der Arbeitgeber hätte sonst betriebsbedingt gekündigt. '
                    'Zusammen mit gewahrter Kündigungsfrist und maßvoller '
                    'Abfindung (0,25–0,5 Monatsgehälter je Jahr) entfällt die '
                    'Sperrzeit meist (§ 159 SGB III).'),
          );
        }),
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

/// Compares the net severance when paid this year vs. next year (M8).
/// Moving the payout into a low-income year usually lowers the tax. The two
/// taxable-income inputs are transient UI state (prefilled from the salary).
class _SeveranceTimingCard extends ConsumerStatefulWidget {
  const _SeveranceTimingCard();

  @override
  ConsumerState<_SeveranceTimingCard> createState() => _SeveranceTimingCardState();
}

class _SeveranceTimingCardState extends ConsumerState<_SeveranceTimingCard> {
  late int _thisYearEuro = ref.read(wizardProvider).grossMonthEuro * 12;
  int _nextYearEuro = 0;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(wizardProvider);
    final theme = Theme.of(context);
    if (data.severanceGrossEuro == 0) return const SizedBox.shrink();

    final c = compareSeveranceTiming(
      severanceCents: data.severanceGrossEuro * 100,
      taxableIncomeThisYearCents: _thisYearEuro * 100,
      taxableIncomeNextYearCents: _nextYearEuro * 100,
      splitting: data.taxClass == TaxClass.iii,
    );

    final String verdict;
    final Color verdictColor;
    if (c.nextYearBetter) {
      verdict = 'Auszahlung nächstes Jahr bringt '
          '${euroFromCents(c.differenceCents, withDecimals: false)} mehr netto.';
      verdictColor = Colors.green.shade700;
    } else if (c.gainNextYearCents < 0) {
      verdict = 'Auszahlung dieses Jahr bringt '
          '${euroFromCents(c.differenceCents, withDecimals: false)} mehr netto.';
      verdictColor = theme.colorScheme.primary;
    } else {
      verdict = 'Bei diesen Angaben macht das Timing keinen Unterschied.';
      verdictColor = theme.colorScheme.onSurfaceVariant;
    }

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Auszahlung timen', style: theme.textTheme.titleSmall),
            Text(
              'Wann bleibt netto mehr von der Abfindung – dieses oder nächstes Jahr?',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _IntField(
                    label: 'zvE dieses Jahr (€)',
                    value: _thisYearEuro,
                    onChanged: (v) => setState(() => _thisYearEuro = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _IntField(
                    label: 'zvE nächstes Jahr (€)',
                    value: _nextYearEuro,
                    onChanged: (v) => setState(() => _nextYearEuro = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dieses Jahr netto: '
                '${euroFromCents(c.thisYear.netSeveranceCents, withDecimals: false)}'),
            Text('Nächstes Jahr netto: '
                '${euroFromCents(c.nextYear.netSeveranceCents, withDecimals: false)}'),
            const SizedBox(height: 4),
            Text(verdict,
                style: theme.textTheme.titleSmall?.copyWith(color: verdictColor)),
            const SizedBox(height: 4),
            Text(
              'zvE = zu versteuerndes Einkommen ohne Abfindung. Orientierung, '
              'keine Steuerberatung.',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Estimates a negotiable severance range (M6) from the entered salary,
/// tenure and age, and lets the user apply the midpoint to the severance
/// field. The negotiation strength is transient UI state.
class _SeveranceEstimator extends ConsumerStatefulWidget {
  const _SeveranceEstimator();

  @override
  ConsumerState<_SeveranceEstimator> createState() => _SeveranceEstimatorState();
}

class _SeveranceEstimatorState extends ConsumerState<_SeveranceEstimator> {
  late NegotiationStrength _strength =
      ref.read(wizardProvider).kuendigungsArt.suggestedStrength;
  bool _smallBusiness = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(wizardProvider);
    final theme = Theme.of(context);
    final tenureYears = data.tenureYears;
    final age = data.ageAtExit;
    // Needs the salary and the dates to say anything meaningful.
    final ready = data.hasCoreData;

    final estimate = data.estimateSeveranceRange(
      strength: _strength,
      smallBusiness: _smallBusiness,
    );

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abfindung schätzen', style: theme.textTheme.titleSmall),
            Text(
              ready
                  ? 'Höhe noch offen? Schätze eine realistische Bandbreite '
                      '($tenureYears Jahre, Alter $age).'
                  : 'Trage oben Gehalt, Geburtsjahr und die beiden Daten ein – '
                      'dann schätzen wir die Bandbreite.',
              style: theme.textTheme.bodySmall,
            ),
            if (ready) ...[
              const SizedBox(height: 8),
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
                dense: true,
                value: _smallBusiness,
                onChanged: (v) => setState(() => _smallBusiness = v),
                title: const Text('Kleinbetrieb (unter 10 Mitarbeiter)'),
              ),
              const SizedBox(height: 4),
              Text(
                'Realistische Spanne: '
                '${euroFromCents(estimate.lowCents, withDecimals: false)} – '
                '${euroFromCents(estimate.highCents, withDecimals: false)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
              Text(
                'Regelabfindung (§ 1a, Faktor 0,5): '
                '${euroFromCents(estimate.regelabfindungCents, withDecimals: false)}'
                '${estimate.cappedByKschG10 ? ' · gekappt auf ${estimate.kschG10CapMonths} Monatsgehälter (§ 10 KSchG)' : ''}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: const Text('Mittelwert übernehmen'),
                  onPressed: () => ref.read(wizardProvider.notifier).update(
                        (d) => d.copyWith(
                            severanceGrossEuro: (estimate.pointCents / 100).round()),
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Severance amount field that syncs external updates (e.g. from the
/// estimator's "übernehmen") into the text box when it is not focused.
class _SeveranceField extends ConsumerStatefulWidget {
  const _SeveranceField();

  @override
  ConsumerState<_SeveranceField> createState() => _SeveranceFieldState();
}

class _SeveranceFieldState extends ConsumerState<_SeveranceField> {
  late final TextEditingController _controller = TextEditingController(
      text: ref.read(wizardProvider).severanceGrossEuro == 0
          ? ''
          : ref.read(wizardProvider).severanceGrossEuro.toString());
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(wizardProvider).severanceGrossEuro;
    if (!_focus.hasFocus && (int.tryParse(_controller.text) ?? -1) != value) {
      _controller.text = value == 0 ? '' : value.toString();
    }
    return TextFormField(
      controller: _controller,
      focusNode: _focus,
      decoration: const InputDecoration(
          labelText: 'Abfindung brutto (€)',
          hintText: 'Angebot – oder oben schätzen lassen'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (t) => ref
          .read(wizardProvider.notifier)
          .update((d) => d.copyWith(severanceGrossEuro: int.tryParse(t) ?? 0)),
    );
  }
}

class _IntField extends StatelessWidget {
  const _IntField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      // Blank rather than a fake "0" so the form starts empty.
      initialValue: value == 0 ? '' : value.toString(),
      decoration: InputDecoration(labelText: label, errorText: errorText),
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
  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Numeric-only pattern → no locale symbol data needed.
    final fmt = DateFormat('dd.MM.yyyy');
    final isSet = value.year > 1900;
    final Color? subColor = errorText != null
        ? theme.colorScheme.error
        : (isSet ? null : theme.colorScheme.onSurfaceVariant);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        errorText ?? (isSet ? fmt.format(value) : 'Noch nicht gewählt'),
        style: theme.textTheme.bodySmall?.copyWith(color: subColor),
      ),
      trailing: Icon(Icons.calendar_today,
          size: 20, color: errorText != null ? theme.colorScheme.error : null),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: isSet ? value : DateTime(now.year, now.month),
          firstDate: DateTime(1980),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}
