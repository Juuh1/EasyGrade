import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'screens/criar_avaliacao_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/sucesso_avaliacao_screen.dart';
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
      home: const MainNavigationShell(),
    );
  }
}

// Navegação principal
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({super.key, this.initialIndex = 1});

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
        return _HomeScreenPlaceholder(onNavigateTab: _onTabChanged);
      case 1:
        return CriarAvaliacaoScreen(onNavigateTab: _onTabChanged);
      case 2:
        return HistoricoScreen(onNavigateTab: _onTabChanged);
      default:
        return CriarAvaliacaoScreen(onNavigateTab: _onTabChanged);
    }
  }
}

// Placeholder Home
class _HomeScreenPlaceholder extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;

  const _HomeScreenPlaceholder({required this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Página Inicial',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecione uma opção no menu inferior para navegar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => onNavigateTab(1),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Criar Avaliação'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SucessoAvaliacaoScreen(
                        avaliacao: MockData.avaliacoes.first,
                        onNavigateTab: onNavigateTab,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline,
                    color: AppColors.deepNavy),
                label: const Text(
                  'Ver Tela de Sucesso)',
                  style: TextStyle(
                    color: AppColors.deepNavy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: AppColors.deepNavy, width: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: onNavigateTab,
      ),
    );
  }
}
