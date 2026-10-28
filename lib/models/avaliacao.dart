import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'status_avaliacao.dart';

class Avaliacao {
  final String id;
  final String codigo;
  final String nome;
  final String disciplina;
  final String turma;
  final DateTime? data;
  final int numQuestoes;
  final int numAlternativas;
  final StatusAvaliacao status;

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
  });

  factory Avaliacao.fromMap(Map<String, dynamic> map) {
    final dataBruta = map['data'];
    return Avaliacao(
      id: map['id'] as String? ?? '',
      codigo: map['codigo'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      disciplina: map['disciplina'] as String? ?? '',
      turma: map['turma'] as String? ?? '',
      data: dataBruta is Timestamp ? dataBruta.toDate() : null,
      numQuestoes: (map['numQuestoes'] as num?)?.toInt() ?? 0,
      numAlternativas: (map['numAlternativas'] as num?)?.toInt() ?? 0,
      status: StatusAvaliacao.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => StatusAvaliacao.rascunho,
      ),
    );
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
    int? numQuestoes,
    int? numAlternativas,
    StatusAvaliacao? status,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nome: nome ?? this.nome,
      disciplina: disciplina ?? this.disciplina,
      turma: turma ?? this.turma,
      data: data ?? this.data,
      numQuestoes: numQuestoes ?? this.numQuestoes,
      numAlternativas: numAlternativas ?? this.numAlternativas,
      status: status ?? this.status,
    );
  }
}

String _formatarDataCurta(DateTime d) {
  const meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  final dia = d.day.toString().padLeft(2, '0');
  final hora = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  final mesStr = meses[(d.month - 1).clamp(0, 11)];
  return '$dia $mesStr ${d.year} · $hora:$min';
}