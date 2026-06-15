import 'package:cloud_firestore/cloud_firestore.dart';

class RacaoModel {
  final String? id;
  final String tipo; // Inicial, Crescimento, Engorda, Gestação, Lactação...
  final double quantidade;
  final String unidade; // 'kg' | 'sacos'
  final String fornecedor;
  final double custo; // custo total da entrada, em R$
  final DateTime criadoEm;

  RacaoModel({
    this.id,
    required this.tipo,
    required this.quantidade,
    required this.unidade,
    required this.fornecedor,
    required this.custo,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'quantidade': quantidade,
      'unidade': unidade,
      'fornecedor': fornecedor,
      'custo': custo,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory RacaoModel.fromMap(String id, Map<String, dynamic> map) {
    return RacaoModel(
      id: id,
      tipo: map['tipo'] ?? '',
      quantidade: (map['quantidade'] as num?)?.toDouble() ?? 0,
      unidade: map['unidade'] ?? 'kg',
      fornecedor: map['fornecedor'] ?? '',
      custo: (map['custo'] as num?)?.toDouble() ?? 0,
      criadoEm: (map['criadoEm'] as Timestamp).toDate(),
    );
  }
}