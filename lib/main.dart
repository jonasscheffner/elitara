import 'dart:async';
import 'package:elitara/screens/chat/chat_detail_screen.dart';
import 'package:elitara/screens/chat/chat_list_screen.dart';
import 'package:elitara/screens/events/edit_event_screen.dart';
import 'package:elitara/screens/login/reset_password_screen.dart';
import 'package:elitara/screens/settings/account_settings_screen.dart';
import 'package:elitara/screens/settings/settings_menu_screen.dart';
import 'package:elitara/screens/settings/membership_settings_screen.dart';
import 'package:elitara/screens/settings/notifications_screen.dart';
import 'package:elitara/screens/settings/app_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:stripe_sdk/stripe_sdk.dart';
import 'package:uni_links/uni_links.dart';
import 'localization/locale_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/events/event_feed_screen.dart';
import 'screens/events/event_detail_screen.dart';
import 'screens/events/create_event_screen.dart';
import 'utils/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  Stripe.init(
      'pk_test_51RbU4rFtzsPyF8cw89n04DGVCrn8khxGsfYeDlJRf0dXrWPPz1Q4kptQdeqOkIP2Rv8Rh64rhfFMSrHbHn4sdR2a00qINWaDMa');

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

class MyApp extends StatefulWidget {
  final bool isDarkMode;
  final String languageCode;

  const MyApp({Key? key, required this.isDarkMode, required this.languageCode})
      : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSub;

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
  }

  void _listenToDeepLinks() {
    _linkSub = linkStream.listen((String? link) {
      if (link != null) _handleLink(link);
    }, onError: (err) {
      print('Deep link error: $err');
    });
  }

  void _handleLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri != null &&
        uri.scheme == 'elitara' &&
        uri.host == 'resetpassword' &&
        uri.queryParameters.containsKey('oobCode')) {
      final oobCode = uri.queryParameters['oobCode']!;
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(oobCode: oobCode),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Elitara',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: widget.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(widget.languageCode),
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
            return MaterialPageRoute(
                builder: (context) => const EventFeedScreen());
          case '/createEvent':
            return MaterialPageRoute(
                builder: (context) => const CreateEventScreen());
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
                builder: (context) => const MembershipSettingsScreen());
          case '/notifications':
            return MaterialPageRoute(
                builder: (context) => const NotificationsScreen());
          case '/appInfo':
            return MaterialPageRoute(
                builder: (context) => const AppInfoScreen());
          case '/chatList':
            return MaterialPageRoute(
                builder: (context) => const ChatListScreen());
          case '/chatDetail':
            if (settings.arguments is Map<String, dynamic>) {
              final arguments = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: arguments['chatId'],
                  otherUserId: arguments['otherUserId'],
                ),
              );
            }
            return _errorRoute();
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
