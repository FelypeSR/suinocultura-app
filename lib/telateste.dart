import 'package:flutter/material.dart';
import 'package:gspr/assets/widgets/itens/navbar.dart'; // Import da sua NavBar
import 'package:gspr/assets/widgets/itens/resumo_widget.dart'; // Import do seu ResumoWidget

class WidgetTestScreen extends StatefulWidget {
  const WidgetTestScreen({super.key});

  @override
  State<WidgetTestScreen> createState() => _WidgetTestScreenState();
}

class _WidgetTestScreenState extends State<WidgetTestScreen> {
  // Variável para controlar qual ícone está selecionado
  int _currentIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      
      // 1. ISSO É MUITO IMPORTANTE para a NavBar flutuar
      extendBody: true, 

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ResumoWidget(),
              const EventosProximosWidget(), 
            ],
          ),
        ),
      ),

      // 2. AQUI ENTRA A SUA NAVBAR!
      bottomNavigationBar: CustomFloatingNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index; // Atualiza a tela quando clicar em outro ícone
          });
        },
      ),
    );
  }
}

// Seu widget temporário mantido intacto
class EventosProximosWidget extends StatelessWidget {
  const EventosProximosWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text('Widget de Eventos Próximos'),
    );
  }
}