import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class MembershipScreen extends StatelessWidget {
  const MembershipScreen({super.key});
  final String section = 'settings.membership_screen';

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMembershipCard(
              context,
              title: localeProvider.translate(section, 'guest_title'),
              features: [
                localeProvider.translate(section, 'guest_feature_1'),
                localeProvider.translate(section, 'guest_feature_2'),
              ],
              color: Colors.blueGrey.shade600,
              icon: Icons.event,
            ),
            const SizedBox(height: 16),
            _buildMembershipCard(
              context,
              title: localeProvider.translate(section, 'gold_title'),
              features: [
                localeProvider.translate(section, 'gold_feature_1'),
                localeProvider.translate(section, 'gold_feature_2'),
                localeProvider.translate(section, 'gold_feature_3'),
              ],
              color: Colors.amber.shade300,
              icon: Icons.star,
            ),
            const SizedBox(height: 16),
            _buildMembershipCard(
              context,
              title: localeProvider.translate(section, 'platinum_title'),
              features: [
                localeProvider.translate(section, 'platinum_feature_1'),
                localeProvider.translate(section, 'platinum_feature_2'),
                localeProvider.translate(section, 'platinum_feature_3'),
              ],
              color: Colors.grey.shade600,
              gradient: LinearGradient(
                colors: [Colors.grey.shade500, Colors.grey.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.diamond,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCard(BuildContext context,
      {required String title,
      required List<String> features,
      required Color color,
      Gradient? gradient,
      required IconData icon}) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: gradient == null ? color.withOpacity(0.2) : null,
          gradient: gradient,
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
