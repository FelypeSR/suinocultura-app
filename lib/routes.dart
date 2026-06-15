import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'HomeScreen.dart';
import 'RecoverScreen.dart';
import 'CadastroScreen.dart';
import 'CadastroUsuarioScreen.dart';
import 'RegistroVacinaScreen.dart';
import 'EstoqueRacaoScreen.dart';

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
    registroVacina: (_) => const RegistroVacinaScreen(),
    estoqueRacao: (_) => EstoqueRacaoScreen(),
    cadastroRacao: (_) => const CadastroRacaoScreen(),
  };
}