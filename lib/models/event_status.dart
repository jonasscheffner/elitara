enum EventStatus {
  active,
  canceled,
}

extension EventStatusExtension on EventStatus {
  String get value {
    switch (this) {
      case EventStatus.canceled:
        return "canceled";
      case EventStatus.active:
        return "active";
    }
  }

  static EventStatus fromString(String value) {
    switch (value) {
      case "canceled":
        return EventStatus.canceled;
      case "active":
      default:
        return EventStatus.active;
    }
  }
}
