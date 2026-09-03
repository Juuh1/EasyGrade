# App de Correção Automatizada de Avaliações — Católica SC (N1)

Aplicativo mobile desenvolvido em **Flutter/Dart** para auxiliar professores no processo de elaboração, agendamento, aplicação e correção automatizada de provas e simulados.

O projeto segue as diretrizes da identidade visual institucional da **Católica SC** e os mockups especificados no Figma.

---

## 1. Objetivo do Projeto

Reduzir o tempo excessivo gasto pelos professores na correção manual de grandes volumes de provas (200 a 400 provas em períodos de avaliação), automatizando a leitura de folhas de respostas com gabarito, agilizando o feedback imediato para os alunos e gerando análises estatísticas pedagógicas de acertos e erros por alternativa.

---

## 2. Escopo Delimitado — Fase N1

Na **Fase N1**, o escopo contempla:
- **Telas navegáveis** estruturadas e interligadas por botões e barra de navegação inferior.
- **Dados fictícios (Mock)** integrados às telas (sem banco de dados real nesta fase).
- **Validação visual de formulários e feedback de tela (Processo N1)**: indicação clara de campos obrigatórios, banners de alerta com estados de erro e feedback imediato para o usuário.

### Divisão do Desenvolvimento em 3 Passos:
1. **Passo 1 (Concluído)**: Formulário de Cadastro/Criação de Avaliação com validação visual estrita de formulário e feedback de tela.
2. **Passo 2 (Próximo)**: Tela de Confirmação/Sucesso com resumo dos dados e botão de retorno à Home.
3. **Passo 3 (Final)**: Tela de Histórico com listagem, badges de status, filtros dinâmicos e ações contextuais.

---

## 3. Requisitos do Sistema

### Requisitos Funcionais (RF)
- **RF01 — Cadastro de Avaliação**: Permitir que o professor informe o nome da avaliação, selecione ou digite a disciplina, escolha a turma, defina a data da prova, a quantidade de questões e a quantidade de alternativas por questão (4, 5 ou 6).
- **RF02 — Validação Visual de Campos**: Validar obrigatoriedade dos campos com destaque visual em vermelho (`#DC2626`) e mensagem *"Este campo é obrigatório"*.
- **RF03 — Banner de Feedback de Erro**: Exibir no topo do formulário banner de alerta com fundo suave (`#FCE8E8`), ícone de alerta e mensagem para revisar campos destacados.
- **RF04 — Criação com Mock Data**: Ao submeter formulário válido, instanciar a entidade `Avaliacao` e registrá-la na lista em memória (`MockData`).
- **RF05 — Feedback de Sucesso**: Exibir confirmação com resumo dos dados após a criação da prova.
- **RF06 — Listagem e Histórico**: Apresentar cards das avaliações com nome, turma, data, quantidade de questões/alternativas e badge de status (Concluída, Agendada, Rascunho).
- **RF07 — Filtros e Busca**: Filtrar avaliações por termo de busca, abas rápidas de status e modal de filtros combinados (turma, disciplina, período).
- **RF08 — Navegação Inferior**: Permitir alternância entre as abas *Home*, *Criar* e *Histórico* com destaque visual no item ativo.

### Requisitos Não Funcionais (RNF)
- **RNF01 — Plataforma**: Mobile (Android / iOS), desenvolvido com Flutter 3.x e Dart.
- **RNF02 — Design System & Aderência ao Figma**: Seguir as cores, raios de borda, espaçamentos e tipografia estabelecidos nos tokens visuais da Católica SC.
- **RNF03 — Responsividade**: Layout adaptável que mantém proporções ideais tanto em celulares compactos quanto em telas maiores (centralização com largura máxima de 480px).
- **RNF04 — Usabilidade**: Interface limpa, minimalista e objetiva, priorizando facilidade de uso para o professor.

---

## 4. Identidade Visual (Design Tokens)

- **Ação Primária / Header**: Vinho Católica SC (`#8B1D3F`)
- **Acento Coral**: Coral vibrante (`#E5283B`)
- **Azul Institucional**: Azul escuro (`#103A58`)
- **Destaque Dourado**: Amarelo/Dourado (`#F5A623`)
- **Alerta / Erro (Fundo)**: `#FCE8E8`
- **Alerta / Erro (Texto e Bordas)**: `#DC2626`
- **Sucesso (Fundo e Texto)**: `#DCFCE7` / `#16A34A`
- **Agendada (Fundo e Texto)**: `#FDEBD3` / `#B45309`
- **Rascunho (Fundo e Texto)**: `#EEEFF1` / `#6B7280`
- **Tipografia**: Poppins / Roboto com pesos regular, medium e semibold.

---

## 5. Estrutura do Projeto

```
lib/
├── data/
│   └── mock_data.dart            # Dados fictícios para simulação N1
├── models/
│   ├── avaliacao.dart            # Entidade central da prova/avaliação
│   ├── filtro_avaliacao.dart     # Modelo para filtros combinados
│   ├── resultado_avaliacao.dart  # Estatísticas da correção
│   └── status_avaliacao.dart     # Enum (concluida, agendada, rascunho)
├── screens/
│   ├── criar_avaliacao_screen.dart    # Passo 1: Cadastro & Validação Visual
│   ├── detalhes_avaliacao_screen.dart # Detalhes da avaliação e métricas
│   └── historico_screen.dart          # Listagem, busca e filtros
├── theme/
│   └── app_theme.dart            # Cores, raios, espaçamentos e tema M3
├── widgets/
│   ├── app_bottom_nav.dart       # Barra inferior com pill ativa do Figma
│   ├── avaliacao_card.dart       # Card de histórico de avaliação
│   ├── filtros_bottom_sheet.dart # Modal de filtros avançados
│   └── status_badge.dart         # Badge de status com cores semânticas
└── main.dart                     # Ponto de entrada com MainNavigationShell
```

---

## 6. Como Executar o Projeto

1. Certifique-se de ter o Flutter instalado e configurado no ambiente.
2. No terminal, na raiz do projeto:
   ```bash
   flutter pub get
   flutter run
   ```
3. O app iniciará diretamente na aba **Criar**, onde o **Passo 1** pode ser avaliado e testado de forma interativa.
