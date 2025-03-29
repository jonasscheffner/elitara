import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/visibility_option.dart';
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
  final VisibilityOption visibility;
  final ValueChanged<VisibilityOption?> onVisibilityChanged;
  final bool canInvite;
  final ValueChanged<bool> onCanInviteChanged;
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
    required this.visibility,
    required this.onVisibilityChanged,
    required this.canInvite,
    required this.onCanInviteChanged,
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
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onSelectDate,
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: LocalizedDateTimeFormatter.getFormattedDate(
                          context, selectedDate),
                    ),
                    decoration: InputDecoration(
                      labelText:
                          localeProvider.translate(section, 'select_date'),
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
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
                            selectedTime.minute),
                      ),
                    ),
                    decoration: InputDecoration(
                      labelText:
                          localeProvider.translate(section, 'select_time'),
                      suffixIcon: const Icon(Icons.access_time),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 12.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<VisibilityOption>(
                decoration: InputDecoration(
                  labelText: localeProvider.translate(section, 'visibility'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0)),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 12.0),
                ),
                value: visibility,
                items: [
                  DropdownMenuItem(
                    value: VisibilityOption.everyone,
                    child: Text(localeProvider.translate(
                        section, 'visibility_everyone')),
                  ),
                  DropdownMenuItem(
                    value: VisibilityOption.participantsOnly,
                    child: Text(localeProvider.translate(
                        section, 'visibility_participants_only')),
                  ),
                ],
                onChanged: onVisibilityChanged,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
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
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    localeProvider.translate(section, 'enable_waitlist'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            Switch(
              value: waitlistEnabled,
              onChanged: onWaitlistChanged,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(localeProvider.translate(section, 'invite_permission'),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: localeProvider.translate(
                        section, 'invite_permission_info'),
                    child: const Icon(Icons.info_outline, size: 18),
                  ),
                ],
              ),
            ),
            Switch(
              value: canInvite,
              onChanged: onCanInviteChanged,
            ),
          ],
        ),
      ],
    );
  }
}
