import 'package:flutter/material.dart';
import 'package:petba_new/chat/CustomUI/OwnChatMessage.dart';
import 'package:petba_new/chat/CustomUI/ReplyMessage.dart';
import 'package:petba_new/chat/Model/ChatModel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:petba_new/chat/notification_service.dart';
import 'package:petba_new/chat/socket_sevice.dart';
import 'package:petba_new/chat/screens/CameraScreen.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:petba_new/providers/Config.dart';

class Individualpage extends StatefulWidget {
  final ChatModel chatModel;
  final ChatModel sourchat;
  final UserModel currentUser;
  final int? conversationId;

  const Individualpage({
    Key? key,
    required this.chatModel,
    required this.sourchat,
    required this.currentUser,
    this.conversationId,
  }) : super(key: key);

  @override
  State<Individualpage> createState() => _IndividualpageState();
}

class _IndividualpageState extends State<Individualpage>
    with WidgetsBindingObserver {
  late SocketService socketService;
  final ImagePicker _picker = ImagePicker();
  bool show = false;
  FocusNode focusNode = FocusNode();
  bool sendbutton = false;
  List<MessageModel> messages = [];
  ScrollController _scrollController = ScrollController();
  late AudioPlayer audioPlayer;
  bool isAppInForeground = true;
  bool isCurrentChatActive = true;
  bool isTyping = false;

  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addObserver(this);
    socketService = SocketService.getInstance();

    // Load chat history first
    _loadChatHistory();

    _initializeSocket();

    Future.delayed(Duration(seconds: 2), () {
      socketService.requestPendingMessages(widget.currentUser.id);
    });

    FirebaseNotificationService.setCurrentChat(widget.chatModel.adoptionId ?? widget.chatModel.id.toString());

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() {
          show = false;
        });
      }
    });

    _controller.addListener(_onTextChanged);
  }

  // Load chat history using adoptionId
  Future<void> _loadChatHistory() async {
    try {
      print("DEBUG: Current User ID: ${widget.currentUser.id}");
      print("DEBUG: ChatModel senderId: ${widget.chatModel.senderId}");
      print("DEBUG: ChatModel receiverId: ${widget.chatModel.receiverId}");
      print("DEBUG: ChatModel ownerId: ${widget.chatModel.ownerId}");
      print("DEBUG: ChatModel interestedUserId: ${widget.chatModel.interestedUserId}");
      print("DEBUG: ChatModel adoptionId: ${widget.chatModel.adoptionId}");

      int currentUserId = widget.currentUser.id;
      int otherUserId;

      if (widget.chatModel.senderId == currentUserId) {
        otherUserId = widget.chatModel.receiverId ?? widget.chatModel.ownerId ?? 0;
      } else {
        otherUserId = widget.chatModel.senderId ?? widget.chatModel.interestedUserId ?? 0;
      }

      String chatHistoryUrl;
      if (widget.chatModel.adoptionId != null) {
        chatHistoryUrl = '$baseUrl/chat-history/$currentUserId/$otherUserId?adoptionId=${widget.chatModel.adoptionId}';
      } else {
        chatHistoryUrl = '$baseUrl/chat-history/$currentUserId/$otherUserId';
      }

      print("DEBUG: Chat history URL: $chatHistoryUrl");

      final response = await http.get(Uri.parse(chatHistoryUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("DEBUG: Chat history response: $data");
        if (data['success']) {
          List<MessageModel> history = [];

          for (var messageData in data['messages']) {
            // FIX: Proper comparison - convert both to same type
            int messageSenderId = int.tryParse(messageData['senderId'].toString()) ?? 0;
            int currentUserId = widget.currentUser.id;


            String messageType;
            if (messageSenderId == currentUserId) {
              messageType = 'source'; // my own message
            } else {
              messageType = 'destination'; // received message
            }


            print("DEBUG: Message from $messageSenderId, current user: $currentUserId, type: $messageType");

            history.add(MessageModel(
              message: messageData['message'] ?? '',
              type: messageType,
              time: _formatTimestamp(messageData['timestamp']),
              messageType: messageData['messageType'] ?? 'text',
              senderId: messageData['senderId']?.toString(),
              receiverId: messageData['receiverId']?.toString(),
              base64Image: messageData['base64Image'],
              fileName: messageData['fileName'],
              messageId: messageData['messageId']?.toString(),
              chatId: messageData['chatId']?.toString(),
              delivered: messageData['delivered'],
              read: messageData['read'],
            ));
          }

          setState(() {
            messages = history;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          // Mark messages as read
          String chatId = _generateChatId(
            widget.currentUser.id.toString(),
            (widget.chatModel.ownerId ?? widget.chatModel.id).toString(),
            widget.chatModel.adoptionId?.toString(),
          );

          await _markMessagesAsRead(chatId, widget.currentUser.id.toString());
        }
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _markMessagesAsRead(String chatId, String userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/mark-read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chatId': chatId,
          'userId': userId,
        }),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      String hour = dateTime.hour.toString().padLeft(2, '0');
      String minute = dateTime.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    } catch (e) {
      return "00:00";
    }
  }

  String _generateChatId(String userId1, String userId2, String? adoptionId) {
    if (adoptionId != null && adoptionId.isNotEmpty) {
      List<String> sortedIds = [userId1, userId2]..sort();  // ADD SORTING
      return 'adoption_${sortedIds[0]}_${sortedIds[1]}_$adoptionId';
    }
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  String generateChatId(String userId1, String userId2, String petId) {
    return 'adoption_${userId1}_${userId2}_$petId';
  }

  @override
  void dispose() {
    isCurrentChatActive = false;
    WidgetsBinding.instance.removeObserver(this);
    focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    audioPlayer.dispose();

    // Clear current chat in Firebase service
    FirebaseNotificationService.setCurrentChat(null);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      isAppInForeground = state == AppLifecycleState.resumed;
    });

    FirebaseNotificationService.setAppState(isAppInForeground);

    if (isAppInForeground) {
      FirebaseNotificationService.setCurrentChat(widget.chatModel.adoptionId ?? widget.chatModel.id.toString());
    } else {
      FirebaseNotificationService.setCurrentChat(null);
    }
  }

  void _initializeSocket() {
    socketService.connect(
      sourceChat: widget.sourchat,
      targetChat: widget.chatModel,
      messageCallback: _onMessageReceived,
      scrollCallback: _scrollToBottom,
    );

    socketService.setCurrentChatId(widget.chatModel.adoptionId ?? widget.chatModel.id.toString());
  }

  // In SocketService.dart, update the message handling in _onMessageReceived:
// CURRENT CODE - Remove the filter that was blocking own messages
  void _onMessageReceived(
      String type,
      String message,
      String time, {
        bool playSound = false,
        String? senderId,
        String? messageType,
        String? receiverId,
        String? base64Image,
        String? fileName,
        String? messageId,
        String? chatId,
        String? adoptionId,
        bool? delivered,
        bool? read,
      }) {
    if (!mounted) return;

    print("DEBUG: Received message - senderId: $senderId, receiverId: $receiverId, message: $message");
    print("DEBUG: Current user ID: ${widget.currentUser.id}");
    print("DEBUG: Chat model adoption ID: ${widget.chatModel.adoptionId}");

    // Validate that this message belongs to the current chat
    String currentAdoptionId = widget.chatModel.adoptionId ?? widget.chatModel.id.toString();
    if (adoptionId != null && adoptionId != currentAdoptionId) {
      print("DEBUG: Message not for this chat - ignoring");
      return;
    }

    // Determine message type for UI display
    String messageTypeForUI;
    int currentUserId = widget.currentUser.id;
    int messageSenderId = int.tryParse(senderId ?? '0') ?? 0;
    int messageReceiverId = int.tryParse(receiverId ?? '0') ?? 0;

    // Check if current user is involved in this message
    bool isCurrentUserInvolved = (messageSenderId == currentUserId) || (messageReceiverId == currentUserId);

    if (!isCurrentUserInvolved) {
      print("DEBUG: Message not involving current user - ignoring");
      return;
    }

    // Determine if it's sent by current user or received
    messageTypeForUI = messageSenderId == currentUserId ? "source" : "destination";

    print("DEBUG: Message type for UI: $messageTypeForUI");

    setState(() {
      messages.add(MessageModel(
        message: message,
        type: messageTypeForUI,
        time: time,
        messageType: messageType ?? "text",
        senderId: senderId?.toString(),
        receiverId: receiverId?.toString(),
        base64Image: base64Image,
        fileName: fileName,
        messageId: messageId?.toString(),
        chatId: chatId?.toString(),
        delivered: delivered,
        read: read,
      ));
    });

    // Only play sound for messages from others
    if (playSound && isCurrentChatActive && messageSenderId != currentUserId) {
      _playNotificationSound();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Mark message as read if it's received
    if (messageSenderId != currentUserId && chatId != null) {
      _markMessageAsRead(chatId, messageId ?? '');
    }
  }

  Future<void> _markMessageAsRead(String chatId, String messageId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/mark-message-read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'chatId': chatId,
          'messageId': messageId,
          'userId': widget.currentUser.id.toString(),
        }),
      );
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }



  void _onTextChanged() {
    bool hasText = _controller.text.trim().isNotEmpty;

    if (hasText != sendbutton) {
      setState(() {
        sendbutton = hasText;
      });
    }

    // Send typing indicator
    if (hasText && !isTyping) {
      isTyping = true;
      socketService.sendTypingIndicator(
        sourceId: widget.currentUser.id,
        targetId: widget.chatModel.ownerId ?? widget.chatModel.id,
        isTyping: true,
      );
    } else if (!hasText && isTyping) {
      isTyping = false;
      socketService.sendTypingIndicator(
        sourceId: widget.currentUser.id,
        targetId: widget.chatModel.ownerId ?? widget.chatModel.id,
        isTyping: false,
      );
    }
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    // FIXED: Determine correct target user ID
    int currentUserId = widget.currentUser.id;
    int targetUserId;

    // Logic to determine who to send message to
    if (widget.chatModel.isPetChat == true && widget.chatModel.isMyPetChat == true) {
      // If this is my pet chat, send to the interested user
      targetUserId = widget.chatModel.interestedUserId ?? 0;
    } else if (widget.chatModel.isPetChat == true && widget.chatModel.isMyPetChat != true) {
      // If this is someone else's pet chat, send to the owner
      targetUserId = widget.chatModel.ownerId ?? 0;
    } else {
      // Regular chat logic
      targetUserId = widget.chatModel.senderId == currentUserId
          ? (widget.chatModel.receiverId ?? 0)
          : (widget.chatModel.senderId ?? 0);
    }

    // Validation - ensure we're not sending to ourselves
    if (targetUserId == currentUserId || targetUserId == 0) {
      print("ERROR: Invalid target user ID. Current: $currentUserId, Target: $targetUserId");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot send message - invalid recipient')),
      );
      return;
    }

    print("DEBUG: Sending message: $message");
    print("DEBUG: Current user ID: $currentUserId");
    print("DEBUG: Target user ID: $targetUserId");
    print("DEBUG: Adoption ID: ${widget.chatModel.adoptionId}");
    print("DEBUG: Is my pet chat: ${widget.chatModel.isMyPetChat}");
    print("DEBUG: Interested user ID: ${widget.chatModel.interestedUserId}");
    print("DEBUG: Owner ID: ${widget.chatModel.ownerId}");

    // Stop typing indicator
    if (isTyping) {
      isTyping = false;
      socketService.sendTypingIndicator(
        sourceId: currentUserId,
        targetId: targetUserId,
        isTyping: false,
      );
    }

    // Generate consistent chat ID
    String chatId = ChatIdHelper.generateChatId(
      currentUserId.toString(),
      targetUserId.toString(),
      adoptionId: widget.chatModel.adoptionId,
    );

    // Get current timestamp
    String currentTime = _formatCurrentTime();
    String timestamp = DateTime.now().toIso8601String();

    // Create message model for local display
    MessageModel newMessage = MessageModel(
      message: message,
      type: "source",
      time: currentTime,
      messageType: "text",
      senderId: currentUserId.toString(),
      receiverId: targetUserId.toString(),
      adoptionId: widget.chatModel.adoptionId,
      chatId: chatId,
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      delivered: false,
      read: false,
    );

    // Add message locally first
    setState(() {
      messages.add(newMessage);
      sendbutton = false;
    });

    // Clear input and scroll
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Send via socket
    socketService.sendMessage(
      message: message,
      sourceId: currentUserId,
      targetId: targetUserId,
      senderName: widget.currentUser.name,
      receiverName: widget.chatModel.name,
      adoptionId: widget.chatModel.adoptionId ?? widget.chatModel.id.toString(),
      petName: widget.chatModel.petName,
    );

    // Try to store in database (with correct endpoint)
    _sendMessageToDatabase(
      message: message,
      chatId: chatId,
      senderId: currentUserId.toString(),
      receiverId: targetUserId.toString(),
      adoptionId: widget.chatModel.adoptionId,
      timestamp: timestamp,
      messageId: newMessage.messageId,
    );
  }

  Future<void> _sendMessageToDatabase({
    required String message,
    required String chatId,
    required String senderId,
    required String receiverId,
    String? adoptionId,
    required String timestamp,
    String? messageId,
  }) async {
    try {
      // First, check what endpoints are available
      List<String> possibleEndpoints = [
        '$baseUrl/api/send-message',
        '$baseUrl/messages/send',
        '$baseUrl/chat/send-message',
        '$baseUrl/message',
        '$baseUrl/send-chat-message',
      ];

      // Try each endpoint until one works
      for (String endpoint in possibleEndpoints) {
        try {
          print("DEBUG: Trying endpoint: $endpoint");

          final response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'message': message,
              'chatId': chatId,
              'senderId': senderId,
              'receiverId': receiverId,
              'adoptionId': adoptionId,
              'timestamp': timestamp,
              'messageId': messageId,
              'messageType': 'text',
              'petName': widget.chatModel.petName,
              'senderName': widget.currentUser.name,
              'receiverName': _getReceiverName(),
            }),
          );

          print("DEBUG: Response status: ${response.statusCode}");
          print("DEBUG: Response body: ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = json.decode(response.body);
            print("SUCCESS: Message stored via endpoint: $endpoint");

            // Update message status
            if (data['success'] == true || response.statusCode == 201) {
              _updateMessageDeliveryStatus(messageId, true);
              return; // Success - exit the loop
            }
          }
        } catch (e) {
          print("ERROR: Endpoint $endpoint failed: $e");
          continue; // Try next endpoint
        }
      }

      // If all endpoints fail, try socket-only storage
      print("WARNING: All database endpoints failed, using socket-only storage");
      _sendViaSocketOnly(message, senderId, receiverId, adoptionId, timestamp, messageId);

    } catch (e) {
      print("CRITICAL ERROR: All storage methods failed: $e");
      _showStorageErrorDialog();
    }
  }

  String _getReceiverName() {
    if (widget.chatModel.isPetChat == true && widget.chatModel.isMyPetChat == true) {
      return widget.chatModel.interestedUserName ?? 'Interested User';
    } else if (widget.chatModel.isPetChat == true && widget.chatModel.isMyPetChat != true) {
      return widget.chatModel.ownerName ?? 'Pet Owner';
    } else {
      return widget.chatModel.name;
    }
  }

  void _sendViaSocketOnly(String message, String senderId, String receiverId, String? adoptionId, String timestamp, String? messageId) {
    print("INFO: Using socket-only storage as fallback");
    // The socket service should handle database storage on the server side
    // This is a fallback when direct HTTP calls fail
  }

  void _updateMessageDeliveryStatus(String? messageId, bool delivered) {
    if (messageId == null) return;

    setState(() {
      int messageIndex = messages.indexWhere((msg) => msg.messageId == messageId);
      if (messageIndex != -1) {
        messages[messageIndex] = MessageModel(
          message: messages[messageIndex].message,
          type: messages[messageIndex].type,
          time: messages[messageIndex].time,
          messageType: messages[messageIndex].messageType,
          senderId: messages[messageIndex].senderId,
          receiverId: messages[messageIndex].receiverId,
          adoptionId: messages[messageIndex].adoptionId,
          chatId: messages[messageIndex].chatId,
          messageId: messages[messageIndex].messageId,
          base64Image: messages[messageIndex].base64Image,
          fileName: messages[messageIndex].fileName,
          delivered: delivered,
          read: messages[messageIndex].read,
        );
      }
    });
  }

  void _showStorageErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Message Storage Warning'),
        content: Text('Your message was sent but may not be saved. Please check your internet connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatCurrentTime() {
    DateTime now = DateTime.now();
    String hour = now.hour.toString().padLeft(2, '0');
    String minute = now.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
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

  void _handleImageSendFromCamera(String imagePath, String base64Image, String fileName) {
    // Add image message locally first
    setState(() {
      messages.add(MessageModel(
        message: imagePath,
        type: "source",
        time: _formatCurrentTime(),
        messageType: "image",
        senderId: widget.currentUser.id.toString(),
        receiverId: (widget.chatModel.ownerId ?? widget.chatModel.id).toString(),
        base64Image: base64Image,
        fileName: fileName,
        adoptionId: widget.chatModel.adoptionId,
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Send to socket with base64 data
    socketService.sendImageMessage(
      imagePath: imagePath,
      base64Image: base64Image,
      fileName: fileName,
      sourceId: widget.currentUser.id,
      targetId: widget.chatModel.ownerId ?? widget.chatModel.id,
      senderName: widget.currentUser.name,
      adoptionId: widget.chatModel.adoptionId ?? widget.chatModel.id.toString(),
      petName: widget.chatModel.petName,
    );
  }

  void _handleVideoSendFromCamera(String videoPath, String base64Video, String fileName) {
    // Add video message locally first
    setState(() {
      messages.add(MessageModel(
        message: videoPath,
        type: "source",
        time: _formatCurrentTime(),
        messageType: "video",
        senderId: widget.currentUser.id.toString(),
        receiverId: (widget.chatModel.ownerId ?? widget.chatModel.id).toString(),
        base64Image: base64Video,
        fileName: fileName,
        adoptionId: widget.chatModel.adoptionId,
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Send to socket with base64 data
    socketService.sendVideoMessage(
      videoPath: videoPath,
      base64Video: base64Video,
      fileName: fileName,
      sourceId: widget.currentUser.id,
      targetId: widget.chatModel.ownerId ?? widget.chatModel.id,
      senderName: widget.currentUser.name,
      adoptionId: widget.chatModel.adoptionId ?? widget.chatModel.id.toString(),
      petName: widget.chatModel.petName,
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _sendImageMessage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _captureImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _sendImageMessage(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  Future<void> _sendImageMessage(XFile imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final fileName = path.basename(imageFile.path);

      // Add image message locally first
      setState(() {
        messages.add(MessageModel(
          message: imageFile.path,
          type: "source",
          time: _formatCurrentTime(),
          messageType: "image",
          senderId: widget.currentUser.id.toString(),
          receiverId: (widget.chatModel.ownerId ?? widget.chatModel.id).toString(),
          base64Image: base64Image,
          fileName: fileName,
          adoptionId: widget.chatModel.adoptionId,
        ));
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Send to socket with base64 data
      socketService.sendImageMessage(
        imagePath: imageFile.path,
        base64Image: base64Image,
        fileName: fileName,
        sourceId: widget.currentUser.id,
        targetId: widget.chatModel.ownerId ?? widget.chatModel.id,
        senderName: widget.currentUser.name,
        adoptionId: widget.chatModel.adoptionId ?? widget.chatModel.id.toString(),
        petName: widget.chatModel.petName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending image: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          "assets/wallpaper.jpg",
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leadingWidth: 70,
            titleSpacing: 0,
            leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 24),
                  CircleAvatar(
                    child: widget.chatModel.petImageUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.chatModel.petImageUrl!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.pets, size: 20);
                        },
                      ),
                    )
                        : Icon(Icons.pets, size: 20),
                    radius: 20,
                    backgroundColor: Colors.blueGrey,
                  )
                ],
              ),
            ),
            title: Container(
              margin: EdgeInsets.all(5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatModel.petName ?? widget.chatModel.name,
                    style: TextStyle(
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.chatModel.isMyPetChat == true
                        ? "Chat with ${widget.chatModel.interestedUserName}"
                        : "Chat with ${widget.chatModel.ownerName}",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(onPressed: () {}, icon: Icon(Icons.video_call)),
              IconButton(onPressed: () {}, icon: Icon(Icons.call)),
              PopupMenuButton<String>(
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: Text("Pet Details"),
                      value: "Pet Details",
                    ),
                    PopupMenuItem(
                      child: Text("Adoption Status"),
                      value: "Adoption Status",
                    ),
                    PopupMenuItem(
                      child: Text("Block User"),
                      value: "Block User",
                    ),
                  ];
                },
              )
            ],
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - 140,
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      if (messages[index].type == "source") {
                        return OwnChatMessage(
                          message: messages[index].message,
                          time: messages[index].time,
                          messageType: messages[index].messageType,
                          base64Image: messages[index].base64Image,
                          fileName: messages[index].fileName,
                        );
                      } else {
                        return Replymessage(
                          message: messages[index].message,
                          time: messages[index].time,
                          messageType: messages[index].messageType,
                          base64Image: messages[index].base64Image,
                          fileName: messages[index].fileName,
                        );
                      }
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width - 55,
                        child: Card(
                          margin: EdgeInsets.only(left: 2, right: 2, bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextFormField(
                            controller: _controller,
                            focusNode: focusNode,
                            textAlignVertical: TextAlignVertical.center,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "Type a Message",
                              prefixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    show = !show;
                                  });
                                },
                                icon: Icon(Icons.emoji_emotions),
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      showModalBottomSheet(
                                          backgroundColor: Colors.transparent,
                                          context: context,
                                          builder: (builder) => bottomSheet());
                                    },
                                    icon: Icon(Icons.attach_file),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      try {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CameraScreen(
                                              onImageSend: _handleImageSendFromCamera,
                                              onVideoSend: _handleVideoSendFromCamera,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Camera not available: $e')),
                                        );
                                      }
                                    },
                                    icon: Icon(Icons.camera_alt),
                                  )
                                ],
                              ),
                              contentPadding: EdgeInsets.all(5),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 2),
                        child: CircleAvatar(
                          radius: 25,
                          child: IconButton(
                            onPressed: () {
                              if (sendbutton && _controller.text.trim().isNotEmpty) {
                                _sendMessage(_controller.text.trim());
                                _controller.clear();
                              }
                            },
                            icon: Icon(sendbutton ? Icons.send : Icons.mic),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget bottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(
                      Icons.insert_drive_file, Colors.indigo, "Document", () {}),
                  SizedBox(width: 40),
                  iconCreation(Icons.camera_alt, Colors.pink, "Camera", () async {
                    Navigator.pop(context);
                    await _captureImageFromCamera();
                  }),
                  SizedBox(width: 40),
                  iconCreation(Icons.insert_photo, Colors.purple, "Gallery", () async {
                    Navigator.pop(context);
                    await _pickImageFromGallery();
                  }),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  iconCreation(Icons.headset, Colors.orange, "Audio", () {}),
                  SizedBox(width: 40),
                  iconCreation(Icons.location_pin, Colors.teal, "Location", () {}),
                  SizedBox(width: 40),
                  iconCreation(Icons.person, Colors.blue, "Contact", () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget iconCreation(IconData icons, Color color, String text, VoidCallback onTap) {
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(
              icons,
              size: 29,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 5),
          Text(
            text,
            style: TextStyle(fontSize: 12),
          )
        ],
      ),
    );
  }
}

