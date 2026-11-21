import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_grade/data/firestore_repository.dart';
import 'package:easy_grade/data/session_store.dart';
import 'package:easy_grade/models/avaliacao.dart';
import 'package:easy_grade/models/correcao.dart';
import 'package:easy_grade/models/status_avaliacao.dart';
import 'package:easy_grade/services/arquivos_service.dart';
import 'package:easy_grade/services/importacao_alunos.dart';
import 'package:excel/excel.dart';

class BancoLocal implements FirestoreRepository {
  final docs = <String, Map<String, dynamic>>{};
  final canais = <String, StreamController<List<Map<String, dynamic>>>>{};
  bool falhar = false;
  int criacoes = 0;
  List<Map<String, dynamic>> lista(String caminho) => docs.entries
      .where((e) =>
          e.key.startsWith('$caminho/') &&
          e.key.split('/').length == caminho.split('/').length + 1)
      .map((e) => {...e.value, 'id': e.key.split('/').last})
      .toList();
  void publicar(String caminho) => canais[caminho]?.add(lista(caminho));
  @override
  Stream<List<Map<String, dynamic>>> acompanhar(String caminho) =>
      Stream.multi((out) {
        out.add(lista(caminho));
        final canal =
            canais.putIfAbsent(caminho, () => StreamController.broadcast());
        final sub = canal.stream.listen(out.add);
        out.onCancel = sub.cancel;
      });
  @override
  Future<void> salvar(String caminho, String id, Map<String, dynamic> dados,
      {bool mesclar = true}) async {
    if (falhar) throw StateError('Sem conexão.');
    validar(dados);
    docs['$caminho/$id'] = {...docs['$caminho/$id'] ?? {}, ...dados}
      ..remove('id');
    publicar(caminho);
  }

  void validar(dynamic v, {bool emLista = false}) {
    if (v is List) {
      if (emLista) throw StateError('O Firestore não aceita arrays aninhados.');
      for (final item in v) {
        validar(item, emLista: true);
      }
    } else if (v is Map) {
      for (final item in v.values) {
        validar(item);
      }
    }
  }

  @override
  Future<String> criar(String caminho, Map<String, dynamic> dados,
      {String? id}) async {
    criacoes++;
    final chave = id ?? 'doc$criacoes';
    await salvar(caminho, chave, dados);
    return chave;
  }

  @override
  Future<void> gravarLote(Map<String, Map<String, dynamic>> dados) async {
    if (falhar) throw StateError('Sem conexão.');
    for (final entry in dados.entries) {
      final partes = entry.key.split('/');
      await salvar(
          partes.take(partes.length - 1).join('/'), partes.last, entry.value);
    }
  }

  @override
  Future<void> excluir(String caminho, String id) async {
    docs.remove('$caminho/$id');
    publicar(caminho);
  }

  @override
  Future<void> excluirColecao(String caminho) async {
    docs.removeWhere((k, _) => k.startsWith('$caminho/'));
    publicar(caminho);
  }

  @override
  Future<Map<String, dynamic>?> obter(String caminho, String id) async =>
      docs['$caminho/$id'];
  @override
  Future<void> salvarPerfil(Map<String, dynamic> dados) async {
    await salvar('usuarios', 'perfil', dados);
  }

