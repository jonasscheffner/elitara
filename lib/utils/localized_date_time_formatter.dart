import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LocalizedDateTimeFormatter {
  static String getFormattedDate(BuildContext context, DateTime dateTime) {
    final String locale = Localizations.localeOf(context).languageCode;
    final DateFormat dateFormat =
        locale == 'de' ? DateFormat('dd/MM/yyyy') : DateFormat('yyyy/MM/dd');
    return dateFormat.format(dateTime);
  }

  static String getFormattedTime(BuildContext context, DateTime dateTime) {
    final String locale = Localizations.localeOf(context).languageCode;
    final DateFormat timeFormat =
        locale == 'de' ? DateFormat("HH:mm 'Uhr'") : DateFormat('h:mm a');
    return timeFormat.format(dateTime);
  }

  static String getFormattedDateTime(BuildContext context, DateTime dateTime) {
    final String formattedDate = getFormattedDate(context, dateTime);
    final String formattedTime = getFormattedTime(context, dateTime);
    return '$formattedDate, $formattedTime';
  }
}
