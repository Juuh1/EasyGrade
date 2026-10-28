import 'status_avaliacao.dart';

class FiltroAvaliacao {
  final String busca;
  final Set<StatusAvaliacao> status;
  final String? disciplina; // null = "Todas as disciplinas"
  final String? turma; // null = "Todas as turmas"
  final DateTime? periodoDe;
  final DateTime? periodoAte;

  FiltroAvaliacao({
    this.busca = '',
    Set<StatusAvaliacao> status = const {},
    this.disciplina,
    this.turma,
    this.periodoDe,
    this.periodoAte,
  }) : status = Set.unmodifiable(status);

  static final vazio = FiltroAvaliacao();

  bool get temFiltroAvancadoAtivo =>
      status.isNotEmpty ||
      disciplina != null ||
      turma != null ||
      periodoDe != null ||
      periodoAte != null;

  int get quantidadeFiltrosAtivos =>
      status.length +
      (disciplina != null ? 1 : 0) +
      (turma != null ? 1 : 0) +
      (periodoDe != null || periodoAte != null ? 1 : 0);

  FiltroAvaliacao copyWith({
    String? busca,
    Set<StatusAvaliacao>? status,
    String? disciplina,
    bool limparDisciplina = false,
    String? turma,
    bool limparTurma = false,
    DateTime? periodoDe,
    bool limparPeriodoDe = false,
    DateTime? periodoAte,
    bool limparPeriodoAte = false,
  }) {
    return FiltroAvaliacao(
      busca: busca ?? this.busca,
      status: status ?? this.status,
      disciplina: limparDisciplina ? null : (disciplina ?? this.disciplina),
      turma: limparTurma ? null : (turma ?? this.turma),
      periodoDe: limparPeriodoDe ? null : (periodoDe ?? this.periodoDe),
      periodoAte: limparPeriodoAte ? null : (periodoAte ?? this.periodoAte),
    );
  }
}
