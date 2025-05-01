import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/event_status.dart';
import 'package:elitara/models/visibility_option.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String host;
  final List<String> participants;
  final EventStatus status;
  final AccessType accessType;
  final VisibilityOption visibility;
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
      status: data['status'] is String
          ? EventStatusExtension.fromString(data['status'] as String)
          : EventStatus.active,
      accessType: data['accessType'] is String
          ? AccessTypeExtension.fromString(data['accessType'] as String)
          : AccessType.public,
      visibility: data['visibility'] is String
          ? VisibilityOptionExtension.fromString(data['visibility'] as String)
          : VisibilityOption.everyone,
      canInvite: data['canInvite'] ?? false,
      waitlistEnabled: data['waitlistEnabled'] ?? false,
      participantLimit: data['participantLimit'] is int
          ? data['participantLimit'] as int
          : null,
      waitlistLimit:
          data['waitlistLimit'] is int ? data['waitlistLimit'] as int : null,
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
      'status': status.value,
      'accessType': accessType.value,
      'visibility': visibility.value,
      'canInvite': canInvite,
      'waitlistEnabled': waitlistEnabled,
      if (participantLimit != null) 'participantLimit': participantLimit,
      if (waitlistLimit != null) 'waitlistLimit': waitlistLimit,
      'coHosts': coHosts,
      'waitlist': waitlist,
    };
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? host,
    List<String>? participants,
    EventStatus? status,
    AccessType? accessType,
    VisibilityOption? visibility,
    bool? canInvite,
    bool? waitlistEnabled,
    int? participantLimit,
    int? waitlistLimit,
    List<String>? coHosts,
    List<Map<String, dynamic>>? waitlist,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      host: host ?? this.host,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      accessType: accessType ?? this.accessType,
      visibility: visibility ?? this.visibility,
      canInvite: canInvite ?? this.canInvite,
      waitlistEnabled: waitlistEnabled ?? this.waitlistEnabled,
      participantLimit: participantLimit ?? this.participantLimit,
      waitlistLimit: waitlistLimit ?? this.waitlistLimit,
      coHosts: coHosts ?? this.coHosts,
      waitlist: waitlist ?? this.waitlist,
    );
  }
}
