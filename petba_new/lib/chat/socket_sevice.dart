import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:petba_new/chat/Model/ChatModel.dart';
import 'package:petba_new/chat/notification_service.dart';
import 'package:petba_new/providers/Config.dart';
import 'package:petba_new/services/user_data_service.dart';

class SocketService {
  static SocketService? _instance;
  late IO.Socket socket;
  bool _isConnected = false;
  List<Map<String, dynamic>> _pendingMessages = [];
  bool _userOnlineStatus = false;
  Map<int, bool> _userStatusMap = {};

  // Add these variables to track app state
  bool _isAppInForeground = true;
  String? _currentChatId;

  // Callbacks for different functionalities
  Function(String type, String message, String time, {
  bool playSound,
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
  })? onMessageReceived;

  Function()? onScrollToBottom;
  Function(List<dynamic>)? onChatListUpdate;
  Function(Map<String, dynamic>)? onNewChat;

  static SocketService getInstance() {
    _instance ??= SocketService._internal();
    return _instance!;
  }

  SocketService._internal();

  // Connect for individual chat
  void connect({
    required ChatModel sourceChat,
    required ChatModel targetChat,
    Function(String type, String message, String time, {
    bool playSound,
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
    })? messageCallback,
    Function()? scrollCallback,
  }) {
    onMessageReceived = messageCallback;
    onScrollToBottom = scrollCallback;

    _connectSocket();

    // Generate consistent room ID for both users
    String roomId = _generateConsistentRoomId(
        sourceChat.id,
        targetChat.ownerId ?? targetChat.id,
        targetChat.adoptionId
    );

    print("DEBUG: Joining room: $roomId");
    print("DEBUG: Source ID: ${sourceChat.id}, Target ID: ${targetChat.ownerId ?? targetChat.id}");

    if (_isConnected) {
      socket.emit("joinChat", {
        "roomId": roomId,
        "userId": sourceChat.id,
        "targetUserId": targetChat.ownerId ?? targetChat.id,
        "adoptionId": targetChat.adoptionId,
      });
    }
  }

// Add this helper method
  String _generateConsistentRoomId(int userId1, int userId2, String? adoptionId) {
    List<int> sortedIds = [userId1, userId2]..sort();
    if (adoptionId != null && adoptionId.isNotEmpty) {
      return 'adoption_${sortedIds[0]}_${sortedIds[1]}_$adoptionId';
    }
    return 'chat_${sortedIds[0]}_${sortedIds[1]}';
  }

  // Connect for chat list management
  void connectForChatList({
    required int userId,
    Function(List<dynamic>)? onChatListUpdate,
    Function(Map<String, dynamic>)? onNewChat,
  }) {
    this.onChatListUpdate = onChatListUpdate;
    this.onNewChat = onNewChat;

    _connectSocket(userId);

    if (_isConnected) {
      socket.emit("joinChatList", {
        "userId": userId,
      });
    }
  }

