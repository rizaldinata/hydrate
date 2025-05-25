import 'package:flutter/material.dart';
import 'package:hydrate/presentation/screens/auth_wrapper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYDRATE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE8F7FF),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF00A6FB),
          selectionColor: Color(0xFF00A6FB),
          selectionHandleColor: Color(0xFF00A6FB),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Logika autentikasi sekarang ada di sini
    );
  }
}