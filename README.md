<p align="center">
  <img src="SVG/easygradelogo.svg" alt="EasyGrade" width="320">
</p>

# EasyGrade

Aplicativo Flutter para professores que corrigem avaliações objetivas em papel. O professor prepara a avaliação e as folhas de respostas, fotografa cada folha e revisa as marcações reconhecidas antes de confirmar os resultados.

## Equipe

| Integrante |
| --- |
| Jorge Luiz Horn Júnior |
| Juliana Maria de Azevedo |
| Lorenzo Foralasso Kochemberger |
| Eduardo Coelho |

## Objetivo

Reduzir o tempo gasto na correção de avaliações objetivas e apoiar a devolutiva pedagógica com resultados individuais e análise das alternativas mais marcadas. Os alunos fazem a prova física, entregam a folha de respostas e podem levar o caderno para estudar.

## Versões do projeto

| Versão | O que entrega | Dados |
| --- | --- | --- |
| **N1** | Protótipo navegável: login, criação, histórico e resultados | Mock, sem persistência |
| **N1 reformulada** | Reforma visual e complementação: leitura simulada, revisão, turmas, banco de questões, materiais, análise e relatório | Fictícios, em memória |
| **N2** | Integração com Firebase: autenticação real, Firestore, leitura de folhas no aparelho, geração de PDF e exportação em Excel | Cloud Firestore |

Fluxo principal atual: entrar na conta, cadastrar turma e alunos, montar avaliação e gabarito, gerar e imprimir cadernos e folhas, fotografar as respostas, revisar a leitura e consultar ou exportar os resultados.

## Requisitos funcionais

Os códigos mudaram entre as versões. A tabela agrupa cada requisito pelo tema e mostra como ele estava em cada entrega, para facilitar a conferência do que foi cumprido, alterado ou deixado de fora.

| Requisito | N1 | N1 reformulada | N2 (atual) |
| --- | --- | --- | --- |
| **Acesso, cadastro e recuperação de senha** | RF01 · simulado | RF01 · demonstrativo (User / User) | **RF01** · e-mail e senha ou Google, recuperação de senha e sessão mantida. *Alterado: agora é real.* |
| **Tela inicial com atalhos** | RF02 · implementado | RF02 · navegável | Mantida nas telas de início e perfil, sem código próprio. |
| **Criar avaliação** (nome, disciplina, turma, data, questões e alternativas) | RF03 · dados locais | RF03 · em memória | **RF02** · criar, consultar, editar e excluir avaliações e gabaritos, persistidos no Firestore. |
| **Buscar e filtrar avaliações** (situação, disciplina, turma e período) | RF04 · dados mock | RF04 · dados da sessão | Mantida nas telas de avaliações e filtros, sem código próprio. |
| **Detalhes e gerenciamento da avaliação** (rascunho, agendada, concluída) | RF05 · implementado | RF05 · edição, duplicação, exclusão e conclusão locais | Coberta pelo **RF02**. |
| **Resultados individuais e indicadores da turma** (média, maior e menor nota) | RF06 · mock | RF06 · calculado sobre respostas fictícias | **RF06** · notas e estatísticas por aluno, turma e questão. |
| **Ler e corrigir folhas de resposta** | RF07 · *próximas etapas* | RF07 · QR e captura simulados, comparação local com o gabarito | **RF05** · foto da folha, reconhecimento de identificação e marcações, revisão e confirmação. *Alterado: agora é real.* |
| **Estatísticas por questão e alternativa assinalada** | RF08 · *próximas etapas* | RF08 · calculado sobre resultados confirmados | Coberta pelo **RF06**. |
| **Relatório de notas em planilha** | RF09 · *próximas etapas* | RF09 · prévia da planilha, exportação simulada | **RF06** · exportação das respostas para Excel. |
| **Turmas, alunos e importação** | RF10 · *próximas etapas* | RF10 · dados locais e planilha de exemplo fixa | **RF03** · organização de turmas e alunos; importação por XLSX, CSV ou texto. |
| **Materiais impressos identificados** | RF10 · *próximas etapas* | RF10 · prévia da folha e do caderno | **RF04** · preparação de cadernos e folhas identificadas, com versões embaralhadas. |
| **Banco de questões e composição do caderno** | — | RF11 · banco em memória | **RF04** · banco de questões persistido. |
| **Configurar gabarito, conferir ambiguidades e reler um aluno** | — | RF12 · revisão obrigatória, substituição sem duplicar | Coberta pelo **RF05** (revisão antes da confirmação). |
| **Perfil, senha e preferências** | Perfil e configurações locais (no escopo) | Edição de perfil, configurações e ajuda | **RF07** · consulta e atualização de perfil, senha e preferências da conta. |

### Resumo da situação

- **Cumpridos e mantidos:** acesso, avaliações, resultados, estatísticas, turmas, alunos, materiais, banco de questões, revisão e perfil.
- **Alterados:** acesso, leitura de folhas, importação, exportação e persistência deixaram de ser simulados na N2. Os requisitos foram reagrupados de 12 para 7 códigos.
- **Que eram *próximas etapas* na N1 e foram concluídos na N2:** leitura e correção de folhas (RF07), estatísticas por questão (RF08), relatório em planilha (RF09) e importação de alunos e geração de provas individualizadas (RF10).
- **Sem código próprio na N2:** tela inicial e busca e filtros continuam nas telas, mas não aparecem mais como requisitos separados.

## Requisitos não funcionais

