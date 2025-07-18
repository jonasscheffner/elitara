import 'package:elitara/models/event_price.dart';
import 'package:elitara/utils/app_snack_bar.dart';
import 'package:flutter/material.dart';

import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/visibility_option.dart';
import 'package:elitara/models/membership_type.dart';
import 'package:elitara/services/event_service.dart';
import 'package:elitara/services/membership_service.dart';
import 'package:elitara/utils/event_validator.dart';
import 'package:elitara/screens/events/widgets/event_form.dart';

class EditEventScreen extends StatefulWidget {
  final String eventId;
  const EditEventScreen({super.key, required this.eventId});

  @override
  _EditEventScreenState createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final String section = 'edit_event_screen';

  final EventService _eventService = EventService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _participantLimitController = TextEditingController();
  final _waitlistLimitController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  AccessType _accessType = AccessType.public;
  bool _waitlistEnabled = false;
  VisibilityOption _visibility = VisibilityOption.everyone;

  bool _isLoading = true;
  bool _hasChanged = false;
  MembershipType? _membershipType;
  bool _isMonetized = false;
  EventPrice? _price;

  Event? _originalEvent;
  String? _titleError;
  String? _descriptionError;
  String? _participantLimitError;
  String? _waitlistLimitError;

  @override
  void initState() {
    super.initState();
    _loadEvent();
    _loadMembership();
    _titleController.addListener(_validateTitle);
    _descriptionController.addListener(_validateDescription);
    _participantLimitController.addListener(_validateParticipantLimit);
    _waitlistLimitController.addListener(_validateWaitlistLimit);
  }

  Future<void> _loadMembership() async {
    final service = MembershipService();
    final membership = await service.getCurrentMembership();
    setState(() => _membershipType = membership);
  }

  Future<void> _loadEvent() async {
    final doc = await _eventService.getEvent(widget.eventId);
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      Navigator.pop(context);
      return;
    }

    final ev = Event.fromMap(doc.id, data);
    _originalEvent = ev;

    _titleController.text = ev.title;
    _descriptionController.text = ev.description;
    _locationController.text = ev.location;
    _selectedDate = ev.date;
    _selectedTime = TimeOfDay(hour: ev.date.hour, minute: ev.date.minute);

    if (ev.participantLimit != null) {
      _participantLimitController.text = ev.participantLimit.toString();
    }
    if (ev.waitlistLimit != null) {
      _waitlistLimitController.text = ev.waitlistLimit.toString();
    }

    _accessType = ev.accessType;
    _waitlistEnabled = ev.waitlistEnabled;
    _visibility = ev.visibility;
    _isMonetized = ev.isMonetized;
    _price = ev.price;

    _titleController.addListener(_onChanged);
    _descriptionController.addListener(_onChanged);
    _locationController.addListener(_onChanged);
    _participantLimitController.addListener(_onChanged);
    _waitlistLimitController.addListener(_onChanged);

    _validateTitle();
    _validateDescription();
    _validateParticipantLimit();
    _validateWaitlistLimit();

    setState(() {
      _isLoading = false;
    });
  }

  void _onChanged() {
    if (_originalEvent == null) return;
    final ev = _originalEvent!;

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newParticipantLimit = _participantLimitController.text.isNotEmpty
        ? int.tryParse(_participantLimitController.text)
        : null;
    final newWaitlistLimit =
        _waitlistEnabled && _waitlistLimitController.text.isNotEmpty
            ? int.tryParse(_waitlistLimitController.text)
            : null;

    final changed = _titleController.text.trim() != ev.title.trim() ||
        _descriptionController.text.trim() != ev.description.trim() ||
        _locationController.text.trim() != ev.location.trim() ||
        !dt.isAtSameMomentAs(ev.date) ||
        _accessType != ev.accessType ||
        _waitlistEnabled != ev.waitlistEnabled ||
        _visibility != ev.visibility ||
        newParticipantLimit != ev.participantLimit ||
        newWaitlistLimit != ev.waitlistLimit ||
        _isMonetized != ev.isMonetized ||
        (_price?.amount != ev.price?.amount ||
            _price?.currency != ev.price?.currency);

    if (changed != _hasChanged) {
      setState(() {
        _hasChanged = changed;
      });
    }
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
      existingParticipantCount: _originalEvent?.participants.length ?? 0,
    );
    setState(() => _participantLimitError = error);
  }

  void _validateWaitlistLimit() {
    final error = EventValidator.validateWaitlistLimit(
      _waitlistLimitController.text,
      context,
      waitlistEnabled: _waitlistEnabled,
      existingWaitlistCount: _originalEvent?.waitlist.length ?? 0,
    );
    setState(() => _waitlistLimitError = error);
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

  Future<void> _selectDate(BuildContext ctx) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _onChanged();
    }
  }

  Future<void> _selectTime(BuildContext ctx) async {
    final picked = await showTimePicker(
      context: ctx,
      initialTime: _selectedTime,
      builder: (_, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _onChanged();
    }
  }

  Future<void> _updateEvent() async {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    final updatedEvent = _originalEvent!.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      location: _locationController.text.trim(),
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ),
      accessType: _accessType,
      waitlistEnabled: _waitlistEnabled,
      visibility: _visibility,
      participantLimit: _participantLimitController.text.isNotEmpty
          ? int.tryParse(_participantLimitController.text)
          : null,
      waitlistLimit:
          _waitlistEnabled && _waitlistLimitController.text.isNotEmpty
              ? int.tryParse(_waitlistLimitController.text)
              : null,
      isMonetized: _isMonetized,
      price: _price,
    );

    await _eventService.updateEvent(widget.eventId, updatedEvent.toMap());

    AppSnackBar.show(
      context,
      locale.translate(section, 'messages.event_updated'),
      type: SnackBarType.success,
    );

    Navigator.pop(context);
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

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate(section, 'edit_event_title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        EventForm(
                          titleController: _titleController,
                          descriptionController: _descriptionController,
                          locationController: _locationController,
                          participantLimitController:
                              _participantLimitController,
                          waitlistLimitController: _waitlistLimitController,
                          selectedDate: _selectedDate,
                          selectedTime: _selectedTime,
                          onSelectDate: () => _selectDate(context),
                          onSelectTime: () => _selectTime(context),
                          accessType: _accessType,
                          onAccessTypeChanged: (v) => setState(() {
                            _accessType = v ?? AccessType.public;
                            _onChanged();
                          }),
                          waitlistEnabled: _waitlistEnabled,
                          onWaitlistChanged: (v) => setState(() {
                            _waitlistEnabled = v;
                            _validateWaitlistLimit();
                            _onChanged();
                          }),
                          visibility: _visibility,
                          onVisibilityChanged: (v) => setState(() {
                            _visibility = v ?? VisibilityOption.everyone;
                            _onChanged();
                          }),
                          participantLimitError: _participantLimitError,
                          waitlistLimitError: _waitlistLimitError,
                          titleError: _titleError,
                          descriptionError: _descriptionError,
                          membershipType: _membershipType,
                          isMonetized: _isMonetized,
                          price: _price,
                          onIsMonetizedChanged: (val) => setState(() {
                            _isMonetized = val;
                            _onChanged();
                          }),
                          onPriceChanged: (val) => setState(() {
                            _price = val;
                            _onChanged();
                          }),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid && _hasChanged ? _updateEvent : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    locale.translate(section, 'update_event'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
