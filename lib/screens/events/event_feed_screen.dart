import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/screens/events/filters/event_search_filter.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:elitara/services/user_service.dart';
import 'package:elitara/services/event_service.dart';
import 'package:flutter/material.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class EventFeedScreen extends StatefulWidget {
  const EventFeedScreen({super.key});

  @override
  _EventFeedScreenState createState() => _EventFeedScreenState();
}

class _EventFeedScreenState extends State<EventFeedScreen> with RouteAware {
  final EventService _eventService = EventService(itemsPerPage: 10);
  final String section = 'event_feed_screen';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    QuerySnapshot querySnapshot = await _eventService.getInitialEvents();
    _events = querySnapshot.docs;
    if (_events.isNotEmpty) {
      _lastDocument = _events.last;
    }
    if (_events.length < _eventService.itemsPerPage) {
      _hasMore = false;
    }
    await _loadHostNamesForEvents(_events);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreEvents() async {
    if (!_hasMore || _lastDocument == null) return;
    setState(() {
      _isLoadingMore = true;
    });
    QuerySnapshot querySnapshot =
        await _eventService.getMoreEvents(_lastDocument!);
    if (querySnapshot.docs.isNotEmpty) {
      _events.addAll(querySnapshot.docs);
      _lastDocument = querySnapshot.docs.last;
      if (querySnapshot.docs.length < _eventService.itemsPerPage) {
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
                      final String accessType =
                          (data.containsKey('accessType') &&
                                  data['accessType'] is String)
                              ? data['accessType'] as String
                              : "public";
                      String accessText = accessType == "invite_only"
                          ? localeProvider.translate(
                              section, 'access_invite_only')
                          : localeProvider.translate(section, 'access_public');
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
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "${localeProvider.translate(section, 'access')}: ",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    accessText,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () async {
                            await Navigator.pushNamed(context, '/eventDetail',
                                arguments: event.id);
                            _loadEvents();
                          },
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
