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
      List<String> sectionKeys = section.split('.');
      dynamic current = localizedStrings;
      for (var sk in sectionKeys) {
        if (current is Map<String, dynamic> && current.containsKey(sk)) {
          current = current[sk];
        } else {
          return 'Translation not found';
        }
      }
      List<String> keyParts = key.split('.');
      for (var k in keyParts) {
        if (current is Map<String, dynamic> && current.containsKey(k)) {
          current = current[k];
        } else {
          return 'Translation not found';
        }
      }
      if (current is String) {
        return current;
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
