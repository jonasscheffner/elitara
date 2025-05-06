import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/membership_type.dart';
import 'package:elitara/screens/events/widgets/invite_users_dialog.dart';
import 'package:elitara/screens/events/widgets/participant_list_dialog.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';
import 'package:elitara/screens/events/widgets/waitlist_dialog.dart';
import 'package:elitara/services/membership_service.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/services/event_service.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final String section = 'event_detail_screen';
  final EventService _eventService = EventService();
  int _currentWaitlistCount = 0;

  Future<void> _updateWaitlistForEvent(String eventId) async {
    final doc = await _eventService.getEvent(eventId);
    final fresh = Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    setState(() {
      _currentWaitlistCount = fresh.waitlist.length;
    });
  }

  String _truncateTextToFit(String text, TextStyle style, String trailingText,
      double maxWidth, int maxLines) {
    final tp = TextPainter(
      text: TextSpan(text: text + trailingText, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );

    String truncated = text;
    while (truncated.isNotEmpty) {
      tp.text = TextSpan(text: truncated + '...' + trailingText, style: style);
      tp.layout(maxWidth: maxWidth);
      if (!tp.didExceedMaxLines) break;
      truncated = truncated.substring(0, truncated.length - 1);
    }
    return '$truncated...';
  }

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
        stream: _eventService.getEventStream(widget.eventId),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final doc = snap.data!;
          final ev = Event.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
          final hostId = ev.host;
          final dateTime = ev.date;
          final int? participantLimit = ev.participantLimit;
          final int currentCount = ev.participants.length;

          final availableWidth = MediaQuery.of(context).size.width - 32 - 48;

          final textSpan = TextSpan(
            text: ev.description,
            style: const TextStyle(fontSize: 16, height: 1.4),
          );

          final accessEnum = ev.accessType;
          final String accessText = accessEnum == AccessType.inviteOnly
              ? locale.translate(section, 'access_invite_only')
              : locale.translate(section, 'access_public');

          final bool waitlistEnabled = ev.waitlistEnabled;
          final int currentWaitlistCount = _currentWaitlistCount > 0
              ? _currentWaitlistCount
              : ev.waitlist.length;
          final int? waitlistLimit = ev.waitlistLimit;

          final bool isJoined =
              currentUser != null && ev.participants.contains(currentUser.uid);
          final bool isOnWaitlist = currentUser != null &&
              ev.waitlist.any((e) => e['uid'] == currentUser.uid);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
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
                                    const Icon(Icons.calendar_today, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      LocalizedDateTimeFormatter
                                          .getFormattedDate(context, dateTime),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      LocalizedDateTimeFormatter
                                          .getFormattedTime(context, dateTime),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                        accessEnum == AccessType.inviteOnly
                                            ? Icons.lock
                                            : Icons.public,
                                        size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      accessText,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.person, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: UserDisplayName(
                                          uid: hostId,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.place, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final text = ev.location;
                                    const textStyle = TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4);
                                    final readMoreText =
                                        ' ${locale.translate(section, 'read_more')}';

                                    final span =
                                        TextSpan(text: text, style: textStyle);
                                    final tp = TextPainter(
                                      text: span,
                                      maxLines: 1,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: constraints.maxWidth);

                                    if (!tp.didExceedMaxLines) {
                                      return Text(text, style: textStyle);
                                    }

                                    final truncatedText = _truncateTextToFit(
                                        text,
                                        textStyle,
                                        readMoreText,
                                        constraints.maxWidth,
                                        2);

                                    return RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                              text: truncatedText,
                                              style: textStyle),
                                          TextSpan(
                                            text: readMoreText,
                                            style: textStyle.copyWith(
                                                color: Colors.blue),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                showGeneralDialog(
                                                  context: context,
                                                  barrierDismissible: true,
                                                  barrierLabel: locale.translate(
                                                      section,
                                                      'location_dialog.title'),
                                                  pageBuilder: (c, a1, a2) =>
                                                      Stack(
                                                    children: [
                                                      BackdropFilter(
                                                        filter:
                                                            ImageFilter.blur(
                                                                sigmaX: 5,
                                                                sigmaY: 5),
                                                        child: Container(
                                                            color: const Color(
                                                                    0x80000000)
                                                                .withOpacity(
                                                                    0)),
                                                      ),
                                                      Center(
                                                        child: Dialog(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          16)),
                                                          child: SizedBox(
                                                            width: 400,
                                                            height: 300,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(20),
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .stretch,
                                                                children: [
                                                                  Expanded(
                                                                      child: SingleChildScrollView(
                                                                          child: Text(
                                                                              ev.location,
                                                                              style: textStyle))),
                                                                  const SizedBox(
                                                                      height:
                                                                          16),
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerRight,
                                                                    child:
                                                                        TextButton(
                                                                      onPressed:
                                                                          () =>
                                                                              Navigator.of(context).pop(),
                                                                      child: Text(
                                                                          locale.translate(
                                                                              section,
                                                                              'location_dialog.close'),
                                                                          style:
                                                                              const TextStyle(fontSize: 16)),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Text(locale.translate(section, 'description'),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final text = ev.description;
                              const textStyle = TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4);
                              final readMoreText =
                                  ' ${locale.translate(section, 'read_more')}';

                              final span =
                                  TextSpan(text: text, style: textStyle);
                              final tp = TextPainter(
                                text: span,
                                maxLines: 3,
                                textDirection: TextDirection.ltr,
                              )..layout(maxWidth: constraints.maxWidth);

                              if (!tp.didExceedMaxLines) {
                                return Text(text, style: textStyle);
                              }

                              final truncatedText = _truncateTextToFit(
                                  text,
                                  textStyle,
                                  readMoreText,
                                  constraints.maxWidth,
                                  3);

                              return RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                        text: truncatedText, style: textStyle),
                                    TextSpan(
                                      text: readMoreText,
                                      style: textStyle.copyWith(
                                          color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          showGeneralDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            barrierLabel: locale.translate(
                                                section,
                                                'description_dialog.title'),
                                            pageBuilder: (c, a1, a2) => Stack(
                                              children: [
                                                BackdropFilter(
                                                  filter: ImageFilter.blur(
                                                      sigmaX: 5, sigmaY: 5),
                                                  child: Container(
                                                      color: const Color(
                                                              0x80000000)
                                                          .withOpacity(0)),
                                                ),
                                                Center(
                                                  child: Dialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16)),
                                                    child: SizedBox(
                                                      width: 400,
                                                      height: 500,
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(20),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Expanded(
                                                              child:
                                                                  SingleChildScrollView(
                                                                child: Text(
                                                                    ev
                                                                        .description,
                                                                    style:
                                                                        textStyle),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 16),
                                                            Align(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              child: TextButton(
                                                                onPressed: () =>
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop(),
                                                                child: Text(
                                                                    locale.translate(
                                                                        section,
                                                                        'description_dialog.close'),
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            16)),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.group, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      participantLimit != null
                                          ? '$currentCount / $participantLimit'
                                          : '$currentCount',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: waitlistEnabled
                                    ? Row(
                                        children: [
                                          const Icon(Icons.hourglass_bottom,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            waitlistLimit != null
                                                ? '$currentWaitlistCount / $waitlistLimit'
                                                : '$currentWaitlistCount',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      )
                                    : Container(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

                        final buttons = <Widget>[];

                        buttons.add(ElevatedButton.icon(
                          onPressed: () {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: true,
                              barrierLabel:
                                  locale.translate(section, 'participant_list'),
                              pageBuilder: (c, a1, a2) => Stack(
                                children: [
                                  BackdropFilter(
                                    filter:
                                        ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                        color: const Color(0x80000000)
                                            .withOpacity(0)),
                                  ),
                                  Center(
                                    child: ParticipantListDialog(
                                      eventId: ev.id,
                                      hostId: hostId,
                                      initialParticipants: ev.participants,
                                      coHosts: ev.coHosts,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.people_outline),
                          label: Text(
                              locale.translate(section, 'participant_list')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ));
                        buttons.add(const SizedBox(height: 12));

                        if (waitlistEnabled && isHost) {
                          buttons.add(ElevatedButton.icon(
                            onPressed: () async {
                              final currentParticipants =
                                  ev.participants.length;
                              final entries = ev.waitlist;
                              final result = await showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (_) {
                                  return Stack(
                                    children: [
                                      BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 5, sigmaY: 5),
                                        child: Container(
                                            color: const Color(0x80000000)
                                                .withOpacity(0)),
                                      ),
                                      WaitlistDialog(
                                        eventId: ev.id,
                                        eventTitle: ev.title,
                                        waitlistEntries: entries,
                                        participantLimit: ev.participantLimit,
                                        currentParticipants:
                                            currentParticipants,
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result == true) {
                                await _updateWaitlistForEvent(ev.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(locale.translate(
                                        section, 'waitlist_updated')),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.hourglass_bottom),
                            label: Text(locale.translate(section, 'waitlist')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.orangeAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ));
                          buttons.add(const SizedBox(height: 12));
                        }

                        if (showInvite) {
                          buttons.add(ElevatedButton.icon(
                            onPressed: () async {
                              final cp = [...ev.participants];
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel:
                                    locale.translate(section, 'invite_users'),
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
                            label:
                                Text(locale.translate(section, 'invite_users')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ));
                          buttons.add(const SizedBox(height: 12));
                        }
                        if (showEdit) {
                          buttons.add(ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/editEvent',
                                  arguments: ev.id);
                            },
                            icon: const Icon(Icons.edit),
                            label:
                                Text(locale.translate(section, 'edit_event')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ));
                          buttons.add(const SizedBox(height: 12));
                        }
                        if (isHost) {
                          buttons.add(ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showGeneralDialog<bool>(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: locale.translate(section,
                                    'cancel_confirmation_dialog.title'),
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
                                      child: AlertDialog(
                                        title: Text(locale.translate(section,
                                            'cancel_confirmation_dialog.title')),
                                        content: Text(locale.translate(section,
                                            'cancel_confirmation_dialog.content')),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, false),
                                              child: Text(locale.translate(
                                                  section,
                                                  'cancel_confirmation_dialog.no'))),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(c, true),
                                              child: Text(locale.translate(
                                                  section,
                                                  'cancel_confirmation_dialog.yes'))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _eventService.cancelEvent(widget.eventId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(locale.translate(
                                            section, 'event_canceled'))));
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.cancel),
                            label:
                                Text(locale.translate(section, 'cancel_event')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ));
                          buttons.add(const SizedBox(height: 12));
                        }
                        if (!isJoined) {
                          if (accessEnum == AccessType.public &&
                              (participantLimit == null ||
                                  currentCount < participantLimit)) {
                            buttons.add(ElevatedButton.icon(
                              onPressed: () async {
                                await _eventService.registerForEvent(
                                    ev.id, currentUser!.uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(locale.translate(
                                            section, 'registered'))));
                              },
                              icon: const Icon(Icons.event_available),
                              label: Text(locale.translate(section, 'join')),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ));
                            buttons.add(const SizedBox(height: 12));
                          } else if (participantLimit != null &&
                              currentCount >= participantLimit &&
                              waitlistEnabled) {
                            if (waitlistLimit != null &&
                                currentWaitlistCount >= waitlistLimit) {
                              buttons.add(Text(
                                locale.translate(section, 'waitlist_full'),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ));
                              buttons.add(const SizedBox(height: 12));
                            } else if (isOnWaitlist) {
                              buttons.add(ElevatedButton(
                                onPressed: () async {
                                  final entry = {
                                    'uid': currentUser.uid,
                                    'name': currentUser.displayName ?? 'Unknown'
                                  };
                                  await _eventService.leaveWaitlist(
                                      ev.id, entry);
                                  await _updateWaitlistForEvent(ev.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(locale.translate(
                                              section, 'leave_waitlist'))));
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(locale.translate(
                                    section, 'leave_waitlist')),
                              ));
                              buttons.add(const SizedBox(height: 12));
                            } else {
                              buttons.add(ElevatedButton(
                                onPressed: () async {
                                  final entry = {
                                    'uid': currentUser!.uid,
                                    'name': currentUser.displayName ?? 'Unknown'
                                  };
                                  await _eventService.joinWaitlist(
                                      ev.id, entry);
                                  await _updateWaitlistForEvent(ev.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(locale.translate(
                                              section,
                                              'waitlist_registered'))));
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                    locale.translate(section, 'join_waitlist')),
                              ));
                              buttons.add(const SizedBox(height: 12));
                            }
                          }
                        }
                        if (!isJoined &&
                            participantLimit != null &&
                            currentCount >= participantLimit &&
                            !waitlistEnabled) {
                          buttons.add(Text(
                            locale.translate(section, 'event_full'),
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red),
                          ));
                        }

                        if (isJoined && !isHost) {
                          buttons.add(ElevatedButton.icon(
                            onPressed: () async {
                              await _eventService.leaveEvent(
                                  ev.id, currentUser!.uid);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        locale.translate(section, 'leave'))),
                              );
                            },
                            icon: const Icon(Icons.exit_to_app),
                            label: Text(locale.translate(section, 'leave')),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ));
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: buttons,
                          ),
                        );
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
