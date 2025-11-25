import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petba_new/screens/SignIn.dart';
import 'package:petba_new/screens/HomePage.dart';
import 'package:camera/camera.dart';
import 'package:petba_new/chat/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io'
    show Platform, HttpClient, SecurityContext, X509Certificate, HttpOverrides;
import 'package:petba_new/services/user_data_service.dart';
import 'package:provider/provider.dart';
import 'package:petba_new/theme/app_color.dart';
import 'package:petba_new/providers/theme_provider.dart';

// ✅ Add HttpOverrides class
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Apply overrides for SSL issue in emulator
  HttpOverrides.global = MyHttpOverrides();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await availableCameras();
  } else {
    print("Camera not supported on this platform");
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Notification Service
  await FirebaseNotificationService.initialize();

  // Check auto login before running the app
  final isLoggedIn = await UserDataService.isUserLoggedIn();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({required this.isLoggedIn});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Widget _home;

  @override
  void initState() {
    super.initState();
    _home = widget.isLoggedIn ? HomePage() : LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (_, themeProvider, __) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Petba',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: _home,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
