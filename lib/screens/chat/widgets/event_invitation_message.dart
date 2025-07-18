import 'package:elitara/models/invitation.dart';
import 'package:elitara/models/message.dart';
import 'package:elitara/services/invitation_service.dart';
import 'package:elitara/services/event_service.dart';
import 'package:elitara/screens/events/event_detail_screen.dart';
import 'package:elitara/utils/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/localization/locale_provider.dart';

class EventInvitationMessage extends StatefulWidget {
  final String chatId;
  final String messageId;
  final bool isSender;
  final String section = 'chat.event_invitation';
  final Function()? onJoinedCallback;

  const EventInvitationMessage({
    Key? key,
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
  final _invitationService = InvitationService();
  final currentUser = FirebaseAuth.instance.currentUser;

  Message? _message;
  InvitationStatus? _invitationStatus;
  bool _isLoading = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadMessageAndStatus();
  }

  Future<void> _loadMessageAndStatus() async {
    if (currentUser == null) return;

    final msgDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(widget.messageId)
        .get();

    final message = Message.fromSnapshot(msgDoc);

    if (message.invitationId == null) {
      if (!mounted) return;
      setState(() {
        _message = message;
        _invitationStatus = null;
        _isLoading = false;
      });
      return;
    }

    final invitation =
        await _invitationService.getInvitationById(message.invitationId!);

    if (!mounted) return;
    setState(() {
      _message = message;
      _invitationStatus = invitation?.status;
      _isLoading = false;
    });
  }

  Future<void> _handleJoin() async {
    if (currentUser == null || _message?.invitationId == null) return;

    if (!mounted) return;
    setState(() => _isJoining = true);

    await _eventService.registerForEvent(_message!.eventId!, currentUser!.uid);
    await _invitationService
        .markInvitationAcceptedById(_message!.invitationId!);

    widget.onJoinedCallback?.call();

    if (!mounted) return;
    setState(() {
      _invitationStatus = InvitationStatus.accepted;
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
            child: _isLoading || _message == null
                ? const SizedBox(
                    height: 110,
                    child: Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.translate(
                            widget.section, 'event_invitation_title'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _message!.eventTitle ?? 'Event',
                        style: const TextStyle(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (!widget.isSender)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _buildStatusWidget(locale),
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventDetailScreen(
                                    eventId: _message!.eventId!),
                              ),
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: Text(
                              locale.translate(widget.section, 'view_event'),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusWidget(LocaleProvider locale) {
    switch (_invitationStatus) {
      case InvitationStatus.accepted:
        return Text(
          locale.translate(widget.section, 'already_accepted'),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.orange,
          ),
        );
      case InvitationStatus.revoked:
        return Text(
          locale.translate(widget.section, 'invitation_revoked'),
          style: const TextStyle(
            fontSize: 14,
            color: Colors.red,
          ),
        );
      case InvitationStatus.pending:
        return ElevatedButton.icon(
          onPressed: _isJoining ? null : _handleJoin,
          icon: _isJoining
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.check),
          label: Text(locale.translate(widget.section, 'join_event')),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: const TextStyle(fontSize: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
