import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'screens/criar_avaliacao_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/login_screen.dart';
import 'screens/sucesso_avaliacao_screen.dart';
import 'screens/home_screen.dart';
import 'screens/perfil_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bottom_nav.dart';

void main() {
  runApp(const N1App());
}

class N1App extends StatelessWidget {
  const N1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Correção de Provas — Católica SC',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AuthenticationGate(),
    );
  }
}

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key});

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  bool _autenticado = false;

  @override
  Widget build(BuildContext context) {
    if (_autenticado) return const MainNavigationShell();
    return LoginScreen(onLogin: () => setState(() => _autenticado = true));
  }
}

// Navegação principal
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return HomePage(onNavigateTab: _onTabChanged);
      case 1:
        return CriarAvaliacaoScreen(onNavigateTab: _onTabChanged);
      case 2:
        return HistoricoScreen(onNavigateTab: _onTabChanged);
      case 3:
        return PerfilScreen(onNavigateTab: _onTabChanged);
      default:
        return CriarAvaliacaoScreen(onNavigateTab: _onTabChanged);
    }
  }
}
