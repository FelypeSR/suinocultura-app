import 'dart:async';

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
import 'package:gspr/models/ninhada_model.dart';
import 'package:gspr/services/ninhada_service.dart';
import 'package:gspr/models/evento_model.dart';
import 'package:gspr/services/evento_service.dart';
import 'package:gspr/services/relatorio_pdf_service.dart'; // Relatório em PDF
import 'package:gspr/assets/widgets/hide_bar.dart'; // Painel lateral
import 'package:gspr/assets/widgets/itens/foto_perfil.dart'; // Avatar do usuário

/// Tela inicial do app (home): cabeçalho com saudação, busca,
/// eventos próximos e o carrossel de resumo. Abaixo, a navbar flutuante.
class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  int _currentIndex = 0;

  // Streams que alimentam o carrossel de resumo (estoque, rebanho e ninhadas).
  // Tudo é derivado em tempo real do Firestore — nada de valores fixos.
  final _racoes = RacaoService().listar();
  final _animais = AnimalService().listar();
  final _ninhadas = NinhadaService().listar();
  final _eventos = EventoService().listar();

  // Controla a abertura do painel lateral (HideBar) a partir do header.
  final _hideBarKey = GlobalKey<HideBarState>();

  // Evita disparar duas gerações de PDF ao mesmo tempo.
  bool _gerandoPdf = false;

  /// Reúne rebanho, ninhadas e ração e abre a pré-visualização do relatório
  /// em PDF (de onde dá para imprimir, salvar ou compartilhar).
  Future<void> _gerarRelatorioPdf() async {
    if (_gerandoPdf) return;
    setState(() => _gerandoPdf = true);

    final produtor = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email ??
        '';

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Gerando relatório...')),
    );

    try {
      await RelatorioPdfService().gerarEVisualizar(produtor: produtor);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erro ao gerar o relatório: $e')),
      );
    } finally {
      if (mounted) setState(() => _gerandoPdf = false);
    }
  }

  /// Formata uma data como dd/MM (ex.: 24/10).
  String _formatarDiaMes(DateTime d) => fmtDiaMes(d);

  /// Descrição curta de um evento para o card (usa o tipo de vacina quando há).
  String _descricaoEvento(EventoModel e) => descricaoEvento(e);

  /// Monta o carrossel de resumo a partir das listas do Firestore. Todos os
  /// números são calculados aqui; o card de anotações reúne as observações
  /// de TODOS os formulários (estoque, animal, ninhada e vacina/evento).
  Widget _buildResumo(
    List<RacaoModel> racoes,
    List<AnimalModel> animais,
    List<NinhadaModel> ninhadas,
    List<EventoModel> eventos,
  ) {
    // Anotações: observações salvas em cada cadastro (reunidas de todos os
    // formulários — estoque, animal, ninhada e vacina/evento).
    final anotacoes = coletarAnotacoes(racoes, animais, ninhadas, eventos);

    // Estoque total em kg: somamos o saldo de todas as entradas em kg
    // (sacos não entram).
    final racoesKg = racoes.where((r) => r.unidade == 'kg');
    final estoqueKg = racoesKg.fold<double>(0, (s, r) => s + r.saldoAtual);

    // Gauge de %: considera só as entradas no modo automático (as que têm
    // consumo/dia em kg). Como saldoAtual desconta o consumo diário, a %
    // cai sozinha conforme a ração é consumida.
    final racoesAuto = racoes.where(
        (r) => r.unidade == 'kg' && r.modoConsumo == 'automatico');
    final saldoAuto = racoesAuto.fold<double>(0, (s, r) => s + r.saldoAtual);
    final totalAuto = racoesAuto.fold<double>(0, (s, r) => s + r.quantidade);
    final percentual = totalAuto <= 0
        ? 0.0
        : (saldoAuto / totalAuto).clamp(0.0, 1.0).toDouble();

    // Movimentação de leitões vem das ninhadas.
    final nascimentos = ninhadas.fold<int>(0, (s, n) => s + n.nascidos);
    final desmames = ninhadas.fold<int>(0, (s, n) => s + n.desmamados);
    final mortalidade = ninhadas.fold<int>(0, (s, n) => s + n.mortos);
    final leitoes = ninhadas.fold<int>(0, (s, n) => s + n.vivos);

    // Data do registro de estoque mais recente (lista ordenada por
    // criadoEm desc).
    final dataRegistro = racoes.isEmpty
        ? '--/--'
        : _formatarDiaMes(racoes.first.criadoEm);

    // ── Card Cobertura (derivado dos animais/ninhadas) ──────────────────────
    final hoje = DateTime.now();
    final femeas = animais.where((a) => a.isFemea);

    // Gestantes: fêmeas com status 'gestante' (exato).
    final gestantes = femeas.where((a) => a.gestante).length;

    // Em aleitamento: mães com ninhada recente (parto nos últimos 35 dias) e
    // leitões ainda não totalmente desmamados. Conta mães distintas.
    final maesAleitando = ninhadas
        .where((n) =>
            hoje.difference(n.data).inDays <= 35 && n.desmamados < n.vivos)
        .map((n) => n.maeCodigo)
        .toSet();
    final emAleitamento = maesAleitando.length;

    // Em cobertura: matrizes disponíveis — fêmeas ativas em idade reprodutiva
    // (≥210 dias), que não estão gestantes nem amamentando.
    final emCobertura = femeas
        .where((a) =>
            a.status == 'ativo' &&
            a.podeCobertura &&
            !maesAleitando.contains(a.codigo))
        .length;

    return ResumodeEventos(
      estoqueKg: estoqueKg,
      // Mortos ficam fora do rebanho (vendidos seguem contando, como antes).
      rebanho: animais.where((a) => !a.morto).length,
      leitoes: leitoes,
      dataRegistro: dataRegistro,
      percentualRacao: percentual,
      nascimentos: nascimentos,
      desmames: desmames,
      mortalidade: mortalidade,
      emCobertura: emCobertura,
      gestantes: gestantes,
      emAleitamento: emAleitamento,
      anotacoes: anotacoes,
    );
  }

  /// Monta os dois cards de "Eventos Próximos" a partir dos eventos salvos:
  /// pega os de hoje em diante, ordenados por data, e preenche até 2 slots.
  /// Slots sem evento viram um placeholder que abre o cadastro de vacinação.
  Widget _cardsEventos(List<EventoModel> eventos) {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final proximos = eventos
        .where((e) => !e.data.isBefore(inicioHoje))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    Widget slot(int i) {
      if (i < proximos.length) {
        final e = proximos[i];
        return EventoProximo(
          data: _formatarDiaMes(e.data),
          ano: e.data.year.toString(),
          descricao: _descricaoEvento(e),
          onTap: () => Navigator.pushNamed(context, Rotas.registroVacina),
        );
      }
      return _EventoVazio(
        onTap: () => Navigator.pushNamed(context, Rotas.registroVacina),
      );
    }

    return Row(
      children: [
        Expanded(child: slot(0)),
        const SizedBox(width: 12),
        Expanded(child: slot(1)),
      ],
    );
  }

  /// Ações rápidas do botão central da navbar: visualizar o rebanho e as
  /// vacinas, cadastrar suíno ou ração.
  void _abrirAcoesRapidas() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Adicionar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.visibility_outlined, color: Color(0xFF2E7D32)),
              title: const Text('Visualizar rebanho'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.visualizarRebanho);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.vaccines_outlined, color: Color(0xFF2E7D32)),
              title: const Text('Visualizar vacinas'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.visualizarVacinas);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pets, color: Color(0xFF2E7D32)),
              title: const Text('Cadastrar suíno'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.cadastroAnimal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_note, color: Color(0xFF2E7D32)),
              title: const Text('Editar suíno'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.editarAnimal);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.inventory_2, color: Color(0xFF2E7D32)),
              title: const Text('Adicionar ração'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.cadastroRacao);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Menu rápido de cadastros (animal e ninhada), aberto pelo painel lateral.
  void _abrirMenuCadastros() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Cadastrar',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.pets, color: Color(0xFF2E7D32)),
              title: const Text('Animal'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.cadastroAnimal);
              },
            ),
            ListTile(
              leading: const Icon(Icons.child_friendly,
                  color: Color(0xFF2E7D32)),
              title: const Text('Ninhada'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.pushNamed(context, Rotas.cadastroNinhada);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return HideBar(
      key: _hideBarKey,
      showTrigger: false, // usamos o botão de 3 pontinhos do header
      userEmail: user?.email ?? '',
      photoUrl: user?.photoURL,
      onLogout: () => FirebaseAuth.instance.signOut(),
      onEditarPerfil: () =>
          Navigator.pushNamed(context, Rotas.editarPerfil),
      onAtividades: () {},
      onConfiguracoes: () =>
          Navigator.pushNamed(context, Rotas.configuracoes),
      onGerenciarDados: _abrirMenuCadastros,
      onExportarDados: _gerarRelatorioPdf,
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBody: true, // navbar flutua sobre o conteúdo
        // O teclado sobrepõe o conteúdo em vez de encolher o corpo: evita o
        // overflow do carrossel (Expanded) ao focar na barra de pesquisa.
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            _HomeHeader(onMenu: () => _hideBarKey.currentState?.open()),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de pesquisa global (funções, animais, eventos e
                  // anotações)
                  _BuscaGlobal(
                    racoes: _racoes,
                    animais: _animais,
                    ninhadas: _ninhadas,
                    eventos: _eventos,
                    onGerarRelatorio: _gerarRelatorioPdf,
                  ),
                  const SizedBox(height: 28),

                  // Dois cards de eventos próximos lado a lado, vindos do
                  // Firestore (os mais próximos por data). Sem eventos, mostram
                  // um placeholder que leva ao cadastro de vacinação.
                  StreamBuilder<List<EventoModel>>(
                    stream: _eventos,
                    builder: (context, eventoSnap) {
                      return _cardsEventos(
                          eventoSnap.data ?? const <EventoModel>[]);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Carrossel de resumo — preenche o espaço restante até a navbar.
                  // Todos os números são calculados a partir do que está
                  // gravado no Firestore; sem dados, o resumo aparece zerado.
                  Expanded(
                    child: StreamBuilder<List<RacaoModel>>(
                      stream: _racoes,
                      builder: (context, racaoSnap) =>
                          StreamBuilder<List<AnimalModel>>(
                        stream: _animais,
                        builder: (context, animalSnap) =>
                            StreamBuilder<List<NinhadaModel>>(
                          stream: _ninhadas,
                          builder: (context, ninhadaSnap) =>
                              StreamBuilder<List<EventoModel>>(
                            stream: _eventos,
                            builder: (context, eventoSnap) => _buildResumo(
                              racaoSnap.data ?? const <RacaoModel>[],
                              animalSnap.data ?? const <AnimalModel>[],
                              ninhadaSnap.data ?? const <NinhadaModel>[],
                              eventoSnap.data ?? const <EventoModel>[],
                            ),
                          ),
                        ),
                      ),
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
          // Botão de ação central (1): abre as ações rápidas
          // (cadastrar suíno / adicionar ração).
          if (index == 1) {
            _abrirAcoesRapidas();
            return;
          }
          // Ícone de documento (2) gera o relatório da granja em PDF
          if (index == 2) {
            _gerarRelatorioPdf();
            return;
          }
          // Ícone de gráfico (3) abre o estoque de ração
          if (index == 3) {
            Navigator.pushNamed(context, Rotas.estoqueRacao);
            return;
          }
          // Engrenagem (4) abre a tela de configurações
          if (index == 4) {
            Navigator.pushNamed(context, Rotas.configuracoes);
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
              // Foto de perfil (a enviada no app tem prioridade; senão a da
              // conta Google; senão o ícone genérico).
              FotoPerfil(radius: 42, photoUrl: foto),
              const SizedBox(width: 16),
              // Saudação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Olá $nome!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'o que vamos fazer hoje?',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
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

/// Card placeholder quando não há evento para o slot. Mantém o visual dos
/// cards de evento e, ao tocar, abre o cadastro de vacinação.
class _EventoVazio extends StatelessWidget {
  final VoidCallback? onTap;

  const _EventoVazio({this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final onContainer = colors.onPrimaryContainer;

    return Material(
      color: colors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Eventos Próximos',
                style: TextStyle(
                  color: onContainer,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '—',
                    style: TextStyle(
                      color: onContainer,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add,
                        color: colors.onPrimary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.event_available,
                      color: onContainer.withValues(alpha: 0.7), size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Sem eventos',
                      style: TextStyle(color: onContainer, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formata uma data como dd/MM (ex.: 24/10).
String fmtDiaMes(DateTime d) {
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}

/// Descrição curta de um evento (usa o tipo de vacina quando há).
String descricaoEvento(EventoModel e) {
  if (e.tipoVacina.trim().isNotEmpty) return 'Vacina: ${e.tipoVacina.trim()}';
  return 'Dia de vacinação';
}

/// Reúne as observações de TODOS os formulários (estoque, animal, ninhada e
/// vacina/evento) numa única lista de anotações. Usado tanto pelo carrossel de
/// resumo quanto pela busca global.
List<Anotacao> coletarAnotacoes(
  List<RacaoModel> racoes,
  List<AnimalModel> animais,
  List<NinhadaModel> ninhadas,
  List<EventoModel> eventos,
) {
  final anotacoes = <Anotacao>[];
  for (final r in racoes) {
    if (r.observacao.trim().isNotEmpty) {
      anotacoes.add(
          Anotacao(origem: 'Estoque • ${r.tipo}', texto: r.observacao.trim()));
    }
  }
  for (final a in animais) {
    if (a.saude.trim().isNotEmpty) {
      anotacoes
          .add(Anotacao(origem: 'Animal ${a.codigo}', texto: a.saude.trim()));
    }
  }
  for (final n in ninhadas) {
    if (n.observacao.trim().isNotEmpty) {
      anotacoes.add(Anotacao(
          origem: 'Ninhada • mãe ${n.maeCodigo}', texto: n.observacao.trim()));
    }
  }
  for (final e in eventos) {
    if (e.observacoes.trim().isNotEmpty) {
      final origem = e.tipoVacina.trim().isNotEmpty
          ? 'Vacina • ${e.tipoVacina.trim()}'
          : 'Vacina • ${fmtDiaMes(e.data)}';
      anotacoes.add(Anotacao(origem: origem, texto: e.observacoes.trim()));
    }
  }
  return anotacoes;
}

/// Um resultado da busca: pode ser uma função/tela do app ou um dado
/// (animal, evento, anotação). Ao tocar, executa [abrir].
class _Resultado {
  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final void Function(BuildContext context) abrir;
  const _Resultado({
    required this.titulo,
    this.subtitulo,
    required this.icone,
    required this.abrir,
  });
}

/// Um grupo de resultados da busca (ex.: "Funções", "Animais").
class _Secao {
  final String titulo;
  final List<_Resultado> itens;
  const _Secao(this.titulo, this.itens);
}

/// Barra de busca global: pesquisa as funções/telas do app e também os dados —
/// animais (por código ou raça), eventos/vacinas e anotações. Ao digitar,
/// mostra os resultados agrupados num painel logo abaixo do campo; tocar em um
/// resultado abre a tela correspondente (ou exibe o texto, no caso de anotação).
class _BuscaGlobal extends StatefulWidget {
  final Stream<List<RacaoModel>> racoes;
  final Stream<List<AnimalModel>> animais;
  final Stream<List<NinhadaModel>> ninhadas;
  final Stream<List<EventoModel>> eventos;

  /// Ação da função "Gerar relatório PDF" (vive no state da home).
  final VoidCallback onGerarRelatorio;

  const _BuscaGlobal({
    required this.racoes,
    required this.animais,
    required this.ninhadas,
    required this.eventos,
    required this.onGerarRelatorio,
  });

  @override
  State<_BuscaGlobal> createState() => _BuscaGlobalState();
}

class _BuscaGlobalState extends State<_BuscaGlobal> {
  static const _verde = Color(0xFF2E7D32);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  // Últimos dados recebidos das streams, para filtrar a busca em memória.
  final _subs = <StreamSubscription<dynamic>>[];
  List<RacaoModel> _dadosRacoes = const [];
  List<AnimalModel> _dadosAnimais = const [];
  List<NinhadaModel> _dadosNinhadas = const [];
  List<EventoModel> _dadosEventos = const [];

  // Funções/telas fixas que a busca conhece.
  late final List<_Resultado> _funcoes = [
    _Resultado(
        titulo: 'Visualizar rebanho',
        icone: Icons.visibility_outlined,
        abrir: (c) => Navigator.pushNamed(c, Rotas.visualizarRebanho)),
    _Resultado(
        titulo: 'Visualizar vacinas',
        icone: Icons.vaccines_outlined,
        abrir: (c) => Navigator.pushNamed(c, Rotas.visualizarVacinas)),
    _Resultado(
        titulo: 'Cadastrar suíno',
        icone: Icons.add_circle_outline,
        abrir: (c) => Navigator.pushNamed(c, Rotas.cadastroAnimal)),
    _Resultado(
        titulo: 'Editar suíno',
        icone: Icons.edit_note,
        abrir: (c) => Navigator.pushNamed(c, Rotas.editarAnimal)),
    _Resultado(
        titulo: 'Cadastrar ninhada',
        icone: Icons.pets,
        abrir: (c) => Navigator.pushNamed(c, Rotas.cadastroNinhada)),
    _Resultado(
        titulo: 'Registrar vacinação',
        icone: Icons.vaccines_outlined,
        abrir: (c) => Navigator.pushNamed(c, Rotas.registroVacina)),
    _Resultado(
        titulo: 'Estoque de ração',
        icone: Icons.inventory_2,
        abrir: (c) => Navigator.pushNamed(c, Rotas.estoqueRacao)),
    _Resultado(
        titulo: 'Cadastrar ração',
        icone: Icons.add_box_outlined,
        abrir: (c) => Navigator.pushNamed(c, Rotas.cadastroRacao)),
    _Resultado(
        titulo: 'Cadastrar usuário',
        icone: Icons.person_add_alt,
        abrir: (c) => Navigator.pushNamed(c, Rotas.cadastroUsuario)),
    _Resultado(
        titulo: 'Gerar relatório PDF',
        icone: Icons.picture_as_pdf_outlined,
        abrir: (_) => widget.onGerarRelatorio()),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_atualizar);
    _focus.addListener(_atualizar);
    _subs.add(widget.racoes.listen((v) => _receber(() => _dadosRacoes = v)));
    _subs.add(widget.animais.listen((v) => _receber(() => _dadosAnimais = v)));
    _subs
        .add(widget.ninhadas.listen((v) => _receber(() => _dadosNinhadas = v)));
    _subs.add(widget.eventos.listen((v) => _receber(() => _dadosEventos = v)));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Guarda os novos dados e reavalia o painel (sem abri-lo se o campo estiver
  /// sem foco).
  void _receber(VoidCallback aplicar) {
    aplicar();
    if (mounted) _atualizar();
  }

  /// Minúsculas + sem acentos, para a busca ignorar acentuação.
  String _normaliza(String s) {
    s = s.toLowerCase();
    const com = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const sem = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < com.length; i++) {
      s = s.replaceAll(com[i], sem[i]);
    }
    return s;
  }

  String _sexoLabel(AnimalModel a) => a.isMacho ? 'Macho' : 'Fêmea';

  String _statusLabel(AnimalModel a) {
    switch (a.status) {
      case 'gestante':
        return 'Gestante';
      case 'vendido':
        return 'Vendido';
      case 'doente':
        return 'Em tratamento';
      case 'morto':
        return 'Perda';
      default:
        return 'Ativo';
    }
  }

  /// Resultados agrupados por categoria; vazio quando o campo está em branco.
  List<_Secao> get _secoes {
    final q = _normaliza(_controller.text.trim());
    if (q.isEmpty) return const [];

    final secoes = <_Secao>[];

    // Funções/telas.
    final funcoes =
        _funcoes.where((f) => _normaliza(f.titulo).contains(q)).toList();
    if (funcoes.isNotEmpty) secoes.add(_Secao('Funções', funcoes));

    // Animais por código ou raça.
    final animais = _dadosAnimais
        .where((a) =>
            _normaliza(a.codigo).contains(q) || _normaliza(a.raca).contains(q))
        .take(8)
        .map((a) => _Resultado(
              titulo: a.codigo,
              subtitulo: a.raca.trim().isEmpty
                  ? '${_sexoLabel(a)} • ${_statusLabel(a)}'
                  : '${_sexoLabel(a)} • ${a.raca.trim()} • ${_statusLabel(a)}',
              icone: Icons.pets,
              abrir: (c) => Navigator.pushNamed(c, Rotas.editarAnimal),
            ))
        .toList();
    if (animais.isNotEmpty) secoes.add(_Secao('Animais', animais));

    // Eventos/vacinas por descrição ou data.
    final eventos = _dadosEventos
        .where((e) => _normaliza(
                '${descricaoEvento(e)} ${fmtDiaMes(e.data)} ${e.data.year}')
            .contains(q))
        .take(8)
        .map((e) => _Resultado(
              titulo: descricaoEvento(e),
              subtitulo: '${fmtDiaMes(e.data)}/${e.data.year}',
              icone: Icons.vaccines_outlined,
              abrir: (c) => Navigator.pushNamed(c, Rotas.registroVacina),
            ))
        .toList();
    if (eventos.isNotEmpty) secoes.add(_Secao('Eventos', eventos));

    // Anotações (observações reunidas de todos os formulários).
    final anotacoes = coletarAnotacoes(
            _dadosRacoes, _dadosAnimais, _dadosNinhadas, _dadosEventos)
        .where((a) => _normaliza('${a.origem} ${a.texto}').contains(q))
        .take(8)
        .map((a) => _Resultado(
              titulo: a.texto,
              subtitulo: a.origem,
              icone: Icons.sticky_note_2_outlined,
              abrir: (c) => _mostrarAnotacao(c, a),
            ))
        .toList();
    if (anotacoes.isNotEmpty) secoes.add(_Secao('Anotações', anotacoes));

    return secoes;
  }

  /// Anotação não tem tela própria: mostramos o texto completo num diálogo.
  void _mostrarAnotacao(BuildContext context, Anotacao a) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a.origem),
        content: Text(a.texto),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _atualizar() {
    final mostrar = _focus.hasFocus && _secoes.isNotEmpty;
    if (mostrar) {
      _portal.show();
    } else {
      _portal.hide();
    }
    if (mounted) setState(() {});
  }

  void _selecionar(_Resultado r) {
    _controller.clear();
    _focus.unfocus();
    _portal.hide();
    r.abrir(context);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) {
          return Align(
            alignment: Alignment.topLeft,
            child: CompositedTransformFollower(
              link: _link,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: _painelResultados(),
            ),
          );
        },
        child: TextField(
          controller: _controller,
          focusNode: _focus,
          decoration: const InputDecoration(
            hintText: 'pesquisar',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _painelResultados() {
    // Acompanha a largura do campo (mesma da coluna da home).
    final largura = MediaQuery.of(context).size.width - 32;
    final secoes = _secoes;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: largura,
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            for (final s in secoes) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                child: Text(
                  s.titulo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              for (final r in s.itens)
                ListTile(
                  dense: true,
                  leading: Icon(r.icone, color: _verde),
                  title: Text(
                    r.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: r.subtitulo == null
                      ? null
                      : Text(
                          r.subtitulo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () => _selecionar(r),
                ),
            ],
          ],
        ),
      ),
    );
  }
}