import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petba_new/screens/SignIn.dart';
import 'package:petba_new/screens/SignUp.dart';
import 'package:petba_new/screens/HomePage.dart';
import 'package:camera/camera.dart';
import 'package:petba_new/chat/notification_service.dart';
import 'package:petba_new/chat/screens/CameraScreen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io'
    show Platform, HttpClient, SecurityContext, X509Certificate, HttpOverrides;
import 'package:petba_new/services/user_data_service.dart';

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
    final cameras = await availableCameras();
    // use cameras...
  } else {
    print("Camera not supported on this platform");
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Notification Service
  await FirebaseNotificationService.initialize();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _home = LoginPage();

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final isLoggedIn = await UserDataService.isUserLoggedIn();
    if (isLoggedIn) {
      // User is already logged in, go directly to HomePage
      setState(() {
        _home = HomePage();
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: _home,
      debugShowCheckedModeBanner: false,
    );
  }
}
