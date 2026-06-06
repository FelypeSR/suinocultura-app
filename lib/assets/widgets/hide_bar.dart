import 'package:flutter/material.dart';
import 'logout_button.dart';

class HideBar extends StatefulWidget {
  final Widget child;
  final String userEmail;
  final VoidCallback onLogout;
  final VoidCallback? onEditarPerfil;
  final VoidCallback? onAtividades;
  final VoidCallback? onConfiguracoes;
  final VoidCallback? onGerenciarDados;
  final VoidCallback? onExportarDados;

  const HideBar({
    super.key,
    required this.child,
    required this.userEmail,
    required this.onLogout,
    this.onEditarPerfil,
    this.onAtividades,
    this.onConfiguracoes,
    this.onGerenciarDados,
    this.onExportarDados,
  });

  @override
  State<HideBar> createState() => _HideBarState();
}

class _HideBarState extends State<HideBar> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  static const double _panelWidthFactor = 0.72;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
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

  void _open() {
    setState(() => _isOpen = true);
    _controller.forward();
  }

  void _close() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isOpen = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,

        // Barreira escura — toque fora fecha o painel
        if (_isOpen)
          GestureDetector(
            onTap: _close,
            child: Container(color: Colors.black.withOpacity(0.35)),
          ),

        // Painel lateral deslizante
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildPanel(context),
          ),
        ),

        // Botão de trigger (⋮) posicionado no cabeçalho verde
        if (!_isOpen)
          Positioned(
            top: topPadding + 55,
            left: 16,
            child: GestureDetector(
              onTap: _open,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
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

  Widget _buildPanel(BuildContext context) {
    return Container(
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
              // Botão fechar
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _close,
                  child: const Icon(Icons.close, color: Color(0xFFEF5350), size: 26),
                ),
              ),

              const SizedBox(height: 8),

              // Email do usuário
              Text(
                widget.userEmail,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 12),

              // Campo editável (nome / apelido)
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

              // Itens de menu
              _menuItem('Editar perfil', widget.onEditarPerfil),
              _menuItem('Atividades', widget.onAtividades),
              _menuItem('Configurações', widget.onConfiguracoes),
              _menuItem('Gerenciar dados', widget.onGerenciarDados),
              _menuItem('Exportar dados', widget.onExportarDados),

              const Spacer(),

              // Botão de logout
              LogoutButton(onPressed: widget.onLogout),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

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