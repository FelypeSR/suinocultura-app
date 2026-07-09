import 'package:flutter/material.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/routes.dart';
import 'package:gspr/theme/app_theme.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:gspr/services/dados_service.dart';

const _verde = Color(0xFF2E7D32);

/// Tela de configurações do app.
///
/// Reúne as opções da conta e dos dados da granja:
/// - Editar dados do usuário (leva para a tela de perfil);
/// - Limpar dados (apaga todo o banco de dados da granja, com confirmação).
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  /// true enquanto a limpeza do banco está em andamento (trava a tela).
  bool _limpando = false;

  /// Abre o diálogo de confirmação; a exclusão só roda se o usuário digitar
  /// APAGAR — barreira extra porque a ação não tem volta.
  Future<void> _confirmarLimpeza() async {
    final ctrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final liberado = ctrl.text.trim().toUpperCase() == 'APAGAR';
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Expanded(child: Text('Limpar dados?')),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Todos os registros da granja serão apagados:\n\n'
                  '• Suínos e histórico de coberturas\n'
                  '• Ninhadas\n'
                  '• Vacinações e eventos\n'
                  '• Estoque de ração\n',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const Text(
                  'Essa ação não pode ser desfeita.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (_) => setStateDialog(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Digite APAGAR para confirmar',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(64, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                // Fica desabilitado até o usuário digitar APAGAR.
                onPressed: liberado
                    ? () => Navigator.pop(dialogContext, true)
                    : null,
                child: const Text('Apagar tudo'),
              ),
            ],
          );
        },
      ),
    );

    ctrl.dispose();
    if (confirmado != true || !mounted) return;
    await _limparDados();
  }

  Future<void> _limparDados() async {
    setState(() => _limpando = true);
    try {
      final removidos = await DadosService().limparBanco();
      if (!mounted) return;
      context.showSuccessSnackBar(
        removidos == 0
            ? 'Nenhum registro para apagar — o banco já estava vazio.'
            : 'Dados apagados com sucesso! ($removidos registros removidos)',
      );
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Erro ao limpar os dados: $e');
    } finally {
      if (mounted) setState(() => _limpando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Configurações',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _limpando ? null : () => Navigator.pop(context),
                  child: const Icon(Icons.cancel_outlined,
                      color: Colors.red, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Conta',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _OpcaoTile(
              icone: Icons.person_outline,
              titulo: 'Editar dados do usuário',
              subtitulo: 'Nome e foto de perfil',
              onTap: _limpando
                  ? null
                  : () => Navigator.pushNamed(context, Rotas.editarPerfil),
            ),
            const SizedBox(height: 28),

            const Text(
              'Granja',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _OpcaoTile(
              icone: Icons.group_outlined,
              titulo: 'Membros da granja',
              subtitulo: 'Convidar ou remover quem tem acesso',
              onTap: _limpando
                  ? null
                  : () => Navigator.pushNamed(context, Rotas.membrosGranja),
            ),
            const SizedBox(height: 28),

            const Text(
              'Dados',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            _limpando
                // Enquanto apaga, o tile vira um indicador de progresso.
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                    ),
                    child: const Column(
                      children: [
                        LoadingBolinhas(),
                        SizedBox(height: 12),
                        Text(
                          'Apagando os dados da granja...',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                : _OpcaoTile(
                    icone: Icons.delete_forever_outlined,
                    titulo: 'Limpar dados',
                    subtitulo: 'Apaga todos os registros da granja',
                    destrutiva: true,
                    onTap: _confirmarLimpeza,
                  ),
            const SizedBox(height: 12),
            const Text(
              'A limpeza remove suínos, ninhadas, vacinações e estoque de '
              'ração. Sua conta e seu perfil não são apagados.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de opção da tela: ícone em círculo, título, subtítulo e seta.
/// Com [destrutiva] = true, usa a paleta vermelha (ações perigosas).
class _OpcaoTile extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback? onTap;
  final bool destrutiva;

  const _OpcaoTile({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.destrutiva = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destrutiva ? Colors.red.shade700 : _verde;
    final fundo = destrutiva ? Colors.red.shade50 : Colors.grey.shade100;

    return Material(
      color: fundo,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cor.withValues(alpha: 0.12),
                child: Icon(icone, color: cor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: destrutiva ? cor : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: destrutiva ? cor : Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
