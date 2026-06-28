import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema central do app (Material Design 3).
///
/// Tudo que é "cor da marca" ou estilo padrão de componente fica aqui, para
/// que as telas consumam os tokens do tema (`Theme.of(context).colorScheme...`)
/// em vez de cravar cores na mão. Mantém a identidade verde "agro" do GSPR.
class AppColors {
  AppColors._();

  /// Verde principal da marca — usado como *seed* do ColorScheme MD3.
  static const Color seed = Color(0xFF2E7D32);

  /// Verdes do cabeçalho (gradiente claro -> escuro). Gradientes não fazem
  /// parte do ColorScheme, então ficam como constantes da marca.
  static const Color headerLight = Color(0xFF5ED84F);
  static const Color headerDark = Color(0xFF3BA135);

  /// Gradiente padrão dos cabeçalhos verdes (topo -> base).
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [headerLight, headerDark],
  );

  /// Cor de confirmação (SnackBars de sucesso). Verde da marca.
  static const Color success = seed;

  /// Conteúdo (texto/ícone) sobre [success].
  static const Color onSuccess = Colors.white;
}

/// Atalhos para exibir SnackBars padronizados em qualquer tela.
///
/// Uso: `context.showSuccessSnackBar('Animal cadastrado com sucesso!');`
/// Centraliza cor, ícone e formato, evitando que cada tela monte o seu.
extension AppSnackBars on BuildContext {
  /// SnackBar verde de confirmação, com ícone de check.
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.onSuccess),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.onSuccess),
                ),
              ),
            ],
          ),
        ),
      );
  }

  /// SnackBar de erro/aviso, usando a cor `error` do tema.
  void showErrorSnackBar(String message) {
    final scheme = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: scheme.error,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: scheme.onError),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onError),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

/// Fábrica do [ThemeData] do app.
class AppTheme {
  AppTheme._();

  /// Raio padrão de cantos arredondados usado em botões, inputs e cards.
  static const double radius = 14;

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );

    // Tipografia: Poppins dá um ar amigável e moderno, combinando com o app.
    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: baseTextTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      // Botões preenchidos (ação primária).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: const StadiumBorder(),
        ),
      ),

      // Botões elevados (mantidos para compatibilidade com telas atuais).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: const StadiumBorder(),
          elevation: 2,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      // Campos de texto preenchidos e arredondados, sem borda dura.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        prefixIconColor: colorScheme.onSurfaceVariant,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}