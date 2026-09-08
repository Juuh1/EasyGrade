class ResultadoAvaliacao {
  final int totalRespostas;
  final double mediaTurma;
  final double maiorNota;
  final double menorNota;

  const ResultadoAvaliacao({
    required this.totalRespostas,
    required this.mediaTurma,
    required this.maiorNota,
    required this.menorNota,
  });

  factory ResultadoAvaliacao.fromJson(Map<String, dynamic> json) {
    return ResultadoAvaliacao(
      totalRespostas: json['totalRespostas'] as int,
      mediaTurma: (json['mediaTurma'] as num).toDouble(),
      maiorNota: (json['maiorNota'] as num).toDouble(),
      menorNota: (json['menorNota'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalRespostas': totalRespostas,
        'mediaTurma': mediaTurma,
        'maiorNota': maiorNota,
        'menorNota': menorNota,
      };
}
