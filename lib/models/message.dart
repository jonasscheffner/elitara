import 'package:elitara/models/message_type.dart';

class Message {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? data;

  Message({
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.data,
  });

  factory Message.fromDocument(Map<String, dynamic> data) {
    return Message(
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
