import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import '../models/avaliacao.dart';
import '../models/correcao.dart';
import '../models/status_avaliacao.dart';
import 'firestore_repository.dart';

/// Estado da sessão conectado ao Cloud Firestore:
/// - Módulo 1: Avaliações
/// - Módulo 2: Turmas e Alunos
/// - Módulo 3: Banco de Questões
class SessionStore extends ChangeNotifier {
  final List<Avaliacao> _avaliacoes = [];
  final Map<String, List<int?>> _gabaritos = {};
  final Map<String, List<Correcao>> _correcoes = {};
  final Map<String, List<Questao>> _questoes = {};
  final Map<String, List<int>> _paginas = {};
  final List<Questao> _bancoQuestoes = [];
  final Map<String, List<Aluno>> _turmas = {};
  final Map<String, String> _turmaIds = {};
  final Map<String, String> _turmaNomes = {};
  final Set<String> _disciplinasRemotas = {};

  String nome = 'User',
      email = 'user@easygrade.app',
      instituicao = 'Católica de Santa Catarina';
  bool reduzirMovimento = false;

  FirestoreRepository? _repo;

  // Assinaturas do Firestore
  StreamSubscription<List<Map<String, dynamic>>>? _avaliacoesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _turmasSub;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>> _alunosSubs =
      {};
  StreamSubscription<List<Map<String, dynamic>>>? _disciplinasSub;
  StreamSubscription<List<Map<String, dynamic>>>? _questoesSub;

  bool carregandoAvaliacoes = false;
  bool carregandoTurmas = false;
  bool carregandoQuestoes = false;

  String? erroAvaliacoes;
  String? erroTurmas;
  String? erroQuestoes;

  SessionStore();

  /// Conecta a sessão ao Firestore do professor autenticado.
  void conectar(FirestoreRepository repo) {
    desconectar(notificar: false);
    _repo = repo;

    // Módulo 1: Avaliações
    carregandoAvaliacoes = true;
    erroAvaliacoes = null;
    _avaliacoesSub = repo.acompanhar('avaliacoes').listen((docs) {
      final ordenados = [...docs]
        ..sort((a, b) => _criadoEm(b).compareTo(_criadoEm(a)));
      final lista = <Avaliacao>[];
      for (final doc in ordenados) {
        try {
          lista.add(Avaliacao.fromMap(doc));
        } catch (_) {}
      }
      _avaliacoes
        ..clear()
        ..addAll(lista);
      carregandoAvaliacoes = false;
      notifyListeners();
    }, onError: (Object _) {
      carregandoAvaliacoes = false;
      erroAvaliacoes =
          'Não foi possível carregar suas avaliações. Confira a conexão e tente novamente.';
      notifyListeners();
    });

    // Módulo 2: Turmas e Alunos
    carregandoTurmas = true;
    erroTurmas = null;
    _turmasSub = repo.acompanhar('turmas').listen((docs) {
      final turmasAtuais = <String, String>{};
      for (final doc in docs) {
        final id = doc['id'] as String;
        final nome = (doc['nome'] as String?)?.trim() ?? '';
        if (nome.isNotEmpty) {
          turmasAtuais[id] = nome;
        }
      }

      // Cancela listeners de turmas removidas
      final idsRemovidos =
          _alunosSubs.keys.where((id) => !turmasAtuais.containsKey(id)).toList();
      for (final id in idsRemovidos) {
        _alunosSubs.remove(id)?.cancel();
        final nomeAntigo = _turmaNomes.remove(id);
        if (nomeAntigo != null) {
          _turmaIds.remove(nomeAntigo);
          _turmas.remove(nomeAntigo);
        }
      }

      // Registra e escuta cada turma
      for (final entry in turmasAtuais.entries) {
        final id = entry.key;
        final nome = entry.value;
        _turmaIds[nome] = id;
        _turmaNomes[id] = nome;
        _turmas.putIfAbsent(nome, () => []);

        if (!_alunosSubs.containsKey(id)) {
          _alunosSubs[id] =
              repo.acompanhar('turmas/$id/alunos').listen((alunosDocs) {
            final tNome = _turmaNomes[id];
            if (tNome == null) return;
            final listaAlunos = <Aluno>[];
            for (final aDoc in alunosDocs) {
              try {
                listaAlunos.add(Aluno.fromMap(aDoc));
              } catch (_) {}
            }
            listaAlunos.sort((a, b) => a.nome.compareTo(b.nome));
            _turmas[tNome] = listaAlunos;
            notifyListeners();
          }, onError: (Object _) {});
        }
      }

      carregandoTurmas = false;
      notifyListeners();
    }, onError: (Object _) {
      carregandoTurmas = false;
      erroTurmas = 'Não foi possível carregar as turmas.';
      notifyListeners();
    });

    // Módulo 2: Disciplinas
    _disciplinasSub = repo.acompanhar('disciplinas').listen((docs) {
      _disciplinasRemotas.clear();
      for (final doc in docs) {
        final nome = doc['nome'] as String?;
        if (nome != null && nome.trim().isNotEmpty) {
          _disciplinasRemotas.add(nome.trim());
        }
      }
      notifyListeners();
    }, onError: (Object _) {});

    // Módulo 3: Banco de Questões
    carregandoQuestoes = true;
    erroQuestoes = null;
    _questoesSub = repo.acompanhar('questoes').listen((docs) {
      final lista = <Questao>[];
      for (final doc in docs) {
        try {
          lista.add(Questao.fromMap(doc));
        } catch (_) {}
      }
      _bancoQuestoes
        ..clear()
        ..addAll(lista);
      carregandoQuestoes = false;
      notifyListeners();
    }, onError: (Object _) {
      carregandoQuestoes = false;
      erroQuestoes = 'Não foi possível carregar o banco de questões.';
      notifyListeners();
    });
  }

