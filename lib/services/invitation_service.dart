import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/invitation.dart';
import 'package:elitara/models/message.dart';
import 'package:elitara/models/message_type.dart';
import 'package:elitara/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationService {
  final _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  Future<void> sendEventInvitation({
    required String targetUserId,
    required String eventId,
    required String eventTitle,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final invitationRef = await _firestore.collection('invitations').add(
          Invitation(
            id: '',
            eventId: eventId,
            userId: targetUserId,
            invitedBy: currentUser.uid,
            status: InvitationStatus.pending,
            createdAt: DateTime.now(),
          ).toMap(),
        );

    final invitationId = invitationRef.id;

    String? chatId =
        await _chatService.getExistingChat(currentUser.uid, targetUserId);
    chatId ??= await _chatService.createChat(currentUser.uid, targetUserId);

    final message = Message(
      senderId: currentUser.uid,
      text: '📩',
      timestamp: DateTime.now(),
      type: MessageType.eventInvitation,
      invitationId: invitationId,
      eventId: eventId,
      eventTitle: eventTitle,
    );

    await _chatService.sendMessage(chatId, message);
  }

  Future<void> revokeInvitationById(String invitationId) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'revoked',
    });
  }

  Future<Invitation?> getInvitationById(String id) async {
    final doc = await _firestore.collection('invitations').doc(id).get();
    if (!doc.exists) return null;
    return Invitation.fromDoc(doc);
  }

  Future<void> markInvitationAcceptedById(String id) async {
    await _firestore.collection('invitations').doc(id).update({
      'status': 'accepted',
    });
  }

  Future<Map<String, String>> getPendingInvitationsForEvent(
      String eventId) async {
    final snapshot = await _firestore
        .collection('invitations')
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: 'pending')
        .get();

    final Map<String, String> result = {};
    for (var doc in snapshot.docs) {
      final data = Invitation.fromDoc(doc);
      result[data.userId] = doc.id;
    }
    return result;
  }

  Future<bool> isUserCurrentlyInvited(String userId, String eventId) async {
    final eventDoc = await _firestore.collection('events').doc(eventId).get();
    if (!eventDoc.exists) return false;

    final data = eventDoc.data()!;
    final List<dynamic> participants = data['participants'] ?? [];
    if (participants.contains(userId)) return true;

    final snapshot = await _firestore
        .collection('invitations')
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }
}
