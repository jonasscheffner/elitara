enum MessageType {
  text,
  eventInvitation;

  static MessageType fromString(String value) {
    switch (value) {
      case 'event_invitation':
        return MessageType.eventInvitation;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  String toShortString() {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.eventInvitation:
        return 'event_invitation';
    }
  }
}
