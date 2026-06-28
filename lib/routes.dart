import 'package:flutter/material.dart';
import 'screens/LoginScreen.dart';
import 'screens/HomeScreen.dart';
import 'screens/RecoverScreen.dart';
import 'screens/CadastroScreen.dart';
import 'screens/EditarAnimalScreen.dart';
import 'screens/CadastroNinhadaScreen.dart';
import 'screens/CadastroUsuarioScreen.dart';
import 'screens/RegistroVacinaScreen.dart';
import 'screens/EstoqueRacaoScreen.dart';

/// Rotas nomeadas do app, centralizadas em um único lugar.
///
/// Uso: `Navigator.pushNamed(context, Rotas.estoqueRacao);`
class Rotas {
  Rotas._();

  // Nomes das rotas
  static const String inicio = '/'; // tela principal com a navbar
  static const String login = '/login';
  static const String cadastroUsuario = '/cadastro-usuario';
  static const String recuperarSenha = '/recuperar-senha';
  static const String painel = '/painel'; // HomeScreen (dashboard/perfil)
  static const String cadastroAnimal = '/cadastro-animal';
  static const String editarAnimal = '/editar-animal';
  static const String cadastroNinhada = '/cadastro-ninhada';
  static const String registroVacina = '/registro-vacina';
  static const String estoqueRacao = '/estoque-racao';
  static const String cadastroRacao = '/cadastro-racao';

  // Mapa nome -> construtor da tela.
  // A raiz ('/') é tratada pelo AuthGate (home do MaterialApp), por isso
  // 'inicio' não entra aqui — evita conflito com o `home:`.
  static final Map<String, WidgetBuilder> mapa = {
    login: (_) => const LoginScreen(),
    cadastroUsuario: (_) => const CadastroUsuarioScreen(),
    recuperarSenha: (_) => const RecoverScreen(),
    painel: (_) => const HomeScreen(),
    cadastroAnimal: (_) => const CadastroScreen(),
    editarAnimal: (_) => const EditarAnimalScreen(),
    cadastroNinhada: (_) => const CadastroNinhadaScreen(),
    registroVacina: (_) => const RegistroVacinaScreen(),
    estoqueRacao: (_) => EstoqueRacaoScreen(),
    cadastroRacao: (_) => const CadastroRacaoScreen(),
  };
}