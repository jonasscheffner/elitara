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
      appBar: AppBar(title: Text(localeProvider.translate(section, 'title'))),
      body: StreamBuilder(
        stream: _firestore.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
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
              return ListTile(
                title: Text(event['title']),
                subtitle: Text(event['date'].toDate().toString()),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/eventDetail',
                  arguments: event.id,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
