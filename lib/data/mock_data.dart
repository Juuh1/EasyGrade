import '../models/avaliacao.dart';
import '../models/resultado_avaliacao.dart';
import '../models/status_avaliacao.dart';

/// Fonte de dados fictícia exigida pelo escopo da N1 (C2: "telas navegáveis
/// com dados mock"). Simula o que, a partir da N2, virá do Firestore.
///
/// Mantida como uma classe utilitária (em vez de só uma lista solta) para
/// já deixar um ponto único de acesso que, na N2, pode ser trocado por um
/// repositório real sem alterar as telas que o consomem.
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

  /// Todas as disciplinas distintas presentes no mock — usado para
  /// popular o dropdown "Disciplina" do modal de Filtros.
  static List<String> get disciplinas =>
      avaliacoes.map((a) => a.disciplina).toSet().toList()..sort();

  /// Todas as turmas distintas presentes no mock — usado para popular o
  /// dropdown "Turma" do modal de Filtros.
  static List<String> get turmas =>
      avaliacoes.map((a) => a.turma).toSet().toList()..sort();
}
