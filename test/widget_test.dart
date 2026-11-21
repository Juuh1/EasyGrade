import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_grade/main.dart';
import 'package:easy_grade/data/auth_service.dart';
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

Future<SessionStore> _criarStoreComDados() async {
  final store = SessionStore();
  await store.adicionarTurma('2ª fase B');
  await store.adicionarAluno('2ª fase B', const Aluno('a1', 'Aluno 1'));
  await store.adicionarTurma('3ª fase A');
  await store.adicionarAluno(
      '3ª fase A', const Aluno('2026001', 'Aluno de Exemplo'));
  await store.salvar(const Avaliacao(
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
  await store.salvarGabarito('1', [0, 1, 2, 3, 4]);
  await store.salvarCorrecao(
    '1',
    Correcao(
      alunoId: '2026001',
      alunoNome: 'Aluno de Exemplo',
      respostas: [0, 1, 2, 3, 4],
      lidaEm: DateTime(2026, 9, 28, 20, 0),
    ),
  );
  await store.salvar(const Avaliacao(
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
  await store.salvarGabarito('2', [0, 1, 2, 3, 0, 1, 2, 3, 0, 1]);
  return store;
}

class AcessoDeTeste implements AuthService {
  String? emailRecuperado;

  @override
  Future<void> recuperarSenha(String email) async => emailRecuperado = email;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  await tester
      .pumpWidget(harness(store!, MainNavigationShell(onLogout: () {})));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
  });
  testWidgets('navegação preserva a busca entre as abas', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await _criarStoreComDados();
    addTearDown(store.dispose);
    await login(tester, store);
    expect(find.text('Olá, Professor.'), findsOneWidget);
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
    final store = await _criarStoreComDados();
    addTearDown(store.dispose);
    await tester.pumpWidget(harness(
        store,
        RevisaoScreen(
            avaliacaoId: '2',
            correcao: Correcao(
                alunoId: 'a1',
                alunoNome: 'Aluno 1',
                respostas: [0, 1, -2, 3, -1, 1, 2, null, 0, 1]))));
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

  testWidgets('recuperação valida o e-mail e envia o link sem entrar na conta',
      (tester) async {
    final store = SessionStore();
    addTearDown(store.dispose);
    final auth = AcessoDeTeste();
    var entrou = false;
    await tester.pumpWidget(harness(store,
        LoginScreen(onLogin: () => entrou = true, authService: auth)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Esqueci minha senha'));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(auth.emailRecuperado, isNull);
    await tester.enterText(find.widgetWithText(TextFormField, 'E-mail da conta'),
        'professora@example.test');
    await tester.tap(find.text('Enviar link'));
    await tester.pumpAndSettle();
    expect(auth.emailRecuperado, 'professora@example.test');
    expect(entrou, isFalse);
    expect(find.textContaining('você receberá um link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 430.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('20 pesos legíveis e alinhados em ${width.toInt()}px, fonte $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = SessionStore();
        addTearDown(store.dispose);
        await tester.pumpWidget(
            harness(store, const CriarAvaliacaoScreen(), scale: scale));
        await tester.pumpAndSettle();
        final quantidade = find.widgetWithText(TextFormField, '10');
        await tester.ensureVisible(quantidade);
        await tester.enterText(quantidade, '20');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();

        Finder botao(int numero) => find.ancestor(
            of: find.text('Questão $numero'),
            matching: find.byType(OutlinedButton));
        final retangulos = [
          for (var numero = 1; numero <= 20; numero++)
            tester.getRect(botao(numero)),
        ];
        final primeiro = retangulos.first;
        final colunas = retangulos
            .takeWhile((retangulo) =>
                (retangulo.top - primeiro.top).abs() < 0.1)
            .length;
        expect(find.text('0,5 pt'), findsNWidgets(20));
        expect(find.text('10 de 10 pontos'), findsOneWidget);
        for (var i = 0; i < retangulos.length; i++) {
          final retangulo = retangulos[i];
          expect(retangulo.width, closeTo(primeiro.width, 0.1));
          expect(retangulo.height, closeTo(primeiro.height, 0.1));
          expect(retangulo.left,
              closeTo(primeiro.left + (i % colunas) * (primeiro.width + 8), 0.1));
          expect(retangulo.top,
              closeTo(primeiro.top + (i ~/ colunas) * (primeiro.height + 8), 0.1));
          final titulo = find.text('Questão ${i + 1}');
          final texto = DefaultTextStyle.of(tester.element(titulo)).style.color!;
          final fundo = tester
              .widget<OutlinedButton>(botao(i + 1))
              .style!
              .backgroundColor!
              .resolve({})!;
          final contraste =
              (fundo.computeLuminance() + 0.05) / (texto.computeLuminance() + 0.05);
          expect(contraste, greaterThanOrEqualTo(4.5));
          expect(retangulo.contains(tester.getCenter(titulo)), isTrue);
        }

        await tester.ensureVisible(botao(20));
        await tester.pumpAndSettle();
        await tester.tap(botao(20));
        await tester.pumpAndSettle();
        expect(find.text('Peso da questão 20'), findsOneWidget);
        final slider = tester.widget<Slider>(find.byType(Slider));
        slider.onChanged!(100);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Aplicar'));
        await tester.pumpAndSettle();
        expect(find.descendant(of: botao(20), matching: find.text('1 pt')),
            findsOneWidget);
        expect(find.text('0,5 pt'), findsNWidgets(19));
        expect(find.text('10,5 de 10 pontos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a acessibilidade do aparelho pode pular a abertura',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final store = SessionStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(EasyGradeApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Fazer login com o Google'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a ação da home abre a correção e o perfil recebe a foto',
      (tester) async {
    final store = SessionStore();
    addTearDown(store.dispose);
    const foto = 'https://lh3.googleusercontent.com/a/teste';
    await tester.pumpWidget(harness(
      store,
      MainNavigationShell(onLogout: () {}, fotoPerfilUrl: foto),
    ));
    await tester.pumpAndSettle();

    Finder fotoDaConta() => find.byWidgetPredicate((widget) {
          if (widget is! Image) return false;
          final fonte = widget.image;
          return fonte is NetworkImage && fonte.url == foto;
        });

    expect(find.text('Corrigir provas'), findsNothing);
    expect(fotoDaConta(), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    await tester.tap(find.text('iniciar correção'));
    await tester.pumpAndSettle();
    expect(find.byType(SelecionarLeituraScreen), findsOneWidget);
    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    expect(fotoDaConta(), findsOneWidget);
    await tester.tap(find.text('Configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Reduzir movimento'), findsNothing);
    expect(find.text('Rever animação de abertura'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 430.0]) {
    testWidgets('telas sem overflow em ${width.toInt()}px com fonte ampliada',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await _criarStoreComDados();
      addTearDown(store.dispose);
      final screens = <Widget>[
        LoginScreen(onLogin: () {}),
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
