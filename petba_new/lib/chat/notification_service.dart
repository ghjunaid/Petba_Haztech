import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ CRITICAL: Background handler MUST be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  // Background messages are automatically displayed by the system
  // But you can add custom logic here if needed

  // If you want to show a custom notification even in background:
  // await FirebaseNotificationService.showLocalNotification(
  //   title: message.notification?.title ?? message.data['senderName'] ?? 'New Message',
  //   body: message.notification?.body ?? message.data['message'] ?? 'You have a message',
  //   payload: message.data.toString(),
  // );
}

class FirebaseNotificationService {
  static FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static String? _currentChatId;
  static bool _isAppInForeground = true;
  static Future<void> _handleBackgroundMessageQueuing(RemoteMessage message) async {
    // Store message locally for when app comes back online
    await _storeOfflineMessage(message);
  }
  static Future<void> initialize() async {
    // ✅ CRITICAL: Set the background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      carPlay: false,
      criticalAlert: false,
      announcement: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is terminated/background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check for initial message when app is opened from terminated state
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }
  static Future<void> _storeOfflineMessage(RemoteMessage message) async {
    // Use shared preferences or local database to store offline messages
    final prefs = await SharedPreferences.getInstance();

    List<String> offlineMessages = prefs.getStringList('offline_messages') ?? [];

    Map<String, dynamic> messageData = {
      'senderId': message.data['senderId'],
      'senderName': message.data['senderName'],
      'message': message.data['message'],
      'messageType': message.data['messageType'],
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'adoptionId': message.data['adoptionId'],
    };

    offlineMessages.add(json.encode(messageData));
    await prefs.setStringList('offline_messages', offlineMessages);
  }
  // ✅ Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    print('Message data: ${message.data}');

    // Check if notification should be shown
    String? senderId = message.data['senderId'] ?? message.data['sourceid'];

    // Show notification even in foreground, but suppress if user is in the same chat
    bool shouldShow = true;

    if (_currentChatId != null && senderId == _currentChatId) {
      // User is currently viewing this chat, don't show notification
      shouldShow = false;
      print('Suppressing notification - user in same chat');
    }

    if (shouldShow) {
      await showLocalNotification(
        title: message.notification?.title ??
            message.data['senderName'] ??
            'New Message',
        body: message.notification?.body ??
            message.data['message'] ??
            _getMessageBodyFromType(message.data['messageType']),
        payload: message.data.toString(),
      );
    }
  }

  static String _getMessageBodyFromType(String? messageType) {
    switch (messageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎵 Audio';
      default:
        return 'You have a new message';
    }
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('Notification tapped: ${message.messageId}');

    // Extract chat/user info from the message
    String? senderId = message.data['senderId'] ?? message.data['sourceid'];
    String? chatId = message.data['chatId'];

    print('Tapped notification from sender: $senderId, chat: $chatId');

    // TODO: Navigate to specific chat
    // You can implement navigation logic here
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  // Make this method public and static
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      // You can add custom sound here if you have one in android/app/src/main/res/raw/
      // sound: RawResourceAndroidNotificationSound('notification'),
    );

    const DarwinNotificationDetails darwinNotificationDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  // ✅ Monitor token refresh
  static void monitorTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // TODO: Send updated token to your server
    });
  }

  static void setCurrentChat(String? chatId) {
    _currentChatId = chatId;
    print('Current chat set to: $chatId');
  }

  static void setAppState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    print('App state changed - in foreground: $isInForeground');
  }

  static Future<void> processOfflineMessages() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> offlineMessages = prefs.getStringList('offline_messages') ?? [];

    if (offlineMessages.isNotEmpty) {
      for (String messageStr in offlineMessages) {
        try {
          Map<String, dynamic> messageData = json.decode(messageStr);

          // Show notification for offline message
          await showLocalNotification(
            title: messageData['senderName'] ?? 'New Message',
            body: messageData['message'] ?? 'You have a message',
            payload: json.encode(messageData),
          );

        } catch (e) {
          print('Error processing offline message: $e');
        }
      }

      // Clear processed offline messages
      await prefs.remove('offline_messages');
    }
  }
}