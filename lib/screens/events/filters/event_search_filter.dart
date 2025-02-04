import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class EventSearchFilter extends StatelessWidget {
  final Function(String) onChanged;
  final String section;
  const EventSearchFilter(
      {super.key, required this.onChanged, required this.section});

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: localeProvider.translate(section, 'search'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
