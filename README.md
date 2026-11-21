<p align="center">
  <img src="SVG/easygradelogo.svg" alt="EasyGrade" width="320">
</p>

# EasyGrade · entrega final N3

**Versão 1.0.0 · build 6 · 21/11/2026**

Aplicativo para professores prepararem e corrigirem avaliações objetivas em papel. O EasyGrade gera materiais identificados, reconhece as respostas fotografadas e apresenta notas e análises após a revisão do professor.

**[Manual do usuário](manual/README.md)** · **[APK Android](EasyGrade.apk)** · **[Validação e checklist de entrega](documentacao/VALIDACAO.md)** · **[Roteiro da apresentação](documentacao/APRESENTACAO.md)**

## N3 · versão atual

O escopo implementado reúne cadastro e acesso por e-mail/senha ou Google, recuperação de senha, turmas e alunos, banco de questões, avaliações com pesos, gabaritos, versões A/B, impressão para toda a turma, leitura de folhas, revisão, resultados e exportação.

As últimas alterações incluem a arte de giz no início, o botão **iniciar correção**, pesos das questões alinhados e legíveis e a simplificação dos avisos de interface e impressão. O cadastro permite informar instituição opcional; a foto Google aparece quando disponível.

A compilação e os testes automatizados são registrados no [relatório de validação](documentacao/VALIDACAO.md). A conferência final com câmera no Android e a situação de Issues/PRs são verificações separadas; consulte esse relatório antes da submissão. Não se considera uma captura de tela de teste como evidência de uso da câmera física.

### Telas da versão atual

<table>
  <tr>
    <td align="center"><img src="manual/imagens/03-inicio.png" alt="Início com o banner de giz e navegação" width="240"><br>Início</td>
    <td align="center"><img src="manual/imagens/08-pesos.png" alt="Vinte questões com pesos alinhados e identificados" width="240"><br>Pesos das questões</td>
    <td align="center"><img src="manual/imagens/14-resultados.png" alt="Notas e indicadores da turma" width="240"><br>Resultados</td>
  </tr>
</table>

As imagens foram capturadas da interface atual, renderizada em tamanho de celular com dados fictícios. O [manual ilustrado](manual/README.md) apresenta o acesso, a preparação, a impressão, a revisão e os relatórios.

| Área | Telas e etapas disponíveis |
| --- | --- |
| Acesso | Login, criação de conta e diálogo de recuperação de senha. |
| Navegação | Abertura, início, avaliações, filtros, seleção para leitura e perfil. |
| Avaliação | Criação/edição, confirmação de criação, detalhes, gabarito e seleção de enunciados. |
| Cadastros | Turmas, alunos, novo aluno, importação, banco e nova questão. |
| Materiais | Seleção de alunos/documentos, versões A/B, organização de páginas e visualização/impressão de PDF. |
| Correção | Captura/seleção de imagem, revisão e resultado individual. |
| Análise | Resultados da turma, análise por questão e relatório Excel. |
| Conta | Perfil, edição, configurações, ajuda e saída. |

### Escopo entregue

1. **Preparar:** cadastrar turma e alunos, importar listas e cadastrar questões.
2. **Montar:** criar avaliação, configurar pesos e definir o gabarito; selecionar enunciados quando desejar gerar o caderno.
3. **Imprimir:** gerar folhas identificadas por aluno e modelo; reunir toda a turma em um PDF, visualizar, imprimir ou compartilhar.
4. **Corrigir:** fotografar ou selecionar a imagem de uma folha, identificar o QR, revisar as marcações e confirmar a nota.
5. **Analisar:** consultar resultados individuais, indicadores da turma, distribuição das alternativas e planilhas.

O professor pode usar uma prova elaborada fora do app: o banco de questões é opcional para esse caminho, mas as folhas de respostas devem ser geradas pelo EasyGrade. Para gerar cadernos completos, é necessário selecionar todos os enunciados.

### Requisitos funcionais finais

Os códigos RF01–RF07 da N2 são mantidos para permitir comparação. A N3 detalha e consolida esses mesmos temas.

