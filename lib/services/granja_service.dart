import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/granja_model.dart';

/// Criação e gestão de granjas e dos seus membros.
///
/// O acesso aos dados é controlado pelo array `membros` (e-mails em
/// minúsculas) do documento da granja — as regras do Firestore só liberam
/// leitura/escrita das subcoleções para quem está nele.
class GranjaService {
  final _col = FirebaseFirestore.instance.collection('granjas');

  String? get _email =>
      FirebaseAuth.instance.currentUser?.email?.toLowerCase();

  /// Granjas das quais o usuário logado é membro (tempo real). É a stream
  /// que o gate observa: quando alguém adiciona o e-mail do usuário a uma
  /// granja, a tela de boas-vindas dá lugar à home sozinha.
  Stream<List<GranjaModel>> minhasGranjas() {
    final email = _email;
    if (email == null || email.isEmpty) return Stream.value(const []);
    return _col.where('membros', arrayContains: email).snapshots().map(
        (snap) => snap.docs
            .map((d) => GranjaModel.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => a.criadaEm.compareTo(b.criadaEm)));
  }

  /// Cria uma granja com o usuário logado como dono/primeiro membro e
  /// devolve o id.
  Future<String> criar(String nome) async {
    final email = _email;
    if (email == null || email.isEmpty) {
      throw StateError('Nenhum usuário autenticado.');
    }
    final ref = await _col.add(GranjaModel(
      nome: nome.trim(),
      dono: email,
      membros: [email],
      criadaEm: DateTime.now(),
    ).toMap());
    return ref.id;
  }

  /// Dados da granja em tempo real (nome, membros...).
  Stream<GranjaModel?> observar(String granjaId) {
    return _col.doc(granjaId).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : GranjaModel.fromMap(doc.id, data);
    });
  }

  /// Dá acesso à granja para um e-mail (qualquer membro pode convidar).
  Future<void> adicionarMembro(String granjaId, String email) async {
    await _col.doc(granjaId).update({
      'membros': FieldValue.arrayUnion([email.trim().toLowerCase()]),
    });
  }

  /// Revoga o acesso de um e-mail. O dono não pode ser removido.
  Future<void> removerMembro(String granjaId, String email) async {
    final alvo = email.trim().toLowerCase();
    final doc = await _col.doc(granjaId).get();
    if (doc.data()?['dono'] == alvo) {
      throw StateError('O dono da granja não pode ser removido.');
    }
    await _col.doc(granjaId).update({
      'membros': FieldValue.arrayRemove([alvo]),
    });
  }
}