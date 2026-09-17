import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _notificacoesAtivas = true;
  bool _confirmarAntesDeExcluir = true;
  String _idioma = 'Português (Brasil)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            _SectionTitle(title: 'Preferências'),
            _SettingsCard(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _notificacoesAtivas,
                  onChanged: (value) =>
                      setState(() => _notificacoesAtivas = value),
                  secondary: const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Notificações'),
                  subtitle: const Text('Receber lembretes sobre avaliações'),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmarAntesDeExcluir,
                  onChanged: (value) =>
                      setState(() => _confirmarAntesDeExcluir = value),
                  secondary: const Icon(
                    Icons.delete_outline,
                    color: AppColors.primary,
                  ),
                  title: const Text('Confirmar exclusões'),
                  subtitle:
                      const Text('Pedir confirmação antes de remover dados'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.language_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Idioma'),
                  subtitle: Text(_idioma),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selecionarIdioma,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionTitle(title: 'Sobre o aplicativo'),
            _SettingsCard(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading:
                      Icon(Icons.school_outlined, color: AppColors.primary),
                  title: Text('EasyGrade',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle:
                      Text('Correção e organização de avaliações acadêmicas'),
                ),
                const Divider(height: 1),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                  ),
                  title: Text('Versão'),
                  trailing: Text('0.1.0',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Termos de uso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      _mostrarMensagem('Termos de uso disponíveis em breve.'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Política de privacidade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _mostrarMensagem(
                      'Política de privacidade disponível em breve.'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _mostrarMensagem(
                  'O suporte será conectado em uma próxima versão.'),
              icon: const Icon(Icons.help_outline),
              label: const Text('Falar com o suporte'),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'EasyGrade • Feito para facilitar sua rotina acadêmica',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selecionarIdioma() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Selecionar idioma',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            RadioListTile<String>(
              value: 'Português (Brasil)',
              groupValue: _idioma,
              title: const Text('Português (Brasil)'),
              onChanged: (value) {
                if (value != null) setState(() => _idioma = value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              value: 'English',
              groupValue: _idioma,
              title: const Text('English'),
              onChanged: (value) {
                if (value != null) setState(() => _idioma = value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(children: children),
      ),
    );
  }
}
