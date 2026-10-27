import 'package:flutter_test/flutter_test.dart';
import 'package:easy_grade/data/session_store.dart';
import 'package:easy_grade/models/avaliacao.dart';
import 'package:easy_grade/models/correcao.dart';
import 'package:easy_grade/models/status_avaliacao.dart';

void main() {
  test('correção conta acertos, brancos e marcações incertas corretamente', () {
    final r = Correcao(
        alunoId: '1', alunoNome: 'Aluno', respostas: [0, 2, null, -1, -2]);
    expect(r.acertos([0, 1, 2, 3, 4]), 1);
    expect(r.nota([0, 1, 2, 3, 4]), 2);
    expect(r.precisaRevisao, isTrue);
    expect(
        r.copyWith(respostas: [0, 1, null, null, 4]).precisaRevisao, isFalse);
  });
  test('uma nova leitura substitui o resultado do mesmo aluno', () {
    final store = SessionStore();
    addTearDown(store.dispose);
    store.salvar(const Avaliacao(
        id: '1',
        codigo: 'EG-1',
        nome: 'Prova',
        disciplina: 'Teste',
        turma: '3ª fase A',
        data: null,
        numQuestoes: 5,
        numAlternativas: 5,
        status: StatusAvaliacao.agendada));
    store.salvarGabarito('1', [0, 1, 2, 3, 4]);
    final key = store.gabarito('1');
    store.salvarCorrecao(
        '1',
        Correcao(
            alunoId: 'a1', alunoNome: 'Aluno', respostas: [0, 0, 0, 0, 0]));
    final count = store.correcoes('1').length;
    store.salvarCorrecao(
        '1', store.correcoes('1').first.copyWith(respostas: key));
    expect(store.correcoes('1').length, count);
    expect(store.correcoes('1').first.nota(key), 10);
    store.salvarGabarito('1', key.map((v) => (v! + 1) % 5).toList());
    expect(store.correcoes('1').first.nota(store.gabarito('1')), 0);
  });
  test('avaliação converte de/para o formato do Firestore', () {
    final original = Avaliacao(
        id: 'x',
        codigo: 'EG-X',
        nome: 'Prova',
        disciplina: 'Algoritmos',
        turma: '2ª fase B',
        data: DateTime(2026, 10, 8, 8),
        numQuestoes: 10,
        numAlternativas: 4,
        status: StatusAvaliacao.agendada);
    final copia = Avaliacao.fromMap({...original.toMap(), 'id': 'x'});
    expect(copia.id, original.id);
    expect(copia.nome, original.nome);
    expect(copia.data, original.data);
    expect(copia.numQuestoes, original.numQuestoes);
    expect(copia.numAlternativas, original.numAlternativas);
    expect(copia.status, original.status);
    expect(original.toMap().containsKey('id'), isFalse);
  });
  test('criação, duplicação e exclusão não alteram a avaliação original', () {
    final store = SessionStore();
    addTearDown(store.dispose);
    store.salvar(const Avaliacao(
        id: 'nova',
        codigo: 'EG-NOVA',
        nome: 'Nova',
        disciplina: 'Teste',
        turma: '3ª fase A',
        data: null,
        numQuestoes: 3,
        numAlternativas: 4,
        status: StatusAvaliacao.rascunho));
    expect(store.gabaritoPronto('nova'), isFalse);
    store.salvarGabarito('nova', [0, 1, 2]);
    expect(store.avaliacao('nova').status, StatusAvaliacao.agendada);
    store.duplicar('nova');
    final copia = store.avaliacoes.first;
    expect(copia.id, isNot('nova'));
    expect(store.correcoes(copia.id), isEmpty);
    store.excluir(copia.id);
    expect(store.avaliacao('nova').nome, 'Nova');
    expect(store.gabarito('nova'), [0, 1, 2]);
  });
  test('matrículas repetidas não entram na mesma turma e não há persistência',
      () {
    final store = SessionStore();
    addTearDown(store.dispose);
    store.adicionarTurma('Nova turma');
    store.adicionarAluno('Nova turma', const Aluno('1', 'Aluno'));
    expect(() => store.adicionarAluno('Nova turma', const Aluno('1', 'Outro')),
        throwsArgumentError);
    final outraSessao = SessionStore();
    addTearDown(outraSessao.dispose);
    expect(outraSessao.turmas, isNot(contains('Nova turma')));
  });
}
