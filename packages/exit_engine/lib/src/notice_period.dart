/// Ordinary notice period for an employer's dismissal (§ 622 BGB).
///
/// The statutory staggering by tenure (§ 622 Abs. 2 BGB) is only a **lower
/// bound / starting point**: individual contracts, works agreements and
/// (framework) collective agreements (Tarifverträge, e.g. the chemical
/// industry / VAA scale for academic staff) frequently agree **longer**
/// periods, also staggered by tenure. Those cannot be modelled reliably, so
/// the app treats the notice period as a **user input** and only offers the
/// § 622 value as a suggestion.
library;

/// Statutory ordinary notice period the **employer** must observe, in whole
/// months to the end of a calendar month (§ 622 Abs. 2 BGB), by completed
/// years of tenure.
///
/// For less than two years the base period is four weeks to the 15th or the
/// end of a calendar month (§ 622 Abs. 1 BGB); in the app's month grid this
/// is approximated as one month (see ASSUMPTIONS A18).
int statutoryNoticePeriodMonths(int tenureYears) {
  if (tenureYears >= 20) return 7;
  if (tenureYears >= 15) return 6;
  if (tenureYears >= 12) return 5;
  if (tenureYears >= 10) return 4;
  if (tenureYears >= 8) return 3;
  if (tenureYears >= 5) return 2;
  if (tenureYears >= 2) return 1;
  return 1;
}

/// End of the notice period: the last day of the calendar month that lies
/// [months] months after [from] ("zum Ende eines Kalendermonats").
DateTime noticeEndDate(DateTime from, int months) =>
    DateTime(from.year, from.month + months + 1, 0);

/// Whole months of notice implied by an end date relative to [from]
/// (inverse of [noticeEndDate], for showing the current selection). Never
/// negative.
int noticeMonthsBetween(DateTime from, DateTime end) {
  final m = (end.year - from.year) * 12 + (end.month - from.month);
  return m < 0 ? 0 : m;
}
