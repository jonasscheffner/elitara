import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:elitara/models/membership_type.dart';
import 'package:elitara/services/membership_service.dart';
import 'package:elitara/utils/app_snack_bar.dart';
import 'package:elitara/utils/localized_date_time_formatter.dart';
import 'package:elitara/widgets/search_filter.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/chat.dart';
import 'chat_detail_screen.dart';
import 'package:elitara/screens/events/widgets/user_display_name.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String section = 'chat';
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  Timer? _debounce;
  MembershipType? _membership = MembershipType.guest;

  OverlayEntry? _overlayEntry;
  final List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoadingUsers = false;
  bool _hasMoreUsers = true;
  DocumentSnapshot? _lastUserDoc;

  List<Chat> _chats = [];
  bool _isLoadingChats = true;
  bool _isLoadingMoreChats = false;
  bool _hasMoreChats = true;
  DocumentSnapshot? _lastChatDoc;
  final ScrollController _chatScrollController = ScrollController();

  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _loadMembership();
    _loadInitialChats();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) {
        _debounce!.cancel();
      }
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final String searchText = _searchController.text.trim();
        if (searchText.isEmpty) {
          setState(() {
            _isLoadingUsers = false;
            _searchResults.clear();
            _hasMoreUsers = true;
            _lastUserDoc = null;
          });
          _removeOverlay();
        } else {
          _loadUsers(reset: true);
          _updateOverlay();
        }
      });
    });

    _chatScrollController.addListener(() {
      if (_chatScrollController.position.pixels >=
              _chatScrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMoreChats &&
          _hasMoreChats &&
          _searchController.text.trim().isEmpty) {
        _loadMoreChats();
      }
    });
  }

  Future<void> _refreshChats() async {
    final QuerySnapshot snapshot =
        await _chatService.getInitialChats(_currentUserId);

    final newChats = snapshot.docs.map((doc) {
      return Chat.fromDocument(
          doc.id, doc.data() as Map<String, dynamic>, _currentUserId);
    }).where((chat) {
      final deleted = chat.isDeleted[_currentUserId] ?? false;
      final clearedAt = chat.lastClearedAt[_currentUserId];
      if (deleted && clearedAt != null) {
        return chat.lastUpdated.isAfter(clearedAt);
      }
      return !deleted;
    }).toList();

    setState(() {
      _chats = newChats;
    });
  }

  Future<void> _loadMembership() async {
    final membership = await MembershipService().getCurrentMembership();
    setState(() {
      _membership = membership;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _searchController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  OverlayEntry _buildOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 60),
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _searchResults.isNotEmpty
                  ? ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final data = _searchResults[index].data()
                            as Map<String, dynamic>;
                        final String uid = data['uid'] ?? '';
                        final String displayName =
                            data['displayName'] ?? 'Unknown';
                        if (uid == _currentUserId) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          title: Text(displayName),
                          onTap: () {
                            _removeOverlay();
                            _onChatTap(uid);
                            _searchController.clear();
                          },
                        );
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  void _updateOverlay() {
    final String searchText = _searchController.text.trim();
    if (searchText.isNotEmpty && _searchResults.isNotEmpty) {
      if (_overlayEntry != null) {
        _overlayEntry!.markNeedsBuild();
      } else {
        _overlayEntry = _buildOverlayEntry();
        Overlay.of(context)?.insert(_overlayEntry!);
      }
    } else {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _loadUsers({bool reset = false}) async {
    final String searchTerm = _searchController.text.trim();
    if (searchTerm.isEmpty) {
      setState(() {
        _isLoadingUsers = false;
        _searchResults.clear();
        _hasMoreUsers = true;
        _lastUserDoc = null;
      });
      return;
    }
    if (reset) {
      setState(() {
        _searchResults.clear();
        _lastUserDoc = null;
        _hasMoreUsers = true;
      });
    }
    if (!_hasMoreUsers) return;
    setState(() => _isLoadingUsers = true);

    final List<QueryDocumentSnapshot> newDocs =
        await _userService.searchInitialUsers(searchTerm);
    if (newDocs.isNotEmpty) {
      setState(() {
        final docsToAdd = newDocs.where((doc) =>
            !_searchResults.any((existingDoc) => existingDoc.id == doc.id));
        _searchResults.addAll(docsToAdd);
        _lastUserDoc = newDocs.last;
        if (newDocs.length < 10) {
          _hasMoreUsers = false;
        }
      });
    } else {
      setState(() {
        _hasMoreUsers = false;
      });
    }
    setState(() => _isLoadingUsers = false);
    _updateOverlay();
  }

  Future<void> _loadInitialChats() async {
    if (!mounted) return;
    setState(() => _isLoadingChats = true);
    final QuerySnapshot querySnapshot =
        await _chatService.getInitialChats(_currentUserId);
    if (!mounted) return;
    if (querySnapshot.docs.isNotEmpty) {
      List<Chat> chats = querySnapshot.docs.map((doc) {
        return Chat.fromDocument(
            doc.id, doc.data() as Map<String, dynamic>, _currentUserId);
      }).toList();

      chats = chats.where((chat) {
        bool deleted = chat.isDeleted[_currentUserId] ?? false;
        DateTime? clearedAt = chat.lastClearedAt[_currentUserId];
        if (deleted && clearedAt != null) {
          return chat.lastUpdated.isAfter(clearedAt);
        }
        return !deleted;
      }).toList();

      setState(() {
        _chats = chats;
        _lastChatDoc = querySnapshot.docs.last;
        _hasMoreChats = querySnapshot.docs.length >= 10;
      });
    } else {
      setState(() {
        _chats = [];
        _hasMoreChats = false;
      });
    }
    setState(() => _isLoadingChats = false);
  }

  Future<void> _loadMoreChats() async {
    if (!_hasMoreChats || _lastChatDoc == null) return;
    if (!mounted) return;

    setState(() => _isLoadingMoreChats = true);

    final QuerySnapshot querySnapshot =
        await _chatService.getMoreChats(_lastChatDoc!, _currentUserId);

    if (!mounted) return;

    if (querySnapshot.docs.isNotEmpty) {
      List<Chat> moreChats = querySnapshot.docs.map((doc) {
        return Chat.fromDocument(
            doc.id, doc.data() as Map<String, dynamic>, _currentUserId);
      }).toList();

      moreChats = moreChats.where((chat) {
        final deleted = chat.isDeleted[_currentUserId] ?? false;
        final clearedAt = chat.lastClearedAt[_currentUserId];
        if (deleted && clearedAt != null) {
          return chat.lastUpdated.isAfter(clearedAt);
        }
        return !deleted;
      }).toList();

      setState(() {
        _chats.addAll(moreChats);
        _lastChatDoc = querySnapshot.docs.last;
        _hasMoreChats = querySnapshot.docs.length >= 10;
      });
    } else {
      setState(() => _hasMoreChats = false);
    }

    setState(() => _isLoadingMoreChats = false);
  }

  Future<void> _onChatTap(String otherUserId) async {
    _removeOverlay();
    _searchController.clear();
    FocusScope.of(context).unfocus();

    final Chat? existingChat = _chats.firstWhereOrNull(
      (c) => c.participants.contains(otherUserId),
    );

    String? chatId = existingChat?.id;

    chatId ??= await _chatService.getExistingChat(_currentUserId, otherUserId);

    if (chatId != null) {
      unawaited(_chatService.markChatRead(chatId, _currentUserId));
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: chatId,
          otherUserId: otherUserId,
        ),
      ),
    );

    _refreshChats();
  }

  Widget _buildDeleteDialog(
      BuildContext context, String partnerName, String chatId) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: const Color(0x80000000).withOpacity(0)),
        ),
        AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(localeProvider.translate(section, 'delete_chat_title',
              params: {'user': partnerName})),
          content: Text(localeProvider.translate(section, 'delete_chat_message',
              params: {'user': partnerName})),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localeProvider.translate(section, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localeProvider.translate(section, 'delete')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilteredChatList() {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    if (_isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(localeProvider.translate(section, 'no_chats')),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final data = _searchResults[index].data() as Map<String, dynamic>;
        final String uid = data['uid'] ?? '';
        final String displayName = data['displayName'] ?? 'Unknown';

        if (uid == _currentUserId) return const SizedBox.shrink();

        return ListTile(
          title: Text(displayName),
          onTap: () {
            _removeOverlay();
            _onChatTap(uid);
            _searchController.clear();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: Text(localeProvider.translate(section, 'title')),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: CompositedTransformTarget(
                link: _layerLink,
                child: SearchFilter(
                  section: section,
                  controller: _searchController,
                  onChanged: (_) {},
                  suffixIcon: _isLoadingUsers
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
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
                                _removeOverlay();
                                setState(() {
                                  _isLoadingUsers = false;
                                  _searchResults.clear();
                                });
                              },
                            )
                          : null),
                ),
              ),
            ),
            Expanded(
              child: _searchController.text.trim().isNotEmpty
                  ? _buildFilteredChatList()
                  : _isLoadingChats
                      ? const Center(child: CircularProgressIndicator())
                      : _chats.isEmpty
                          ? Center(
                              child: Text(localeProvider.translate(
                                  section, 'no_chats')),
                            )
                          : ListView.builder(
                              controller: _chatScrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount:
                                  _chats.length + (_isLoadingMoreChats ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _chats.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }

                                final chat = _chats[index];
                                final otherUserId = chat.participants
                                    .firstWhere((p) => p != _currentUserId,
                                        orElse: () => '');

                                return Slidable(
                                  key: ValueKey(chat.id),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        padding: const EdgeInsets.only(
                                            right: 20, left: 0),
                                        onPressed: (context) async {
                                          final userData = await _userService
                                              .getUser(otherUserId);
                                          final partnerName =
                                              userData['displayName'] ?? '';
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            barrierColor: Colors.transparent,
                                            builder: (ctx) =>
                                                _buildDeleteDialog(
                                                    ctx, partnerName, chat.id),
                                          );
                                          if (confirm == true) {
                                            await _chatService
                                                .deleteChatForUser(
                                                    chat.id, _currentUserId);
                                          }
                                        },
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete,
                                        label: localeProvider.translate(
                                            section, 'delete'),
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      leading: chat.hasUnread
                                          ? Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : null,
                                      title: UserDisplayName(
                                        uid: otherUserId,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      subtitle: _membership ==
                                              MembershipType.guest
                                          ? Text(
                                              localeProvider.translate(section,
                                                  'chat_locked_message'),
                                              style: const TextStyle(
                                                  color: Colors.grey),
                                            )
                                          : Text(
                                              chat.lastMessage?.text ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      trailing: Text(
                                        LocalizedDateTimeFormatter
                                            .getChatListFormattedDate(
                                                context, chat.lastUpdated),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      onTap: () {
                                        if (_membership ==
                                            MembershipType.guest) {
                                          AppSnackBar.show(
                                            context,
                                            localeProvider.translate(section,
                                                'upgrade_required_messages'),
                                            type: SnackBarType.warning,
                                          );
                                          return;
                                        }
                                        _onChatTap(otherUserId);
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
