import 'package:cloud_firestore/cloud_firestore.dart';

class EventoModel {
  final String? id;
  final String tipo; // 'vacina' (preparado para outras atividades depois)
  final DateTime data;
  final String tipoVacina;
  final String dosagem;
  final String viaAplicacao;
  final String grupo; // 'machos' | 'femeas' | 'filhotes' | 'especificos'
  final List<String> animaisIds; // usado quando grupo == 'especificos'
  final String observacoes;
  final DateTime criadoEm;

  EventoModel({
    this.id,
    this.tipo = 'vacina',
    required this.data,
    required this.tipoVacina,
    required this.dosagem,
    required this.viaAplicacao,
    required this.grupo,
    this.animaisIds = const [],
    this.observacoes = '',
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'data': Timestamp.fromDate(data),
      'tipoVacina': tipoVacina,
      'dosagem': dosagem,
      'viaAplicacao': viaAplicacao,
      'grupo': grupo,
      'animaisIds': animaisIds,
      'observacoes': observacoes,
      'criadoEm': Timestamp.fromDate(criadoEm),
    };
  }

  factory EventoModel.fromMap(String id, Map<String, dynamic> map) {
    return EventoModel(
      id: id,
      tipo: map['tipo'] ?? 'vacina',
      data: (map['data'] as Timestamp).toDate(),
      tipoVacina: map['tipoVacina'] ?? '',
      dosagem: map['dosagem'] ?? '',
      viaAplicacao: map['viaAplicacao'] ?? '',
      grupo: map['grupo'] ?? '',
      animaisIds: (map['animaisIds'] as List?)?.cast<String>() ?? const [],
      observacoes: map['observacoes'] ?? '',
      criadoEm: (map['criadoEm'] as Timestamp).toDate(),
    );
  }
}