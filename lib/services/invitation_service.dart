import 'package:elitara/models/message.dart';
import 'package:elitara/models/message_type.dart';
import 'package:elitara/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvitationService {
  final ChatService _chatService = ChatService();

  Future<void> sendEventInvitation({
    required String targetUserId,
    required String eventId,
    required String eventTitle,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String? chatId =
        await _chatService.getExistingChat(currentUser.uid, targetUserId);
    chatId ??= await _chatService.createChat(currentUser.uid, targetUserId);

    final message = Message(
      senderId: currentUser.uid,
      text: '📩',
      timestamp: DateTime.now(),
      type: MessageType.eventInvitation,
      data: {
        'eventId': eventId,
        'eventTitle': eventTitle,
      },
    );

    await _chatService.sendMessage(chatId, message);
  }
}
