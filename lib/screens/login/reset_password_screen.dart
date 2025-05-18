import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/utils/validators.dart';
import 'package:elitara/localization/locale_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String oobCode;

  const ResetPasswordScreen({super.key, required this.oobCode});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  String? passwordError;
  bool isLoading = false;
  late LocaleProvider localeProvider;
  String section = 'reset_password';
  bool _touched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
  }

  bool get isFormValid =>
      passwordError == null && passwordController.text.isNotEmpty;

  void validatePassword() {
    final error = Validators.validatePassword(
        passwordController.text, localeProvider, section);
    setState(() {
      passwordError = _touched ? error : null;
    });
  }

  Future<void> _resetPassword() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: passwordController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localeProvider.translate(section, 'reset_success')),
        backgroundColor: Colors.green,
      ));

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(localeProvider.translate(section, 'reset_failed')),
        backgroundColor: Colors.red,
      ));
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      if (!_touched && passwordController.text.isNotEmpty) {
        _touched = true;
      }
      validatePassword();
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(localeProvider.translate(section, 'title'))),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'new_password'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (passwordError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    passwordError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading || !isFormValid ? null : _resetPassword,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(localeProvider.translate(section, 'submit')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
