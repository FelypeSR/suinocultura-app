import 'package:cloud_firestore/cloud_firestore.dart';

class RacaoModel {
  final String? id;
  final String tipo; // Inicial, Crescimento, Engorda, Gestação, Lactação...
  final String classe; // 'femeas' | 'machos' | 'todos' | 'filhotes'
  final double quantidade;
  final String unidade; // 'kg' | 'sacos'
  final String fornecedor;
  final double custo; // custo total da entrada, em R$
  final String observacao;
  final String modoConsumo; // 'manual' | 'automatico'
  final double consumoPorDia; // kg/dia descontado (usado no modo automático)
  final DateTime inicioConsumo; // a partir de quando o consumo começa a contar
  final DateTime criadoEm;

  RacaoModel({
    this.id,
    required this.tipo,
    this.classe = 'todos',
    required this.quantidade,
    required this.unidade,
    required this.fornecedor,
    required this.custo,
    this.observacao = '',
    this.modoConsumo = 'manual',
    this.consumoPorDia = 0,
    DateTime? inicioConsumo,
    DateTime? criadoEm,
  })  : criadoEm = criadoEm ?? DateTime.now(),
        inicioConsumo = inicioConsumo ?? criadoEm ?? DateTime.now();

  /// Saldo atual em estoque.
  ///
  /// No modo automático, desconta `consumoPorDia` por cada dia decorrido
  /// desde [inicioConsumo] — calculado na hora de exibir, sem job no servidor.
  /// Nunca fica abaixo de zero. No modo manual, devolve a [quantidade] cheia.
  double get saldoAtual {
    if (modoConsumo != 'automatico' || consumoPorDia <= 0) return quantidade;
    final dias = DateTime.now().difference(inicioConsumo).inDays;
    if (dias <= 0) return quantidade;
    final saldo = quantidade - (consumoPorDia * dias);
    return saldo < 0 ? 0 : saldo;
  }

  /// Dias restantes até o estoque acabar (modo automático). null se manual
  /// ou sem consumo definido.
  int? get diasRestantes {
    if (modoConsumo != 'automatico' || consumoPorDia <= 0) return null;
    return (saldoAtual / consumoPorDia).floor();
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'classe': classe,
      'quantidade': quantidade,
      'unidade': unidade,
      'fornecedor': fornecedor,
      'custo': custo,
      'observacao': observacao,
      'modoConsumo': modoConsumo,
      'consumoPorDia': consumoPorDia,
      'inicioConsumo': Timestamp.fromDate(inicioConsumo),
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory RacaoModel.fromMap(String id, Map<String, dynamic> map) {
    final criado = (map['criadoEm'] as Timestamp?)?.toDate();
    return RacaoModel(
      id: id,
      tipo: map['tipo'] ?? '',
      classe: map['classe'] ?? 'todos',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0,
      unidade: map['unidade'] ?? 'kg',
      fornecedor: map['fornecedor'] ?? '',
      custo: (map['custo'] as num?)?.toDouble() ?? 0,
      observacao: map['observacao'] ?? '',
      modoConsumo: map['modoConsumo'] ?? 'manual',
      consumoPorDia: (map['consumoPorDia'] as num?)?.toDouble() ?? 0,
      inicioConsumo: (map['inicioConsumo'] as Timestamp?)?.toDate() ?? criado,
      criadoEm: criado,
    );
  }
}