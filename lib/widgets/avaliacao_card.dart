import 'package:flutter/material.dart';
import '../models/avaliacao.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

class AvaliacaoCard extends StatelessWidget {
  final Avaliacao avaliacao;
  final VoidCallback onTap;
  const AvaliacaoCard(
      {super.key, required this.avaliacao, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: AppColors.border)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: AppColors.softPurple,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.assignment_outlined,
                                  color: AppColors.primary, size: 18)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(avaliacao.disciplina,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary))),
                          StatusBadge(status: avaliacao.status)
                        ]),
                        const SizedBox(height: 16),
                        Text(avaliacao.nome,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3)),
                        const SizedBox(height: 6),
                        Text(
                            '${avaliacao.turma}  ·  ${avaliacao.numQuestoes} questões',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 7),
                          Expanded(
                              child: Text(avaliacao.dataLabelCurta,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted))),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppColors.primary)
                        ]),
                      ])))));
}
