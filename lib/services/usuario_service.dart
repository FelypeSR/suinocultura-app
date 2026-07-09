import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dados de perfil do usuário que não cabem no Firebase Auth.
///
/// A foto de perfil é gravada em `usuarios/{uid}` como base64 — o projeto não
/// usa Firebase Storage (exige plano pago em projetos novos), e a foto vai
/// redimensionada/comprimida pelo seletor (~400px), bem abaixo do limite de
/// 1 MB por documento do Firestore.
class UsuarioService {
  final _col = FirebaseFirestore.instance.collection('usuarios');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Bytes da foto de perfil do usuário logado (tempo real); null sem foto.
  Stream<Uint8List?> fotoBytes() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _col.doc(uid).snapshots().map((doc) {
      final b64 = doc.data()?['fotoBase64'] as String?;
      if (b64 == null || b64.isEmpty) return null;
      try {
        return base64Decode(b64);
      } catch (_) {
        return null; // dado corrompido: trata como sem foto
      }
    });
  }

  /// Salva (ou substitui) a foto de perfil do usuário logado.
  Future<void> salvarFoto(Uint8List bytes) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('Nenhum usuário autenticado.');
    }
    await _col.doc(uid).set({
      'fotoBase64': base64Encode(bytes),
      'atualizadoEm': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}