| Código | Requisito final e comportamento implementado | Onde conferir |
| --- | --- | --- |
| RF01 | Criar conta com usuário, nome, e-mail e senha; instituição opcional; entrar por senha ou Google; recuperar senha por e-mail; manter sessão e sair. | Acesso, cadastro e Perfil |
| RF02 | Criar, consultar, buscar, filtrar, editar, duplicar, excluir e concluir avaliações; configurar gabarito, data opcional, quantidade de questões/alternativas e pesos. | Avaliações, detalhes, criação e gabarito |
| RF03 | Organizar turmas e alunos; cadastrar e editar nomes; identificar por matrícula; importar XLSX, CSV ou lista de texto, tratando matrículas repetidas. | Turmas e alunos |
| RF04 | Manter banco de questões; compor cadernos; organizar páginas; gerar versões A/B com embaralhamento opcional de questões e alternativas; gerar folhas, cadernos e prova completa em PDF e cadernos em Word; imprimir a turma em uma operação. | Banco de questões e Materiais |
| RF05 | Ler QR e marcações de uma foto; identificar aluno/modelo; aplicar a ordem das questões e alternativas e os pesos; exigir revisão das marcações incertas; confirmar ou substituir a correção de um aluno. | Correção, captura e revisão |
| RF06 | Exibir nota individual, média, maior/menor nota, andamento e estatísticas por questão; exportar notas e respostas para Excel. | Resultados, análise e relatório |
| RF07 | Consultar e editar perfil; mostrar foto Google quando disponível; configurar a pontuação padrão para novas avaliações; acessar ajuda. | Perfil e Configurações |

### Requisitos não funcionais finais

| Código | Requisito | Implementação ou critério de verificação |
| --- | --- | --- |
| RNF01 | Separar os dados por conta. | Caminhos `usuarios/{uid}`, autenticação e regras do Firestore; testes das regras incluídos em `test/firestore.test.cjs`. |
| RNF02 | Processar a foto localmente. | Identificação e marcações são tratadas no dispositivo; as fotos não são enviadas ao Firestore. |
| RNF03 | Interface em português, consistente e adaptável. | Tema compartilhado, fonte local, testes de telas com 320 e 430 px e texto ampliado; grade de pesos também conferida com 20 questões. |
| RNF04 | Exigir conexão para acesso e dados da conta. | Autenticação e persistência dependem de internet; o aplicativo não promete operação completa sem conexão. |
| RNF05 | Dar ao professor controle sobre a correção. | Marcações incertas impedem confirmar até serem revisadas; respostas em branco valem zero; releitura substitui o resultado após confirmação. |
| RNF06 | Manter o projeto organizado e reproduzível. | Camadas de dados, modelos, telas, serviços, tema e componentes; dependências declaradas e arquivos de teste com imagens de referência. |
| RNF07 | Preservar a coerência dos materiais já corrigidos. | Composição, formato e pesos são bloqueados após a primeira correção; mudanças de modelos antes das correções exigem gerar e imprimir novos materiais. |

### Regras e limites de uso

- Avaliações de **1 a 60 questões**, com **2 a 5 alternativas**, uniformes na mesma avaliação. Questões incompatíveis ficam indisponíveis na seleção.
- A pontuação padrão é escolhida em Configurações e usada nas novas avaliações. Os pesos automáticos dividem esse limite; pesos manuais não redistribuem as outras questões. A soma não pode ultrapassar o limite.
- O planejamento informa data e hora para organização e filtros; **não cria lembrete ou notificação**.
- Cada QR identifica avaliação, aluno e modelo. A correção é feita **uma folha por vez**, com revisão; não há captura automática de um lote de fotos.
- Imprima os PDFs em A4, no tamanho original. A leitura depende da qualidade da impressão e da foto. O Word é destinado à edição do caderno, não à alteração do modelo de leitura.
- Alterar questões ou gerar versões invalida os materiais anteriores. Gere os modelos antes de imprimir e não os regenere durante a aplicação da mesma prova.
- A folha impressa reserva um espaço para o professor escrever a nota, sem denominador fixo como “/10”. O resultado calculado é consultado no app.
- O aplicativo é uma ferramenta do professor. O aluno responde à avaliação em papel; não há portal de prova virtual.

