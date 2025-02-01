import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/localization/locale_provider.dart';

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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  final String section = 'settings.account_screen';

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _usernameController =
        TextEditingController(text: _currentUser?.displayName ?? '');
    _emailController = TextEditingController(text: _currentUser?.email ?? '');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'profile_updated')),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "${Localizations.of<LocaleProvider>(context, LocaleProvider)!.translate(section, 'profile_update_error')}$error"),
        ),
      );
    }
    setState(() {
      _isSaving = false;
    });
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
                  onPressed: _isSaving
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
