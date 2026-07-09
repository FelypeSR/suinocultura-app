import 'package:cloud_firestore/cloud_firestore.dart';
import 'granja_ativa.dart';

/// Limpeza do banco de dados da granja ATIVA.
///
/// Apaga todos os documentos das subcoleções de dados da granja aberta:
/// animais (incluindo o histórico de coberturas), rações, eventos/vacinações
/// e ninhadas. A granja em si (nome, membros), o perfil do usuário
/// (`usuarios/{uid}`) e a conta de login NÃO são afetados.
class DadosService {
  final _db = FirebaseFirestore.instance;

  /// Subcoleções da granja que serão esvaziadas.
  static const _colecoes = ['animais', 'racoes', 'eventos', 'ninhadas'];

  /// Apaga todos os dados da granja e devolve o total de registros removidos.
  Future<int> limparBanco() async {
    var removidos = 0;

    // Subcoleção de coberturas de cada animal — precisa ser apagada
    // explicitamente (no Firestore, excluir o pai não remove subcoleções).
    final animais = await GranjaAtiva.colecao('animais').get();
    for (final animal in animais.docs) {
      final coberturas = await animal.reference.collection('coberturas').get();
      removidos += await _apagarDocs(coberturas.docs);
    }

    for (final nome in _colecoes) {
      final snap = await GranjaAtiva.colecao(nome).get();
      removidos += await _apagarDocs(snap.docs);
    }
    return removidos;
  }

  /// Apaga os documentos em lotes (limite do Firestore: 500 operações/batch).
  Future<int> _apagarDocs(List<QueryDocumentSnapshot> docs) async {
    for (var i = 0; i < docs.length; i += 400) {
      final batch = _db.batch();
      for (final doc in docs.skip(i).take(400)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    return docs.length;
  }
}