import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/message.dart';

class Chat {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final DateTime lastUpdated;
  final Map<String, bool> isDeleted;
  final Map<String, DateTime> lastClearedAt;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastUpdated,
    required this.isDeleted,
    required this.lastClearedAt,
  });

  factory Chat.fromDocument(String docId, Map<String, dynamic> data) {
    Map<String, bool> deleted = {};
    if (data['isDeleted'] != null) {
      (data['isDeleted'] as Map).forEach((key, value) {
        deleted[key] = value as bool;
      });
    }

    Map<String, DateTime> cleared = {};
    if (data['lastClearedAt'] != null) {
      (data['lastClearedAt'] as Map).forEach((key, value) {
        cleared[key] = value is Timestamp
            ? value.toDate()
            : DateTime.parse(value.toString());
      });
    }
    return Chat(
      id: docId,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] != null
          ? Message.fromDocument(data['lastMessage'])
          : null,
      lastUpdated: data['lastUpdated']?.toDate() ?? DateTime.now(),
      isDeleted: deleted,
      lastClearedAt: cleared,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'lastUpdated': lastUpdated,
      'isDeleted': isDeleted,
      'lastClearedAt': lastClearedAt,
    };
  }
}
