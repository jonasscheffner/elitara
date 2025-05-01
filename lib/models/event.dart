import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String host;
  final List<String> participants;
  final String status;
  final String accessType;
  final String visibility;
  final bool canInvite;
  final bool waitlistEnabled;
  final int? participantLimit;
  final int? waitlistLimit;
  final List<String> coHosts;
  final List<Map<String, dynamic>> waitlist;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.host,
    required this.participants,
    required this.status,
    required this.accessType,
    required this.visibility,
    required this.canInvite,
    required this.waitlistEnabled,
    this.participantLimit,
    this.waitlistLimit,
    required this.coHosts,
    required this.waitlist,
  });

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      host: data['host'] ?? '',
      participants: List<String>.from(data['participants'] ?? <String>[]),
      status: data['status'] ?? 'active',
      accessType: data['accessType'] ?? 'public',
      visibility: data['visibility'] ?? 'everyone',
      canInvite: data['canInvite'] ?? false,
      waitlistEnabled: data['waitlistEnabled'] ?? false,
      participantLimit: data['participantLimit'],
      waitlistLimit: data['waitlistLimit'],
      coHosts: List<String>.from(data['coHosts'] ?? <String>[]),
      waitlist: List<Map<String, dynamic>>.from(data['waitlist'] ?? <Map>[]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'location': location,
      'host': host,
      'participants': participants,
      'status': status,
      'accessType': accessType,
      'visibility': visibility,
      'canInvite': canInvite,
      'waitlistEnabled': waitlistEnabled,
      'participantLimit': participantLimit,
      'waitlistLimit': waitlistLimit,
      'coHosts': coHosts,
      'waitlist': waitlist,
    };
  }
}
