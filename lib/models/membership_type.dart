enum MembershipType {
  guest,
  gold,
  platinum,
}

extension MembershipTypeExtension on MembershipType {
  String get name {
    switch (this) {
      case MembershipType.guest:
        return "guest";
      case MembershipType.gold:
        return "gold";
      case MembershipType.platinum:
        return "platinum";
    }
  }

  static MembershipType fromString(String value) {
    switch (value) {
      case "guest":
        return MembershipType.guest;
      case "gold":
        return MembershipType.gold;
      case "platinum":
        return MembershipType.platinum;
      default:
        throw ArgumentError("Invalid membership type: $value");
    }
  }
}
