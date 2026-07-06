// Standalone preview entrypoint for visual verification of the M7 liquidity
// tab (not part of the app). Build with:
//   flutter build web -t tool/preview_liquidity.dart --no-web-resources-cdn
import 'package:exit_engine/exit_engine.dart';
import 'package:exitkompass_app/screens/liquidity_tab.dart';
import 'package:exitkompass_app/state/wizard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [
        wizardProvider.overrideWith(
          (ref) => WizardController(
            initial: WizardData(
              grossMonthEuro: 5200,
              monthlyExpensesEuro: 3400,
              savingsEuro: 9000,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00696E)),
          useMaterial3: true,
        ),
        home: const Scaffold(
          // Eigenkündigung has a 12-week blocking period → a real income gap.
          body: SafeArea(
            child: LiquidityTab(initialScenario: ScenarioType.eigenkuendigung),
          ),
        ),
      ),
    ),
  );
}
