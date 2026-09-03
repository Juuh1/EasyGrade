import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../models/avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';

// Tela de Criação de Avaliação
class CriarAvaliacaoScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateTab;
  final ValueChanged<Avaliacao>? onAvaliacaoCriada;

  const CriarAvaliacaoScreen({
    super.key,
    this.onNavigateTab,
    this.onAvaliacaoCriada,
  });

  @override
  State<CriarAvaliacaoScreen> createState() => _CriarAvaliacaoScreenState();
}

class _CriarAvaliacaoScreenState extends State<CriarAvaliacaoScreen> {
  final _scrollController = ScrollController();

  // Controladores
  late final TextEditingController _nomeController;
  late final TextEditingController _disciplinaController;
  late final TextEditingController _dataController;
  late final TextEditingController _questoesController;

  // Estado dos campos
  String? _turmaSelecionada;
  int _numAlternativas = 5;
  DateTime? _dataSelecionada;

  // Validação
  bool _tentouSubmeter = false;
  bool _erroNome = false;
  bool _erroDisciplina = false;
  bool _erroTurma = false;
  bool _erroData = false;
  bool _erroQuestoes = false;

  final List<String> _opcoesTurmas = [
    '3ª fase A',
    '2ª fase B',
    '1ª fase A',
    '4ª fase B',
    '5ª fase A',
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: 'Prova N1 — Engenharia');
    _disciplinaController =
        TextEditingController(text: 'Engenharia de Software');
    _dataSelecionada = DateTime(2026, 9, 12, 19, 0);
    _dataController = TextEditingController(text: '12/09/2026');
    _questoesController = TextEditingController(text: '20');
    _turmaSelecionada = null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomeController.dispose();
    _disciplinaController.dispose();
    _dataController.dispose();
    _questoesController.dispose();
    super.dispose();
  }

  // Validação dos campos
  bool _validarFormulario() {
    final nomeInvalido = _nomeController.text.trim().isEmpty;
    final disciplinaInvalida = _disciplinaController.text.trim().isEmpty;
    final turmaInvalida =
        _turmaSelecionada == null || _turmaSelecionada!.trim().isEmpty;
    final dataInvalida = _dataController.text.trim().isEmpty;
    final questoesQtd = int.tryParse(_questoesController.text.trim()) ?? 0;
    final questoesInvalida = questoesQtd <= 0;

    setState(() {
      _tentouSubmeter = true;
      _erroNome = nomeInvalido;
      _erroDisciplina = disciplinaInvalida;
      _erroTurma = turmaInvalida;
      _erroData = dataInvalida;
      _erroQuestoes = questoesInvalida;
    });

    final temErro = nomeInvalido ||
        disciplinaInvalida ||
        turmaInvalida ||
        dataInvalida ||
        questoesInvalida;

    if (temErro) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      return false;
    }

    return true;
  }

  void _aoClicarCriar() {
    final valido = _validarFormulario();

    if (!valido) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Atenção: preencha os campos destacados antes de continuar.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.dangerFg,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final novaAvaliacao = Avaliacao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      codigo: 'EVAL-2026-N${MockData.avaliacoes.length + 1}',
      nome: _nomeController.text.trim(),
      disciplina: _disciplinaController.text.trim(),
      turma: _turmaSelecionada!,
      data: _dataSelecionada ?? DateTime.now(),
      numQuestoes: int.tryParse(_questoesController.text.trim()) ?? 20,
      numAlternativas: _numAlternativas,
      status: StatusAvaliacao.agendada,
    );

    MockData.avaliacoes.insert(0, novaAvaliacao);
    widget.onAvaliacaoCriada?.call(novaAvaliacao);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.concluidaFg,
          size: 48,
        ),
        title: const Text(
          'Avaliação Criada',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'A avaliação "${novaAvaliacao.nome}" foi cadastrada com sucesso.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Disciplina: ${novaAvaliacao.disciplina}'),
                  Text('• Turma: ${novaAvaliacao.turma}'),
                  Text(
                      '• Formato: ${novaAvaliacao.numQuestoes} questões (${novaAvaliacao.numAlternativas} alternativas)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada ?? hoje,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataEscolhida != null) {
      setState(() {
        _dataSelecionada = dataEscolhida;
        _dataController.text = DateFormat('dd/MM/yyyy').format(dataEscolhida);
        if (_tentouSubmeter) _erroData = false;
      });
    }
  }

  void _abrirSeletorTurma() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Selecione uma turma',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                ..._opcoesTurmas.map((turma) {
                  final selecionada = _turmaSelecionada == turma;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      turma,
                      style: TextStyle(
                        fontWeight:
                            selecionada ? FontWeight.w700 : FontWeight.w500,
                        color: selecionada
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: selecionada
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _turmaSelecionada = turma;
                        if (_tentouSubmeter) _erroTurma = false;
                      });
                      Navigator.of(ctx).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Preenchimento de exemplo
  void _preencherExemplo() {
    setState(() {
      _nomeController.text = 'Prova N1 — Engenharia';
      _disciplinaController.text = 'Engenharia de Software';
      _turmaSelecionada = null;
      _dataController.text = '12/09/2026';
      _questoesController.text = '20';
      _numAlternativas = 5;
      _tentouSubmeter = true;
      _erroNome = false;
      _erroDisciplina = false;
      _erroTurma = true;
      _erroData = false;
      _erroQuestoes = false;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= AppBreakpoints.compact;
    final horizontalPadding = isWide ? AppSpacing.xl : AppSpacing.md;

    final temAlgumErro = _tentouSubmeter &&
        (_erroNome ||
            _erroDisciplina ||
            _erroTurma ||
            _erroData ||
            _erroQuestoes);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Criar avaliação',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Preencher exemplo',
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _preencherExemplo,
                  ),
                ],
              ),
            ),

            // Formulário
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide
                        ? AppBreakpoints.maxContentWidth
                        : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.md,
                      horizontalPadding,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Seção
                        const Text(
                          'ETAPA ÚNICA · DADOS DA AVALIAÇÃO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Alerta de validação
                        if (temAlgumErro) ...[
                          _BannerAlertaValidacao(
                            mensagem: _erroTurma &&
                                    !_erroNome &&
                                    !_erroDisciplina &&
                                    !_erroData &&
                                    !_erroQuestoes
                                ? 'Revise o campo em vermelho antes de continuar.'
                                : 'Revise os campos em vermelho antes de continuar.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Campo 1: Nome da avaliação
                        _CampoTextoRotulado(
                          label: 'Nome da avaliação',
                          controller: _nomeController,
                          hintText: 'Digite um nome',
                          temErro: _erroNome,
                          mensagemErro: 'Este campo é obrigatório',
                          onChanged: (_) {
                            if (_erroNome) {
                              setState(() => _erroNome = false);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Campo 2: Disciplina
                        _CampoTextoRotulado(
                          label: 'Disciplina',
                          controller: _disciplinaController,
                          hintText: 'Engenharia de Software',
                          temErro: _erroDisciplina,
                          mensagemErro: 'Este campo é obrigatório',
                          onChanged: (_) {
                            if (_erroDisciplina) {
                              setState(() => _erroDisciplina = false);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Campo 3: Turma
                        _SeletorTurma(
                          label: 'Turma',
                          valorSelecionado: _turmaSelecionada,
                          temErro: _erroTurma,
                          mensagemErro: 'Este campo é obrigatório',
                          onTap: _abrirSeletorTurma,
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Linha com Data e Questões
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _CampoData(
                                label: 'Data',
                                controller: _dataController,
                                temErro: _erroData,
                                mensagemErro: 'Obrigatório',
                                onTap: _selecionarData,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 2,
                              child: _CampoNumero(
                                label: 'Questões',
                                controller: _questoesController,
                                temErro: _erroQuestoes,
                                mensagemErro: 'Inválido',
                                onChanged: (_) {
                                  if (_erroQuestoes) {
                                    setState(() => _erroQuestoes = false);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Alternativas por questão
                        const Text(
                          'Alternativas por questão',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _SeletorAlternativas(
                          valorSelecionado: _numAlternativas,
                          onSelect: (val) =>
                              setState(() => _numAlternativas = val),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Botão Criar avaliação
                        ElevatedButton(
                          onPressed: _aoClicarCriar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Criar avaliação',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (widget.onNavigateTab != null) {
            widget.onNavigateTab!(index);
          } else {
            if (index == 1) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(index == 0 ? 'Home' : 'Histórico'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}

// Banner de alerta
class _BannerAlertaValidacao extends StatelessWidget {
  final String mensagem;

  const _BannerAlertaValidacao({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0x33DC2626)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.dangerFg,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(
                color: AppColors.dangerFg,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Campo de texto
class _CampoTextoRotulado extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool temErro;
  final String mensagemErro;
  final ValueChanged<String>? onChanged;

  const _CampoTextoRotulado({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.temErro,
    required this.mensagemErro,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: temErro ? AppColors.dangerFg : AppColors.inputBorder,
                width: temErro ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: temErro ? AppColors.dangerFg : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 4),
          Text(
            mensagemErro,
            style: const TextStyle(
              color: AppColors.dangerFg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Seletor de turma
class _SeletorTurma extends StatelessWidget {
  final String label;
  final String? valorSelecionado;
  final bool temErro;
  final String mensagemErro;
  final VoidCallback onTap;

  const _SeletorTurma({
    required this.label,
    required this.valorSelecionado,
    required this.temErro,
    required this.mensagemErro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final temValor = valorSelecionado != null && valorSelecionado!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: temErro ? AppColors.dangerFg : AppColors.inputBorder,
                width: temErro ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  temValor ? valorSelecionado! : 'Selecione uma turma',
                  style: TextStyle(
                    fontSize: 15,
                    color: temErro
                        ? AppColors.dangerFg
                        : (temValor
                            ? AppColors.textPrimary
                            : AppColors.textMuted),
                    fontWeight: temErro ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color:
                      temErro ? AppColors.dangerFg : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 4),
          Text(
            mensagemErro,
            style: const TextStyle(
              color: AppColors.dangerFg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Campo de data
class _CampoData extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool temErro;
  final String mensagemErro;
  final VoidCallback onTap;

  const _CampoData({
    required this.label,
    required this.controller,
    required this.temErro,
    required this.mensagemErro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: temErro ? AppColors.dangerFg : AppColors.inputBorder,
                width: temErro ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'DD/MM/AAAA' : controller.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: controller.text.isEmpty
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 4),
          Text(
            mensagemErro,
            style: const TextStyle(
              color: AppColors.dangerFg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Campo numérico
class _CampoNumero extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool temErro;
  final String mensagemErro;
  final ValueChanged<String>? onChanged;

  const _CampoNumero({
    required this.label,
    required this.controller,
    required this.temErro,
    required this.mensagemErro,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: temErro ? AppColors.dangerFg : AppColors.inputBorder,
                width: temErro ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: temErro ? AppColors.dangerFg : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (temErro) ...[
          const SizedBox(height: 4),
          Text(
            mensagemErro,
            style: const TextStyle(
              color: AppColors.dangerFg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// Seletor de alternativas
class _SeletorAlternativas extends StatelessWidget {
  final int valorSelecionado;
  final ValueChanged<int> onSelect;

  const _SeletorAlternativas({
    required this.valorSelecionado,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [4, 5, 6].map((qtd) {
        final selecionado = qtd == valorSelecionado;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: qtd == 4 ? 0 : 6,
              right: qtd == 6 ? 0 : 6,
            ),
            child: InkWell(
              onTap: () => onSelect(qtd),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 44,
                decoration: BoxDecoration(
                  color: selecionado ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: selecionado
                        ? AppColors.primary
                        : AppColors.inputBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$qtd',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selecionado ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
