import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class LayoutProvaScreen extends StatefulWidget {
  final String avaliacaoId;
  const LayoutProvaScreen({super.key, required this.avaliacaoId});
  @override
  State<LayoutProvaScreen> createState() => _LayoutProvaScreenState();
}

class _LayoutProvaScreenState extends State<LayoutProvaScreen> {
  List<int>? _paginas;
  bool _salvando = false;
  @override
  Widget build(BuildContext _) {
    final store = SessionScope.of(context);
    final a = store.avaliacao(widget.avaliacaoId),
        questoes = store.questoes(a.id);
    _paginas ??= [...store.paginas(a.id)];
    final paginasUsadas = _paginas!.toSet().toList()..sort();
    return AppPage(
        title: 'Organizar páginas',
        bottom: ElevatedButton(
            onPressed: _salvando
                ? null
                : () async {
                    setState(() => _salvando = true);
                    try {
                      await store.salvarPaginas(a.id, _paginas!);
                      if (!mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        avisar(
                            context, 'Não foi possível salvar a organização.');
                      }
                    } finally {
                      if (mounted) setState(() => _salvando = false);
                    }
                  },
            child: const Text('Salvar organização')),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(
              title: 'Organizar páginas',
              subtitle:
                  'Mova a questão inteira para outra página. O enunciado e as alternativas permanecem no mesmo bloco.'),
          const InfoBanner(
              'A organização será aplicada aos cadernos PDF e Word. Blocos que não couberem passam para a próxima página.'),
          const SectionHeading('Distribuição inicial'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final n in [1, 2, 3])
              OutlinedButton(
                  onPressed: () => setState(() =>
                      _paginas = List.generate(a.numQuestoes, (q) => q ~/ n)),
                  child: Text(
                      '$n ${n == 1 ? 'questão' : 'questões'} por página',
                      style: const TextStyle(fontSize: 11)))
          ]),
          const SizedBox(height: 24),
          for (final page in paginasUsadas) ...[
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  const Icon(Icons.description_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Eyebrow('Página ${page + 1} · Versão A')
                ])),
            SurfaceCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  for (final q in List.generate(a.numQuestoes, (q) => q)
                      .where((q) => _paginas![q] == page))
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(14)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Questão ${(q + 1).toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 8),
                                  Text(
                                      q < questoes.length
                                          ? questoes[q].enunciado
                                          : 'Enunciado ainda não adicionado ao caderno.',
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 8),
                                  if (q < questoes.length)
                                    ...questoes[q].alternativas.indexed.map(
                                        (alt) => Text(
                                            '${String.fromCharCode(65 + alt.$1)}) ${alt.$2}',
                                            style: const TextStyle(
                                                fontSize: 10, height: 1.8)))
                                  else
                                    Text(
                                        '${a.numAlternativas} alternativas · bloco reservado',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textMuted)),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    const Expanded(
                                        child: Text('Mover bloco inteiro',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted))),
                                    IconButton(
                                        tooltip:
                                            'Mover questão ${q + 1} para a página anterior',
                                        onPressed: page == 0
                                            ? null
                                            : () => setState(
                                                () => _paginas![q] = page - 1),
                                        icon: const Icon(
                                            Icons.keyboard_arrow_up_rounded,
                                            size: 22)),
                                    IconButton(
                                        tooltip:
                                            'Mover questão ${q + 1} para a próxima página',
                                        onPressed: page >= a.numQuestoes - 1
                                            ? null
                                            : () => setState(
                                                () => _paginas![q] = page + 1),
                                        icon: const Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            size: 22))
                                  ]),
                                ]))),
                ])),
            const SizedBox(height: 24),
          ],
        ]));
  }
}
