import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';

class AnimalService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('animais');

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
