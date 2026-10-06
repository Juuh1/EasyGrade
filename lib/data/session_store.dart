import 'package:flutter/material.dart';
import '../models/avaliacao.dart';
import '../models/correcao.dart';
import '../models/status_avaliacao.dart';
import 'mock_data.dart';

/// Estado da sessão da N1, mantido em memória.
class SessionStore extends ChangeNotifier {
  final List<Avaliacao> _avaliacoes = MockData.avaliacoes;
  final Map<String, List<int?>> _gabaritos = {};
  final Map<String, List<Correcao>> _correcoes = {};
  final Map<String, List<Questao>> _questoes = {};
  final Map<String, List<int>> _paginas = {};
  final List<Questao> bancoQuestoes = [...MockData.questoes];
  final Map<String, List<Aluno>> _turmas = {
    for (final t in MockData.turmas) t: [...MockData.alunos]
  };
  String nome = 'User',
      email = 'user@easygrade.app',
      instituicao = 'Católica de Santa Catarina';
  bool reduzirMovimento = false;
  SessionStore() {
    for (final a
        in _avaliacoes.where((a) => a.status != StatusAvaliacao.rascunho)) {
      _gabaritos[a.id] =
          List.generate(a.numQuestoes, (i) => i % a.numAlternativas);
    }
    final a = _avaliacoes.first;
    _correcoes[a.id] = List.generate(
        8,
        (s) => Correcao(
            alunoId: MockData.alunos[s].id,
            alunoNome: MockData.alunos[s].nome,
            respostas: List.generate(
                a.numQuestoes,
                (q) => q < 5 + (s % 5)
                    ? q % a.numAlternativas
                    : (q + 1) % a.numAlternativas),
            lidaEm: DateTime(2026, 9, 28, 20, s)));
  }
  List<Avaliacao> get avaliacoes => List.unmodifiable(_avaliacoes);
  Avaliacao avaliacao(String id) => _avaliacoes.firstWhere((a) => a.id == id);
  List<Aluno> alunos(String turma) => List.unmodifiable(_turmas[turma] ?? []);
  List<String> get turmas => _turmas.keys.toList()..sort();
  List<String> get disciplinas => {
        ...MockData.disciplinas,
        ..._avaliacoes.map((a) => a.disciplina)
      }.toList()
        ..sort();
  List<int?> gabarito(String id) => List.unmodifiable(
      _gabaritos[id] ?? List<int?>.filled(avaliacao(id).numQuestoes, null));
  bool gabaritoPronto(String id) => gabarito(id).every((r) => r != null);
  List<Correcao> correcoes(String id) =>
      List.unmodifiable(_correcoes[id] ?? []);
  List<Questao> questoes(String id) => List.unmodifiable(_questoes[id] ?? []);
  List<int> paginas(String id) => List.unmodifiable(
      _paginas[id] ?? List.generate(avaliacao(id).numQuestoes, (q) => q ~/ 3));
  void salvarPaginas(String id, List<int> paginas) {
    _paginas[id] = [...paginas];
    notifyListeners();
  }

  List<int?> leituraExemplo(String id) {
    final a = avaliacao(id), key = gabarito(id);
    final respostas = List<int?>.generate(
        a.numQuestoes,
        (q) => key[q] == null
            ? null
            : q % 4 == 3
                ? (key[q]! + 1) % a.numAlternativas
                : key[q]);
    if (respostas.length > 2) respostas[2] = -2;
    if (respostas.length > 4) respostas[4] = -1;
    if (respostas.length > 7) respostas[7] = null;
    return List.unmodifiable(respostas);
  }

  double media(String id) {
    final lista = correcoes(id);
    return lista.isEmpty
        ? 0
        : lista.map((r) => r.nota(gabarito(id))).reduce((a, b) => a + b) /
            lista.length;
  }

  void salvar(Avaliacao a) {
    final index = _avaliacoes.indexWhere((e) => e.id == a.id);
    if (index < 0) {
      _avaliacoes.insert(0, a);
    } else {
      _avaliacoes[index] = a;
    }
    notifyListeners();
  }

  void salvarGabarito(String id, List<int?> respostas) {
    _gabaritos[id] = [...respostas];
    final a = avaliacao(id);
    if (a.status == StatusAvaliacao.rascunho &&
        respostas.every((r) => r != null)) {
      salvar(a.copyWith(status: StatusAvaliacao.agendada));
    } else {
      notifyListeners();
    }
  }

  void salvarCorrecao(String id, Correcao r) {
    final lista = _correcoes.putIfAbsent(id, () => []);
    final index = lista.indexWhere((v) => v.alunoId == r.alunoId);
    if (index >= 0) {
      lista[index] = r;
    } else {
      lista.add(r);
    }
    notifyListeners();
  }

  void concluir(String id) =>
      salvar(avaliacao(id).copyWith(status: StatusAvaliacao.concluida));
  void excluir(String id) {
    _avaliacoes.removeWhere((a) => a.id == id);
    _gabaritos.remove(id);
    _correcoes.remove(id);
    _questoes.remove(id);
    _paginas.remove(id);
    notifyListeners();
  }

  void duplicar(String id) {
    final a = avaliacao(id);
    final novoId = DateTime.now().microsecondsSinceEpoch.toString();
    _gabaritos[novoId] = [...gabarito(id)];
    _questoes[novoId] = [...questoes(id)];
    _paginas[novoId] = [...paginas(id)];
    salvar(a.copyWith(
        id: novoId,
        codigo: 'EG-${novoId.substring(novoId.length - 6)}',
        nome: '${a.nome} · cópia',
        status: StatusAvaliacao.rascunho));
  }

  void salvarQuestoes(String id, List<Questao> selecionadas) {
    _questoes[id] = [...selecionadas];
    final a = avaliacao(id);
    _gabaritos[id] = List<int?>.generate(a.numQuestoes,
        (q) => q < selecionadas.length ? selecionadas[q].correta : null);
    notifyListeners();
  }

  void adicionarQuestao(Questao questao) {
    bancoQuestoes.add(questao);
    notifyListeners();
  }

  void adicionarAluno(String turma, Aluno aluno) {
    final lista = _turmas.putIfAbsent(turma, () => []);
    if (lista.any((a) => a.id == aluno.id)) {
      throw ArgumentError('Esta matrícula já está na turma.');
    }
    lista.add(aluno);
    notifyListeners();
  }

  void removerAluno(String turma, String id) {
    _turmas[turma]?.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void adicionarTurma(String nome) {
    _turmas.putIfAbsent(nome, () => []);
    notifyListeners();
  }

  void atualizarPerfil(
      String novoNome, String novoEmail, String novaInstituicao) {
    nome = novoNome;
    email = novoEmail;
    instituicao = novaInstituicao;
    notifyListeners();
  }

  void movimento(bool value) {
    reduzirMovimento = value;
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<SessionStore> {
  const SessionScope(
      {super.key, required SessionStore store, required super.child})
      : super(notifier: store);
  static SessionStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
