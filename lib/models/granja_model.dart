import 'package:cloud_firestore/cloud_firestore.dart';

/// Uma granja: a unidade que agrupa todos os dados do produtor.
///
/// Os dados do rebanho (animais, rações, eventos, ninhadas) vivem em
/// subcoleções de `granjas/{id}`, e só os e-mails em [membros] têm acesso
/// (aplicado pelas regras do Firestore).
class GranjaModel {
  final String? id;
  final String nome;

  /// E-mail (minúsculas) de quem criou a granja. Só o dono pode excluí-la.
  final String dono;

  /// E-mails (minúsculas) com acesso aos dados — o dono está incluído.
  final List<String> membros;

  final DateTime criadaEm;

  GranjaModel({
    this.id,
    required this.nome,
    required this.dono,
    required this.membros,
    required this.criadaEm,
  });

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'dono': dono,
        'membros': membros,
        'criadaEm': Timestamp.fromDate(criadaEm),
      };

  factory GranjaModel.fromMap(String id, Map<String, dynamic> map) {
    return GranjaModel(
      id: id,
      nome: (map['nome'] as String?) ?? 'Granja',
      dono: (map['dono'] as String?) ?? '',
      membros: List<String>.from(map['membros'] as List? ?? const []),
      criadaEm: (map['criadaEm'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}