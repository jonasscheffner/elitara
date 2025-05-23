enum Currency {
  eur,
  usd,
  gbp,
}

extension CurrencyExtension on Currency {
  String get symbol {
    switch (this) {
      case Currency.eur:
        return '€';
      case Currency.usd:
        return '\$';
      case Currency.gbp:
        return '£';
    }
  }

  String get code {
    return toString().split('.').last.toUpperCase();
  }

  static Currency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'eur':
        return Currency.eur;
      case 'usd':
        return Currency.usd;
      case 'gbp':
        return Currency.gbp;
      default:
        return Currency.eur;
    }
  }
}
