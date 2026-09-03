# Módulo Listagem & Domínio — Membro 2 (N1)

Implementação em Flutter/Dart da parte do app referente ao **Membro 2**,
seguindo o escopo da N1 (telas navegáveis com **dados mock**, sem banco
de dados real) e o layout do Figma (arquivos `3_Mockups_N1_Mobile...png`
e `n1-mobile-mockups-historico-filtros.png`).

## Telas entregues

| Tela | Arquivo | Referência no Figma |
|---|---|---|
| Histórico (listagem com cards interativos, busca e abas rápidas) | `lib/screens/historico_screen.dart` | tela "Histórico" |
| Detalhes da Avaliação | `lib/screens/detalhes_avaliacao_screen.dart` | tela "Detalhes da Avaliação" |
| Modal de Filtros/Busca | `lib/widgets/filtros_bottom_sheet.dart` | modal "Filtros" |

Fluxo de navegação: **Histórico → toca em um card ou em "Ver
resultados"/"Editar avaliação"/"Continuar edição" → Detalhes da
Avaliação**. O ícone de filtro ao lado da busca abre o modal de Filtros
como um bottom sheet, igual ao mockup.

## Domain Models (processo N1)

Ficam em `lib/models/`, sem qualquer dependência de Flutter (puro Dart),
para poderem ser reaproveitados depois com Firestore na N2 sem
reescrever as telas:

- **`Avaliacao`** — entidade central (nome, disciplina, turma, data,
  nº de questões, nº de alternativas, status, código, resultado).
- **`StatusAvaliacao`** — enum `rascunho` / `agendada` / `concluida`,
  com extensão que resolve label, cor do badge e texto do CTA do card
  a partir do próprio status (evita `if/else` espalhado pelas telas).
- **`ResultadoAvaliacao`** — estatísticas de uma avaliação concluída
  (total de respostas, média, maior/menor nota).
- **`FiltroAvaliacao`** — estado imutável do modal de Filtros (busca,
  status selecionados, disciplina, turma, período).

Todos os modelos têm `fromJson`/`toJson`, já preparados para quando a
N2 trocar `MockData` por um repositório que lê/grava no Firestore.

## Dados mock

`lib/data/mock_data.dart` expõe `MockData.avaliacoes`, uma lista
fixa com as 3 avaliações do mockup ("Prova N1 — Engenharia",
"Revisão — Algoritmos", "Simulado — Banco de Dados"), cobrindo os três
status possíveis. Também expõe `MockData.disciplinas` e
`MockData.turmas`, usadas para popular os dropdowns do modal de
Filtros.

## Responsividade

- Todas as telas usam `MediaQuery`/`LayoutBuilder` e o breakpoint
  `AppBreakpoints.compact` (600px) para distinguir celular de
  tablet/desktop.
- Em telas largas, o conteúdo é centralizado com uma largura máxima
  (`ConstrainedBox`), em vez de esticar os cards e o texto até a borda.
- O modal de Filtros também respeita esse limite de largura e usa
  `SingleChildScrollView` para não estourar em telas baixas (teclado
  aberto, por exemplo).

## Como rodar isoladamente

```bash
flutter pub get
flutter run
```

`lib/main.dart` sobe direto na tela de Histórico para permitir testar
este módulo isoladamente. Quando for integrado ao restante do app
(telas de Home e Criar avaliação, dos outros membros), basta trocar a
`home:` do `MaterialApp` e ligar a bottom nav às rotas reais.

## Fora do escopo deste módulo

Telas "Criar avaliação" e "Avaliação criada" (tela de sucesso) e a Home
pertencem a outros membros do grupo; aqui elas aparecem apenas como
itens (desabilitados/mock) da bottom nav para manter a navegação
coerente com o app completo do Figma.
