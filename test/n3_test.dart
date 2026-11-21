import 'dart:io';
import 'package:easy_grade/data/session_store.dart';
import 'package:easy_grade/models/avaliacao.dart';
import 'package:easy_grade/models/correcao.dart';
import 'package:easy_grade/models/status_avaliacao.dart';
import 'package:easy_grade/services/arquivos_service.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

const id = 'n3-moveis';
const turma = 'Engenharia de Software';
const disciplina = 'Dispositivos Móveis';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pesos preservam o limite e funcionam em avaliações antigas', () async {
    final store = SessionStore();
    addTearDown(store.dispose);
    const base = Avaliacao(
      id: 'pesos', codigo: 'EG-02', nome: 'Pesos',
      disciplina: disciplina, turma: turma, data: null,
      numQuestoes: 10, numAlternativas: 4, status: StatusAvaliacao.rascunho,
    );
    await store.salvar(base.copyWith(pesos: [200, 50, 50, ...List.filled(7, null)]));
    final ponderada = store.avaliacao('pesos');
    expect(ponderada.totalPontos, 1000);
    expect(ponderada.pontos.take(4), [200, 50, 50, 100]);
    expect(Avaliacao.fromMap({...ponderada.toMap(), 'id': 'pesos'}).pontos, ponderada.pontos);
    final r = Correcao(alunoId: '01', alunoNome: 'Ana', respostas: [0, ...List.filled(9, null)]);
    final key = List<int?>.filled(10, 0);
    expect(r.nota(key, ponderada), 2);
    expect(r.nota(key, base), 1);
    await expectLater(store.salvar(base.copyWith(pesos: [200, ...List.filled(9, null)])), throwsArgumentError);
    expect(store.avaliacao('pesos').pontos, ponderada.pontos);
    expect(Avaliacao.distribuir(500, 7).reduce((a, b) => a + b), 500);
    expect(Avaliacao.distribuir(500, 60).reduce((a, b) => a + b), 500);
  });

  test('gera materiais A e B, preserva pesos e grava o relatório', () async {
    final store = SessionStore();
    addTearDown(store.dispose);
    store.atualizarPerfil('Tassiana Kautzmann', '', 'Católica de Santa Catarina – Jaraguá do Sul');
    await store.salvarPontuacaoPadrao(500);
    expect(store.pontuacaoPadrao, 500);
    await store.adicionarTurma(turma);
    await store.adicionarAluno(turma, const Aluno('2026001', 'Ana Ribeiro'));
    await store.adicionarAluno(turma, const Aluno('2026002', 'Caio Martins'));
    final a = Avaliacao(
      id: id, codigo: 'EG-N3', nome: 'Avaliação prática de Dispositivos Móveis',
      disciplina: disciplina, turma: turma, data: DateTime(2026, 11, 17, 19),
      numQuestoes: 5, numAlternativas: 4, status: StatusAvaliacao.rascunho,
      pesos: const [300, 200, 200, 200, 100],
    );
    await store.salvar(a);
    final enunciados = [
      'Qual widget organiza elementos verticalmente no Flutter?',
      'Qual formato é usado pelo QR Code para identificar uma folha?',
      'Qual recurso do Dart representa uma operação assíncrona com um resultado?',
      'Qual serviço do Firebase persiste documentos das avaliações?',
      'Qual componente do Flutter recebe entrada de texto?',
    ];
    final opcoes = [
      ['Column', 'Row', 'Stack', 'AppBar'],
      ['Identificador estruturado', 'Imagem do aluno', 'Nota final', 'Vídeo'],
      ['Future', 'Icon', 'SizedBox', 'Color'],
      ['Cloud Firestore', 'Crashlytics', 'Performance Monitoring', 'Messaging'],
      ['TextField', 'Text', 'Divider', 'Padding'],
    ];
    final questoes = List.generate(5, (i) => Questao(
      id: 'm$i', enunciado: enunciados[i], disciplina: disciplina,
      alternativas: opcoes[i], correta: 0,
    ));
    await store.salvarQuestoes(id, questoes);
    await store.gerarVariantes(id, embaralharQuestoes: false, embaralharAlternativas: true);
    final antigo = ArquivosService.versaoAluno(store, id, '2026002');
    expect(ArquivosService.ordem(store, id, antigo), [0, 1, 2, 3, 4]);
    expect(ArquivosService.alternativas(store, id, antigo).first, isNot([0, 1, 2, 3]));
    await store.gerarVariantes(id, embaralharQuestoes: true, embaralharAlternativas: false);
    final apenasQuestoes = ArquivosService.versaoAluno(store, id, '2026002');
    expect(ArquivosService.ordem(store, id, apenasQuestoes), isNot([0, 1, 2, 3, 4]));
    expect(ArquivosService.alternativas(store, id, apenasQuestoes).first, [0, 1, 2, 3]);
    await store.gerarVariantes(id);
    expect(await store.carregarVariante(id, antigo), isNull);
    final destino = Directory('tmp/simulacao-n3')..createSync(recursive: true);
    final pdf = await ArquivosService.provaCompletaPDF(store, id);
    expect(pdf.take(5), [37, 80, 68, 70, 45]);
    File('${destino.path}/EasyGrade_Prova_Simulacao_N3.pdf').writeAsBytesSync(pdf);
    File('${destino.path}/gabarito.pdf').writeAsBytesSync(
      await ArquivosService.folhasPDF(store, id, gabarito: true),
    );
    for (final aluno in store.alunos(turma)) {
      final versao = ArquivosService.versaoAluno(store, id, aluno.id);
      final b = aluno.id == '2026002';
      expect(store.rotuloVersao(id, versao), b ? 'B' : 'A');
      final ordem = ArquivosService.ordem(store, id, versao);
      final alternativas = ArquivosService.alternativas(store, id, versao);
      final respostas = List<int?>.generate(5, (i) {
        if (b && (ordem[i] == 0 || ordem[i] == 4)) return null;
        return alternativas[i].indexOf(!b && ordem[i] == 1 ? 1 : 0);
      });
      final correcao = Correcao(alunoId: aluno.id, alunoNome: aluno.nome,
        variante: versao, respostas: respostas, ordemQuestoes: ordem,
        ordemAlternativas: alternativas);
      await store.salvarCorrecao(id, correcao);
      expect(correcao.nota(store.gabarito(id), a), b ? 6 : 8);
    }
    expect(store.media(id), 7);
    await store.concluir(id);
    expect(store.avaliacao(id).status, StatusAvaliacao.concluida);
    expect(Excel.decodeBytes(ArquivosService.relatorioExcel(store, id, respostas: false)).tables.keys,
      ['Notas']);
    await expectLater(store.gerarVariantes(id), throwsStateError);
    await expectLater(store.salvar(a.copyWith(pesos: const [200, 200, 200, 200, 200])), throwsStateError);
  });
}
