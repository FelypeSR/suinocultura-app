import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen_base.dart';
import 'assets/widgets/hide_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lê o usuário atualmente logado no Firebase.
    // Após o login com Google, este objeto contém email, nome e photoURL
    // (a foto de perfil da conta Google do usuário).
    final user = FirebaseAuth.instance.currentUser;

    return HideBar(
      // Passa o email real do usuário logado para o painel lateral
      userEmail: user?.email ?? '',

      // Passa a URL da foto de perfil do Google para o painel lateral.
      // Será null se o login não for via Google (sem foto).
      photoUrl: user?.photoURL,

      onLogout: () async {
        // Encerra a sessão no Firebase e no Google Sign-In
        await FirebaseAuth.instance.signOut();
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
