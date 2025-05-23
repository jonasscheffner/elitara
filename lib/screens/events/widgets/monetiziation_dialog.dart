import 'dart:ui';
import 'package:elitara/utils/app_snack_bar.dart';
import 'package:elitara/utils/currency_smart_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:elitara/models/currency.dart';
import 'package:elitara/models/event_price.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:intl/intl.dart';

class MonetizationDialog extends StatefulWidget {
  final EventPrice? initialPrice;

  const MonetizationDialog({
    super.key,
    this.initialPrice,
  });

  @override
  State<MonetizationDialog> createState() => _MonetizationDialogState();
}

class _MonetizationDialogState extends State<MonetizationDialog> {
  final TextEditingController _priceController = TextEditingController();
  Currency _selectedCurrency = Currency.eur;
  final String section = 'event_form.monetization_dialog';
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    final locale = WidgetsBinding.instance.window.locale;

    if (widget.initialPrice != null) {
      final format = NumberFormat.currency(
        locale: locale.toString(),
        symbol: '',
        decimalDigits: 2,
      );
      _priceController.text = format.format(widget.initialPrice!.amount).trim();
      _selectedCurrency = widget.initialPrice!.currency;
      _enabled = true;
    }

    _priceController.addListener(_onPriceChanged);
  }

  void _onPriceChanged() {
    setState(() {}); // Nur um Confirm-Button zu aktivieren/deaktivieren
  }

  double? _parseFormattedPrice(String input, Locale locale) {
    final format = NumberFormat.currency(
      locale: locale.toString(),
      symbol: '',
      decimalDigits: 2,
    );
    final cleaned = input
        .replaceAll(format.symbols.GROUP_SEP, '')
        .replaceAll(format.symbols.DECIMAL_SEP, '.');
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    final locale = Localizations.localeOf(context);

    final confirmEnabled = !_enabled || _priceController.text.trim().isNotEmpty;

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(color: const Color(0x80000000).withOpacity(0)),
        ),
        Center(
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: GestureDetector(
              onVerticalDragDown: (_) => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            localeProvider.translate(section, 'enable_fee'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Switch(
                            value: _enabled,
                            onChanged: (val) => setState(() => _enabled = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_enabled) ...[
                        TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          inputFormatters: [
                            CurrencySmartInputFormatter(locale)
                          ],
                          decoration: InputDecoration(
                            labelText: localeProvider.translate(
                                section, 'price_label'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Currency>(
                          value: _selectedCurrency,
                          onChanged: (value) =>
                              setState(() => _selectedCurrency = value!),
                          items: Currency.values.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child:
                                  Text('${currency.symbol} ${currency.code}'),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            labelText: localeProvider.translate(
                                section, 'currency_label'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                                localeProvider.translate(section, 'cancel')),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(40, 36),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 16),
                            ),
                            onPressed: confirmEnabled
                                ? () {
                                    if (!_enabled) {
                                      Navigator.of(context).pop(null);
                                      return;
                                    }

                                    final parsed = _parseFormattedPrice(
                                        _priceController.text, locale);
                                    if (parsed == null || parsed < 5) {
                                      final currencyText =
                                          '${_selectedCurrency.symbol} ${_selectedCurrency.code}';
                                      final errorMsg = localeProvider.translate(
                                        section,
                                        'priceErrorWithCurrency',
                                        params: {'currency': currencyText},
                                      );

                                      AppSnackBar.show(
                                        context,
                                        errorMsg,
                                        type: SnackBarType.error,
                                      );
                                      return;
                                    }

                                    final result = EventPrice(
                                      amount: parsed,
                                      currency: _selectedCurrency,
                                    );
                                    Navigator.of(context).pop(result);
                                  }
                                : null,
                            child: Text(
                                localeProvider.translate(section, 'confirm')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  void dispose() {
    _priceController.removeListener(_onPriceChanged);
    _priceController.dispose();
    super.dispose();
  }
}
