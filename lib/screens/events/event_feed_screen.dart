import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/screens/events/filters/event_search_filter.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';
import 'package:elitara/screens/events/widgets/waitlist_dialog.dart';
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
  bool _showOnlyOwnEvents = false;
  String _currentUserId = '';
  final Map<String, int> _waitlistCounts = {};

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
    try {
      if (_currentUserId.isEmpty) {
        _currentUserId = await _userService.getCurrentUserId();
      }
      QuerySnapshot querySnapshot;
      if (_showOnlyOwnEvents) {
        if (_currentUserId.isNotEmpty) {
          querySnapshot =
              await _eventService.getUserHostedEvents(_currentUserId);
        } else {
          throw Exception("User ID is empty");
        }
      } else {
        querySnapshot = await _eventService.getInitialEvents();
      }
      _events = querySnapshot.docs;
      for (var event in _events) {
        final data = event.data() as Map<String, dynamic>;
        _waitlistCounts[event.id] =
            data['waitlist'] != null ? (data['waitlist'] as List).length : 0;
      }
      if (_events.isNotEmpty) {
        _lastDocument = _events.last;
      }
      if (_events.length < _eventService.itemsPerPage) {
        _hasMore = false;
      }
      await _loadHostNamesForEvents(_events);
    } catch (e) {
      debugPrint("Fehler beim Laden der Events: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
      for (var event in querySnapshot.docs) {
        final data = event.data() as Map<String, dynamic>;
        _waitlistCounts[event.id] =
            data['waitlist'] != null ? (data['waitlist'] as List).length : 0;
      }
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

  Future<void> _updateWaitlistForEvent(String eventId) async {
    DocumentSnapshot doc = await _eventService.getEvent(eventId);
    final data = doc.data() as Map<String, dynamic>;
    int count =
        data['waitlist'] != null ? (data['waitlist'] as List).length : 0;
    setState(() {
      _waitlistCounts[eventId] = count;
    });
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showOnlyOwnEvents = !_showOnlyOwnEvents;
                  });
                  _loadEvents();
                },
                icon: const Icon(Icons.person, size: 20),
                label: Text(
                  localeProvider.translate(section, 'filter_own_events'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor:
                      _showOnlyOwnEvents ? Colors.blue : Colors.grey,
                ),
              ),
            ),
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
                      final AccessType accessTypeEnum =
                          data.containsKey('accessType') &&
                                  data['accessType'] is String
                              ? AccessTypeExtension.fromString(
                                  data['accessType'] as String)
                              : AccessType.public;
                      String accessText = accessTypeEnum ==
                              AccessType.inviteOnly
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
                              Text(LocalizedDateTimeFormatter
                                  .getFormattedDateTime(context, dateTime)),
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
                              if (data['waitlistEnabled'] == true &&
                                  data['host'] == _currentUserId)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hourglass_empty),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${localeProvider.translate(section, 'waitlist')}: ${_waitlistCounts[event.id] ?? 0}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if ((_waitlistCounts[event.id] ?? 0) > 0)
                                        TextButton(
                                          child: Text(localeProvider.translate(
                                              section, 'open_waitlist')),
                                          onPressed: () async {
                                            int currentParticipants =
                                                data['participants'] != null
                                                    ? (data['participants']
                                                            as List)
                                                        .length
                                                    : 0;
                                            int? participantLimit =
                                                data['participantLimit'];
                                            List<Map<String, dynamic>>
                                                waitlistEntries = [];
                                            if (data['waitlist'] != null) {
                                              waitlistEntries = List<
                                                      Map<String,
                                                          dynamic>>.from(
                                                  data['waitlist']);
                                            }
                                            final result = await showDialog(
                                              context: context,
                                              barrierColor: Colors.transparent,
                                              builder: (context) {
                                                return Stack(
                                                  children: [
                                                    BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                          sigmaX: 5, sigmaY: 5),
                                                      child: Container(
                                                        color: const Color(
                                                                0x80000000)
                                                            .withOpacity(0),
                                                      ),
                                                    ),
                                                    WaitlistDialog(
                                                      eventId: event.id,
                                                      eventTitle: data['title'],
                                                      waitlistEntries:
                                                          waitlistEntries,
                                                      participantLimit:
                                                          participantLimit,
                                                      currentParticipants:
                                                          currentParticipants,
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (result == true) {
                                              _updateWaitlistForEvent(event.id);
                                            }
                                          },
                                        ),
                                    ],
                                  ),
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
