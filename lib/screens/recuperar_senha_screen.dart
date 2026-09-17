import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RecuperarSenhaScreen extends StatefulWidget {
  const RecuperarSenhaScreen({super.key});

  @override
  State<RecuperarSenhaScreen> createState() => _RecuperarSenhaScreenState();
}

class _RecuperarSenhaScreenState extends State<RecuperarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _enviado = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Recuperar senha'), leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxContentWidth,
            ),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Icon(Icons.mark_email_read_outlined,
                    color: AppColors.primary, size: 64),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _enviado ? 'Confira seu e-mail' : 'Esqueceu sua senha?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _enviado
                      ? 'Enviamos as instruções de recuperação para ${_emailController.text.trim()}.'
                      : 'Informe o e-mail cadastrado para receber as instruções de recuperação.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (!_enviado)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined)),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'Informe seu e-mail.';
                            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(value.trim())
                                ? null
                                : 'Informe um e-mail válido.';
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                            onPressed: _enviar,
                            child: const Text('Enviar instruções')),
                      ],
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Voltar para o login'),
                  ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'A recuperação está simulada localmente e será conectada ao serviço de autenticação posteriormente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
