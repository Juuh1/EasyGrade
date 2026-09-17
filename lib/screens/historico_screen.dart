import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/avaliacao.dart';
import '../models/filtro_avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/avaliacao_card.dart';
import '../widgets/filtros_bottom_sheet.dart';
import 'detalhes_avaliacao_screen.dart';

// Filtros rápidos
enum _AbaRapida { todos, agendadas, concluidas }

class HistoricoScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const HistoricoScreen({super.key, this.onNavigateTab});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _buscaController = TextEditingController();

  _AbaRapida _abaRapida = _AbaRapida.todos;
  FiltroAvaliacao _filtro = FiltroAvaliacao.vazio;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  List<Avaliacao> get _avaliacoesFiltradas {
    final busca = _buscaController.text.trim().toLowerCase();

    return MockData.avaliacoes.where((a) {
      final bateBusca = busca.isEmpty ||
          a.nome.toLowerCase().contains(busca) ||
          a.disciplina.toLowerCase().contains(busca);

      final bateAbaRapida = switch (_abaRapida) {
        _AbaRapida.todos => true,
        _AbaRapida.agendadas => a.status == StatusAvaliacao.agendada,
        _AbaRapida.concluidas => a.status == StatusAvaliacao.concluida,
      };

      final bateStatusAvancado =
          _filtro.status.isEmpty || _filtro.status.contains(a.status);

      final bateDisciplina =
          _filtro.disciplina == null || a.disciplina == _filtro.disciplina;

      final bateTurma = _filtro.turma == null || a.turma == _filtro.turma;

      final bateData = _dataDentroDoPeriodo(a.data);

      return bateBusca &&
          bateAbaRapida &&
          bateStatusAvancado &&
          bateDisciplina &&
          bateTurma &&
          bateData;
    }).toList();
  }

  bool _dataDentroDoPeriodo(DateTime? data) {
    if (_filtro.periodoDe == null && _filtro.periodoAte == null) return true;
    if (data == null) return false;
    if (_filtro.periodoDe != null && data.isBefore(_filtro.periodoDe!)) {
      return false;
    }
    if (_filtro.periodoAte != null &&
        data.isAfter(_filtro.periodoAte!.add(const Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  Future<void> _abrirFiltros() async {
    final resultado = await showFiltrosBottomSheet(
      context,
      filtroAtual: _filtro,
    );
    if (resultado != null) {
      setState(() => _filtro = resultado);
    }
  }

  void _abrirDetalhes(Avaliacao avaliacao) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalhesAvaliacaoScreen(avaliacao: avaliacao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avaliacoes = _avaliacoesFiltradas;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppBreakpoints.compact;
    final horizontalPadding = isWide ? AppSpacing.xl : AppSpacing.md;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: const Text(
                'Histórico',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide
                        ? AppBreakpoints.maxContentWidth *
                            (width >= AppBreakpoints.medium ? 1.6 : 1.2)
                        : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Barra de busca e botão de filtros
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          AppSpacing.md,
                          horizontalPadding,
                          0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _buscaController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Buscar por avaliação',
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: AppColors.primary,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _FiltrosButton(
                              quantidadeAtiva: _filtro.quantidadeFiltrosAtivos,
                              onTap: _abrirFiltros,
                            ),
                          ],
                        ),
                      ),

                      // Filtros rápidos
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: AppSpacing.md,
                        ),
                        child: _AbaRapidaTabs(
                          selecionada: _abaRapida,
                          onSelect: (aba) => setState(() => _abaRapida = aba),
                        ),
                      ),

                      // Contagem e link de limpeza
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${avaliacoes.length} avaliaç${avaliacoes.length == 1 ? 'ão' : 'ões'}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_filtro.quantidadeFiltrosAtivos > 0)
                              InkWell(
                                onTap: () => setState(
                                    () => _filtro = FiltroAvaliacao.vazio),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.close,
                                          size: 14, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Limpar filtros',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Lista de avaliações
                      Expanded(
                        child: avaliacoes.isEmpty
                            ? const _EstadoVazio()
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  horizontalPadding,
                                  0,
                                  horizontalPadding,
                                  AppSpacing.lg,
                                ),
                                itemCount: avaliacoes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final avaliacao = avaliacoes[index];
                                  return AvaliacaoCard(
                                    avaliacao: avaliacao,
                                    onTap: () => _abrirDetalhes(avaliacao),
                                    onAcaoPrincipal: () =>
                                        _abrirDetalhes(avaliacao),
                                    onMenuAcao: (acao) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '$acao em "${avaliacao.nome}"'),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          if (widget.onNavigateTab != null) {
            widget.onNavigateTab!(i);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(i == 0 ? 'Home' : 'Criar'),
              ),
            );
          }
        },
      ),
    );
  }
}

// Botão de filtros
class _FiltrosButton extends StatelessWidget {
  final int quantidadeAtiva;
  final VoidCallback onTap;

  const _FiltrosButton({required this.quantidadeAtiva, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ativo = quantidadeAtiva > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: ativo
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: ativo ? AppColors.primary : AppColors.inputBorder,
            width: ativo ? 1.5 : 1.0,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Center(
              child: Icon(Icons.tune, color: AppColors.primary),
            ),
            if (ativo)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '$quantidadeAtiva',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Abas de filtro rápido
class _AbaRapidaTabs extends StatelessWidget {
  final _AbaRapida selecionada;
  final ValueChanged<_AbaRapida> onSelect;

  const _AbaRapidaTabs({required this.selecionada, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    Widget chip(_AbaRapida aba, String label) {
      final ativo = aba == selecionada;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: ativo,
          showCheckmark: false,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          side: BorderSide(
            color: ativo ? AppColors.primary : AppColors.inputBorder,
          ),
          labelStyle: TextStyle(
            color: ativo ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onSelected: (_) => onSelect(aba),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(_AbaRapida.todos, 'Todos'),
          chip(_AbaRapida.agendadas, 'Agendadas'),
          chip(_AbaRapida.concluidas, 'Concluídas'),
        ],
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(
              'Nenhuma avaliação encontrada',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Ajuste a busca ou os filtros aplicados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
