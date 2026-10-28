import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/avaliacao.dart';
import '../models/correcao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'layout_prova_screen.dart';

class MateriaisScreen extends StatefulWidget {
  final String avaliacaoId;
  const MateriaisScreen({super.key, required this.avaliacaoId});
  @override
  State<MateriaisScreen> createState() => _MateriaisScreenState();
}

class _MateriaisScreenState extends State<MateriaisScreen> {
  String? _alunoId;
  bool _caderno = false;
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final a = store.avaliacaoOuNull(widget.avaliacaoId);
    if (a == null) {
      return const AppPage(
          title: 'Materiais da avaliação',
          child: Center(child: CircularProgressIndicator()));
    }
    final alunos = store.alunos(a.turma);
    final aluno = alunos.where((s) => s.id == _alunoId).firstOrNull;
    return AppPage(
        title: 'Materiais da avaliação',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(
              title: 'Materiais da avaliação',
              subtitle:
                  'Visualize a folha de respostas e o caderno. A prova é feita no papel.'),
          const InfoBanner(
              'Prévia de demonstração. O QR Code é ilustrativo; impressão, arquivos e embaralhamento real ficam para uma etapa futura.'),
          const FormLabel('Identificação da folha'),
          DropdownButtonFormField<String>(
              key: ValueKey('${alunos.length}'),
              initialValue: _alunoId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Folha sem nome preenchido')),
                ...alunos.map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.nome)))
              ],
              onChanged: (v) => setState(() => _alunoId = v),
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded))),
          const SizedBox(height: 18),
          Wrap(spacing: 8, children: [
            ChoiceChip(
                label: const Text('Folha de respostas'),
                selected: !_caderno,
                showCheckmark: false,
                onSelected: (_) => setState(() => _caderno = false)),
            ChoiceChip(
                label: const Text('Caderno de prova'),
                selected: _caderno,
                showCheckmark: false,
                onSelected: (_) => setState(() => _caderno = true))
          ]),
          const SizedBox(height: 20),
          if (!_caderno)
            FolhaRespostas(avaliacao: a, aluno: aluno)
          else
            SurfaceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const Brand(size: 24),
                  const SizedBox(height: 20),
                  Text(a.nome, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                      '${aluno?.nome ?? 'Nome: _____________________'}\n${a.turma} · Versão A'),
                  const SizedBox(height: 20),
                  const Divider(),
                  if (store.questoes(a.id).isEmpty)
                    const EmptyState(
                        title: 'Adicione os enunciados',
                        subtitle:
                            'Use “Questões da avaliação” para selecionar as perguntas do caderno.',
                        icon: Icons.library_books_outlined)
                  else
                    ...store.questoes(a.id).indexed.map((item) => Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.$1 + 1}. ${item.$2.enunciado}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              const SizedBox(height: 10),
                              ...item.$2.alternativas.indexed.map((alt) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                      '${String.fromCharCode(65 + alt.$1)}) ${alt.$2}',
                                      style: const TextStyle(fontSize: 12))))
                            ])))
                ])),
          const SizedBox(height: 20),
          OutlinedButton.icon(
              onPressed: () => abrir(
                  context, _ConfiguracaoMateriaisScreen(avaliacaoId: a.id)),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Opções de geração')),
        ]));
  }
}

class FolhaRespostas extends StatelessWidget {
  final Avaliacao avaliacao;
  final Aluno? aluno;
  final List<int?>? respostas;
  final bool compact;
  const FolhaRespostas(
      {super.key,
      required this.avaliacao,
      this.aluno,
      this.respostas,
      this.compact = false});
  @override
  Widget build(BuildContext context) => SurfaceCard(
      padding: EdgeInsets.all(compact ? 16 : 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Brand(size: 23),
          Spacer(),
          Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.primaryDark)
        ]),
        const SizedBox(height: 18),
        Text(avaliacao.nome,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
            '${aluno?.nome ?? 'Nome: ____________________'}\n${aluno?.id ?? 'Matrícula: _________________'} · ${avaliacao.turma}',
            style: const TextStyle(fontSize: 10, height: 1.7)),
        const SizedBox(height: 10),
        const Text('Versão A · Preencha apenas uma alternativa por questão.',
            style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),
        for (var q = 0;
            q <
                (compact
                    ? avaliacao.numQuestoes.clamp(1, 6)
                    : avaliacao.numQuestoes);
            q++)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                SizedBox(
                    width: 30,
                    child: Text('${q + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700))),
                ...List.generate(avaliacao.numAlternativas, (alt) {
                  final resposta = respostas == null ? null : respostas![q];
                  final incerta =
                      resposta == -2 && alt == q % avaliacao.numAlternativas;
                  final marcada =
                      resposta == alt || (resposta == -1 && alt < 2);
                  return Expanded(
                      child: Center(
                          child: Container(
                              width: compact ? 21 : 27,
                              height: compact ? 21 : 27,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: marcada
                                          ? AppColors.primaryDark
                                          : AppColors.textMuted),
                                  color: marcada
                                  ? AppColors.primaryDark
                                  : incerta
                                      ? AppColors.textMuted
                                          .withValues(alpha: .3)
                                      : Colors.white),
                              child: Center(
                                  child: Text(String.fromCharCode(65 + alt),
                                      style: TextStyle(
                                          fontSize: compact ? 8 : 10,
                                          color: marcada
                                              ? Colors.white
                                              : AppColors.textSecondary))))));
                })
              ])),
        if (compact && avaliacao.numQuestoes > 6)
          Text('… ${avaliacao.numQuestoes} questões no total',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 9)),
        const SizedBox(height: 14),
        const Divider(),
        const SizedBox(height: 10),
        Text('${avaliacao.codigo} · QR ilustrativo · N1',
            style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
      ]));
}

class _ConfiguracaoMateriaisScreen extends StatefulWidget {
  final String avaliacaoId;
  const _ConfiguracaoMateriaisScreen({required this.avaliacaoId});
  @override
  State<_ConfiguracaoMateriaisScreen> createState() =>
      _ConfiguracaoMateriaisScreenState();
}

class _ConfiguracaoMateriaisScreenState
    extends State<_ConfiguracaoMateriaisScreen> {
  bool _nomes = true;
  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Opções de geração',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Opções dos materiais',
            subtitle:
                'Veja como os materiais serão preparados para os alunos.'),
        SurfaceCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _nomes,
              onChanged: (v) => setState(() => _nomes = v),
              title: const Text('Identificar cada aluno',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              subtitle: const Text('Nome e matrícula na folha de respostas.',
                  style: TextStyle(fontSize: 12))),
          const Divider(),
          const SizedBox(height: 16),
          const Text('Formato A4 · Versão A',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
              'Um enunciado e suas alternativas devem permanecer juntos na mesma página.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),
          const InfoBanner(
              'Geração de arquivos, provas embaralhadas e edição de paginação em Word são recursos previstos. Esta tela apresenta somente as opções da N1.')
        ])),
        const SizedBox(height: 16),
        ActionTile(
            icon: Icons.view_agenda_outlined,
            title: 'Organizar páginas do caderno',
            subtitle: 'Mova as questões inteiras entre páginas da prévia.',
            onTap: () => abrir(
                context, LayoutProvaScreen(avaliacaoId: widget.avaliacaoId))),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () {
              avisar(context,
                  'Prévia ${_nomes ? 'individualizada' : 'sem nomes'} selecionada. Nenhum arquivo foi gerado.');
            },
            child: const Text('Simular preparação dos materiais'))
      ]));
}
