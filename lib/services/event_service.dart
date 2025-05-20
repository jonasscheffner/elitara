import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/event_status.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int itemsPerPage;
  static const int goldMonthlyLimit = 5;

  EventService({this.itemsPerPage = 10});

  Future<QuerySnapshot> getInitialEvents() async {
    return await _firestore
        .collection('events')
        .where('status', isEqualTo: EventStatus.active.value)
        .orderBy('date', descending: true)
        .limit(itemsPerPage)
        .get();
  }

  Future<QuerySnapshot> getMoreEvents(DocumentSnapshot lastDocument) async {
    return await _firestore
        .collection('events')
        .where('status', isEqualTo: EventStatus.active.value)
        .orderBy('date', descending: true)
        .startAfterDocument(lastDocument)
        .limit(itemsPerPage)
        .get();
  }

  Future<bool> isGoldLimitReached(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final snapshot = await _firestore
        .collection('events')
        .where('host', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: startOfMonth)
        .get();

    return snapshot.docs.length >= goldMonthlyLimit;
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
        .update({'status': EventStatus.canceled.value});
  }

  Future<DocumentReference> createEvent(Map<String, dynamic> eventData) async {
    return await _firestore.collection('events').add(eventData);
  }

  Future<void> registerForEvent(String eventId, String uid) async {
    final docRef = _firestore.collection('events').doc(eventId);

    await docRef.update({
      'participants': FieldValue.arrayUnion([uid]),
    });

    final snapshot = await docRef.get();
    final data = snapshot.data() as Map<String, dynamic>;
    final List<dynamic> waitlistRaw = data['waitlist'] ?? [];

    Map<String, dynamic>? entryToRemove;
    for (var e in waitlistRaw) {
      if (e is Map<String, dynamic> && e['uid'] == uid) {
        entryToRemove = e;
        break;
      }
    }

    if (entryToRemove != null) {
      await leaveWaitlist(eventId, entryToRemove);
    }
  }

  Future<void> leaveEvent(String eventId, String uid) async {
    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([uid])
    });
  }

  Future<QuerySnapshot> getUserHostedEvents(String userId) async {
    return await _firestore
        .collection('events')
        .where('status', isEqualTo: EventStatus.active.value)
        .where('host', isEqualTo: userId)
        .orderBy('date', descending: true)
        .limit(itemsPerPage)
        .get();
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
