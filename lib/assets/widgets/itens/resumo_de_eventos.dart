import 'package:flutter/material.dart';

/// Uma anotação exibida no carrossel, com a origem (de onde a informação veio,
/// ex.: "Estoque • Inicial", "Animal 123") e o texto da observação.
class Anotacao {
  final String origem;
  final String texto;

  const Anotacao({required this.origem, required this.texto});
}

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

  // --- Anotações ---
  final List<Anotacao> anotacoes;

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
    this.anotacoes = const [],
  });

  @override
  State<ResumodeEventos> createState() => _ResumodeEventosState();
}

class _ResumodeEventosState extends State<ResumodeEventos> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Decoração dos cards baseada no tema (verde sólido da marca).
  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  /// Cor do conteúdo sobre o card verde.
  Color get _onCard => Theme.of(context).colorScheme.onPrimary;

  /// Preenche o espaço restante do card com [child] em tamanho natural,
  /// encolhendo-o proporcionalmente quando a tela é baixa demais (evita
  /// overflow em celulares de resolução menor).
  Widget _conteudoAdaptavel(Widget child,
      {Alignment alignment = Alignment.topCenter}) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, c) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment,
          child: SizedBox(width: c.maxWidth, child: child),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: [
              _cardEstoque(),
              _cardLeitoes(),
              _cardAnotacoes(),
              _cardCobertura(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildDots(4),
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
          _conteudoAdaptavel(
            alignment: Alignment.topLeft,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Expanded + FittedBox por linha: em telas estreitas o texto
                // encolhe em vez de estourar sobre o gauge.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoTexto(
                          'Estoque: ${widget.estoqueKg.toStringAsFixed(0)} kgs.'),
                      const SizedBox(height: 12),
                      _infoTexto('Rebanho: ${widget.rebanho}.'),
                      const SizedBox(height: 12),
                      _infoTexto('Leitões: ${widget.leitoes}.'),
                      const SizedBox(height: 12),
                      _infoTexto('Registro: ${widget.dataRegistro}.'),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      'Estoque de ração',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _onCard,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: CircularProgressIndicator(
                            value: widget.percentualRacao,
                            strokeWidth: 8,
                            backgroundColor: _onCard.withValues(alpha: 0.25),
                            color: _onCard,
                          ),
                        ),
                        Text(
                          '${(widget.percentualRacao * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: _onCard,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
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
          _conteudoAdaptavel(
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCard(
                        Icons.child_care, '${widget.nascimentos}', 'Nascimentos'),
                    _statCard(
                        Icons.directions_run, '${widget.desmames}', 'Desmames'),
                    _statCard(Icons.warning_amber_rounded,
                        '${widget.mortalidade}', 'Mortalidade'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total no plantel: ${widget.leitoes}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _onCard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 4: Período de cobertura ────────────────────────────────────────────
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
          _conteudoAdaptavel(
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCard(
                        Icons.favorite, '${widget.emCobertura}', 'Em cobertura'),
                    // Ícone de porco (cofrinho/leitoa) no lugar da gestante
                    // humana.
                    _statCard(Icons.savings, '${widget.gestantes}', 'Gestantes'),
                    _statCard(Icons.child_friendly, '${widget.emAleitamento}',
                        'Aleitamento'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Rebanho total: ${widget.rebanho}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _onCard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 3: Anotações ───────────────────────────────────────────────────────
  Widget _cardAnotacoes() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cabecalho('ANOTAÇÕES'),
          const SizedBox(height: 16),
          Expanded(
            child: widget.anotacoes.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma anotação registrada.',
                      style: TextStyle(color: _onCard, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: widget.anotacoes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final a = widget.anotacoes[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Origem da anotação (de qual lugar ela vem)
                            Row(
                              children: [
                                const Icon(Icons.label_important_outline,
                                    size: 14, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    a.origem,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              a.texto,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      );
                    },
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
        Icon(Icons.receipt_long, color: _onCard, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _onCard,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${DateTime.now().year}',
          style: TextStyle(
            fontSize: 12,
            color: _onCard.withValues(alpha: 0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _infoTexto(String texto) {
    // FittedBox: em telas estreitas o texto encolhe em vez de quebrar linha.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: _onCard,
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: _onCard, size: 36),
        const SizedBox(height: 6),
        Text(
          valor,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _onCard,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: _onCard.withValues(alpha: 0.8)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDots(int count) {
    final colors = Theme.of(context).colorScheme;
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
            color: active ? colors.primary : colors.outlineVariant,
          ),
        );
      }),
    );
  }
}