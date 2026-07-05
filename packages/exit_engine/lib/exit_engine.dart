/// ExitKompass calculation engine (tax year 2026).
///
/// All monetary amounts are passed and returned as `int` values in
/// **cents** unless documented otherwise.
library;

export 'src/m1_income_tax.dart';
export 'src/m2_social_insurance.dart';
export 'src/money.dart';
export 'src/net_income.dart';
export 'src/params.dart';
export 'src/params_2026_data.dart' show params2026Json;
export 'src/sv_rates.dart';
