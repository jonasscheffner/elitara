import 'package:elitara/screens/events/widgets/user_display_name.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/services/event_service.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  final String section = 'event_detail_screen';
  final EventService _eventService = EventService();

  EventDetailScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Text(localeProvider.translate(section, 'title')),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _eventService.getEventStream(eventId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var eventData = snapshot.data!;
          final Map<String, dynamic> eventMap =
              eventData.data() as Map<String, dynamic>;
          final DateTime dateTime = eventMap['date'].toDate();
          final String hostId = eventMap['host'] as String? ?? '';
          final List<dynamic> participantsDynamic =
              eventMap['participants'] ?? [];
          List<String> participantIds =
              participantsDynamic.map((p) => p.toString()).toList();
          participantIds.remove(hostId);
          participantIds.insert(0, hostId);

          final int? participantLimit =
              (eventMap.containsKey('participantLimit') &&
                      eventMap['participantLimit'] is int)
                  ? eventMap['participantLimit'] as int
                  : null;
          final int currentCount = participantIds.length;

          final String accessType = (eventMap.containsKey('accessType') &&
                  eventMap['accessType'] is String)
              ? eventMap['accessType'] as String
              : "public";
          String accessText = accessType == "invite_only"
              ? localeProvider.translate(section, 'access_invite_only')
              : localeProvider.translate(section, 'access_public');

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventMap['title'],
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    eventMap['description'],
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${localeProvider.translate(section, 'date')}: ${LocalizedDateTimeFormatter.getFormattedDate(context, dateTime)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "${localeProvider.translate(section, 'time')}: ${LocalizedDateTimeFormatter.getFormattedTime(context, dateTime)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${localeProvider.translate(section, 'location')}: ${eventMap['location']}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${localeProvider.translate(section, 'access')}: $accessText",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        participantLimit != null
                            ? "${localeProvider.translate(section, 'participants')} ($currentCount / $participantLimit):"
                            : "${localeProvider.translate(section, 'participants')} ($currentCount):",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: participantIds.map((uid) {
                            if (uid == hostId) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  UserDisplayName(
                                    uid: uid,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    " (${localeProvider.translate(section, 'host_label')})",
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              );
                            }
                            return UserDisplayName(
                              uid: uid,
                              style: const TextStyle(fontSize: 16),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Builder(
                      builder: (context) {
                        final currentUser = FirebaseAuth.instance.currentUser;
                        bool isHost =
                            currentUser != null && currentUser.uid == hostId;
                        if (isHost) {
                          return ElevatedButton(
                            onPressed: () => Navigator.pushNamed(
                                context, '/editEvent',
                                arguments: eventData.id),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              textStyle: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(localeProvider.translate(
                                section, 'edit_event')),
                          );
                        } else {
                          return ElevatedButton(
                            onPressed: () async {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser != null) {
                                await _eventService.registerForEvent(
                                    eventId, currentUser.uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localeProvider.translate(
                                        section, 'registered')),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              textStyle: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child:
                                Text(localeProvider.translate(section, 'join')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
