import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'configuracoes_screen.dart';
import 'editar_usuario_screen.dart';

class PerfilScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateTab;

  const PerfilScreen({super.key, required this.onNavigateTab});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _nome = 'User';
  String _email = 'user@easygrade.app';
  String _instituicao = 'Católica de Santa Catarina';

  Future<void> _editarUsuario() async {
    final dadosAtualizados = await Navigator.of(context).push<UsuarioFormData>(
      MaterialPageRoute(
        builder: (_) => EditarUsuarioScreen(
          dadosIniciais: UsuarioFormData(
            nome: _nome,
            email: _email,
            instituicao: _instituicao,
          ),
        ),
      ),
    );

    if (!mounted || dadosAtualizados == null) return;
    setState(() {
      _nome = dadosAtualizados.nome;
      _email = dadosAtualizados.email;
      _instituicao = dadosAtualizados.instituicao;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado localmente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu perfil'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              widget.onNavigateTab(0);
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _ProfileHeader(nome: _nome, email: _email),
            const SizedBox(height: AppSpacing.lg),
            _InfoCard(
              title: 'Dados do usuário',
              children: [
                _InfoRow(
                    icon: Icons.person_outline, label: 'Nome', value: _nome),
                const Divider(height: 24),
                _InfoRow(
                    icon: Icons.email_outlined, label: 'E-mail', value: _email),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Instituição',
                  value: _instituicao,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _editarUsuario,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar usuário'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Funcionalidade disponível sem backend.')),
              ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Alterar senha'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ConfiguracoesScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Sobre e configurações'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String nome;
  final String email;

  const _ProfileHeader({required this.nome, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: AppColors.pillActiveBg,
          child: Text(
            _iniciais(nome),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          nome,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(email, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  String _iniciais(String texto) {
    final partes = texto.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
