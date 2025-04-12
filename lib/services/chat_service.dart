import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Chat>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Chat.fromDocument(doc.id, doc.data());
      }).toList();
    });
  }

  Stream<List<Message>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return Message.fromDocument(doc.data());
      }).toList();
    });
  }

  Future<void> sendMessage(String chatId, Message message) async {
    final messageMap = message.toMap();
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageMap);

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': messageMap,
      'lastUpdated': message.timestamp,
    });
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
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }
    return null;
  }

  Future<String> createChat(String currentUserId, String otherUserId) async {
    final chatData = {
      'participants': [currentUserId, otherUserId],
      'lastUpdated': DateTime.now(),
      'lastMessage': null,
    };
    final newDoc = await _firestore.collection('chats').add(chatData);
    return newDoc.id;
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
}
