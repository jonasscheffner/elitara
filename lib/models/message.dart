import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/message_type.dart';

class Message {
  final String? id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? invitationId;
  final String? eventId;
  final String? eventTitle;

  Message({
    this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.invitationId,
    this.eventId,
    this.eventTitle,
  });

  factory Message.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.fromString(data['type'] ?? 'text'),
      invitationId: data['invitationId'],
      eventId: data['eventId'],
      eventTitle: data['eventTitle'],
    );
  }

  factory Message.fromDocument(Map<String, dynamic> data) {
    return Message(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: MessageType.fromString(data['type'] ?? 'text'),
      invitationId: data['invitationId'],
      eventId: data['eventId'],
      eventTitle: data['eventTitle'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'type': type.toShortString(),
      'invitationId': invitationId,
      'eventId': eventId,
      'eventTitle': eventTitle,
    };
  }
}
