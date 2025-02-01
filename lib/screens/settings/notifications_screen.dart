import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  final String section = 'settings.notifications_screen';

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
