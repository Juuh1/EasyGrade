import 'dart:async';
import 'dart:math';
import 'auth_service.dart';
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

  String nome = 'Professor', email = '', instituicao = '';
  AuthService? autenticacao;
  final Map<String, Future<void>> _turmasPendentes = {};
  final Map<String, List<Map<String, dynamic>>> _variantes = {};
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>>
      _correcoesSubs = {};
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>>
      _materiaisSubs = {};
  final Set<String> carregandoDetalhes = {};
  final Map<String, Set<String>> _detalhesPendentes = {};
  int _geracao = 0;
  bool _descartado = false;
  @override
  void notifyListeners() {
    if (!_descartado) super.notifyListeners();
  }

  bool reduzirMovimento = false;

  FirestoreRepository? _repo;

  // Assinaturas do Firestore
  StreamSubscription<List<Map<String, dynamic>>>? _avaliacoesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _turmasSub;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>>
      _alunosSubs = {};
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
  void conectar(FirestoreRepository repo, {AuthService? auth}) {
    desconectar(notificar: false);
    _repo = repo;
    autenticacao = auth;
    final geracao = _geracao;

    // Módulo 1: Avaliações
    carregandoAvaliacoes = true;
    erroAvaliacoes = null;
    _avaliacoesSub = repo.acompanhar('avaliacoes').listen((docs) {
      if (geracao != _geracao) return;
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
      final idsRemovidos =
          _variantesSubs.keys.where((id) => !idsAtuais.contains(id)).toList();
      for (final id in idsRemovidos) {
        _variantesSubs.remove(id)?.cancel();
        _gabaritosSubs.remove(id)?.cancel();
        _correcoesSubs.remove(id)?.cancel();
        _materiaisSubs.remove(id)?.cancel();
        _correcoes.remove(id);
        _variantes.remove(id);
        _questoes.remove(id);
        _variantesQuestoesIds.remove(id);
        _gabaritos.remove(id);
      }

      // Conecta subcoleções de cada avaliação (variantes e gabaritos)
      for (final a in lista) {
        final aId = a.id;
        if (!_variantesSubs.containsKey(aId)) {
          carregandoDetalhes.add(aId);
          _detalhesPendentes[aId] = {
            'variantes',
            'gabaritos',
            'correcoes',
            'materiais'
          };
          _variantesSubs[aId] =
              repo.acompanhar('avaliacoes/$aId/variantes').listen((vDocs) {
            if (geracao != _geracao) return;
            _variantes[aId] = vDocs;
            _detalheCarregado(aId, 'variantes');
            final varDoc = vDocs.where((d) => d['id'] == 'A').firstOrNull;
            if (varDoc != null && varDoc['questoes'] is List) {
              final qIds = (varDoc['questoes'] as List)
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              final itens = varDoc['itens'];
              if (itens is List) {
                _questoes[aId] = itens
                    .map((v) =>
                        Questao.fromMap(Map<String, dynamic>.from(v as Map)))
                    .toList();
              }
              _variantesQuestoesIds[aId] = qIds;
              _reconstruirQuestoesAvaliacao(aId);
            }
            notifyListeners();
          }, onError: (Object _) {
            erroAvaliacoes =
                'Não foi possível carregar os detalhes da avaliação.';
            notifyListeners();
          });
        }

        if (!_gabaritosSubs.containsKey(aId)) {
          _gabaritosSubs[aId] =
              repo.acompanhar('avaliacoes/$aId/gabaritos').listen((gDocs) {
            if (geracao != _geracao) return;
            _detalheCarregado(aId, 'gabaritos');
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
        if (!_correcoesSubs.containsKey(aId)) {
          _correcoesSubs[aId] =
              repo.acompanhar('avaliacoes/$aId/correcoes').listen((docs) {
            if (geracao != _geracao) return;
            final lista = <Correcao>[];
            for (final doc in docs) {
              try {
                final r = Correcao.fromMap(doc);
                if (r.respostas.length == a.numQuestoes) lista.add(r);
              } catch (_) {
                erroAvaliacoes = 'Uma correção contém dados inválidos.';
              }
            }
            _correcoes[aId] = lista;
            _detalheCarregado(aId, 'correcoes');
            notifyListeners();
          }, onError: (Object _) {
            carregandoDetalhes.remove(aId);
            erroAvaliacoes = 'Não foi possível carregar as correções.';
            notifyListeners();
          });
          _materiaisSubs[aId] =
              repo.acompanhar('avaliacoes/$aId/materiais').listen((docs) {
            if (geracao != _geracao) return;
            _detalheCarregado(aId, 'materiais');
            final layout = docs.where((v) => v['id'] == 'layout').firstOrNull;
            if (layout?['paginas'] is List) {
              _paginas[aId] = (layout!['paginas'] as List)
                  .map((v) => (v as num).toInt())
                  .toList();
            }
            notifyListeners();
          }, onError: (Object _) {
            erroAvaliacoes =
                'Não foi possível carregar a organização das páginas.';
            notifyListeners();
          });
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
        final nomeAnterior = _turmaNomes[id];
        if (nomeAnterior != null && nomeAnterior != nome) {
          _turmas[nome] = _turmas.remove(nomeAnterior) ?? [];
          _turmaIds.remove(nomeAnterior);
        }
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

  void _detalheCarregado(String id, String tipo) {
    _detalhesPendentes[id]?.remove(tipo);
    if (_detalhesPendentes[id]?.isEmpty == true) {
      carregandoDetalhes.remove(id);
      notifyListeners();
    }
  }

  void _reconstruirQuestoesAvaliacao(String avaliacaoId) {
    final versao = (_variantes[avaliacaoId] ?? [])
        .where((v) => v['id'] == 'A')
        .firstOrNull;
    if (versao?['itens'] is List && (versao!['itens'] as List).isNotEmpty) {
      return;
    }
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
    if (lista.length == qIds.length) {
      _questoes[avaliacaoId] = lista;
      _gabaritos.putIfAbsent(
          avaliacaoId,
          () => List<int?>.generate(avaliacao(avaliacaoId).numQuestoes,
              (i) => i < lista.length ? lista[i].correta : null));
    }
    notifyListeners();
  }

  /// Desliga o Firestore e limpa os dados do professor (logout).
  void desconectar({bool notificar = true}) {
    _geracao++;
    for (final sub in [..._correcoesSubs.values, ..._materiaisSubs.values]) {
      sub.cancel();
    }
    _correcoesSubs.clear();
    _materiaisSubs.clear();
    _detalhesPendentes.clear();
    _variantes.clear();
    _turmasPendentes.clear();
    carregandoDetalhes.clear();
    autenticacao = null;
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
    _descartado = true;
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
      erroAvaliacoes = null;
      await operacao(repo);
    } catch (erro) {
      erroAvaliacoes =
          'Não foi possível salvar. Confira sua conexão e tente novamente.';
      notifyListeners();
      rethrow;
    }
  }

  // Consultas
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

  Future<void> salvarPaginas(String id, List<int> paginas) async {
    if (paginas.length != avaliacao(id).numQuestoes ||
        paginas.any((v) => v < 0 || v >= 60)) {
      throw ArgumentError('Organização de páginas inválida.');
    }
    await _gravar((repo) => repo.salvar('avaliacoes/$id/materiais', 'layout',
        {'tipo': 'layout', 'paginas': paginas}));
    _paginas[id] = [...paginas];
    notifyListeners();
  }

  double media(String id) {
    final lista = correcoes(id);
    return lista.isEmpty
        ? 0
        : lista.map((r) => r.nota(gabarito(id))).reduce((a, b) => a + b) /
            lista.length;
  }

  // Avaliações
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
        final disc = _sanitizarId(a.disciplina);
        await repo.gravarLote({
          'avaliacoes/${a.id}': a.toMap(),
          if (a.disciplina.trim().isNotEmpty)
            'disciplinas/$disc': {'nome': a.disciplina.trim()},
        });
      });
    } catch (e) {
      if (backup == null) {
        _avaliacoes.removeWhere((e) => e.id == a.id);
      } else {
        final atual = _avaliacoes.indexWhere((v) => v.id == backup.id);
        if (atual < 0) {
          _avaliacoes.insert(0, backup);
        } else {
          _avaliacoes[atual] = backup;
        }
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
      if (backup == null) {
        _gabaritos.remove(id);
      } else {
        _gabaritos[id] = backup;
      }
      notifyListeners();
      rethrow;
    }
  }

  Future<void> salvarCorrecao(String id, Correcao r) async {
    final a = avaliacao(id);
    if (r.respostas.length != a.numQuestoes ||
        r.precisaRevisao ||
        r.respostas
            .any((v) => v != null && (v < 0 || v >= a.numAlternativas))) {
      throw ArgumentError('Revise todas as respostas antes de salvar.');
    }
    await _gravar((repo) =>
        repo.salvar('avaliacoes/$id/correcoes', r.alunoId, r.toMap()));
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
    await _gravar((repo) async {
      for (final filha in [
        'variantes',
        'gabaritos',
        'correcoes',
        'materiais'
      ]) {
        await repo.excluirColecao('avaliacoes/$id/$filha');
      }
      await repo.excluir('avaliacoes', id);
    });
    _avaliacoes.removeWhere((a) => a.id == id);
    _gabaritos.remove(id);
    _correcoes.remove(id);
    _questoes.remove(id);
    _paginas.remove(id);
    _variantesQuestoesIds.remove(id);
    _variantes.remove(id);
    _variantesSubs.remove(id)?.cancel();
    _gabaritosSubs.remove(id)?.cancel();
    _correcoesSubs.remove(id)?.cancel();
    _materiaisSubs.remove(id)?.cancel();
    _detalhesPendentes.remove(id);
    carregandoDetalhes.remove(id);
    notifyListeners();
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

  // Turmas e alunos
  Future<void> adicionarTurma(String nome) {
    final t = nome.trim();
    if (t.isEmpty || t.length > 200) {
      return Future.error(
          ArgumentError('Informe um nome de até 200 caracteres.'));
    }
    if (_turmasPendentes.containsKey(t)) return _turmasPendentes[t]!;
    if (_turmas.containsKey(t)) {
      return Future.error(ArgumentError('Esta turma já existe.'));
    }
    final tarefa = () async {
      await _gravar((repo) async {
        final id = await repo.criar('turmas', {'nome': t});
        _turmaIds[t] = id;
        _turmaNomes[id] = t;
      });
      _turmas.putIfAbsent(t, () => []);
      notifyListeners();
    }();
    _turmasPendentes[t] = tarefa;
    return tarefa.whenComplete(() => _turmasPendentes.remove(t));
  }

  Future<void> renomearTurma(String antigo, String novo) async {
    final nomeNovo = novo.trim();
    if (nomeNovo.isEmpty || nomeNovo.length > 200) {
      throw ArgumentError('Informe um nome de até 200 caracteres.');
    }
    if (antigo == nomeNovo) return;
    if (_turmas.containsKey(nomeNovo)) {
      throw ArgumentError('Esta turma já existe.');
    }
    final alunosAnteriores = [...alunos(antigo)];
    final id = _turmaIds[antigo];
    final avaliacoes = _avaliacoes.where((a) => a.turma == antigo).toList();
    if (id != null) {
      await _gravar((repo) => repo.gravarLote({
            'turmas/$id': {'nome': nomeNovo},
            for (final a in avaliacoes)
              'avaliacoes/${a.id}': a.copyWith(turma: nomeNovo).toMap(),
          }));
    }
    final listaAnterior = _turmas.remove(antigo);
    _turmas.putIfAbsent(nomeNovo, () => listaAnterior ?? alunosAnteriores);
    if (id != null) {
      _turmaIds.remove(antigo);
      _turmaIds[nomeNovo] = id;
      _turmaNomes[id] = nomeNovo;
    }
    for (var i = 0; i < _avaliacoes.length; i++) {
      if (_avaliacoes[i].turma == antigo) {
        _avaliacoes[i] = _avaliacoes[i].copyWith(turma: nomeNovo);
      }
    }
    notifyListeners();
  }

  Future<void> atualizarAluno(String turma, Aluno aluno) async {
    if (aluno.nome.trim().isEmpty || aluno.nome.length > 200) {
      throw ArgumentError('Confira o nome do aluno.');
    }
    final id = _turmaIds[turma];
    if (id != null) {
      await _gravar(
          (repo) => repo.salvar('turmas/$id/alunos', aluno.id, aluno.toMap()));
    }
    final lista = _turmas[turma];
    final index = lista?.indexWhere((v) => v.id == aluno.id) ?? -1;
    if (index >= 0) lista![index] = aluno;
    notifyListeners();
  }

  Future<void> removerTurma(String nome) async {
    if (carregandoAvaliacoes) {
      throw StateError(
          'Aguarde o carregamento das avaliações antes de excluir a turma.');
    }
    final turmaNome = nome.trim();
    if (_avaliacoes.any((a) => a.turma == turmaNome)) {
      throw StateError(
          'Esta turma está vinculada a uma avaliação. Exclua ou transfira as avaliações antes.');
    }
    final id = _turmaIds[turmaNome];
    if (id != null) {
      await _gravar((repo) async {
        await repo.excluirColecao('turmas/$id/alunos');
        await repo.excluir('turmas', id);
      });
      _turmaNomes.remove(id);
      _alunosSubs.remove(id)?.cancel();
    }
    _turmaIds.remove(turmaNome);
    _turmas.remove(turmaNome);
    notifyListeners();
  }

  Future<void> adicionarAluno(String turma, Aluno aluno) async {
    if (aluno.id.trim().isEmpty ||
        aluno.id.contains('/') ||
        aluno.id.length > 200 ||
        aluno.nome.trim().isEmpty ||
        aluno.nome.length > 200) {
      throw ArgumentError('Confira o nome e a matrícula do aluno.');
    }
    await _turmasPendentes[turma];
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
        await repo.criar('turmas/$id/alunos', aluno.toMap(), id: aluno.id);
      });
    } catch (e) {
      _turmas[turma]?.removeWhere((a) => a.id == aluno.id);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removerAluno(String turma, String id) async {
    final alunoRemovido = _turmas[turma]?.where((a) => a.id == id).firstOrNull;
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

  // Questões
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
    final qRemovida = _bancoQuestoes.where((q) => q.id == id).firstOrNull;
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
    if (correcoes(id).isNotEmpty || carregandoDetalhes.contains(id)) {
      throw StateError(
          'Aguarde as correções carregarem. A composição é preservada após a primeira correção.');
    }
    if (selecionadas.length > a.numQuestoes ||
        selecionadas.any((q) => q.alternativas.length != a.numAlternativas)) {
      throw ArgumentError(
          'As questões devem ter o mesmo formato da avaliação.');
    }
    final backupQIds = _variantesQuestoesIds[id];
    final backupGabarito = _gabaritos[id];

    _variantes[id] = [
      ...(_variantes[id] ?? []).where((v) => v['id'] != 'A'),
      {
        'id': 'A',
        'questoes': qIds,
        'itens': selecionadas.map((q) => {...q.toMap(), 'id': q.id}).toList()
      }
    ];
    _questoes[id] = [...selecionadas];
    _variantesQuestoesIds[id] = qIds;
    final gab = List<int?>.generate(a.numQuestoes,
        (q) => q < selecionadas.length ? selecionadas[q].correta : null);
    _gabaritos[id] = gab;
    notifyListeners();

    try {
      await _gravar((repo) async {
        await repo.gravarLote({
          'avaliacoes/$id/variantes/A': {
            'questoes': qIds,
            'itens':
                selecionadas.map((q) => {...q.toMap(), 'id': q.id}).toList()
          },
          'avaliacoes/$id/gabaritos/A': {'respostas': gab},
        });
      });

      if (a.status == StatusAvaliacao.rascunho && gab.every((r) => r != null)) {
        await salvar(a.copyWith(status: StatusAvaliacao.agendada));
      }
    } catch (e) {
      _questoes[id] = backupQuestoes ?? [];
      _variantesQuestoesIds[id] = backupQIds ?? [];
      if (backupGabarito == null) {
        _gabaritos.remove(id);
      } else {
        _gabaritos[id] = backupGabarito;
      }
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

  List<Map<String, dynamic>> variantes(String id) =>
      List.unmodifiable(_variantes[id] ?? []);
  Map<String, dynamic>? variante(String id, String versao) =>
      variantes(id).where((v) => v['id'] == versao).firstOrNull;

  Future<Map<String, dynamic>?> carregarVariante(
          String id, String versao) async =>
      variante(id, versao) ??
      await _repo?.obter('avaliacoes/$id/variantes', versao);

  Future<void> salvarPerfil(String novoNome, String novaInstituicao) async {
    final n = novoNome.trim(), i = novaInstituicao.trim();
    if (n.isEmpty || n.length > 200 || i.length > 200) {
      throw ArgumentError('Confira o nome e a instituição.');
    }
    await _gravar((repo) => repo.salvarPerfil({
          'nome': n,
          'email': email,
          'instituicao': i,
          'reduzirMovimento': reduzirMovimento
        }));
    atualizarPerfil(n, email, i);
  }

  Future<void> salvarMovimento(bool valor) async {
    await _gravar((repo) => repo.salvarPerfil({
          'nome': nome,
          'email': email,
          'instituicao': instituicao,
          'reduzirMovimento': valor
        }));
    movimento(valor);
  }

  Future<void> gerarVariantes(String id) async {
    final a = avaliacao(id);
    if (carregandoDetalhes.contains(id) || correcoes(id).isNotEmpty) {
      throw StateError(
          'As versões não podem ser alteradas após iniciar as correções.');
    }
    if (questoes(id).length != a.numQuestoes || !gabaritoPronto(id)) {
      throw StateError(
          'Selecione todas as questões e defina o gabarito antes de embaralhar.');
    }
    final alunosDaTurma = alunos(a.turma);
    if (alunosDaTurma.isEmpty) {
      throw StateError('Cadastre os alunos antes de gerar as versões.');
    }
    final versoes = <Map<String, dynamic>>[];
    final antigos = variantes(id).where((v) => v['id'] != 'A').toList();
    for (final antigo in antigos) {
      await _gravar((repo) =>
          repo.excluir('avaliacoes/$id/variantes', antigo['id'] as String));
    }
    final random = Random();
    for (var i = 0; i < alunosDaTurma.length; i++) {
      final ordem = List.generate(a.numQuestoes, (q) => q)..shuffle(random);
      final alternativas = List.generate(a.numQuestoes,
          (_) => List.generate(a.numAlternativas, (j) => j)..shuffle(random));
      final v = {
        'id': 'V${i + 1}',
        'questoes': ordem.map((q) => questoes(id)[q].id).toList(),
        'alunoId': alunosDaTurma[i].id,
        'ordemQuestoes': ordem,
        'ordemAlternativas': alternativas.map((v) => {'valores': v}).toList()
      };
      await _gravar((repo) =>
          repo.salvar('avaliacoes/$id/variantes', v['id'] as String, v));
      versoes.add(v);
    }
    _variantes[id] = [
      ...variantes(id).where((v) => v['id'] == 'A'),
      ...versoes
    ];
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
