import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/pages/enquiry/enquiry_page_list.dart';
import 'package:leadassist/pages/auth.dart';
import 'package:leadassist/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  );
  runApp(const LeadAssistApp());
}

class LeadAssistApp extends StatelessWidget {
  const LeadAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "LeadAssist",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,

        /// Global text theme
        // textTheme: ThemeData.light().textTheme.apply(
        //   bodyColor: Colors.deepPurple,
        //   displayColor: Colors.deepPurple,
        // ).copyWith(
        //   bodyLarge: const TextStyle(
        //     fontWeight: FontWeight.bold,
        //     letterSpacing: 1,
        //   ),
        //   bodyMedium: const TextStyle(
        //     fontWeight: FontWeight.bold,
        //     letterSpacing: 1,
        //   ),
        //   titleLarge: const TextStyle(
        //     fontWeight: FontWeight.bold,
        //     letterSpacing: 1,
        //   ),
        // ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 20, // default AppBar text size
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.deepPurple),
            foregroundColor: Colors.deepPurple,
          ),
        ),
      ),
      home: SplashPage(),
    );
  }
}
