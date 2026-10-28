import '../data/auth_service.dart';
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
                    child: Text(
                        store.nome.isEmpty ? '?' : store.nome[0].toUpperCase(),
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
              subtitle: 'Nome e instituição.',
              onTap: () => abrir(context, const EditarUsuarioScreen())),
          ActionTile(
              icon: Icons.lock_outline_rounded,
              title: 'Alterar senha',
              subtitle: 'Atualize sua senha de acesso.',
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
              child: Text('EasyGrade · versão 1.0.0',
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
  bool _loaded = false, _salvando = false;
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
  Widget build(BuildContext _) => AppPage(
      title: 'Editar perfil',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Editar perfil',
            subtitle: 'Mantenha seu nome e sua instituição atualizados.'),
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
                  readOnly: true,
                  decoration: const InputDecoration(
                      labelText: 'E-mail da conta',
                      helperText: 'Vinculado ao seu método de acesso.'),
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
            onPressed: _salvando
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    final store = SessionScope.of(context);
                    setState(() => _salvando = true);
                    try {
                      await store.salvarPerfil(_nome.text, _instituicao.text);
                      if (!mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (mounted) {
                        avisar(context,
                            'Não foi possível salvar o perfil. Confira a conexão.');
                      }
                    } finally {
                      if (mounted) setState(() => _salvando = false);
                    }
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
  final _senha = TextEditingController(), _atual = TextEditingController();
  bool _salvando = false;
  @override
  void dispose() {
    _senha.dispose();
    _atual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext _) => AppPage(
      title: 'Alterar senha',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(
            title: 'Alterar senha',
            subtitle: 'Confirme sua senha atual para definir uma nova senha.'),
        Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                  controller: _atual,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Senha atual'),
                  validator: obrigatorio),
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
            'Se você acessa pelo Google, a senha é gerenciada na sua conta Google. Para recuperar um acesso por senha, use a recuperação na tela de login.'),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: _salvando
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    final auth = SessionScope.of(context).autenticacao;
                    if (auth == null || !auth.usaSenha) {
                      avisar(context,
                          'A senha deste acesso é gerenciada na conta Google.');
                      return;
                    }
                    setState(() => _salvando = true);
                    try {
                      await auth.alterarSenha(_atual.text, _senha.text);
                      if (!mounted) return;
                      Navigator.pop(context);
                      avisar(context, 'Senha alterada.');
                    } catch (e) {
                      if (mounted) avisar(context, mensagemAutenticacao(e));
                    } finally {
                      if (mounted) setState(() => _salvando = false);
                    }
                  },
            child: Text(_salvando ? 'Salvando…' : 'Alterar senha'))
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
                  onChanged: (v) async {
                    try {
                      await store.salvarMovimento(v);
                    } catch (e) {
                      if (context.mounted) {
                        avisar(
                            context, 'Não foi possível salvar a preferência.');
                      }
                    }
                  })),
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
                    'Aplicativo acadêmico para preparar e corrigir avaliações objetivas em papel, com revisão das marcações e análise dos resultados.',
                    style: TextStyle(fontSize: 12)),
                SizedBox(height: 20),
                Eyebrow('Versão 1.0.0'),
                SizedBox(height: 12),
                InfoBanner(
                    'Seus dados são privados e vinculados à sua conta. A leitura usa as folhas identificadas geradas pelo EasyGrade e exige revisão antes de confirmar o resultado.')
              ]))
        ]));
  }
}
