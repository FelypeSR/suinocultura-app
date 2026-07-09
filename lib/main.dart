import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes.dart'; // Rotas nomeadas centralizadas
import 'auth_gate.dart'; // Decide entre login e home
import 'firebase_options.dart';
import 'theme/app_theme.dart'; // Tema central Material Design 3
import 'screens/SplashScreen.dart'; // Tela de abertura animada

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // O Firebase inicializa DENTRO do app (BootGate), atrás da splash animada.
  // Esperar aqui deixaria o usuário numa tela branca em aparelhos lentos.
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
      // BootGate inicializa o Firebase sob a splash e então entrega ao
      // AuthGate, que mostra login ou home conforme a autenticação.
      home: const BootGate(),
      routes: Rotas.mapa,
    );
  }
}

/// Mostra a splash animada enquanto o Firebase inicializa; quando termina,
/// entrega a decisão de tela ao AuthGate. Se a inicialização falhar, a splash
/// exibe o erro no lugar da animação.
class BootGate extends StatefulWidget {
  const BootGate({super.key});

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  // Future criado uma única vez: rebuilds não reinicializam o Firebase.
  late final Future<FirebaseApp> _init = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SplashScreen(erro: '${snapshot.error}');
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        return const AuthGate();
      },
    );
  }
}