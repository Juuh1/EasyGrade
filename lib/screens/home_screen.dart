import 'package:flutter/material.dart';

import '../screens/perfil_screen.dart';
import '../widgets/app_bottom_nav.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const HomePage({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    // Pegando as cores diretamente do tema do projeto
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final surfaceColor = theme.colorScheme.surface;

    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Column(
                children: [
                  // =====================================
                  // CABEÇALHO
                  // =====================================

                  Container(
                    width: double.infinity,
                    height: 86,
                    color: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 38,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Olá User!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =====================================
                  // LOGO EASYGRADE
                  // =====================================

                  Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            color: primaryColor,
                            size: 55,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              color: surfaceColor,
                              child: Icon(
                                Icons.check_circle_outline,
                                color: primaryColor,
                                size: 37,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EasyGrade',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 58),

                  // =====================================
                  // MINHAS AVALIAÇÕES
                  // =====================================

                  MenuButton(
                    texto: 'Minhas Avaliações',
                    onPressed: () {
                      // Índice 2 = Histórico
                      onNavigateTab(2);
                    },
                  ),

                  const SizedBox(height: 23),

                  // =====================================
                  // NOVA AVALIAÇÃO
                  // =====================================

                  MenuButton(
                    texto: 'Nova avaliação',
                    onPressed: () {
                      // Índice 1 = Criar Avaliação
                      onNavigateTab(1);
                    },
                  ),

                  const SizedBox(height: 23),

                  // =====================================
                  // MEU PERFIL
                  // =====================================

                  MenuButton(
                    texto: 'Meu perfil',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PerfilScreen(onNavigateTab: onNavigateTab),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // =====================================
      // MENU INFERIOR DO PROJETO
      // =====================================

      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: onNavigateTab,
      ),
    );
  }
}

// =====================================
// BOTÃO PERSONALIZADO
// =====================================

class MenuButton extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.texto,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 400,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
