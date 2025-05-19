import 'package:elitara/utils/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/services/event_service.dart';
import 'package:elitara/screens/events/event_detail_screen.dart';

class EventInvitationMessage extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final String chatId;
  final String messageId;
  final bool isSender;
  final String section = 'chat.event_invitation';
  final Function()? onJoinedCallback;

  const EventInvitationMessage({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.chatId,
    required this.messageId,
    required this.isSender,
    this.onJoinedCallback,
  }) : super(key: key);

  @override
  State<EventInvitationMessage> createState() => _EventInvitationMessageState();
}

class _EventInvitationMessageState extends State<EventInvitationMessage> {
  final _eventService = EventService();
  final currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  bool _canJoin = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Future<void> _checkJoinStatus() async {
    if (currentUser == null) return;

    final uid = currentUser!.uid;
    final doc = await _eventService.getEvent(widget.eventId);
    if (!doc.exists) return;

    final event = Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);

    if (event.participants.contains(uid)) {
      setState(() {
        _canJoin = false;
        _isLoading = false;
      });
      return;
    }

    final messageDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.messageId)
        .get();

    final messageData = messageDoc.data();
    final acceptedBy =
        List<String>.from(messageData?['data']?['acceptedBy'] ?? []);

    setState(() {
      _canJoin = !acceptedBy.contains(uid);
      _isLoading = false;
    });
  }

  Future<void> _handleJoin() async {
    if (currentUser == null) return;
    final uid = currentUser!.uid;

    setState(() {
      _isJoining = true;
    });

    await _eventService.registerForEvent(widget.eventId, uid);

    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.messageId);

    await messageRef.update({
      'data.acceptedBy': FieldValue.arrayUnion([uid])
    });

    widget.onJoinedCallback?.call();

    setState(() {
      _canJoin = false;
      _isJoining = false;
    });

    AppSnackBar.show(
      context,
      Localizations.of<LocaleProvider>(context, LocaleProvider)!
          .translate(widget.section, 'joined_successfully'),
      type: SnackBarType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    final alignment =
        widget.isSender ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  locale.translate(widget.section, 'event_invitation_title'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.eventTitle,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (!_isLoading)
                  Row(
                    mainAxisAlignment: widget.isSender
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (!widget.isSender && _canJoin)
                        ElevatedButton.icon(
                          onPressed: _isJoining ? null : _handleJoin,
                          icon: _isJoining
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                              locale.translate(widget.section, 'join_event')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            textStyle: const TextStyle(fontSize: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EventDetailScreen(eventId: widget.eventId),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(
                            locale.translate(widget.section, 'view_event')),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          textStyle: const TextStyle(fontSize: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
