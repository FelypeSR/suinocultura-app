import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/racao_model.dart';
import 'granja_ativa.dart';

class RacaoService {
  // Subcoleção da granja aberta no app (granjas/{id}/racoes).
  CollectionReference get _col => GranjaAtiva.colecao('racoes');

  Future<void> salvar(RacaoModel racao) async {
    if (racao.id != null) {
      await _col.doc(racao.id).update(racao.toMap());
    } else {
      await _col.add(racao.toMap());
    }
  }

  Stream<List<RacaoModel>> listar() {
    return _col
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                RacaoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}