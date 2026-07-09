import 'package:flutter/material.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';

/// Tela de abertura do app: fundo verde da marca, porquinho e as bolinhas
/// animadas. Aparece enquanto o Firebase inicializa e enquanto o AuthGate
/// decide entre login e home — em aparelhos mais lentos, é o que o usuário
/// vê no lugar da tela branca.
class SplashScreen extends StatelessWidget {
  /// Mensagem de erro da inicialização (quando há, substitui as bolinhas).
  final String? erro;

  const SplashScreen({super.key, this.erro});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Mesmo degradê do cabeçalho da home.
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5ED84F), Color(0xFF3BA135)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'lib/assets/widgets/itens/logo.png',
                height: 140,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              if (erro == null)
                // Bolinhas em branco/rosa: o verde padrão sumiria no fundo.
                const LoadingBolinhas(
                  cores: [Colors.white, Color(0xFFE91E63)],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Não foi possível iniciar o app.\n$erro',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
