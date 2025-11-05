import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:petba_new/providers/Config.dart';

class OwnerService {
  static Future<Map<String, dynamic>?> getOwnerInfo(int customerId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiurl/api/customer/$customerId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      
      print('Failed to fetch owner info: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching owner info: $e');
      return null;
    }
  }

  static Future<String?> getOwnerName(int customerId) async {
    try {
      final ownerInfo = await getOwnerInfo(customerId);
      if (ownerInfo != null) {
        final firstName = ownerInfo['firstname'] ?? '';
        final lastName = ownerInfo['lastname'] ?? '';
        return '$firstName $lastName'.trim();
      }
      return null;
    } catch (e) {
      print('Error getting owner name: $e');
      return null;
    }
  }

  static Future<String?> getOwnerPhone(int customerId) async {
    try {
      final ownerInfo = await getOwnerInfo(customerId);
      return ownerInfo?['telephone'];
    } catch (e) {
      print('Error getting owner phone: $e');
      return null;
    }
  }

  static Future<String?> getOwnerEmail(int customerId) async {
    try {
      final ownerInfo = await getOwnerInfo(customerId);
      return ownerInfo?['email'];
    } catch (e) {
      print('Error getting owner email: $e');
      return null;
    }
  }
}
