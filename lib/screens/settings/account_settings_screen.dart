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
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  bool _isSaving = false;
  bool _hasChanged = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  final String section = 'settings.account_screen';
  final UserService _userService = UserService();
  String _initialUsername = '';
  String _initialEmail = '';

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _initialUsername = _currentUser?.displayName ?? '';
    _initialEmail = _currentUser?.email ?? '';
    _usernameController = TextEditingController(text: _initialUsername);
    _emailController = TextEditingController(text: _initialEmail);
    _usernameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _passwordController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    bool changed = _usernameController.text != _initialUsername ||
        _emailController.text != _initialEmail ||
        _passwordController.text.isNotEmpty;
    if (changed != _hasChanged) {
      setState(() {
        _hasChanged = changed;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });
    try {
      if (_usernameController.text.isNotEmpty &&
          _usernameController.text != _currentUser?.displayName) {
        await _currentUser?.updateDisplayName(_usernameController.text);
      }
      if (_emailController.text.isNotEmpty &&
          _emailController.text != _currentUser?.email) {
        await _currentUser?.updateEmail(_emailController.text);
      }
      if (_passwordController.text.isNotEmpty) {
        await _currentUser?.updatePassword(_passwordController.text);
      }
      await _currentUser?.reload();
      _currentUser = _auth.currentUser;
      await _userService.updateUser(_currentUser!.uid, {
        'displayName': _usernameController.text,
        'email': _emailController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'profile_updated')),
        ),
      );
      _initialUsername = _usernameController.text;
      _initialEmail = _emailController.text;
      _passwordController.clear();
      setState(() {
        _hasChanged = false;
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'profile_update_error')),
        ),
      );
    }
    setState(() {
      _isSaving = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'username'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localeProvider.translate(
                        section, 'username_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'email'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return localeProvider.translate(section, 'email_required');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'password_hint'),
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!_hasChanged || _isSaving)
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _saveChanges();
                          }
                        },
                  child: _isSaving
                      ? const CircularProgressIndicator()
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
