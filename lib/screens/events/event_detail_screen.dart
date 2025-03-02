import 'package:elitara/models/access_type.dart';
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

  EventDetailScreen({super.key, required this.eventId});

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
          final AccessType accessType = eventMap.containsKey('accessType') &&
                  eventMap['accessType'] is String
              ? AccessTypeExtension.fromString(eventMap['accessType'] as String)
              : AccessType.public;
          String accessText = accessType == AccessType.inviteOnly
              ? localeProvider.translate(section, 'access_invite_only')
              : localeProvider.translate(section, 'access_public');
          final currentUser = FirebaseAuth.instance.currentUser;
          bool isJoined = false;
          bool isOnWaitlist = false;
          if (currentUser != null) {
            isJoined = participantIds.contains(currentUser.uid);
            List<dynamic> waitlist = eventMap['waitlist'] ?? [];
            isOnWaitlist = waitlist.any((element) =>
                element is Map && element['uid'] == currentUser.uid);
          }
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
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              "${localeProvider.translate(section, 'date')}: ",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              LocalizedDateTimeFormatter.getFormattedDate(
                                  context, dateTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              "${localeProvider.translate(section, 'time')}: ",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              LocalizedDateTimeFormatter.getFormattedTime(
                                  context, dateTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${localeProvider.translate(section, 'location')}: ",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    eventMap['location'],
                    style: const TextStyle(fontSize: 16),
                    softWrap: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${localeProvider.translate(section, 'description')}: ",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    eventMap['description'],
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${localeProvider.translate(section, 'access')}: ",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        accessText,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        participantLimit != null
                            ? "${localeProvider.translate(section, 'participants')} ($currentCount / $participantLimit):"
                            : "${localeProvider.translate(section, 'participants')} ($currentCount):",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...participantIds.map((uid) {
                              List<Widget> children = [
                                UserDisplayName(
                                  uid: uid,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: uid == hostId
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (uid == hostId)
                                  Text(
                                    " (${localeProvider.translate(section, 'host_label')})",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                if (uid != participantIds.last)
                                  const Text(", "),
                              ];
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: children,
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Builder(
                      builder: (context) {
                        if (currentUser != null && currentUser.uid == hostId) {
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
                                    borderRadius: BorderRadius.circular(12))),
                            child: Text(localeProvider.translate(
                                section, 'edit_event')),
                          );
                        } else if (isJoined) {
                          return ElevatedButton(
                            onPressed: () async {
                              await _eventService.leaveEvent(
                                  eventId, currentUser!.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(localeProvider.translate(
                                      section, 'leave')),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                textStyle: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                            child: Text(
                                localeProvider.translate(section, 'leave')),
                          );
                        } else {
                          if (accessType == AccessType.public) {
                            return ElevatedButton(
                              onPressed: () async {
                                await _eventService.registerForEvent(
                                    eventId, currentUser!.uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(localeProvider.translate(
                                        section, 'registered')),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  textStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text(
                                  localeProvider.translate(section, 'join')),
                            );
                          } else if (eventMap['waitlistEnabled'] == true) {
                            if (isOnWaitlist) {
                              return ElevatedButton(
                                onPressed: () async {
                                  final waitlistEntry = {
                                    "uid": currentUser!.uid,
                                    "name": currentUser.displayName ?? "Unknown"
                                  };
                                  await _eventService.leaveWaitlist(
                                      eventId, waitlistEntry);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localeProvider.translate(
                                          section, 'leave_waitlist')),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40),
                                    textStyle: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(localeProvider.translate(
                                    section, 'leave_waitlist')),
                              );
                            } else {
                              return ElevatedButton(
                                onPressed: () async {
                                  final waitlistEntry = {
                                    "uid": currentUser!.uid,
                                    "name": currentUser.displayName ?? "Unknown"
                                  };
                                  await _eventService.joinWaitlist(
                                      eventId, waitlistEntry);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(localeProvider.translate(
                                          section, 'waitlist_registered')),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40),
                                    textStyle: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12))),
                                child: Text(localeProvider.translate(
                                    section, 'join_waitlist')),
                              );
                            }
                          } else {
                            return Container();
                          }
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
