import 'package:elitara/screens/chat/widgets/chat_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/localization/locale_provider.dart';
import '../../services/chat_service.dart';
import '../../models/message.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';

class ChatDetailScreen extends StatefulWidget {
  final String? chatId;
  final String otherUserId;

  const ChatDetailScreen({Key? key, this.chatId, required this.otherUserId})
      : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final String section = 'chat';
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;
  String? _chatId;
  bool _isMessageValid = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatId = widget.chatId;
    _messageController.addListener(() {
      final bool isValid = _messageController.text.trim().isNotEmpty;
      if (isValid != _isMessageValid) {
        setState(() {
          _isMessageValid = isValid;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final message = Message(
      senderId: _currentUserId,
      text: text,
      timestamp: DateTime.now(),
    );
    if (_chatId == null) {
      _chatId =
          await _chatService.createChat(_currentUserId, widget.otherUserId);
      setState(() {});
    }
    await _chatService.sendMessage(_chatId!, message);
    _messageController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 60,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: UserDisplayName(
          uid: widget.otherUserId,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId != null
                ? StreamBuilder<List<Message>>(
                    stream: _chatService.getMessages(_chatId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                              localeProvider.translate(section, 'no_messages')),
                        );
                      }
                      final messages = snapshot.data!;
                      return ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isCurrentUser =
                              message.senderId == _currentUserId;
                          return Container(
                            alignment: isCurrentUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue[100]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: Text(message.text),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child:
                        Text(localeProvider.translate(section, 'no_messages')),
                  ),
          ),
          ChatInputWidget(
            controller: _messageController,
            onSend: _sendMessage,
            isMessageValid: _isMessageValid,
          ),
        ],
      ),
    );
  }
}
