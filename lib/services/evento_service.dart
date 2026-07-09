import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/evento_model.dart';
import 'granja_ativa.dart';

class EventoService {
  // Subcoleção da granja aberta no app (granjas/{id}/eventos).
  CollectionReference get _col => GranjaAtiva.colecao('eventos');

  Future<void> salvar(EventoModel evento) async {
    if (evento.id != null) {
      await _col.doc(evento.id).update(evento.toMap());
    } else {
      await _col.add(evento.toMap());
    }
  }

  Stream<List<EventoModel>> listar() {
    return _col
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                EventoModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}