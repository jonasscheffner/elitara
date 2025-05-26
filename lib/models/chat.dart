import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/message.dart';

class Chat {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final DateTime lastUpdated;
  final Map<String, bool> isDeleted;
  final Map<String, DateTime> lastClearedAt;
  final Map<String, DateTime> lastReadAt;
  final bool hasUnread;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastUpdated,
    required this.isDeleted,
    required this.lastClearedAt,
    required this.lastReadAt,
    required this.hasUnread,
  });

  factory Chat.fromDocument(
      String docId, Map<String, dynamic> data, String userId) {
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

    Map<String, DateTime> read = {};
    if (data['lastReadAt'] != null) {
      (data['lastReadAt'] as Map).forEach((key, value) {
        read[key] = value is Timestamp
            ? value.toDate()
            : DateTime.parse(value.toString());
      });
    }

    final DateTime? lastUpdated = (data['lastUpdated'] as Timestamp?)?.toDate();
    final DateTime? lastRead = read[userId];
    final DateTime? clearedAt = cleared[userId];
    final bool isDeleted = deleted[userId] ?? false;

    final Message? lastMsg = data['lastMessage'] != null
        ? Message.fromDocument(data['lastMessage'])
        : null;

    final bool isOwnLastMessage = lastMsg?.senderId == userId;

    bool isUnread = false;
    if (!isOwnLastMessage) {
      if (!isDeleted ||
          (clearedAt != null &&
              lastUpdated != null &&
              lastUpdated.isAfter(clearedAt))) {
        if (lastUpdated != null &&
            (lastRead == null || lastUpdated.isAfter(lastRead))) {
          isUnread = true;
        }
      }
    }

    return Chat(
      id: docId,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: lastMsg,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isDeleted: deleted,
      lastClearedAt: cleared,
      lastReadAt: read,
      hasUnread: isUnread,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'lastUpdated': lastUpdated,
      'isDeleted': isDeleted,
      'lastClearedAt': lastClearedAt,
      'lastReadAt': lastReadAt,
    };
  }
}
