import 'membership_type.dart';
import 'plan_period.dart';

extension MembershipPricing on MembershipType {
  double getPrice(PlanPeriod period) {
    switch (this) {
      case MembershipType.guest:
        return period == PlanPeriod.monthly ? 9.99 : 99.99;
      case MembershipType.gold:
        return period == PlanPeriod.monthly ? 29.99 : 299.99;
      case MembershipType.platinum:
        return period == PlanPeriod.monthly ? 99.99 : 999.99;
    }
  }
}
