import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/services/event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/screens/events/event_detail_screen.dart';

class EventInvitationMessage extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final String chatId;
  final bool isSender;
  final String section = 'chat.event_invitation';
  final Function()? onJoinedCallback;

  const EventInvitationMessage({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.chatId,
    required this.isSender,
    this.onJoinedCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    final EventService _eventService = EventService();
    final currentUser = FirebaseAuth.instance.currentUser;

    final alignment = isSender ? Alignment.centerRight : Alignment.centerLeft;
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localeProvider.translate(section, 'event_invitation_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  eventTitle,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: isSender
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!isSender)
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (currentUser == null) return;

                          final eventDoc =
                              await _eventService.getEvent(eventId);
                          if (!eventDoc.exists) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(localeProvider.translate(
                                  section, 'event_not_found')),
                            ));
                            return;
                          }

                          final eventData =
                              eventDoc.data() as Map<String, dynamic>;
                          final participants = List<String>.from(
                              eventData['participants'] ?? []);
                          final participantLimit =
                              eventData['participantLimit'] as int?;

                          if (participantLimit != null &&
                              participants.length >= participantLimit) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(localeProvider.translate(
                                  section, 'event_full')),
                            ));
                            return;
                          }

                          await _eventService.registerForEvent(
                              eventId, currentUser.uid);

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(localeProvider.translate(
                                section, 'joined_successfully')),
                          ));

                          if (onJoinedCallback != null) {
                            onJoinedCallback!();
                          }
                        },
                        icon: const Icon(Icons.check),
                        label: Text(
                            localeProvider.translate(section, 'join_event')),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(eventId: eventId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label:
                          Text(localeProvider.translate(section, 'view_event')),
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
