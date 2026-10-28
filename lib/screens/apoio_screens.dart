import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/correcao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'auth_screens.dart';

class TurmasScreen extends StatelessWidget {
  const TurmasScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    return AppPage(
        title: 'Turmas e alunos',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(
              title: 'Turmas',
              subtitle:
                  'Organize as turmas e a identificação nas folhas de respostas.'),
          if (store.turmas.isEmpty)
            const EmptyState(
                title: 'Nenhuma turma cadastrada',
                subtitle: 'Adicione uma turma para cadastrar alunos.',
                icon: Icons.groups_outlined)
          else
            ...store.turmas.map((t) => ActionTile(
                icon: Icons.groups_outlined,
                title: t,
                subtitle: '${store.alunos(t).length} alunos',
                onTap: () => abrir(context, AlunosScreen(turma: t)))),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: () async {
                final nome =
                    await _novoNome(context, 'Nova turma', 'Nome da turma');
                if (!context.mounted || nome == null) return;
                if (store.turmas.contains(nome)) {
                  avisar(context, 'Esta turma já existe.');
                  return;
                }
                store.adicionarTurma(nome);
                abrir(context, AlunosScreen(turma: nome));
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar turma')),
        ]));
  }
}

Future<String?> _novoNome(
    BuildContext context, String titulo, String label) async {
  final controller = TextEditingController();
  final form = GlobalKey<FormState>();
  final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
              title: Text(titulo),
              content: Form(
                  key: form,
                  child: TextFormField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(labelText: label),
                      validator: obrigatorio)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        Navigator.pop(c, controller.text.trim());
                      }
                    },
                    child: const Text('Adicionar'))
              ]));
  // O diálogo mantém o campo durante a animação de saída.
  Future<void>.delayed(const Duration(milliseconds: 400), controller.dispose);
  return result;
}

class AlunosScreen extends StatelessWidget {
  final String turma;
  const AlunosScreen({super.key, required this.turma});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context), alunos = store.alunos(turma);
    return AppPage(
        title: turma,
        actions: [
          IconButton(
              tooltip: 'Excluir turma',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (await confirmar(
                    context,
                    'Excluir turma?',
                    'A turma e seus alunos serão removidos.',
                    action: 'Excluir')) {
                  store.removerTurma(turma);
                  if (context.mounted) Navigator.pop(context);
                }
              })
        ],
        child: ListView(padding: const EdgeInsets.all(24), children: [
          PageHeading(
              eyebrow: '${alunos.length} alunos',
              title: turma,
              subtitle: 'A matrícula identifica cada aluno na correção.'),
          ActionTile(
              icon: Icons.upload_file_outlined,
              title: 'Importar lista de alunos',
              subtitle: 'Visualize a conferência de uma planilha de exemplo.',
              onTap: () => abrir(context, ImportarAlunosScreen(turma: turma))),
          ActionTile(
              icon: Icons.person_add_alt_rounded,
              title: 'Adicionar aluno',
              subtitle: 'Cadastre nome e matrícula nesta turma.',
              onTap: () => abrir(context, NovoAlunoScreen(turma: turma))),
          const SectionHeading('Alunos da turma'),
          if (alunos.isEmpty)
            const EmptyState(
                title: 'Nenhum aluno cadastrado',
                subtitle: 'Adicione alunos ou use a importação de exemplo.',
                icon: Icons.groups_outlined)
          else
            ...alunos.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SurfaceCard(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.softPurple,
                          child: Text(s.nome.isNotEmpty ? s.nome[0] : '?',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(s.nome,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            Text(s.id,
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.textMuted))
                          ])),
                      IconButton(
                          tooltip: 'Remover aluno da turma',
                          onPressed: () async {
                            if (await confirmar(
                                context,
                                'Remover aluno da turma?',
                                'Resultados já registrados permanecem na avaliação.',
                                action: 'Remover')) {
                              store.removerAluno(turma, s.id);
                            }
                          },
                          icon: const Icon(Icons.person_remove_outlined,
                              size: 18, color: AppColors.textMuted))
                    ]))))
        ]));
  }
}

class NovoAlunoScreen extends StatefulWidget {
  final String turma;
  const NovoAlunoScreen({super.key, required this.turma});
  @override
  State<NovoAlunoScreen> createState() => _NovoAlunoScreenState();
}