## Equipe

| Integrante |
| --- |
| Jorge Luiz Horn Júnior |
| Juliana Maria de Azevedo |
| Lorenzo Foralasso Kochemberger |
| Eduardo Coelho |

## Tecnologias e identidade

Flutter e Dart; Firebase Authentication e Cloud Firestore; ML Kit e ZXing para identificação; processamento local de imagens; PDF/Printing para materiais; Excel/CSV para planilhas. A fonte Manrope acompanha sua [licença OFL](assets/fonts/OFL.txt).

| Cor | Uso |
| --- | --- |
| `#342047` | Roxo profundo, títulos e banner |
| `#7952B9` | Ações e destaques |
| `#B79AD8` | Lavanda, botão principal e marcações |
| `#F0EAF8` | Superfícies de apoio |

## Executar, validar e compilar

Requer Flutter compatível com Dart **3.11 ou superior**. Para Android, instale Java 17 e o Android SDK/NDK solicitado pela versão do Flutter. O Gradle utiliza os valores definidos pelo SDK Flutter.

```sh
flutter pub get
flutter run
```

Para testar no navegador do computador:

```sh
flutter run -d chrome --web-port 5000
```

Abra `http://localhost:5000`. O código é compartilhado, mas permissões de câmera, seleção de arquivos e impressão variam entre navegador e Android.

```sh
flutter analyze
flutter test
flutter build apk --release
```

O APK para entrega está na raiz, em [`EasyGrade.apk`](EasyGrade.apk). A configuração pública do Firebase está em `lib/firebase_options.dart`; as regras e índices estão em `firestore.rules` e `firestore.indexes.json`. Uma assinatura Android diferente exige cadastrar seu SHA no projeto Firebase para o login Google. A assinatura da entrega acadêmica é a assinatura local de desenvolvimento já usada neste projeto.

Os testes opcionais das regras usam Node.js, Java e Firebase Emulator:

```sh
npm ci
npm run test:firestore
```

Esses testes usam o projeto de demonstração `demo-easygrade`; não executam contra os dados de produção. Veja no [relatório](documentacao/VALIDACAO.md) quais verificações foram executadas nesta entrega.

### Organização

```text
lib/              dados, modelos, telas, serviços, tema e componentes
android/          aplicativo e configuração Android
web/              execução no navegador
assets/           fonte, licença e arte do banner
SVG/              marcas vetoriais
manual/           manual ilustrado do usuário
documentacao/     validação e roteiro da apresentação
historico/        registros anteriores preservados
test/             testes e imagens de referência para leitura
EasyGrade.apk     APK atual
```

## Histórico · do mais recente para o mais antigo

### N2 · dados e funções reais

Autenticação, persistência, importação, leitura das folhas, materiais e exportação deixaram de ser demonstrativos. A N2 reagrupou os requisitos em RF01–RF07. O backlog, a comparação dos requisitos e todas as informações do README anterior foram preservados no **[README histórico da N2](historico/N2/README.md)**, inclusive a comparação com a N1 original e reformulada.

### N1 reformulada · navegação e identidade

Reforma visual, revisão das respostas, turmas, banco de questões, prévias de materiais e relatórios, ainda com dados locais e funções demonstrativas. O **[registro histórico da N1](historico/N1/README.md)** preserva suas regras, decisões de demonstração e correspondência com o relato do cliente.

### N1 original · protótipo navegável

Login, criação, histórico e resultados com dados fictícios, antes da integração com banco. **[Vídeo da primeira entrega](https://youtu.be/tSS6fOFkVIA)**, anterior à reformulação.

Os registros históricos descrevem o estado de cada época e podem mencionar funções simuladas ou opções que já mudaram. Para o uso atual, consulte este README e o [manual](manual/README.md).
