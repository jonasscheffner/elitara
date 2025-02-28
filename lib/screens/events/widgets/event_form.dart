import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:elitara/widgets/required_field_label.dart';

class EventForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController participantLimitController;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final String accessType;
  final ValueChanged<String?> onAccessTypeChanged;

  final String section = "event_form";

  const EventForm({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.participantLimitController,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.accessType,
    required this.onAccessTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            label: RequiredFieldLabel(
              label: localeProvider.translate(section, 'title'),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            label: RequiredFieldLabel(
              label: localeProvider.translate(section, 'description'),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: locationController,
          decoration: InputDecoration(
            label: RequiredFieldLabel(
              label: localeProvider.translate(section, 'location'),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onSelectDate,
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(
                text: LocalizedDateTimeFormatter.getFormattedDate(
                    context, selectedDate),
              ),
              decoration: InputDecoration(
                labelText: localeProvider.translate(section, 'select_date'),
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
          onTap: onSelectTime,
          child: AbsorbPointer(
            child: TextField(
              controller: TextEditingController(
                text: LocalizedDateTimeFormatter.getFormattedTime(
                  context,
                  DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  ),
                ),
              ),
              decoration: InputDecoration(
                labelText: localeProvider.translate(section, 'select_time'),
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
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: localeProvider.translate(section, 'access'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          ),
          value: accessType,
          items: [
            DropdownMenuItem(
              value: "public",
              child: Text(localeProvider.translate(section, 'access_public')),
            ),
            DropdownMenuItem(
              value: "invite_only",
              child:
                  Text(localeProvider.translate(section, 'access_invite_only')),
            ),
          ],
          onChanged: onAccessTypeChanged,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: participantLimitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText:
                  "${localeProvider.translate(section, 'participant_limit')} (optional)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            ),
          ),
        ),
      ],
    );
  }
}
