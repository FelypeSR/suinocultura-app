import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/theme/app_theme.dart';
import 'package:gspr/models/granja_model.dart';
import 'package:gspr/services/granja_ativa.dart';
import 'package:gspr/services/granja_service.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';

const _verde = Color(0xFF2E7D32);

/// Membros da granja ativa: quem pode ver e editar os dados.
///
/// Convidar alguém = adicionar o e-mail aqui (a pessoa cria a conta com esse
/// e-mail e a granja abre para ela automaticamente). Remover revoga o acesso
/// na hora. O dono da granja não pode ser removido.
class MembrosGranjaScreen extends StatefulWidget {
  const MembrosGranjaScreen({super.key});

  @override
  State<MembrosGranjaScreen> createState() => _MembrosGranjaScreenState();
}

class _MembrosGranjaScreenState extends State<MembrosGranjaScreen> {
  final _service = GranjaService();

  Future<void> _adicionarMembro() async {
    final ctrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        title: const Text('Convidar membro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A pessoa passa a ver e editar todos os dados da granja. '
              'Peça para ela criar a conta no app com este mesmo e-mail.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'email@exemplo.com',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              onSubmitted: (v) => Navigator.pop(dialogContext, v.trim()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, ctrl.text.trim()),
            child: const Text('Convidar'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (email == null || email.isEmpty || !mounted) return;
    if (!email.contains('@') || !email.contains('.')) {
      context.showErrorSnackBar('E-mail inválido: $email');
      return;
    }
    try {
      await _service.adicionarMembro(GranjaAtiva.id!, email);
      if (!mounted) return;
      context.showSuccessSnackBar('$email agora é membro da granja!');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Erro ao convidar: $e');
    }
  }

  Future<void> _removerMembro(String email) async {
    final meuEmail =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        title: const Text('Remover membro?'),
        content: Text(
          email == meuEmail
              ? 'Você vai remover VOCÊ MESMO da granja e perder o acesso '
                  'aos dados dela.'
              : '$email vai perder o acesso aos dados da granja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    try {
      await _service.removerMembro(GranjaAtiva.id!, email);
      if (!mounted) return;
      context.showSuccessSnackBar('Acesso de $email removido.');
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Erro ao remover: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Membros',
      child: StreamBuilder<GranjaModel?>(
        stream: _service.observar(GranjaAtiva.id!),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar membros: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: LoadingBolinhas());
          }
          final granja = snapshot.data;
          if (granja == null) {
            return const Center(child: Text('Granja não encontrada.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        granja.nome,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.cancel_outlined,
                          color: Colors.red, size: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${granja.membros.length} membro(s) com acesso aos dados',
                  style:
                      const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),

                ...granja.membros.map((email) {
                  final ehDono = email == granja.dono;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                _verde.withValues(alpha: 0.12),
                            child: Icon(
                              ehDono
                                  ? Icons.star_outline
                                  : Icons.person_outline,
                              color: _verde,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (ehDono)
                                  const Text(
                                    'Dono da granja',
                                    style: TextStyle(
                                        fontSize: 12, color: _verde),
                                  ),
                              ],
                            ),
                          ),
                          if (!ehDono)
                            IconButton(
                              onPressed: () => _removerMembro(email),
                              icon: Icon(Icons.remove_circle_outline,
                                  color: Colors.red.shade400),
                              tooltip: 'Remover acesso',
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                Center(
                  child: FilledButton.icon(
                    onPressed: _adicionarMembro,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Convidar membro'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
