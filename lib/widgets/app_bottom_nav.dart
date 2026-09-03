import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Barra inferior reaproveitada nas telas deste módulo. As abas "Home" e
/// "Criar" são responsabilidade de outros membros do grupo — aqui elas
/// aparecem apenas como destino de navegação (placeholder) para manter a
/// experiência coerente com o restante do app mockado no Figma.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.surface,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Criar'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
      ],
    );
  }
}
