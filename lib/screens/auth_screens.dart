import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../data/auth_service.dart';
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
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _usuario = TextEditingController();
  final _nome = TextEditingController();
  final _instituicao = TextEditingController();
  bool _ocupado = false;
  bool _criando = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    _usuario.dispose();
    _nome.dispose();
    _instituicao.dispose();
    super.dispose();
  }

  Future<void> _autenticar(Future<void> Function(AuthService) acao) async {
    final auth = widget.authService;
    if (_ocupado || auth == null) return;
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await acao(auth);
      if (mounted) widget.onLogin();
    } catch (erro) {
      if (mounted) setState(() => _erro = mensagemAutenticacao(erro));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _enviar() {
    if (!_form.currentState!.validate()) return;
    _autenticar((auth) async {
      if (_criando) {
        await auth.cadastrar(
          email: _email.text,
          senha: _senha.text,
          usuario: _usuario.text,
          nome: _nome.text,
          instituicao: _instituicao.text,
        );
      } else {
        await auth.entrar(_email.text, _senha.text);
      }
      TextInput.finishAutofillContext();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 408),
            child: SurfaceCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Brand(size: 36),
                  ),
                  const SizedBox(height: 28),
                  PageHeading(
                    title: _criando ? 'Criar conta' : 'Acesso do professor',
                    subtitle: _criando
                        ? 'Informe seus dados para configurar o perfil.'
                        : '',
                  ),
                  if (_erro != null) ...[
                    InfoBanner(_erro!, warning: true),
                    const SizedBox(height: 12),
                  ],
                  AutofillGroup(
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          if (_criando) ...[
                            TextFormField(
                              controller: _usuario,
                              enabled: !_ocupado,
                              maxLength: 60,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nome de usuário',
                              ),
                              validator: obrigatorio,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _nome,
                              enabled: !_ocupado,
                              maxLength: 200,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Nome do professor',
                              ),
                              validator: obrigatorio,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _instituicao,
                              enabled: !_ocupado,
                              maxLength: 200,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Instituição (opcional)',
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            enabled: !_ocupado,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                            ),
                            validator: (v) =>
                                RegExp(
                                  r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                ).hasMatch(v?.trim() ?? '')
                                ? null
                                : 'Informe um e-mail válido.',
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _senha,
                            enabled: !_ocupado,
                            obscureText: true,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              _criando
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Senha',
                            ),
                            validator: (v) => _criando && (v?.length ?? 0) < 6
                                ? 'Use pelo menos 6 caracteres.'
                                : obrigatorio(v),
                            onFieldSubmitted: (_) {
                              if (!_ocupado && widget.authService != null) {
                                _enviar();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _ocupado || widget.authService == null
                        ? null
                        : _enviar,
                    child: Text(
                      _ocupado
                          ? 'Aguarde…'
                          : (_criando ? 'Criar conta' : 'Entrar'),
                    ),
                  ),
                  if (!_criando) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _ocupado || widget.authService == null
                          ? null
                          : () => _autenticar((auth) => auth.entrarComGoogle()),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff1f1f1f),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      icon: SvgPicture.asset(
                        'SVG/google-g.svg',
                        width: 18,
                        height: 18,
                      ),
                      label: const Text('Fazer login com o Google'),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => setState(() {
                            _criando = !_criando;
                            _erro = null;
                            _senha.clear();
                          }),
                    child: Text(
                      _criando ? 'Já tenho uma conta' : 'Criar conta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
