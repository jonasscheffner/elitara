import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/screens/events/filters/event_search_filter.dart';
import 'package:elitara/screens/user_display_name.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:elitara/services/user_service.dart';
import 'package:flutter/material.dart';

class EventFeedScreen extends StatefulWidget {
  const EventFeedScreen({super.key});

  @override
  _EventFeedScreenState createState() => _EventFeedScreenState();
}

class _EventFeedScreenState extends State<EventFeedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String section = 'event_feed_screen';
  final int itemsPerPage = 10;
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  final Map<String, String> _hostNames = {};
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreEvents();
      }
    });
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    Query query = _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .orderBy('date')
        .limit(itemsPerPage);
    QuerySnapshot querySnapshot = await query.get();
    _events = querySnapshot.docs;
    if (_events.isNotEmpty) {
      _lastDocument = _events.last;
    }
    if (_events.length < itemsPerPage) {
      _hasMore = false;
    }
    await _loadHostNamesForEvents(_events);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreEvents() async {
    if (!_hasMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    Query query = _firestore
        .collection('events')
        .where('status', isEqualTo: 'active')
        .orderBy('date')
        .startAfterDocument(_lastDocument!)
        .limit(itemsPerPage);
    QuerySnapshot querySnapshot = await query.get();
    if (querySnapshot.docs.isNotEmpty) {
      _events.addAll(querySnapshot.docs);
      _lastDocument = querySnapshot.docs.last;
      if (querySnapshot.docs.length < itemsPerPage) {
        _hasMore = false;
      }
      await _loadHostNamesForEvents(querySnapshot.docs);
    } else {
      _hasMore = false;
    }
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _loadHostNamesForEvents(List<DocumentSnapshot> docs) async {
    Set<String> hostIds = {};
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final dynamic hostData = data['host'];
      String hostId = '';
      if (hostData is String) {
        hostId = hostData;
      } else if (hostData is Map) {
        hostId = hostData['uid'] as String? ?? '';
      }
      if (hostId.isNotEmpty && !_hostNames.containsKey(hostId)) {
        hostIds.add(hostId);
      }
    }
    for (var id in hostIds) {
      _userService.getUser(id).then((userData) {
        setState(() {
          _hostNames[id] = userData['displayName'] ?? 'Unknown';
        });
      });
    }
  }

  List<DocumentSnapshot> get _filteredEvents {
    if (_searchQuery.isEmpty) {
      return _events;
    } else {
      return _events.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final title = (data['title'] ?? '').toString().toLowerCase();
        final description =
            (data['description'] ?? '').toString().toLowerCase();
        final location = (data['location'] ?? '').toString().toLowerCase();
        String host = '';
        final dynamic hostData = data['host'];
        if (hostData is Map) {
          host = _hostNames[hostData['uid']]?.toLowerCase() ?? '';
        } else if (hostData is String) {
          host = _hostNames[hostData]?.toLowerCase() ?? hostData.toLowerCase();
        }
        return title.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            location.contains(_searchQuery) ||
            host.contains(_searchQuery);
      }).toList();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          EventSearchFilter(
            section: section,
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        _filteredEvents.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _filteredEvents.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var event = _filteredEvents[index];
                      final Map<String, dynamic> data =
                          event.data() as Map<String, dynamic>;
                      final DateTime dateTime = data['date'].toDate();
                      final dynamic hostData = data['host'];
                      String hostId = '';
                      if (hostData is String) {
                        hostId = hostData;
                      } else if (hostData is Map) {
                        hostId = hostData['uid'] as String? ?? '';
                      }
                      return Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Text(
                            data['title'],
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
                          onTap: () => Navigator.pushNamed(
                              context, '/eventDetail',
                              arguments: event.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/createEvent');
          _loadEvents();
        },
        label: Text(localeProvider.translate(section, 'create_event')),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
