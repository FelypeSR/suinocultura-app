import 'package:flutter/material.dart';
import 'package:gspr/assets/widgets/loading_bolinhas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gspr/screen_base.dart';
import 'package:gspr/assets/widgets/primary__button.dart';
import 'package:gspr/routes.dart';

// StatefulWidget porque precisamos controlar o estado de carregamento
// enquanto o login com o Google está em andamento.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false; // controla se o botão está bloqueado durante o login

  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  // Login com email e senha. Após o sucesso, o AuthGate troca para a home
  // automaticamente (reage à mudança de authStateChanges).
  Future<void> _signInWithEmail() async {
    if (_loading) return;
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    if (email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha email e senha')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      // Navegação tratada pelo AuthGate.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensagemErro(e.code))),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar: $e')),
      );
      setState(() => _loading = false);
    }
  }

  String _mensagemErro(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email inválido';
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou senha incorretos';
      case 'user-disabled':
        return 'Usuário desativado';
      case 'too-many-requests':
        return 'Muitas tentativas. Tente novamente mais tarde';
      default:
        return 'Falha no login ($code)';
    }
  }

  // Realiza o login com o Google e depois autentica no Firebase.
  // Após sucesso, navega para a HomeScreen substituindo a tela atual.
  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);

    try {
      // Abre a janela de seleção de conta do Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Se o usuário fechou a janela sem escolher uma conta, cancela
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      // Obtém os tokens de acesso e identidade da conta Google escolhida
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Cria a credencial do Firebase usando os tokens do Google
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autentica no Firebase com a credencial do Google.
      // Após isso, FirebaseAuth.instance.currentUser estará preenchido,
      // incluindo o photoURL que exibimos na HomeScreen.
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Navegação tratada pelo AuthGate após a mudança de estado.
    } catch (e) {
      // Exibe um aviso rápido caso o login falhe por qualquer motivo
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao entrar com Google: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return BaseScreen(
      title: 'GSPR',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo de volta',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Entre para gerenciar sua granja',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // USUÁRIO
            Text('Usuário', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'email do usuário',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: 20),

            // SENHA
            Text('Senha', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _senhaCtrl,
              obscureText: true,
              onSubmitted: (_) => _signInWithEmail(),
              decoration: const InputDecoration(
                hintText: 'senha',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 8),

            // ESQUECEU SENHA
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Rotas.recuperarSenha);
                },
                child: const Text('Esqueceu a senha?'),
              ),
            ),

            const SizedBox(height: 16),

            // BOTÃO DE LOGIN POR EMAIL/SENHA (compacto, centralizado)
            Center(
              child: _loading
                  ? const LoadingBolinhas()
                  : PrimaryButton(
                      text: 'ENTRAR',
                      icon: Icons.check,
                      onPressed: _signInWithEmail,
                    ),
            ),

            const SizedBox(height: 28),

            // Separador "ou"
            Row(
              children: [
                Expanded(child: Divider(color: colors.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ou',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colors.outlineVariant)),
              ],
            ),

            const SizedBox(height: 24),

            // BOTÃO GOOGLE — a imagem google.png já é um botão completo
            // ("Login com Gmail"), então ela mesma é o alvo de toque. Evita
            // repetir o texto que antes vinha como label ao lado.
            // Durante o login (_loading) mostra um indicador no lugar.
            Center(
              child: _loading
                  ? const LoadingBolinhas()
                  : InkWell(
                      onTap: _signInWithGoogle,
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'lib/assets/widgets/itens/google.png',
                        height: 52,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // LINK PARA CADASTRO DE NOVO USUÁRIO
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context)
                        .pushNamed(Rotas.cadastroUsuario),
                child: Text.rich(
                  TextSpan(
                    text: 'Não tem conta? ',
                    style: TextStyle(color: colors.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: 'Cadastre-se',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}