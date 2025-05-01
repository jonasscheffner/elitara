import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/membership_type.dart';
import 'package:elitara/screens/events/widgets/invite_users_dialog.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';
import 'package:elitara/services/membership_service.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:flutter/material.dart';
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
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(locale.translate(section, 'title')),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _eventService.getEventStream(eventId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snap.data!;
          final ev = Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);

          final hostId = ev.host;
          final participants = List<String>.from(ev.participants);
          participants.remove(hostId);
          participants.insert(0, hostId);

          final dateTime = ev.date;
          final int? participantLimit = ev.participantLimit;
          final int currentCount = participants.length;

          final accessEnum = ev.accessType;
          final String accessText = accessEnum == AccessType.inviteOnly
              ? locale.translate(section, 'access_invite_only')
              : locale.translate(section, 'access_public');

          final bool waitlistEnabled = ev.waitlistEnabled;
          final int currentWaitlistCount = ev.waitlist.length;
          final int? waitlistLimit = ev.waitlistLimit;

          bool isJoined = false;
          bool isOnWaitlist = false;
          if (currentUser != null) {
            isJoined = participants.contains(currentUser.uid);
            isOnWaitlist = ev.waitlist.any((e) => e['uid'] == currentUser.uid);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ev.title,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text("${locale.translate(section, 'date')}: ",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                LocalizedDateTimeFormatter.getFormattedDate(
                                    context, dateTime),
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Text("${locale.translate(section, 'time')}: ",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(
                                LocalizedDateTimeFormatter.getFormattedTime(
                                    context, dateTime),
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text("${locale.translate(section, 'location')}: ",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(ev.location, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  Text("${locale.translate(section, 'description')}: ",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(ev.description,
                      style: const TextStyle(fontSize: 16, height: 1.4)),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${locale.translate(section, 'access')}: ",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(accessText, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      Text(
                        participantLimit != null
                            ? "${locale.translate(section, 'participants')} ($currentCount / $participantLimit):"
                            : "${locale.translate(section, 'participants')} ($currentCount):",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: participants.map((uid) {
                            final isHost = uid == hostId;
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                UserDisplayName(
                                    uid: uid,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isHost
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                                if (isHost)
                                  Text(
                                    " (${locale.translate(section, 'host_label')})",
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                if (uid != participants.last) const Text(", "),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: FutureBuilder<MembershipType>(
                      future: MembershipService().getCurrentMembership(),
                      builder: (ctx, msnap) {
                        if (msnap.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        final membership = msnap.data ?? MembershipType.guest;
                        final isHost = currentUser?.uid == hostId;
                        final isCoHost = currentUser != null &&
                            ev.coHosts.contains(currentUser.uid);
                        final canInvite = ev.canInvite;
                        final showInvite = isHost ||
                            (canInvite &&
                                (membership == MembershipType.gold ||
                                    membership == MembershipType.platinum));
                        final showEdit = isHost || isCoHost;

                        if (showInvite || showEdit) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showInvite)
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final cp = [
                                        ...ev.participants,
                                        ...ev.waitlist
                                            .map((e) => e['uid'] as String)
                                      ];
                                      showGeneralDialog(
                                        context: context,
                                        barrierDismissible: true,
                                        barrierLabel: "Invite Users",
                                        pageBuilder: (c, a1, a2) => Stack(
                                          children: [
                                            BackdropFilter(
                                              filter: ImageFilter.blur(
                                                  sigmaX: 5, sigmaY: 5),
                                              child: Container(
                                                  color: const Color(0x80000000)
                                                      .withOpacity(0)),
                                            ),
                                            Center(
                                              child: InviteUsersDialog(
                                                eventId: ev.id,
                                                eventTitle: ev.title,
                                                currentParticipants: cp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.group_add),
                                    label: Text(locale.translate(
                                        section, 'invite_users')),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        backgroundColor:
                                            Colors.deepPurpleAccent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                  ),
                                if (showEdit) const SizedBox(height: 12),
                                if (showEdit)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/editEvent',
                                          arguments: ev.id);
                                    },
                                    icon: const Icon(Icons.edit),
                                    label: Text(locale.translate(
                                        section, 'edit_event')),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        backgroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                  ),
                              ],
                            ),
                          );
                        }

                        if (isJoined) {
                          return ElevatedButton(
                            onPressed: () async {
                              await _eventService.leaveEvent(
                                  ev.id, currentUser!.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(locale.translate(section, 'leave')),
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
                            child: Text(locale.translate(section, 'leave')),
                          );
                        }

                        if (accessEnum == AccessType.public &&
                            (participantLimit == null ||
                                currentCount < participantLimit)) {
                          return ElevatedButton(
                            onPressed: () async {
                              await _eventService.registerForEvent(
                                  ev.id, currentUser!.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      locale.translate(section, 'registered')),
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
                            child: Text(locale.translate(section, 'join')),
                          );
                        }

                        if (participantLimit != null &&
                            currentCount >= participantLimit &&
                            waitlistEnabled) {
                          if (isOnWaitlist) {
                            return ElevatedButton(
                              onPressed: () async {
                                final entry = {
                                  'uid': currentUser!.uid,
                                  'name': currentUser.displayName ?? 'Unknown'
                                };
                                await _eventService.leaveWaitlist(ev.id, entry);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(locale.translate(
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
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text(
                                  locale.translate(section, 'leave_waitlist')),
                            );
                          } else {
                            if (waitlistLimit != null &&
                                currentWaitlistCount >= waitlistLimit) {
                              return Text(
                                locale.translate(section, 'waitlist_full'),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              );
                            }
                            return ElevatedButton(
                              onPressed: () async {
                                final entry = {
                                  'uid': currentUser!.uid,
                                  'name': currentUser.displayName ?? 'Unknown'
                                };
                                await _eventService.joinWaitlist(ev.id, entry);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(locale.translate(
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
                                      borderRadius: BorderRadius.circular(12))),
                              child: Text(
                                  locale.translate(section, 'join_waitlist')),
                            );
                          }
                        }

                        if (participantLimit != null &&
                            currentCount >= participantLimit) {
                          return Text(
                            locale.translate(section, 'event_full'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          );
                        }

                        return const SizedBox.shrink();
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
