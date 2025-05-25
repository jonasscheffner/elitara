import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, revoked }

InvitationStatus invitationStatusFromString(String status) {
  switch (status) {
    case 'pending':
      return InvitationStatus.pending;
    case 'accepted':
      return InvitationStatus.accepted;
    case 'revoked':
      return InvitationStatus.revoked;
    default:
      throw ArgumentError('Unknown status: $status');
  }
}

String invitationStatusToString(InvitationStatus status) {
  return status.name;
}

class Invitation {
  final String id;
  final String eventId;
  final String userId;
  final String invitedBy;
  final InvitationStatus status;
  final DateTime createdAt;

  Invitation({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.invitedBy,
    required this.status,
    required this.createdAt,
  });

  factory Invitation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invitation(
      id: doc.id,
      eventId: data['eventId'],
      userId: data['userId'],
      invitedBy: data['invitedBy'],
      status: invitationStatusFromString(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'invitedBy': invitedBy,
      'status': invitationStatusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
