import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'status_avaliacao.dart';

class Avaliacao {
  static const pesoMinimo = 25;
  final String id;
  final String codigo;
  final String nome;
  final String disciplina;
  final String turma;
  final DateTime? data;
  final int numQuestoes;
  final int numAlternativas;
  final StatusAvaliacao status;
  final int limitePontos;
  final List<int?> pesos;

  const Avaliacao({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.disciplina,
    required this.turma,
    required this.data,
    required this.numQuestoes,
    required this.numAlternativas,
    required this.status,
    this.limitePontos = 1000,
    this.pesos = const [],
  });

  static int lerLimite(Object? valor) =>
      valor is int && valor >= 100 && valor <= 1000 ? valor : 1000;

  static List<int> distribuir(int total, int quantidade) => List.generate(
    quantidade,
    (i) => total ~/ quantidade + (i < total % quantidade ? 1 : 0),
  );

  List<int> get pontos {
    final automaticos = distribuir(limitePontos, numQuestoes);
    return List.generate(
      numQuestoes,
      (i) => i < pesos.length ? pesos[i] ?? automaticos[i] : automaticos[i],
    );
  }

  int get totalPontos => pontos.fold(0, (total, valor) => total + valor);

  void validarPontuacao() {
    if (numQuestoes < 1 ||
        numQuestoes > 60 ||
        lerLimite(limitePontos) != limitePontos ||
        (pesos.isNotEmpty && pesos.length != numQuestoes) ||
        pesos.any((p) => p != null && (p < pesoMinimo || p > 300))) {
      throw ArgumentError('Confira a pontuação e os pesos das questões.');
    }
    if (totalPontos > limitePontos) {
      throw ArgumentError(
        'A soma dos pesos é ${formatarPontos(totalPontos)} e ultrapassa o limite de ${formatarPontos(limitePontos)} pontos. Ajuste os pesos para salvar a avaliação.',
      );
    }
  }

  factory Avaliacao.fromMap(Map<String, dynamic> map) {
    if ([
          'id',
          'codigo',
          'nome',
          'disciplina',
          'turma',
        ].any((k) => map[k] is! String || (map[k] as String).trim().isEmpty) ||
        map['numQuestoes'] is! num ||
        map['numAlternativas'] is! num ||
        (map['numQuestoes'] as num) < 1 ||
        (map['numQuestoes'] as num) > 60 ||
        (map['numAlternativas'] as num) < 2 ||
        (map['numAlternativas'] as num) > 5) {
      throw const FormatException('Avaliação com dados incompletos.');
    }
    final dataBruta = map['data'];
    final avaliacao = Avaliacao(
      id: map['id'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      disciplina: map['disciplina'] as String? ?? '',
      turma: map['turma'] as String? ?? '',
      data: dataBruta is Timestamp ? dataBruta.toDate() : null,
      numQuestoes: (map['numQuestoes'] as num?)?.toInt() ?? 0,
      numAlternativas: (map['numAlternativas'] as num?)?.toInt() ?? 0,
      limitePontos: lerLimite(map['limitePontos']),
      pesos: List<int?>.unmodifiable(
        (map['pesos'] as List? ?? const []).map((peso) => peso as int?),
      ),
      status: StatusAvaliacao.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StatusAvaliacao.rascunho,
      ),
    );
    avaliacao.validarPontuacao();
    return avaliacao;
  }

  Map<String, dynamic> toMap() => {
    'codigo': codigo,
    'nome': nome,
    'disciplina': disciplina,
    'turma': turma,
    'data': data == null ? null : Timestamp.fromDate(data!),
    'numQuestoes': numQuestoes,
    'numAlternativas': numAlternativas,
    'status': status.name,
    'limitePontos': limitePontos,
    'pesos': pesos,
  };

  String get dataLabelCurta =>
      data == null ? 'Sem data definida' : _formatarDataCurta(data!);

  Avaliacao copyWith({
    String? id,
    String? codigo,
    String? nome,
    String? disciplina,
    String? turma,
    DateTime? data,
    bool limparData = false,
    int? numQuestoes,
    int? numAlternativas,
    StatusAvaliacao? status,
    int? limitePontos,
    List<int?>? pesos,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      disciplina: disciplina ?? this.disciplina,
      turma: turma ?? this.turma,
      data: limparData ? null : data ?? this.data,
      numQuestoes: numQuestoes ?? this.numQuestoes,
      numAlternativas: numAlternativas ?? this.numAlternativas,
      status: status ?? this.status,
      limitePontos: limitePontos ?? this.limitePontos,
      pesos: pesos ?? this.pesos,
    );
  }
}

String formatarPontos(int centavos) {
  final texto = (centavos / 100).toStringAsFixed(2).replaceAll('.', ',');
  return texto.replaceFirst(RegExp(r',00$|0$'), '');
}

String _formatarDataCurta(DateTime d) {
  const meses = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  final dia = d.day.toString().padLeft(2, '0');
  final hora = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  final mesStr = meses[(d.month - 1).clamp(0, 11)];
  return '$dia $mesStr ${d.year} · $hora:$min';
}
