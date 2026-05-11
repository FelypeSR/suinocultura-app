import 'package:flutter/material.dart';
import 'screen_base.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'GSPR',
      child: Center(
        child: Text('Tela inicial do sistema'),
      ),
    );
  }
}