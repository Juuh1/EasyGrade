import 'resultado_avaliacao.dart';
import 'status_avaliacao.dart';

/// Entidade central do domínio: uma avaliação (prova) criada pelo professor.
///
/// Reúne os dados usados tanto no card da listagem (Histórico) quanto na
/// tela de Detalhes. Na N1 os dados vêm de [mockData], sem banco de dados;
/// na N2 este mesmo modelo passa a ser lido/gravado no Firestore.
class Avaliacao {
  final String id;
  final String codigo;
  final String nome;
  final String disciplina;
  final String turma;

  /// Nula quando a avaliação ainda não tem data marcada (ex.: rascunho).
  final DateTime? data;

  final int numQuestoes;
  final int numAlternativas;
  final StatusAvaliacao status;

  /// Preenchido apenas quando [status] é [StatusAvaliacao.concluida].
  final ResultadoAvaliacao? resultado;

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
    this.resultado,
  });

  /// Texto amigável mostrado no lugar da data quando ela não existe.
  String get dataLabelCurta =>
      data == null ? 'Sem data definida' : _formatarDataCurta(data!);

  String get subtitulo => '$numQuestoes questões · $numAlternativas alternativas';

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
    ResultadoAvaliacao? resultado,
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
      resultado: resultado ?? this.resultado,
    );
  }

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      nome: json['nome'] as String,
      disciplina: json['disciplina'] as String,
      turma: json['turma'] as String,
      data: json['data'] == null ? null : DateTime.parse(json['data'] as String),
      numQuestoes: json['numQuestoes'] as int,
      numAlternativas: json['numAlternativas'] as int,
      status: StatusAvaliacao.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StatusAvaliacao.rascunho,
      ),
      resultado: json['resultado'] == null
          ? null
          : ResultadoAvaliacao.fromJson(
              json['resultado'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nome': nome,
        'disciplina': disciplina,
        'turma': turma,
        'data': data?.toIso8601String(),
        'numQuestoes': numQuestoes,
        'numAlternativas': numAlternativas,
        'status': status.name,
        'resultado': resultado?.toJson(),
      };
}

String _formatarDataCurta(DateTime d) {
  const meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  final dia = d.day.toString().padLeft(2, '0');
  final hora = d.hour.toString().padLeft(2, '0');
  final min = d.minute.toString().padLeft(2, '0');
  return '$dia ${meses[d.month - 1]} ${d.year} · $hora:$min';
}
