import 'package:flutter/material.dart';
import 'screen_base.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'GSPR',
      child: const Center(
        child: Text('Tela inicial do sistema'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Perfil',
      child: const Text('Perfil do usuário'),
    );
  }
}
