import 'package:flutter/material.dart';
import 'logout_button.dart';
import 'itens/foto_perfil.dart';

// HideBar é o painel lateral deslizante (drawer customizado).
// Ele envolve qualquer tela filha e adiciona um botão (⋮) no canto superior
// esquerdo que abre o painel com as opções do usuário.
class HideBar extends StatefulWidget {
  final Widget child;       // tela principal que fica atrás do painel
  final String userEmail;   // email exibido no painel
  final String? photoUrl;   // URL da foto de perfil (vinda do Google); pode ser null
  final VoidCallback onLogout;
  final VoidCallback? onEditarPerfil;
  final VoidCallback? onAtividades;
  final VoidCallback? onConfiguracoes;
  final VoidCallback? onGerenciarDados;
  final VoidCallback? onExportarDados;

  // Quando false, o botão (⋮) interno não é exibido — útil quando a tela já
  // tem seu próprio gatilho e abre o painel via GlobalKey<HideBarState>.open().
  final bool showTrigger;

  const HideBar({
    super.key,
    required this.child,
    required this.userEmail,
    this.photoUrl,
    required this.onLogout,
    this.onEditarPerfil,
    this.onAtividades,
    this.onConfiguracoes,
    this.onGerenciarDados,
    this.onExportarDados,
    this.showTrigger = true,
  });

  @override
  State<HideBar> createState() => HideBarState();
}

// SingleTickerProviderStateMixin é necessário para o AnimationController
// que controla a animação de deslizamento do painel.
class HideBarState extends State<HideBar> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  // Largura do painel: 72% da largura da tela
  static const double _panelWidthFactor = 0.72;

  @override
  void initState() {
    super.initState();

    // Controla a duração da animação de abrir/fechar
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // O painel começa fora da tela (Offset -1.0 = totalmente à esquerda)
    // e desliza até Offset.zero (posição normal)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Abre o painel a partir de fora (via `GlobalKey<HideBarState>().open()`).
  void open() => _open();

  void _open() {
    // Tira o foco do que estiver ativo (ex.: barra de pesquisa) antes de
    // abrir: fecha o teclado e o painel de resultados, que é desenhado no
    // Overlay do app e ficaria sobreposto à sidebar.
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isOpen = true);
    _controller.forward(); // executa a animação de entrada
  }

  void _close() {
    // Executa a animação de saída e só atualiza _isOpen quando terminar,
    // para não sumir o painel antes da animação completar
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Altura da barra de status do sistema (notch, hora, rede...)
    final topPadding = MediaQuery.of(context).padding.top;

    // Stack empilha a tela principal, a barreira escura e o painel lateral
    return Stack(
      children: [
        // Tela principal (HomeScreen, etc.) fica na camada de baixo
        widget.child,

        // Barreira escura semitransparente — aparece atrás do painel.
        // Ao tocar nela, fecha o painel.
        if (_isOpen)
          GestureDetector(
            onTap: _close,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),

        // Painel lateral animado — desliza da esquerda
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildPanel(context),
          ),
        ),

        // Botão (⋮) que abre o painel, posicionado sobre o cabeçalho verde.
        // Fica oculto enquanto o painel está aberto.
        if (!_isOpen && widget.showTrigger)
          Positioned(
            top: topPadding + 55, // alinha visualmente com o título do AppBar
            left: 16,
            child: GestureDetector(
              onTap: _open,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Constrói o conteúdo do painel lateral
  Widget _buildPanel(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
      width: MediaQuery.of(context).size.width * _panelWidthFactor,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(5, 0)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botão X para fechar o painel
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _close,
                  child: const Icon(Icons.close, color: Color(0xFFEF5350), size: 26),
                ),
              ),

              const SizedBox(height: 8),

              // Foto de perfil em círculo: a enviada no app (Firestore) tem
              // prioridade; senão a da conta (photoUrl); senão o ícone.
              FotoPerfil(radius: 36, photoUrl: widget.photoUrl),

              const SizedBox(height: 10),

              // Email do usuário logado
              Text(
                widget.userEmail,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 12),

              // Campo para o usuário definir um nome/apelido de exibição
              TextField(
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Itens de navegação do menu
              _menuItem('Editar perfil', widget.onEditarPerfil),
              _menuItem('Atividades', widget.onAtividades),
              _menuItem('Configurações', widget.onConfiguracoes),
              _menuItem('Gerenciar dados', widget.onGerenciarDados),
              _menuItem('Exportar dados', widget.onExportarDados),

              // Empurra o botão de logout para o rodapé do painel
              const Spacer(),

              LogoutButton(onPressed: widget.onLogout),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Cria um item de menu com linha de toque.
  // Se o callback não foi fornecido, apenas fecha o painel ao tocar.
  Widget _menuItem(String label, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap ?? _close,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
