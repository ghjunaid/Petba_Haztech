import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petba_new/chat/Model/Messagemodel.dart';
import 'package:petba_new/providers/Config.dart';

class ChatService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<List<MessageModel>> getChatHistory(
      String userId1,
      String userId2,
      String currentUserId,
          {int page = 1, int limit = 50}
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$apiurl/chat-history/$userId1/$userId2?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          List<MessageModel> messages = [];
          for (var messageData in data['messages']) {
            // Pass currentUserId to correctly determine message type
            messages.add(MessageModel.fromJson(messageData, currentUserId));
          }
          return messages;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching chat history: $e');
      return [];
    }
  }


  static Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      await http.post(
        Uri.parse('$apiurl/mark-read'),
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
}