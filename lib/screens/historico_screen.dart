import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/filtro_avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/avaliacao_card.dart';
import '../widgets/filtros_bottom_sheet.dart';
import 'criar_avaliacao_screen.dart';
import 'detalhes_avaliacao_screen.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});
  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _busca = TextEditingController();
  FiltroAvaliacao _filtro = FiltroAvaliacao.vazio;
  StatusAvaliacao? _status;
  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final query = _busca.text.trim().toLowerCase();
    final lista = store.avaliacoes.where((a) {
      final dia = a.data == null
          ? null
          : DateTime(a.data!.year, a.data!.month, a.data!.day);
      return ('${a.nome} ${a.disciplina} ${a.turma} ${a.codigo}'
              .toLowerCase()
              .contains(query)) &&
          (_status == null || _status == a.status) &&
          (_filtro.status.isEmpty || _filtro.status.contains(a.status)) &&
          (_filtro.disciplina == null || _filtro.disciplina == a.disciplina) &&
          (_filtro.turma == null || _filtro.turma == a.turma) &&
          (_filtro.periodoDe == null ||
              (dia != null && !dia.isBefore(_filtro.periodoDe!))) &&
          (_filtro.periodoAte == null ||
              (dia != null && !dia.isAfter(_filtro.periodoAte!)));
    }).toList();
    return AppPage(
        title: 'Avaliações',
        root: true,
        actions: [
          IconButton(
              tooltip: 'Nova avaliação',
              onPressed: () => abrir(context, const CriarAvaliacaoScreen()),
              icon: const Icon(Icons.add_rounded))
        ],
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(title: 'Avaliações'),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _busca,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                        hintText: 'Buscar avaliação, disciplina ou turma',
                        prefixIcon: const Icon(Icons.search_rounded, size: 21),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () => setState(() => _busca.clear()),
                                icon: const Icon(Icons.close_rounded,
                                    size: 18))))),
            const SizedBox(width: 10),
            Badge(
                isLabelVisible: _filtro.quantidadeFiltrosAtivos > 0,
                label: Text('${_filtro.quantidadeFiltrosAtivos}'),
                child: IconButton.filledTonal(
                    tooltip: 'Filtros',
                    onPressed: () async {
                      final novo = await showFiltrosBottomSheet(context,
                          filtroAtual: _filtro);
                      if (mounted && novo != null) {
                        setState(() => _filtro = novo);
                      }
                    },
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.softPurple,
                        fixedSize: const Size(52, 52)),
                    icon: const Icon(Icons.tune_rounded,
                        color: AppColors.primaryDark)))
          ]),
          const SizedBox(height: 16),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: _status == null,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _status = null))),
                ...StatusAvaliacao.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                        label: Text(s.label),
                        selected: _status == s,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _status = s))))
              ])),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
                child: Text(
                    '${lista.length} avaliaç${lista.length == 1 ? 'ão' : 'ões'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary))),
            if (_filtro.temFiltroAvancadoAtivo ||
                _status != null ||
                query.isNotEmpty)
              TextButton(
                  onPressed: () => setState(() {
                        _filtro = FiltroAvaliacao.vazio;
                        _status = null;
                        _busca.clear();
                      }),
                  child: const Text('Limpar filtros'))
          ]),
          const SizedBox(height: 10),
          if (lista.isEmpty)
            EmptyState(
                title: 'Nenhuma avaliação encontrada',
                subtitle: 'Ajuste a busca ou crie uma nova avaliação.',
                action: OutlinedButton(
                    onPressed: () =>
                        abrir(context, const CriarAvaliacaoScreen()),
                    child: const Text('Criar avaliação')))
          else
            ...lista.map((a) => AvaliacaoCard(
                avaliacao: a,
                onTap: () => abrir(
                    context, DetalhesAvaliacaoScreen(avaliacaoId: a.id)))),
        ]));
  }
}
