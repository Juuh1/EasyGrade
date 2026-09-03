import 'package:flutter/material.dart';

import '../models/avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class DetalhesAvaliacaoScreen extends StatelessWidget {
  final Avaliacao avaliacao;

  const DetalhesAvaliacaoScreen({super.key, required this.avaliacao});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppBreakpoints.compact;
    final horizontalPadding = isWide ? AppSpacing.xl : AppSpacing.md;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Avaliação')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? AppBreakpoints.maxContentWidth : double.infinity,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  horizontalPadding, AppSpacing.lg, horizontalPadding, AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CardInfoPrincipal(avaliacao: avaliacao),
                  const SizedBox(height: AppSpacing.md),
                  if (avaliacao.status == StatusAvaliacao.concluida &&
                      avaliacao.resultado != null) ...[
                    _CardResultados(avaliacao: avaliacao),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: () => _acaoMock(context, 'Exportar resultados'),
                      child: const Text('Exportar resultados'),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: () => _acaoMock(context, 'Aplicar avaliação'),
                      child: Text(avaliacao.status == StatusAvaliacao.agendada
                          ? 'Ver detalhes do agendamento'
                          : 'Continuar edição'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => _acaoMock(context, 'Editar avaliação'),
                    child: const Text('Editar avaliação'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _acaoMock(BuildContext context, String acao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$acao" (mock — sem efeito real na N1)')),
    );
  }
}

class _CardInfoPrincipal extends StatelessWidget {
  final Avaliacao avaliacao;
  const _CardInfoPrincipal({required this.avaliacao});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  avaliacao.nome,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: avaliacao.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Código: ${avaliacao.codigo}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _LinhaInfo(label: 'Disciplina', valor: avaliacao.disciplina),
          _LinhaInfo(label: 'Turma', valor: avaliacao.turma),
          _LinhaInfo(label: 'Data', valor: avaliacao.dataLabelCurta),
          _LinhaInfo(label: 'Questões', valor: '${avaliacao.numQuestoes} questões'),
          _LinhaInfo(
            label: 'Alternativas',
            valor: '${avaliacao.numAlternativas} por questão',
            ultima: true,
          ),
        ],
      ),
    );
  }
}

class _CardResultados extends StatelessWidget {
  final Avaliacao avaliacao;
  const _CardResultados({required this.avaliacao});

  @override
  Widget build(BuildContext context) {
    final r = avaliacao.resultado!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resultados obtidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          _LinhaInfo(label: 'Total de respostas', valor: '${r.totalRespostas} alunos'),
          _LinhaInfo(label: 'Média da turma', valor: r.mediaTurma.toStringAsFixed(1)),
          _LinhaInfo(label: 'Maior nota', valor: r.maiorNota.toStringAsFixed(1)),
          _LinhaInfo(
            label: 'Menor nota',
            valor: r.menorNota.toStringAsFixed(1),
            ultima: true,
          ),
        ],
      ),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final String label;
  final String valor;
  final bool ultima;

  const _LinhaInfo({
    required this.label,
    required this.valor,
    this.ultima = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultima ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
