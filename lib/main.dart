import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/auth_service.dart';
import 'firebase_options.dart';
import 'data/session_store.dart';
import 'screens/auth_screens.dart';
import 'screens/home_screen.dart';
import 'screens/historico_screen.dart';
import 'screens/leitura_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_bottom_nav.dart';
import 'widgets/app_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(EasyGradeApp(authService: AuthService()));
}

class EasyGradeApp extends StatefulWidget {
  final SessionStore? store;
  final AuthService? authService;
  const EasyGradeApp({super.key, this.store, this.authService});
  @override
  State<EasyGradeApp> createState() => _EasyGradeAppState();
}

class _EasyGradeAppState extends State<EasyGradeApp> {
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
        home: AuthenticationGate(authService: widget.authService),
      ));
}

class AuthenticationGate extends StatefulWidget {
  final AuthService? authService;
  const AuthenticationGate({super.key, this.authService});
  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  bool _abriu = false;
  late final Stream<User?>? _conta =
      widget.authService?.auth.authStateChanges();
  @override
  Widget build(BuildContext context) {
    if (!_abriu) {
      return SplashScreen(onComplete: () => setState(() => _abriu = true));
    }
    final service = widget.authService;
    if (service != null) {
      return StreamBuilder<User?>(
          stream: _conta,
          initialData: service.auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null) {
              return LoginScreen(authService: service, onLogin: () {});
            }
            return _SessaoAutenticada(
                key: ValueKey(user.uid),
                user: user,
                service: service,
                store: SessionScope.of(context));
          });
    }
    return LoginScreen(onLogin: () {});
  }
}

class _SessaoAutenticada extends StatefulWidget {
  final User user;
  final AuthService service;
  final SessionStore store;
  const _SessaoAutenticada(
      {super.key,
      required this.user,
      required this.service,
      required this.store});
  @override
  State<_SessaoAutenticada> createState() => _SessaoAutenticadaState();
}

class _SessaoAutenticadaState extends State<_SessaoAutenticada> {
  late Future<void> _perfil = _carregar();

  @override
  void initState() {
    super.initState();
    widget.store.conectar(widget.service.dados, auth: widget.service);
  }

  @override
  void dispose() {
    widget.store.desconectar(notificar: false);
    super.dispose();
  }

  Future<void> _carregar() async {
    final perfil = await widget.service.carregarPerfil(widget.user);
    if (!mounted) return;
    widget.store.atualizarPerfil(perfil['nome'] as String,
        widget.user.email ?? '', perfil['instituicao'] as String? ?? '');
    widget.store.movimento(perfil['reduzirMovimento'] == true);
  }

  Future<void> _sair() async {
    try {
      await widget.service.sair();
    } catch (erro) {
      if (mounted) avisar(context, mensagemAutenticacao(erro));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
      future: _perfil,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: SafeArea(
                  child: Center(
                      child: Padding(
                          padding: const EdgeInsets.all(24),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const InfoBanner(
                                'Não foi possível carregar seu perfil. Confira a conexão e tente novamente.',
                                warning: true),
                            const SizedBox(height: 16),
                            ElevatedButton(
                                onPressed: () =>
                                    setState(() => _perfil = _carregar()),
                                child: const Text('Tentar novamente')),
                            TextButton(
                                onPressed: _sair,
                                child: const Text('Sair da conta')),
                          ])))));
        }
        return MainNavigationShell(onLogout: _sair);
      });
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
