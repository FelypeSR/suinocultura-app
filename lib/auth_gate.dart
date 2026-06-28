import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/telateste.dart';
import 'screens/LoginScreen.dart';

/// Decide qual tela mostrar conforme o estado de autenticação:
/// - usuário logado  -> home (WidgetTestScreen)
/// - sem usuário     -> tela de login
///
/// Reage automaticamente a login/logout, então não é preciso navegar
/// manualmente após entrar ou sair.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
          );
        }
        if (snapshot.hasData) {
          return const WidgetTestScreen();
        }
        return const LoginScreen();
      },
    );
  }
}