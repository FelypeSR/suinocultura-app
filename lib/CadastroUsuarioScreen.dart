import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen_base.dart';

const _verde = Color(0xFF2E7D32);

/// Tela de cadastro de novo usuário (nome + email + senha).
/// Cria a conta no Firebase Auth e grava o nome via updateDisplayName,
/// para que ele apareça no app. Após o sucesso, o AuthGate leva à home.
class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _senhaCtrl.text,
      );
      // Grava o nome na conta e recarrega para o app já enxergar.
      await cred.user?.updateDisplayName(_nomeCtrl.text.trim());
      await cred.user?.reload();
      // Navegação tratada pelo AuthGate após a mudança de estado.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(e.code))),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: $e')),
      );
      setState(() => _loading = false);
    }
  }

  String _mensagemErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este email já está cadastrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'weak-password':
        return 'Senha muito fraca (use 6+ caracteres)';
      case 'operation-not-allowed':
        return 'Cadastro por email/senha não está habilitado';
      default:
        return 'Falha no cadastro ($code)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Cadastro',
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
                    'Criar conta',
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

              _campo(
                controller: _nomeCtrl,
                label: 'Nome',
                hint: 'seu nome',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe seu nome'
                    : null,
              ),
              const SizedBox(height: 16),

              _campo(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'email@exemplo.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o email';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _campo(
                controller: _senhaCtrl,
                label: 'Senha',
                hint: 'mínimo 6 caracteres',
                icon: Icons.lock_outline,
                obscure: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a senha';
                  if (v.length < 6) return 'Use 6 ou mais caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Center(
                child: _loading
                    ? const CircularProgressIndicator(color: _verde)
                    : ElevatedButton.icon(
                        onPressed: _cadastrar,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'CADASTRAR',
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

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autocorrect: false,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}