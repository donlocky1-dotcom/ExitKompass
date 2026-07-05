import 'package:exit_engine/exit_engine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../util/labels.dart';
import '../widgets/disclaimer_footer.dart';

/// Scenario detail (spec §4 screen 7): monthly net cashflow chart, key
/// figures and the risk/information flags.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({required this.type, super.key});

  final ScenarioType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(wizardProvider).compute();
    final scenario = result.scenarios[type]!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(scenarioLabel(type))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatTile(
                  label: 'Kumulierte Netto-Summe über ${result.horizonMonths} Monate',
                  value: euroFromCents(scenario.cumulativeNetCents),
                  emphasise: true,
                ),
                _StatTile(
                  label: 'Differenz zu „Bleiben"',
                  value: signedEuroFromCents(result.deltaToBaselineCents(type)),
                ),
                const SizedBox(height: 20),
                Text('Monatlicher Netto-Cashflow', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(height: 200, child: _CashflowChart(scenario: scenario)),
                const SizedBox(height: 8),
                _Legend(),
                const SizedBox(height: 20),
                if (scenario.flags.isNotEmpty) ...[
                  Text('Hinweise', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final flag in scenario.flags)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        title: Text(flag.message),
                      ),
                    ),
                ],
              ],
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.emphasise = false});
  final String label;
  final String value;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: (emphasise ? theme.textTheme.headlineSmall : theme.textTheme.titleMedium)
                ?.copyWith(color: emphasise ? theme.colorScheme.primary : null),
          ),
        ],
      ),
    );
  }
}

class _CashflowChart extends StatelessWidget {
  const _CashflowChart({required this.scenario});
  final ScenarioResult scenario;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = [
      for (var i = 0; i < scenario.monthlyNetCents.length; i++)
        FlSpot(i.toDouble(), scenario.monthlyNetCents[i] / 100.0),
    ];
    final maxV = scenario.monthlyNetCents.reduce((a, b) => a > b ? a : b) / 100.0;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxV <= 0 ? 1 : maxV * 1.15,
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

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 12,
      children: [
        for (final s in CashflowSource.values)
          Text('• ${cashflowSourceLabel(s)}', style: style),
      ],
    );
  }
}
