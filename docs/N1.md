# Protótipo N1

A N1 é um protótipo Flutter navegável com dados fictícios. O escopo acadêmico pede navegação com mocks, e o relato do cliente descreve provas físicas, folhas de respostas identificadas e análise das alternativas assinaladas.

## Fluxo do professor

1. Organizar turmas e alunos.
2. Criar a avaliação, escolhendo turma e formato.
3. Selecionar questões do banco local ou usar uma prova preparada fora do aplicativo.
4. Definir o gabarito de referência manualmente ou pela leitura simulada.
5. Consultar a prévia da folha identificada e do caderno.
6. Identificar a folha por um QR ilustrativo e executar uma leitura de demonstração.
7. Conferir marcações incertas ou múltiplas com a folha física. Corrigir a alternativa ou registrar em branco.
8. Confirmar o resultado individual e continuar com o próximo aluno.
9. Consultar notas da turma, distribuição das alternativas e prévia da planilha.

O aluno realiza a prova no papel. O aplicativo é uma ferramenta do professor, sem portal de prova virtual. A leitura de uma folha por vez corresponde ao fluxo relatado pelo cliente; captura de lotes não foi presumida como requisito.

## Correspondência com o relato

| Necessidade | Representação na N1 |
| --- | --- |
| Gerar e corrigir provas objetivas | Criação, seleção de questões, gabarito, prévias de materiais, captura simulada, revisão e resultado |
| Identificar avaliação e aluno | Etapa de identificação demonstrativa, código da avaliação, matrícula e versão A |
| Comparar com o gabarito | Cálculo local usando as respostas fictícias confirmadas |
| Saber qual alternativa foi marcada | Resultado individual e prévia do relatório com uma coluna por questão |
| Alternativa mais assinalada | Distribuição por alternativa, taxa de acerto e empates na maior frequência |
| Importar alunos | Conferência de uma planilha de exemplo, sem leitura de arquivo real; matrículas repetidas são ignoradas |
| Folha individualizada | Seleção do aluno na prévia da folha e do caderno |
| Relatório Excel | Tela de configuração e tabela de prévia, sem gerar arquivo |
| Evitar questões cortadas entre páginas | Organização lógica de páginas com movimentação de blocos inteiros; medidas de impressão e geração Word reais ficam para a implementação futura |
| Uso minimalista e lógico | Quatro áreas principais, cabeçalhos comuns, hierarquia visual e ações por etapa |

## Decisões de demonstração

- Uma versão A por avaliação. O QR é ilustrativo e não contém dados reconhecíveis pelo aplicativo.
- De 1 a 60 questões e de 2 a 5 alternativas, com o mesmo número de alternativas em toda a avaliação.
- Questões com pesos iguais, nota entre 0 e 10 e resposta em branco valendo zero. O relato não especifica regras de peso; esta é uma escolha da demonstração.
- A composição de questões e a troca de turma ficam bloqueadas após a primeira correção. Editar o gabarito depois de corrigir requer confirmação e recalcula as notas da sessão.
- Ler novamente o mesmo aluno substitui o resultado anterior somente após revisão e confirmação, sem duplicar a contagem.
- A avaliação pode ser concluída com alunos pendentes, após confirmar a quantidade corrigida. É possível continuar lendo depois.
- Cadastro, senha, importação, câmera, QR, reconhecimento e exportação são explicitamente simulados.
- O estado é compartilhado por `SessionStore`, em memória. Trocar de aba preserva busca e estado das telas; fechar/recarregar o app inicia outra sessão.

## Direção visual

| Papel | Cor |
| --- | --- |
| Ação principal e acertos | Roxo `#7952B9` |
| Texto e cartões escuros | Roxo profundo `#342047` |
| Destaque e alternativas | Lavanda `#B79AD8` |
| Superfícies de apoio | Lilás `#F0EAF8` |
| Fundo | Claro `#F8F6FA` |
| Revisão | Âmbar `#91621C` sobre `#FFF2D9` |

A fonte Manrope é distribuída localmente, com sua licença OFL. O símbolo é o monograma EG contínuo: o ícone de instalação tem fundo roxo e traços brancos, ampliados em 10%; os cabeçalhos usam o símbolo preto, sem fundo, ao lado da escrita EasyGrade. Android e Web usam a mesma identidade.

A abertura dura 2,6 segundos: aparecem marcações de respostas, uma faixa de leitura atravessa o quadro, o símbolo é revelado e o nome entra suavemente. A preferência de reduzir movimento do aparelho e a opção nas configurações pulam a abertura.

## Verificação

Os testes cobrem cálculo das notas, revisão obrigatória de leituras incertas, substituição de resultados, cadastro de matrículas, isolamento das sessões, criação/duplicação/exclusão, navegação com busca preservada e calendário em português. Uma verificação de layout percorre 30 telas em 320 e 430 pixels com texto ampliado em 30%.

As telas também são conferidas no navegador em tamanho de celular. Compilar o APK confirma a construção para Android; a execução em um aparelho físico continua sendo uma verificação separada.
