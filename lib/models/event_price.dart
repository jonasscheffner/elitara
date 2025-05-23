import 'package:elitara/models/currency.dart';

class EventPrice {
  final double amount;
  final Currency currency;

  EventPrice({required this.amount, required this.currency})
      : assert(amount >= 5, 'Minimum price is 5');

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'currency': currency.code,
    };
  }

  factory EventPrice.fromMap(Map<String, dynamic> map) {
    return EventPrice(
      amount: (map['amount'] as num).toDouble(),
      currency: CurrencyExtension.fromString(map['currency']),
    );
  }
}
