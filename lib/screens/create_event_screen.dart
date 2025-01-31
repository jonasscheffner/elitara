import 'package:elitara/localization/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateEventScreen extends StatefulWidget {
  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String section = 'create_event_screen';

  void _createEvent() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              Localizations.of<LocaleProvider>(context, LocaleProvider)!
                  .translate(section, 'messages.fill_all_fields'))));
      return;
    }

    await FirebaseFirestore.instance.collection('events').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'location': _locationController.text,
      'date': Timestamp.fromDate(_selectedDate),
      'participants': []
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(Localizations.of<LocaleProvider>(context, LocaleProvider)!
            .translate(section, 'messsages.event_created'))));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Scaffold(
      appBar: AppBar(
          title: Text(localeProvider.translate(section, 'create_event_title'))),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: _titleController,
                decoration: InputDecoration(
                    labelText: localeProvider.translate(section, 'title'))),
            TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                    labelText:
                        localeProvider.translate(section, 'description'))),
            TextField(
                controller: _locationController,
                decoration: InputDecoration(
                    labelText: localeProvider.translate(section, 'location'))),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null)
                  setState(() => _selectedDate = pickedDate);
              },
              child: Text(
                  "${localeProvider.translate(section, 'select_date')}: ${_selectedDate.toLocal()}"
                      .split(' ')[0]),
            ),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: _createEvent,
                child: Text(localeProvider.translate(section, 'create_event'))),
          ],
        ),
      ),
    );
  }
}
