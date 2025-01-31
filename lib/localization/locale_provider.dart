import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LocaleProvider {
  static const LocalizationsDelegate<LocaleProvider> delegate =
      _LocaleProviderDelegate();

  static Future<LocaleProvider> load(Locale locale) async {
    String jsonString =
        await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    return LocaleProvider(locale.languageCode, jsonMap);
  }

  final String languageCode;
  final Map<String, dynamic> localizedStrings;

  LocaleProvider(this.languageCode, this.localizedStrings);

  String translate(String section, String key) {
    try {
      var keys = key.split('.');
      var translation = localizedStrings[section];

      for (var k in keys) {
        if (translation is Map<String, dynamic>) {
          translation = translation[k];
        } else {
          return 'Translation not found';
        }
      }

      if (translation is String) {
        return translation;
      } else {
        return 'Translation not found';
      }
    } catch (e) {
      print('Translation error: $e');
      return 'Translation not found';
    }
  }
}

class _LocaleProviderDelegate extends LocalizationsDelegate<LocaleProvider> {
  const _LocaleProviderDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<LocaleProvider> load(Locale locale) => LocaleProvider.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<LocaleProvider> old) {
    return false;
  }
}
