import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ninhada_model.dart';

class NinhadaService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('ninhadas');

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