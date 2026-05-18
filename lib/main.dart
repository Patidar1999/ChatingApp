import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'utils/app_theme.dart';

/// Entry point of the Flutter Chat App
void main() async {
  // Ensure Flutter bindings are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your project config
  await Firebase.initializeApp();

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chating App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // StreamBuilder listens to auth state changes.
      // If user is already logged in → go to HomeScreen.
      // If not → go to LoginScreen.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // User is logged in
          if (snapshot.hasData && snapshot.data != null) {
            return const HomeScreen();
          }

          // User is not logged in
          return const LoginScreen();
        },
      ),
    );
  }
}
