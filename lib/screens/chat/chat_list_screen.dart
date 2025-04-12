import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elitara/widgets/search_filter.dart';
import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _searchController.addListener(() {
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
    _chatScrollController.addListener(() {
      if (_chatScrollController.position.pixels >=
              _chatScrollController.position.maxScrollExtent - 100 &&
          !_isLoadingMoreChats &&
          _hasMoreChats &&
          _searchController.text.trim().isEmpty) {
        _loadMoreChats();
      }
    });
    _loadInitialChats();
  }

  @override
  void dispose() {
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
                            _onUserTap(uid);
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
    final QuerySnapshot querySnapshot = await _userService.searchUsers(
      searchTerm,
      lastDoc: _lastUserDoc,
      limit: 10,
    );
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _searchResults.addAll(querySnapshot.docs);
        _lastUserDoc = querySnapshot.docs.last;
        if (querySnapshot.docs.length < 10) {
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
    setState(() => _isLoadingChats = true);
    final QuerySnapshot querySnapshot =
        await _chatService.getInitialChats(_currentUserId);
    if (querySnapshot.docs.isNotEmpty) {
      List<Chat> chats = querySnapshot.docs.map((doc) {
        return Chat.fromDocument(doc.id, doc.data() as Map<String, dynamic>);
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
    setState(() => _isLoadingMoreChats = true);
    final QuerySnapshot querySnapshot =
        await _chatService.getMoreChats(_lastChatDoc!, _currentUserId);
    if (querySnapshot.docs.isNotEmpty) {
      List<Chat> moreChats = querySnapshot.docs.map((doc) {
        return Chat.fromDocument(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
      setState(() {
        _chats.addAll(moreChats);
        _lastChatDoc = querySnapshot.docs.last;
        if (querySnapshot.docs.length < 10) {
          _hasMoreChats = false;
        }
      });
    } else {
      setState(() => _hasMoreChats = false);
    }
    setState(() => _isLoadingMoreChats = false);
  }

  void _onUserTap(String otherUserId) async {
    final String? existingChatId =
        await _chatService.getExistingChat(_currentUserId, otherUserId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chatId: existingChatId,
          otherUserId: otherUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(localeProvider.translate(section, 'title')),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: SearchFilter(
                    section: section,
                    controller: _searchController,
                    onChanged: (_) {
                      final searchText = _searchController.text.trim();
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
                    },
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
                child: _isLoadingChats && _searchController.text.trim().isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _chats.isEmpty
                        ? Center(
                            child: Text(
                                localeProvider.translate(section, 'no_chats')))
                        : ListView.builder(
                            controller: _chatScrollController,
                            itemCount: _chats.length +
                                ((_isLoadingMoreChats && _hasMoreChats)
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index == _chats.length &&
                                  (_isLoadingMoreChats && _hasMoreChats)) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              final chat = _chats[index];
                              final otherUserId = chat.participants.firstWhere(
                                (participant) => participant != _currentUserId,
                                orElse: () => '',
                              );
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: UserDisplayName(
                                    uid: otherUserId,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  subtitle: Text(
                                    chat.lastMessage != null
                                        ? chat.lastMessage!.text
                                        : '',
                                  ),
                                  trailing: Text(
                                    "${chat.lastUpdated.hour.toString().padLeft(2, '0')}:${chat.lastUpdated.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatDetailScreen(
                                          chatId: chat.id,
                                          otherUserId: otherUserId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