  Future<void> _connectSocket([int? userId]) async {
    if (_isConnected) return;

    socket = IO.io("$baseUrl", <String, dynamic>{
       "transports": ["websocket"],
      "autoConnect": true,
    });

    socket.onConnect((data) async {
      print("Connected to server from Socket Service");
      _isConnected = true;

      // Get FCM token and send to server
      String? fcmToken = await FirebaseNotificationService.getToken();

      socket.emit("signin", {
        "userId": userId ?? socket.id,
        "fcmToken": fcmToken,
      });
      if (userId != null) {
        Future.delayed(Duration(seconds: 1), () {
          requestQueuedNotifications(userId);
        });
      }
    });

    socket.onDisconnect((data) {
      print("Disconnected from server");
      _isConnected = false;
    });

    socket.onConnectError((data) {
      print("Connection Error: $data");
      _isConnected = false;
    });

    socket.onError((data) {
      print("Socket Error: $data");
    });

    // Listen for chat list updates
    socket.on("chatListUpdate", (data) {
      print("Received chat list update: $data");
      if (onChatListUpdate != null && data != null) {
        onChatListUpdate!(data['chats'] ?? []);
      }
    });

    // Listen for new chat creation
    socket.on("newChatCreated", (data) {
      print("New chat created: $data");
      if (onNewChat != null && data != null) {
        onNewChat!(data);
      }
    });

    socket.on("userStatusUpdate", (data) {
      print("User status update: $data");
      if (data != null && data['userId'] != null) {
        _userStatusMap[data['userId']] = data['isOnline'] ?? false;

        // If user comes online, send pending messages
        if (data['isOnline'] == true) {
          _sendPendingMessagesForUser(data['userId']);
        }
      }
    });

    socket.on("pendingMessages", (data) {
      print("Received pending messages: $data");
      if (data != null && data['messages'] != null) {
        _processPendingMessages(data['messages']);
      }
    });

    socket.on("queuedNotifications", (data) {
      print("Received queued notifications: $data");
      if (data != null && data['notifications'] != null) {
        _processQueuedNotifications(data['notifications']);
      }
    });

    // Emit user online status
    socket.emit("userOnline", {
      "userId": userId,
      "isOnline": true,
    });

    // Listen for regular text messages
    socket.on("message", (msg) {
      print("Received text message in Socket Service: $msg");
      if (msg != null && msg["message"] != null) {
        final senderId = msg["senderId"];
        final receiverId = msg["receiverId"];
        final timestamp = msg["timestamp"];
        final senderName = msg["senderName"] ?? "Unknown";
        final adoptionId = msg["adoptionId"];

        // Format time
        String formattedTime = _formatTime(timestamp);

        // Handle incoming message
        onMessageReceived?.call(
          "message",
          msg["message"],
          formattedTime,
          playSound: true,
          senderId: senderId.toString(),
          messageType: "text",
          receiverId: receiverId.toString(),
          adoptionId: adoptionId.toString(),
        );
        onScrollToBottom?.call();

        // Show local notification for foreground messages
        _showForegroundNotification(senderName, msg["message"], senderId.toString());
      }
    });

    // Listen for image messages
    socket.on("image_message", (msg) {
      print("Received image message in Socket Service: $msg");
      if (msg != null) {
        final senderId = msg["senderId"];
        final receiverId = msg["receiverId"];
        final timestamp = msg["timestamp"];
        final base64Image = msg["base64Image"];
        final fileName = msg["fileName"];
        final imagePath = msg["imagePath"];
        final senderName = msg["senderName"] ?? "Unknown";
        final adoptionId = msg["adoptionId"];

        // Format time
        String formattedTime = _formatTime(timestamp);

        // Handle incoming image message
        onMessageReceived?.call(
          "message",
          imagePath ?? "Image",
          formattedTime,
          playSound: true,
          senderId: senderId.toString(),
          messageType: "image",
          receiverId: receiverId.toString(),
          base64Image: base64Image,
          fileName: fileName,
          adoptionId: adoptionId.toString(),
        );
        onScrollToBottom?.call();

        // Show local notification for foreground messages
        _showForegroundNotification(senderName, "Photo", senderId.toString());
      }
    });

    // Listen for video messages
    socket.on("video_message", (msg) {
      print("Received video message in Socket Service: $msg");
      if (msg != null) {
        final senderId = msg["senderId"];
        final receiverId = msg["receiverId"];
        final timestamp = msg["timestamp"];
        final base64Video = msg["base64Video"];
        final fileName = msg["fileName"];
        final videoPath = msg["videoPath"];
        final senderName = msg["senderName"] ?? "Unknown";
        final adoptionId = msg["adoptionId"];

        // Format time
        String formattedTime = _formatTime(timestamp);

        // Handle incoming video message
        onMessageReceived?.call(
          "destination",
          videoPath ?? "Video",
          formattedTime,
          playSound: true,
          senderId: senderId.toString(),
          messageType: "video",
          receiverId: receiverId.toString(),
          base64Image: base64Video,
          fileName: fileName,
          adoptionId: adoptionId.toString(),
        );
        onScrollToBottom?.call();

        // Show local notification for foreground messages
        _showForegroundNotification(senderName, "Video", senderId.toString());
      }
    });

    // Listen for typing indicators
    socket.on("typing", (data) {
      print("User is typing: $data");
      // Handle typing indicator
    });

    socket.on("stopTyping", (data) {
      print("User stopped typing: $data");
      // Handle stop typing indicator
    });

    socket.connect();
  }

