import 'package:flutter/material.dart';
import 'package:petba_new/chat/CustomUI/CustomCard.dart';
import 'package:petba_new/chat/Model/ChatModel.dart';
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:petba_new/chat/notification_service.dart';

import '../screens/Individualpage.dart';

class Chatpage extends StatefulWidget {
  const Chatpage({
    Key? key,
    required this.chatmodels,
    required this.sourchat,
    required this.currentUser,
  }) : super(key: key);

  final List<ChatModel> chatmodels;
  final ChatModel sourchat;
  final UserModel currentUser;

  @override
  State<Chatpage> createState() => _ChatpageState();
}

class _ChatpageState extends State<Chatpage> with WidgetsBindingObserver {
  bool isAppInForeground = true;
  StreamSubscription? _messageSubscription;
  OverlayEntry? _currentNotificationOverlay;
  late AudioPlayer audioPlayer;
  Timer? _notificationTimer;
  String _searchQuery = '';
  List<ChatModel> _filteredChats = [];

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);
    _filteredChats = widget.chatmodels;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageSubscription?.cancel();
    _notificationTimer?.cancel();
    _removeNotificationOverlay();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    try {
      await audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print("Custom sound not found, using system sound");
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (e2) {
        print("Could not play notification sound: $e2");
      }
    }
  }

  void _filterChats(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredChats = widget.chatmodels;
      } else {
        _filteredChats = widget.chatmodels.where((chat) {
          return chat.name.toLowerCase().contains(query.toLowerCase()) ||
              (chat.petBreed?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (chat.petType?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              chat.ownerName.toLowerCase().contains(query.toLowerCase()) ||
              (chat.interestedUserName?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Widget _buildPetCard(ChatModel chatModel) {
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
              // Pet Avatar with network image support
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green.shade100,
                    child: chatModel.petImageUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: chatModel.petImageUrl!.startsWith('http')
                          ? Image.network(
                        chatModel.petImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets,
                            size: 30,
                            color: Colors.green.shade700,
                          );
                        },
                      )
                          : Image.asset(
                        chatModel.petImageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.pets,
                            size: 30,
                            color: Colors.green.shade700,
                          );
                        },
                      ),
                    )
                        : Icon(
                      Icons.pets,
                      size: 30,
                      color: Colors.green.shade700,
                    ),
                  ),
                  // Status indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: chatModel.status == "Active" ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),

              // Pet Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet name and type
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
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chatModel.petType ?? 'Pet',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),

                    // Owner and interested user info
                    Row(
                      children: [
                        if (chatModel.interestedUserName != null) ...[
                          Icon(Icons.person, size: 12, color: Colors.grey[600]),
                          SizedBox(width: 2),
                          Text(
                            '${chatModel.interestedUserName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' → ${chatModel.ownerName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ] else ...[
                          Icon(Icons.home, size: 12, color: Colors.grey[600]),
                          SizedBox(width: 2),
                          Text(
                            'Owner: ${chatModel.ownerName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),

                    // Last message
                    Text(
                      chatModel.currentMessage.length > 40
                          ? '${chatModel.currentMessage.substring(0, 40)}...'
                          : chatModel.currentMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Show adoption ID if available
                    if (chatModel.adoptionId != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'ID: ${chatModel.adoptionId}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Time and status
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: chatModel.status == "Active"
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          chatModel.status == "Active"
                              ? Icons.chat
                              : Icons.chat_outlined,
                          size: 10,
                          color: chatModel.status == "Active"
                              ? Colors.green.shade600
                              : Colors.grey.shade600,
                        ),
                        SizedBox(width: 2),
                        Text(
                          chatModel.status == "Active" ? 'Active' : 'Chat',
                          style: TextStyle(
                            fontSize: 9,
                            color: chatModel.status == "Active"
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  // Unread message count (if available)
                  if (chatModel.status == "Active")
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
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

  OverlayEntry _createNotificationOverlay(Map<String, dynamic> messageData) {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          elevation: 10,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.pets,
                    color: Colors.green.shade700,
                    size: 25,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        messageData['petName'] ?? 'Pet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        (messageData['message'] ?? '').length > 50
                            ? '${messageData['message'].substring(0, 50)}...'
                            : messageData['message'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'from ${messageData['ownerName'] ?? 'Owner'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _removeNotificationOverlay,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeNotificationOverlay() {
    _notificationTimer?.cancel();
    if (_currentNotificationOverlay != null) {
      _currentNotificationOverlay!.remove();
      _currentNotificationOverlay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // Search bar
          Container(
            padding: EdgeInsets.all(16),
            child: TextField(
              onChanged: _filterChats,
              decoration: InputDecoration(
                hintText: 'Search chats by pet name, owner, or user...',
                prefixIcon: Icon(Icons.search, color: Colors.green.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _filterChats(''),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          // Results summary
          if (_searchQuery.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Found ${_filteredChats.length} chat${_filteredChats.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => _filterChats(''),
                    child: Text(
                      'Clear',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Chat list
          Expanded(
            child: _filteredChats.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchQuery.isEmpty ? Icons.pets : Icons.search_off,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'No chats available' : 'No chats found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      'Try searching for different terms',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 8),
                    Text(
                      'Start chatting with pet owners!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredChats.length,
              itemBuilder: (context, index) => _buildPetCard(_filteredChats[index]),
            ),
          ),
        ],
      ),
    );
  }
}