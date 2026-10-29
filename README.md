# EasyGrade

Aplicativo Android para professores organizarem avaliações objetivas em papel e agilizar a correção. O professor prepara a avaliação e as folhas de respostas, fotografa cada folha e revisa as marcações reconhecidas antes de confirmar os resultados.

## Equipe

| Integrante |
| --- |
| Jorge Luiz Horn Júnior |
| Juliana Maria de Azevedo |
| Lorenzo Foralasso Kochemberger |
| Eduardo Coelho |

## Escopo atual

Na N2, os dados de avaliações, turmas, alunos e questões passaram a ser lidos e gravados no Cloud Firestore, associados à conta autenticada do professor. O aplicativo também prepara os materiais impressos e processa as folhas de resposta no aparelho. A leitura automática auxilia a correção; o professor confere as marcações antes de salvar a nota.

O fluxo principal é: entrar na conta, cadastrar turma e alunos, montar avaliação e gabarito, gerar e imprimir cadernos e folhas, fotografar as respostas, revisar a leitura e consultar ou exportar os resultados.

## Requisitos

### Funcionais

| Código | Requisito |
| --- | --- |
| RF01 | Criar conta, entrar por e-mail e senha ou Google, recuperar a senha e manter a sessão do professor. |
| RF02 | Criar, consultar, editar e excluir avaliações e seus gabaritos. |
| RF03 | Organizar turmas e alunos e importar listas por XLSX, CSV ou texto. |
| RF04 | Manter banco de questões e preparar cadernos e folhas identificadas; permitir versões com questões e alternativas embaralhadas. |
| RF05 | Capturar ou selecionar a foto de uma folha gerada pelo EasyGrade, reconhecer sua identificação e marcações, revisar e confirmar a correção. |
| RF06 | Consultar notas e estatísticas por aluno, turma e questão e exportar respostas para Excel. |
| RF07 | Consultar e atualizar perfil, senha e preferências da conta. |

### Não funcionais

| Código | Requisito |
| --- | --- |
| RNF01 | Manter os dados de cada professor separados pelo identificador da conta autenticada nas regras e no acesso ao Firestore. |
| RNF02 | Processar as imagens da folha no dispositivo; as fotos não são enviadas ao Firestore. |
| RNF03 | Apresentar interface em português, adaptada ao uso móvel, e respeitar a preferência por redução de movimento. |
| RNF04 | Exigir conexão à internet para autenticação e leitura/gravação dos dados na nuvem. |
| RNF05 | A leitura da folha depende de impressão e fotografia adequadas e deve ser revisada pelo professor antes da confirmação. |

## Telas e fluxo

O aplicativo reúne autenticação e cadastro; início e perfil; avaliações e filtros; criação, edição e gabarito; turmas, alunos e importação; banco de questões; preparação e geração dos materiais; leitura pela câmera ou galeria; revisão das respostas; resultados, estatísticas e relatório.

As folhas devem ser geradas pelo EasyGrade e impressas em A4 no tamanho original, com as quatro marcas dos cantos visíveis na foto. O preenchimento deve ser feito com caneta preta ou azul. O navegador permite selecionar imagens; a captura direta pela câmera é destinada ao Android. Matrículas com zeros à esquerda devem ser mantidas como texto na planilha.

## Tecnologias

- **Flutter e Dart:** interface e aplicativo Android.
- **Firebase Authentication:** contas de professores e login Google.
- **Cloud Firestore:** persistência das avaliações, turmas, alunos, questões, gabaritos e correções.
- **Google ML Kit, ZXing e QR Flutter:** identificação das folhas por QR Code.
- **Image Picker e Image:** captura/seleção e processamento local das imagens.
- **PDF e Printing:** geração, impressão e compartilhamento dos materiais.
- **Excel e CSV:** importação de alunos e exportação de resultados.

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
SVG/          marcas e elementos vetoriais do aplicativo
web/          recursos de execução no navegador
```

Os documentos ficam sob `usuarios/{uid}` no Firestore. O repositório de dados valida os caminhos aceitos e associa as operações ao usuário autenticado. As regras de acesso estão em `firestore.rules`; índices declarados ficam em `firestore.indexes.json`.

## Executar o aplicativo

Requisitos locais: Flutter 3.41 ou superior, Dart 3.11 ou superior, Android SDK e Java 17 ou superior.

```sh
flutter pub get
flutter run
```

A configuração pública do Firebase está em `lib/firebase_options.dart` e o projeto Firebase usado é `easygrade-dc9be`. Para autenticação Google em outra instalação Android, cadastre no Firebase o SHA do certificado de assinatura correspondente.

O APK entregue está em [`EasyGrade.apk`](EasyGrade.apk). Para gerar outro APK de release a partir do código:

```sh
flutter build apk --release
```

## Backlog realizado na N2

As tarefas abaixo correspondem às entregas integradas ao projeto nesta fase.

### Juliana Maria de Azevedo

| Tarefa | Prazo previsto | Situação |
| --- | --- | --- |
| Configurar o projeto Firebase, Firestore, coleções e regras de segurança | 07/10/2026 | Concluída |
| Criar a camada reutilizável de acesso ao Firestore | 09/10/2026 | Concluída |

### Lorenzo Foralasso Kochemberger

| Tarefa | Prazo previsto | Situação |
| --- | --- | --- |
| Substituir os mocks e integrar o módulo 1 ao Firestore | 13/10/2026 | Concluída |

### Eduardo Coelho

| Tarefa | Prazo previsto | Situação |
| --- | --- | --- |
| Substituir os mocks e integrar os módulos 2 e 3 ao Firestore | 13/10/2026 | Concluída |

### Jorge Luiz Horn Júnior

| Tarefa | Prazo previsto | Situação |
| --- | --- | --- |
| Revisar e ajustar classes de domínio e Issues para a integração com dados reais | 12/10/2026 | Concluída |
