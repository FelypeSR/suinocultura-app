import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/animal_model.dart';

class AnimalService {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('animais');

  Future<void> salvar(AnimalModel animal) async {
    if (animal.id != null) {
      await _col.doc(animal.id).update(animal.toMap());
    } else {
      await _col.add(animal.toMap());
    }
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
    return _col
        .where('sexo', isEqualTo: sexo)
        .orderBy('criadoEm', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                AnimalModel.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}
