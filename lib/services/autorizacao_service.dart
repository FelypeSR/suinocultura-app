import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controle de acesso aos dados da granja.
///
/// O acesso é restrito à lista de e-mails da coleção `autorizados` (um
/// documento por e-mail, em minúsculas) — criar conta no app não basta.
/// As regras do Firestore aplicam essa checagem no servidor; aqui o app a
/// consulta apenas para decidir qual tela mostrar após o login.
class AutorizacaoService {
  final _col = FirebaseFirestore.instance.collection('autorizados');

  /// true se o e-mail do usuário logado está na lista de autorizados.
  ///
  /// O `get()` usa o cache do Firestore quando está sem rede, então um
  /// usuário já autorizado continua entrando offline. Erros (ex.: primeira
  /// abertura sem internet) são tratados como "não autorizado" — a tela de
  /// bloqueio tem um botão de tentar novamente.
  Future<bool> usuarioAutorizado() async {
    final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == null || email.isEmpty) return false;
    try {
      final doc = await _col.doc(email).get();
      return doc.exists;
    } on FirebaseException {
      return false;
    }
  }

  /// Adiciona um e-mail à lista de autorizados (só funciona para quem já é
  /// autorizado, conforme as regras do Firestore).
  Future<void> autorizar(String email) async {
    await _col.doc(email.trim().toLowerCase()).set({
      'adicionadoPor': FirebaseAuth.instance.currentUser?.email,
      'adicionadoEm': Timestamp.now(),
    });
  }

  /// Remove um e-mail da lista de autorizados.
  Future<void> revogar(String email) async {
    await _col.doc(email.trim().toLowerCase()).delete();
  }

  /// E-mails autorizados em tempo real (para uma futura tela de gestão).
  Stream<List<String>> listar() {
    return _col.snapshots().map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
