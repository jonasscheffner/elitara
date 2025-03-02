import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int itemsPerPage;

  EventService({this.itemsPerPage = 10});

  Future<QuerySnapshot> getInitialEvents() async {
    Query query = _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: true)
        .limit(itemsPerPage);
    return await query.get();
  }

  Future<QuerySnapshot> getMoreEvents(DocumentSnapshot lastDocument) async {
    Query query = _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .orderBy('date', descending: true)
        .startAfterDocument(lastDocument)
        .limit(itemsPerPage);
    return await query.get();
  }

  Stream<DocumentSnapshot> getEventStream(String eventId) {
    return _firestore.collection('events').doc(eventId).snapshots();
  }

  Future<DocumentSnapshot> getEvent(String eventId) async {
    return await _firestore.collection('events').doc(eventId).get();
  }

  Future<void> updateEvent(
      String eventId, Map<String, dynamic> eventData) async {
    await _firestore.collection('events').doc(eventId).update(eventData);
  }

  Future<void> cancelEvent(String eventId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .update({'status': 'canceled'});
  }

  Future<DocumentReference> createEvent(Map<String, dynamic> eventData) async {
    return await _firestore.collection('events').add(eventData);
  }

  Future<void> registerForEvent(String eventId, String uid) async {
    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([uid])
    });
  }

  Future<void> leaveEvent(String eventId, String uid) async {
    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([uid])
    });
  }

  Future<QuerySnapshot> getUserHostedEvents(String userId) async {
    Query query = _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .where('host', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(itemsPerPage);
    return await query.get();
  }

  Future<void> joinWaitlist(
      String eventId, Map<String, dynamic> waitlistEntry) async {
    await _firestore.collection('events').doc(eventId).update({
      'waitlist': FieldValue.arrayUnion([waitlistEntry])
    });
  }

  Future<void> leaveWaitlist(
      String eventId, Map<String, dynamic> waitlistEntry) async {
    await _firestore.collection('events').doc(eventId).update({
      'waitlist': FieldValue.arrayRemove([waitlistEntry])
    });
  }
}
