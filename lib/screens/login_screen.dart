import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'cadastro_screen.dart';
import 'recuperar_senha_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _usuarioTeste = 'User';
  static const _senhaTeste = 'User';

  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _mostrarSenha = false;
  bool _lembrarAcesso = false;

  @override
  void dispose() {
    _usuarioController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final usuarioValido = _usuarioController.text.trim() == _usuarioTeste;
    final senhaValida = _senhaController.text == _senhaTeste;

    if (!usuarioValido || !senhaValida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário ou senha inválidos.')),
      );
      return;
    }

    widget.onLogin();
  }

  Future<void> _abrirCadastro() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CadastroScreen()),
    );
  }

  Future<void> _abrirRecuperacao() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecuperarSenhaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.maxContentWidth,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Bem-vindo de volta',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Entre para continuar usando o EasyGrade.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _usuarioController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Informe seu usuário.'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: !_mostrarSenha,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip:
                              _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                          icon: Icon(_mostrarSenha
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _mostrarSenha = !_mostrarSenha),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe sua senha.';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: _lembrarAcesso,
                          onChanged: (value) =>
                              setState(() => _lembrarAcesso = value ?? false),
                        ),
                        const Expanded(child: Text('Lembrar meu acesso')),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: _abrirRecuperacao,
                          child: const Text('Esqueci a senha'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _entrar,
                      child: const Text('Entrar'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Ainda não tem uma conta?'),
                        TextButton(
                          onPressed: _abrirCadastro,
                          child: const Text('Cadastre-se'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.pillActiveBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'Acesso de teste',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Usuário: User  •  Senha: User',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Autenticação local para demonstração da N1.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
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
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.pillActiveBg,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(Icons.fact_check_outlined,
              color: AppColors.primary, size: 42),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'EasyGrade',
          style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
