import 'package:flutter/material.dart';
import 'package:petba_new/theme/app_color.dart';

// // The primary colour
// Color kThemeColour = Color(0xff253150);
//
// // The colours for the loading screen
// Color kShimmerBgColor = Colors.grey[300]!;
// Color kShimmerColor = Colors.grey[100]!;

class AppColors {
  static ThemeData get _theme {
    // Prefer the navigator state's context (more stable during rebuilds),
    // fall back to the global currentContext. If both are null return a
    // light ThemeData as a safe default to avoid transient inverted colors
    // when the app is rebuilding the MaterialApp/theme.
    final context =
        appNavigatorKey.currentState?.context ?? appNavigatorKey.currentContext;
    return context != null ? Theme.of(context) : ThemeData.light();
  }

  static ColorScheme get _scheme => _theme.colorScheme;

  static Color get primaryColor => _theme.cardColor;
  static Color get primaryDark => _theme.scaffoldBackgroundColor;
  static Color get white => _scheme.onSurface;
  static Color get black => Colors.black;
  static Color get grey => _scheme.onSurfaceVariant;
  static Color get blue => _scheme.primary;
  static Color get red => _scheme.error;
  static Color get green => _scheme.secondary;
  static Color get primaryLight => primaryColor.withOpacity(0.7);
}

// String apiurl = 'http://192.168.0.157:8000'; // Haztech Wifi
// String apiurl = 'http://10.0.2.2:8000'; // Emulator/Local ip
// String apiurl = 'http://10.105.235.218:8000'; // Local machine IP
String apiurl = 'https://petba.in/petbalaravel/public';

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
