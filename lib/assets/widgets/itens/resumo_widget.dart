import 'package:flutter/material.dart';

class ResumoWidget extends StatelessWidget {
  const ResumoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // 1. Aplicando o Gradiente de fundo
        gradient: const LinearGradient(
          colors: [
            Color(0xFF388E3C), // Verde escuro (topo)
            Color(0xFF69F0AE), // Verde claro vibrante (base)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Cabeçalho (Ícone + RESUMO 2026)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.receipt_long, color: Colors.black87),
              const SizedBox(width: 8),
              const Text(
                'RESUMO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '2026',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // 3. Conteúdo Principal (Textos na esquerda, Gráfico na direita)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Coluna da Esquerda (Lista de dados)
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoText(text: 'Estoque: 80 kgs.'),
                  SizedBox(height: 8),
                  _InfoText(text: 'Rebanho: 140.'),
                  SizedBox(height: 8),
                  _InfoText(text: 'Leitões: 45.'),
                  SizedBox(height: 8),
                  _InfoText(text: 'Data de Registro: 40/10.'),
                ],
              ),

              // Coluna da Direita (Gráfico Circular)
              Column(
                children: [
                  const Text(
                    'Estoque de ração',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Usando Stack para sobrepor o texto no centro do círculo
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          value: 0.88, // Representa os 88%
                          strokeWidth: 6,
                          backgroundColor: Colors.black87, // Trilha preta
                          color: Colors.white, // Progresso branco
                        ),
                      ),
                      const Text(
                        '88%',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Indicadores de página (Bolinhas no rodapé)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(isActive: false),
              const SizedBox(width: 8),
              _buildDot(isActive: true), // A segunda bolinha está preta na sua imagem
              const SizedBox(width: 8),
              _buildDot(isActive: false),
              const SizedBox(width: 8),
              _buildDot(isActive: false),
            ],
          ),
        ],
      ),
    );
  }

  // Método auxiliar para criar as bolinhas de paginação
  Widget _buildDot({required bool isActive}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.black : Colors.white,
      ),
    );
  }
}

// Widget auxiliar para os textos da lista manterem o mesmo padrão
class _InfoText extends StatelessWidget {
  final String text;

  const _InfoText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900, // Fonte bem grossa para bater com a imagem
        color: Colors.black87,
      ),
    );
  }
}