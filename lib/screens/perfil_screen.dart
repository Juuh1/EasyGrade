import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/avatar_perfil.dart';
import 'apoio_screens.dart';

class PerfilScreen extends StatelessWidget {
  final VoidCallback onLogout;
  final String? fotoPerfilUrl;
  const PerfilScreen({super.key, required this.onLogout, this.fotoPerfilUrl});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    return AppPage(
      title: 'Perfil',
      root: true,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(title: 'Meu perfil'),
          SurfaceCard(
            color: AppColors.softPurple,
            child: Row(
              children: [
                AvatarPerfil(
                  radius: 31,
                  nome: store.nome,
                  fotoUrl: fotoPerfilUrl,
                  fontSize: 24,
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.nome,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(store.email, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        store.instituicao,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeading('Sua conta'),
          ActionTile(
            icon: Icons.edit_outlined,
            title: 'Editar perfil',
            subtitle: 'Nome e instituição.',
            onTap: () => abrir(context, const EditarUsuarioScreen()),
          ),
          const SectionHeading('Preferências e ajuda'),
          ActionTile(
            icon: Icons.tune_rounded,
            title: 'Configurações',
            subtitle: 'Pontuação padrão e informações do aplicativo.',
            onTap: () => abrir(context, const ConfiguracoesScreen()),
          ),
          ActionTile(
            icon: Icons.help_outline_rounded,
            title: 'Como funciona',
            subtitle: 'Conheça o caminho da prova física ao resultado.',
            onTap: () => abrir(context, const AjudaScreen()),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Sair da conta'),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'EasyGrade · versão 1.0.0',
              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
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
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeading(
          title: 'Editar perfil',
          subtitle: 'Mantenha seu nome e sua instituição atualizados.',
        ),
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: obrigatorio,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'E-mail da conta',
                  helperText: 'Vinculado à sua conta EasyGrade.',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instituicao,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Instituição (opcional)',
                ),
              ),
            ],
          ),
        ),
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
                      avisar(
                        context,
                        'Não foi possível salvar o perfil. Confira a conexão.',
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _salvando = false);
                  }
                },
          child: const Text('Salvar alterações'),
        ),
      ],
    ),
  );
}

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  Future<void> _editarLimite(BuildContext context, SessionStore store) async {
    final form = GlobalKey<FormState>();
    var valor = formatarPontos(store.pontuacaoPadrao);
    int? pontos() {
      final numero = double.tryParse(valor.trim().replaceAll(',', '.'));
      if (numero == null || !numero.isFinite || numero < 1 || numero > 10) {
        return null;
      }
      return (numero * 100).round();
    }

    final escolhido = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pontuação padrão'),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: valor,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Pontos'),
            onChanged: (v) => valor = v,
            validator: (_) =>
                pontos() == null ? 'Informe um valor de 1 a 10.' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, pontos());
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (escolhido == null || !context.mounted) return;
    try {
      await store.salvarPontuacaoPadrao(escolhido);
    } catch (_) {
      if (context.mounted) {
        avisar(context, 'Não foi possível salvar a pontuação padrão.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    return AppPage(
      title: 'Configurações',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(title: 'Configurações'),
          ActionTile(
            icon: Icons.grade_outlined,
            title: 'Pontuação padrão',
            subtitle:
                '${formatarPontos(store.pontuacaoPadrao)} pontos para novas avaliações neste dispositivo.',
            onTap: () => _editarLimite(context, store),
          ),
          const SectionHeading('Sobre o EasyGrade'),
          const SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Brand(size: 34),
                SizedBox(height: 20),
                Text(
                  'Aplicativo acadêmico para preparar e corrigir avaliações objetivas em papel, com revisão das marcações e análise dos resultados.',
                  style: TextStyle(fontSize: 12),
                ),
                SizedBox(height: 20),
                Eyebrow('Versão 1.0.0'),
                SizedBox(height: 12),
                InfoBanner(
                  'Seus dados são privados e vinculados à sua conta. A leitura usa as folhas identificadas geradas pelo EasyGrade e exige revisão antes de confirmar o resultado.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
