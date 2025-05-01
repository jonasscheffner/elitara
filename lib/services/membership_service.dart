import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/membership_type.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembershipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<MembershipType> getCurrentMembership() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user is logged in");

    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists || userDoc.data() == null) {
      throw Exception("User not found in database");
    }

    final membershipStr =
        (userDoc.data() as Map<String, dynamic>)['membership'] ?? '';

    return MembershipTypeExtension.fromString(membershipStr);
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
