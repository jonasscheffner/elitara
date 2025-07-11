import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:elitara/widgets/search_filter.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';
import 'package:elitara/services/user_service.dart';
import 'package:elitara/services/event_service.dart';
import 'package:elitara/screens/chat/chat_detail_screen.dart';

class ParticipantListDialog extends StatefulWidget {
  final String eventId;
  final String hostId;
  final List<String> initialParticipants;
  final List<String> coHosts;

  const ParticipantListDialog({
    Key? key,
    required this.eventId,
    required this.hostId,
    required this.initialParticipants,
    required this.coHosts,
  }) : super(key: key);

  @override
  _ParticipantListDialogState createState() => _ParticipantListDialogState();
}

class _ParticipantListDialogState extends State<ParticipantListDialog> {
  final String section = 'event_detail_screen.participant_list_dialog';

  final UserService _userService = UserService();
  final EventService _eventService = EventService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<_Participant> _allParticipants = [];
  List<_Participant> _filteredParticipants = [];
  List<_Participant> _displayedParticipants = [];

  String _searchTerm = '';
  final int _pageSize = 20;
  int _currentMax = 20;
  bool _hasMore = false;
  bool _isLoading = true;
  bool _isFiltering = false;
  bool _hasReturnedFromChat = false;

  @override
  void initState() {
    super.initState();
    _loadAllParticipants();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasReturnedFromChat && mounted) {
        FocusScope.of(context).requestFocus(_searchFocusNode);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openChatWithUser(String uid) async {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      currentFocus.unfocus();
      await Future.delayed(const Duration(milliseconds: 10));
    }

    if (mounted) {
      setState(() => _hasReturnedFromChat = true);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(otherUserId: uid),
        fullscreenDialog: false,
      ),
    );

    if (mounted) {
      setState(() => _hasReturnedFromChat = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
      });
    }
  }

  Future<void> _loadAllParticipants() async {
    final temp = <_Participant>[];
    for (var uid in widget.initialParticipants) {
      final data = await _userService.getUser(uid);
      temp.add(_Participant(uid: uid, displayName: data['displayName'] ?? ''));
    }
    temp.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    setState(() {
      _allParticipants = temp;
      _isLoading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    _filteredParticipants = _allParticipants
        .where((p) =>
            p.displayName.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();

    _currentMax = _pageSize;
    _hasMore = _filteredParticipants.length > _currentMax;
    _displayedParticipants = _filteredParticipants.take(_currentMax).toList();
    setState(() {});
  }

  void _onSearchChanged() {
    setState(() {
      _searchTerm = _searchController.text;
      _isFiltering = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _applyFilter();
      setState(() => _isFiltering = false);
    });
  }

  void _loadMore() {
    if (!_hasMore) return;
    final more =
        _filteredParticipants.skip(_currentMax).take(_pageSize).toList();
    setState(() {
      _displayedParticipants.addAll(more);
      _currentMax += _pageSize;
      _hasMore = _filteredParticipants.length > _currentMax;
    });
  }

  bool get _isCurrentUserHost {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == widget.hostId;
  }

  bool get _isCurrentUserCoHost {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && widget.coHosts.contains(uid);
  }

  Future<void> _makeCoHost(String uid) async {
    await _eventService.updateEvent(widget.eventId, {
      'coHosts': FieldValue.arrayUnion([uid]),
    });
    setState(() {
      widget.coHosts.add(uid);
    });
  }

  Future<void> _removeCoHost(String uid) async {
    await _eventService.updateEvent(widget.eventId, {
      'coHosts': FieldValue.arrayRemove([uid]),
    });
    setState(() {
      widget.coHosts.remove(uid);
    });
  }

  Future<void> _removeParticipant(String uid) async {
    await _eventService.leaveEvent(widget.eventId, uid);
    setState(() {
      _allParticipants.removeWhere((p) => p.uid == uid);
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          height: 500,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SearchFilter(
                        focusNode: _searchFocusNode,
                        section: section,
                        controller: _searchController,
                        onChanged: (_) {},
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged();
                                },
                              )
                            : null,
                      ),
                      if (_isFiltering)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              controller: _scrollController,
                              padding: EdgeInsets.zero,
                              itemCount: _displayedParticipants.length +
                                  (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _displayedParticipants.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final p = _displayedParticipants[index];
                                final isHost = p.uid == widget.hostId;
                                final isCoHost = widget.coHosts.contains(p.uid);
                                final currentUserId =
                                    FirebaseAuth.instance.currentUser?.uid;
                                final isSelf = p.uid == currentUserId;

                                Widget? trailing;
                                if (!isSelf) {
                                  trailing = PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'start_chat') {
                                        await _openChatWithUser(p.uid);
                                      } else if (value == 'make_cohost' &&
                                          _isCurrentUserHost) {
                                        _makeCoHost(p.uid);
                                      } else if (value == 'remove_cohost' &&
                                          _isCurrentUserHost) {
                                        _removeCoHost(p.uid);
                                      } else if (value ==
                                              'remove_participant' &&
                                          (_isCurrentUserHost ||
                                              _isCurrentUserCoHost)) {
                                        _removeParticipant(p.uid);
                                      }
                                    },
                                    onCanceled: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                    itemBuilder: (_) {
                                      final items = <PopupMenuEntry<String>>[];

                                      items.add(
                                        PopupMenuItem(
                                          value: 'start_chat',
                                          child: Text(locale.translate(
                                              section, 'start_chat')),
                                        ),
                                      );

                                      if (_isCurrentUserHost ||
                                          _isCurrentUserCoHost) {
                                        if (_isCurrentUserHost) {
                                          if (isCoHost) {
                                            items.add(PopupMenuItem(
                                              value: 'remove_cohost',
                                              child: Text(locale.translate(
                                                  section, 'remove_cohost')),
                                            ));
                                          } else {
                                            items.add(PopupMenuItem(
                                              value: 'make_cohost',
                                              child: Text(locale.translate(
                                                  section, 'make_cohost')),
                                            ));
                                          }
                                        }

                                        items.add(PopupMenuItem(
                                          value: 'remove_participant',
                                          child: Text(locale.translate(
                                              section, 'remove_participant')),
                                        ));
                                      }

                                      return items;
                                    },
                                  );
                                }
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => ChatDetailScreen(
                                            otherUserId: p.uid),
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    onTap: () async {
                                      if (p.uid ==
                                          FirebaseAuth.instance.currentUser
                                              ?.uid) return;
                                      _openChatWithUser(p.uid);
                                    },
                                    title: RichText(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: [
                                          WidgetSpan(
                                            child: UserDisplayName(
                                              uid: p.uid,
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                            alignment:
                                                PlaceholderAlignment.middle,
                                          ),
                                          if (isHost)
                                            TextSpan(
                                              text:
                                                  ' (${locale.translate(section, 'host_label')})',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          if (!isHost && isCoHost)
                                            TextSpan(
                                              text:
                                                  ' (${locale.translate(section, 'co_host_label')})',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    trailing: trailing,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child:
                              Text(locale.translate(section, 'close_button')),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Participant {
  final String uid;
  final String displayName;
  _Participant({required this.uid, required this.displayName});
}
