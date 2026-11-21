# Validação e conferência da entrega N3

**EasyGrade 1.0.0 · build 6 · 21/11/2026**

Este documento separa as verificações executadas das conferências que dependem de aparelho, acesso ao repositório ou apresentação pela equipe. Ele não é um diário de bordo.

## Verificações automatizadas

O resumo final dos comandos, da APK e do ZIP está em [ENTREGA.md](ENTREGA.md). Os testes incluídos no código cobrem:

| Área | Cobertura |
| --- | --- |
| Leitura de folhas | QR, respostas corretas, folha em branco, perspectiva, rotação, foto sem identificação válida e 60 questões em três colunas. |
| Notas e dados | Pesos, respostas em branco, marcações incertas, ordem das versões, substituição de correção, matrículas e edição de turmas. |
| Materiais | Geração de PDF, caderno Word e relatório Excel; referências de versões A/B. |
| Telas e navegação | Fluxo de revisão até resultado, manutenção de busca entre abas, calendário em português, layout com texto ampliado e pesos de 20 questões. |
| Acesso | Recuperação de senha: validação de e-mail e solicitação do link sem autenticar o usuário. O envio real depende do serviço de autenticação. |

As 18 imagens do manual foram renderizadas a partir das telas atuais, com fonte e ícones do app e dados fictícios. Não são fotos de um Android nem uma prova de funcionamento da câmera física.

Os testes de segurança do Firestore estão em `test/firestore.test.cjs` e podem ser executados no Emulator com `npm run test:firestore`. Sua reexecução não integra a evidência automatizada desta rodada, que não alterou as regras.

## Conferência final no Android

Não havia aparelho conectado ao computador durante esta preparação. A equipe deve executar o roteiro abaixo com a APK final antes de submetê-la. Testes automatizados e compilação não substituem essa conferência.

1. Instalar/atualizar a APK e conferir o novo banner e o botão **iniciar correção**.
2. Entrar com e-mail/senha; sair e conferir o acesso Google. Conferir a recuperação com uma conta de teste que receba e-mail.
3. Criar uma turma de teste e importar ou cadastrar alunos fictícios.
4. Criar uma avaliação, conferir o gabarito e os pesos; testar a configuração de 20 questões.
5. Gerar versões A/B e imprimir as folhas da turma a partir de um único PDF.
6. Fotografar uma folha de cada versão, com respostas conhecidas; conferir aluno, versão, alternativas e nota esperada.
7. Testar uma folha em branco e outra com dupla marcação; conferir a revisão antes de confirmar.
8. Reler um aluno e confirmar que o resultado é substituído, sem duplicação.
9. Abrir resultados, análise por questão e Excel; comparar a planilha com as notas esperadas.
10. Fechar e reabrir o app com a mesma conta para conferir o carregamento dos dados.

Use uma avaliação nova para os testes. Não regenere modelos de uma prova já impressa que ainda será aplicada.

## Conferência no GitHub

A conexão disponível não permitiu consultar o repositório `Juuh1/EasyGrade` nesta rodada. Por isso, não foi possível verificar nem alterar o estado de Issues, aprovações ou merges. Nenhum fechamento ou merge é declarado como realizado.

Antes da entrega, a equipe deve publicar os arquivos finais e conferir:

- Issues de escopo concluído encerradas, com as evidências pertinentes.
- PRs relevantes revisados, aprovados por quem pode aprovar e integrados à branch de entrega.
- README, manual, imagens e APK atualizados no mesmo estado final do código.
- Ausência de funcionalidades concluídas apenas em branches ainda não integradas.

## Correspondência com as orientações da professora

| Item | Preparação realizada / conferência necessária |
| --- | --- |
| 01 · Funcionalidades e banco | Escopo implementado documentado nos RF/RNF do README; a conferência real da conta e da persistência integra o roteiro Android. |
| 02 · Issues e PRs | Roteiro acima; situação remota não verificada por falta de acesso. |
| 03 · APK de ponta a ponta | Testes automatizados e verificação da compilação/assinatura; falta a rodada final no Android físico. |
| 04 · README e manual | README final, histórico N2/N1 preservado e manual ilustrado em arquivo próprio. |
| 05 · Diário de bordo | Omitido conforme a orientação do solicitante para este semestre. |
| 06 · Pitch | [Roteiro e plano de demonstração](APRESENTACAO.md) preparados; ensaio e apresentação cabem à equipe. |
| 07 · Fonte ZIP e APK | Arquivos e instruções relacionados em [ENTREGA.md](ENTREGA.md). |

**[Voltar ao projeto](../README.md)** · **[Manual do usuário](../manual/README.md)**
