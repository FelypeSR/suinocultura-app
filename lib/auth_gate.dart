import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/telateste.dart';
import 'screens/LoginScreen.dart';
import 'screens/SplashScreen.dart';
import 'screens/NaoAutorizadoScreen.dart';
import 'services/autorizacao_service.dart';

/// Decide qual tela mostrar conforme o estado de autenticação:
/// - usuário logado E autorizado -> home (WidgetTestScreen)
/// - logado mas fora da lista    -> tela de "acesso não autorizado"
/// - sem usuário                 -> tela de login
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
          // Mesma splash do boot: a abertura fica contínua, sem "pulo" visual.
          return const SplashScreen();
        }
        if (snapshot.hasData) {
          // Estar logado não basta: o e-mail precisa estar na lista de
          // autorizados da granja. A key força uma nova checagem quando
          // troca de usuário.
          return _GateAutorizacao(key: ValueKey(snapshot.data!.uid));
        }
        return const LoginScreen();
      },
    );
  }
}

/// Consulta a lista de autorizados uma única vez após o login e mostra a
/// home ou a tela de bloqueio. "Tentar novamente" refaz a consulta.
class _GateAutorizacao extends StatefulWidget {
  const _GateAutorizacao({super.key});

  @override
  State<_GateAutorizacao> createState() => _GateAutorizacaoState();
}

class _GateAutorizacaoState extends State<_GateAutorizacao> {
  late Future<bool> _checagem = AutorizacaoService().usuarioAutorizado();

  void _tentarNovamente() {
    setState(() => _checagem = AutorizacaoService().usuarioAutorizado());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checagem,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        if (snapshot.data == true) {
          return const WidgetTestScreen();
        }
        return NaoAutorizadoScreen(onTentarNovamente: _tentarNovamente);
      },
    );
  }
}
