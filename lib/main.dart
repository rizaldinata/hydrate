import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'locator.dart'; 
import 'app.dart';   

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupLocator(); 

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    const MyApp(),
  );
}