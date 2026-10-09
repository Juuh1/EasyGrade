import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import 'auth_screens.dart';
import 'detalhes_avaliacao_screen.dart';
import 'gabarito_screen.dart';

class CriarAvaliacaoScreen extends StatefulWidget {
  final String? avaliacaoId;
  const CriarAvaliacaoScreen({super.key, this.avaliacaoId});
  @override
  State<CriarAvaliacaoScreen> createState() => _CriarAvaliacaoScreenState();
}

class _CriarAvaliacaoScreenState extends State<CriarAvaliacaoScreen> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController(),
      _disciplina = TextEditingController(),
      _quantidade = TextEditingController(text: '10');
  String? _turma;
  DateTime? _data;
  TimeOfDay _hora = const TimeOfDay(hour: 8, minute: 0);
  int _alternativas = 5;
  bool _loaded = false;
  bool _temCorrecoes = false;
  bool get _edicao => widget.avaliacaoId != null;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      if (_edicao) {
        final a = SessionScope.of(context).avaliacao(widget.avaliacaoId!);
        _temCorrecoes = SessionScope.of(context).correcoes(a.id).isNotEmpty;
        _nome.text = a.nome;
        _disciplina.text = a.disciplina;
        _turma = a.turma;
        _data = a.data;
        _alternativas = a.numAlternativas;
        _quantidade.text = '${a.numQuestoes}';
        if (a.data != null) _hora = TimeOfDay.fromDateTime(a.data!);
      }
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _disciplina.dispose();
    _quantidade.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final initial = _data ?? DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040),
        helpText: 'Data da avaliação',
        cancelText: 'Cancelar',
        confirmText: 'Selecionar');
    if (!mounted || date == null) return;
    setState(() => _data = date);
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final store = SessionScope.of(context);
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final old = _edicao ? store.avaliacao(widget.avaliacaoId!) : null;
    final a = Avaliacao(
        id: old?.id ?? stamp,
        codigo: old?.codigo ?? 'EG-${stamp.substring(stamp.length - 6)}',
        nome: _nome.text.trim(),
        disciplina: _disciplina.text.trim(),
        turma: _turma!,
        data: _data == null
            ? null
            : DateTime(_data!.year, _data!.month, _data!.day, _hora.hour,
                _hora.minute),
        numQuestoes: int.parse(_quantidade.text),
        numAlternativas: _alternativas,
        status: old?.status ?? StatusAvaliacao.rascunho);
    store.salvar(a);
    if (_edicao) {
      Navigator.pop(context);
      avisar(context, 'Avaliação atualizada nesta sessão.');
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => SucessoAvaliacaoScreen(avaliacaoId: a.id)));
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: _edicao ? 'Editar avaliação' : 'Nova avaliação',
      child: ListView(padding: const EdgeInsets.all(24), children: [
        PageHeading(
            title: _edicao ? 'Editar avaliação' : 'Nova avaliação',
            subtitle:
                'Comece pelos detalhes. Depois, prepare o gabarito e as folhas de resposta.'),
        Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SurfaceCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const Eyebrow('Informações básicas'),
                        const FormLabel('Nome da avaliação'),
                        TextFormField(
                            controller: _nome,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                hintText: 'Ex.: Fundamentos de software'),
                            validator: obrigatorio),
                        const FormLabel('Disciplina'),
                        TextFormField(
                            controller: _disciplina,
                            decoration: const InputDecoration(
                                hintText: 'Ex.: Engenharia de Software'),
                            validator: obrigatorio),
                        const FormLabel('Turma'),
                        DropdownButtonFormField<String>(
                            initialValue: _turma,
                            isExpanded: true,
                            decoration: InputDecoration(
                                hintText: 'Selecione uma turma',
                                helperText: _temCorrecoes
                                    ? 'Turma preservada após a primeira correção.'
                                    : null),
                            items: SessionScope.of(context)
                                .turmas
                                .map((t) =>
                                    DropdownMenuItem(value: t, child: Text(t)))
                                .toList(),
                            onChanged: _temCorrecoes
                                ? null
                                : (v) => setState(() => _turma = v),
                            validator: (v) =>
                                v == null ? 'Selecione uma turma.' : null)
                      ])),
                  const SizedBox(height: 16),
                  SurfaceCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const Eyebrow('Formato da folha'),
                        const FormLabel('Quantidade de questões'),
                        TextFormField(
                            controller: _quantidade,
                            enabled: !_edicao,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                hintText: 'De 1 a 60', suffixText: 'questões'),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              return n == null || n < 1 || n > 60
                                  ? 'Informe de 1 a 60 questões.'
                                  : null;
                            }),
                        const FormLabel('Alternativas por questão'),
                        Wrap(spacing: 8, children: [
                          for (final n in [2, 3, 4, 5])
                            ChoiceChip(
                                label: Text('$n'),
                                selected: _alternativas == n,
                                showCheckmark: false,
                                onSelected: _edicao
                                    ? null
                                    : (_) => setState(() => _alternativas = n))
                        ]),
                        const SizedBox(height: 12),
                        Text(
                            _edicao
                                ? 'O formato é preservado para manter o gabarito e as correções consistentes.'
                                : 'Todas as questões usam o mesmo número de alternativas.',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textMuted))
                      ])),
                  const SizedBox(height: 16),
                  SurfaceCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        const Eyebrow('Planejamento · opcional'),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                            onPressed: _selecionarData,
                            icon: const Icon(Icons.calendar_month_outlined,
                                size: 20),
                            label: Text(_data == null
                                ? 'Escolher data'
                                : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}')),
                        if (_data != null) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                              onPressed: () async {
                                final hora = await showTimePicker(
                                    context: context,
                                    initialTime: _hora,
                                    builder: (c, child) => MediaQuery(
                                        data: MediaQuery.of(c).copyWith(
                                            alwaysUse24HourFormat: true),
                                        child: child!));
                                if (mounted && hora != null) {
                                  setState(() => _hora = hora);
                                }
                              },
                              icon:
                                  const Icon(Icons.schedule_rounded, size: 20),
                              label: Text(
                                  '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}')),
                          TextButton(
                              onPressed: () => setState(() => _data = null),
                              child: const Text('Remover data'))
                        ]
                      ])),
                  const SizedBox(height: 24),
                  ElevatedButton(
                      onPressed: _salvar,
                      child: Text(
                          _edicao ? 'Salvar alterações' : 'Criar avaliação')),
                  const SizedBox(height: 12),
                  const InfoBanner(
                      'As informações ficam disponíveis apenas durante esta sessão de demonstração.'),
                ])),
      ]));
}

class SucessoAvaliacaoScreen extends StatelessWidget {
  final String avaliacaoId;
  const SucessoAvaliacaoScreen({super.key, required this.avaliacaoId});
  @override
  Widget build(BuildContext context) {
    final a = SessionScope.of(context).avaliacao(avaliacaoId);
    return AppPage(
        title: 'Avaliação criada',
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 20),
          const EmptyState(
              title: 'Avaliação criada',
              subtitle: 'Defina o gabarito de referência para a correção.',
              icon: Icons.check_rounded),
          SurfaceCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Eyebrow('Sua avaliação'),
                const SizedBox(height: 12),
                Text(a.nome, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${a.disciplina}\n${a.turma} · ${a.numQuestoes} questões')
              ])),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GabaritoScreen(
                          avaliacaoId: a.id, abrirDetalhesAoSalvar: true))),
              child: const Text('Preparar gabarito')),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DetalhesAvaliacaoScreen(avaliacaoId: a.id))),
              child: const Text('Ver avaliação'))
        ]));
  }
}
