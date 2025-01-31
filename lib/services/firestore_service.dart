import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createEvent(Map<String, dynamic> eventData) async {
    await _firestore.collection('events').add(eventData);
  }

  Stream<QuerySnapshot> getEvents() {
    return _firestore.collection('events').snapshots();
  }
}
