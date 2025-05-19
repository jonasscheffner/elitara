import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsMenuScreen extends StatelessWidget {
  const SettingsMenuScreen({super.key});
  final String section = 'settings.menu_screen';

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(localeProvider.translate(section, 'account_settings')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/accountSettings'),
          ),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: Text(localeProvider.translate(section, 'membership')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/membership'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(localeProvider.translate(section, 'notifications')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text(localeProvider.translate(section, 'app_info')),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, '/appInfo'),
          ),
          const Divider(),
          ListTile(
            title: Text(
              localeProvider.translate(section, 'sign_out'),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
