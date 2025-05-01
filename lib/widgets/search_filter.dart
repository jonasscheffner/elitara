import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class SearchFilter extends StatelessWidget {
  final String section;
  final Function(String) onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const SearchFilter({
    super.key,
    required this.section,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: localeProvider.translate(section, 'search'),
        prefixIcon: prefixIcon ?? const Icon(Icons.search),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