  /// Desliga o Firestore e limpa os dados do professor (logout).
  void desconectar({bool notificar = true}) {
    _avaliacoesSub?.cancel();
    _avaliacoesSub = null;
    _turmasSub?.cancel();
    _turmasSub = null;
    for (final sub in _alunosSubs.values) {
      sub.cancel();
    }
    _alunosSubs.clear();
    _disciplinasSub?.cancel();
    _disciplinasSub = null;
    _questoesSub?.cancel();
    _questoesSub = null;

    _repo = null;
    _avaliacoes.clear();
    _gabaritos.clear();
    _correcoes.clear();
    _questoes.clear();
    _paginas.clear();
    _bancoQuestoes.clear();
    _turmas.clear();
    _turmaIds.clear();
    _turmaNomes.clear();
    _disciplinasRemotas.clear();

    carregandoAvaliacoes = false;
    carregandoTurmas = false;
    carregandoQuestoes = false;
    erroAvaliacoes = null;
    erroTurmas = null;
    erroQuestoes = null;

    if (notificar) notifyListeners();
  }

  @override
  void dispose() {
    desconectar(notificar: false);
    super.dispose();
  }

  // Documentos com data de criação pendente (null) são os mais novos.
  static int _criadoEm(Map<String, dynamic> doc) {
    final v = doc['criadoEm'];
    return v is Timestamp ? v.millisecondsSinceEpoch : 9007199254740991;
  }

  void _gravar(Future<void> Function(FirestoreRepository repo) operacao) {
    final repo = _repo;
    if (repo == null) return;
    operacao(repo).catchError((Object erro) {
      erroAvaliacoes =
          'Não foi possível sincronizar com o Firestore. A alteração pode não ter sido salva.';
      notifyListeners();
    });
  }

  // --- Getters ---
  List<Avaliacao> get avaliacoes => List.unmodifiable(_avaliacoes);
  Avaliacao avaliacao(String id) => _avaliacoes.firstWhere((a) => a.id == id);
  List<Aluno> alunos(String turma) => List.unmodifiable(_turmas[turma] ?? []);
  List<String> get turmas => _turmas.keys.toList()..sort();
  List<String> get disciplinas => {
        ..._disciplinasRemotas,
        ..._avaliacoes.map((a) => a.disciplina),
        ..._bancoQuestoes.map((q) => q.disciplina),
      }.where((d) => d.trim().isNotEmpty).toList()
        ..sort();

  List<int?> gabarito(String id) => List.unmodifiable(
      _gabaritos[id] ?? List<int?>.filled(avaliacao(id).numQuestoes, null));
  bool gabaritoPronto(String id) => gabarito(id).every((r) => r != null);
  List<Correcao> correcoes(String id) =>
      List.unmodifiable(_correcoes[id] ?? []);
  List<Questao> questoes(String id) => List.unmodifiable(_questoes[id] ?? []);
  List<Questao> get bancoQuestoes => List.unmodifiable(_bancoQuestoes);

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

