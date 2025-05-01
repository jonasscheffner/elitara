import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/widgets/search_filter.dart';
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
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();

  final String section = 'event_feed_screen';
  List<Event> _events = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';
  String _currentUserId = '';
  bool _showOnlyOwnEvents = false;
  final Map<String, String> _hostNames = {};
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
    setState(() => _isLoading = true);
    try {
      if (_currentUserId.isEmpty) {
        _currentUserId = await _userService.getCurrentUserId();
      }

      QuerySnapshot raw;
      if (_showOnlyOwnEvents) {
        raw = await _eventService.getUserHostedEvents(_currentUserId);
      } else {
        raw = await _eventService.getInitialEvents();
      }

      _events = raw.docs
          .map((d) => Event.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      _lastDocument = raw.docs.isNotEmpty ? raw.docs.last : null;
      _hasMore = raw.docs.length >= _eventService.itemsPerPage;

      for (var ev in _events) {
        _waitlistCounts[ev.id] = ev.waitlist.length;
      }
      await _loadHostNamesForEvents(_events);
    } catch (e) {
      debugPrint("Fehler beim Laden der Events: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreEvents() async {
    if (!_hasMore || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);

    QuerySnapshot raw = await _eventService.getMoreEvents(_lastDocument!);

    if (raw.docs.isNotEmpty) {
      final more = raw.docs
          .map((d) => Event.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      _events.addAll(more);
      _lastDocument = raw.docs.last;
      _hasMore = raw.docs.length >= _eventService.itemsPerPage;

      for (var ev in more) {
        _waitlistCounts[ev.id] = ev.waitlist.length;
      }
      await _loadHostNamesForEvents(more);
    } else {
      _hasMore = false;
    }

    setState(() => _isLoadingMore = false);
  }

  Future<void> _loadHostNamesForEvents(List<Event> events) async {
    final hosts = events.map((e) => e.host).toSet()
      ..removeWhere((id) => id.isEmpty || _hostNames.containsKey(id));

    for (var id in hosts) {
      final userData = await _userService.getUser(id);
      setState(() {
        _hostNames[id] = userData['displayName'] ?? 'Unknown';
      });
    }
  }

  Future<void> _updateWaitlistForEvent(String eventId) async {
    final doc = await _eventService.getEvent(eventId);
    final fresh = Event.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    setState(() {
      _waitlistCounts[eventId] = fresh.waitlist.length;
    });
  }

  List<Event> get _filteredEvents {
    if (_searchQuery.isEmpty) return _events;
    return _events.where((ev) {
      final q = _searchQuery;
      final title = ev.title.toLowerCase();
      final desc = ev.description.toLowerCase();
      final loc = ev.location.toLowerCase();
      final host =
          (_hostNames[ev.host]?.toLowerCase() ?? ev.host.toLowerCase());
      return title.contains(q) ||
          desc.contains(q) ||
          loc.contains(q) ||
          host.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(locale.translate(section, 'title')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () => Navigator.pushNamed(context, '/chatList'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settingsMenu'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SearchFilter(
              section: section,
              onChanged: (v) => setState(() {
                _searchQuery = v.toLowerCase();
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() => _showOnlyOwnEvents = !_showOnlyOwnEvents);
                  _loadEvents();
                },
                icon: const Icon(Icons.person, size: 20),
                label: Text(
                  locale.translate(section, 'filter_own_events'),
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
                    itemBuilder: (ctx, i) {
                      if (i == _filteredEvents.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final ev = _filteredEvents[i];
                      final dateTime = ev.date;
                      final accessEnum = ev.accessType;
                      final accessText = accessEnum == AccessType.inviteOnly
                          ? locale.translate(section, 'access_invite_only')
                          : locale.translate(section, 'access_public');
                      final waitlistLimit = ev.waitlistLimit;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Text(
                            ev.title,
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
                                    "${locale.translate(section, 'hosted_by')}: ",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  UserDisplayName(
                                    uid: ev.host,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "${locale.translate(section, 'access')}: ",
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
                              if (ev.waitlistEnabled)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.hourglass_top),
                                      const SizedBox(width: 4),
                                      Text(
                                        waitlistLimit != null
                                            ? "${_waitlistCounts[ev.id] ?? 0} / $waitlistLimit"
                                            : "${_waitlistCounts[ev.id] ?? 0}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      if (_currentUserId == ev.host &&
                                          (_waitlistCounts[ev.id] ?? 0) > 0)
                                        TextButton(
                                          child: Text(locale.translate(
                                              section, 'open_waitlist')),
                                          onPressed: () async {
                                            final currentParticipants =
                                                ev.participants.length;
                                            final entries = ev.waitlist;
                                            final result = await showDialog(
                                              context: ctx,
                                              barrierColor: Colors.transparent,
                                              builder: (_) {
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
                                                      eventId: ev.id,
                                                      eventTitle: ev.title,
                                                      waitlistEntries: entries,
                                                      participantLimit:
                                                          ev.participantLimit,
                                                      currentParticipants:
                                                          currentParticipants,
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (result == true) {
                                              _updateWaitlistForEvent(ev.id);
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
                                arguments: ev.id);
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
        label: Text(locale.translate(section, 'create_event')),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
