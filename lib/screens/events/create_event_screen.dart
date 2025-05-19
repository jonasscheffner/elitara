import 'package:elitara/models/event_status.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/visibility_option.dart';
import 'package:elitara/services/event_service.dart';
import 'package:elitara/utils/event_validator.dart';
import 'package:elitara/screens/events/widgets/event_form.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _participantLimitController =
      TextEditingController();
  final TextEditingController _waitlistLimitController =
      TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  AccessType _accessType = AccessType.public;
  bool _waitlistEnabled = false;
  VisibilityOption _visibility = VisibilityOption.everyone;
  bool _canInvite = false;

  final String section = 'create_event_screen';
  final EventService _eventService = EventService();

  String? _titleError;
  String? _descriptionError;
  String? _participantLimitError;
  String? _waitlistLimitError;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_validateTitle);
    _descriptionController.addListener(_validateDescription);
    _participantLimitController.addListener(_validateParticipantLimit);
    _waitlistLimitController.addListener(_validateWaitlistLimit);
  }

  void _validateTitle() {
    setState(() {
      _titleError =
          EventValidator.validateTitle(_titleController.text, context);
    });
  }

  void _validateDescription() {
    setState(() {
      _descriptionError = EventValidator.validateDescription(
          _descriptionController.text, context);
    });
  }

  void _validateParticipantLimit() {
    final error = EventValidator.validateParticipantLimit(
      _participantLimitController.text,
      context,
    );
    setState(() {
      _participantLimitError = error;
    });
  }

  void _validateWaitlistLimit() {
    final error = EventValidator.validateWaitlistLimit(
      _waitlistLimitController.text,
      context,
      waitlistEnabled: _waitlistEnabled,
    );
    setState(() {
      _waitlistLimitError = error;
    });
  }

  bool get _isFormValid {
    return _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _titleError == null &&
        _descriptionError == null &&
        _participantLimitError == null &&
        _waitlistLimitError == null;
  }

  Future<void> _createEvent() async {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    int? participantLimit;
    if (_participantLimitController.text.isNotEmpty) {
      participantLimit = int.tryParse(_participantLimitController.text);
    }
    int? waitlistLimit;
    if (_waitlistEnabled && _waitlistLimitController.text.isNotEmpty) {
      waitlistLimit = int.tryParse(_waitlistLimitController.text);
    }

    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newEvent = Event(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: eventDateTime,
      location: _locationController.text.trim(),
      host: currentUser.uid,
      participants: [currentUser.uid],
      status: EventStatus.active,
      accessType: _accessType,
      visibility: _visibility,
      canInvite: _canInvite,
      waitlistEnabled:
          _accessType == AccessType.inviteOnly ? _waitlistEnabled : false,
      participantLimit: participantLimit,
      waitlistLimit: waitlistLimit,
      coHosts: [],
      waitlist: [],
    );

    await _eventService.createEvent(newEvent.toMap());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(locale.translate(section, 'messages.event_created')),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantLimitController.dispose();
    _waitlistLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate(section, 'create_event_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
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
                  onAccessTypeChanged: (val) =>
                      setState(() => _accessType = val ?? AccessType.public),
                  waitlistEnabled: _waitlistEnabled,
                  onWaitlistChanged: (val) => setState(() {
                    _waitlistEnabled = val;
                    _validateWaitlistLimit();
                  }),
                  visibility: _visibility,
                  onVisibilityChanged: (val) => setState(
                      () => _visibility = val ?? VisibilityOption.everyone),
                  canInvite: _canInvite,
                  onCanInviteChanged: (val) => setState(() => _canInvite = val),
                  participantLimitError: _participantLimitError,
                  waitlistLimitError: _waitlistLimitError,
                  titleError: _titleError,
                  descriptionError: _descriptionError,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isFormValid ? _createEvent : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locale.translate(section, 'create_event'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
