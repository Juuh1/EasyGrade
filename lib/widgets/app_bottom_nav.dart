import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const AppBottomNav(
      {super.key, required this.currentIndex, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border))),
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                  children: List.generate(4, (i) {
                const labels = ['Início', 'Avaliações', 'Leitura', 'Perfil'];
                const icons = [
                  Icons.grid_view_rounded,
                  Icons.assignment_outlined,
                  Icons.document_scanner_outlined,
                  Icons.person_outline_rounded
                ];
                final active = i == currentIndex;
                return Expanded(
                    child: Semantics(
                        selected: active,
                        button: true,
                        child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => onTap(i),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 7),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: active
                                                  ? AppColors.lavender
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          child: Icon(icons[i],
                                              size: 22,
                                              color: active
                                                  ? AppColors.primaryDark
                                                  : AppColors.textMuted)),
                                      const SizedBox(height: 4),
                                      Text(labels[i],
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: active
                                                  ? FontWeight.w800
                                                  : FontWeight.w500,
                                              color: active
                                                  ? AppColors.primaryDark
                                                  : AppColors.textMuted))
                                    ])))));
              })))));
}
