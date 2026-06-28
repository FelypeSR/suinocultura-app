import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes.dart'; // Rotas nomeadas centralizadas
import 'auth_gate.dart'; // Decide entre login e home
import 'firebase_options.dart';
import 'theme/app_theme.dart'; // Tema central Material Design 3



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // Tema Material Design 3 (identidade verde)
      // Traduções dos widgets do Material/Cupertino (date picker, etc.)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      // AuthGate mostra login ou home conforme o usuário está autenticado.
      home: const AuthGate(),
      routes: Rotas.mapa,
    );
  }
}