class _NovoAlunoScreenState extends State<NovoAlunoScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(), _id = TextEditingController();
  @override
  void dispose() {
    _nome.dispose();
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Adicionar aluno',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        PageHeading(
            title: 'Novo aluno',
            subtitle: 'Adicionar aluno à ${widget.turma}.'),
        Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: obrigatorio),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _id,
                  decoration: const InputDecoration(labelText: 'Matrícula'),
                  validator: obrigatorio)
            ])),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              try {
                SessionScope.of(context).adicionarAluno(
                    widget.turma, Aluno(_id.text.trim(), _nome.text.trim()));
                Navigator.pop(context);
              } on ArgumentError {
                avisar(context, 'Esta matrícula já está na turma.');
              }
            },
            child: const Text('Adicionar à turma'))
      ]));
}

class ImportarAlunosScreen extends StatefulWidget {
  final String turma;
  const ImportarAlunosScreen({super.key, required this.turma});
  @override
  State<ImportarAlunosScreen> createState() => _ImportarAlunosScreenState();
}

class _ImportarAlunosScreenState extends State<ImportarAlunosScreen> {
  static const _planilhaExemplo = [
    Aluno('2026001', 'Ana Clara Souza'),
    Aluno('2026002', 'Bruno Henrique Lima'),
    Aluno('2026003', 'Carlos Eduardo Dias'),
    Aluno('2026004', 'Daniela Martins Rocha'),
    Aluno('2026005', 'Eduardo Santos Silva'),
    Aluno('2026006', 'Fernanda Oliveira Castro'),
    Aluno('2026007', 'Gabriel Alves Pereira'),
    Aluno('2026008', 'Helena Ribeiro Costa'),
  ];

  bool _abriu = false;
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context), lista = store.alunos(widget.turma);
    final novos = _planilhaExemplo
        .where((a) => !lista.any((s) => s.id == a.id))
        .toList();
    return AppPage(
        title: 'Importar alunos',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(
              title: 'Importar alunos',
              subtitle:
                  'O fluxo previsto recebe uma planilha com nome e matrícula e permite conferir os dados.'),
          const InfoBanner(
              'A importação lê nome e matrícula para cadastrar os alunos no Firestore.'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
              onPressed: () => setState(() => _abriu = true),
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Abrir planilha de exemplo')),
          if (_abriu) ...[
            const SectionHeading('Confira antes de importar'),
            SurfaceCard(
                child: Column(children: [
              const Row(children: [
                Icon(Icons.table_chart_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                    child: Text('alunos_exemplo.xlsx',
                        style: TextStyle(fontWeight: FontWeight.w700)))
              ]),
              const SizedBox(height: 16),
              ..._planilhaExemplo.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Expanded(
                        child:
                            Text(s.nome, style: const TextStyle(fontSize: 12))),
                    Text(lista.any((a) => a.id == s.id) ? 'Já na turma' : s.id,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary))
                  ])))
            ])),
            const SizedBox(height: 16),
            InfoBanner(
                '${novos.length} novos alunos · ${_planilhaExemplo.length - novos.length} matrículas já cadastradas serão ignoradas.'),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: novos.isEmpty
                    ? null
                    : () {
                        for (final s in novos) {
                          store.adicionarAluno(widget.turma, s);
                        }
                        Navigator.pop(context);
                        avisar(context,
                            '${novos.length} alunos importados com sucesso.');
                      },
                child: Text(novos.isEmpty
                    ? 'Todos já estão na turma'
                    : 'Importar ${novos.length} alunos'))
          ]
        ]));
  }
}

class QuestoesScreen extends StatefulWidget {
  final String? avaliacaoId;
  const QuestoesScreen({super.key, this.avaliacaoId});
  @override
  State<QuestoesScreen> createState() => _QuestoesScreenState();
}

