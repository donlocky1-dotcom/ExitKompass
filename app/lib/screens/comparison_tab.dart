import 'package:exit_engine/exit_engine.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/wizard.dart';
import '../util/format.dart';
import '../util/labels.dart';
import '../widgets/help_panel.dart';
import '../widgets/ui_kit.dart';
import 'detail_screen.dart';

/// Comparison tab (spec §4 screen 6): the four scenarios compared by their
/// cumulative net over the horizon, best option highlighted, deltas to the
/// baseline, tap-through to the detail view.
class ComparisonTab extends ConsumerWidget {
  const ComparisonTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(wizardProvider).compute();

    const order = [
      ScenarioType.kuendigungAg,
      ScenarioType.aufhebungsvertrag,
      ScenarioType.eigenkuendigung,
      ScenarioType.bleiben,
    ];
    final best = result.bestScenario;
    final accent = abfindungAccent(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: [
        const SectionLabel('Netto über die Laufzeit', topPad: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kumulierte Netto-Summe über ${result.horizonMonths} Monate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 210,
                child:
                    _ComparisonChart(result: result, order: order, best: best),
              ),
            ],
          ),
        ),
        const SectionLabel('Deine Optionen'),
        AppGroup(children: [
          for (final type in order)
            _ScenarioRow(
              result: result,
              type: type,
              isBest: type == best,
              accent: accent,
            ),
        ]),
        const SizedBox(height: 10),
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
    final accent = abfindungAccent(context);
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
                      ? accent
                      : accent.withValues(alpha: 0.22),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ScenarioRow extends StatelessWidget {
  const _ScenarioRow({
    required this.result,
    required this.type,
    required this.isBest,
    required this.accent,
  });

  final AggregateResult result;
  final ScenarioType type;
  final bool isBest;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scenario = result.scenarios[type]!;
    final delta = result.deltaToBaselineCents(type);
    final isBaseline = type == ScenarioType.bleiben;
    final positive = delta >= 0;
    final deltaColor = positive
        ? (theme.brightness == Brightness.dark
            ? const Color(0xFF46C98B)
            : const Color(0xFF1F9D5A))
        : theme.colorScheme.error;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DetailScreen(type: type)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isBest
                    ? accent
                    : accent.withValues(alpha: isBaseline ? 0.10 : 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                isBest
                    ? Icons.star_rounded
                    : (isBaseline ? Icons.home_outlined : Icons.trending_flat),
                size: 19,
                color: isBest ? Colors.white : accent,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(scenarioLabel(type),
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                      ),
                      if (isBaseline)
                        _Chip(
                            label: 'Referenz',
                            color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(euroFromCents(scenario.cumulativeNetCents),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  if (isBaseline)
                    Text(
                      'Ausgangswert (volles Gehalt) – nur Vergleichsmaßstab.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    )
                  else
                    Text(
                      '${signedEuroFromCents(delta)} gegenüber „Bleiben"',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: deltaColor, fontWeight: FontWeight.w600),
                    ),
                  if (scenario.flags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('${scenario.flags.length} Hinweis(e)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Icon(Icons.chevron_right,
                  size: 20,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small outlined pill used to mark the reference (baseline) scenario.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color)),
    );
  }
}
