import 'package:exit_engine/exit_engine.dart';
import 'package:test/test.dart';

void main() {
  group('statutoryNoticePeriodMonths (§ 622 Abs. 2 BGB)', () {
    test('staggering by completed years of tenure', () {
      expect(statutoryNoticePeriodMonths(0), 1); // base (4 weeks ≈ 1 month)
      expect(statutoryNoticePeriodMonths(1), 1);
      expect(statutoryNoticePeriodMonths(2), 1);
      expect(statutoryNoticePeriodMonths(4), 1);
      expect(statutoryNoticePeriodMonths(5), 2);
      expect(statutoryNoticePeriodMonths(8), 3);
      expect(statutoryNoticePeriodMonths(10), 4);
      expect(statutoryNoticePeriodMonths(12), 5);
      expect(statutoryNoticePeriodMonths(15), 6);
      expect(statutoryNoticePeriodMonths(20), 7);
      expect(statutoryNoticePeriodMonths(35), 7, reason: 'caps at 7 months');
    });
  });

  group('noticeEndDate (zum Monatsende)', () {
    test('end of the month that lies N months after the start', () {
      // Notice on 7 July 2026, 4 months → end of November 2026.
      expect(noticeEndDate(DateTime(2026, 7, 7), 4), DateTime(2026, 11, 30));
      // 2 months from mid-December rolls over the year end.
      expect(noticeEndDate(DateTime(2026, 12, 15), 2), DateTime(2027, 2, 28));
      // Zero months → end of the current month.
      expect(noticeEndDate(DateTime(2026, 3, 10), 0), DateTime(2026, 3, 31));
    });
  });

  group('noticeMonthsBetween (inverse for display)', () {
    test('whole months between a start and an end date, never negative', () {
      expect(noticeMonthsBetween(DateTime(2026, 7, 1), DateTime(2026, 11, 30)), 4);
      expect(noticeMonthsBetween(DateTime(2026, 7, 1), DateTime(2026, 7, 15)), 0);
      expect(noticeMonthsBetween(DateTime(2026, 7, 1), DateTime(2026, 6, 1)), 0);
    });
  });
}
