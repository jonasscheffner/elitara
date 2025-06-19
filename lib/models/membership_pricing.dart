import 'membership_type.dart';
import 'plan_period.dart';

extension MembershipPricing on MembershipType {
  double getPrice(PlanPeriod period) {
    switch (this) {
      case MembershipType.guest:
        return period == PlanPeriod.monthly ? 4.99 : 49.99;
      case MembershipType.gold:
        return period == PlanPeriod.monthly ? 14.99 : 149.99;
      case MembershipType.platinum:
        return period == PlanPeriod.monthly ? 49.99 : 499.99;
    }
  }
}
