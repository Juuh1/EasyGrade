import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'auth_screens.dart';
import 'apoio_screens.dart';
import 'splash_screen.dart';

class PerfilScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const PerfilScreen({super.key, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    return AppPage(
        title: 'Perfil',
        root: true,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(title: 'Meu perfil'),
          SurfaceCard(
              color: AppColors.softPurple,
              child: Row(children: [
                CircleAvatar(
                    radius: 31,
                    backgroundColor: AppColors.lavender,
                    child: Text(store.nome[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w800))),
                const SizedBox(width: 18),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(store.nome,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(store.email, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(store.instituicao,
                          style: const TextStyle(fontSize: 11))
                    ]))
              ])),
          const SectionHeading('Sua conta'),
          ActionTile(
              icon: Icons.edit_outlined,
              title: 'Editar perfil',
              subtitle: 'Nome, e-mail e instituição.',
              onTap: () => abrir(context, const EditarUsuarioScreen())),
          ActionTile(
              icon: Icons.lock_outline_rounded,
              title: 'Alterar senha',
              subtitle: 'Veja o fluxo de atualização de acesso.',
              onTap: () => abrir(context, const AlterarSenhaScreen())),
          const SectionHeading('Preferências e ajuda'),
          ActionTile(
              icon: Icons.tune_rounded,
              title: 'Configurações',
              subtitle: 'Movimento, abertura e informações do app.',
              onTap: () => abrir(context, const ConfiguracoesScreen())),
          ActionTile(
              icon: Icons.help_outline_rounded,
              title: 'Como funciona',
              subtitle: 'Conheça o caminho da prova física ao resultado.',
              onTap: () => abrir(context, const AjudaScreen())),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text('Sair da conta')),
          const SizedBox(height: 20),
          const Center(
              child: Text('EasyGrade · N1 · versão 0.2.0',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)))
        ]));
  }
}

class EditarUsuarioScreen extends StatefulWidget {
  const EditarUsuarioScreen({super.key});
  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(),
      _email = TextEditingController(),
      _instituicao = TextEditingController();
  bool _loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final store = SessionScope.of(context);
      _nome.text = store.nome;
      _email.text = store.email;
      _instituicao.text = store.instituicao;
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _instituicao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Editar perfil',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Editar perfil',
            subtitle: 'As alterações aparecem em todas as telas nesta sessão.'),
        Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: obrigatorio),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: validarEmail),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _instituicao,
                  decoration: const InputDecoration(labelText: 'Instituição'),
                  validator: obrigatorio)
            ])),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              SessionScope.of(context).atualizarPerfil(_nome.text.trim(),
                  _email.text.trim(), _instituicao.text.trim());
              Navigator.pop(context);
              avisar(context, 'Perfil atualizado nesta sessão.');
            },
            child: const Text('Salvar alterações'))
      ]));
}

class AlterarSenhaScreen extends StatefulWidget {
  const AlterarSenhaScreen({super.key});
  @override
  State<AlterarSenhaScreen> createState() => _AlterarSenhaScreenState();
}

class _AlterarSenhaScreenState extends State<AlterarSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _senha = TextEditingController();
  @override
  void dispose() {
    _senha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Alterar senha',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Alterar senha',
            subtitle: 'Experimente a validação de uma nova senha.'),
        Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Senha atual de demonstração'),
                  validator: (v) =>
                      v != 'User' ? 'A senha de demonstração é User.' : null),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _senha,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Nova senha'),
                  validator: (v) => (v?.length ?? 0) < 6
                      ? 'Use pelo menos 6 caracteres.'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar nova senha'),
                  validator: (v) =>
                      v != _senha.text ? 'As senhas devem ser iguais.' : null)
            ])),
        const SizedBox(height: 20),
        const InfoBanner(
            'A mudança de senha é simulada. Para entrar novamente na N1, use User / User.'),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              Navigator.pop(context);
              avisar(context,
                  'Fluxo de alteração validado. A senha de acesso continua User.');
            },
            child: const Text('Simular alteração de senha'))
      ]));
}

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    return AppPage(
        title: 'Configurações',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(title: 'Configurações'),
          SurfaceCard(
              child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reduzir movimento',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  subtitle: const Text(
                      'Pule a animação de abertura. A preferência de acessibilidade do aparelho também é respeitada.',
                      style: TextStyle(fontSize: 12)),
                  value: store.reduzirMovimento,
                  onChanged: store.movimento)),
          const SizedBox(height: 16),
          ActionTile(
              icon: Icons.play_circle_outline_rounded,
              title: 'Rever animação de abertura',
              subtitle: 'Uma folha de respostas se transforma na marca.',
              onTap: () => abrir(context,
                  SplashScreen(onComplete: () => Navigator.pop(context)))),
          const SectionHeading('Sobre o EasyGrade'),
          const SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Brand(size: 34),
                SizedBox(height: 20),
                Text(
                    'Protótipo acadêmico de correção de avaliações objetivas em papel. Preparação, leitura demonstrativa e análise pedagógica em um só fluxo.',
                    style: TextStyle(fontSize: 12)),
                SizedBox(height: 20),
                Eyebrow('N1 · Versão 0.2.0'),
                SizedBox(height: 12),
                InfoBanner(
                    'Dados locais de demonstração, sem persistência. A integração com banco de dados pertence à N2 e não está presente nesta versão.')
              ]))
        ]));
  }
}
