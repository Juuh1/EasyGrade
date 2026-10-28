# EasyGrade

Aplicativo Android para professores prepararem e corrigirem avaliações objetivas em papel, com identificação por QR Code, revisão das marcações e resultados por aluno e turma.

## Escopo

- Acesso por e-mail e senha ou conta Google, cadastro e recuperação de senha.
- Avaliações, turmas, alunos, banco de questões, gabaritos e correções vinculados à conta do professor no Cloud Firestore.
- Importação de alunos por Excel (.xlsx), CSV ou texto com matrícula e nome.
- Folhas identificadas e cadernos em PDF, impressão e compartilhamento; cadernos editáveis em Word (.docx).
- Versões por aluno com questões e alternativas embaralhadas.
- Captura pela câmera ou galeria, leitura das marcações e revisão antes da confirmação da nota.
- Notas, estatísticas por questão e exportação Excel com as alternativas assinaladas.

## Requisitos

| Código | Requisito funcional |
| --- | --- |
| RF01 | Autenticar o professor e manter seus dados privados. |
| RF02 | Cadastrar, consultar, editar e excluir avaliações. |
| RF03 | Organizar turmas, alunos e questões e importar listas de alunos. |
| RF04 | Definir gabaritos e gerar materiais identificados e versões da prova. |
| RF05 | Ler e revisar folhas de respostas e persistir as correções. |
| RF06 | Consultar notas e estatísticas e exportar as respostas em Excel. |
| RF07 | Atualizar perfil, senha e preferências. |

Requisitos não funcionais: interface em português, navegação adaptada ao celular, respeito à redução de movimento, dados separados por usuário autenticado e processamento das fotos no aparelho. As fotos não são enviadas ao Firestore. A gravação e recuperação dos dados exigem conexão à internet.

## Telas principais

Acesso e cadastro; início; avaliações e filtros; criação e edição da avaliação; gabarito; turmas e alunos; importação; banco de questões; materiais e organização das páginas; captura e revisão; resultados e estatísticas; relatório; perfil e configurações.

## Uso

1. Entre ou crie uma conta. Cadastre a turma e seus alunos.
2. Crie a avaliação e defina seu gabarito. Para gerar o caderno, selecione todas as questões.
3. Em Materiais, gere as versões por aluno se desejar embaralhar a prova. Depois gere os cadernos e as folhas.
4. Imprima as folhas em A4, no tamanho original. Use apenas as folhas geradas pelo EasyGrade para a leitura automática.
5. Fotografe a folha inteira, plana, com boa iluminação e as quatro marcas dos cantos visíveis. Preencha as bolhas com caneta preta ou azul.
6. Confira as respostas reconhecidas, resolva as marcações incertas e confirme. Consulte os resultados ou exporte o Excel.

O reconhecimento depende da qualidade da foto e do preenchimento. A revisão pelo professor é obrigatória. O navegador permite selecionar uma foto; a captura com a câmera é destinada ao Android. Matrículas com zeros à esquerda devem estar como texto na planilha de importação.

## Execução e entrega

Requer Flutter 3.41 ou superior com Dart 3.11 ou superior, Android SDK e Java 17 ou superior.

```sh
flutter pub get
flutter run
flutter build apk --release
```

O projeto utiliza o Firebase `easygrade-dc9be`. A configuração pública do aplicativo está em `lib/firebase_options.dart`; não utiliza chave privada de administrador. Para login Google em outra assinatura Android, cadastre o SHA do certificado no Firebase.

O APK de entrega está em [entrega/EasyGrade.apk](entrega/EasyGrade.apk). O build acadêmico usa a assinatura local de desenvolvimento. Documentos de apoio, testes e arquivos temporários ficam locais, fora do versionamento.
