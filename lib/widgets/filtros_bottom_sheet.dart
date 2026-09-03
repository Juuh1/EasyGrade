import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/mock_data.dart';
import '../models/filtro_avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';

// Modal de filtros
Future<FiltroAvaliacao?> showFiltrosBottomSheet(
  BuildContext context, {
  required FiltroAvaliacao filtroAtual,
}) {
  return showModalBottomSheet<FiltroAvaliacao>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FiltrosBottomSheet(filtroInicial: filtroAtual),
  );
}

class _FiltrosBottomSheet extends StatefulWidget {
  final FiltroAvaliacao filtroInicial;
  const _FiltrosBottomSheet({required this.filtroInicial});

  @override
  State<_FiltrosBottomSheet> createState() => _FiltrosBottomSheetState();
}

class _FiltrosBottomSheetState extends State<_FiltrosBottomSheet> {
  late Set<StatusAvaliacao> _status;
  String? _disciplina;
  String? _turma;
  DateTime? _periodoDe;
  DateTime? _periodoAte;

  final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _status = {...widget.filtroInicial.status};
    _disciplina = widget.filtroInicial.disciplina;
    _turma = widget.filtroInicial.turma;
    _periodoDe = widget.filtroInicial.periodoDe;
    _periodoAte = widget.filtroInicial.periodoAte;
  }

  void _limparFiltros() {
    setState(() {
      _status = {};
      _disciplina = null;
      _turma = null;
      _periodoDe = null;
      _periodoAte = null;
    });
  }

  void _aplicarFiltros() {
    Navigator.of(context).pop(
      widget.filtroInicial.copyWith(
        status: _status,
        disciplina: _disciplina,
        limparDisciplina: _disciplina == null,
        turma: _turma,
        limparTurma: _turma == null,
        periodoDe: _periodoDe,
        limparPeriodoDe: _periodoDe == null,
        periodoAte: _periodoAte,
        limparPeriodoAte: _periodoAte == null,
      ),
    );
  }

  Future<void> _selecionarData({required bool inicio}) async {
    final agora = DateTime.now();
    final selecionada = await showDatePicker(
      context: context,
      initialDate: (inicio ? _periodoDe : _periodoAte) ?? agora,
      firstDate: DateTime(agora.year - 2),
      lastDate: DateTime(agora.year + 2),
    );
    if (selecionada == null) return;
    setState(() {
      if (inicio) {
        _periodoDe = selecionada;
      } else {
        _periodoAte = selecionada;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;
    final isWide = mediaQuery.size.width >= AppBreakpoints.compact;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide
                    ? AppBreakpoints.maxContentWidth + 40
                    : double.infinity,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom: mediaQuery.viewInsets.bottom + AppSpacing.lg,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      const Text(
                        'Filtros',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('Status'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: StatusAvaliacao.values.map((s) {
                          final selecionado = _status.contains(s);
                          return FilterChip(
                            label: Text(s.label),
                            selected: selecionado,
                            showCheckmark: false,
                            selectedColor: AppColors.pillActiveBg,
                            backgroundColor: AppColors.surface,
                            side: BorderSide(
                              color: selecionado
                                  ? AppColors.primary
                                  : AppColors.inputBorder,
                            ),
                            labelStyle: TextStyle(
                              color: selecionado
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (v) => setState(() {
                              v ? _status.add(s) : _status.remove(s);
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('Disciplina'),
                      const SizedBox(height: 8),
                      _Dropdown<String>(
                        value: _disciplina,
                        hint: 'Todas as disciplinas',
                        items: MockData.disciplinas,
                        onChanged: (v) => setState(() => _disciplina = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('Turma'),
                      const SizedBox(height: 8),
                      _Dropdown<String>(
                        value: _turma,
                        hint: 'Todas as turmas',
                        items: MockData.turmas,
                        onChanged: (v) => setState(() => _turma = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('Período'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _DateField(
                              label: 'De',
                              value: _periodoDe,
                              formatter: _dateFormat,
                              onTap: () => _selecionarData(inicio: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateField(
                              label: 'Até',
                              value: _periodoAte,
                              formatter: _dateFormat,
                              onTap: () => _selecionarData(inicio: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _limparFiltros,
                              child: const Text('Limpar filtros'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _aplicarFiltros,
                              child: const Text('Aplicar filtros'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint, style: const TextStyle(color: AppColors.textMuted)),
      icon:
          const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
      decoration: const InputDecoration(),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text('$item'),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Text(
              value == null ? 'DD/MM/AAAA' : formatter.format(value!),
              style: TextStyle(
                color:
                    value == null ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
