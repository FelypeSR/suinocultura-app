import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gspr/assets/widgets/itens/navbar.dart'; // NavBar
import 'package:gspr/assets/widgets/itens/evento_proximo.dart'; // Card de evento
import 'package:gspr/assets/widgets/itens/resumo_de_eventos.dart'; // Carrossel de resumo
import 'package:gspr/routes.dart'; // Rotas nomeadas

/// Tela inicial do app (home): cabeçalho com saudação, busca,
/// eventos próximos e o carrossel de resumo. Abaixo, a navbar flutuante.
class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true, // navbar flutua sobre o conteúdo
      body: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de pesquisa
                  _BarraPesquisa(),
                  const SizedBox(height: 16),

                  // Dois cards de eventos próximos lado a lado
                  Row(
                    children: [
                      Expanded(
                        child: EventoProximo(
                          data: '24/10',
                          descricao: 'Dia de vacinação',
                          onTap: () => Navigator.pushNamed(
                              context, Rotas.registroVacina),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: EventoProximo(
                          data: '24/10',
                          descricao: 'Dia de vacinação',
                          onTap: () => Navigator.pushNamed(
                              context, Rotas.registroVacina),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Carrossel de resumo (Estoque / Leitões / Cobertura)
                  const ResumodeEventos(
                    estoqueKg: 80,
                    rebanho: 140,
                    leitoes: 45,
                    dataRegistro: '40/10',
                    percentualRacao: 0.88,
                    nascimentos: 12,
                    desmames: 8,
                    mortalidade: 2,
                    emCobertura: 5,
                    gestantes: 7,
                    emAleitamento: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFloatingNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          // Ícone do porquinho (1) abre o cadastro de eventos / vacinação
          if (index == 1) {
            Navigator.pushNamed(context, Rotas.registroVacina);
            return;
          }
          // Ícone de documento (2) abre o estoque de ração
          if (index == 2) {
            Navigator.pushNamed(context, Rotas.estoqueRacao);
            return;
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

/// Cabeçalho verde com foto de perfil, saudação e o porquinho.
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  /// Nome a exibir: usa o displayName (contas Google), senão o trecho do
  /// email antes do @, senão um fallback genérico.
  String _primeiroNome(User? user) {
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName.split(' ').first;

    final email = user?.email ?? '';
    if (email.contains('@')) {
      final usuario = email.split('@').first;
      if (usuario.isNotEmpty) {
        return usuario[0].toUpperCase() + usuario.substring(1);
      }
    }
    return 'Produtor';
  }

  @override
  Widget build(BuildContext context) {
    // userChanges() emite em login/logout E em updates de perfil (nome/foto),
    // então o header reflete o nome assim que ele é gravado.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        return _conteudo(_primeiroNome(user), user?.photoURL);
      },
    );
  }

  Widget _conteudo(String nome, String? foto) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5ED84F), Color(0xFF3BA135)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              // Foto de perfil
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: foto != null ? NetworkImage(foto) : null,
                child: foto == null
                    ? const Icon(Icons.person,
                        color: Color(0xFF3BA135), size: 30)
                    : null,
              ),
              const SizedBox(width: 12),
              // Saudação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Olá $nome!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'o que vamos fazer hoje?',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Porquinho
              SizedBox(
                height: 64,
                width: 64,
                child: Image.asset(
                  'lib/assets/widgets/itens/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo de busca arredondado.
class _BarraPesquisa extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'pesquisar',
        hintStyle: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black38,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black26),
        ),
      ),
    );
  }
}