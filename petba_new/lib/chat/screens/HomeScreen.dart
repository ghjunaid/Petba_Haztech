import 'package:flutter/material.dart';
import 'package:petba_new/chat/Model/ChatModel.dart';
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:petba_new/chat/Pages/ChatPage.dart';
import 'package:petba_new/chat/Pages/LoginScreen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petba_new/services/user_data_service.dart';
import 'package:petba_new/chat/notification_service.dart';
import 'package:petba_new/chat/socket_sevice.dart';
import 'dart:convert';

import '../../providers/Config.dart';
import 'Individualpage.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({
    Key? key,
    required this.chatmodels,
    required this.sourchat,
    required this.currentUser,
    required this.allUsers,
  }) : super(key: key);

  final List<ChatModel> chatmodels;
  final ChatModel sourchat;
  final UserModel currentUser;
  final List<UserModel> allUsers;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late SocketService socketService;

  List<ChatModel> allChats = [];
  bool _isLoading = false;

  TextEditingController _searchController = TextEditingController();
  List<ChatModel> _filteredChats = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    socketService = SocketService.getInstance();
    _initializeSocket();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeSocket() {
    print("DEBUG: Starting socket initialization for user: ${widget.currentUser.id}");
    socketService.connectForChatList(
      userId: widget.currentUser.id,
      onChatListUpdate: _onChatListUpdate,
      onNewChat: _onNewChat,
    );

    print("DEBUG: Socket connected, now requesting chat list...");
    socketService.requestChatList(widget.currentUser.id);
    print("DEBUG: Chat list request sent");
    Future.delayed(Duration(seconds: 2), () {
      socketService.requestQueuedNotifications(widget.currentUser.id);
    });
  }

  void _onChatListUpdate(List<dynamic> chatData) {
    print("DEBUG: Received chat data: ${chatData.length} chats");
    print("DEBUG: Current user ID: ${widget.currentUser.id}");

    try {
      setState(() {
        allChats.clear();

        for (var chat in chatData) {
          try {
            int currentUserId = widget.currentUser.id;
            int senderId = int.tryParse(chat['senderId'].toString()) ?? 0;
            int receiverId = int.tryParse(chat['receiverId'].toString()) ?? 0;
            int ownerId = int.tryParse(chat['ownerId'].toString()) ?? 0;
            int interestedUserId = int.tryParse(chat['interestedUserId'].toString()) ?? 0;

            // FIXED: Check if current user is in participants array
            List<dynamic> participants = chat['participants'] ?? [];
            bool isParticipant = participants.any((p) =>
            int.tryParse(p.toString()) == currentUserId
            );

            // Alternative check: user is either owner or interested user
            bool isOwnerOrInterested = (currentUserId == ownerId) || (currentUserId == interestedUserId);

            bool shouldShowChat = isParticipant || isOwnerOrInterested;

            print("DEBUG: Chat ${chat['adoptionId']} - shouldShowChat: $shouldShowChat");
            print("DEBUG: - isParticipant: $isParticipant");
            print("DEBUG: - isOwnerOrInterested: $isOwnerOrInterested");
            print("DEBUG: - participants: $participants");

            if (shouldShowChat) {
              String displayName;
              String messageType;
              bool isMyPetChat;

              if (currentUserId == ownerId) {
                // Current user is pet owner - show interested user's name
                displayName =
                    chat['interestedUserName']?.toString() ?? 'Interested User';
                messageType = 'Adoption Request';
                isMyPetChat = true;

                bool isReceivedMessage = senderId != currentUserId;

                // Create ChatModel
                ChatModel chatModel = ChatModel(
                  name: displayName,
                  icon: "pet.svg",
                  isGroup: false,
                  time: _formatTime(chat['lastMessageTime']),
                  currentMessage: chat['lastMessage']?.toString() ?? '',
                  id: int.tryParse(chat['adoptionId'].toString()) ?? 0,
                  status: chat['status'] == 1 ? "Active" : "Inactive",
                  ownerId: ownerId,
                  ownerName: chat['ownerName']?.toString() ?? 'Unknown',
                  isPetChat: true,
                  isMyPetChat: isMyPetChat,
                  adoptionId: chat['adoptionId'].toString(),
                  conversationId: _safeInt(chat['conversationId']),
                  petImageUrl: chat['petImageUrl']?.toString(),
                  petName: chat['petName']?.toString(),
                  petType: chat['petType']?.toString() ?? "Pet",
                  petBreed: chat['petBreed']?.toString() ?? "Unknown",
                  interestedUserName: chat['interestedUserName']?.toString(),
                  interestedUserId: interestedUserId,
                  senderId: senderId,
                  receiverId: receiverId,
                  chatId: _safeInt(chat['chatId']),
                  messageType: messageType,
                  isReceivedMessage: isReceivedMessage,
                );

                allChats.add(chatModel);

                print("DEBUG: Added chat: $displayName about ${chatModel
                    .petName}");
              }
            }else {
              print("DEBUG: Filtered out chat ${chat['adoptionId']} - user not participant");
            }
          } catch (e) {
            print("ERROR: Failed to create ChatModel for chat: $e");
          }
        }

        // Sort chats by time (most recent first)
        allChats.sort((a, b) {
          try {
            DateTime timeA = DateTime.parse(a.time);
            DateTime timeB = DateTime.parse(b.time);
            return timeB.compareTo(timeA);
          } catch (e) {
            return 0;
          }
        });

        _filteredChats = List.from(allChats);
        print("DEBUG: Total chats displayed: ${allChats.length}");
      });
    } catch (e) {
      print("ERROR: Exception in _onChatListUpdate: $e");
    }
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  void _onNewChat(Map<String, dynamic> chatData) {
    // Handle new chat creation - only show if it's from an interested user to current pet owner
    int currentUserId = widget.currentUser.id;
    int senderId = int.tryParse(chatData['senderId'].toString()) ?? 0;
    int receiverId = int.tryParse(chatData['receiverId'].toString()) ?? 0;
    int ownerId = int.tryParse(chatData['ownerId'].toString()) ?? 0;
    int interestedUserId = int.tryParse(chatData['interestedUserId'].toString()) ?? 0;

    // Only show if current user is pet owner AND message is from someone else
    // bool shouldShowChat = (currentUserId == ownerId) && (senderId != currentUserId);
    // bool shouldShowChat = (currentUserId == ownerId) &&
    //     (senderId != currentUserId) &&
    //     (receiverId == currentUserId);

    bool shouldShowChat = false;

    if (currentUserId == ownerId) {
      // User is pet owner - show chats from interested users
      shouldShowChat = (senderId != currentUserId) && (receiverId == currentUserId);
    } else if (currentUserId == interestedUserId) {
      // User is interested user - show their own adoption chats
      shouldShowChat = true;
    }

    if (shouldShowChat) {
      String displayName = chatData['interestedUserName']?.toString() ?? 'Unknown User';
      String messageType = 'Adoption Request';
      bool isReceivedMessage = true;

      ChatModel newChat = ChatModel(
        name: displayName,
        icon: "pet.svg",
        isGroup: false,
        time: _formatTime(chatData['timestamp']),
        currentMessage: chatData['initialMessage'] ?? 'Chat started',
        id: int.tryParse(chatData['adoptionId'].toString()) ?? 0,
        status: "Active",
        ownerId: ownerId,
        ownerName: chatData['ownerName'] ?? 'Unknown',
        isPetChat: true,
        isMyPetChat: true,
        adoptionId: chatData['adoptionId'].toString(),
        conversationId: int.tryParse(chatData['conversationId'].toString()) ?? 0,
        petImageUrl: chatData['petImageUrl'],
        petName: chatData['petName'],
        petType: chatData['petType'] ?? "Pet",
        petBreed: chatData['petBreed'] ?? "Unknown",
        interestedUserName: chatData['interestedUserName'],
        interestedUserId: int.tryParse(chatData['interestedUserId'].toString()) ?? 0,
        senderId: senderId,
        receiverId: int.tryParse(chatData['receiverId'].toString()) ?? 0,
        chatId: chatData['chatId'],
        messageType: messageType,
        isReceivedMessage: isReceivedMessage,
      );

      setState(() {
        allChats.insert(0, newChat);
        _filteredChats = List.from(allChats);
      });
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filterChats(_searchController.text);
    });
  }

  void _filterChats(String query) {
    if (query.isEmpty) {
      _filteredChats = allChats;
    } else {
      _filteredChats = allChats.where((chat) =>
      chat.petName!.toLowerCase().contains(query.toLowerCase()) ||
          chat.name.toLowerCase().contains(query.toLowerCase()) ||
          chat.currentMessage.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterChats('');
      }
    });
  }

  Future<void> _refreshAllChats() async {
    setState(() {
      _isLoading = true;
    });
    socketService.requestChatList(widget.currentUser.id);
    // Add a small delay to show loading state
    await Future.delayed(Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "00:00";
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "00:00";
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    socketService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Handle app minimized
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade400,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search chats...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pet Adoption Chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Logged in as ${widget.currentUser.name}',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _toggleSearch,
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? 'Close Search' : 'Search',
          ),
          if (!_isSearching) ...[
            IconButton(
              onPressed: _refreshAllChats,
              icon: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(Icons.refresh),
              tooltip: 'Refresh Chats',
            ),
            PopupMenuButton<String>(
              itemBuilder: (BuildContext context) {
                return [
                  PopupMenuItem(child: Text("Refresh Chats"), value: "Refresh"),
                  PopupMenuItem(child: Text("Settings"), value: "Settings"),
                  PopupMenuItem(child: Text("Logout"), value: "Logout"),
                ];
              },
              onSelected: (value) {
                _handleMenuSelection(value);
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_isSearching && _searchController.text.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Text(
                'Search results: ${_filteredChats.length} chats found',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.chat, color: Colors.green.shade600),
                SizedBox(width: 8),
                Text(
                  'All Conversations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                Spacer(),
                Text(
                  '${_filteredChats.length} chats',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshAllChats,
              child: _filteredChats.isEmpty
                  ? _buildEmptyState(
                  _searchController.text.isNotEmpty
                      ? "No matching chats found"
                      : "No conversations yet",
                  _searchController.text.isNotEmpty
                      ? "Try adjusting your search terms"
                      : "Start chatting about pet adoption!")
                  : _buildChatsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList() {
    return ListView.builder(
      itemCount: _filteredChats.length,
      itemBuilder: (context, index) => _buildChatCard(_filteredChats[index]),
    );
  }

  Widget _buildChatCard(ChatModel chatModel) {
    // Determine the color scheme based on chat type
    Color primaryColor = chatModel.isMyPetChat ? Colors.blue : Colors.green;
    Color lightColor = chatModel.isMyPetChat ? Colors.blue.shade100 : Colors.green.shade100;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Individualpage(
                chatModel: chatModel,
                sourchat: widget.sourchat,
                currentUser: widget.currentUser,
                conversationId: chatModel.conversationId ?? 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lightColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: chatModel.petImageUrl != null
                          ? Image.network(
                        chatModel.petImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets,
                            size: 30,
                            color: Colors.green,
                          );
                        },
                      )
                          : Icon(
                        Icons.pets,
                        size: 30,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: chatModel.status == "Active" ? Colors.green.shade400 : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        chatModel.isReceivedMessage ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatModel.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: lightColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chatModel.messageType ?? (chatModel.isMyPetChat ? 'Request' : 'Adoption'),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      'About: ${chatModel.petName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600]!,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        if (chatModel.isReceivedMessage)
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: Colors.green.shade600,
                          ),
                        Expanded(
                          child: Text(
                            chatModel.currentMessage.length > 35
                                ? '${chatModel.currentMessage.substring(0, 35)}...'
                                : chatModel.currentMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: chatModel.isReceivedMessage ? Colors.black87 : Colors.grey[600],
                              fontWeight: chatModel.isReceivedMessage ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    chatModel.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 4),
                  if (chatModel.isReceivedMessage)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case "Refresh":
        _refreshAllChats();
        break;
      case "Settings":
      // Handle settings
        break;
      case "Logout":
        _logout();
        break;
    }
  }

  void _logout() async {
    final userData = await UserDataService.getUserData();
    final cityId = await UserDataService.getCityId();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Loginscreen(
          userId: userData?['customer_id'],
          userToken: userData?['token'],
          userEmail: userData?['email'],
          firstName: userData?['firstname'],
          lastName: userData?['lastname'],
          telephone: userData?['telephone'],
          cityId: cityId,
        ),
      ),
    );
  }
}