import 'package:elitara/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String? emailError;
  String? usernameError;
  String? passwordError;

  bool emailUnique = false;
  bool usernameUnique = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
  }

  bool get isFormValid =>
      emailError == null &&
      usernameError == null &&
      passwordError == null &&
      emailUnique &&
      usernameUnique &&
      emailController.text.isNotEmpty &&
      usernameController.text.isNotEmpty &&
      passwordController.text.isNotEmpty;

  void validateEmail() async {
    final email = emailController.text.trim();
    final result = _authService.validateEmail(email);
    if (result != null) {
      setState(() {
        emailError = localeProvider.translate(section, 'validation.$result');
        emailUnique = false;
      });
      return;
    }
    final exists = await _authService.checkEmailExists(email);
    setState(() {
      emailError = exists
          ? localeProvider.translate(section, 'validation.email_exists')
          : null;
      emailUnique = !exists;
    });
  }

  void validateUsername() async {
    final username = usernameController.text.trim();
    final result = _authService.validateUsername(username);
    if (result != null) {
      setState(() {
        usernameError = localeProvider.translate(section, 'validation.$result');
        usernameUnique = false;
      });
      return;
    }
    final exists = await _authService.checkUsernameExists(username);
    setState(() {
      usernameError = exists
          ? localeProvider.translate(section, 'validation.username_exists')
          : null;
      usernameUnique = !exists;
    });
  }

  void validatePassword() {
    final result = _authService.validatePassword(passwordController.text);
    setState(() {
      passwordError = result != null
          ? localeProvider.translate(section, 'validation.$result')
          : null;
    });
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _authService.registerWithEmailPassword(
        emailController.text.trim(),
        usernameController.text.trim(),
        passwordController.text,
      );
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              localeProvider.translate(section, 'messages.register_success')),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      String errorKey = 'messages.register_error';

      if (e is FirebaseAuthException) {
        if (e.code == 'weak-password')
          errorKey = 'validation.weak_password';
        else if (e.code == 'email-already-in-use')
          errorKey = 'validation.email_in_use';
        else if (e.code == 'invalid-email')
          errorKey = 'validation.invalid_email';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localeProvider.translate(section, errorKey)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: theme.dialogBackgroundColor,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localeProvider.translate(section, 'create_account'),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate(section, 'email'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => validateEmail(),
                  ),
                  if (emailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        emailError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate(section, 'username'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    onChanged: (_) => validateUsername(),
                  ),
                  if (usernameError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        usernameError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: localeProvider.translate(section, 'password'),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    obscureText: true,
                    onChanged: (_) => validatePassword(),
                  ),
                  if (passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        passwordError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: Text(localeProvider.translate(section, 'cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: isLoading || !isFormValid ? null : _register,
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                            ),
                          )
                        : Text(localeProvider.translate(section, 'create')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
