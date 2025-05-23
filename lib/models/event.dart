import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/event_price.dart';
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
  final bool waitlistEnabled;
  final int? participantLimit;
  final int? waitlistLimit;
  final List<String> coHosts;
  final List<Map<String, dynamic>> waitlist;
  final bool isMonetized;
  final EventPrice? price;

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
    required this.waitlistEnabled,
    this.participantLimit,
    this.waitlistLimit,
    required this.coHosts,
    required this.waitlist,
    required this.isMonetized,
    this.price,
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
      waitlistEnabled: data['waitlistEnabled'] ?? false,
      participantLimit: data['participantLimit'] is int
          ? data['participantLimit'] as int
          : null,
      waitlistLimit:
          data['waitlistLimit'] is int ? data['waitlistLimit'] as int : null,
      coHosts: List<String>.from(data['coHosts'] ?? <String>[]),
      waitlist: List<Map<String, dynamic>>.from(data['waitlist'] ?? <Map>[]),
      isMonetized: data['isMonetized'] ?? false,
      price: data['price'] != null ? EventPrice.fromMap(data['price']) : null,
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
      'waitlistEnabled': waitlistEnabled,
      'participantLimit': participantLimit,
      'waitlistLimit': waitlistLimit,
      'coHosts': coHosts,
      'waitlist': waitlist,
      'isMonetized': isMonetized,
      'price': isMonetized ? price?.toMap() : null,
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
    bool? waitlistEnabled,
    Object? participantLimit = const Object(),
    Object? waitlistLimit = const Object(),
    List<String>? coHosts,
    List<Map<String, dynamic>>? waitlist,
    bool? isMonetized,
    EventPrice? price,
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
      waitlistEnabled: waitlistEnabled ?? this.waitlistEnabled,
      participantLimit: participantLimit == const Object()
          ? this.participantLimit
          : participantLimit as int?,
      waitlistLimit: waitlistLimit == const Object()
          ? this.waitlistLimit
          : waitlistLimit as int?,
      coHosts: coHosts ?? this.coHosts,
      waitlist: waitlist ?? this.waitlist,
      isMonetized: isMonetized ?? this.isMonetized,
      price: price ?? this.price,
    );
  }
}
