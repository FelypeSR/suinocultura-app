import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gspr/screen_base.dart';
import 'assets/widgets/primary__button.dart';
import 'routes.dart';

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
    return BaseScreen(
      title: 'GSPR',
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // USUÁRIO
            const Text(
              'usuário:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'email do usuário',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // SENHA
            const Text(
              'senha:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _senhaCtrl,
              obscureText: true,
              onSubmitted: (_) => _signInWithEmail(),
              decoration: InputDecoration(
                hintText: 'senha',
                prefixIcon: const Icon(Icons.lock_outline),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ESQUECEU SENHA
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(Rotas.recuperarSenha);
                },
                child: const Text(
                  'Esqueceu a senha?',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // BOTÃO DE LOGIN POR EMAIL/SENHA
            Center(
              child: _loading
                  ? const CircularProgressIndicator(color: Color(0xFF2E7D32))
                  : PrimaryButton(
                      text: 'ENTRAR',
                      icon: Icons.check,
                      onPressed: _signInWithEmail,
                    ),
            ),

            const SizedBox(height: 40),

            // BOTÃO GOOGLE — usa imagem separada porque não é um ícone do Material.
            // Quando pressionado chama _signInWithGoogle().
            // Enquanto o login está em andamento (_loading = true), exibe um
            // indicador de progresso no lugar do ícone e bloqueia novos toques.
            Center(
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Image.asset(
                        'lib/assets/widgets/itens/google.png',
                        height: 24,
                      ),
                label: const Text(
                  'Login com Gmail',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // LINK PARA CADASTRO DE NOVO USUÁRIO
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context)
                        .pushNamed(Rotas.cadastroUsuario),
                child: const Text.rich(
                  TextSpan(
                    text: 'Não tem conta? ',
                    style: TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: 'Cadastre-se',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
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