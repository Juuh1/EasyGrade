import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class UsuarioFormData {
  final String nome;
  final String email;
  final String instituicao;

  const UsuarioFormData({
    required this.nome,
    required this.email,
    required this.instituicao,
  });
}

class EditarUsuarioScreen extends StatefulWidget {
  final UsuarioFormData dadosIniciais;

  const EditarUsuarioScreen({
    super.key,
    required this.dadosIniciais,
  });

  @override
  State<EditarUsuarioScreen> createState() => _EditarUsuarioScreenState();
}

class _EditarUsuarioScreenState extends State<EditarUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _instituicaoController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.dadosIniciais.nome);
    _emailController = TextEditingController(text: widget.dadosIniciais.email);
    _instituicaoController =
        TextEditingController(text: widget.dadosIniciais.instituicao);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _instituicaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      UsuarioFormData(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        instituicao: _instituicaoController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar usuário'),
        leading: const BackButton(),
      ),
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
                    'Atualize seus dados',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'As alterações ficam disponíveis apenas nesta sessão enquanto o backend não estiver conectado.',
                    style:
                        TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _nomeController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: _campoObrigatorio,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: _validarEmail,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _instituicaoController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Instituição de ensino',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    validator: _campoObrigatorio,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.check),
                    label: const Text('Salvar alterações'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _campoObrigatorio(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preencha este campo.';
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preencha este campo.';
    final emailValido =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return emailValido ? null : 'Informe um e-mail válido.';
  }
}
