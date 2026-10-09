import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/avaliacao_card.dart';
import 'criar_avaliacao_screen.dart';
import 'detalhes_avaliacao_screen.dart';
import 'apoio_screens.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onNavigateTab;
  const HomePage({super.key, required this.onNavigateTab});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final total = store.avaliacoes
        .fold<int>(0, (n, a) => n + store.correcoes(a.id).length);
    return AppPage(
        root: true,
        title: 'Início',
        actions: [
          IconButton(
              tooltip: 'Como funciona',
              onPressed: () => abrir(context, const AjudaScreen()),
              icon: const Icon(Icons.help_outline_rounded, size: 22)),
          IconButton(
              tooltip: 'Meu perfil',
              onPressed: () => onNavigateTab(3),
              icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.lavender,
                  child: Text(
                      store.nome.isEmpty ? 'P' : store.nome[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark))))
        ],
        child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
            children: [
              PageHeading(title: 'Olá, ${store.nome.split(' ').first}.'),
              Container(
                  decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(26)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(children: [
                    Positioned(
                        right: -30,
                        top: -25,
                        child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.darkBorder, width: 1)))),
                    Positioned(
                        right: -8,
                        top: -6,
                        child: Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.darkBorder, width: 1)))),
                    Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Corrigir pode\nser mais simples.',
                                  style: TextStyle(
                                      fontSize: 29,
                                      height: 1.23,
                                      letterSpacing: -.9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              const SizedBox(height: 12),
                              const Text(
                                  'Leia as respostas. Revise as marcações.\nAcompanhe cada conquista.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      height: 1.7,
                                      color: AppColors.onDarkSecondary)),
                              const SizedBox(height: 24),
                              SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.lavender,
                                          foregroundColor:
                                              AppColors.primaryDark),
                                      onPressed: () => onNavigateTab(2),
                                      icon: const Icon(
                                          Icons.document_scanner_outlined,
                                          size: 20),
                                      label: const Text('Iniciar correção')))
                            ])),
                  ])),
              const SizedBox(height: 16),
              Row(children: [
                Metric('${store.avaliacoes.length}', 'avaliações na sessão'),
                const SizedBox(width: 12),
                Metric('$total', 'folhas corrigidas',
                    color: AppColors.softPurple)
              ]),
              const SectionHeading('Prepare sua próxima avaliação'),
              ActionTile(
                  icon: Icons.add_rounded,
                  title: 'Criar avaliação',
                  subtitle: 'Defina a turma, as questões e o gabarito.',
                  onTap: () => abrir(context, const CriarAvaliacaoScreen())),
              Row(children: [
                Expanded(
                    child: _Shortcut(
                        icon: Icons.groups_outlined,
                        label: 'Turmas e alunos',
                        onTap: () => abrir(context, const TurmasScreen()))),
                const SizedBox(width: 12),
                Expanded(
                    child: _Shortcut(
                        icon: Icons.library_books_outlined,
                        label: 'Banco de questões',
                        onTap: () => abrir(context, const QuestoesScreen())))
              ]),
              SectionHeading('Avaliações recentes',
                  action: 'Ver todas', onAction: () => onNavigateTab(1)),
              if (store.avaliacoes.isEmpty)
                const EmptyState(
                    title: 'Nenhuma avaliação cadastrada',
                    subtitle: 'Crie uma avaliação para começar.',
                    icon: Icons.assignment_outlined)
              else
                ...store.avaliacoes.take(3).map((a) => AvaliacaoCard(
                    avaliacao: a,
                    onTap: () => abrir(
                        context, DetalhesAvaliacaoScreen(avaliacaoId: a.id)))),
              const SizedBox(height: 12),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.science_outlined,
                    size: 13, color: AppColors.textMuted),
                SizedBox(width: 6),
                Text('N1 · ambiente de demonstração',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted))
              ]),
            ]));
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Shortcut(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border)),
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
                    Text(label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))
                  ]))));
}
