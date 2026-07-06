import 'package:exit_engine/exit_engine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../util/labels.dart';
import '../widgets/help_panel.dart';
import 'detail_screen.dart';

/// Comparison tab (spec §4 screen 6): the four scenarios compared by their
/// cumulative net over the horizon, best option highlighted, deltas to the
/// baseline, tap-through to the detail view.
class ComparisonTab extends ConsumerWidget {
  const ComparisonTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(wizardProvider).compute();
    final theme = Theme.of(context);

    const order = [
      ScenarioType.kuendigungAg,
      ScenarioType.aufhebungsvertrag,
      ScenarioType.eigenkuendigung,
      ScenarioType.bleiben,
    ];
    final best = result.bestScenario;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Kumulierte Netto-Summe über ${result.horizonMonths} Monate',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: _ComparisonChart(result: result, order: order, best: best),
        ),
        const SizedBox(height: 16),
        for (final type in order)
          _ScenarioCard(result: result, type: type, isBest: type == best),
        const SizedBox(height: 8),
        HelpPanel(flagCodes: _flagCodesOf(result)),
      ],
    );
  }

  /// Union of the risk-flag codes across every scenario – drives which
  /// help resources are surfaced first.
  static Set<String> _flagCodesOf(AggregateResult result) => {
        for (final scenario in result.scenarios.values)
          for (final flag in scenario.flags) flag.code,
      };
}

class _ComparisonChart extends StatelessWidget {
  const _ComparisonChart({required this.result, required this.order, required this.best});

  final AggregateResult result;
  final List<ScenarioType> order;
  final ScenarioType best;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = [
      for (final t in order) result.scenarios[t]!.cumulativeNetCents / 100.0,
    ];
    final maxV = values.reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxV * 1.15,
        barTouchData: BarTouchData(enabled: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= order.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    scenarioShortLabel(order[i]),
                    style: theme.textTheme.labelSmall,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < order.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  color: order[i] == best
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.result, required this.type, required this.isBest});

  final AggregateResult result;
  final ScenarioType type;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenario = result.scenarios[type]!;
    final delta = result.deltaToBaselineCents(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isBest ? theme.colorScheme.primaryContainer : null,
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => DetailScreen(type: type)),
        ),
        title: Row(
          children: [
            Expanded(child: Text(scenarioLabel(type))),
            if (isBest) Icon(Icons.star, size: 18, color: theme.colorScheme.primary),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(euroFromCents(scenario.cumulativeNetCents),
                style: theme.textTheme.titleMedium),
            if (type != ScenarioType.bleiben)
              Text(
                '${signedEuroFromCents(delta)} gegenüber „Bleiben"',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: delta >= 0 ? Colors.green.shade700 : theme.colorScheme.error,
                ),
              ),
            if (scenario.flags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('${scenario.flags.length} Hinweis(e)',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
