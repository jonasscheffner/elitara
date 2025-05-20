import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/models/event.dart';
import 'package:elitara/models/access_type.dart';
import 'package:elitara/models/membership_type.dart';
import 'package:elitara/services/chat_service.dart';
import 'package:elitara/services/membership_service.dart';
import 'package:elitara/utils/app_snack_bar.dart';
import 'package:elitara/widgets/search_filter.dart';
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
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

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
  final Map<String, bool> _isParticipating = {};
  bool _hasUnreadChats = false;
  bool _showOnlyParticipatingEvents = false;
  MembershipType? _membership;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _checkUnreadChats();
    _loadMembership();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreEvents();
      }
    });
  }

  Future<void> _loadMembership() async {
    final membership = await MembershipService().getCurrentMembership();
    setState(() {
      _membership = membership;
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

  Future<void> _checkUnreadChats() async {
    final userId = await _userService.getCurrentUserId();
    final hasUnread = await ChatService().hasUnreadChats(userId);
    setState(() {
      _hasUnreadChats = hasUnread;
    });
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
        _isParticipating[ev.id] = ev.participants.contains(_currentUserId);
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
        _isParticipating[ev.id] = ev.participants.contains(_currentUserId);
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

  List<Event> get _filteredEvents {
    var filtered = _events;

    if (_showOnlyParticipatingEvents) {
      filtered =
          filtered.where((ev) => _isParticipating[ev.id] == true).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      filtered = filtered.where((ev) {
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

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(locale.translate(section, 'title')),
            centerTitle: true,
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.message),
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      _searchController.clear();

                      if (_membership == null ||
                          _membership == MembershipType.guest) {
                        AppSnackBar.show(
                          context,
                          locale.translate(
                              section, 'upgrade_required_messages'),
                          type: SnackBarType.warning,
                        );
                        return;
                      }

                      await Navigator.pushNamed(context, '/chatList');
                      _checkUnreadChats();
                    },
                  ),
                  if (_hasUnreadChats)
                    Positioned(
                      right: 11,
                      top: 11,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _searchController.clear();
                  Navigator.pushNamed(context, '/settingsMenu');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SearchFilter(
                      section: section,
                      controller: _searchController,
                      onChanged: (v) => setState(() {
                        _searchQuery = v.toLowerCase();
                      }),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(
                            () => _showOnlyOwnEvents = !_showOnlyOwnEvents);
                        _loadEvents();
                      },
                      icon: const Icon(Icons.star, size: 20),
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
                    const SizedBox(height: 4),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showOnlyParticipatingEvents =
                            !_showOnlyParticipatingEvents);
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        locale.translate(
                            section, 'filter_participating_events'),
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: _showOnlyParticipatingEvents
                            ? Colors.blue
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        controller: _scrollController,
                        itemCount:
                            _filteredEvents.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _filteredEvents.length) {
                            return const Center(
                                child: CircularProgressIndicator());
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
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      ev.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (ev.host == _currentUserId)
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 20)
                                  else if (_isParticipating[ev.id] == true)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              LocalizedDateTimeFormatter
                                                  .getFormattedDate(
                                                      context, dateTime),
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.access_time,
                                                size: 16),
                                            const SizedBox(width: 6),
                                            Text(
                                              LocalizedDateTimeFormatter
                                                  .getFormattedTime(
                                                      context, dateTime),
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              accessEnum ==
                                                      AccessType.inviteOnly
                                                  ? Icons.lock
                                                  : Icons.public,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              accessText,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.person, size: 16),
                                            const SizedBox(width: 6),
                                            UserDisplayName(
                                              uid: ev.host,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                FocusScope.of(context).unfocus();
                                _searchController.clear();
                                await Navigator.pushNamed(
                                    context, '/eventDetail',
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
              FocusScope.of(context).unfocus();
              _searchController.clear();

              final membership = _membership;

              if (membership == null || membership == MembershipType.guest) {
                AppSnackBar.show(
                  context,
                  locale.translate(section, 'upgrade_required_create'),
                  type: SnackBarType.warning,
                );
                return;
              }

              if (membership == MembershipType.gold) {
                final userId = await _userService.getCurrentUserId();
                final isLimitReached =
                    await _eventService.isGoldLimitReached(userId);

                if (isLimitReached) {
                  AppSnackBar.show(
                    context,
                    locale.translate(section, 'limit_reached_gold'),
                    type: SnackBarType.warning,
                  );
                  return;
                }
              }

              await Navigator.pushNamed(context, '/createEvent');
              _loadEvents();
            },
            label: Text(locale.translate(section, 'create_event')),
            icon: const Icon(Icons.add),
          ),
        ));
  }
}
