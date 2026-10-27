import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_grade/main.dart';
import 'package:easy_grade/data/session_store.dart';
import 'package:easy_grade/models/avaliacao.dart';
import 'package:easy_grade/models/status_avaliacao.dart';
import 'package:easy_grade/models/correcao.dart';
import 'package:easy_grade/screens/auth_screens.dart';
import 'package:easy_grade/screens/apoio_screens.dart';
import 'package:easy_grade/screens/criar_avaliacao_screen.dart';
import 'package:easy_grade/screens/detalhes_avaliacao_screen.dart';
import 'package:easy_grade/screens/gabarito_screen.dart';
import 'package:easy_grade/screens/historico_screen.dart';
import 'package:easy_grade/screens/home_screen.dart';
import 'package:easy_grade/screens/leitura_screen.dart';
import 'package:easy_grade/screens/perfil_screen.dart';
import 'package:easy_grade/screens/preparacao_screens.dart';
import 'package:easy_grade/screens/resultados_screen.dart';
import 'package:easy_grade/screens/splash_screen.dart';
import 'package:easy_grade/screens/layout_prova_screen.dart';
import 'package:easy_grade/theme/app_theme.dart';

SessionStore _criarStoreComDados() {
  final store = SessionStore();
  store.adicionarTurma('2ª fase B');
  store.adicionarAluno('2ª fase B', const Aluno('a1', 'Aluno 1'));
  store.adicionarTurma('3ª fase A');
  store.adicionarAluno('3ª fase A', const Aluno('2026001', 'Aluno de Exemplo'));
  store.salvar(const Avaliacao(
    id: '1',
    codigo: 'EVAL-2026-N1',
    nome: 'Prova N1 — Lógica',
    disciplina: 'Lógica',
    turma: '3ª fase A',
    data: null,
    numQuestoes: 5,
    numAlternativas: 5,
    status: StatusAvaliacao.concluida,
  ));
  store.salvarGabarito('1', [0, 1, 2, 3, 4]);
  store.salvarCorrecao(
    '1',
    Correcao(
      alunoId: '2026001',
      alunoNome: 'Aluno de Exemplo',
      respostas: [0, 1, 2, 3, 4],
      lidaEm: DateTime(2026, 9, 28, 20, 0),
    ),
  );
  store.salvar(const Avaliacao(
    id: '2',
    codigo: 'EVAL-2026-N2',
    nome: 'Revisão — Algoritmos',
    disciplina: 'Algoritmos e Estrutura de Dados',
    turma: '2ª fase B',
    data: null,
    numQuestoes: 10,
    numAlternativas: 4,
    status: StatusAvaliacao.agendada,
  ));
  store.salvarGabarito('2', [0, 1, 2, 3, 0, 1, 2, 3, 0, 1]);
  return store;
}

Widget harness(SessionStore store, Widget screen, {double scale = 1}) =>
    SessionScope(
        store: store,
        child: MaterialApp(
            theme: buildAppTheme(),
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: screen));

Future<void> login(WidgetTester tester, [SessionStore? store]) async {
  await tester.pumpWidget(N1App(store: store));
  await tester.pumpAndSettle();
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), 'User');
  await tester.enterText(fields.at(1), 'User');
  await tester.ensureVisible(find.text('Entrar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
  });
  testWidgets('abertura, acesso e navegação preservam a busca', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _criarStoreComDados();
    addTearDown(store.dispose);
    await login(tester, store);
    expect(find.text('Olá, User.'), findsOneWidget);
    await tester.tap(find.text('Avaliações', skipOffstage: true));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Lógica');
    await tester.pumpAndSettle();
    expect(find.text('1 avaliação'), findsOneWidget);
    await tester.tap(find.text('Perfil', skipOffstage: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avaliações', skipOffstage: true));
    await tester.pumpAndSettle();
    expect(find.text('1 avaliação'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fluxo de leitura exige revisão e registra a nota do aluno',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _criarStoreComDados();
    addTearDown(store.dispose);
    await tester
        .pumpWidget(harness(store, const CapturaScreen(avaliacaoId: '2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Identificar QR de demonstração'));
    await tester.pumpAndSettle();
    expect(find.text('Ler folha de demonstração'), findsOneWidget);
    await tester.tap(find.text('Ler folha de demonstração'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar marcações'), findsOneWidget);
    await tester.tap(find.text('Revisar 2 marcações para confirmar'));
    await tester.pumpAndSettle();
    expect(store.correcoes('2'), isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registrar em branco').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar em branco').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registrar em branco').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar em branco').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar correção'));
    await tester.pumpAndSettle();
    expect(store.correcoes('2'), hasLength(1));
    expect(store.correcoes('2').first.precisaRevisao, isFalse);
    expect(find.text('Resultado individual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendário abre em português e permite confirmar a data',
      (tester) async {
    final store = SessionStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(harness(store, const CriarAvaliacaoScreen()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Escolher data'), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escolher data'));
    await tester.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Selecionar'), findsOneWidget);
    await tester.tap(find.text('Selecionar'));
    await tester.pumpAndSettle();
    expect(find.text('Remover data'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduzir movimento pula a abertura sem erro de reconstrução',
      (tester) async {
    final store = SessionStore()..movimento(true);
    addTearDown(store.dispose);
    await tester.pumpWidget(N1App(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo de volta.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('telas sem overflow em ${width.toInt()}px com fonte ampliada',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = _criarStoreComDados();
      addTearDown(store.dispose);
      final screens = <Widget>[
        LoginScreen(onLogin: () {}),
        CadastroScreen(onLogin: () {}),
        const RecuperarSenhaScreen(),
        HomePage(onNavigateTab: (_) {}),
        const HistoricoScreen(),
        const CriarAvaliacaoScreen(),
        const SucessoAvaliacaoScreen(avaliacaoId: '2'),
        const DetalhesAvaliacaoScreen(avaliacaoId: '1'),
        const GabaritoScreen(avaliacaoId: '2'),
        const SelecionarLeituraScreen(),
        const CapturaScreen(avaliacaoId: '2'),
        RevisaoScreen(
            avaliacaoId: '2',
            correcao: Correcao(
                alunoId: 't',
                alunoNome: 'Aluno de exemplo',
                respostas: [0, 1, -1, null, -2, 1, 2, 3, 0, 1])),
        const ResultadosScreen(avaliacaoId: '1'),
        const ResultadoAlunoScreen(avaliacaoId: '1', alunoId: '2026001'),
        const EstatisticasScreen(avaliacaoId: '1'),
        const RelatorioScreen(avaliacaoId: '1'),
        const MateriaisScreen(avaliacaoId: '1'),
        const LayoutProvaScreen(avaliacaoId: '1'),
        const TurmasScreen(),
        const AlunosScreen(turma: '3ª fase A'),
        const ImportarAlunosScreen(turma: '3ª fase A'),
        const NovoAlunoScreen(turma: '3ª fase A'),
        const QuestoesScreen(),
        const NovaQuestaoScreen(),
        PerfilScreen(onLogout: () {}),
        const EditarUsuarioScreen(),
        const AlterarSenhaScreen(),
        const ConfiguracoesScreen(),
        const AjudaScreen(),
        SplashScreen(onComplete: () {}),
      ];
      for (final screen in screens) {
        await tester.pumpWidget(harness(
            store, KeyedSubtree(key: UniqueKey(), child: screen),
            scale: 1.3));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '${screen.runtimeType} com largura $width');
      }
    });
  }
}
