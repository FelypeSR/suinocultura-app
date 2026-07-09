import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gspr/services/usuario_service.dart';

/// Avatar do usuário logado, com a ordem de prioridade:
/// 1. foto enviada pelo app (Firestore, via [UsuarioService.fotoBytes]);
/// 2. [photoUrl] da conta (ex.: login Google);
/// 3. ícone genérico de pessoa.
///
/// Atualiza em tempo real: ao salvar uma foto nova em "Editar perfil",
/// todos os avatares do app trocam sozinhos.
class FotoPerfil extends StatefulWidget {
  final double radius;

  /// URL de foto da conta (fallback quando não há foto enviada no app).
  final String? photoUrl;

  const FotoPerfil({super.key, this.radius = 42, this.photoUrl});

  @override
  State<FotoPerfil> createState() => _FotoPerfilState();
}

class _FotoPerfilState extends State<FotoPerfil> {
  // Stream criada uma vez: rebuilds não reabrem a consulta no Firestore.
  late final _foto = UsuarioService().fotoBytes();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Uint8List?>(
      stream: _foto,
      builder: (context, snap) {
        final bytes = snap.data;
        final ImageProvider? imagem = bytes != null
            ? MemoryImage(bytes)
            : (widget.photoUrl != null
                ? NetworkImage(widget.photoUrl!)
                : null);
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.white,
          backgroundImage: imagem,
          child: imagem == null
              ? Icon(Icons.person,
                  color: const Color(0xFF3BA135), size: widget.radius * 1.1)
              : null,
        );
      },
    );
  }
}
