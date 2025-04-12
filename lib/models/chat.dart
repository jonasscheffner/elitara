import 'message.dart';

class Chat {
  final String id;
  final List<String> participants;
  final Message? lastMessage;
  final DateTime lastUpdated;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.lastUpdated,
  });

  factory Chat.fromDocument(String docId, Map<String, dynamic> data) {
    return Chat(
      id: docId,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] != null
          ? Message.fromDocument(data['lastMessage'])
          : null,
      lastUpdated: data['lastUpdated']?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage?.toMap(),
      'lastUpdated': lastUpdated,
    };
  }
}
