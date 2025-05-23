import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencySmartInputFormatter extends TextInputFormatter {
  final NumberFormat numberFormat;

  CurrencySmartInputFormatter(Locale locale)
      : numberFormat = NumberFormat.currency(
          locale: locale.toString(),
          symbol: '',
          decimalDigits: 2,
        );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      return const TextEditingValue(
          text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    double value = double.parse(digits) / 100;

    String formatted = numberFormat.format(value).trim();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
