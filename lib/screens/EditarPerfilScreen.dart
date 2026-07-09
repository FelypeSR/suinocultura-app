import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/theme/app_theme.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:gspr/assets/widgets/itens/foto_perfil.dart';
import 'package:gspr/services/usuario_service.dart';

const _verde = Color(0xFF2E7D32);

/// Edição de perfil do usuário logado: nome (Firebase Auth) e foto
/// (enviada da galeria e salva no Firestore via [UsuarioService]).
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioService = UsuarioService();
  bool _salvando = false;

  // Nome atual da conta preenche o campo.
  final _nomeCtrl = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.displayName ?? '',
  );

  /// Foto recém-escolhida na galeria (preview antes de salvar).
  Uint8List? _fotoNova;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  /// Abre a galeria já redimensionando/comprimindo no lado nativo
  /// (~400px, qualidade 70) — suficiente para avatar e leve no Firestore.
  Future<void> _escolherFoto() async {
    try {
      final arquivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (arquivo == null) return; // usuário cancelou
      final bytes = await arquivo.readAsBytes();
      if (mounted) setState(() => _fotoNova = bytes);
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Erro ao abrir a galeria: $e');
    }
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final nome = _nomeCtrl.text.trim();

      // Nome no Firebase Auth (o header usa userChanges() e atualiza sozinho).
      if (nome != (user?.displayName ?? '')) {
        await user?.updateDisplayName(nome);
        await user?.reload();
      }

      // Foto no Firestore (todos os avatares escutam a mesma stream).
      if (_fotoNova != null) {
        await _usuarioService.salvarFoto(_fotoNova!);
      }

      if (!mounted) return;
      context.showSuccessSnackBar('Perfil atualizado com sucesso!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Erro ao salvar o perfil: $e');
      setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return BaseScreen(
      title: 'Perfil',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Editar perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.cancel_outlined,
                        color: Colors.red, size: 32),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Foto: preview da nova (se escolhida) ou a atual; o lápis
              // sobreposto abre a galeria.
              Center(
                child: GestureDetector(
                  onTap: _escolherFoto,
                  child: Stack(
                    children: [
                      _fotoNova != null
                          ? CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.white,
                              backgroundImage: MemoryImage(_fotoNova!),
                            )
                          : FotoPerfil(radius: 56, photoUrl: user?.photoURL),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: _verde,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _escolherFoto,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Alterar foto'),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Nome',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeCtrl,
                autocorrect: false,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe seu nome'
                    : null,
                decoration: InputDecoration(
                  hintText: 'seu nome',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Email é só informativo (não editável por aqui).
              Text(
                user?.email ?? '',
                style: const TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 32),

              Center(
                child: _salvando
                    ? const LoadingBolinhas()
                    : ElevatedButton.icon(
                        onPressed: _salvar,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'SALVAR',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _verde,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
