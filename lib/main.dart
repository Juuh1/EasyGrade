import 'package:flutter/material.dart';

import 'screens/historico_screen.dart';
import 'theme/app_theme.dart';

/// Entry point usado para rodar/demonstrar isoladamente o Módulo
/// Listagem & Domínio (Membro 2). Quando o app for integrado ao restante
/// do projeto (Home, Criar avaliação), a rota inicial deve voltar a ser a
/// Home, ficando o Histórico acessível pela bottom nav.
void main() {
  runApp(const N1App());
}

class N1App extends StatelessWidget {
  const N1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Correção Automatizada — N1',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HistoricoScreen(),
    );
  }
}
