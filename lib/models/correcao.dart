import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// null = em branco; -1 = marcação múltipla; -2 = leitura incerta.
class Correcao {
  final String alunoId;
  final String alunoNome;
  final String variante;
  final List<int?> respostas;
  final DateTime lidaEm;
  final List<int> ordemQuestoes;
  final List<List<int>> ordemAlternativas;

  Correcao(
      {required this.alunoId,
      required this.alunoNome,
      this.variante = 'A',
      required List<int?> respostas,
      DateTime? lidaEm,
      List<int> ordemQuestoes = const [],
      List<List<int>> ordemAlternativas = const []})
      : respostas = List.unmodifiable(respostas),
        ordemQuestoes = List.unmodifiable(ordemQuestoes),
        ordemAlternativas = List.unmodifiable(
            ordemAlternativas.map((v) => List<int>.unmodifiable(v))),
        lidaEm = lidaEm ?? DateTime.now() {
    if (alunoId.isEmpty ||
        alunoNome.trim().isEmpty ||
        respostas.length > 60 ||
        (ordemQuestoes.isNotEmpty &&
            (ordemQuestoes.length != respostas.length ||
                ordemQuestoes.toSet().length != respostas.length ||
                ordemQuestoes.any((q) => q < 0 || q >= respostas.length))) ||
        (ordemAlternativas.isNotEmpty &&
            (ordemAlternativas.length != respostas.length ||
                ordemAlternativas.any((v) =>
                    v.length < 2 ||
                    v.length > 5 ||
                    v.toSet().length != v.length ||
                    v.any((n) => n < 0 || n >= v.length))))) {
      throw const FormatException(
          'Correção com identificação ou versão inválida.');
    }
  }
  static List<List<int>> lerOrdens(dynamic valor) =>
      (valor as List? ?? []).map((v) {
        final lista = v is Map ? v['valores'] as List : v as List;
        return lista.map((n) => (n as num).toInt()).toList();
      }).toList();
  List<int?> get respostasBase {
    final resultado = List<int?>.filled(respostas.length, null);
    for (var i = 0; i < respostas.length; i++) {
      final q = ordemQuestoes.isEmpty ? i : ordemQuestoes[i];
      final r = respostas[i];
      resultado[q] = r == null || r < 0 || ordemAlternativas.isEmpty
          ? r
          : ordemAlternativas[i][r];
    }
    return resultado;
  }

  List<int?> gabaritoNaFolha(List<int?> base) =>
      List.generate(respostas.length, (i) {
        final q = ordemQuestoes.isEmpty ? i : ordemQuestoes[i];
        final correta = base[q];
        return correta == null || ordemAlternativas.isEmpty
            ? correta
            : ordemAlternativas[i].indexOf(correta);
      });
  Map<String, dynamic> toMap() => {
        'alunoId': alunoId,
        'alunoNome': alunoNome,
        'variante': variante,
        'respostas': respostas,
        'lidaEm': Timestamp.fromDate(lidaEm),
        'ordemQuestoes': ordemQuestoes,
        'ordemAlternativas':
            ordemAlternativas.map((v) => {'valores': v}).toList(),
      };
  factory Correcao.fromMap(Map<String, dynamic> d) => Correcao(
        alunoId: d['alunoId'] as String,
        alunoNome: d['alunoNome'] as String,
        variante: d['variante'] as String? ?? 'A',
        respostas: (d['respostas'] as List)
            .map((v) => v == null ? null : (v as num).toInt())
            .toList(),
        lidaEm: (d['lidaEm'] as Timestamp).toDate(),
        ordemQuestoes: (d['ordemQuestoes'] as List? ?? [])
            .map((v) => (v as num).toInt())
            .toList(),
        ordemAlternativas: lerOrdens(d['ordemAlternativas']),
      );
  bool get precisaRevisao => respostas.any((r) => r != null && r < 0);
  int acertos(List<int?> gabarito) {
    var total = 0;
    final base = respostasBase;
    for (var i = 0; i < base.length && i < gabarito.length; i++) {
      if (base[i] != null && base[i]! >= 0 && base[i] == gabarito[i]) {
        total++;
      }
    }
    return total;
  }

  double nota(List<int?> gabarito) =>
      gabarito.isEmpty ? 0 : acertos(gabarito) * 10 / gabarito.length;
  Correcao copyWith({List<int?>? respostas}) => Correcao(
      alunoId: alunoId,
      alunoNome: alunoNome,
      variante: variante,
      respostas: respostas ?? this.respostas,
      ordemQuestoes: ordemQuestoes,
      ordemAlternativas: ordemAlternativas,
      lidaEm: lidaEm);
}

class Aluno {
  final String id, nome;
  const Aluno(this.id, this.nome);

  Map<String, dynamic> toMap() => {
        'nome': nome,
      };

  factory Aluno.fromMap(Map<String, dynamic> map) => Aluno(
        (map['id'] ?? '').toString(),
        (map['nome'] as String?) ?? '',
      );
}

class Questao {
  final String id, enunciado, disciplina;
  final List<String> alternativas;
  final int correta;
  Questao(
      {required this.id,
      required this.enunciado,
      required this.disciplina,
      required List<String> alternativas,
      required this.correta})
      : alternativas = List.unmodifiable(alternativas) {
    if (id.isEmpty ||
        enunciado.trim().isEmpty ||
        enunciado.length > 20000 ||
        disciplina.trim().isEmpty ||
        disciplina.length > 120 ||
        alternativas.length < 2 ||
        alternativas.length > 5 ||
        correta < 0 ||
        correta >= alternativas.length ||
        alternativas.any((v) => v.trim().isEmpty)) {
      throw ArgumentError(
          'Confira o enunciado, a disciplina e as alternativas.');
    }
  }

  Map<String, dynamic> toMap() => {
        'enunciado': enunciado,
        'disciplina': disciplina,
        'alternativas': alternativas,
        'correta': correta,
      };

  factory Questao.fromMap(Map<String, dynamic> map) {
    return Questao(
      id: (map['id'] ?? '').toString(),
      enunciado: (map['enunciado'] as String?) ?? '',
      disciplina: (map['disciplina'] as String?) ?? '',
      alternativas: (map['alternativas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correta: (map['correta'] as num?)?.toInt() ?? 0,
    );
  }
}
