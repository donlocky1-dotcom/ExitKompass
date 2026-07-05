import 'package:intl/intl.dart';

final NumberFormat _euro = NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 2);
final NumberFormat _euro0 = NumberFormat.currency(locale: 'de_DE', symbol: '€', decimalDigits: 0);

/// Formats a cent amount as a German euro string, e.g. `1.907,10 €`.
String euroFromCents(int cents, {bool withDecimals = true}) =>
    (withDecimals ? _euro : _euro0).format(cents / 100);

/// Formats a signed cent delta, e.g. `+2.760,00 €` / `−1.462,00 €`.
String signedEuroFromCents(int cents) {
  final sign = cents > 0 ? '+' : (cents < 0 ? '−' : '');
  return '$sign${euroFromCents(cents.abs())}';
}
