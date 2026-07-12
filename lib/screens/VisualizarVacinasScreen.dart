import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/evento_model.dart';
import 'package:gspr/services/evento_service.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/services/animal_service.dart';

const _verde = Color(0xFF2E7D32);

final _data = DateFormat('dd/MM/yyyy');

/// Rótulo do grupo vacinado, a partir do valor gravado no evento.
String _grupoLabel(EventoModel e) => switch (e.grupo) {
      'machos' => 'Machos',
      'femeas' => 'Fêmeas',
      'filhotes' => 'Filhotes',
      'especificos' => 'Animais específicos',
      _ => e.grupo,
    };

/// Tela de visualização das vacinas: lista somente-leitura de todas as
/// vacinações registradas na granja. Cada card mostra o essencial e, ao tocar,
/// abre uma ficha com as informações completas do registro.
class VisualizarVacinasScreen extends StatelessWidget {
  VisualizarVacinasScreen({super.key});

  // Streams criadas uma vez: rebuilds não reabrem a consulta no Firestore.
  // Os animais entram só para traduzir os ids gravados no evento em códigos.
  late final _eventos = EventoService().listar();
  late final _animais = AnimalService().listar();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Vacinas',
      child: StreamBuilder<List<EventoModel>>(
        stream: _eventos,
        builder: (context, eventoSnap) {
          if (eventoSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingBolinhas());
          }
          if (eventoSnap.hasError) {
            return Center(child: Text('Erro: ${eventoSnap.error}'));
          }

          final eventos = (eventoSnap.data ?? [])
            ..sort((a, b) => b.data.compareTo(a.data));

          return StreamBuilder<List<AnimalModel>>(
            stream: _animais,
            builder: (context, animalSnap) {
              // Mapa id -> código para exibir os animais do grupo 'específicos'.
              final codigos = {
                for (final a in animalSnap.data ?? const <AnimalModel>[])
                  if (a.id != null) a.id!: a.codigo,
              };

              return Column(
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _ResumoVacinas(eventos: eventos),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: eventos.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma vacinação registrada',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black45),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: eventos.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) => _CardVacina(
                              evento: eventos[i],
                              codigos: codigos,
                            ),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Faixa verde com a contagem das vacinas: total, agendadas (hoje em diante)
/// e aplicadas (datas passadas).
class _ResumoVacinas extends StatelessWidget {
  final List<EventoModel> eventos;

  const _ResumoVacinas({required this.eventos});

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final agendadas =
        eventos.where((e) => !e.data.isBefore(inicioHoje)).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5ED84F), Color(0xFF3BA135)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _contagem('Total', eventos.length),
          _divisor(),
          _contagem('Agendadas', agendadas),
          _divisor(),
          _contagem('Aplicadas', eventos.length - agendadas),
        ],
      ),
    );
  }

  Widget _divisor() => Container(
        width: 1,
        height: 36,
        color: Colors.white38,
      );

  Widget _contagem(String label, int valor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$valor',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Card resumido da vacinação na lista. Tocar abre a ficha completa.
class _CardVacina extends StatelessWidget {
  final EventoModel evento;

  /// Mapa id -> código dos animais, para o grupo 'específicos'.
  final Map<String, String> codigos;

  const _CardVacina({required this.evento, required this.codigos});

  bool get _agendada {
    final hoje = DateTime.now();
    return !evento.data.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  String get _titulo => evento.tipoVacina.trim().isEmpty
      ? 'Vacinação'
      : evento.tipoVacina.trim();

  /// Códigos dos animais vacinados (grupo 'específicos'); ids sem animal
  /// correspondente (ex.: excluído) aparecem como '?'.
  String get _animaisTexto =>
      evento.animaisIds.map((id) => codigos[id] ?? '?').join(', ');

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirFicha(context),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _verde.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vaccines_outlined, color: _verde),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        _data.format(evento.data),
                        _grupoLabel(evento),
                        if (evento.dosagem.trim().isNotEmpty)
                          evento.dosagem.trim(),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SituacaoBadge(agendada: _agendada),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  /// Ficha completa da vacinação num bottom sheet, com todos os dados
  /// gravados (tipo, data, dosagem, via, grupo, animais e observações).
  void _abrirFicha(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SituacaoBadge(agendada: _agendada),
              ],
            ),
            const SizedBox(height: 16),
            _linha('Data', _data.format(evento.data)),
            _linha('Dosagem', evento.dosagem),
            _linha('Via de aplicação', evento.viaAplicacao),
            _linha('Grupo', _grupoLabel(evento)),
            if (evento.animaisIds.isNotEmpty)
              _linha('Animais', _animaisTexto),
            _linha('Observações', evento.observacoes),
            _linha('Registrado em', _data.format(evento.criadoEm)),
          ],
        ),
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    final texto = valor.trim().isEmpty ? '—' : valor.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de situação da vacinação: agendada (hoje em diante) ou aplicada.
class _SituacaoBadge extends StatelessWidget {
  final bool agendada;
  const _SituacaoBadge({required this.agendada});

  @override
  Widget build(BuildContext context) {
    final (label, cor) = agendada
        ? ('Agendada', const Color(0xFFEF6C00))
        : ('Aplicada', _verde);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}