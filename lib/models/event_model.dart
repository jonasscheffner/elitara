class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;

  Event(
      {required this.id,
      required this.title,
      required this.description,
      required this.date,
      required this.location});

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    return Event(
      id: id,
      title: data['title'],
      description: data['description'],
      date: data['date'].toDate(),
      location: data['location'],
    );
  }
}
