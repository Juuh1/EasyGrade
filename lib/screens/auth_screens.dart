import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../data/session_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final AuthService? authService;
  const LoginScreen({super.key, required this.onLogin, this.authService});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _user = TextEditingController(), _senha = TextEditingController();
  bool _obscure = true;
  bool _ocupado = false;
  String? _error;
  @override
  void dispose() {
    _user.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!_form.currentState!.validate()) return;
    if (widget.authService != null) {
      _autenticar(() => widget.authService!.entrar(_user.text, _senha.text));
      return;
    }
    if (_user.text.trim().toLowerCase() != 'user' || _senha.text != 'User') {
      setState(() => _error = 'Use o acesso de demonstração: User / User.');
      return;
    }
    widget.onLogin();
  }

  Future<void> _autenticar(Future<void> Function() operacao) async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await operacao();
      if (mounted) widget.onLogin();
    } catch (erro) {
      if (mounted) setState(() => _error = mensagemAutenticacao(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
                  children: [
            const Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 10,
                children: [Brand(size: 32), Eyebrow('Para professores')]),
            const SizedBox(height: 40),
            Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(28)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Corrigir pode\nser mais simples.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                                color: AppColors.lavender,
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.document_scanner_outlined,
                                color: AppColors.primaryDark)),
                        const SizedBox(width: 13),
                        const Expanded(
                            child: Text(
                                'Prepare avaliações, leia gabaritos\ne confira os resultados.',
                                style: TextStyle(
                                    color: AppColors.onDarkSecondary,
                                    fontSize: 12,
                                    height: 1.7)))
                      ]),
                    ])),
            const SizedBox(height: 32),
            Text('Bem-vindo de volta.',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text('Entre para organizar suas avaliações.'),
            Form(
                key: _form,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FormLabel(
                          widget.authService == null ? 'Usuário' : 'E-mail'),
                      TextFormField(
                          controller: _user,
                          textInputAction: TextInputAction.next,
                          keyboardType: widget.authService == null
                              ? TextInputType.text
                              : TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                              hintText: widget.authService == null
                                  ? 'Seu usuário'
                                  : 'Seu e-mail',
                              prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  size: 20)),
                          validator: widget.authService == null
                              ? obrigatorio
                              : validarEmail),
                      const FormLabel('Senha'),
                      TextFormField(
                          controller: _senha,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                              hintText: 'Sua senha',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  size: 20),
                              suffixIcon: IconButton(
                                  tooltip: _obscure
                                      ? 'Mostrar senha'
                                      : 'Ocultar senha',
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20))),
                          validator: obrigatorio),
                      Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: _ocupado
                                  ? null
                                  : () => abrir(
                                      context,
                                      RecuperarSenhaScreen(
                                          authService: widget.authService)),
                              child: const Text('Esqueci minha senha',
                                  style: TextStyle(fontSize: 12)))),
                      if (_error != null) ...[
                        InfoBanner(_error!, warning: true),
                        const SizedBox(height: 12)
                      ],
                      ElevatedButton(
                          onPressed: _ocupado ? null : _entrar,
                          child: _ocupado
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Text('Entrar'),
                                      SizedBox(width: 10),
                                      Icon(Icons.arrow_forward_rounded,
                                          size: 18)
                                    ])),
                    ])),
            const SizedBox(height: 16),
            if (widget.authService != null) ...[
              OutlinedButton(
                  onPressed: _ocupado
                      ? null
                      : () => _autenticar(widget.authService!.entrarComGoogle),
                  child: const Text('Continuar com Google')),
              const SizedBox(height: 12),
            ] else
              const InfoBanner(
                  'Acesso de demonstração: User / User. Os dados desta versão são fictícios.',
                  icon: Icons.science_outlined),
            const SizedBox(height: 12),
            TextButton(
                onPressed: _ocupado
                    ? null
                    : () => abrir(
                        context,
                        CadastroScreen(
                            onLogin: widget.onLogin,
                            authService: widget.authService)),
                child: const Text('Primeiro acesso? Criar conta')),
          ])));
}

String? obrigatorio(String? value) =>
    value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;
String? validarEmail(String? value) => value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Informe um e-mail válido.'
    : null;

class CadastroScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final AuthService? authService;
  const CadastroScreen({super.key, required this.onLogin, this.authService});
  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(),
      _email = TextEditingController(),
      _instituicao = TextEditingController(),
      _senha = TextEditingController();
  bool _termos = false, _obscure = true;
  bool _ocupado = false;
  String? _erro;
  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _instituicao.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_ocupado) return;
    if (!_form.currentState!.validate()) return;
    if (widget.authService != null) {
      setState(() {
        _ocupado = true;
        _erro = null;
      });
      try {
        await widget.authService!
            .cadastrar(_nome.text, _email.text, _senha.text, _instituicao.text);
        if (!mounted) return;
        Navigator.pop(context);
        widget.onLogin();
      } catch (erro) {
        if (mounted) setState(() => _erro = mensagemAutenticacao(erro));
      } finally {
        if (mounted) setState(() => _ocupado = false);
      }
      return;
    }
    if (!_termos) {
      avisar(context, 'Confirme que entendeu o acesso de demonstração.');
      return;
    }
    SessionScope.of(context).atualizarPerfil(
        _nome.text.trim(), _email.text.trim(), _instituicao.text.trim());
    Navigator.pop(context);
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Criar conta',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const PageHeading(title: 'Dados da conta'),
        Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                  controller: _nome,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: obrigatorio),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: validarEmail),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _instituicao,
                  decoration: const InputDecoration(labelText: 'Instituição'),
                  validator: obrigatorio),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _senha,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                      labelText: 'Senha',
                      suffixIcon: IconButton(
                          tooltip: 'Mostrar ou ocultar senha',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: const Icon(Icons.visibility_outlined))),
                  validator: (v) => (v?.length ?? 0) < 6
                      ? 'Use pelo menos 6 caracteres.'
                      : null),
              const SizedBox(height: 16),
              TextFormField(
                  obscureText: _obscure,
                  decoration:
                      const InputDecoration(labelText: 'Confirmar senha'),
                  validator: (v) =>
                      v != _senha.text ? 'As senhas devem ser iguais.' : null),
            ])),
        const SizedBox(height: 20),
        if (_erro != null) InfoBanner(_erro!, warning: true),
        if (widget.authService == null) ...[
          const InfoBanner(
              'Cadastro demonstrativo. Seu perfil fica disponível nesta sessão; a senha não é armazenada.'),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _termos,
              onChanged: (v) => setState(() => _termos = v!),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                  'Entendi que este é um protótipo com dados de demonstração.',
                  style: TextStyle(fontSize: 12))),
        ],
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: _ocupado ? null : _salvar,
            child: Text(_ocupado
                ? 'Criando conta…'
                : widget.authService == null
                    ? 'Criar conta de demonstração'
                    : 'Criar conta')),
      ]));
}

class RecuperarSenhaScreen extends StatefulWidget {
  final AuthService? authService;
  const RecuperarSenhaScreen({super.key, this.authService});
  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _enviado = false;
  bool _ocupado = false;
  String? _erro;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Recuperar acesso',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        PageHeading(
            title: _enviado ? 'Recuperação de acesso' : 'Esqueceu sua senha?',
            subtitle: _enviado
                ? widget.authService == null
                    ? 'Assim será a confirmação da recuperação de acesso.'
                    : 'Confira a caixa de entrada e o spam.'
                : 'Informe o e-mail associado à sua conta.'),
        if (_enviado) ...[
          EmptyState(
              title: widget.authService == null
                  ? 'Solicitação simulada'
                  : 'Solicitação recebida',
              subtitle: widget.authService == null
                  ? 'Nenhum e-mail foi enviado nesta versão.\nPara entrar na demonstração, use User / User.'
                  : 'Se houver uma conta com este e-mail, você receberá as instruções de recuperação.',
              icon: Icons.mark_email_read_outlined),
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar ao login'))
        ] else ...[
          Form(
              key: _form,
              child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline_rounded)),
                  validator: validarEmail)),
          const SizedBox(height: 24),
          if (_erro != null) InfoBanner(_erro!, warning: true),
          ElevatedButton(
              onPressed: _ocupado
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() {
                        _ocupado = true;
                        _erro = null;
                      });
                      try {
                        await widget.authService?.recuperarSenha(_email.text);
                        if (!mounted) return;
                        setState(() => _enviado = true);
                      } catch (erro) {
                        if (mounted) {
                          setState(() => _erro = mensagemAutenticacao(erro));
                        }
                      } finally {
                        if (mounted) setState(() => _ocupado = false);
                      }
                    },
              child: Text(_ocupado ? 'Enviando…' : 'Solicitar recuperação')),
          const SizedBox(height: 16),
          if (widget.authService == null)
            const InfoBanner(
                'Você está visualizando o fluxo demonstrativo de recuperação de senha.')
        ],
      ]));
}
