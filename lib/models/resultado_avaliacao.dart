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
  final totalRespostas = json['totalRespostas'] as int;
  final mediaTurma = (json['mediaTurma'] as num).toDouble();
  final maiorNota = (json['maiorNota'] as num).toDouble();
  final menorNota = (json['menorNota'] as num).toDouble();

  if (totalRespostas < 0) {
    throw const FormatException(
      'O total de respostas não pode ser negativo.',
    );
  }

  if (!mediaTurma.isFinite ||
      !maiorNota.isFinite ||
      !menorNota.isFinite) {
    throw const FormatException(
      'As notas devem ser números finitos.',
    );
  }

  if (menorNota > maiorNota) {
    throw const FormatException(
      'A menor nota não pode ser maior que a maior nota.',
    );
  }

  if (totalRespostas > 0 &&
      (mediaTurma < menorNota || mediaTurma > maiorNota)) {
    throw const FormatException(
      'A média deve estar entre a menor e a maior nota.',
    );
  }

  return ResultadoAvaliacao(
    totalRespostas: totalRespostas,
    mediaTurma: mediaTurma,
    maiorNota: maiorNota,
    menorNota: menorNota,
  );
}


  Map<String, dynamic> toJson() => {
        'totalRespostas': totalRespostas,
        'mediaTurma': mediaTurma,
        'maiorNota': maiorNota,
        'menorNota': menorNota,
      };
}
