import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  // O 'child' é o conteúdo que vai mudar em cada tela (formulário de login, dashboard, etc)
  final Widget child;

  // O título pode ser "GSPR" ou outro texto que você queira passar
  final String title;

  const BaseScreen({
    Key? key,
    required this.child,
    this.title = 'GSPR', // Texto padrão
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fundo branco padrão
      body: Column(
        children: [
          // CABEÇALHO VERDE PERSONALIZADO
          Container(
            width: double.infinity,
            height: 160, // Ajuste a altura conforme necessário
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5ED84F), // Verde mais claro (topo)
                  Color(0xFF3BA135), // Verde mais escuro (base)
                ],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30), // Borda arredondada embaixo
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Texto do lado esquerdo
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic, // Deixei em itálico como na imagem
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    // Logo do Porquinho do lado direito
                    // Lembre-se de adicionar a imagem na pasta assets e no pubspec.yaml
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Image.asset(
                        'lib/assets/widgets/itens/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CONTEÚDO DA TELA (Restante da tela branca)
          Expanded(
            child: child, // Aqui entra o conteúdo dinâmico
          ),
        ],
      ),
    );
  }
}