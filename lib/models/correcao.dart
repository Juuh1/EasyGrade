/// null = em branco; -1 = marcação múltipla; -2 = leitura incerta.
class Correcao {
  final String alunoId;
  final String alunoNome;
  final String variante;
  final List<int?> respostas;
  final DateTime lidaEm;

  Correcao(
      {required this.alunoId,
      required this.alunoNome,
      this.variante = 'A',
      required List<int?> respostas,
      DateTime? lidaEm})
      : respostas = List.unmodifiable(respostas),
        lidaEm = lidaEm ?? DateTime.now();
  bool get precisaRevisao => respostas.any((r) => r != null && r < 0);
  int acertos(List<int?> gabarito) {
    var total = 0;
    for (var i = 0; i < respostas.length && i < gabarito.length; i++) {
      if (respostas[i] != null &&
          respostas[i]! >= 0 &&
          respostas[i] == gabarito[i]) {
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
      lidaEm: lidaEm);
}

class Aluno {
  final String id, nome;
  const Aluno(this.id, this.nome);

  Map<String, dynamic> toMap() => {
        'nome': nome,
      };

  factory Aluno.fromMap(Map<String, dynamic> map) => Aluno(
        map['id'] as String,
        (map['nome'] as String?) ?? '',
      );
}

class Questao {
  final String id, enunciado, disciplina;
  final List<String> alternativas;
  final int correta;
  const Questao(
      {required this.id,
      required this.enunciado,
      required this.disciplina,
      required this.alternativas,
      required this.correta});

  Map<String, dynamic> toMap() => {
        'enunciado': enunciado,
        'disciplina': disciplina,
        'alternativas': alternativas,
        'correta': correta,
      };

  factory Questao.fromMap(Map<String, dynamic> map) {
    return Questao(
      id: map['id'] as String,
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
