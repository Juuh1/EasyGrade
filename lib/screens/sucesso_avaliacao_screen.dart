import 'package:flutter/material.dart';

import '../models/avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import 'detalhes_avaliacao_screen.dart';

// Tela de Sucesso da Avaliação
class SucessoAvaliacaoScreen extends StatelessWidget {
  final Avaliacao avaliacao;
  final ValueChanged<int>? onNavigateTab;

  const SucessoAvaliacaoScreen({
    super.key,
    required this.avaliacao,
    this.onNavigateTab,
  });

  void _voltarParaHome(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    onNavigateTab?.call(0);
  }

  void _verAvaliacao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalhesAvaliacaoScreen(avaliacao: avaliacao),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                'EasyGrade',
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
                        ? AppBreakpoints.maxContentWidth
                        : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.xl,
                      horizontalPadding,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),

                        // Ícone de confirmação
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.concluidaBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: const BoxDecoration(
                                  color: AppColors.concluidaFg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Título e subtítulo
                        const Text(
                          'Avaliação criada!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Tudo certo. A avaliação foi salva e já aparece no seu histórico.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Card de resumo
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: AppColors.deepNavy,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.deepNavy.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Faixa de cabeçalho em Deep Navy
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: AppColors.deepNavy,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.assignment_turned_in_outlined,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Resumo da avaliação',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        avaliacao.codigo,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Conteúdo das informações
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _LinhaResumo(
                                      rotulo: 'Nome',
                                      valor: avaliacao.nome,
                                    ),
                                    const SizedBox(height: 8),
                                    _LinhaResumo(
                                      rotulo: 'Turma',
                                      valor: avaliacao.turma,
                                    ),
                                    const SizedBox(height: 8),
                                    _LinhaResumo(
                                      rotulo: 'Formato',
                                      valor:
                                          '${avaliacao.numQuestoes} questões · ${avaliacao.numAlternativas} alternativas',
                                    ),
                                    if (avaliacao.data != null) ...[
                                      const SizedBox(height: 8),
                                      _LinhaResumo(
                                        rotulo: 'Data',
                                        valor: avaliacao.dataLabelCurta,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Botão primário: Voltar para a Home
                        ElevatedButton(
                          onPressed: () => _voltarParaHome(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Voltar para a Home',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Botão secundário: Ver avaliação
                        ElevatedButton.icon(
                          onPressed: () => _verAvaliacao(context),
                          icon: const Icon(
                            Icons.remove_red_eye_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Ver avaliação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.deepNavy,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          onNavigateTab?.call(index);
        },
      ),
    );
  }
}

// Linha de item de resumo
class _LinhaResumo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _LinhaResumo({
    required this.rotulo,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        children: [
          TextSpan(
            text: '$rotulo · ',
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(
            text: valor,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
