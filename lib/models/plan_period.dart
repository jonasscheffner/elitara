enum PlanPeriod {
  monthly,
  yearly,
}

extension PlanPeriodExtension on PlanPeriod {
  String get localizationKey {
    switch (this) {
      case PlanPeriod.monthly:
        return "monthly";
      case PlanPeriod.yearly:
        return "yearly";
    }
  }
}
