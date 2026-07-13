import 'package:exit_engine/exit_engine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../util/labels.dart';
import '../widgets/disclaimer_footer.dart';
import '../widgets/ui_kit.dart';

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
    final accent = abfindungAccent(context);

    return GroupedPage(
      title: scenarioLabel(type),
      footer: const DisclaimerFooter(),
      children: [
        const SectionLabel('Ergebnis', topPad: 8),
        AppCard(
          child: Column(
            children: [
              StatRow(
                label:
                    'Kumulierte Netto-Summe über ${result.horizonMonths} Monate',
                value: euroFromCents(scenario.cumulativeNetCents),
                accent: accent,
                emphasise: true,
              ),
              Divider(height: 18, color: hairline(context)),
              StatRow(
                label: 'Differenz zu „Bleiben"',
                value: signedEuroFromCents(result.deltaToBaselineCents(type)),
              ),
            ],
          ),
        ),
        const SectionLabel('Monatlicher Netto-Cashflow'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 200, child: _CashflowChart(scenario: scenario)),
              const SizedBox(height: 10),
              _Legend(),
            ],
          ),
        ),
        if (scenario.flags.isNotEmpty) ...[
          const SectionLabel('Hinweise'),
          AppGroup(children: [
            for (final flag in scenario.flags)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 19, color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(flag.message,
                            style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
          ]),
        ],
      ],
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