  // --- Operações Módulo 1 (Avaliações) ---
  void salvar(Avaliacao a) {
    final index = _avaliacoes.indexWhere((e) => e.id == a.id);
    if (index < 0) {
      _avaliacoes.insert(0, a);
    } else {
      _avaliacoes[index] = a;
    }
    notifyListeners();
    _gravar((repo) async {
      await repo.salvar('avaliacoes', a.id, a.toMap());
      if (a.disciplina.trim().isNotEmpty) {
        final idDisc = _sanitizarId(a.disciplina);
        if (idDisc.isNotEmpty) {
          await repo.salvar('disciplinas', idDisc, {'nome': a.disciplina.trim()});
        }
      }
    });
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
    _gravar((repo) => repo.excluir('avaliacoes', id));
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

  // --- Operações Módulo 2 (Turmas e Alunos) ---
  void adicionarTurma(String nome) {
    final turmaNome = nome.trim();
    if (turmaNome.isEmpty || _turmas.containsKey(turmaNome)) return;
    _turmas[turmaNome] = [];
    notifyListeners();
    _gravar((repo) async {
      final id = await repo.criar('turmas', {'nome': turmaNome});
      _turmaIds[turmaNome] = id;
      _turmaNomes[id] = turmaNome;
    });
  }

  void removerTurma(String nome) {
    final turmaNome = nome.trim();
    _turmas.remove(turmaNome);
    final id = _turmaIds.remove(turmaNome);
    if (id != null) {
      _turmaNomes.remove(id);
      _alunosSubs.remove(id)?.cancel();
      _gravar((repo) => repo.excluir('turmas', id));
    }
    notifyListeners();
  }

  void adicionarAluno(String turma, Aluno aluno) {
    final lista = _turmas.putIfAbsent(turma, () => []);
    if (lista.any((a) => a.id == aluno.id)) {
      throw ArgumentError('Esta matrícula já está na turma.');
    }
    lista.add(aluno);
    notifyListeners();
    _gravar((repo) async {
      var id = _turmaIds[turma];
      if (id == null) {
        id = await repo.criar('turmas', {'nome': turma});
        _turmaIds[turma] = id;
        _turmaNomes[id] = turma;
      }
      await repo.salvar('turmas/$id/alunos', aluno.id, aluno.toMap());
    });
  }

  void removerAluno(String turma, String id) {
    _turmas[turma]?.removeWhere((a) => a.id == id);
    notifyListeners();
    final turmaId = _turmaIds[turma];
    if (turmaId != null) {
      _gravar((repo) => repo.excluir('turmas/$turmaId/alunos', id));
    }
  }

  // --- Operações Módulo 3 (Banco de Questões) ---
  void adicionarQuestao(Questao questao) {
    final index = _bancoQuestoes.indexWhere((q) => q.id == questao.id);
    if (index >= 0) {
      _bancoQuestoes[index] = questao;
    } else {
      _bancoQuestoes.insert(0, questao);
    }
    notifyListeners();
    _gravar((repo) async {
      await repo.salvar('questoes', questao.id, questao.toMap());
      if (questao.disciplina.trim().isNotEmpty) {
        final idDisc = _sanitizarId(questao.disciplina);
        if (idDisc.isNotEmpty) {
          await repo.salvar('disciplinas', idDisc, {'nome': questao.disciplina.trim()});
        }
      }
    });
  }

  void excluirQuestao(String id) {
    _bancoQuestoes.removeWhere((q) => q.id == id);
    notifyListeners();
    _gravar((repo) => repo.excluir('questoes', id));
  }

  void salvarQuestoes(String id, List<Questao> selecionadas) {
    _questoes[id] = [...selecionadas];
    final a = avaliacao(id);
    _gabaritos[id] = List<int?>.generate(a.numQuestoes,
        (q) => q < selecionadas.length ? selecionadas[q].correta : null);
    notifyListeners();
    _gravar((repo) => repo.salvar('avaliacoes/$id/variantes', 'A', {
          'questoes': selecionadas.map((q) => q.id).toList(),
        }));
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

  static String _sanitizarId(String texto) {
    final limpo = texto
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return limpo.startsWith('_')
        ? 'disc$limpo'
        : (limpo.isEmpty ? 'disc' : limpo);
  }
}

class SessionScope extends InheritedNotifier<SessionStore> {
  const SessionScope(
      {super.key, required SessionStore store, required super.child})
      : super(notifier: store);
  static SessionStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;
}