class _QuestoesScreenState extends State<QuestoesScreen> {
  List<String>? _selecionadas;
  String _busca = '';
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final a = widget.avaliacaoId == null
        ? null
        : store.avaliacao(widget.avaliacaoId!);
    final bloqueado = a != null && store.correcoes(a.id).isNotEmpty;
    _selecionadas ??=
        a == null ? [] : store.questoes(a.id).map((q) => q.id).toList();
    final questoes = store.bancoQuestoes
        .where((q) => '${q.enunciado} ${q.disciplina}'
            .toLowerCase()
            .contains(_busca.toLowerCase()))
        .toList();
    return AppPage(
        title: a == null ? 'Banco de questões' : 'Questões da avaliação',
        actions: [
          IconButton(
              tooltip: 'Nova questão',
              onPressed: () => abrir(context, const NovaQuestaoScreen()),
              icon: const Icon(Icons.add_rounded))
        ],
        bottom: a == null || bloqueado
            ? null
            : ElevatedButton(
                onPressed: () async {
                  if (store.gabaritoPronto(a.id) &&
                      !await confirmar(
                          context,
                          'Atualizar questões e referência?',
                          'As respostas das questões selecionadas serão usadas no gabarito. As posições restantes ficarão sem resposta.',
                          action: 'Atualizar')) {
                    return;
                  }
                  if (!context.mounted) return;
                  store.salvarQuestoes(
                      a.id,
                      _selecionadas!
                          .map((id) =>
                              store.bancoQuestoes.firstWhere((q) => q.id == id))
                          .toList());
                  Navigator.pop(context);
                },
                child: Text(
                    'Usar ${_selecionadas!.length}/${a.numQuestoes} questões')),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          PageHeading(
              title: a == null ? 'Banco de questões' : 'Selecionar questões',
              subtitle: a == null
                  ? 'Crie e consulte suas questões.'
                  : 'Selecione as questões na ordem desejada. A alternativa correta acompanha cada enunciado.'),
          if (bloqueado) ...[
            const InfoBanner(
                'A composição fica bloqueada após a primeira correção para preservar a ordem das respostas.'),
            const SizedBox(height: 16)
          ],
          if (a != null && !bloqueado) ...[
            InfoBanner(
                '${_selecionadas!.length}/${a.numQuestoes} selecionadas. Para provas feitas fora do app, você pode definir o gabarito manualmente.'),
            const SizedBox(height: 16)
          ],
          TextField(
              onChanged: (v) => setState(() => _busca = v),
              decoration: const InputDecoration(
                  hintText: 'Buscar enunciado ou disciplina',
                  prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 20),
          if (questoes.isEmpty)
            const EmptyState(
                title: 'Nenhuma questão encontrada',
                subtitle: 'Adicione uma pergunta ou ajuste a busca.')
          else
            ...questoes.map((q) {
              final selected = _selecionadas!.contains(q.id),
                  compatible =
                      a == null || q.alternativas.length == a.numAlternativas;
              return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Expanded(child: Eyebrow(q.disciplina)),
                          if (a != null)
                            Checkbox(
                                value: selected,
                                onChanged: bloqueado || !compatible
                                    ? null
                                    : (v) {
                                        if (v! &&
                                            _selecionadas!.length >=
                                                a.numQuestoes) {
                                          avisar(context,
                                              'A avaliação já tem ${a.numQuestoes} questões selecionadas.');
                                          return;
                                        }
                                        setState(() => v
                                            ? _selecionadas!.add(q.id)
                                            : _selecionadas!.remove(q.id));
                                      })
                          else
                            IconButton(
                                tooltip: 'Excluir questão',
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppColors.textMuted),
                                onPressed: () async {
                                  if (await confirmar(
                                      context,
                                      'Excluir questão?',
                                      'A questão será removida do banco de questões.',
                                      action: 'Excluir')) {
                                    store.excluirQuestao(q.id);
                                  }
                                })
                        ]),
                        Text(q.enunciado,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ...q.alternativas.indexed.map((alt) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                                '${String.fromCharCode(65 + alt.$1)} · ${alt.$2}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: q.correta == alt.$1
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontWeight: q.correta == alt.$1
                                        ? FontWeight.w700
                                        : FontWeight.w400)))),
                        if (!compatible) ...[
                          const SizedBox(height: 10),
                          Text(
                              'Esta questão tem ${q.alternativas.length} alternativas; a avaliação usa ${a.numAlternativas}.',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.agendadaFg))
                        ],
                        if (selected && a != null) ...[
                          const SizedBox(height: 10),
                          Text(
                              'Posição ${_selecionadas!.indexOf(q.id) + 1} no caderno',
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.primary))
                        ]
                      ])));
            })
        ]));
  }
}

