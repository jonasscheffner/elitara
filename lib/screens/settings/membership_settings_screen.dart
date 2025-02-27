import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/services/membership_service.dart';

class MembershipSettingsScreen extends StatefulWidget {
  const MembershipSettingsScreen({super.key});
  final String section = 'settings.membership_screen';

  @override
  _MembershipSettingsScreenState createState() =>
      _MembershipSettingsScreenState();
}

class _MembershipSettingsScreenState extends State<MembershipSettingsScreen> {
  String? _currentMembership;
  final MembershipService _membershipService = MembershipService();

  @override
  void initState() {
    super.initState();
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    String membership = await _membershipService.getCurrentMembership();
    setState(() {
      _currentMembership = membership.isNotEmpty ? membership : null;
    });
  }

  Future<void> _changeMembership(String newMembership) async {
    if (_currentMembership == newMembership) return;

    await _membershipService.updateMembership(newMembership);
    setState(() {
      _currentMembership = newMembership;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.of<LocaleProvider>(context, LocaleProvider)!
              .translate(widget.section, 'membership_updated'),
        ),
      ),
    );
  }

  Future<void> _cancelMembership() async {
    bool confirm = await _showConfirmationDialog();
    if (!confirm) return;

    await _membershipService.cancelMembership();
    setState(() {
      _currentMembership = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.of<LocaleProvider>(context, LocaleProvider)!
              .translate(widget.section, 'membership_canceled'),
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
                Localizations.of<LocaleProvider>(context, LocaleProvider)!
                    .translate(widget.section, 'cancel_title')),
            content: Text(
                Localizations.of<LocaleProvider>(context, LocaleProvider)!
                    .translate(widget.section, 'cancel_confirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                    Localizations.of<LocaleProvider>(context, LocaleProvider)!
                        .translate(widget.section, 'cancel_no')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                    Localizations.of<LocaleProvider>(context, LocaleProvider)!
                        .translate(widget.section, 'cancel_yes')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(widget.section, 'title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMembershipCard(
              context,
              title: localeProvider.translate(widget.section, 'guest_title'),
              features: [
                localeProvider.translate(widget.section, 'guest_feature_1'),
                localeProvider.translate(widget.section, 'guest_feature_2'),
              ],
              color: Colors.blueGrey.shade600,
              icon: Icons.event,
              textColor: Colors.white,
              isCurrent: _currentMembership == "guest",
              onSelect: () => _changeMembership("guest"),
            ),
            const SizedBox(height: 16),
            _buildMembershipCard(
              context,
              title: localeProvider.translate(widget.section, 'gold_title'),
              features: [
                localeProvider.translate(widget.section, 'gold_feature_1'),
                localeProvider.translate(widget.section, 'gold_feature_2'),
                localeProvider.translate(widget.section, 'gold_feature_3'),
              ],
              color: Colors.amber.shade300,
              icon: Icons.star,
              textColor: Colors.white,
              isCurrent: _currentMembership == "gold",
              onSelect: () => _changeMembership("gold"),
            ),
            const SizedBox(height: 16),
            _buildMembershipCard(
              context,
              title: localeProvider.translate(widget.section, 'platinum_title'),
              features: [
                localeProvider.translate(widget.section, 'platinum_feature_1'),
                localeProvider.translate(widget.section, 'platinum_feature_2'),
                localeProvider.translate(widget.section, 'platinum_feature_3'),
              ],
              color: Colors.grey.shade500,
              gradient: LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.diamond,
              textColor: Colors.black87,
              isCurrent: _currentMembership == "platinum",
              onSelect: () => _changeMembership("platinum"),
            ),
            const SizedBox(height: 20),
            if (_currentMembership != null)
              ElevatedButton(
                onPressed: _cancelMembership,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: Text(
                    localeProvider.translate(widget.section, 'cancel_button')),
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
      required IconData icon,
      required Color textColor,
      required bool isCurrent,
      required VoidCallback onSelect}) {
    return GestureDetector(
      onTap: onSelect,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              isCurrent ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
        elevation: isCurrent ? 6 : 4,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 18, color: Colors.green),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(feature,
                                style: TextStyle(color: textColor))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
