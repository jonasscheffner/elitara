import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/message_type.dart';

class Message {
  final String? id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? data;

  Message({
    this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.data,
  });

  factory Message.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      type: MessageType.fromString(data['type'] ?? 'text'),
      data:
          data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
    );
  }

  factory Message.fromDocument(Map<String, dynamic> data) {
    return Message(
      id: data['id'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      type: MessageType.fromString(data['type'] ?? 'text'),
      data:
          data['data'] != null ? Map<String, dynamic>.from(data['data']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
      'type': type.toShortString(),
      'data': data,
    };
  }
}
