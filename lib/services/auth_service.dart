import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      throw e;
    }
  }

  Future<void> registerWithEmailPassword(
      String email, String username, String password) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(username);
        await UserService().createUser(user.uid, {
          'uid': user.uid,
          'displayName': username,
          'email': email,
        });
      }
    } catch (e) {
      throw e;
    }
  }
}
