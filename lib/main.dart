import 'package:elitara/screens/events/edit_event_screen.dart';
import 'package:elitara/screens/settings/account_settings_screen.dart';
import 'package:elitara/screens/settings/settings_menu_screen.dart';
import 'package:elitara/screens/settings/membership_settings_screen.dart';
import 'package:elitara/screens/settings/notifications_screen.dart';
import 'package:elitara/screens/settings/app_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'localization/locale_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/events/event_feed_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  bool isDarkMode = await _getSavedTheme();
  String languageCode = await _getSavedLanguageCode();

  runApp(MyApp(isDarkMode: isDarkMode, languageCode: languageCode));
}

Future<bool> _getSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isDarkMode') ?? true;
}

Future<String> _getSavedLanguageCode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('language_code') ?? 'en';
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  final String languageCode;

  const MyApp({Key? key, required this.isDarkMode, required this.languageCode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elitara',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(languageCode),
      supportedLocales: const [Locale('en', 'US'), Locale('de', 'DE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        LocaleProvider.delegate,
      ],
      initialRoute: '/welcome',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/welcome':
            return MaterialPageRoute(
                builder: (context) => const WelcomeScreen());
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginScreen());
          case '/eventFeed':
            return MaterialPageRoute(builder: (context) => EventFeedScreen());
          case '/createEvent':
            return MaterialPageRoute(builder: (context) => CreateEventScreen());
          case '/eventDetail':
            if (settings.arguments is String) {
              final String eventId = settings.arguments as String;
              return MaterialPageRoute(
                  builder: (context) => EventDetailScreen(eventId: eventId));
            }
            return _errorRoute();
          case '/editEvent':
            if (settings.arguments is String) {
              final String eventId = settings.arguments as String;
              return MaterialPageRoute(
                  builder: (context) => EditEventScreen(eventId: eventId));
            }
            return _errorRoute();
          case '/settingsMenu':
            return MaterialPageRoute(
                builder: (context) => const SettingsMenuScreen());
          case '/accountSettings':
            return MaterialPageRoute(
                builder: (context) => const AccountSettingsScreen());
          case '/membership':
            return MaterialPageRoute(
                builder: (context) => const MembershipScreen());
          case '/notifications':
            return MaterialPageRoute(
                builder: (context) => const NotificationsScreen());
          case '/appInfo':
            return MaterialPageRoute(
                builder: (context) => const AppInfoScreen());
          default:
            return _errorRoute();
        }
      },
    );
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => const Scaffold(
        body: Center(child: Text("Seite nicht gefunden")),
      ),
    );
  }
}
