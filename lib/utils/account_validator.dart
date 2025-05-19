import 'package:elitara/services/auth_service.dart';
import 'package:elitara/localization/locale_provider.dart';

class AccountValidator {
  static final AuthService _authService = AuthService();

  static Future<String?> validateEmail(
      String email, LocaleProvider locale, String section,
      {bool checkExistence = true}) async {
    final result = _validateEmailFormat(email.trim());
    if (result != null) {
      return locale.translate(section, 'validation.$result');
    }
    if (checkExistence) {
      final exists = await _authService.checkEmailExists(email.trim());
      if (exists) {
        return locale.translate(section, 'validation.email_exists');
      }
    }
    return null;
  }

  static Future<String?> validateUsername(
      String username, LocaleProvider locale, String section,
      {bool checkExistence = true}) async {
    final result = _validateUsernameFormat(username.trim());
    if (result != null) {
      return locale.translate(section, 'validation.$result');
    }
    if (checkExistence) {
      final exists = await _authService.checkUsernameExists(username.trim());
      if (exists) {
        return locale.translate(section, 'validation.username_exists');
      }
    }
    return null;
  }

  static String? validatePassword(
      String password, LocaleProvider locale, String section) {
    final result = _validatePasswordFormat(password);
    if (result != null) {
      return locale.translate(section, 'validation.$result');
    }
    return null;
  }

  static String? _validateEmailFormat(String email) {
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'invalid_email';
    }
    return null;
  }

  static String? _validateUsernameFormat(String username) {
    if (username.length < 3 || username.length > 20) {
      return 'username_length';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(username)) {
      return 'username_chars';
    }
    return null;
  }

  static String? _validatePasswordFormat(String password) {
    if (password.length < 6) {
      return 'password_length';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'password_upper';
    }
    if (!RegExp(r'[!@#\$&*~.,;:_\-]').hasMatch(password)) {
      return 'password_special';
    }
    return null;
  }
}
