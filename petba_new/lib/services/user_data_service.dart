import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserDataService {
  static const String USER_DATA_KEY = 'userData';
  static const String IS_LOGGED_IN_KEY = 'isLoggedIn';
  static const String CITY_ID_KEY = 'cityId';
  static const String REMEMBER_ME_KEY = 'rememberMe';
  static const String REMEMBER_ME_EMAIL_KEY = 'rememberMeEmail';
  static const String REMEMBER_ME_PASSWORD_KEY = 'rememberMePassword';

  // Save user data after login/signup
  static Future<bool> saveUserData({
    required int customerId,
    required String firstName,
    required String lastName,
    required String email,
    String? token,
    String? telephone,
    int? cityId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      Map<String, dynamic> userData = {
        'customer_id': customerId,
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        if (token != null) 'token': token,
        if (telephone != null) 'telephone': telephone,
      };

      await prefs.setString(USER_DATA_KEY, jsonEncode(userData));
      await prefs.setBool(IS_LOGGED_IN_KEY, true);

      if (cityId != null) {
        await prefs.setInt(CITY_ID_KEY, cityId);
      }

      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Get complete user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(USER_DATA_KEY);

      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }


  // Get customer ID only
  static Future<int?> getCustomerId() async {
    try {
      final userData = await getUserData();
      return userData?['customer_id'];
    } catch (e) {
      print('Error getting customer ID: $e');
      return null;
    }
  }

  // Get user email only
  static Future<String?> getUserEmail() async {
    try {
      final userData = await getUserData();
      return userData?['email'];
    } catch (e) {
      print('Error getting user email: $e');
      return null;
    }
  }

  // Get user token only
  static Future<String?> getUserToken() async {
    try {
      final userData = await getUserData();
      return userData?['token'];
    } catch (e) {
      print('Error getting user token: $e');
      return null;
    }
  }

  // Get first name only
  static Future<String?> getFirstName() async {
    try {
      final userData = await getUserData();
      return userData?['firstname'];
    } catch (e) {
      print('Error getting first name: $e');
      return null;
    }
  }

  // Get last name only
  static Future<String?> getLastName() async {
    try {
      final userData = await getUserData();
      return userData?['lastname'];
    } catch (e) {
      print('Error getting last name: $e');
      return null;
    }
  }

  // Get telephone only
  static Future<String?> getTelephone() async {
    try {
      final userData = await getUserData();
      return userData?['telephone'];
    } catch (e) {
      print('Error getting telephone: $e');
      return null;
    }
  }

  // COMBINATION GETTERS - For pages that need multiple specific fields

  // Get customer ID and email (for profile pages)
  static Future<Map<String, dynamic>?> getCustomerIdAndEmail() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        return {
          'customer_id': userData['customer_id'],
          'email': userData['email'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting customer ID and email: $e');
      return null;
    }
  }

  // Get customer ID, email, and token (for API calls)
  static Future<Map<String, dynamic>?> getAuthData() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        return {
          'customer_id': userData['customer_id'],
          'email': userData['email'],
          'token': userData['token'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Error getting auth data: $e');
      return null;
    }
  }

  // Get user display info (name and email)
  static Future<Map<String, dynamic>?> getUserDisplayInfo() async {
    try {
      final userData = await getUserData();
      if (userData != null) {
        return {
          'firstname': userData['firstname'],
          'lastname': userData['lastname'],
          'email': userData['email'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting user display info: $e');
      return null;
    }
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(IS_LOGGED_IN_KEY) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get city ID
  static Future<int?> getCityId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cityId = prefs.getInt(CITY_ID_KEY);
      return cityId;
    } catch (e) {
      print('Error getting city ID: $e');
      return null;
    }
  }

  // Set city ID
  static Future<bool> setCityId(int cityId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(CITY_ID_KEY, cityId);
      return true;
    } catch (e) {
      print('Error setting city ID: $e');
      return false;
    }
  }

  // Prepare data for HomePage API call
  static Future<Map<String, dynamic>?> getHomePageData() async {
    try {
      final userData = await getUserData();
      final cityId = await getCityId();

      if (userData != null && cityId != null) {
        return {
          'city_id': cityId,
          'userData': {
            'customer_id': userData['customer_id'],
            'email': userData['email'],
            'token': userData['token'] ?? '',
          }
        };
      }
      return null;
    } catch (e) {
      print('Error preparing homepage data: $e');
      return null;
    }
  }

  // Update user data (for partial updates)
  static Future<bool> updateUserData(Map<String, dynamic> updates) async {
    try {
      final currentData = await getUserData();
      if (currentData != null) {
        currentData.addAll(updates);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(USER_DATA_KEY, jsonEncode(currentData));
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  // Clear all user data (logout)
  static Future<bool> clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(USER_DATA_KEY);
      await prefs.remove(IS_LOGGED_IN_KEY);
      await prefs.remove(CITY_ID_KEY);
      return true;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Save complete login response
  static Future<bool> saveLoginResponse(Map<String, dynamic> response) async {
    try {
      if (response.containsKey('userData')) {
        final userData = response['userData'];

        // final prefs = await SharedPreferences.getInstance();
        // await prefs.remove(CITY_ID_KEY); // Remove previous city selection

        print('=== USER DATA SERVICE - LOGIN RESPONSE ===');
        print('Clearing previous city data');
        print('Saving new user data without city');

        return await saveUserData(
          customerId: userData['customer_id'],
          firstName: userData['firstname'],
          lastName: userData['lastname'],
          email: userData['email'],
          token: userData['token'],
        );
      }
      return false;
    } catch (e) {
      print('Error saving login response: $e');
      return false;
    }
  }

  // Save complete signup response
  static Future<bool> saveSignupResponse(Map<String, dynamic> response) async {
    try {
      if (response.containsKey('userData')) {
        final userData = response['userData'];
        return await saveUserData(
          customerId: userData['customer_id'],
          firstName: userData['firstname'],
          lastName: userData['lastname'],
          email: userData['email'],
          telephone: userData['telephone'],
        );
      }
      return false;
    } catch (e) {
      print('Error saving signup response: $e');
      return false;
    }
  }

  static Future<bool> clearCitySelection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CITY_ID_KEY);
      print('City selection cleared successfully');
      return true;
    } catch (e) {
      print('Error clearing city selection: $e');
      return false;
    }
  }

  // Remember Me functionality
  // static Future<bool> saveRememberMeCredentials(String email, String password) async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool(REMEMBER_ME_KEY, true);
  //     await prefs.setString(REMEMBER_ME_EMAIL_KEY, email);
  //     await prefs.setString(REMEMBER_ME_PASSWORD_KEY, password);
  //     return true;
  //   } catch (e) {
  //     print('Error saving remember me credentials: $e');
  //     return false;
  //   }
  // }

  // static Future<Map<String, String>?> getRememberMeCredentials() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final isRememberMe = prefs.getBool(REMEMBER_ME_KEY) ?? false;
  //     if (isRememberMe) {
  //       final email = prefs.getString(REMEMBER_ME_EMAIL_KEY);
  //       final password = prefs.getString(REMEMBER_ME_PASSWORD_KEY);
  //       if (email != null && password != null) {
  //         return {'email': email, 'password': password};
  //       }
  //     }
  //     return null;
  //   } catch (e) {
  //     print('Error getting remember me credentials: $e');
  //     return null;
  //   }
  // }

  // static Future<bool> clearRememberMeCredentials() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool(REMEMBER_ME_KEY, false);
  //     await prefs.remove(REMEMBER_ME_EMAIL_KEY);
  //     await prefs.remove(REMEMBER_ME_PASSWORD_KEY);
  //     return true;
  //   } catch (e) {
  //     print('Error clearing remember me credentials: $e');
  //     return false;
  //   }
  // }

  // static Future<bool> isRememberMeEnabled() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     return prefs.getBool(REMEMBER_ME_KEY) ?? false;
  //   } catch (e) {
  //     print('Error checking remember me status: $e');
  //     return false;
  //   }
  // }
}
