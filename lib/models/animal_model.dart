import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalModel {
  final String? id;
  final String codigo;
  final String sexo; // 'macho' | 'femea'
  final DateTime dataNascimento;
  final double peso;
  final String raca;
  final String produtividade;
  final String saude;
  final DateTime criadoEm;

  AnimalModel({
    this.id,
    required this.codigo,
    required this.sexo,
    required this.dataNascimento,
    required this.peso,
    required this.raca,
    required this.produtividade,
    required this.saude,
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  // Regra: 7 meses = 210 dias
  bool get podeCobertura {
    return DateTime.now().difference(dataNascimento).inDays >= 210;
  }

  int get idadeEmMeses {
    final hoje = DateTime.now();
    int meses = (hoje.year - dataNascimento.year) * 12 +
        (hoje.month - dataNascimento.month);
    if (hoje.day < dataNascimento.day) meses--;
    return meses;
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'sexo': sexo,
      'dataNascimento': Timestamp.fromDate(dataNascimento),
      'peso': peso,
      'raca': raca,
      'produtividade': produtividade,
      'saude': saude,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory AnimalModel.fromMap(String id, Map<String, dynamic> map) {
    return AnimalModel(
      id: id,
      codigo: map['codigo'] ?? '',
      sexo: map['sexo'] ?? 'macho',
      dataNascimento: (map['dataNascimento'] as Timestamp).toDate(),
      peso: (map['peso'] as num).toDouble(),
      raca: map['raca'] ?? '',
      produtividade: map['produtividade'] ?? '',
      saude: map['saude'] ?? '',
      criadoEm: (map['criadoEm'] as Timestamp).toDate(),
    );
  }
}
