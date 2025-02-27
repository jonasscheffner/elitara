import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> getCurrentMembership() async {
    User? user = _auth.currentUser;
    if (user == null) return "";

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      return (userDoc.data() as Map<String, dynamic>)['membership'] ?? "";
    }
    return "";
  }

  Future<void> updateMembership(String newMembership) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'membership': newMembership,
    });
  }

  Future<void> cancelMembership() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'membership': null,
    });
  }
}
