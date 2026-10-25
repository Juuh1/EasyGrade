import '../models/avaliacao.dart';
import '../models/correcao.dart';

class MockData {
  MockData._();

  /// Dados mock removidos (N1 -> dados reais / Firestore).
  /// Mantidos tipados para não quebrar o restante do app; serão
  /// alimentados por dados reais na próxima etapa.
  static List<Avaliacao> get avaliacoes => <Avaliacao>[];
  static const disciplinas = <String>[];
  static const turmas = <String>[];
  static const alunos = <Aluno>[];
  static const questoes = <Questao>[];
}
