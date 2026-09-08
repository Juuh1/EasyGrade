import '../models/avaliacao.dart';
import '../models/resultado_avaliacao.dart';
import '../models/status_avaliacao.dart';

// Dados simulados para testes
class MockData {
  MockData._();

  static final List<Avaliacao> avaliacoes = [
    Avaliacao(
      id: '1',
      codigo: 'EVAL-2026-N1',
      nome: 'Prova N1 — Engenharia',
      disciplina: 'Engenharia de Software',
      turma: '3ª fase A',
      data: DateTime(2026, 9, 12, 19, 0),
      numQuestoes: 20,
      numAlternativas: 5,
      status: StatusAvaliacao.concluida,
      resultado: const ResultadoAvaliacao(
        totalRespostas: 32,
        mediaTurma: 7.4,
        maiorNota: 9.8,
        menorNota: 4.2,
      ),
    ),
    Avaliacao(
      id: '2',
      codigo: 'EVAL-2026-N2',
      nome: 'Revisão — Algoritmos',
      disciplina: 'Algoritmos e Estrutura de Dados',
      turma: '2ª fase B',
      data: DateTime(2026, 9, 18, 8, 0),
      numQuestoes: 10,
      numAlternativas: 4,
      status: StatusAvaliacao.agendada,
    ),
    const Avaliacao(
      id: '3',
      codigo: 'EVAL-2026-N3',
      nome: 'Simulado — Banco de Dados',
      disciplina: 'Banco de Dados',
      turma: '3ª fase A',
      data: null,
      numQuestoes: 15,
      numAlternativas: 4,
      status: StatusAvaliacao.rascunho,
    ),
  ];

  // Listas de apoio
  static List<String> get disciplinas =>
      avaliacoes.map((a) => a.disciplina).toSet().toList()..sort();

  static List<String> get turmas =>
      avaliacoes.map((a) => a.turma).toSet().toList()..sort();
}
