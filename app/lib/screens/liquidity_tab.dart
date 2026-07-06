import 'package:exit_engine/exit_engine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../util/labels.dart';

/// Liquidity / bridge tab (M7): "Reicht mein Geld bis zum neuen Job?".
/// Projects savings + the chosen scenario's net income minus monthly
/// expenses, and shows when the money runs out.
class LiquidityTab extends ConsumerStatefulWidget {
  const LiquidityTab({this.initialScenario, super.key});

  /// Scenario selected on first build; `null` follows the best scenario.
  final ScenarioType? initialScenario;

  @override
  ConsumerState<LiquidityTab> createState() => _LiquidityTabState();
}

class _LiquidityTabState extends ConsumerState<LiquidityTab> {
  /// null → follow the best scenario.
  late ScenarioType? _scenario = widget.initialScenario;

  static const _order = [
    ScenarioType.kuendigungAg,
    ScenarioType.aufhebungsvertrag,
    ScenarioType.eigenkuendigung,
    ScenarioType.bleiben,
  ];

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(wizardProvider);
    final result = data.compute();
    final scenario = _scenario ?? result.bestScenario;
    final runway = data.runwayFor(scenario, aggregate: result);
    final theme = Theme.of(context);
    final notifier = ref.read(wizardProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reicht mein Geld bis zum neuen Job?',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Rücklagen plus Einkommen des gewählten Szenarios, minus deine '
          'monatlichen Ausgaben.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _IntField(
                label: 'Ausgaben/Monat (€)',
                value: data.monthlyExpensesEuro,
                onChanged: (v) =>
                    notifier.update((d) => d.copyWith(monthlyExpensesEuro: v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _IntField(
                label: 'Rücklagen (€)',
                value: data.savingsEuro,
                onChanged: (v) =>
                    notifier.update((d) => d.copyWith(savingsEuro: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Szenario', style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            for (final t in _order)
              ChoiceChip(
                label: Text(scenarioShortLabel(t)),
                selected: t == scenario,
                onSelected: (_) => setState(() => _scenario = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _RunwayHeadline(runway: runway, horizonMonths: result.horizonMonths,
            referenceDate: result.referenceDate),
        const SizedBox(height: 16),
        SizedBox(height: 220, child: _RunwayChart(runway: runway)),
        const SizedBox(height: 8),
        Text(
          'Vereinfachte Cashflow-Projektion ohne Zinsen und Inflation. '
          'Schätzung, keine Finanzberatung.',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Whole-euro number field that keeps its own controller and syncs external
/// resets (e.g. after "Daten löschen") when not focused.
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

class _RunwayHeadline extends StatelessWidget {
  const _RunwayHeadline({
    required this.runway,
    required this.horizonMonths,
    required this.referenceDate,
  });

  final RunwayPlan runway;
  final int horizonMonths;
  final DateTime referenceDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final survives = runway.survivesHorizon;
    final color = survives ? Colors.green.shade700 : theme.colorScheme.error;

    final String title;
    final String subtitle;
    if (survives) {
      title = 'Deine Rücklagen tragen über die vollen $horizonMonths Monate.';
      subtitle = 'Rechnerischer Endstand: '
          '${euroFromCents(runway.endBalanceCents, withDecimals: false)}.';
    } else {
      final gapMonth = DateTime(
          referenceDate.year, referenceDate.month + runway.firstNegativeMonth!, 1);
      title = 'Nach ${runway.monthsCovered} Monaten entsteht eine '
          'Deckungslücke.';
      subtitle = 'Ab etwa ${DateFormat('MM.yyyy').format(gapMonth)} reicht das '
          'Geld nicht mehr. Tiefster Stand: '
          '${euroFromCents(runway.minBalanceCents, withDecimals: false)}.';
    }

    return Card(
      color: survives
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.errorContainer,
      child: ListTile(
        leading: Icon(
          survives ? Icons.check_circle_outline : Icons.warning_amber_outlined,
          color: color,
        ),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _RunwayChart extends StatelessWidget {
  const _RunwayChart({required this.runway});

  final RunwayPlan runway;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = runway.balanceSeriesCents;
    if (series.isEmpty) return const SizedBox.shrink();

    final spots = [
      for (var i = 0; i < series.length; i++) FlSpot(i.toDouble(), series[i] / 100.0),
    ];
    final maxV = series.reduce((a, b) => a > b ? a : b) / 100.0;
    final minV = series.reduce((a, b) => a < b ? a : b) / 100.0;
    final top = maxV <= 0 ? 1.0 : maxV * 1.1;
    final bottom = minV >= 0 ? 0.0 : minV * 1.1;

    return LineChart(
      LineChartData(
        minY: bottom,
        maxY: top,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              reservedSize: 24,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('M${value.toInt()}', style: theme.textTheme.labelSmall),
              ),
            ),
          ),
        ),
        // Zero reference line: below it the money has run out.
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 0,
            color: theme.colorScheme.error.withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ]),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
