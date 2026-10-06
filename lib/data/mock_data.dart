import '../models/avaliacao.dart';
import '../models/correcao.dart';
import '../models/status_avaliacao.dart';

class MockData {
  MockData._();
  static List<Avaliacao> get avaliacoes => [
        Avaliacao(
            id: '1',
            codigo: 'EG-2601',
            nome: 'Fundamentos de software',
            disciplina: 'Engenharia de Software',
            turma: '3ª fase A',
            data: DateTime(2026, 9, 28, 19),
            numQuestoes: 10,
            numAlternativas: 5,
            status: StatusAvaliacao.concluida),
        Avaliacao(
            id: '2',
            codigo: 'EG-2602',
            nome: 'Lógica e algoritmos',
            disciplina: 'Algoritmos',
            turma: '2ª fase B',
            data: DateTime(2026, 10, 8, 8),
            numQuestoes: 10,
            numAlternativas: 4,
            status: StatusAvaliacao.agendada),
        const Avaliacao(
            id: '3',
            codigo: 'EG-2603',
            nome: 'Modelagem de dados',
            disciplina: 'Banco de Dados',
            turma: '3ª fase A',
            data: null,
            numQuestoes: 15,
            numAlternativas: 4,
            status: StatusAvaliacao.rascunho),
      ];
  static const disciplinas = [
    'Algoritmos',
    'Banco de Dados',
    'Engenharia de Software'
  ];
  static const turmas = ['2ª fase B', '3ª fase A'];
  static const alunos = [
    Aluno('2026001', 'Ana Clara Martins'),
    Aluno('2026002', 'Bruno Oliveira'),
    Aluno('2026003', 'Camila Santos'),
    Aluno('2026004', 'Daniel Ferreira'),
    Aluno('2026005', 'Eduarda Costa'),
    Aluno('2026006', 'Felipe Rodrigues'),
    Aluno('2026007', 'Gabriela Alves'),
    Aluno('2026008', 'Henrique Lima')
  ];
  static const questoes = [
    Questao(
        id: 'q1',
        disciplina: 'Engenharia de Software',
        enunciado:
            'Qual é a principal finalidade do levantamento de requisitos?',
        alternativas: [
          'Definir as cores da interface.',
          'Compreender as necessidades dos usuários.',
          'Escolher o servidor de produção.',
          'Escrever testes de desempenho.',
          'Publicar o aplicativo.'
        ],
        correta: 1),
    Questao(
        id: 'q2',
        disciplina: 'Engenharia de Software',
        enunciado: 'Qual prática favorece a manutenção de um sistema?',
        alternativas: [
          'Duplicar regras de negócio.',
          'Concentrar o código em um arquivo.',
          'Separar responsabilidades.',
          'Evitar documentação.',
          'Remover testes.'
        ],
        correta: 2),
    Questao(
        id: 'q3',
        disciplina: 'Algoritmos',
        enunciado:
            'Qual estrutura repete um bloco enquanto uma condição é verdadeira?',
        alternativas: [
          'Uma constante.',
          'Uma variável.',
          'Uma seleção.',
          'Um laço de repetição.'
        ],
        correta: 3),
  ];
}
