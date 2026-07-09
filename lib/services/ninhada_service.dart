import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ninhada_model.dart';
import 'granja_ativa.dart';

class NinhadaService {
  // Subcoleção da granja aberta no app (granjas/{id}/ninhadas).
  CollectionReference get _col => GranjaAtiva.colecao('ninhadas');

  Future<void> salvar(NinhadaModel ninhada) async {
    if (ninhada.id != null) {
      await _col.doc(ninhada.id).update(ninhada.toMap());
    } else {
      await _col.add(ninhada.toMap());
    }
  }

  Stream<List<NinhadaModel>> listar() {
    return _col
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                NinhadaModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}