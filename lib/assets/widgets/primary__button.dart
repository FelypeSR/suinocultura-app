import 'package:flutter/material.dart';

/// Botão de ação primária do app.
///
/// Usa o [FilledButton] do Material 3, então cor, formato e tipografia vêm do
/// tema central (`AppTheme`). Basta passar texto e, opcionalmente, um ícone.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
    );
  }
}