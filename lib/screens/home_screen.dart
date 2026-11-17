import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/avatar_perfil.dart';
import '../widgets/avaliacao_card.dart';
import 'criar_avaliacao_screen.dart';
import 'detalhes_avaliacao_screen.dart';
import 'apoio_screens.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;
  final String? fotoPerfilUrl;
  const HomePage({super.key, required this.onNavigateTab, this.fotoPerfilUrl});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final total = store.avaliacoes.fold<int>(
      0,
      (n, a) => n + store.correcoes(a.id).length,
    );
    return AppPage(
      root: true,
      title: 'Início',
      actions: [
        IconButton(
          tooltip: 'Como funciona',
          onPressed: () => abrir(context, const AjudaScreen()),
          icon: const Icon(Icons.help_outline_rounded, size: 22),
        ),
        IconButton(
          tooltip: 'Meu perfil',
          onPressed: () => onNavigateTab(3),
          icon: AvatarPerfil(
            radius: 16,
            nome: store.nome,
            fotoUrl: fotoPerfilUrl,
            fontSize: 13,
          ),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        children: [
          PageHeading(title: 'Olá, ${store.nome.split(' ').first}.'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(26),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: IgnorePointer(
                    child: CustomPaint(painter: _ArteCorrecao()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 110, 24, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavender,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      onPressed: () => onNavigateTab(2),
                      icon: const Icon(
                        Icons.document_scanner_outlined,
                        size: 20,
                      ),
                      label: const Text('Iniciar correção'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Metric('${store.avaliacoes.length}', 'avaliações'),
              const SizedBox(width: 12),
              Metric(
                '$total',
                'folhas corrigidas',
                color: AppColors.softPurple,
              ),
            ],
          ),
          const SectionHeading('Preparação'),
          ActionTile(
            icon: Icons.add_rounded,
            title: 'Criar avaliação',
            subtitle: 'Defina a turma, as questões e o gabarito.',
            onTap: () => abrir(context, const CriarAvaliacaoScreen()),
          ),
          Row(
            children: [
              Expanded(
                child: _Shortcut(
                  icon: Icons.groups_outlined,
                  label: 'Turmas e alunos',
                  onTap: () => abrir(context, const TurmasScreen()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Shortcut(
                  icon: Icons.library_books_outlined,
                  label: 'Banco de questões',
                  onTap: () => abrir(context, const QuestoesScreen()),
                ),
              ),
            ],
          ),
          SectionHeading(
            'Avaliações recentes',
            action: 'Ver todas',
            onAction: () => onNavigateTab(1),
          ),
          if (store.avaliacoes.isEmpty)
            const EmptyState(
              title: 'Nenhuma avaliação cadastrada',
              subtitle: 'Crie uma avaliação para começar.',
              icon: Icons.assignment_outlined,
            )
          else
            ...store.avaliacoes
                .take(3)
                .map(
                  (a) => AvaliacaoCard(
                    avaliacao: a,
                    onTap: () => abrir(
                      context,
                      DetalhesAvaliacaoScreen(avaliacaoId: a.id),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ArteCorrecao extends CustomPainter {
  const _ArteCorrecao();

  @override
  void paint(Canvas canvas, Size size) {
    final passo = math.min(size.width / 4.4, 104.0);
    final raio = passo * .43;
    final margem = (size.width - 3 * passo) / 2;
    final contorno = Paint()
      ..color = AppColors.lavender.withValues(alpha: .54)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final preenchimento = Paint()..color = AppColors.primary;

    for (var i = 0; i < 4; i++) {
      final centro = Offset(margem + i * passo, raio * .40);
      canvas.drawCircle(centro, raio, i == 2 ? preenchimento : contorno);
    }
  }

  @override
  bool shouldRepaint(covariant _ArteCorrecao oldDelegate) => false;
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}
