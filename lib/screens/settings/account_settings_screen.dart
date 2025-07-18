import 'package:elitara/utils/account_validator.dart';
import 'package:elitara/utils/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/services/user_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  _AccountSettingsScreenState createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();

  bool _isSaving = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  final String section = 'settings.account_screen';
  final UserService _userService = UserService();

  String _initialUsername = '';
  String _initialEmail = '';

  String? usernameError;
  String? emailError;
  String? passwordError;

  bool get isFormValid =>
      usernameError == null &&
      emailError == null &&
      passwordError == null &&
      _usernameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty;

  bool get hasChanged =>
      _usernameController.text.trim() != _initialUsername ||
      _emailController.text.trim() != _initialEmail ||
      _passwordController.text.isNotEmpty;

  late LocaleProvider localeProvider;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _initialUsername = _currentUser?.displayName ?? '';
    _initialEmail = _currentUser?.email ?? '';

    _usernameController = TextEditingController(text: _initialUsername);
    _emailController = TextEditingController(text: _initialEmail);

    _usernameController.addListener(_validateUsername);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    localeProvider = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    _validateUsername();
    _validateEmail();
    _validatePassword();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateUsername() async {
    final username = _usernameController.text.trim();
    final current = _auth.currentUser?.displayName ?? '';
    final error = await AccountValidator.validateUsername(
      username,
      localeProvider,
      section,
      checkExistence: username != current,
    );
    setState(() {
      usernameError = error;
    });
  }

  void _validateEmail() async {
    final email = _emailController.text.trim();
    final current = _auth.currentUser?.email ?? '';
    final error = await AccountValidator.validateEmail(
      email,
      localeProvider,
      section,
      checkExistence: email != current,
    );
    setState(() {
      emailError = error;
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final error = password.isNotEmpty
        ? AccountValidator.validatePassword(password, localeProvider, section)
        : null;
    setState(() {
      passwordError = error;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (username != _initialUsername) {
        await _currentUser?.updateDisplayName(username);
      }
      if (email != _initialEmail) {
        await _currentUser?.updateEmail(email);
      }
      if (password.isNotEmpty) {
        await _currentUser?.updatePassword(password);
      }

      await _currentUser?.reload();
      _currentUser = _auth.currentUser;

      await _userService.updateUser(_currentUser!.uid, {
        'displayName': username,
        'email': email,
      });

      AppSnackBar.show(
        context,
        localeProvider.translate(section, 'profile_updated'),
        type: SnackBarType.success,
      );

      setState(() {
        _initialUsername = username;
        _initialEmail = email;
        _passwordController.clear();
      });

      Navigator.pop(context);
    } catch (error) {
      AppSnackBar.show(
        context,
        localeProvider.translate(section, 'profile_update_error'),
        type: SnackBarType.error,
      );
    }

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'username'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
              ),
              if (usernameError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    usernameError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'email'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4),
                  child: Text(
                    emailError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'password_hint'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
                obscureText: true,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!_isSaving && isFormValid && hasChanged)
                      ? _saveChanges
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localeProvider.translate(section, 'save_changes')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