class NovaQuestaoScreen extends StatefulWidget {
  const NovaQuestaoScreen({super.key});
  @override
  State<NovaQuestaoScreen> createState() => _NovaQuestaoScreenState();
}

class _NovaQuestaoScreenState extends State<NovaQuestaoScreen> {
  final _form = GlobalKey<FormState>();
  final _enunciado = TextEditingController(),
      _disciplina = TextEditingController();
  final _alternativas = List.generate(5, (_) => TextEditingController());
  int _quantidade = 5;
  int? _correta;
  @override
  void dispose() {
    _enunciado.dispose();
    _disciplina.dispose();
    for (final c in _alternativas) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Nova questão',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Nova questão',
            subtitle:
                'Escreva o enunciado, as alternativas e a resposta correta.'),
        Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                      controller: _disciplina,
                      decoration:
                          const InputDecoration(labelText: 'Disciplina'),
                      validator: obrigatorio),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: _enunciado,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Enunciado'),
                      validator: obrigatorio),
                  const FormLabel('Quantidade de alternativas'),
                  Wrap(spacing: 8, children: [
                    for (final n in [2, 3, 4, 5])
                      ChoiceChip(
                          label: Text('$n'),
                          selected: _quantidade == n,
                          onSelected: (_) => setState(() {
                                _quantidade = n;
                                if (_correta != null && _correta! >= n) {
                                  _correta = null;
                                }
                              }))
                  ]),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _quantidade; i++)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(children: [
                          AnswerBubble(
                              index: i,
                              selected: _correta == i,
                              onTap: () => setState(() => _correta = i)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: TextFormField(
                                  controller: _alternativas[i],
                                  decoration: InputDecoration(
                                      labelText:
                                          'Alternativa ${String.fromCharCode(65 + i)}'),
                                  validator: obrigatorio))
                        ])),
                  const InfoBanner(
                      'Toque na letra para definir a resposta correta.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: () {
                        if (!_form.currentState!.validate()) return;
                        if (_correta == null) {
                          avisar(context, 'Selecione a alternativa correta.');
                          return;
                        }
                        SessionScope.of(context).adicionarQuestao(Questao(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            enunciado: _enunciado.text.trim(),
                            disciplina: _disciplina.text.trim(),
                            alternativas: _alternativas
                                .take(_quantidade)
                                .map((c) => c.text.trim())
                                .toList(),
                            correta: _correta!));
                        Navigator.pop(context);
                      },
                      child: const Text('Salvar questão'))
                ]))
      ]));
}

class AjudaScreen extends StatelessWidget {
  const AjudaScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Como funciona',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Como usar o EasyGrade',
            subtitle:
                'Os alunos fazem a prova física. Você usa o EasyGrade para preparar, ler e conferir as folhas de respostas.'),
        ...[
          (
            '01',
            'Prepare a avaliação',
            'Informe turma e formato. Você pode montar as questões aqui ou usar uma prova que já preparou fora do app.'
          ),
          (
            '02',
            'Defina o gabarito',
            'Marque as alternativas corretas ou experimente a leitura do gabarito de referência. Nesta versão, usamos a ordem da versão A.'
          ),
          (
            '03',
            'Entregue os materiais',
            'Cada aluno recebe a prova e uma folha de respostas identificada. A folha é entregue ao professor, e o aluno pode levar a prova.'
          ),
          (
            '04',
            'Leia uma folha por vez',
            'O QR identifica a folha. A leitura compara as marcações com o gabarito; você revisa marcações incertas antes de confirmar.'
          ),
          (
            '05',
            'Use os resultados',
            'Consulte notas e alternativas mais escolhidas para planejar a devolutiva. O relatório de notas apresenta uma prévia da planilha.'
          ),
        ].map((step) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurfaceCard(
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(step.$1,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  const SizedBox(width: 18),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(step.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(step.$3, style: const TextStyle(fontSize: 12))
                      ]))
                ])))),
        const SizedBox(height: 12),
        const InfoBanner(
            'N1: todas as leituras e identificações são simulações. Dados ficam em memória e são reiniciados ao fechar o app. Não há banco, envio de e-mails, câmera real ou exportação de arquivos.',
            icon: Icons.science_outlined)
      ]));
}
