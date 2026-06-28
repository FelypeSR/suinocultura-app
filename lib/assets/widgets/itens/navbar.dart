import 'package:flutter/material.dart';

/// Barra de navegação flutuante e arredondada, sobreposta ao conteúdo.
///
/// Cores vêm do tema central (Material 3): fundo em `inverseSurface` (neutro
/// escuro que harmoniza com a identidade verde) e anel de seleção em `primary`.
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      height: 65,
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(colors, 0, Icons.home_rounded),
          // Botão de ação central: abre um menu com "Cadastrar suíno" e
          // "Adicionar ração". Destacado (círculo preenchido) para deixar
          // claro que é uma ação, não uma aba.
          _buildActionItem(colors, 1, Icons.pets),
          _buildNavItem(colors, 2, Icons.file_download_outlined),
          _buildNavItem(colors, 3, Icons.bar_chart_rounded),
          _buildNavItem(colors, 4, Icons.settings),
        ],
      ),
    );
  }

  /// Botão de ação em destaque (usado no item central). Diferente das abas,
  /// é um círculo preenchido com `primary` que dispara um menu de opções.
  Widget _buildActionItem(ColorScheme colors, int index, IconData icon) {
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.primary,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: colors.onPrimary, size: 30),
      ),
    );
  }

  Widget _buildNavItem(ColorScheme colors, int index, IconData icon) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Anel verde quando selecionado; transparente quando não.
          border: Border.all(
            color: isSelected ? colors.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.primary : colors.onInverseSurface,
          size: 30,
        ),
      ),
    );
  }
}
