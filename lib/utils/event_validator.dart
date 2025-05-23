import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class EventValidator {
  static const String _section = "event_validation";

  static String? validateTitle(String title, BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    if (title.trim().length > 50) {
      return localeProvider.translate(_section, 'title_too_long');
    }
    return null;
  }

  static String? validateDescription(String description, BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    if (description.trim().length > 500) {
      return localeProvider.translate(_section, 'description_too_long');
    }
    return null;
  }

  static String? validateParticipantLimit(
    String text,
    BuildContext context, {
    int? existingParticipantCount,
  }) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    if (text.isNotEmpty) {
      int? value = int.tryParse(text);
      if (value == null) {
        return localeProvider.translate(_section, 'participant_limit_invalid');
      } else if (value < 1) {
        return localeProvider.translate(_section, 'participant_limit_min');
      } else if (existingParticipantCount != null &&
          value < existingParticipantCount) {
        return localeProvider.translate(
          _section,
          'participant_limit_error',
          params: {'count': '$existingParticipantCount'},
        );
      }
    }
    return null;
  }

  static String? validateWaitlistLimit(
    String text,
    BuildContext context, {
    bool waitlistEnabled = false,
    int? existingWaitlistCount,
  }) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    if (waitlistEnabled && text.isNotEmpty) {
      int? value = int.tryParse(text);
      if (value == null) {
        return localeProvider.translate(_section, 'waitlist_limit_invalid');
      } else if (value < 1) {
        return localeProvider.translate(_section, 'waitlist_limit_min');
      } else if (existingWaitlistCount != null &&
          value < existingWaitlistCount) {
        return localeProvider.translate(
          _section,
          'waitlist_limit_error',
          params: {'count': '$existingWaitlistCount'},
        );
      }
    }
    return null;
  }
}
