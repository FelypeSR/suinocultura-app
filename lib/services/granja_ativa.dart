import 'package:cloud_firestore/cloud_firestore.dart';

/// Granja atualmente aberta no app.
///
/// Definida pelo gate de granjas (auth_gate.dart) antes de mostrar a home e
/// limpa no logout/troca. Os serviços usam [colecao] para montar o caminho
/// das subcoleções — nenhuma tela precisa carregar o id da granja.
class GranjaAtiva {
  GranjaAtiva._();

  static String? id;
  static String? nome;

  static void definir({required String granjaId, required String granjaNome}) {
    id = granjaId;
    nome = granjaNome;
  }

  static void limpar() {
    id = null;
    nome = null;
  }

  /// Referência a uma subcoleção da granja ativa (ex.: `colecao('animais')`).
  /// Falha cedo e com mensagem clara se nenhuma granja estiver aberta.
  static CollectionReference<Map<String, dynamic>> colecao(String nome) {
    final granjaId = id;
    if (granjaId == null) {
      throw StateError(
          'Nenhuma granja ativa — acesso a "$nome" antes do gate de granjas.');
    }
    return FirebaseFirestore.instance
        .collection('granjas')
        .doc(granjaId)
        .collection(nome);
  }
}