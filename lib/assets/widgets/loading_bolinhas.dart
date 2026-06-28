import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Indicador de carregamento do app: três bolinhas pulando em onda,
/// alternando verde e rosa. Substitui os `CircularProgressIndicator`.
///
/// Uso:
///   const LoadingBolinhas()                 // padrão (verde/rosa)
///   const LoadingBolinhas(dotSize: 8)       // menor (ex.: dentro de botão)
///   const LoadingBolinhas(cores: [...])     // outras cores
class LoadingBolinhas extends StatefulWidget {
  /// Diâmetro de cada bolinha.
  final double dotSize;

  /// Cores aplicadas em sequência às bolinhas (repetem se forem menos que 3).
  final List<Color> cores;

  const LoadingBolinhas({
    super.key,
    this.dotSize = 12,
    this.cores = const [Color(0xFF2E7D32), Color(0xFFE91E63)], // verde, rosa
  });

  @override
  State<LoadingBolinhas> createState() => _LoadingBolinhasState();
}

class _LoadingBolinhasState extends State<LoadingBolinhas>
    with SingleTickerProviderStateMixin {
  static const _qtd = 3;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dotSize;
    final salto = d * 0.9; // altura do pulo
    return SizedBox(
      height: d + salto,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(_qtd, (i) {
              // Fase deslocada por bolinha cria o efeito de onda.
              final fase = (_controller.value + i / _qtd) % 1.0;
              final offset = -salto * math.sin(fase * math.pi);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: d * 0.28),
                child: Transform.translate(
                  offset: Offset(0, offset),
                  child: Container(
                    width: d,
                    height: d,
                    decoration: BoxDecoration(
                      color: widget.cores[i % widget.cores.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
