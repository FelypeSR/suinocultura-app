import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/theme/app_theme.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:gspr/services/granja_service.dart';

/// Primeira tela de quem entrou mas ainda não participa de nenhuma granja
/// (conta recém-cadastrada ou primeiro login com Google).
///
/// Daqui o usuário cria a própria granja — ou aguarda ser convidado: o gate
/// (auth_gate.dart) observa as granjas em tempo real, então assim que o
/// e-mail dele for adicionado como membro esta tela dá lugar à home sozinha.
class BemVindoGranjaScreen extends StatefulWidget {
  const BemVindoGranjaScreen({super.key});

  @override
  State<BemVindoGranjaScreen> createState() => _BemVindoGranjaScreenState();
}

class _BemVindoGranjaScreenState extends State<BemVindoGranjaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  bool _criando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _criarGranja() async {
    if (_criando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _criando = true);
    try {
      await GranjaService().criar(_nomeCtrl.text);
      // Nada a navegar: o gate observa a stream de granjas e troca para a
      // home assim que a granja criada chegar.
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar('Erro ao criar a granja: $e');
      setState(() => _criando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final nome = user?.displayName ?? '';
    final email = user?.email ?? '';

    return BaseScreen(
      title: 'GSPR',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome.isEmpty ? 'Bem-vindo!' : 'Bem-vindo, $nome!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Para começar, crie a sua granja. Todos os registros do '
                'rebanho ficam guardados nela.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              const Text(
                'Nome da granja',
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomeCtrl,
                enabled: !_criando,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Dê um nome para a granja'
                    : null,
                decoration: const InputDecoration(
                  hintText: 'ex.: Granja Boa Vista',
                  prefixIcon: Icon(Icons.agriculture_outlined),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: _criando
                    ? const LoadingBolinhas()
                    : FilledButton.icon(
                        onPressed: _criarGranja,
                        icon: const Icon(Icons.add),
                        label: const Text('Criar granja'),
                      ),
              ),
              const SizedBox(height: 32),

              // Caminho de quem foi convidado para uma granja existente.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.mail_outline,
                            size: 20, color: Colors.black54),
                        SizedBox(width: 8),
                        Text(
                          'Foi convidado?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Peça para adicionarem o seu e-mail ($email) aos '
                      'membros da granja. Assim que for adicionado, ela '
                      'abre aqui automaticamente.',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sair e entrar com outra conta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
