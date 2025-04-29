import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/services/user_service.dart';
import 'package:elitara/services/invitation_service.dart';
import 'package:flutter/material.dart';
import 'package:elitara/widgets/search_filter.dart';
import 'package:elitara/localization/locale_provider.dart';

class InviteUsersDialog extends StatefulWidget {
  final String eventId;
  final String eventTitle;
  final List<String> currentParticipants;

  const InviteUsersDialog({
    Key? key,
    required this.eventId,
    required this.eventTitle,
    required this.currentParticipants,
  }) : super(key: key);

  @override
  _InviteUsersDialogState createState() => _InviteUsersDialogState();
}

class _InviteUsersDialogState extends State<InviteUsersDialog> {
  final String section = 'invite_users';
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final InvitationService _invitationService = InvitationService();

  final ScrollController _scrollController = ScrollController();

  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _hasSearched = false;
  Set<String> _invitedUserIds = {};
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _invitedUserIds.addAll(widget.currentParticipants);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMore &&
          _hasMore) {
        _loadMoreUsers();
      }
    });
  }

  Future<void> _searchUsers(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
        _lastDocument = null;
        _hasMore = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastDocument = null;
      _hasMore = true;
    });

    final results = await _userService.searchInitialUsers(searchTerm.trim());

    setState(() {
      _searchResults = results;
      _isLoading = false;
      if (results.length < 20) _hasMore = false;
      if (results.isNotEmpty) _lastDocument = results.last;
    });
  }

  Future<void> _loadMoreUsers() async {
    if (_searchController.text.trim().isEmpty || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    final moreResults = await _userService.searchMoreUsers(
        _searchController.text.trim(), _lastDocument!);

    setState(() {
      _searchResults.addAll(moreResults);
      _isLoadingMore = false;
      if (moreResults.length < 20) _hasMore = false;
      if (moreResults.isNotEmpty) _lastDocument = moreResults.last;
    });
  }

  Future<void> _sendInvitation(String targetUserId) async {
    await _invitationService.sendEventInvitation(
      targetUserId: targetUserId,
      eventId: widget.eventId,
      eventTitle: widget.eventTitle,
    );

    setState(() {
      _invitedUserIds.add(targetUserId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 400,
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SearchFilter(
                section: section,
                controller: _searchController,
                onChanged: _searchUsers,
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                                _hasSearched = false;
                                _lastDocument = null;
                                _hasMore = true;
                              });
                            },
                          )
                        : null),
                prefixIcon: const Icon(Icons.search),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          localeProvider.translate(section, 'title'),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : (_searchResults.length <= 5
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _searchResults.map((doc) {
                              final userData =
                                  doc.data() as Map<String, dynamic>;
                              final displayName =
                                  userData['displayName'] ?? 'Unknown';
                              final userId = doc.id;
                              final bool isAlreadyInvited =
                                  _invitedUserIds.contains(userId);

                              return ListTile(
                                title: Tooltip(
                                  message: displayName,
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                trailing: isAlreadyInvited
                                    ? Text(
                                        localeProvider.translate(
                                            section, 'already_invited'),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                      )
                                    : TextButton(
                                        onPressed: () =>
                                            _sendInvitation(userId),
                                        child: Text(
                                          localeProvider.translate(
                                              section, 'invite_button'),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                              );
                            }).toList(),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _searchResults.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _searchResults.length &&
                                  _isLoadingMore) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                );
                              }

                              final userDoc = _searchResults[index];
                              final userData =
                                  userDoc.data() as Map<String, dynamic>;
                              final displayName =
                                  userData['displayName'] ?? 'Unknown';
                              final userId = userDoc.id;
                              final bool isAlreadyInvited =
                                  _invitedUserIds.contains(userId);

                              return ListTile(
                                title: Tooltip(
                                  message: displayName,
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                trailing: isAlreadyInvited
                                    ? Text(
                                        localeProvider.translate(
                                            section, 'already_invited'),
                                        style: const TextStyle(
                                            color: Colors.grey, fontSize: 14),
                                      )
                                    : TextButton(
                                        onPressed: () =>
                                            _sendInvitation(userId),
                                        child: Text(
                                          localeProvider.translate(
                                              section, 'invite_button'),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                              );
                            },
                          )),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    localeProvider.translate(section, 'close'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
