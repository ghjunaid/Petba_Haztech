import 'package:flutter/material.dart';

// // The primary colour
// Color kThemeColour = Color(0xff253150);
//
// // The colours for the loading screen
// Color kShimmerBgColor = Colors.grey[300]!;
// Color kShimmerColor = Colors.grey[100]!;

class AppColors {
  // Main theme colors
  static const Color primaryColor = Color(0xFF2d2d2d);
  static const Color primaryDark = Color(0xFF1a1a1a);

  // You can also define other common colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color blue = Colors.blue;
  static const Color red = Colors.red;
  static const Color green = Colors.green;

  // Example for transparency variants
  static Color primaryLight = Color(0xFF2d2d2d).withOpacity(0.7);
}

//String apiurl = 'http://192.168.0.157:8000'; // Haztech Wifi
String apiurl = 'http://10.252.14.218:8000'; // Local machine IP
//String apiurl= 'http://10.0.2.2:8000'; // Emulator/Local ip
// String apiurl= 'https://petba.in/petbalaravel/public';

//For chat page
const String baseUrl = 'http://192.168.0.157:8000';

//The server base url
String serverIp = 'http://192.168.0.157:8000'; //Haztech Wifi
// String serverIp = 'http://192.168.15.37'; //My phone

String producturl = 'https://petba.in/image';

// The api keys for the google maps. Vets and Groomers
const String googleMapsApiKey = "AIzaSyDMwyFExzv-Mvp6NxuECQTacnNun1I0JI4";

// The Api key for the payment gateway
const String razorApiKey = "rzp_test_Xgh9KnPUU8MaII";
