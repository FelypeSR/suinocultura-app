import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de uma ninhada (leitegada): nascimento de leitões a partir de uma
/// fêmea (mãe). Alimenta os relatórios e o resumo da home.
class NinhadaModel {
  final String? id;
  final String? maeId; // id do animal-mãe em 'animais' (se cadastrada)
  final String maeCodigo; // código da mãe, para exibição
  final DateTime data; // data do parto
  final int nascidos; // total de leitões nascidos
  final int mortos; // mortos até o desmame
  final int desmamados; // desmamados com sucesso
  final String observacao;
  final DateTime criadoEm;

  NinhadaModel({
    this.id,
    this.maeId,
    required this.maeCodigo,
    required this.data,
    required this.nascidos,
    this.mortos = 0,
    this.desmamados = 0,
    this.observacao = '',
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  /// Leitões vivos (nascidos menos mortos). Nunca negativo.
  int get vivos {
    final v = nascidos - mortos;
    return v < 0 ? 0 : v;
  }

  /// Taxa de mortalidade da ninhada (0..1). 0 quando não houve nascimentos.
  double get taxaMortalidade {
    if (nascidos <= 0) return 0;
    return mortos / nascidos;
  }

  Map<String, dynamic> toMap() {
    return {
      'maeId': maeId,
      'maeCodigo': maeCodigo,
      'data': Timestamp.fromDate(data),
      'nascidos': nascidos,
      'mortos': mortos,
      'desmamados': desmamados,
      'observacao': observacao,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory NinhadaModel.fromMap(String id, Map<String, dynamic> map) {
    return NinhadaModel(
      id: id,
      maeId: map['maeId'],
      maeCodigo: map['maeCodigo'] ?? '',
      data: (map['data'] as Timestamp).toDate(),
      nascidos: (map['nascidos'] as num?)?.toInt() ?? 0,
      mortos: (map['mortos'] as num?)?.toInt() ?? 0,
      desmamados: (map['desmamados'] as num?)?.toInt() ?? 0,
      observacao: map['observacao'] ?? '',
      criadoEm: (map['criadoEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}