import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  bool _mostrarSenha = false;
  bool _aceitouTermos = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _cadastrar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para criar sua conta.')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cadastro concluído'),
        content:
            const Text('Sua conta foi criada localmente nesta demonstração.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Criar conta'), leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(
                    'Crie sua conta',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Preencha seus dados para começar a organizar suas avaliações.',
                    style:
                        TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _nomeController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: _obrigatorio,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined)),
                    validator: _validarEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_mostrarSenha,
                    textInputAction: TextInputAction.next,
                    decoration: _decoracaoSenha('Senha'),
                    validator: _validarSenha,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: !_mostrarSenha,
                    textInputAction: TextInputAction.done,
                    decoration: _decoracaoSenha('Confirmar senha'),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Confirme sua senha.';
                      if (value != _senhaController.text)
                        return 'As senhas não conferem.';
                      return null;
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _aceitouTermos,
                    onChanged: (value) =>
                        setState(() => _aceitouTermos = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                        'Concordo com os termos de uso e a política de privacidade.'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                      onPressed: _cadastrar, child: const Text('Criar conta')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoracaoSenha(String label) {
    return InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
        icon: Icon(_mostrarSenha
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined),
        onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
      ),
    );
  }

  String? _obrigatorio(String? value) =>
      value == null || value.trim().isEmpty ? 'Preencha este campo.' : null;

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu e-mail.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
        ? null
        : 'Informe um e-mail válido.';
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) return 'Informe uma senha.';
    return value.length < 6
        ? 'A senha deve ter pelo menos 6 caracteres.'
        : null;
  }
}
