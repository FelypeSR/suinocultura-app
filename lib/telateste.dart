import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gspr/assets/widgets/itens/navbar.dart'; // NavBar
import 'package:gspr/assets/widgets/itens/evento_proximo.dart'; // Card de evento
import 'package:gspr/assets/widgets/itens/resumo_de_eventos.dart'; // Carrossel de resumo
import 'package:gspr/routes.dart'; // Rotas nomeadas
import 'package:gspr/models/racao_model.dart';
import 'package:gspr/services/racao_service.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/services/animal_service.dart';
import 'package:gspr/assets/widgets/hide_bar.dart'; // Painel lateral

/// Tela inicial do app (home): cabeçalho com saudação, busca,
/// eventos próximos e o carrossel de resumo. Abaixo, a navbar flutuante.
class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _currentIndex = 0;

  // Streams das anotações exibidas no carrossel (estoque + animais).
  final _racoes = RacaoService().listar();
  final _animais = AnimalService().listar();

  // Controla a abertura do painel lateral (HideBar) a partir do header.
  final _hideBarKey = GlobalKey<HideBarState>();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return HideBar(
      key: _hideBarKey,
      showTrigger: false, // usamos o botão de 3 pontinhos do header
      userEmail: user?.email ?? '',
      photoUrl: user?.photoURL,
      onLogout: () => FirebaseAuth.instance.signOut(),
      onEditarPerfil: () {},
      onAtividades: () {},
      onConfiguracoes: () {},
      onGerenciarDados: () {},
      onExportarDados: () {},
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true, // navbar flutua sobre o conteúdo
        body: Column(
          children: [
            _HomeHeader(onMenu: () => _hideBarKey.currentState?.open()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de pesquisa
                  _BarraPesquisa(),
                  const SizedBox(height: 28),

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

                  // Carrossel de resumo — preenche o espaço restante até a navbar
                  Expanded(
                    child: StreamBuilder<List<RacaoModel>>(
                      stream: _racoes,
                      builder: (context, racaoSnap) {
                        return StreamBuilder<List<AnimalModel>>(
                          stream: _animais,
                          builder: (context, animalSnap) {
                            final anotacoes = <Anotacao>[];
                            for (final r
                                in racaoSnap.data ?? const <RacaoModel>[]) {
                              if (r.observacao.trim().isNotEmpty) {
                                anotacoes.add(Anotacao(
                                  origem: 'Estoque • ${r.tipo}',
                                  texto: r.observacao.trim(),
                                ));
                              }
                            }
                            for (final a
                                in animalSnap.data ?? const <AnimalModel>[]) {
                              if (a.saude.trim().isNotEmpty) {
                                anotacoes.add(Anotacao(
                                  origem: 'Animal ${a.codigo}',
                                  texto: a.saude.trim(),
                                ));
                              }
                            }
                            return ResumodeEventos(
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
                              anotacoes: anotacoes,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // Espaço para a navbar flutuante não cobrir os dots
                  const SizedBox(height: 80),
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
      ),
    );
  }
}

/// Cabeçalho verde com foto de perfil, saudação e o porquinho.
class _HomeHeader extends StatelessWidget {
  final VoidCallback onMenu;

  const _HomeHeader({required this.onMenu});

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
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 56),
          child: Stack(
            children: [
              Row(
            children: [
              // Foto de perfil
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                backgroundImage: foto != null ? NetworkImage(foto) : null,
                child: foto == null
                    ? const Icon(Icons.person,
                        color: Color(0xFF3BA135), size: 46)
                    : null,
              ),
              const SizedBox(width: 16),
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
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'o que vamos fazer hoje?',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              // Porquinho (deslocado para baixo, próximo à base do header)
              Transform.translate(
                offset: const Offset(0, 24),
                child: SizedBox(
                  height: 96,
                  width: 96,
                  child: Image.asset(
                    'lib/assets/widgets/itens/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
              ),
              // Botão de 3 pontinhos que abre o painel lateral (HideBar)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onMenu,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
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
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
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