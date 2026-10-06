import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/session_store.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/leitura_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bottom_nav.dart';

void main() => runApp(const N1App());

class N1App extends StatefulWidget {
  final SessionStore? store;
  const N1App({super.key, this.store});
  @override
  State<N1App> createState() => _N1AppState();
}

class _N1AppState extends State<N1App> {
  late final SessionStore _store = widget.store ?? SessionStore();
  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SessionScope(
      store: _store,
      child: MaterialApp(
        title: 'EasyGrade',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) {
          final media = MediaQuery.of(context);
          final store = SessionScope.of(context);
          return Container(
              color: AppColors.pageBackground,
              alignment: Alignment.center,
              child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  decoration: const BoxDecoration(boxShadow: [
                    BoxShadow(color: Color(0x16342047), blurRadius: 40)
                  ]),
                  child: MediaQuery(
                      data: media.copyWith(
                          size: Size(math.min(600, media.size.width),
                              media.size.height),
                          disableAnimations: store.reduzirMovimento ||
                              media.disableAnimations),
                      child: child!)));
        },
        home: const AuthenticationGate(),
      ));
}

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({super.key});
  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  bool _abriu = false, _autenticado = false;
  @override
  Widget build(BuildContext context) {
    if (!_abriu) {
      return SplashScreen(onComplete: () => setState(() => _abriu = true));
    }
    if (!_autenticado) {
      return LoginScreen(onLogin: () => setState(() => _autenticado = true));
    }
    return MainNavigationShell(
        onLogout: () => setState(() => _autenticado = false));
  }
}

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  final VoidCallback onLogout;
  const MainNavigationShell(
      {super.key, this.initialIndex = 0, required this.onLogout});
  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _index = widget.initialIndex;
  void _navigate(int i) => setState(() => _index = i);
  @override
  Widget build(BuildContext context) => Scaffold(
      body: IndexedStack(index: _index, children: [
        HomePage(onNavigateTab: _navigate),
        const HistoricoScreen(),
        const SelecionarLeituraScreen(),
        PerfilScreen(onLogout: widget.onLogout)
      ]),
      bottomNavigationBar:
          AppBottomNav(currentIndex: _index, onTap: _navigate));
}
