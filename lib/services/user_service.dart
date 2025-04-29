import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 20;

  Future<Map<String, dynamic>> getUser(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return doc.data() as Map<String, dynamic>;
    } else {
      return {'uid': uid, 'displayName': 'Unknown'};
    }
  }

  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    await _firestore.collection('users').doc(uid).set(userData);
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<Map<String, dynamic>> streamUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data() as Map<String, dynamic>);
  }

  Future<String> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }
    return user.uid;
  }

  Future<List<QueryDocumentSnapshot>> searchInitialUsers(
      String searchTerm) async {
    Query query =
        _firestore.collection('users').orderBy('displayName').limit(_pageSize);

    final querySnapshot = await query.get();

    final lowerSearch = searchTerm.toLowerCase();
    return querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final displayName = (data['displayName'] ?? '').toString().toLowerCase();
      return displayName.contains(lowerSearch);
    }).toList();
  }

  Future<List<QueryDocumentSnapshot>> searchMoreUsers(
      String searchTerm, DocumentSnapshot lastDoc) async {
    Query query = _firestore
        .collection('users')
        .orderBy('displayName')
        .startAfterDocument(lastDoc)
        .limit(_pageSize);

    final querySnapshot = await query.get();

    final lowerSearch = searchTerm.toLowerCase();
    return querySnapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final displayName = (data['displayName'] ?? '').toString().toLowerCase();
      return displayName.contains(lowerSearch);
    }).toList();
  }
}
