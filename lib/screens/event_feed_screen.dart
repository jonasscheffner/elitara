import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/screens/user_display_name.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';

class EventFeedScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String section = 'event_feed_screen';

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(localeProvider.translate(section, 'title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settingsMenu'),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _firestore
            .collection('events')
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(localeProvider.translate(section, 'no_events')),
            );
          }
          var events = snapshot.data!.docs;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              var event = events[index];
              final DateTime dateTime = event['date'].toDate();
              final dynamic hostData = event['host'];
              String hostDisplay;
              String hostId;
              if (hostData is Map) {
                hostDisplay = hostData['displayName'] ?? 'Unknown';
                hostId = hostData['uid'] as String? ?? '';
              } else if (hostData is String) {
                hostDisplay = hostData;
                hostId = hostData;
              } else {
                hostDisplay = 'Unknown';
                hostId = '';
              }
              return Card(
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(15),
                  title: Text(
                    event['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizedDateTimeFormatter.getFormattedDateTime(
                            context, dateTime),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "${localeProvider.translate(section, 'hosted_by')}: ",
                            style: const TextStyle(fontSize: 14),
                          ),
                          UserDisplayName(
                              uid: hostId,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => Navigator.pushNamed(context, '/eventDetail',
                      arguments: event.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/createEvent'),
        label: Text(localeProvider.translate(section, 'create_event')),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
