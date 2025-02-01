import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/localization/locale_provider.dart';

class EventFeedScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String section = 'event_feed_screen';

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/createEvent'),
            child: Text(
              localeProvider.translate(section, 'create_event'),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(localeProvider.translate(section, 'no_events')));
          }
          var events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              final DateTime dateTime = event['date'].toDate();
              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    event['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    LocalizedDateTimeFormatter.getFormattedDateTime(
                        context, dateTime),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/eventDetail',
                    arguments: event.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
