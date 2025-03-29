enum VisibilityOption {
  everyone,
  participantsOnly,
}

extension VisibilityOptionExtension on VisibilityOption {
  String get value {
    switch (this) {
      case VisibilityOption.everyone:
        return "everyone";
      case VisibilityOption.participantsOnly:
        return "participants_only";
    }
  }

  static VisibilityOption fromString(String value) {
    switch (value) {
      case "participants_only":
        return VisibilityOption.participantsOnly;
      case "everyone":
      default:
        return VisibilityOption.everyone;
    }
  }
}
