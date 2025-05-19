import 'dart:ui';

import 'package:elitara/screens/login/widgets/register_dialog.dart';
import 'package:elitara/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/localization/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  bool showPasswordField = false;
  String section = 'login_screen';
  late LocaleProvider localeProvider;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _heightAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _showPasswordField() {
    setState(() {
      showPasswordField = true;
      _controller.forward();
    });
  }

  void _hidePasswordField() {
    setState(() {
      showPasswordField = false;
      _controller.reverse();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
  }

  Future<void> _login() async {
    try {
      User? user = await _authService.signInWithEmailPassword(
        emailController.text,
        passwordController.text,
      );
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/eventFeed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localeProvider.translate(section, 'messages.login_error'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(localeProvider.translate(section, 'enter_email_for_reset')),
        ),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localeProvider.translate(section, 'reset_email_sent')),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localeProvider.translate(section, 'reset_email_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openRegisterDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Register',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withOpacity(0),
              ),
            ),
            Center(
              child: RegisterDialog(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localeProvider.translate(section, 'login'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: localeProvider.translate(section, 'email'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    suffixIcon: showPasswordField
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _showPasswordField,
                          ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    if (value.isNotEmpty && showPasswordField) {
                      _hidePasswordField();
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizeTransition(
                  sizeFactor: _heightAnimation,
                  axis: Axis.vertical,
                  axisAlignment: -1.0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText:
                            localeProvider.translate(section, 'password'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 12.0),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _login,
                        ),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _login(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _forgotPassword,
                  child: Text(
                      localeProvider.translate(section, 'forgotten_password')),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _openRegisterDialog,
                  child:
                      Text(localeProvider.translate(section, 'create_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
