import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 14),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.blue),
      ),
      labelStyle: const TextStyle(color: Colors.black),
      floatingLabelStyle: const TextStyle(color: Colors.blue),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.blue,
      selectionColor: Colors.blue.withOpacity(0.3),
      selectionHandleColor: Colors.blue,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: Colors.blue,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        textStyle: const TextStyle(color: Colors.black),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
          iconColor: WidgetStateProperty.all(
            Colors.blue,
          ),
          foregroundColor: WidgetStateProperty.all(
            Colors.blue,
          )),
    ),
    cardTheme: CardTheme(color: Colors.grey[200]),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Colors.blue),
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.blue),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF34C759);
        }
        return Colors.grey.shade300;
      }),
    ),
    datePickerTheme: DatePickerThemeData(
      headerBackgroundColor: Colors.blue,
      headerForegroundColor: Colors.white,
      dayBackgroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.blue;
        return Colors.transparent;
      }),
      dayForegroundColor: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.black;
      }),
    ),
    timePickerTheme: const TimePickerThemeData(
      hourMinuteColor: Colors.blue,
      hourMinuteTextColor: Colors.white,
      dayPeriodColor: Colors.blue,
      dayPeriodTextColor: Colors.white,
      dialHandColor: Colors.blue,
      entryModeIconColor: Colors.blue,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: const Color(0xFF1C1C1E),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.white),
      ),
      labelStyle: const TextStyle(color: Colors.white),
      floatingLabelStyle: const TextStyle(color: Colors.white),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.blue,
      selectionColor: Colors.lightBlueAccent.withOpacity(0.3),
      selectionHandleColor: Colors.blue,
    ),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: Colors.blue,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
        textStyle: const TextStyle(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
          iconColor: WidgetStateProperty.all(
            Colors.blue,
          ),
          foregroundColor: WidgetStateProperty.all(
            Colors.blue,
          )),
    ),
    cardTheme: CardTheme(color: Colors.grey[850]),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: Colors.blue),
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.blue),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF34C759);
        }
        return Colors.grey.shade700;
      }),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: const Color(0xFF1C1C1E),
      headerBackgroundColor: Colors.blue,
      headerForegroundColor: Colors.white,
      dayBackgroundColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.blue;
        return Colors.transparent;
      }),
      dayForegroundColor: MaterialStateColor.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.white;
        return Colors.white;
      }),
    ),
    timePickerTheme: const TimePickerThemeData(
      hourMinuteColor: Colors.blue,
      hourMinuteTextColor: Colors.white,
      dayPeriodColor: Colors.blue,
      dayPeriodTextColor: Colors.white,
      dialHandColor: Colors.blue,
      entryModeIconColor: Colors.blue,
    ),
  );

  static ThemeData get defaultTheme => darkTheme;
}
