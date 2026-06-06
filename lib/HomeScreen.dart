import 'package:flutter/material.dart';
import 'screen_base.dart';
import 'assets/widgets/hide_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HideBar(
      userEmail: 'seuemail@gmail.com',
      onLogout: () {
        // TODO: lógica de logout (ex: FirebaseAuth.instance.signOut())
      },
      onEditarPerfil: () {},
      onAtividades: () {},
      onConfiguracoes: () {},
      onGerenciarDados: () {},
      onExportarDados: () {},
      child: BaseScreen(
        title: 'GSPR',
        child: const Center(
          child: Text('Tela inicial do sistema'),
        ),
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