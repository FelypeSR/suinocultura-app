import 'package:flutter/material.dart';
import 'package:gspr/screen_base.dart';
import 'assets/widgets/primary__button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
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
              obscureText: true,
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
                onPressed: () {},
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

            // BOTÃO SALVAR (AGORA REUTILIZÁVEL)
            Center(
              child:PrimaryButton(
                text: 'SALVAR',
                icon: Icons.check,
                onPressed: () {
                  // lógica de login aqui
                },
              ),
            ),

            const SizedBox(height: 40),

            // BOTÃO GOOGLE (mantive separado porque tem imagem)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: Image.asset(
                  'assets/itens/google.png', /// tu vai precisar colocar imagem aqui
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
          ],
        ),
      ),
    );
  }
}