import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/screens/events/widgets/event_form.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/services/event_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String section = 'create_event_screen';
  final EventService _eventService = EventService();

  void _createEvent() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Localizations.of<LocaleProvider>(context, LocaleProvider)!
                .translate(section, 'messages.fill_all_fields'),
          ),
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
            content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'messages.invalid_participant_limit'),
            ),
          ),
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
                  .translate(section, 'messages.invalid_waitlist_limit'),
            ),
          ),
        );
        return;
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final DateTime eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final Map<String, dynamic> eventData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'date': Timestamp.fromDate(eventDateTime),
      'host': currentUser.uid,
      'participants': [currentUser.uid],
      'status': 'active',
      'accessType': _accessType.value,
      'waitlistEnabled':
          _accessType == AccessType.inviteOnly ? _waitlistEnabled : false,
    };
    if (participantLimit != null) {
      eventData['participantLimit'] = participantLimit;
    }
    if (_waitlistEnabled && waitlistLimit != null) {
      eventData['waitlistLimit'] = waitlistLimit;
    }

    await _eventService.createEvent(eventData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.of<LocaleProvider>(context, LocaleProvider)!
              .translate(section, 'messages.event_created'),
        ),
      ),
    );
    Navigator.pop(context);
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
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'create_event_title')),
      ),
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
                  });
                },
                waitlistEnabled: _waitlistEnabled,
                onWaitlistChanged: (value) {
                  setState(() {
                    _waitlistEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createEvent,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(
                  localeProvider.translate(section, 'create_event'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
