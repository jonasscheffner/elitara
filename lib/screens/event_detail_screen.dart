import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/localization/locale_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  String section = 'event_detail_screen';

  EventDetailScreen({required this.eventId});

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Scaffold(
      appBar: AppBar(title: Text(localeProvider.translate(section, 'title'))),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('events').doc(eventId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var eventData = snapshot.data!;
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventData['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(eventData['description'], style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
                Text(
                    "${localeProvider.translate(section, 'date')}: ${eventData['date'].toDate()}"),
                Text(
                    "${localeProvider.translate(section, 'location')}: ${eventData['location']}"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('events')
                        .doc(eventId)
                        .update({
                      'participants': FieldValue.arrayUnion(['testUser'])
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              localeProvider.translate(section, 'registered'))),
                    );
                  },
                  child: Text(localeProvider.translate(section, 'join')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
