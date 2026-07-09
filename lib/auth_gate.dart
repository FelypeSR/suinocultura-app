import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/telateste.dart';
import 'screens/LoginScreen.dart';
import 'screens/SplashScreen.dart';
import 'screens/BemVindoGranjaScreen.dart';
import 'models/granja_model.dart';
import 'services/granja_ativa.dart';
import 'services/granja_service.dart';

/// Decide qual tela mostrar conforme autenticação e granjas do usuário:
/// - sem usuário            -> tela de login
/// - logado, sem granja     -> boas-vindas (criar granja ou aguardar convite)
/// - logado, 1 granja       -> home direto
/// - logado, várias granjas -> seletor de granja
///
/// Reage automaticamente a login/logout e a convites (as granjas são uma
/// stream), então não é preciso navegar manualmente.
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
          // A key força um gate novo (e nova stream) quando troca de usuário.
          return _GateGranjas(key: ValueKey(snapshot.data!.uid));
        }
        // Logout: esquece a granja aberta antes de voltar ao login.
        GranjaAtiva.limpar();
        return const LoginScreen();
      },
    );
  }
}

/// Observa as granjas do usuário logado e encaminha para a tela certa.
class _GateGranjas extends StatefulWidget {
  const _GateGranjas({super.key});

  @override
  State<_GateGranjas> createState() => _GateGranjasState();
}

class _GateGranjasState extends State<_GateGranjas> {
  late final Stream<List<GranjaModel>> _granjas =
      GranjaService().minhasGranjas();

  /// Granja escolhida no seletor (quando o usuário participa de várias).
  String? _escolhidaId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GranjaModel>>(
      stream: _granjas,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ErroGate(mensagem: '${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const SplashScreen();
        }

        final granjas = snapshot.data!;
        if (granjas.isEmpty) {
          GranjaAtiva.limpar();
          return const BemVindoGranjaScreen();
        }

        // Uma granja só (caso comum): entra direto. Com várias, usa a
        // escolhida no seletor — se ainda não escolheu (ou perdeu acesso à
        // escolhida), mostra o seletor.
        final GranjaModel ativa;
        if (granjas.length == 1) {
          ativa = granjas.first;
        } else {
          final escolhida =
              granjas.where((g) => g.id == _escolhidaId).toList();
          if (escolhida.isEmpty) {
            return _EscolherGranja(
              granjas: granjas,
              onEscolher: (g) => setState(() => _escolhidaId = g.id),
            );
          }
          ativa = escolhida.first;
        }

        GranjaAtiva.definir(granjaId: ativa.id!, granjaNome: ativa.nome);
        return const WidgetTestScreen();
      },
    );
  }
}

/// Lista simples para escolher em qual granja entrar.
class _EscolherGranja extends StatelessWidget {
  final List<GranjaModel> granjas;
  final ValueChanged<GranjaModel> onEscolher;

  const _EscolherGranja({required this.granjas, required this.onEscolher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Escolha a granja',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: granjas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final g = granjas[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.agriculture_outlined,
                            color: Color(0xFF2E7D32)),
                        title: Text(g.nome),
                        subtitle: Text('${g.membros.length} membro(s)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => onEscolher(g),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sair'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Erro ao carregar as granjas (ex.: sem rede na primeira abertura).
class _ErroGate extends StatelessWidget {
  final String mensagem;

  const _ErroGate({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Colors.black38),
              const SizedBox(height: 16),
              const Text(
                'Não foi possível carregar suas granjas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sair e tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
