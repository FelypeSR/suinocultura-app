import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gspr/screen_base.dart';

/// Tela mostrada quando o usuário fez login mas o e-mail dele não está na
/// lista de autorizados da granja (coleção `autorizados` do Firestore).
///
/// Sem essa tela, um usuário não autorizado cairia na home com todos os
/// carregamentos falhando por permissão negada.
class NaoAutorizadoScreen extends StatelessWidget {
  /// Reexecuta a checagem de autorização (útil logo após o responsável
  /// adicionar o e-mail à lista).
  final VoidCallback onTentarNovamente;

  const NaoAutorizadoScreen({super.key, required this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return BaseScreen(
      title: 'GSPR',
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.lock_outline,
                size: 72, color: Colors.orange.shade700),
            const SizedBox(height: 24),
            const Text(
              'Acesso não autorizado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A conta $email ainda não tem acesso aos dados desta granja.\n\n'
              'Peça ao responsável para autorizar o seu e-mail e toque em '
              '"Tentar novamente".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sair e entrar com outra conta'),
            ),
          ],
        ),
      ),
    );
  }
}
