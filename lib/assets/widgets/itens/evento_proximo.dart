import 'package:flutter/material.dart';

class EventoProximo extends StatelessWidget {
  final String data;
  final String descricao;
  final String ano;
  final VoidCallback? onTap;

  const EventoProximo({
    super.key,
    required this.data,
    required this.descricao,
    this.ano = '2026',
    this.onTap,
  });

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
              // Título + Ano
              Row(
                children: [
                  Text(
                    'Eventos Próximos',
                    style: TextStyle(
                      color: onContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    ano,
                    style: TextStyle(
                      color: onContainer.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Data grande + botão seta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    data,
                    style: TextStyle(
                      color: onContainer,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      color: colors.onPrimary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Ícone + descrição do evento
              Row(
                children: [
                  Icon(Icons.push_pin,
                      color: onContainer.withValues(alpha: 0.7), size: 12),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      descricao,
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