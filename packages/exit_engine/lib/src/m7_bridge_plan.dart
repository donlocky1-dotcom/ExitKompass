/// M7 – Liquidity / bridge planner ("Reicht das Geld bis zum neuen Job?").
///
/// Given a scenario's monthly net cashflow (from the M5 aggregator), the
/// household's monthly living expenses and the savings available today, this
/// projects the running balance month by month and finds when – if ever – the
/// money runs out. All amounts are `int` cents.
///
/// This is a cashflow projection, not financial advice; it ignores interest,
/// inflation and irregular one-off costs.
library;

/// Result of the runway projection (all amounts in cents).
class RunwayPlan {
  const RunwayPlan({
    required this.balanceSeriesCents,
    required this.startingSavingsCents,
    required this.monthlyExpensesCents,
    required this.firstNegativeMonth,
    required this.minBalanceCents,
    required this.minBalanceMonth,
    required this.endBalanceCents,
  });

  /// Running balance at the end of each month (length == horizon).
  final List<int> balanceSeriesCents;

  final int startingSavingsCents;
  final int monthlyExpensesCents;

  /// Zero-based index of the first month the balance is negative, or `null`
  /// if the balance stays non-negative over the whole horizon.
  final int? firstNegativeMonth;

  /// Lowest balance reached over the horizon and the month it occurs in.
  final int minBalanceCents;
  final int minBalanceMonth;

  /// Balance at the end of the horizon.
  final int endBalanceCents;

  /// Whether the money lasts the whole horizon (no negative month).
  bool get survivesHorizon => firstNegativeMonth == null;

  /// Number of months fully covered before the balance first goes negative
  /// (equals the horizon length when it never does).
  int get monthsCovered => firstNegativeMonth ?? balanceSeriesCents.length;
}

/// Projects the running balance from [startingSavingsCents], adding each
/// month's [monthlyNetCents] inflow and subtracting [monthlyExpensesCents].
RunwayPlan computeRunway({
  required List<int> monthlyNetCents,
  required int startingSavingsCents,
  required int monthlyExpensesCents,
}) {
  assert(monthlyExpensesCents >= 0);

  final series = <int>[];
  var balance = startingSavingsCents;
  int? firstNegative;
  var minBalance = startingSavingsCents;
  var minMonth = 0;
  var haveMin = false;

  for (var m = 0; m < monthlyNetCents.length; m++) {
    balance += monthlyNetCents[m] - monthlyExpensesCents;
    series.add(balance);
    if (!haveMin || balance < minBalance) {
      minBalance = balance;
      minMonth = m;
      haveMin = true;
    }
    if (firstNegative == null && balance < 0) {
      firstNegative = m;
    }
  }

  return RunwayPlan(
    balanceSeriesCents: series,
    startingSavingsCents: startingSavingsCents,
    monthlyExpensesCents: monthlyExpensesCents,
    firstNegativeMonth: firstNegative,
    minBalanceCents: haveMin ? minBalance : startingSavingsCents,
    minBalanceMonth: minMonth,
    endBalanceCents: series.isEmpty ? startingSavingsCents : series.last,
  );
}
