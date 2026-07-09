import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';
import 'granja_ativa.dart';

class AnimalService {
  // Subcoleção da granja aberta no app (granjas/{id}/animais).
  CollectionReference get _col => GranjaAtiva.colecao('animais');

  /// Cria ou atualiza um animal e devolve o id do documento.
  Future<String> salvar(AnimalModel animal) async {
    if (animal.id != null) {
      await _col.doc(animal.id).update(animal.toMap());
      return animal.id!;
    }
    final ref = await _col.add(animal.toMap());
    return ref.id;
  }

  Stream<List<AnimalModel>> listar() {
    return _col
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                AnimalModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<AnimalModel>> listarPorSexo(String sexo) {
    // Filtra por sexo no Firestore e ordena por criadoEm em memória — assim
    // evita exigir um índice composto (where + orderBy em campos diferentes).
    return _col
        .where('sexo', isEqualTo: sexo)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                AnimalModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm)));
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }

  /// Marca uma fêmea como gestante, guardando o macho usado, a data da
  /// cobertura e calculando a previsão de parto (~114 dias depois).
  Future<void> marcarGestante(
    String id, {
    required String machoCodigo,
    required DateTime dataCobertura,
  }) async {
    final previsaoParto =
        dataCobertura.add(const Duration(days: AnimalModel.diasGestacao));
    await _col.doc(id).update({
      'status': 'gestante',
      'machoCobertura': machoCodigo,
      'dataCobertura': Timestamp.fromDate(dataCobertura),
      'previsaoParto': Timestamp.fromDate(previsaoParto),
    });
  }

  /// Registra a venda do animal e muda o status para 'vendido'.
  Future<void> registrarVenda(
    String id, {
    required String comprador,
    required double valor,
    required DateTime data,
  }) async {
    await _col.doc(id).update({
      'status': 'vendido',
      'compradorVenda': comprador,
      'valorVenda': valor,
      'dataVenda': Timestamp.fromDate(data),
    });
  }

  /// Registra uma doença no animal (status 'doente'), com a descrição do
  /// tratamento e se ele já está em tratamento. Também serve para atualizar
  /// os dados de uma doença já registrada.
  Future<void> registrarDoenca(
    String id, {
    required String doenca,
    required String tratamento,
    required bool emTratamento,
    required DateTime data,
  }) async {
    await _col.doc(id).update({
      'status': 'doente',
      'doenca': doenca,
      'tratamento': tratamento,
      'emTratamento': emTratamento,
      'dataDoenca': Timestamp.fromDate(data),
      // Reabrir uma doença limpa a conclusão anterior.
      'dataFimTratamento': FieldValue.delete(),
    });
  }

  /// Conclui o tratamento: o animal volta a 'ativo' e os dados da doença
  /// ficam como histórico, com a data de conclusão registrada.
  Future<void> concluirTratamento(String id, {required DateTime data}) async {
    await _col.doc(id).update({
      'status': 'ativo',
      'emTratamento': false,
      'dataFimTratamento': Timestamp.fromDate(data),
    });
  }

  /// Registra a perda (morte) do animal: status 'morto', com causa e data.
  Future<void> registrarPerda(
    String id, {
    required String causa,
    required DateTime data,
  }) async {
    await _col.doc(id).update({
      'status': 'morto',
      'causaMorte': causa,
      'dataMorte': Timestamp.fromDate(data),
      'emTratamento': false,
    });
  }

  /// Registra uma cobertura feita por um macho (subcoleção 'coberturas'),
  /// usada para contar o nº de coberturas / fertilidade do reprodutor.
  Future<void> registrarCobertura(String machoId, DateTime data) async {
    await _col.doc(machoId).collection('coberturas').add({
      'data': Timestamp.fromDate(data),
      'criadoEm': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Quantidade de coberturas registradas para um macho (tempo real).
  Stream<int> contarCoberturas(String machoId) {
    return _col
        .doc(machoId)
        .collection('coberturas')
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
