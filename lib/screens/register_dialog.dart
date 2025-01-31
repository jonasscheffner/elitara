import 'package:elitara/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class RegisterDialog extends StatefulWidget {
  @override
  _RegisterDialogState createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<RegisterDialog> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String section = 'register_dialog';
  late LocaleProvider localeProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _authService.registerWithEmailPassword(
        emailController.text,
        usernameController.text,
        passwordController.text,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                localeProvider.translate(section, 'messages.register_error'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              localeProvider.translate(section, 'create_account'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: localeProvider.translate(section, 'email'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: localeProvider.translate(section, 'username'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: localeProvider.translate(section, 'password'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(localeProvider.translate(section, 'cancel')),
                ),
                TextButton(
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : Text(localeProvider.translate(section, 'create')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