| Requisito | N1 | N1 reformulada | N2 (atual) |
| --- | --- | --- | --- |
| Interface simples, lógica e consistente | RNF01 | RNF01 · uma ação por etapa | RNF03 · em português e adaptada ao uso móvel |
| Layout para celular e adaptação a larguras maiores | RNF02 | RNF02 · conteúdo limitado a 600 px | RNF03 |
| Resposta rápida sem backend | RNF03 | RNF03 · dados e buscas sem backend | **Alterado:** RNF04 exige internet para autenticação e dados na nuvem. |
| Separação de modelos, estado, telas, tema e componentes | RNF04 | RNF04 | Mantida na organização do código. |
| Proteção dos dados dos usuários | RNF05 · *quando houver backend* | RNF05 · ações simuladas sinalizadas, sem persistência | **RNF01** · dados separados pelo identificador da conta, nas regras e no acesso ao Firestore. |
| Flutter e Dart, multiplataforma | RNF06 | RNF06 · português brasileiro e fonte local | Mantido (Flutter e Dart). |
| Redução de movimento, campos validados e texto ampliado | — | RNF07 | RNF03 · respeita a preferência por redução de movimento. |
| Fotos processadas no aparelho | — | — | **RNF02** · fotos não são enviadas ao Firestore. |
| Revisão da leitura pelo professor | — | — | **RNF05** · a leitura depende de impressão e foto adequadas e deve ser revisada antes da confirmação. |

## Limites e pendências

| Item | Situação |
| --- | --- |
| Autenticação, persistência e integração com banco de dados | Fora do escopo da N1 e da reformulada; **concluídas na N2**. |
| Câmera e QR Code | Simulados na N1 e na reformulada; **reais na N2**. |
| Exportação para Excel | Simulada até a reformulada; **real na N2**. |
| Impressão, PDF, paginação real e embaralhamento | Não implementados até a reformulada; **geração e versões embaralhadas na N2**. |
| Funcionamento sem internet | Não suportado na N2 (RNF04). |
| Qualidade da leitura | Depende de impressão em A4 no tamanho original, quatro marcas dos cantos visíveis e caneta preta ou azul. |


O aplicativo reúne ainda cadastro e recuperação de acesso; edição e confirmação de avaliação; gabarito; seleção para leitura; relatório; turmas, alunos e importação; banco e criação de questões; materiais; perfil, alteração de senha, configurações e ajuda.

## Tecnologias

- **Flutter e Dart:** interface e aplicativo Android.
- **Firebase Authentication:** contas de professores e login Google.
- **Cloud Firestore:** avaliações, turmas, alunos, questões, gabaritos e correções.
- **Google ML Kit, ZXing e QR Flutter:** identificação das folhas por QR Code.
- **Image Picker e Image:** captura, seleção e processamento local das imagens.
- **PDF e Printing:** geração, impressão e compartilhamento dos materiais.
- **Excel e CSV:** importação de alunos e exportação de resultados.
- **Manrope:** fonte local, com [licença OFL](assets/fonts/OFL.txt).

Identidade visual: roxo `#7952B9`, roxo profundo `#342047`, lavanda `#B79AD8` e lilás `#F0EAF8`. O monograma EG usa branco sobre roxo no ícone de instalação e preto sem fundo dentro do aplicativo.

## Organização do código

```text
lib/
  data/       autenticação, acesso ao Firestore e estado da sessão
  models/     modelos de avaliação, correção, filtros e status
  screens/    telas e fluxos do aplicativo
  services/   leitura de folhas, arquivos e importação
  theme/      cores, tipografia e tema visual
  widgets/    componentes reutilizados pelas telas
android/      configuração da plataforma Android
assets/       fonte Manrope
docs/         documentação da N1 e imagens das telas
SVG/          marcas e elementos vetoriais
test/         testes de notas, ambiguidade, releitura, navegação, calendário e layout
web/          recursos de execução no navegador
```

Os documentos ficam sob `usuarios/{uid}` no Firestore. O repositório de dados valida os caminhos aceitos e associa as operações ao usuário autenticado. As regras de acesso estão em `firestore.rules` e os índices em `firestore.indexes.json`. A [documentação da N1](docs/N1.md) relaciona as telas ao relato do cliente.

## Como executar

Requisitos: Flutter 3.41 ou superior, Dart 3.11 ou superior, Android SDK e Java 17 ou superior.

```sh
flutter pub get
flutter run
```

A configuração pública do Firebase está em `lib/firebase_options.dart` (projeto `easygrade-dc9be`). Para o login Google em outra instalação Android, cadastre no Firebase o SHA do certificado de assinatura correspondente.

Comandos de validação e build:

```sh
flutter analyze
flutter test
flutter build apk --release
```

O APK entregue está em [`EasyGrade.apk`](EasyGrade.apk).

## Backlog da N2

| Responsável | Tarefa | Prazo previsto | Situação |
| --- | --- | --- | --- |
| Jorge | Configurar o projeto Firebase, Firestore, coleções e regras de segurança | 07/10/2026 | Concluída |
| Jorge | Criar a camada reutilizável de acesso ao Firestore | 09/10/2026 | Concluída |
| Juliana | Revisar e ajustar classes de domínio e Issues para a integração com dados reais | 12/10/2026 | Concluída |
| Lorenzo | Substituir os mocks e integrar o módulo 1 ao Firestore | 13/10/2026 | Concluída |
| Eduardo | Substituir os mocks e integrar os módulos 2 e 3 ao Firestore | 13/10/2026 | Concluída |

### Complemento da N1

| Responsável | Tarefa | Período | Situação |
| --- | --- | --- | --- |
| Jorge | Reformulação visual e complementação da N1 | 01/10/2026 a 06/10/2026 | Concluída |

## Apresentação

[Vídeo da primeira entrega](https://youtu.be/tSS6fOFkVIA), anterior à reformulação da N1.
