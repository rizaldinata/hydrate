import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:hydrate/locator.dart'; 
import 'package:hydrate/data/repositories/pengguna_repository.dart';
import 'package:hydrate/presentation/screens/Pendaftaran/login_view.dart';
import 'package:hydrate/presentation/screens/main_screen.dart';
import 'package:hydrate/presentation/widgets/splash_screen_widget.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth firebaseAuth = locator<FirebaseAuth>();
    final PenggunaRepository penggunaRepo = locator<PenggunaRepository>();

    return StreamBuilder<User?>(
      stream: firebaseAuth.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return SplashScreenWidget();
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          final firebaseUser = authSnapshot.data!;
          
          return FutureBuilder<bool>(
            future: penggunaRepo.handleUserLoginInitialization(firebaseUser),
            builder: (context, initSnapshot) {
              if (initSnapshot.connectionState == ConnectionState.waiting) {
                return SplashScreenWidget();
              }
              if (initSnapshot.hasData && initSnapshot.data == true) {
                return MainScreen();
              }
              return const LoginView();
            },
          );
        } else {
          return const LoginView(); 
        }
      },
    );
  }
}