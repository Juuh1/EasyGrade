import 'package:flutter/material.dart';
import 'package:n1_avaliacoes_app/models/status_avaliacao.dart';
import '../models/avaliacao.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Card interativo de uma avaliação, exibido na lista do Histórico.
///
/// - Toque em qualquer lugar do card -> abre a tela de Detalhes.
/// - Toque no link de ação (ex.: "Ver resultados") -> mesma navegação,
///   mas destacado visualmente como CTA (call to action) principal.
/// - Toque no "..." -> abre um menu rápido de ações secundárias.
class AvaliacaoCard extends StatelessWidget {
  final Avaliacao avaliacao;
  final VoidCallback onTap;
  final VoidCallback onAcaoPrincipal;
  final void Function(String acao)? onMenuAcao;

  const AvaliacaoCard({
    super.key,
    required this.avaliacao,
    required this.onTap,
    required this.onAcaoPrincipal,
    this.onMenuAcao,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      avaliacao.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: avaliacao.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                avaliacao.dataLabelCurta,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Text(
                avaliacao.subtitulo,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onAcaoPrincipal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          avaliacao.status.acaoPrincipal,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz,
                        color: AppColors.textSecondary),
                    onSelected: onMenuAcao,
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'duplicar', child: Text('Duplicar')),
                      PopupMenuItem(value: 'arquivar', child: Text('Arquivar')),
                      PopupMenuItem(
                        value: 'excluir',
                        child: Text('Excluir',
                            style: TextStyle(color: AppColors.dangerFg)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
