import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/screens/events/widgets/event_form.dart';
import 'package:elitara/services/event_service.dart';
import 'package:flutter/material.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _participantLimitController =
      TextEditingController();
  final TextEditingController _waitlistLimitController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = true;
  bool _hasChanged = false;
  Map<String, dynamic>? eventData;
  String section = 'edit_event_screen';
  late String _initialTitle;
  late String _initialDescription;
  late String _initialLocation;
  int? _initialParticipantLimit;
  int? _initialWaitlistLimit;
  late DateTime _initialDate;
  late TimeOfDay _initialTime;
  AccessType _accessType = AccessType.public;
  bool _waitlistEnabled = false;

  String? _participantLimitError;
  String? _waitlistLimitError;
  int _existingParticipantCount = 0;
  int _existingWaitlistCount = 0;

  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    DocumentSnapshot doc = await _eventService.getEvent(widget.eventId);
    eventData = doc.data() as Map<String, dynamic>?;
    if (eventData != null) {
      _titleController.text = eventData!['title'] ?? '';
      _descriptionController.text = eventData!['description'] ?? '';
      _locationController.text = eventData!['location'] ?? '';
      _initialParticipantLimit = eventData!['participantLimit'] is int
          ? eventData!['participantLimit'] as int
          : null;
      _participantLimitController.text =
          _initialParticipantLimit?.toString() ?? '';
      _initialWaitlistLimit = eventData!['waitlistLimit'] is int
          ? eventData!['waitlistLimit'] as int
          : null;
      _waitlistLimitController.text = _initialWaitlistLimit?.toString() ?? '';
      String accessTypeStr = eventData!['accessType'] is String
          ? eventData!['accessType'] as String
          : "public";
      _accessType = AccessTypeExtension.fromString(accessTypeStr);
      _waitlistEnabled = eventData!['waitlistEnabled'] is bool
          ? eventData!['waitlistEnabled'] as bool
          : false;
      _existingParticipantCount = (eventData!['participants'] is List)
          ? (eventData!['participants'] as List).length
          : 0;
      _existingWaitlistCount = (eventData!['waitlist'] is List)
          ? (eventData!['waitlist'] as List).length
          : 0;
      Timestamp ts = eventData!['date'];
      DateTime dt = ts.toDate();
      _selectedDate = dt;
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _initialTitle = _titleController.text;
      _initialDescription = _descriptionController.text;
      _initialLocation = _locationController.text;
      _initialDate = _selectedDate;
      _initialTime = _selectedTime;
      _titleController.addListener(_checkForChanges);
      _descriptionController.addListener(_checkForChanges);
      _locationController.addListener(_checkForChanges);
      _participantLimitController.addListener(_checkForChanges);
      _waitlistLimitController.addListener(_checkForChanges);
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _validateLimits() {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    if (_participantLimitController.text.isNotEmpty) {
      int? newLimit = int.tryParse(_participantLimitController.text);
      if (newLimit != null && newLimit < _existingParticipantCount) {
        _participantLimitError = localeProvider.translate(
          section,
          'messages.participant_limit_error',
          params: {'count': '$_existingParticipantCount'},
        );
      } else {
        _participantLimitError = null;
      }
    } else {
      _participantLimitError = null;
    }
    if (_waitlistEnabled && _waitlistLimitController.text.isNotEmpty) {
      int? newWaitlistLimit = int.tryParse(_waitlistLimitController.text);
      if (newWaitlistLimit != null &&
          newWaitlistLimit < _existingWaitlistCount) {
        _waitlistLimitError = localeProvider.translate(
          section,
          'messages.waitlist_limit_error',
          params: {'count': '$_existingWaitlistCount'},
        );
      } else {
        _waitlistLimitError = null;
      }
    } else {
      _waitlistLimitError = null;
    }
  }

  void _checkForChanges() {
    _validateLimits();
    bool participantLimitChanged = _participantLimitController.text.isNotEmpty
        ? int.tryParse(_participantLimitController.text) !=
            _initialParticipantLimit
        : _initialParticipantLimit != null;
    bool changed = _titleController.text != _initialTitle ||
        _descriptionController.text != _initialDescription ||
        _locationController.text != _initialLocation ||
        participantLimitChanged ||
        _waitlistLimitController.text !=
            (_initialWaitlistLimit?.toString() ?? '') ||
        !_selectedDate.isAtSameMomentAs(_initialDate) ||
        (_selectedTime.hour != _initialTime.hour ||
            _selectedTime.minute != _initialTime.minute) ||
        (_accessType.value !=
            (eventData?['accessType'] as String? ?? "public")) ||
        (_waitlistEnabled != (eventData?['waitlistEnabled'] as bool? ?? false));
    setState(() {
      _hasChanged = changed;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _checkForChanges();
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!);
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      _checkForChanges();
    }
  }

  Future<void> _updateEvent() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'messages.fill_all_fields')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    int? participantLimit;
    if (_participantLimitController.text.isNotEmpty) {
      try {
        participantLimit = int.parse(_participantLimitController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(Localizations.of<LocaleProvider>(
                      context, LocaleProvider)!
                  .translate(section, 'messages.invalid_participant_limit'))),
        );
        return;
      }
    }
    int? waitlistLimit;
    if (_waitlistEnabled && _waitlistLimitController.text.isNotEmpty) {
      try {
        waitlistLimit = int.parse(_waitlistLimitController.text);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  Localizations.of<LocaleProvider>(context, LocaleProvider)!
                      .translate(section, 'messages.invalid_waitlist_limit'))),
        );
        return;
      }
    }
    final Map<String, dynamic> updatedData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'date': Timestamp.fromDate(DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute)),
      'accessType': _accessType.value,
      'waitlistEnabled':
          _accessType == AccessType.inviteOnly ? _waitlistEnabled : false,
    };
    if (_participantLimitController.text.isNotEmpty) {
      updatedData['participantLimit'] = participantLimit;
    } else {
      updatedData['participantLimit'] = FieldValue.delete();
    }
    if (_waitlistEnabled && _waitlistLimitController.text.isNotEmpty) {
      updatedData['waitlistLimit'] = waitlistLimit;
    } else {
      updatedData['waitlistLimit'] = FieldValue.delete();
    }
    await _eventService.updateEvent(widget.eventId, updatedData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'messages.event_updated'))),
    );
    Navigator.pop(context);
  }

  Future<void> _cancelEvent() async {
    await _eventService.cancelEvent(widget.eventId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'messages.event_canceled'))),
    );
    Navigator.pop(context);
  }

  Future<void> _confirmCancelEvent() async {
    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
                Localizations.of<LocaleProvider>(context, LocaleProvider)!
                    .translate(section, 'confirmation_dialog.title')),
            content: Text(
                Localizations.of<LocaleProvider>(context, LocaleProvider)!
                    .translate(section, 'confirmation_dialog.content')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                    Localizations.of<LocaleProvider>(context, LocaleProvider)!
                        .translate(section, 'confirmation_dialog.no')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                    Localizations.of<LocaleProvider>(context, LocaleProvider)!
                        .translate(section, 'confirmation_dialog.yes')),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      _cancelEvent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
          title: Text(localeProvider.translate(section, 'edit_event_title'))),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EventForm(
                titleController: _titleController,
                descriptionController: _descriptionController,
                locationController: _locationController,
                participantLimitController: _participantLimitController,
                waitlistLimitController: _waitlistLimitController,
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                onSelectDate: () => _selectDate(context),
                onSelectTime: () => _selectTime(context),
                accessType: _accessType,
                onAccessTypeChanged: (value) {
                  setState(() {
                    _accessType = value ?? AccessType.public;
                    _checkForChanges();
                  });
                },
                waitlistEnabled: _waitlistEnabled,
                onWaitlistChanged: (value) {
                  setState(() {
                    _waitlistEnabled = value;
                    _checkForChanges();
                  });
                },
                participantLimitError: _participantLimitError,
                waitlistLimitError: _waitlistLimitError,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (!_hasChanged ||
                        _participantLimitError != null ||
                        _waitlistLimitError != null ||
                        _isLoading)
                    ? null
                    : _updateEvent,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
                child: Text(localeProvider.translate(section, 'update_event'),
                    style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _confirmCancelEvent,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                  shape: WidgetStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                ),
                child: Text(localeProvider.translate(section, 'cancel_event'),
                    style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
