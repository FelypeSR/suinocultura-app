import 'package:cloud_firestore/cloud_firestore.dart';

class AnimalModel {
  /// Gestação da fêmea suína dura ~114 dias. Usado para calcular a previsão
  /// de parto a partir da data da cobertura.
  static const int diasGestacao = 114;

  final String? id;
  final String codigo;
  final String sexo; // 'macho' | 'femea'
  final DateTime dataNascimento;
  final double peso;
  final String raca;
  final String produtividade;
  final String saude;
  final DateTime criadoEm;

  /// Situação atual do animal:
  /// 'ativo' | 'gestante' | 'vendido' | 'doente' | 'morto'.
  final String status;

  // Dados da gestação atual (somente fêmea com status 'gestante').
  final String? machoCobertura; // código do macho usado na cobertura
  final DateTime? dataCobertura;
  final DateTime? previsaoParto;

  // Dados da venda (somente quando status 'vendido').
  final String? compradorVenda;
  final double? valorVenda;
  final DateTime? dataVenda;

  // Dados da doença/tratamento (status 'doente'; ficam como histórico da
  // última doença depois que o tratamento é concluído).
  final String? doenca; // qual a doença
  final String? tratamento; // descrição do tratamento
  final bool emTratamento; // se o animal está em tratamento no momento
  final DateTime? dataDoenca;
  final DateTime? dataFimTratamento; // conclusão do tratamento

  // Dados da perda/morte (somente quando status 'morto').
  final String? causaMorte;
  final DateTime? dataMorte;

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
    this.status = 'ativo',
    this.machoCobertura,
    this.dataCobertura,
    this.previsaoParto,
    this.compradorVenda,
    this.valorVenda,
    this.dataVenda,
    this.doenca,
    this.tratamento,
    this.emTratamento = false,
    this.dataDoenca,
    this.dataFimTratamento,
    this.causaMorte,
    this.dataMorte,
  }) : criadoEm = criadoEm ?? DateTime.now();

  bool get isMacho => sexo == 'macho';
  bool get isFemea => sexo == 'femea';
  bool get gestante => status == 'gestante';
  bool get vendido => status == 'vendido';
  bool get doente => status == 'doente';
  bool get morto => status == 'morto';

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
      'status': status,
      if (machoCobertura != null) 'machoCobertura': machoCobertura,
      if (dataCobertura != null)
        'dataCobertura': Timestamp.fromDate(dataCobertura!),
      if (previsaoParto != null)
        'previsaoParto': Timestamp.fromDate(previsaoParto!),
      if (compradorVenda != null) 'compradorVenda': compradorVenda,
      if (valorVenda != null) 'valorVenda': valorVenda,
      if (dataVenda != null) 'dataVenda': Timestamp.fromDate(dataVenda!),
      if (doenca != null) 'doenca': doenca,
      if (tratamento != null) 'tratamento': tratamento,
      'emTratamento': emTratamento,
      if (dataDoenca != null) 'dataDoenca': Timestamp.fromDate(dataDoenca!),
      if (dataFimTratamento != null)
        'dataFimTratamento': Timestamp.fromDate(dataFimTratamento!),
      if (causaMorte != null) 'causaMorte': causaMorte,
      if (dataMorte != null) 'dataMorte': Timestamp.fromDate(dataMorte!),
    };
  }

  factory AnimalModel.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseData(dynamic v) => v is Timestamp ? v.toDate() : null;

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
      status: map['status'] ?? 'ativo',
      machoCobertura: map['machoCobertura'],
      dataCobertura: parseData(map['dataCobertura']),
      previsaoParto: parseData(map['previsaoParto']),
      compradorVenda: map['compradorVenda'],
      valorVenda: (map['valorVenda'] as num?)?.toDouble(),
      dataVenda: parseData(map['dataVenda']),
      doenca: map['doenca'],
      tratamento: map['tratamento'],
      emTratamento: map['emTratamento'] ?? false,
      dataDoenca: parseData(map['dataDoenca']),
      dataFimTratamento: parseData(map['dataFimTratamento']),
      causaMorte: map['causaMorte'],
      dataMorte: parseData(map['dataMorte']),
    );
  }
}
