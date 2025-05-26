import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Chat>> getUserChats(String userId) {
    assert(() {
      _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();
      return true;
    }());

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Chat.fromDocument(doc.id, doc.data(), userId);
      }).where((chat) {
        bool deleted = chat.isDeleted[userId] ?? false;
        DateTime? clearedAt = chat.lastClearedAt[userId];
        if (deleted && clearedAt != null) {
          return chat.lastUpdated.isAfter(clearedAt);
        }
        return !deleted;
      }).toList();
    });
  }

  bool shouldMarkUnread(Map<String, dynamic> data, String userId) {
    final Timestamp? lastUpdatedTs = data['lastUpdated'];
    final Timestamp? lastReadTs = data['lastReadAt']?[userId];
    final lastUpdated = lastUpdatedTs?.toDate();
    final lastRead = lastReadTs?.toDate();

    final isDeleted = (data['isDeleted'] ?? {})[userId] ?? false;
    final clearedAtRaw = (data['lastClearedAt'] ?? {})[userId];
    DateTime? clearedAt;
    if (clearedAtRaw != null) {
      clearedAt = clearedAtRaw is Timestamp
          ? clearedAtRaw.toDate()
          : DateTime.tryParse(clearedAtRaw.toString());
    }

    final lastMessage = data['lastMessage'];
    final isOwnLastMessage =
        lastMessage != null && lastMessage['senderId'] == userId;
    if (isOwnLastMessage) return false;

    if (isDeleted && clearedAt != null) {
      if (lastUpdated == null || lastUpdated.isBefore(clearedAt)) {
        return false;
      }
    }

    return lastUpdated != null &&
        (lastRead == null || lastUpdated.isAfter(lastRead));
  }

  Stream<List<Message>> getMessages(String chatId, String userId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .switchMap((chatDoc) {
      DateTime? lastCleared;
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        if (data['lastClearedAt'] != null &&
            data['lastClearedAt'][userId] != null) {
          var ts = data['lastClearedAt'][userId];
          lastCleared =
              ts is Timestamp ? ts.toDate() : DateTime.parse(ts.toString());
        }
      }
      Query query = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: false);
      if (lastCleared != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: lastCleared);
      }
      return query.snapshots();
    }).map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Message.fromSnapshot(doc);
      }).toList();
    });
  }

  Future<QuerySnapshot> getAllChats() async {
    return await _firestore.collection('chats').get();
  }

  Future<List<Message>> getMessagesOnce(String chatId) async {
    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    return snapshot.docs.map((doc) => Message.fromSnapshot(doc)).toList();
  }

  Future<void> sendMessage(String chatId, Message message) async {
    try {
      final messageMap = message.toMap();

      final docRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(messageMap);

      final messageId = docRef.id;
      DocumentSnapshot chatDoc =
          await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data() as Map<String, dynamic>;
      List<dynamic> participants = chatData['participants'] ?? [];

      Map<String, dynamic> updatedIsDeleted =
          Map<String, dynamic>.from(chatData['isDeleted'] ?? {});
      for (var participant in participants) {
        if (participant != message.senderId) {
          updatedIsDeleted[participant] = false;
        }
      }

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': {
          ...messageMap,
          'id': messageId,
        },
        'lastUpdated': message.timestamp,
        'isDeleted': updatedIsDeleted,
      });
    } catch (e, stack) {}
  }

  Future<bool> hasUnreadChats(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final Timestamp? lastUpdatedTs = data['lastUpdated'];
      final Timestamp? lastReadTs =
          data['lastReadAt'] != null ? data['lastReadAt'][userId] : null;

      final Map<String, dynamic>? lastMessage = data['lastMessage'];

      if (lastMessage != null && lastMessage['senderId'] == userId) continue;

      final lastUpdated = lastUpdatedTs?.toDate();
      final lastRead = lastReadTs?.toDate();

      final isDeleted = (data['isDeleted'] ?? {})[userId] ?? false;
      final clearedAtRaw = (data['lastClearedAt'] ?? {})[userId];
      DateTime? clearedAt;
      if (clearedAtRaw != null) {
        clearedAt = clearedAtRaw is Timestamp
            ? clearedAtRaw.toDate()
            : DateTime.tryParse(clearedAtRaw.toString());
      }

      if (isDeleted && clearedAt != null) {
        if (lastUpdated == null || lastUpdated.isBefore(clearedAt)) {
          continue;
        }
      }

      if (lastUpdated != null &&
          (lastRead == null || lastUpdated.isAfter(lastRead))) {
        return true;
      }
    }

    return false;
  }

  Future<void> updateMessage(
      String chatId, String messageId, Map<String, dynamic> data) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update(data);
  }

  Future<String?> getExistingChat(
      String currentUserId, String otherUserId) async {
    final chatsQuery = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();
    for (var doc in chatsQuery.docs) {
      final data = doc.data();
      List<dynamic> participants = data['participants'] ?? [];
      if (!participants.contains(otherUserId)) continue;

      return doc.id;
    }
    return null;
  }

  Future<String> createChat(String currentUserId, String otherUserId) async {
    final chatData = {
      'participants': [currentUserId, otherUserId],
      'lastUpdated': DateTime.now(),
      'lastMessage': null,
      'isDeleted': {currentUserId: false, otherUserId: false},
      'lastClearedAt': {},
    };
    final newDoc = await _firestore.collection('chats').add(chatData);
    return newDoc.id;
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isDeleted.$userId': true,
      'lastClearedAt.$userId': DateTime.now(),
    });
  }

  Future<QuerySnapshot> getInitialChats(String userId, {int limit = 10}) async {
    return await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .limit(limit)
        .get();
  }

  Future<QuerySnapshot> getMoreChats(
      DocumentSnapshot lastChatDoc, String userId,
      {int limit = 10}) async {
    return await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .startAfterDocument(lastChatDoc)
        .limit(limit)
        .get();
  }

  Future<void> markChatRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastReadAt.$userId': DateTime.now(),
    });
  }
}
