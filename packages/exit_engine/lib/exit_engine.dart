/// ExitKompass calculation engine (tax year 2026).
///
/// Modules:
/// * M1 – income tax / wage tax (`m1_income_tax.dart`)
/// * M2 – social insurance (`m2_social_insurance.dart`)
/// * M3 – severance / Fünftelregelung (`m3_severance.dart`)
/// * M4 – unemployment benefit ALG 1 (`m4_alg1.dart`)
/// * M5 – scenario aggregator (`m5_scenarios.dart`)
/// * M6 – severance amount estimate (`m6_severance_estimate.dart`)
/// * M7 – liquidity / bridge planner (`m7_bridge_plan.dart`)
/// * M8 – severance payout timing (`m8_severance_timing.dart`)
/// * M9 – non-compete compensation / Karenzentschädigung (`m9_non_compete.dart`)
///
/// All monetary amounts are passed and returned as `int` values in
/// **cents** unless documented otherwise.
library;

export 'src/m1_income_tax.dart';
export 'src/m2_social_insurance.dart';
export 'src/m3_severance.dart';
export 'src/m4_alg1.dart';
export 'src/m5_scenarios.dart';
export 'src/m6_severance_estimate.dart';
export 'src/m7_bridge_plan.dart';
export 'src/m8_severance_timing.dart';
export 'src/m9_non_compete.dart';
export 'src/money.dart';
export 'src/net_income.dart';
export 'src/params.dart';
export 'src/params_2026_data.dart' show params2026Json;
export 'src/sv_rates.dart';
