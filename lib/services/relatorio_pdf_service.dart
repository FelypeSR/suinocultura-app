import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/animal_model.dart';
import '../models/racao_model.dart';
import '../models/ninhada_model.dart';
import 'animal_service.dart';
import 'racao_service.dart';
import 'ninhada_service.dart';

/// Gera o relatório da granja em PDF, reunindo rebanho, ninhadas e ração,
/// e abre a pré-visualização (imprimir / salvar / compartilhar) via `printing`.
class RelatorioPdfService {
  final _animalService = AnimalService();
  final _racaoService = RacaoService();
  final _ninhadaService = NinhadaService();

  static const PdfColor _verde = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _verdeClaro = PdfColor.fromInt(0xFFE8F5E9);
  static const PdfColor _cinza = PdfColor.fromInt(0xFF6B6B6B);

  /// Busca os dados (um snapshot de cada stream), monta o documento e abre a
  /// pré-visualização do sistema.
  Future<void> gerarEVisualizar({required String produtor}) async {
    final animais = await _animalService.listar().first;
    final racoes = await _racaoService.listar().first;
    final ninhadas = await _ninhadaService.listar().first;

    final doc = _montarDocumento(
      produtor: produtor,
      animais: animais,
      racoes: racoes,
      ninhadas: ninhadas,
    );

    await Printing.layoutPdf(
      name:
          'relatorio_granja_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
      onLayout: (format) => doc.save(),
    );
  }

