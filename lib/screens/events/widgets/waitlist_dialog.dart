import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/services/event_service.dart';

class WaitlistDialog extends StatefulWidget {
  final String eventId;
  final String section = "waitlist_dialog";
  final List<Map<String, dynamic>> waitlistEntries;
  final int? participantLimit;
  final int currentParticipants;

  const WaitlistDialog({
    super.key,
    required this.eventId,
    required this.waitlistEntries,
    required this.currentParticipants,
    this.participantLimit,
  });

  @override
  _WaitlistDialogState createState() => _WaitlistDialogState();
}

class _WaitlistDialogState extends State<WaitlistDialog> {
  late List<Map<String, dynamic>> _entries;
  late int _currentParticipants;
  bool _hasChanged = false;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _entries = List<Map<String, dynamic>>.from(widget.waitlistEntries);
    _currentParticipants = widget.currentParticipants;
    _hasChanged = false;
  }

  Future<void> _acceptEntry(Map<String, dynamic> entry) async {
    if (widget.participantLimit != null &&
        _currentParticipants >= widget.participantLimit!) {
      return;
    }
    await _eventService.registerForEvent(widget.eventId, entry['uid']);
    await _eventService.leaveWaitlist(widget.eventId, entry);
    setState(() {
      _entries.removeWhere((e) => e['uid'] == entry['uid']);
      _currentParticipants++;
      _hasChanged = true;
    });
    if (_entries.isEmpty) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _declineEntry(Map<String, dynamic> entry) async {
    await _eventService.leaveWaitlist(widget.eventId, entry);
    setState(() {
      _entries.removeWhere((e) => e['uid'] == entry['uid']);
      _hasChanged = true;
    });
    if (_entries.isEmpty) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    bool isLimitReached = widget.participantLimit != null &&
        _currentParticipants >= widget.participantLimit!;
    return AlertDialog(
      title: Text(localeProvider.translate(widget.section, "title")),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLimitReached)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    localeProvider.translate(
                        widget.section, "limit_reached_message"),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return ListTile(
                    title: Text(entry['name'] ?? 'Unknown'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed:
                              isLimitReached ? null : () => _acceptEntry(entry),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _declineEntry(entry),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text(localeProvider.translate(widget.section, "close")),
          onPressed: () {
            Navigator.of(context).pop(_hasChanged);
          },
        ),
      ],
    );
  }
}
