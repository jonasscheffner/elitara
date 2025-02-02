import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:intl/intl.dart';

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
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = true;
  bool _hasChanged = false;
  Map<String, dynamic>? eventData;
  String section = 'edit_event_screen';
  late String _initialTitle;
  late String _initialDescription;
  late String _initialLocation;
  late DateTime _initialDate;
  late TimeOfDay _initialTime;

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  Future<void> _loadEventData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .get();
    eventData = doc.data() as Map<String, dynamic>?;
    if (eventData != null) {
      _titleController.text = eventData!['title'] ?? '';
      _descriptionController.text = eventData!['description'] ?? '';
      _locationController.text = eventData!['location'] ?? '';
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
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _checkForChanges() {
    bool changed = _titleController.text != _initialTitle ||
        _descriptionController.text != _initialDescription ||
        _locationController.text != _initialLocation ||
        !_selectedDate.isAtSameMomentAs(_initialDate) ||
        (_selectedTime.hour != _initialTime.hour ||
            _selectedTime.minute != _initialTime.minute);
    if (changed != _hasChanged) {
      setState(() {
        _hasChanged = changed;
      });
    }
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
          child: child!,
        );
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
        ),
      );
      return;
    }
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .update({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'date': Timestamp.fromDate(DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      )),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Localizations.of<LocaleProvider>(context, LocaleProvider)!
            .translate(section, 'messages.event_updated')),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _cancelEvent() async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .update({'status': 'canceled'});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(Localizations.of<LocaleProvider>(context, LocaleProvider)!
            .translate(section, 'messages.event_canceled')),
      ),
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'edit_event_title')),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'title'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'description'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'location'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: LocalizedDateTimeFormatter.getFormattedDate(
                          context, _selectedDate),
                    ),
                    decoration: InputDecoration(
                      labelText:
                          localeProvider.translate(section, 'select_date'),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: LocalizedDateTimeFormatter.getFormattedTime(
                          context, _selectedDate),
                    ),
                    decoration: InputDecoration(
                      labelText:
                          localeProvider.translate(section, 'select_time'),
                      suffixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (!_hasChanged || _isLoading) ? null : _updateEvent,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                child: Text(
                  localeProvider.translate(section, 'update_event'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _confirmCancelEvent,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 30)),
                  backgroundColor: WidgetStateProperty.all(Colors.red),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                child: Text(
                  localeProvider.translate(section, 'cancel_event'),
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
