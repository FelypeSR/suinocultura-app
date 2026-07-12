import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/models/animal_model.dart';
import 'package:gspr/services/animal_service.dart';

const _verde = Color(0xFF2E7D32);

final _data = DateFormat('dd/MM/yyyy');
final _moeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Tela de visualização do rebanho: lista somente-leitura de todos os animais
/// da granja. Cada card mostra o essencial e, ao tocar, abre uma ficha com as
/// informações completas do animal.
class VisualizarRebanhoScreen extends StatelessWidget {
  VisualizarRebanhoScreen({super.key});

  // Stream criada uma vez: rebuilds não reabrem a consulta no Firestore.
  late final _animais = AnimalService().listar();

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Rebanho',
      child: StreamBuilder<List<AnimalModel>>(
        stream: _animais,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingBolinhas());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final animais = snapshot.data ?? [];

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _ResumoRebanho(animais: animais),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: animais.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum animal cadastrado',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black45),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: animais.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _CardAnimal(animal: animais[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Faixa verde com a contagem do rebanho: total (sem perdas), machos e fêmeas.
class _ResumoRebanho extends StatelessWidget {
  final List<AnimalModel> animais;

  const _ResumoRebanho({required this.animais});

  @override
  Widget build(BuildContext context) {
    // Perdas ficam fora da contagem (mesma regra do resumo da home).
    final vivos = animais.where((a) => !a.morto).toList();
    final machos = vivos.where((a) => a.isMacho).length;
    final femeas = vivos.where((a) => a.isFemea).length;

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
          _contagem('Total', vivos.length),
          _divisor(),
          _contagem('Machos', machos),
          _divisor(),
          _contagem('Fêmeas', femeas),
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

/// Card resumido do animal na lista. Tocar abre a ficha completa.
class _CardAnimal extends StatelessWidget {
  final AnimalModel animal;

  const _CardAnimal({required this.animal});

  @override
  Widget build(BuildContext context) {
    final raca = animal.raca.trim();

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
                child: Icon(
                  animal.isMacho ? Icons.male : Icons.female,
                  color: _verde,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.codigo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        animal.isMacho ? 'Macho' : 'Fêmea',
                        if (raca.isNotEmpty) raca,
                        '${animal.idadeEmMeses} meses',
                        '${animal.peso} kg',
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
              _StatusBadge(status: animal.status),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  /// Ficha completa do animal num bottom sheet, com todos os dados gravados
  /// (incluindo gestação, venda, doença ou perda, conforme o status).
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
                    animal.codigo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(status: animal.status),
              ],
            ),
            const SizedBox(height: 16),
            _linha('Sexo', animal.isMacho ? 'Macho' : 'Fêmea'),
            _linha('Raça', animal.raca),
            _linha('Nascimento',
                '${_data.format(animal.dataNascimento)} (${animal.idadeEmMeses} meses)'),
            _linha('Peso', '${animal.peso} kg'),
            _linha('Produtividade', animal.produtividade),
            _linha('Saúde', animal.saude),
            _linha('Cadastrado em', _data.format(animal.criadoEm)),
            if (animal.gestante) ...[
              _secao('Gestação'),
              _linha('Macho da cobertura', animal.machoCobertura ?? ''),
              if (animal.dataCobertura != null)
                _linha('Data da cobertura',
                    _data.format(animal.dataCobertura!)),
              if (animal.previsaoParto != null)
                _linha('Previsão de parto',
                    _data.format(animal.previsaoParto!)),
            ],
            if (animal.vendido) ...[
              _secao('Venda'),
              _linha('Comprador', animal.compradorVenda ?? ''),
              if (animal.valorVenda != null)
                _linha('Valor', _moeda.format(animal.valorVenda)),
              if (animal.dataVenda != null)
                _linha('Data da venda', _data.format(animal.dataVenda!)),
            ],
            // Doença atual ou histórico da última doença registrada.
            if (animal.doenca != null) ...[
              _secao(animal.doente ? 'Doença' : 'Última doença'),
              _linha('Doença', animal.doenca ?? ''),
              _linha('Tratamento', animal.tratamento ?? ''),
              if (animal.dataDoenca != null)
                _linha('Registrada em', _data.format(animal.dataDoenca!)),
              if (animal.dataFimTratamento != null)
                _linha('Tratamento concluído em',
                    _data.format(animal.dataFimTratamento!)),
            ],
            if (animal.morto) ...[
              _secao('Perda'),
              _linha('Causa', animal.causaMorte ?? ''),
              if (animal.dataMorte != null)
                _linha('Data', _data.format(animal.dataMorte!)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        titulo.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _verde,
          letterSpacing: 0.5,
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

/// Etiqueta de status (gestante / vendido / doente / morto). Animais ativos
/// exibem a etiqueta "Ativo".
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (String label, Color cor) = switch (status) {
      'vendido' => ('Vendido', Colors.grey),
      'gestante' => ('Gestante', const Color(0xFFEF6C00)),
      'doente' => ('Em tratamento', const Color(0xFFC62828)),
      'morto' => ('Perda', Colors.black54),
      _ => ('Ativo', _verde),
    };
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
