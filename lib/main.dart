import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/app_colors.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'views/screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to your Firebase project (settings from firebase_options.dart).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check proves requests really come from this app. The debug provider
  // is for development only. Pass the debug token you registered in the
  // Firebase console with --dart-define (see README); without one, the SDK
  // makes up its own and prints it in the device logs.
  const token = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');
  const debugToken = token == '' ? null : token;
  await FirebaseAppCheck.instance.activate(
    providerAndroid: const AndroidDebugProvider(debugToken: debugToken),
    providerApple: const AppleDebugProvider(debugToken: debugToken),
  );

  runApp(const ChatbotApp());
}

class ChatbotApp extends StatelessWidget {
  const ChatbotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.botName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}
