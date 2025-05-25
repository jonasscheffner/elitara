import 'package:elitara/models/message_type.dart';
import 'package:elitara/screens/chat/widgets/chat_input_widget.dart';
import 'package:elitara/screens/chat/widgets/event_invitation_message.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
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
  Stream<List<Message>>? _messagesStream;
  late String _currentUserId;
  String? _chatId;
  bool _isMessageValid = false;
  bool _isMounted = true;

  bool _hasAutoScrolledInitially = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _chatId = widget.chatId;

    if (_chatId != null) {
      _messagesStream = _chatService.getMessages(_chatId!, _currentUserId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatService.markChatRead(_chatId!, _currentUserId);
      });
    }

    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final bool valid = _messageController.text.trim().isNotEmpty;
    if (valid != _isMessageValid) {
      if (_isMounted) {
        setState(() {
          _isMessageValid = valid;
        });
      }
    }
  }

  @override
  void dispose() {
    _isMounted = false;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final msg = Message(
      senderId: _currentUserId,
      text: text,
      timestamp: DateTime.now(),
    );

    if (_chatId == null) {
      _chatId =
          await _chatService.createChat(_currentUserId, widget.otherUserId);
      _messagesStream = _chatService.getMessages(_chatId!, _currentUserId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _chatService.markChatRead(_chatId!, _currentUserId);
      });
      if (_isMounted) {
        setState(() {});
      }
    }

    await _chatService.sendMessage(_chatId!, msg);
    if (_isMounted) {
      _messageController.clear();
    }

    await _chatService.markChatRead(_chatId!, _currentUserId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            Expanded(
              child: _chatId == null || _messagesStream == null
                  ? Center(
                      child: Text(
                          localeProvider.translate(section, 'no_messages')))
                  : StreamBuilder<List<Message>>(
                      stream: _messagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data ?? [];

                        if (!_hasAutoScrolledInitially && messages.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent,
                              );
                              _hasAutoScrolledInitially = true;
                            }
                          });
                        }

                        if (messages.isNotEmpty) {
                          final lastMessage = messages.last;
                          if (lastMessage.senderId != _currentUserId) {
                            _chatService.markChatRead(_chatId!, _currentUserId);
                          }
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Text(localeProvider.translate(
                                section, 'no_messages')),
                          );
                        }

                        return ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isCurrentUser =
                                message.senderId == _currentUserId;

                            final messageDate = DateTime(
                              message.timestamp.year,
                              message.timestamp.month,
                              message.timestamp.day,
                            );

                            DateTime? previousMessageDate;
                            if (index > 0) {
                              final prevMessage = messages[index - 1];
                              previousMessageDate = DateTime(
                                prevMessage.timestamp.year,
                                prevMessage.timestamp.month,
                                prevMessage.timestamp.day,
                              );
                            }

                            bool showDateHeader = previousMessageDate == null ||
                                messageDate != previousMessageDate;

                            Widget messageContent;

                            if (message.type == MessageType.eventInvitation &&
                                message.invitationId != null &&
                                message.eventId != null &&
                                message.eventTitle != null) {
                              messageContent = EventInvitationMessage(
                                chatId: _chatId!,
                                messageId: message.id!,
                                isSender: isCurrentUser,
                              );
                            } else {
                              messageContent = Container(
                                decoration: BoxDecoration(
                                  color: isCurrentUser
                                      ? Colors.blue[300]
                                      : Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                child: Text(
                                  message.text,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showDateHeader)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    child: Center(
                                      child: Text(
                                        LocalizedDateTimeFormatter
                                            .getChatFormattedDate(
                                                context, message.timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  alignment: isCurrentUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  child: messageContent,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
            ChatInputWidget(
              controller: _messageController,
              onSend: _sendMessage,
              isMessageValid: _isMessageValid,
            ),
          ],
        ),
      ),
    );
  }
}