// Create a separate utility class for consistent chat ID generation
class ChatIdHelper {
  /// Generate consistent chat ID for adoption conversations
  static String generateAdoptionChatId(
      String userId1,
      String userId2,
      String adoptionId
      ) {
    // Always sort user IDs to ensure consistency
    List<String> sortedIds = [userId1, userId2]..sort();
    return 'adoption_${sortedIds[0]}_${sortedIds[1]}_$adoptionId';
  }

  /// Generate consistent chat ID for regular conversations
  static String generateRegularChatId(String userId1, String userId2) {
    List<String> sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  /// Generate chat ID based on context
  static String generateChatId(
      String userId1,
      String userId2,
      {String? adoptionId}
      ) {
    if (adoptionId != null && adoptionId.isNotEmpty) {
      return generateAdoptionChatId(userId1, userId2, adoptionId);
    }
    return generateRegularChatId(userId1, userId2);
  }

  /// Validate if a chat ID belongs to specific users and adoption
  static bool isValidChatId(
      String chatId,
      String userId1,
      String userId2,
      {String? adoptionId}
      ) {
    String expectedChatId = generateChatId(userId1, userId2, adoptionId: adoptionId);
    return chatId == expectedChatId;
  }
}

// Usage in your components:
class MessageHelper {
  /// Updated send message method with proper chat ID
  static void sendMessageWithProperChatId({
    required SocketService socketService,
    required String message,
    required int sourceId,
    required int targetId,
    required String senderName,
    required String receiverName,
    String? adoptionId,
    String? petName,
  }) {
    // Generate consistent chat ID
    String chatId = ChatIdHelper.generateChatId(
        sourceId.toString(),
        targetId.toString(),
        adoptionId: adoptionId
    );

    print("DEBUG: Generated chat ID: $chatId");
    print("DEBUG: Source ID: $sourceId, Target ID: $targetId, Adoption ID: $adoptionId");

    // Send message with proper chat ID
    socketService.sendMessage(
      message: message,
      sourceId: sourceId,
      targetId: targetId,
      senderName: senderName,
      receiverName: receiverName,
      adoptionId: adoptionId ?? '',
      petName: petName ?? '',

    );
  }
}