  pw.Document _montarDocumento({
    required String produtor,
    required List<AnimalModel> animais,
    required List<RacaoModel> racoes,
    required List<NinhadaModel> ninhadas,
  }) {
    final doc = pw.Document();
    final fmtData = DateFormat('dd/MM/yyyy');
    final fmtDataHora = DateFormat('dd/MM/yyyy HH:mm');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Text('Relatório da Granja — GSPR',
                    style: pw.TextStyle(color: _cinza, fontSize: 9)),
              ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Página ${context.pageNumber}/${context.pagesCount}',
            style: pw.TextStyle(color: _cinza, fontSize: 9),
          ),
        ),
        build: (context) => [
          _cabecalho(produtor, fmtDataHora.format(DateTime.now())),
          pw.SizedBox(height: 20),
          _secaoRebanho(animais),
          pw.SizedBox(height: 18),
          _secaoNinhada(ninhadas, fmtData),
          pw.SizedBox(height: 18),
          _secaoRacao(racoes),
        ],
      ),
    );

    return doc;
  }

  // -------------------------------------------------------------------------
  // Cabeçalho
  // -------------------------------------------------------------------------
  pw.Widget _cabecalho(String produtor, String geradoEm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _verde,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Relatório da Granja',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  )),
              pw.SizedBox(height: 4),
              pw.Text('GSPR — Gestão de Suinocultura',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 11)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Produtor',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 9)),
              pw.Text(produtor.isEmpty ? '—' : produtor,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text('Gerado em $geradoEm',
                  style: pw.TextStyle(
                      color: PdfColors.white, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Seção: Rebanho
  // -------------------------------------------------------------------------
  pw.Widget _secaoRebanho(List<AnimalModel> animais) {
    final total = animais.length;
    final machos = animais.where((a) => a.sexo == 'macho').length;
    final femeas = animais.where((a) => a.sexo == 'femea').length;
    final aptasCobertura =
        animais.where((a) => a.sexo == 'femea' && a.podeCobertura).length;

    final pesoMedio = total == 0
        ? 0.0
        : animais.map((a) => a.peso).reduce((a, b) => a + b) / total;
    final idadeMedia = total == 0
        ? 0.0
        : animais.map((a) => a.idadeEmMeses).reduce((a, b) => a + b) / total;

    // Distribuição por raça
    final porRaca = <String, int>{};
    for (final a in animais) {
      final r = a.raca.trim().isEmpty ? 'Não informada' : a.raca.trim();
      porRaca[r] = (porRaca[r] ?? 0) + 1;
    }

    return _secao(
      'Rebanho',
      [
        _tabelaIndicadores([
          ['Total de animais', '$total'],
          ['Machos', '$machos'],
          ['Fêmeas', '$femeas'],
          ['Fêmeas aptas à cobertura', '$aptasCobertura'],
          ['Peso médio', '${pesoMedio.toStringAsFixed(1)} kg'],
          ['Idade média', '${idadeMedia.toStringAsFixed(0)} meses'],
        ]),
        if (porRaca.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text('Distribuição por raça',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          _tabela(
            ['Raça', 'Quantidade'],
            porRaca.entries
                .map((e) => [e.key, '${e.value}'])
                .toList(),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Seção: Ninhada
  // -------------------------------------------------------------------------
  pw.Widget _secaoNinhada(List<NinhadaModel> ninhadas, DateFormat fmtData) {
    final totalNinhadas = ninhadas.length;
    final nascidos =
        ninhadas.fold<int>(0, (s, n) => s + n.nascidos);
    final mortos = ninhadas.fold<int>(0, (s, n) => s + n.mortos);
    final desmamados = ninhadas.fold<int>(0, (s, n) => s + n.desmamados);
    final vivos = ninhadas.fold<int>(0, (s, n) => s + n.vivos);
    final taxaMort = nascidos == 0 ? 0.0 : (mortos / nascidos) * 100;
    final mediaLeitoes =
        totalNinhadas == 0 ? 0.0 : nascidos / totalNinhadas;

    if (totalNinhadas == 0) {
      return _secao('Ninhada / Leitões', [
        pw.Text('Nenhuma ninhada registrada até o momento.',
            style: pw.TextStyle(color: _cinza, fontSize: 11)),
      ]);
    }

    // Ninhadas mais recentes (até 8 linhas) para detalhe.
    final recentes = ninhadas.take(8).toList();

    return _secao(
      'Ninhada / Leitões',
      [
        _tabelaIndicadores([
          ['Ninhadas registradas', '$totalNinhadas'],
          ['Leitões nascidos', '$nascidos'],
          ['Leitões vivos', '$vivos'],
          ['Mortos', '$mortos'],
          ['Desmamados', '$desmamados'],
          ['Média de leitões/ninhada', mediaLeitoes.toStringAsFixed(1)],
          ['Taxa de mortalidade', '${taxaMort.toStringAsFixed(1)}%'],
        ]),
        pw.SizedBox(height: 10),
        pw.Text('Ninhadas recentes',
            style:
                pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        _tabela(
          ['Data', 'Mãe', 'Nascidos', 'Vivos', 'Desmamados'],
          recentes
              .map((n) => [
                    fmtData.format(n.data),
                    n.maeCodigo,
                    '${n.nascidos}',
                    '${n.vivos}',
                    '${n.desmamados}',
                  ])
              .toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Seção: Ração
  // -------------------------------------------------------------------------
  pw.Widget _secaoRacao(List<RacaoModel> racoes) {
    final entradas = racoes.length;

    double compradoKg = 0, compradoSacos = 0;
    double saldoKg = 0, saldoSacos = 0;
    double custoTotal = 0;
    for (final r in racoes) {
      custoTotal += r.custo;
      if (r.unidade == 'sacos') {
        compradoSacos += r.quantidade;
        saldoSacos += r.saldoAtual;
      } else {
        compradoKg += r.quantidade;
        saldoKg += r.saldoAtual;
      }
    }
    final consumidoKg = compradoKg - saldoKg;
    final consumidoSacos = compradoSacos - saldoSacos;

    if (entradas == 0) {
      return _secao('Ração', [
        pw.Text('Nenhuma entrada de ração registrada até o momento.',
            style: pw.TextStyle(color: _cinza, fontSize: 11)),
      ]);
    }

    // Resumo por tipo de ração.
    final porTipo = <String, double>{};
    for (final r in racoes) {
      final t = r.tipo.trim().isEmpty ? 'Não informado' : r.tipo.trim();
      porTipo[t] = (porTipo[t] ?? 0) + r.quantidade;
    }

    return _secao(
      'Ração',
      [
        _tabelaIndicadores([
          ['Entradas registradas', '$entradas'],
          ['Comprado (kg)', compradoKg.toStringAsFixed(1)],
          if (compradoSacos > 0)
            ['Comprado (sacos)', compradoSacos.toStringAsFixed(0)],
          ['Consumido (kg)', consumidoKg.toStringAsFixed(1)],
          if (consumidoSacos > 0)
            ['Consumido (sacos)', consumidoSacos.toStringAsFixed(0)],
          ['Saldo atual (kg)', saldoKg.toStringAsFixed(1)],
          if (saldoSacos > 0)
            ['Saldo atual (sacos)', saldoSacos.toStringAsFixed(0)],
          ['Custo total', 'R\$ ${custoTotal.toStringAsFixed(2)}'],
        ]),
        pw.SizedBox(height: 10),
        pw.Text('Comprado por tipo',
            style:
                pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        _tabela(
          ['Tipo', 'Quantidade'],
          porTipo.entries
              .map((e) => [e.key, e.value.toStringAsFixed(1)])
              .toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Helpers de layout
  // -------------------------------------------------------------------------

  /// Cartão de seção com título em barra verde.
  pw.Widget _secao(String titulo, List<pw.Widget> filhos) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const pw.BoxDecoration(
              color: _verde,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(titulo,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                )),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: filhos,
            ),
          ),
        ],
      ),
    );
  }

  /// Tabela de indicadores rótulo/valor em duas colunas.
  pw.Widget _tabelaIndicadores(List<List<String>> linhas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
      },
      children: linhas.map((l) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text(l[0], style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.Padding(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: pw.Text(l[1],
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Tabela genérica com cabeçalho verde-claro.
  pw.Widget _tabela(List<String> cabecalho, List<List<String>> linhas) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _verdeClaro),
          children: cabecalho
              .map((c) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    child: pw.Text(c,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...linhas.map((l) => pw.TableRow(
              children: l
                  .map((cel) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child:
                            pw.Text(cel, style: const pw.TextStyle(fontSize: 10)),
                      ))
                  .toList(),
            )),
      ],
    );
  }
}