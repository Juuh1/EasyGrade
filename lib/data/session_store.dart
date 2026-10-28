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
  final Map<String, List<String>> _variantesQuestoesIds = {};

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
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>>
      _variantesSubs = {};
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>>
      _gabaritosSubs = {};

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
      final idsAtuais = <String>{};
      for (final doc in ordenados) {
        try {
          final a = Avaliacao.fromMap(doc);
          lista.add(a);
          idsAtuais.add(a.id);
        } catch (_) {}
      }
      _avaliacoes
        ..clear()
        ..addAll(lista);
      carregandoAvaliacoes = false;

      // Limpa assinaturas de avaliações excluídas
      final idsRemovidos = _variantesSubs.keys
          .where((id) => !idsAtuais.contains(id))
          .toList();
      for (final id in idsRemovidos) {
        _variantesSubs.remove(id)?.cancel();
        _gabaritosSubs.remove(id)?.cancel();
        _questoes.remove(id);
        _variantesQuestoesIds.remove(id);
        _gabaritos.remove(id);
      }

      // Conecta subcoleções de cada avaliação (variantes e gabaritos)
      for (final a in lista) {
        final aId = a.id;
        if (!_variantesSubs.containsKey(aId)) {
          _variantesSubs[aId] =
              repo.acompanhar('avaliacoes/$aId/variantes').listen((vDocs) {
            final varDoc = vDocs.where((d) => d['id'] == 'A').firstOrNull ??
                vDocs.firstOrNull;
            if (varDoc != null && varDoc['questoes'] is List) {
              final qIds = (varDoc['questoes'] as List)
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              _variantesQuestoesIds[aId] = qIds;
              _reconstruirQuestoesAvaliacao(aId);
            }
          }, onError: (Object _) {});
        }

        if (!_gabaritosSubs.containsKey(aId)) {
          _gabaritosSubs[aId] =
              repo.acompanhar('avaliacoes/$aId/gabaritos').listen((gDocs) {
            final gabDoc = gDocs.where((d) => d['id'] == 'A').firstOrNull ??
                gDocs.firstOrNull;
            if (gabDoc != null && gabDoc['respostas'] is List) {
              final resps = (gabDoc['respostas'] as List)
                  .map((e) => e == null ? null : (e as num).toInt())
                  .toList();
              _gabaritos[aId] = resps;
              notifyListeners();
            }
          }, onError: (Object _) {});
        }
      }

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
      final idsRemovidos = _alunosSubs.keys
          .where((id) => !turmasAtuais.containsKey(id))
          .toList();
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

      // Re-resolve as questões selecionadas de todas as avaliações
      for (final aId in _variantesQuestoesIds.keys) {
        _reconstruirQuestoesAvaliacao(aId);
      }

      notifyListeners();
    }, onError: (Object _) {
      carregandoQuestoes = false;
      erroQuestoes = 'Não foi possível carregar o banco de questões.';
      notifyListeners();
    });
  }

  void _reconstruirQuestoesAvaliacao(String avaliacaoId) {
    final qIds = _variantesQuestoesIds[avaliacaoId];
    if (qIds == null) return;
    final lista = <Questao>[];
    for (final qId in qIds) {
      final qIdLimpo = qId.trim();
      final q = _bancoQuestoes
          .where((item) => item.id.trim() == qIdLimpo)
          .firstOrNull;
      if (q != null) {
        lista.add(q);
      }
    }
    _questoes[avaliacaoId] = lista;
    notifyListeners();
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
    for (final sub in _variantesSubs.values) {
      sub.cancel();
    }
    _variantesSubs.clear();
    for (final sub in _gabaritosSubs.values) {
      sub.cancel();
    }
    _gabaritosSubs.clear();

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
    _variantesQuestoesIds.clear();

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

  Future<void> _gravar(
      Future<void> Function(FirestoreRepository repo) operacao) async {
    final repo = _repo;
    if (repo == null) return;
    try {
      await operacao(repo);
    } catch (erro) {
      erroAvaliacoes =
          'Não foi possível sincronizar com o Firestore. A alteração pode não ter sido salva.';
      notifyListeners();
      rethrow;
    }
  }

  // --- Getters ---
  List<Avaliacao> get avaliacoes => List.unmodifiable(_avaliacoes);
  Avaliacao avaliacao(String id) => _avaliacoes.firstWhere((a) => a.id == id);
  Avaliacao? avaliacaoOuNull(String id) =>
      _avaliacoes.where((a) => a.id == id).firstOrNull;
  List<Aluno> alunos(String turma) => List.unmodifiable(_turmas[turma] ?? []);
  List<String> get turmas => _turmas.keys.toList()..sort();
  List<String> get disciplinas => {
        ..._disciplinasRemotas,
        ..._avaliacoes.map((a) => a.disciplina),
        ..._bancoQuestoes.map((q) => q.disciplina),
      }.where((d) => d.trim().isNotEmpty).toList()
        ..sort();

  List<int?> gabarito(String id) {
    final a = avaliacaoOuNull(id);
    if (a == null) {
      return List.unmodifiable(_gabaritos[id] ?? []);
    }
    final salvo = _gabaritos[id];
    if (salvo == null) {
      return List.unmodifiable(List<int?>.filled(a.numQuestoes, null));
    }
    if (salvo.length < a.numQuestoes) {
      return List.unmodifiable([
        ...salvo,
        ...List<int?>.filled(a.numQuestoes - salvo.length, null),
      ]);
    }
    return List.unmodifiable(salvo.sublist(0, a.numQuestoes));
  }

  bool gabaritoPronto(String id) {
    final a = avaliacaoOuNull(id);
    if (a == null) return false;
    final g = gabarito(id);
    return g.length == a.numQuestoes && g.every((r) => r != null);
  }

  List<Correcao> correcoes(String id) =>
      List.unmodifiable(_correcoes[id] ?? []);
  List<Questao> questoes(String id) => List.unmodifiable(_questoes[id] ?? []);
  List<String> variantesQuestoesIds(String avaliacaoId) =>
      List.unmodifiable(_variantesQuestoesIds[avaliacaoId] ?? []);
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
  Future<void> salvar(Avaliacao a) async {
    final index = _avaliacoes.indexWhere((e) => e.id == a.id);
    final backup = index >= 0 ? _avaliacoes[index] : null;
    if (index < 0) {
      _avaliacoes.insert(0, a);
    } else {
      _avaliacoes[index] = a;
    }
    notifyListeners();

    try {
      await _gravar((repo) async {
        await repo.salvar('avaliacoes', a.id, a.toMap());
        if (a.disciplina.trim().isNotEmpty) {
          final idDisc = _sanitizarId(a.disciplina);
          if (idDisc.isNotEmpty) {
            await repo.salvar('disciplinas', idDisc, {'nome': a.disciplina.trim()});
          }
        }
      });
    } catch (e) {
      if (backup == null) {
        _avaliacoes.removeWhere((e) => e.id == a.id);
      } else {
        _avaliacoes[index] = backup;
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> salvarGabarito(String id, List<int?> respostas) async {
    final a = avaliacao(id);
    final backup = _gabaritos[id];
    _gabaritos[id] = [...respostas];
    notifyListeners();

    try {
      await _gravar((repo) async {
        await repo.salvar('avaliacoes/$id/gabaritos', 'A', {
          'respostas': respostas,
        });
      });

      if (a.status == StatusAvaliacao.rascunho &&
          respostas.every((r) => r != null)) {
        await salvar(a.copyWith(status: StatusAvaliacao.agendada));
      }
    } catch (e) {
      _gabaritos[id] = backup;
      notifyListeners();
      rethrow;
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

  Future<void> concluir(String id) =>
      salvar(avaliacao(id).copyWith(status: StatusAvaliacao.concluida));

  Future<void> excluir(String id) async {
    final backupAvaliacao = _avaliacoes.where((a) => a.id == id).firstOrNull;
    final backupGabarito = _gabaritos[id];
    final backupCorrecoes = _correcoes[id];
    final backupQuestoes = _questoes[id];
    final backupPaginas = _paginas[id];
    final backupVarIds = _variantesQuestoesIds[id];

    _avaliacoes.removeWhere((a) => a.id == id);
    _gabaritos.remove(id);
    _correcoes.remove(id);
    _questoes.remove(id);
    _paginas.remove(id);
    _variantesQuestoesIds.remove(id);
    _variantesSubs.remove(id)?.cancel();
    _gabaritosSubs.remove(id)?.cancel();
    notifyListeners();

    try {
      await _gravar((repo) async {
        try {
          await repo.excluir('avaliacoes/$id/variantes', 'A');
        } catch (_) {}
        try {
          await repo.excluir('avaliacoes/$id/gabaritos', 'A');
        } catch (_) {}
        await repo.excluir('avaliacoes', id);
      });
    } catch (e) {
      if (backupAvaliacao != null) _avaliacoes.insert(0, backupAvaliacao);
      if (backupGabarito != null) _gabaritos[id] = backupGabarito;
      if (backupCorrecoes != null) _correcoes[id] = backupCorrecoes;
      if (backupQuestoes != null) _questoes[id] = backupQuestoes;
      if (backupPaginas != null) _paginas[id] = backupPaginas;
      if (backupVarIds != null) _variantesQuestoesIds[id] = backupVarIds;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> duplicar(String id) async {
    final a = avaliacao(id);
    final novoId = DateTime.now().microsecondsSinceEpoch.toString();
    final gab = gabarito(id);
    final qList = questoes(id);
    final pList = paginas(id);

    _gabaritos[novoId] = [...gab];
    _questoes[novoId] = [...qList];
    _paginas[novoId] = [...pList];
    final nova = a.copyWith(
        id: novoId,
        codigo: 'EG-${novoId.substring(novoId.length - 6)}',
        nome: '${a.nome} · cópia',
        status: StatusAvaliacao.rascunho);

    await salvar(nova);
    if (qList.isNotEmpty) {
      await salvarQuestoes(novoId, qList);
    } else if (gab.isNotEmpty && gab.any((r) => r != null)) {
      await salvarGabarito(novoId, gab);
    }
  }

  // --- Operações Módulo 2 (Turmas e Alunos) ---
  Future<void> adicionarTurma(String nome) async {
    final turmaNome = nome.trim();
    if (turmaNome.isEmpty) {
      throw ArgumentError('O nome da turma não pode ser vazio.');
    }
    if (_turmas.containsKey(turmaNome)) {
      throw ArgumentError('Esta turma já existe.');
    }
    _turmas[turmaNome] = [];
    notifyListeners();

    try {
      await _gravar((repo) async {
        final id = await repo.criar('turmas', {'nome': turmaNome});
        _turmaIds[turmaNome] = id;
        _turmaNomes[id] = turmaNome;
      });
    } catch (e) {
      _turmas.remove(turmaNome);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removerTurma(String nome) async {
    final turmaNome = nome.trim();
    final backup = _turmas[turmaNome];
    _turmas.remove(turmaNome);
    final id = _turmaIds.remove(turmaNome);
    if (id != null) {
      _turmaNomes.remove(id);
      _alunosSubs.remove(id)?.cancel();
    }
    notifyListeners();

    if (id != null) {
      try {
        await _gravar((repo) => repo.excluir('turmas', id));
      } catch (e) {
        if (backup != null) _turmas[turmaNome] = backup;
        _turmaIds[turmaNome] = id;
        _turmaNomes[id] = turmaNome;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> adicionarAluno(String turma, Aluno aluno) async {
    final lista = _turmas.putIfAbsent(turma, () => []);
    if (lista.any((a) => a.id == aluno.id)) {
      throw ArgumentError('Esta matrícula já está na turma.');
    }
    lista.add(aluno);
    notifyListeners();

    try {
      await _gravar((repo) async {
        var id = _turmaIds[turma];
        if (id == null) {
          id = await repo.criar('turmas', {'nome': turma});
          _turmaIds[turma] = id;
          _turmaNomes[id] = turma;
        }
        await repo.salvar('turmas/$id/alunos', aluno.id, aluno.toMap());
      });
    } catch (e) {
      _turmas[turma]?.removeWhere((a) => a.id == aluno.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removerAluno(String turma, String id) async {
    final alunoRemovido =
        _turmas[turma]?.where((a) => a.id == id).firstOrNull;
    _turmas[turma]?.removeWhere((a) => a.id == id);
    notifyListeners();

    final turmaId = _turmaIds[turma];
    if (turmaId != null) {
      try {
        await _gravar((repo) => repo.excluir('turmas/$turmaId/alunos', id));
      } catch (e) {
        if (alunoRemovido != null) _turmas[turma]?.add(alunoRemovido);
        notifyListeners();
        rethrow;
      }
    }
  }

  // --- Operações Módulo 3 (Banco de Questões) ---
  Future<void> adicionarQuestao(Questao questao) async {
    final index = _bancoQuestoes.indexWhere((q) => q.id == questao.id);
    final backup = index >= 0 ? _bancoQuestoes[index] : null;
    if (index >= 0) {
      _bancoQuestoes[index] = questao;
    } else {
      _bancoQuestoes.insert(0, questao);
    }
    notifyListeners();

    try {
      await _gravar((repo) async {
        await repo.salvar('questoes', questao.id, questao.toMap());
        if (questao.disciplina.trim().isNotEmpty) {
          final idDisc = _sanitizarId(questao.disciplina);
          if (idDisc.isNotEmpty) {
            await repo.salvar(
                'disciplinas', idDisc, {'nome': questao.disciplina.trim()});
          }
        }
      });
    } catch (e) {
      if (backup == null) {
        _bancoQuestoes.removeWhere((q) => q.id == questao.id);
      } else {
        _bancoQuestoes[index] = backup;
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> excluirQuestao(String id) async {
    final qRemovida =
        _bancoQuestoes.where((q) => q.id == id).firstOrNull;
    _bancoQuestoes.removeWhere((q) => q.id == id);
    notifyListeners();

    try {
      await _gravar((repo) => repo.excluir('questoes', id));
    } catch (e) {
      if (qRemovida != null) _bancoQuestoes.insert(0, qRemovida);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> salvarQuestoes(String id, List<Questao> selecionadas) async {
    final a = avaliacao(id);
    final qIds = selecionadas.map((q) => q.id).toList();
    final backupQuestoes = _questoes[id];
    final backupQIds = _variantesQuestoesIds[id];
    final backupGabarito = _gabaritos[id];

    _questoes[id] = [...selecionadas];
    _variantesQuestoesIds[id] = qIds;
    final gab = List<int?>.generate(a.numQuestoes,
        (q) => q < selecionadas.length ? selecionadas[q].correta : null);
    _gabaritos[id] = gab;
    notifyListeners();

    try {
      await _gravar((repo) async {
        await repo.salvar('avaliacoes/$id/variantes', 'A', {
          'questoes': qIds,
        });
        await repo.salvar('avaliacoes/$id/gabaritos', 'A', {
          'respostas': gab,
        });
      });

      if (a.status == StatusAvaliacao.rascunho &&
          gab.every((r) => r != null)) {
        await salvar(a.copyWith(status: StatusAvaliacao.agendada));
      }
    } catch (e) {
      _questoes[id] = backupQuestoes ?? [];
      _variantesQuestoesIds[id] = backupQIds ?? [];
      _gabaritos[id] = backupGabarito;
      notifyListeners();
      rethrow;
    }
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
