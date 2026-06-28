import 'package:flutter/material.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/assets/widgets/primary__button.dart';

class RecoverScreen extends StatefulWidget {
  const RecoverScreen({super.key});

  @override
  State<RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends State<RecoverScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendRecoveryEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showDialog('Campo obrigatório', 'Por favor, insira seu e-mail.');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      if (e.code == 'user-not-found') {
        _showDialog(
          'E-mail não cadastrado',
          'Não encontramos nenhuma conta com o e-mail informado. Verifique e tente novamente.',
        );
      } else {
        _showDialog('Erro', 'Não foi possível enviar o e-mail. Tente novamente.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'GSPR',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            Image.asset(
              'lib/assets/widgets/itens/recover.png',
              height: 160,
            ),

            const SizedBox(height: 24),

            const Text(
              'Recuperar senha',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Informe seu e-mail cadastrado e enviaremos\num link para redefinir sua senha.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 32),

            if (_emailSent) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2E7D32)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'E-mail enviado! Verifique sua caixa de entrada.',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ] else ...[
              Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'e-mail:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'seu@email.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: _loading
                    ? const LoadingBolinhas()
                    : PrimaryButton(
                        text: 'ENVIAR',
                        icon: Icons.send,
                        onPressed: _sendRecoveryEmail,
                      ),
              ),
              const SizedBox(height: 16),
            ],

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Voltar ao login',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}