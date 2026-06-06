import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// Tela principal para testar a NavBar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Cor de fundo da tela
      // extendBody é importante para a navbar ficar flutuando sobre o fundo
      extendBody: true, 
      body: Center(
        child: Text('Tela selecionada: $_currentIndex'),
      ),
      bottomNavigationBar: CustomFloatingNavBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

// --- WIDGET DA NAVBAR CUSTOMIZADA ---
class CustomFloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const CustomFloatingNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      height: 65,
      decoration: BoxDecoration(
        color: const Color(0xFF6B6B6B), // Cor cinza escuro da navbar
        borderRadius: BorderRadius.circular(40), // Bordas bem arredondadas
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_rounded),
          _buildNavItem(1, Icons.pets), // Placeholder para o Porco
          _buildNavItem(2, Icons.file_download_outlined), // Placeholder para o doc
          _buildNavItem(3, Icons.bar_chart_rounded),
          _buildNavItem(4, Icons.settings),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Adiciona a borda verde se estiver selecionado, senão fica transparente
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.transparent,
            width: 3,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
//extendBody: true: No Scaffold, isso permite que o corpo da tela vá até o final do dispositivo (por baixo da navbar).
// O Indicador de Seleção: Dentro do método _buildNavItem, usamos um AnimatedContainer com uma borda (border: Border.all).