  // Request chat list from server
  void requestChatList(int userId) {
    print("DEBUG: requestChatList called for user: $userId");
    print("DEBUG: _isConnected: $_isConnected");
    print("DEBUG: socket.connected: ${socket.connected}");
    if (_isConnected) {
      socket.emit("getChatList", {
        "userId": userId,
      });
    }
  }

  void _processPendingMessages(List<dynamic> messages) {
    for (var message in messages) {
      // Process each pending message
      final messageType = message['messageType'] ?? 'text';
      final timestamp = message['timestamp'];
      String formattedTime = _formatTime(timestamp);

      if (messageType == 'text') {
        onMessageReceived?.call(
          "message",
          message["message"],
          formattedTime,
          playSound: true,
          senderId: message["senderId"].toString(),
          messageType: "text",
          receiverId: message["receiverId"].toString(),
          adoptionId: message["adoptionId"]?.toString(),
        );
      } else if (messageType == 'image') {
        onMessageReceived?.call(
          "message",
          message["imagePath"] ?? "Image",
          formattedTime,
          playSound: true,
          senderId: message["senderId"].toString(),
          messageType: "image",
          receiverId: message["receiverId"].toString(),
          base64Image: message["base64Image"],
          fileName: message["fileName"],
          adoptionId: message["adoptionId"]?.toString(),
        );
      }
    }
  }

  // Method to send pending messages for a specific user
  void _sendPendingMessagesForUser(int userId) {
    List<Map<String, dynamic>> userMessages = _pendingMessages
        .where((msg) => msg['receiverId'] == userId)
        .toList();

    for (var message in userMessages) {
      // Resend the message
      socket.emit(message['eventType'], message['data']);
    }

    // Remove sent messages from pending list
    _pendingMessages.removeWhere((msg) => msg['receiverId'] == userId);
  }

  void requestQueuedNotifications(int userId) {
    if (_isConnected) {
      socket.emit("getQueuedNotifications", {
        "userId": userId,
      });
    }
  }

  void _processQueuedNotifications(List<dynamic> notifications) {
    for (var notification in notifications) {
      // Show local notification for each queued message
      FirebaseNotificationService.showLocalNotification(
        title: notification['title'] ?? 'New Message',
        body: notification['body'] ?? '',
        payload: notification['data']['senderId']?.toString() ?? '',
      );
    }
  }

  // Create or get existing chat
  void createOrGetChat({
    required int senderId,
    required int receiverId,
    required String adoptionId,
    required String petName,
    String? petImageUrl,
    String? petBreed,
    String? petType,
    String? ownerName,
    String? interestedUserName,
  }) {
    if (_isConnected) {
      socket.emit("createOrGetChat", {
        "senderId": senderId,
        "receiverId": receiverId,
        "adoptionId": adoptionId,
        "petName": petName,
        "petImageUrl": petImageUrl,
        "petBreed": petBreed,
        "petType": petType,
        "ownerName": ownerName,
        "interestedUserName": interestedUserName,
      });
    }
  }

