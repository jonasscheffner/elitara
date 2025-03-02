enum AccessType {
  public,
  inviteOnly,
}

extension AccessTypeExtension on AccessType {
  String get value {
    switch (this) {
      case AccessType.inviteOnly:
        return "invite_only";
      case AccessType.public:
      default:
        return "public";
    }
  }

  static AccessType fromString(String str) {
    switch (str) {
      case "invite_only":
        return AccessType.inviteOnly;
      case "public":
      default:
        return AccessType.public;
    }
  }
}
