import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/services/user_service.dart';
import 'package:elitara/services/invitation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:elitara/widgets/search_filter.dart';
import 'package:elitara/localization/locale_provider.dart';

class InviteUsersDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final List<String> currentParticipants;

  const InviteUsersDialog({
    super.key,
    required this.eventId,
    required this.eventTitle,
    required this.currentParticipants,
  });

  @override
  _InviteUsersDialogState createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends State<InviteUsersDialog> {
  final String section = 'invite_users';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final UserService _userService = UserService();
  final InvitationService _invitationService = InvitationService();

  List<QueryDocumentSnapshot> _searchResults = [];
  Set<String> _invitedUserIds = {};
  final Set<String> _loadingUserIds = {};
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadInvitedUsers();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreUsers();
      }
    });
  }

  Future<void> _loadInvitedUsers() async {
    final ids =
        await _invitationService.getInvitedUserIdsForEvent(widget.eventId);
    setState(() => _invitedUserIds = ids);
  }

  Future<void> _searchUsers(String term) async {
    term = term.trim();
    if (term.isEmpty) {
      setState(() {
        _searchResults.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _resetScroll();
      return;
    }

    setState(() {
      _isLoading = true;
      _lastDocument = null;
      _hasMore = true;
    });

    final current = FirebaseAuth.instance.currentUser!.uid;
    final exclude = {current, ...widget.currentParticipants};

    final results = await _userService.searchUsersByFilters(
      searchTerm: term,
      excludeUserIds: exclude.toList(),
    );

    setState(() {
      _searchResults = results;
      _isLoading = false;
      if (results.length < 20) _hasMore = false;
      if (results.isNotEmpty) _lastDocument = results.last;
    });
    _resetScroll();
  }

  Future<void> _loadMoreUsers() async {
    if (_searchController.text.trim().isEmpty || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);

    final current = FirebaseAuth.instance.currentUser!.uid;
    final exclude = {current, ...widget.currentParticipants};

    final more = await _userService.searchUsersByFilters(
      searchTerm: _searchController.text.trim(),
      lastDoc: _lastDocument,
      excludeUserIds: exclude.toList(),
    );

    setState(() {
      _searchResults.addAll(more);
      _isLoadingMore = false;
      if (more.length < 20) _hasMore = false;
      if (more.isNotEmpty) _lastDocument = more.last;
    });
  }

  Future<void> _sendInvitation(String uid) async {
    setState(() => _loadingUserIds.add(uid));
    await _invitationService.sendEventInvitation(
      targetUserId: uid,
      eventId: widget.eventId,
      eventTitle: widget.eventTitle,
    );
    setState(() {
      _invitedUserIds.add(uid);
      _loadingUserIds.remove(uid);
    });
  }

  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
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

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 400,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  Column(
                    children: [
                      SearchFilter(
                        focusNode: _searchFocusNode,
                        section: section,
                        controller: _searchController,
                        onChanged: _searchUsers,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults.clear();
                                    _lastDocument = null;
                                    _hasMore = true;
                                  });
                                  _resetScroll();
                                },
                              )
                            : null),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _searchResults.isEmpty
                            ? Center(
                                child: Text(
                                  locale.translate(section, 'title'),
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.zero,
                                itemCount: _searchResults.length +
                                    (_isLoadingMore ? 1 : 0),
                                itemBuilder: (ctx, idx) {
                                  if (idx == _searchResults.length &&
                                      _isLoadingMore) {
                                    return const Center(
                                      child: Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 12),
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                    );
                                  }
                                  final doc = _searchResults[idx];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final userId = doc.id;
                                  final name = data['displayName'] ?? 'Unknown';
                                  final invited =
                                      _invitedUserIds.contains(userId);

                                  return ListTile(
                                    title: Tooltip(
                                      message: name,
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    trailing: invited
                                        ? Text(
                                            locale.translate(
                                                section, 'already_invited'),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14),
                                          )
                                        : _loadingUserIds.contains(userId)
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2),
                                              )
                                            : TextButton(
                                                onPressed: () =>
                                                    _sendInvitation(userId),
                                                child: Text(
                                                  locale.translate(
                                                      section, 'invite_button'),
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                ),
                                              ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            locale.translate(section, 'close'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
          ),
        ));
  }
}