  void sendMessage({
    required String message,
    required int sourceId,
    required int targetId,
    required String senderName,
    required String receiverName,
    required String adoptionId,
    String? petName,
  }) {
    if (message.trim().isEmpty || !_isConnected) return;

    int timestamp = DateTime.now().millisecondsSinceEpoch;
    String roomId = _generateConsistentRoomId(sourceId, targetId, adoptionId);

    // socket.emit("message", {
    //   "roomId": roomId,
    //   "message": message,
    //   "senderId": sourceId,
    //   "receiverId": targetId,
    //   "senderName": senderName,
    //   "receiverName": receiverName,
    //   "adoptionId": adoptionId,
    //   "petName": petName,
    //   "timestamp": timestamp,
    //   "messageType": "text",
    // });

    Map<String, dynamic> messageData = {
      "roomId": roomId,
      "message": message,
      "senderId": sourceId,
      "receiverId": targetId,
      "senderName": senderName,
      "receiverName": receiverName,
      "adoptionId": adoptionId,
      "petName": petName,
      "timestamp": timestamp,
      "messageType": "text",
      "isQueueable": true, // Mark message as queueable for offline users
    };

    // Check if receiver is online
    bool isReceiverOnline = _userStatusMap[targetId] ?? false;

    if (!isReceiverOnline) {
      // Add to pending messages queue
      _pendingMessages.add({
        'eventType': 'message',
        'data': messageData,
        'receiverId': targetId,
        'timestamp': timestamp,
      });
      print("Message queued for offline user: $targetId");
    }

    // Always emit the message (server will handle queuing)
    socket.emit("message", messageData);
  }

  void requestPendingMessages(int userId) {
    if (_isConnected) {
      socket.emit("getPendingMessages", {
        "userId": userId,
      });
    }
  }

  void sendImageMessage({
    required String imagePath,
    required String base64Image,
    required String fileName,
    required int sourceId,
    required int targetId,
    required String senderName,
    required String adoptionId,
    String? petName,
  }) {
    if (!_isConnected) return;

    int timestamp = DateTime.now().millisecondsSinceEpoch;

    socket.emit("image_message", {
      'senderId': sourceId,
      'receiverId': targetId,
      'senderName': senderName,
      'imagePath': imagePath,
      'base64Image': base64Image,
      'fileName': fileName,
      'messageType': 'image',
      'timestamp': timestamp,
      'adoptionId': adoptionId,
      'petName': petName,
    });
  }

  void sendVideoMessage({
    required String videoPath,
    required String base64Video,
    required String fileName,
    required int sourceId,
    required int targetId,
    required String senderName,
    required String adoptionId,
    String? petName,
  }) {
    if (!_isConnected) return;

    int timestamp = DateTime.now().millisecondsSinceEpoch;

    socket.emit("video_message", {
      'senderId': sourceId,
      'receiverId': targetId,
      'senderName': senderName,
      'videoPath': videoPath,
      'base64Video': base64Video,
      'fileName': fileName,
      'messageType': 'video',
      'timestamp': timestamp,
      'adoptionId': adoptionId,
      'petName': petName,
    });

    print("Video message sent via socket: $fileName");
  }

  void sendTypingIndicator({
    required int sourceId,
    required int targetId,
    required bool isTyping,
  }) {
    if (!_isConnected) return;

    if (isTyping) {
      socket.emit("typing", {
        "senderId": sourceId,
        "receiverId": targetId,
      });
    } else {
      socket.emit("stopTyping", {
        "senderId": sourceId,
        "receiverId": targetId,
      });
    }
  }

  // Add this method to show foreground notifications
  void _showForegroundNotification(String senderName, String message, String senderId) async {
    if (_isAppInForeground) {
      final userData = await UserDataService.getUserData();
      final currentUserId = userData?['customer_id']?.toString() ?? userData?['id']?.toString();

      // Only show notification if:
      // 1. Not from current user
      // 2. Not currently in that specific chat
      if (senderId != currentUserId && _currentChatId != senderId) {
        await FirebaseNotificationService.showLocalNotification(
          title: senderName,
          body: message,
          payload: senderId,
        );
      }
    }
  }

  // Add methods to update app state
  void setAppState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
  }

  String _formatTime(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String hour = dateTime.hour.toString().padLeft(2, '0');
    String minute = dateTime.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  void disconnect() {
    if (_isConnected && socket.connected) {
      socket.emit("userOffline", {
        "userId": socket.id, // or actual user ID
        "isOnline": false,
      });
      socket.disconnect();
      _isConnected = false;
    }
  }

  bool get isConnected => _isConnected;

  void dispose() {
    disconnect();
    onMessageReceived = null;
    onScrollToBottom = null;
    onChatListUpdate = null;
    onNewChat = null;
  }
}