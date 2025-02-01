import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});
  final String section = 'settings.app_info_screen';

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
      ),
      body: Center(
        child: Text(
          localeProvider.translate(section, 'coming_soon'),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