  Future<void> fechar() async {
    for (final canal in canais.values) {
      await canal.close();
    }
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<void> eventos() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const avaliacao = Avaliacao(
    id: 'av1',
    codigo: 'EG-1',
    nome: 'Avaliação de matemática',
    disciplina: 'Matemática',
    turma: 'Turma A',
    data: null,
    numQuestoes: 3,
    numAlternativas: 4,
    status: StatusAvaliacao.rascunho);

Future<SessionStore> preparar({BancoLocal? banco}) async {
  final store = SessionStore();
  if (banco != null) {
    store.conectar(banco);
    await eventos();
  }
  await store.adicionarTurma('Turma A');
  await store.adicionarAluno('Turma A', const Aluno('001', 'Maria Souza'));
  await store.salvar(avaliacao);
  await eventos();
  final questoes = List.generate(
      3,
      (i) => Questao(
          id: 'q$i',
          enunciado: 'Questão ${i + 1}: escolha a alternativa correta.',
          disciplina: 'Matemática',
          alternativas: [
            'Primeira alternativa',
            'Segunda alternativa',
            'Terceira alternativa',
            'Quarta alternativa'
          ],
          correta: i));
  for (final q in questoes) {
    await store.adicionarQuestao(q);
  }
  await store.salvarQuestoes('av1', questoes);
  await eventos();
  return store;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('importação preserva matrícula com zeros, aspas e cabeçalho', () {
    final alunos =
        ImportacaoAlunos.texto('matrícula;nome\n001;"Maria, Souza"\n002;João');
    expect(alunos.map((v) => v.id), ['001', '002']);
    expect(alunos.first.nome, 'Maria, Souza');
    expect(() => ImportacaoAlunos.texto('1,A\n1,B'), throwsFormatException);
    final x = Excel.createExcel();
    x['Alunos'].appendRow([TextCellValue('matrícula'), TextCellValue('nome')]);
    x['Alunos'].appendRow([TextCellValue('003'), TextCellValue('José')]);
    x.delete('Sheet1');
    expect(
        ImportacaoAlunos.arquivo(Uint8List.fromList(x.encode()!), 'alunos.xlsx')
            .single
            .id,
        '003');
  });

  test('correção embaralhada é recuperada com nota e respostas originais',
      () async {
    final banco = BancoLocal(), store = await preparar(banco: banco);
    final nova = SessionStore();
    addTearDown(() async {
      store.dispose();
      nova.dispose();
      await banco.fechar();
    });
    await store.gerarVariantes('av1');
    final v = store.variantes('av1').firstWhere((v) => v['id'] != 'A');
    final ordem = (v['ordemQuestoes'] as List).cast<int>();
    final alt = Correcao.lerOrdens(v['ordemAlternativas']);
    final respostas = List<int?>.generate(
        3, (i) => alt[i].indexOf(store.gabarito('av1')[ordem[i]]!));
    await store.salvarCorrecao(
        'av1',
        Correcao(
            alunoId: '001',
            alunoNome: 'Maria Souza',
            variante: v['id'] as String,
            respostas: respostas,
            ordemQuestoes: ordem,
            ordemAlternativas: alt));
    await store.salvarPaginas('av1', [0, 1, 1]);
    await expectLater(store.removerTurma('Turma A'), throwsStateError);
    store.desconectar();
    nova.conectar(banco);
    await eventos();
    expect(nova.correcoes('av1').single.nota(nova.gabarito('av1')), 10);
    expect(nova.correcoes('av1').single.respostasBase, [0, 1, 2]);
    expect(nova.questoes('av1').map((v) => v.id), ['q0', 'q1', 'q2']);
    expect(nova.paginas('av1'), [0, 1, 1]);
    await nova.excluirQuestao('q0');
    await eventos();
    expect(nova.questoes('av1'), hasLength(3));
    await nova.excluir('av1');
    await eventos();
    await nova.removerTurma('Turma A');
    expect(banco.docs.keys.where((v) => v.contains('/alunos/')), isEmpty);
  });

  test('renomear turma preserva os alunos e atualiza as avaliações', () async {
    final banco = BancoLocal(), store = await preparar(banco: banco);
    addTearDown(() async {
      store.dispose();
      await banco.fechar();
    });
    await store.renomearTurma('Turma A', 'Turma B');
    await eventos();
    expect(store.alunos('Turma B').single.id, '001');
    expect(store.avaliacao('av1').turma, 'Turma B');
    expect(store.turmas, isNot(contains('Turma A')));
  });

  test('falha de gravação não confirma correção nem altera resultados',
      () async {
    final banco = BancoLocal(), store = await preparar(banco: banco);
    addTearDown(() async {
      store.dispose();
      await banco.fechar();
    });
    banco.falhar = true;
    await expectLater(
        store.salvarCorrecao(
            'av1',
            Correcao(
                alunoId: '001',
                alunoNome: 'Maria Souza',
                respostas: [0, 1, 2])),
        throwsStateError);
    expect(store.correcoes('av1'), isEmpty);
    expect(store.erroAvaliacoes, isNotNull);
  });

  test('gera PDF Word e Excel reais para inspeção', () async {
    final store = await preparar();
    addTearDown(store.dispose);
    await store.salvarCorrecao(
        'av1',
        Correcao(
            alunoId: '001', alunoNome: 'Maria Souza', respostas: [0, 1, 2]));
    final pasta = Directory('tmp/validacao-final')..createSync(recursive: true);
    File('${pasta.path}/folhas.pdf')
        .writeAsBytesSync(await ArquivosService.folhasPDF(store, 'av1'));
    File('${pasta.path}/gabarito.pdf').writeAsBytesSync(
        await ArquivosService.folhasPDF(store, 'av1', gabarito: true));
    File('${pasta.path}/cadernos.pdf')
        .writeAsBytesSync(await ArquivosService.cadernoPDF(store, 'av1'));
    File('${pasta.path}/cadernos.docx')
        .writeAsBytesSync(ArquivosService.cadernoWord(store, 'av1'));
    final excel = ArquivosService.relatorioExcel(store, 'av1');
    File('${pasta.path}/notas.xlsx').writeAsBytesSync(excel);
    expect(
        double.parse(Excel.decodeBytes(excel)
            .tables['Notas']!
            .rows[1][5]!
            .value
            .toString()),
        10);
    await store.salvar(const Avaliacao(
        id: 'av60',
        codigo: 'EG-60',
        nome: 'Avaliação com 60 questões',
        disciplina: 'Teste',
        turma: 'Turma A',
        data: null,
        numQuestoes: 60,
        numAlternativas: 5,
        status: StatusAvaliacao.rascunho));
    await store.salvarGabarito('av60', List.generate(60, (q) => q % 5));
    File('${pasta.path}/gabarito60.pdf').writeAsBytesSync(
        await ArquivosService.folhasPDF(store, 'av60', gabarito: true));
  });
}
