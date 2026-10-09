import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/status_badge.dart';
import 'criar_avaliacao_screen.dart';
import 'gabarito_screen.dart';
import 'leitura_screen.dart';
import 'resultados_screen.dart';
import 'preparacao_screens.dart';
import 'apoio_screens.dart';

class DetalhesAvaliacaoScreen extends StatelessWidget {
  final String avaliacaoId;
  const DetalhesAvaliacaoScreen({super.key, required this.avaliacaoId});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final a = store.avaliacoes.where((a) => a.id == avaliacaoId).firstOrNull;
    if (a == null) {
      return const AppPage(
          title: 'Avaliação removida',
          child: EmptyState(
              title: 'Avaliação removida da sessão',
              subtitle: 'Volte para suas avaliações.'));
    }
    final pronto = store.gabaritoPronto(a.id);
    final corrigidas = store.correcoes(a.id).length;
    final alunos = store.alunos(a.turma).length;
    return AppPage(
        title: 'Sua avaliação',
        actions: [
          PopupMenuButton<String>(
              tooltip: 'Opções da avaliação',
              onSelected: (value) async {
                if (value == 'editar') {
                  abrir(context, CriarAvaliacaoScreen(avaliacaoId: a.id));
                }
                if (value == 'duplicar') {
                  store.duplicar(a.id);
                  avisar(context, 'Cópia criada nas avaliações.');
                }
                if (value == 'excluir') {
                  if (await confirmar(context, 'Excluir esta avaliação?',
                      'O gabarito e as correções desta avaliação serão removidos da sessão.',
                      action: 'Excluir')) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    store.excluir(a.id);
                  }
                }
              },
              itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'editar', child: Text('Editar informações')),
                    PopupMenuItem(
                        value: 'duplicar', child: Text('Duplicar avaliação')),
                    PopupMenuItem(
                        value: 'excluir',
                        child: Text('Excluir da sessão',
                            style: TextStyle(color: AppColors.dangerFg)))
                  ])
        ],
        child: ListView(padding: const EdgeInsets.all(24), children: [
          Row(children: [
            Eyebrow(a.codigo),
            const Spacer(),
            StatusBadge(status: a.status)
          ]),
          const SizedBox(height: 16),
          PageHeading(
              title: a.nome,
              subtitle: '${a.disciplina}\n${a.turma} · ${a.dataLabelCurta}'),
          Row(children: [
            Metric('${a.numQuestoes}', 'questões'),
            const SizedBox(width: 12),
            Metric('${a.numAlternativas}', 'alternativas'),
            const SizedBox(width: 12),
            Metric('$corrigidas', 'corrigidas', color: AppColors.softPurple)
          ]),
          const SectionHeading('Preparação'),
          ActionTile(
              icon:
                  pronto ? Icons.fact_check_outlined : Icons.edit_note_rounded,
              title: pronto ? 'Gabarito definido' : 'Preparar gabarito',
              subtitle: pronto
                  ? 'Confira as respostas corretas da versão A.'
                  : 'Defina as respostas antes de ler as folhas.',
              onTap: () => abrir(context, GabaritoScreen(avaliacaoId: a.id))),
          ActionTile(
              icon: Icons.library_books_outlined,
              title: 'Questões da avaliação',
              subtitle: 'Selecione enunciados para o caderno da prova.',
              tint: AppColors.softPurple,
              onTap: () => abrir(context, QuestoesScreen(avaliacaoId: a.id))),
          ActionTile(
              icon: Icons.print_outlined,
              title: 'Folhas e caderno de prova',
              subtitle: 'Veja a identificação e o modelo para os alunos.',
              onTap: () => abrir(context, MateriaisScreen(avaliacaoId: a.id))),
          const SectionHeading('Correção e resultados'),
          SurfaceCard(
              color: AppColors.softPurple,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      const Icon(Icons.document_scanner_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text('Uma folha por vez.',
                              style: Theme.of(context).textTheme.titleMedium))
                    ]),
                    const SizedBox(height: 10),
                    Text(
                        '$corrigidas de $alunos alunos com resultado nesta sessão.',
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                            value: alunos == 0
                                ? 0
                                : (corrigidas / alunos).clamp(0, 1),
                            minHeight: 5,
                            backgroundColor: Colors.white,
                            color: AppColors.primary)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        onPressed: () => abrir(
                            context,
                            pronto
                                ? CapturaScreen(avaliacaoId: a.id)
                                : GabaritoScreen(avaliacaoId: a.id)),
                        icon: Icon(
                            pronto
                                ? Icons.document_scanner_outlined
                                : Icons.edit_note_rounded,
                            size: 20),
                        label: Text(pronto
                            ? 'Ler folha de respostas'
                            : 'Definir gabarito primeiro'))
                  ])),
          const SizedBox(height: 12),
          ActionTile(
              icon: Icons.bar_chart_rounded,
              title: 'Resultados da turma',
              subtitle: corrigidas == 0
                  ? 'Consulte os resultados depois da primeira leitura.'
                  : 'Notas, respostas e análise por questão.',
              tint: AppColors.softPurple,
              onTap: () => abrir(context, ResultadosScreen(avaliacaoId: a.id))),
          if (corrigidas > 0 && a.status != StatusAvaliacao.concluida)
            TextButton.icon(
                onPressed: () async {
                  if (await confirmar(context, 'Concluir avaliação?',
                      '$corrigidas de $alunos alunos foram corrigidos. Você poderá continuar lendo folhas depois.',
                      action: 'Concluir')) {
                    if (!context.mounted) return;
                    store.concluir(a.id);
                    avisar(context, 'Avaliação concluída nesta sessão.');
                  }
                },
                icon: const Icon(Icons.task_alt_rounded),
                label: const Text('Marcar avaliação como concluída')),
        ]));
  }
}
