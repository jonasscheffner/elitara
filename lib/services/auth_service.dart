import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
          await _auth.createUserWithEmailAndPassword(
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

  Future<bool> checkUsernameExists(String username) async {
    final result = await _firestore
        .collection('users')
        .where('displayName', isEqualTo: username)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }

  Future<bool> checkEmailExists(String email) async {
    final result = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return result.docs.isNotEmpty;
  }
}
