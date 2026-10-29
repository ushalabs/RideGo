import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱ ',
    decimalDigits: 2,
  );

  static final NumberFormat _currencyFormatNoDecimals = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱ ',
    decimalDigits: 0,
  );

  static String format(num amount) {
    if (amount % 1 == 0) {
      return _currencyFormatNoDecimals.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatPrecise(num amount) {
    return _currencyFormat.format(amount);
  }
}
