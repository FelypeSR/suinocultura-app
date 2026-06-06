import 'package:flutter/material.dart';

class ResumodeEventos extends StatefulWidget {
  // --- Estoque / Ração ---
  final double estoqueKg;
  final int rebanho;
  final int leitoes;
  final String dataRegistro;
  final double percentualRacao; // 0.0 a 1.0

  // --- Controle de leitões ---
  final int nascimentos;
  final int desmames;
  final int mortalidade;

  // --- Período de cobertura ---
  final int emCobertura;
  final int gestantes;
  final int emAleitamento;

  const ResumodeEventos({
    super.key,
    this.estoqueKg = 0,
    this.rebanho = 0,
    this.leitoes = 0,
    this.dataRegistro = '--/--',
    this.percentualRacao = 0.0,
    this.nascimentos = 0,
    this.desmames = 0,
    this.mortalidade = 0,
    this.emCobertura = 0,
    this.gestantes = 0,
    this.emAleitamento = 0,
  });

  @override
  State<ResumodeEventos> createState() => _ResumodeEventosState();
}

class _ResumodeEventosState extends State<ResumodeEventos> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF388E3C), Color(0xFF69F0AE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const _cardDecoration = BoxDecoration(
    gradient: _gradient,
    borderRadius: BorderRadius.all(Radius.circular(16)),
    boxShadow: [
      BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
    ],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 180,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _cardEstoque(),
              _cardLeitoes(),
              _cardCobertura(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildDots(3),
      ],
    );
  }

  // ── Card 1: Estoque de ração ────────────────────────────────────────────────
  Widget _cardEstoque() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalho('RESUMO'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoTexto('Estoque: ${widget.estoqueKg.toStringAsFixed(0)} kgs.'),
                  const SizedBox(height: 6),
                  _infoTexto('Rebanho: ${widget.rebanho}.'),
                  const SizedBox(height: 6),
                  _infoTexto('Leitões: ${widget.leitoes}.'),
                  const SizedBox(height: 6),
                  _infoTexto('Registro: ${widget.dataRegistro}.'),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Estoque de ração',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: widget.percentualRacao,
                          strokeWidth: 6,
                          backgroundColor: Colors.black26,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(widget.percentualRacao * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card 2: Controle de leitões ─────────────────────────────────────────────
  Widget _cardLeitoes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalho('LEITÕES'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(Icons.child_care, '${widget.nascimentos}', 'Nascimentos'),
              _statCard(Icons.directions_run, '${widget.desmames}', 'Desmames'),
              _statCard(Icons.warning_amber_rounded, '${widget.mortalidade}', 'Mortalidade'),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Total no plantel: ${widget.leitoes}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 3: Período de cobertura ────────────────────────────────────────────
  Widget _cardCobertura() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalho('COBERTURA'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCard(Icons.favorite, '${widget.emCobertura}', 'Em cobertura'),
              _statCard(Icons.pregnant_woman, '${widget.gestantes}', 'Gestantes'),
              _statCard(Icons.child_friendly, '${widget.emAleitamento}', 'Aleitamento'),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              'Rebanho total: ${widget.rebanho}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Widget _cabecalho(String titulo) {
    return Row(
      children: [
        const Icon(Icons.receipt_long, color: Colors.black87, size: 16),
        const SizedBox(width: 6),
        Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '2026',
          style: TextStyle(
            fontSize: 10,
            color: Colors.black45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _infoTexto(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }

  Widget _statCard(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 14 : 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.black : Colors.white,
          ),
        );
      }),
    );
  }
}