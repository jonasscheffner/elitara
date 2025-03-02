import 'package:elitara/models/access_type.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:elitara/widgets/required_field_label.dart';

class EventForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController participantLimitController;
  final TextEditingController waitlistLimitController;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final AccessType accessType;
  final ValueChanged<AccessType?> onAccessTypeChanged;
  final bool waitlistEnabled;
  final ValueChanged<bool> onWaitlistChanged;
  final String section = "event_form";
  final String? participantLimitError;
  final String? waitlistLimitError;

  const EventForm({
    Key? key,
    required this.titleController,
    required this.descriptionController,
    required this.locationController,
    required this.participantLimitController,
    required this.waitlistLimitController,
    required this.selectedDate,
    required this.selectedTime,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.accessType,
    required this.onAccessTypeChanged,
    required this.waitlistEnabled,
    required this.onWaitlistChanged,
    this.participantLimitError,
    this.waitlistLimitError,
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
                label: localeProvider.translate(section, 'title')),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            label: RequiredFieldLabel(
                label: localeProvider.translate(section, 'description')),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
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
                label: localeProvider.translate(section, 'location')),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
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
                    borderRadius: BorderRadius.circular(12.0)),
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
                  DateTime(selectedDate.year, selectedDate.month,
                      selectedDate.day, selectedTime.hour, selectedTime.minute),
                ),
              ),
              decoration: InputDecoration(
                labelText: localeProvider.translate(section, 'select_time'),
                suffixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0, horizontal: 12.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<AccessType>(
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'access'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
                value: accessType,
                items: [
                  DropdownMenuItem(
                    value: AccessType.public,
                    child: Text(
                        localeProvider.translate(section, 'access_public')),
                  ),
                  DropdownMenuItem(
                    value: AccessType.inviteOnly,
                    child: Text(localeProvider.translate(
                        section, 'access_invite_only')),
                  ),
                ],
                onChanged: onAccessTypeChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: TextField(
                controller: participantLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      localeProvider.translate(section, 'participant_limit'),
                  errorText: participantLimitError,
                  errorMaxLines: 2,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (accessType == AccessType.inviteOnly)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        localeProvider.translate(section, 'enable_waitlist'),
                        style: const TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                        value: waitlistEnabled, onChanged: onWaitlistChanged),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: waitlistLimitController,
                  keyboardType: TextInputType.number,
                  enabled: waitlistEnabled,
                  decoration: InputDecoration(
                    labelText:
                        localeProvider.translate(section, 'waitlist_limit'),
                    errorText: waitlistLimitError,
                    errorMaxLines: 2,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 12.0),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
