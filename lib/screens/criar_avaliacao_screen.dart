import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/avaliacao.dart';
import '../models/status_avaliacao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
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
  bool _salvando = false;
  int _limite = 1000;
  List<int?> _pesos = List.filled(10, null);
  bool get _edicao => widget.avaliacaoId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _limite = SessionScope.of(context).pontuacaoPadrao;
      if (_edicao) {
        final a = SessionScope.of(context).avaliacaoOuNull(widget.avaliacaoId!);
        if (a != null) {
          _temCorrecoes = SessionScope.of(context).correcoes(a.id).isNotEmpty;
          _nome.text = a.nome;
          _disciplina.text = a.disciplina;
          _turma = a.turma;
          _data = a.data;
          _alternativas = a.numAlternativas;
          _quantidade.text = '${a.numQuestoes}';
          _limite = a.limitePontos;
          _pesos = List.generate(
            a.numQuestoes,
            (i) => i < a.pesos.length ? a.pesos[i] : null,
          );
          if (a.data != null) _hora = TimeOfDay.fromDateTime(a.data!);
        }
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
      confirmText: 'Selecionar',
    );
    if (!mounted || date == null) return;
    setState(() => _data = date);
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate() || _salvando) return;
    final store = SessionScope.of(context);
    final stamp = DateTime.now().microsecondsSinceEpoch.toString();
    final old = _edicao ? store.avaliacaoOuNull(widget.avaliacaoId!) : null;
    final a = Avaliacao(
      id: old?.id ?? stamp,
      codigo: old?.codigo ?? 'EG-${stamp.substring(stamp.length - 6)}',
      nome: _nome.text.trim(),
      disciplina: _disciplina.text.trim(),
      turma: _turma!,
      data: _data == null
          ? null
          : DateTime(
              _data!.year,
              _data!.month,
              _data!.day,
              _hora.hour,
              _hora.minute,
            ),
      numQuestoes: int.parse(_quantidade.text),
      numAlternativas: _alternativas,
      status: old?.status ?? StatusAvaliacao.rascunho,
      limitePontos: _limite,
      pesos:
          _temCorrecoes ||
              (old != null &&
                  old.pesos.isEmpty &&
                  _pesos.every((p) => p == null))
          ? old!.pesos
          : List.unmodifiable(_pesos),
    );

    try {
      a.validarPontuacao();
    } on ArgumentError catch (erro) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confira a pontuação da avaliação'),
          content: Text(erro.message.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Revisar pesos'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _salvando = true);
    try {
      await store.salvar(a);
      if (!mounted) return;
      if (_edicao) {
        Navigator.pop(context);
        avisar(context, 'Avaliação atualizada.');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SucessoAvaliacaoScreen(avaliacaoId: a.id),
          ),
        );
      }
    } catch (erro) {
      if (mounted) {
        avisar(
          context,
          'Não foi possível salvar a avaliação: ${mensagemErro(erro)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  Future<void> _editarPeso(int indice, int automatico) async {
    if (_salvando || _temCorrecoes) return;
    const minimo = Avaliacao.pesoMinimo;
    final maximo = _limite.clamp(minimo, 300);
    var peso = (_pesos[indice] ?? automatico).clamp(minimo, maximo);
    final escolha = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => AlertDialog(
          title: Text('Peso da questão ${indice + 1}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${formatarPontos(peso)} ponto(s)'),
              Slider(
                min: minimo.toDouble(),
                max: maximo.toDouble(),
                divisions: maximo - minimo,
                value: peso.toDouble(),
                label: formatarPontos(peso),
                onChanged: (v) => atualizar(() => peso = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Usar automático'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, peso),
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
    if (mounted && escolha != null) {
      setState(() => _pesos[indice] = escolha == 0 ? null : escolha);
    }
  }

  Widget _cartaoPontuacao() {
    final automaticos = Avaliacao.distribuir(_limite, _pesos.length);
    final total = Iterable<int>.generate(
      _pesos.length,
      (i) => _pesos[i] ?? automaticos[i],
    ).fold(0, (a, b) => a + b);
    return SurfaceCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: true,
        title: const Text('Pesos das questões'),
        subtitle: Text(
          '${formatarPontos(total)} de ${formatarPontos(_limite)} pontos',
        ),
        children: [
          if (_temCorrecoes)
            const Text('Os pesos ficam fixos após a primeira correção.')
          else
            const Text('Toque em uma questão para ajustar seu peso.'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _pesos.length; i++)
                  ActionChip(
                    label: Text(
                      'Q${i + 1} · ${formatarPontos(_pesos[i] ?? automaticos[i])}',
                    ),
                    tooltip: 'Peso da questão ${i + 1}',
                    onPressed: _salvando || _temCorrecoes
                        ? null
                        : () => _editarPeso(i, automaticos[i]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext _) => AppPage(
    title: _edicao ? 'Editar avaliação' : 'Nova avaliação',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          title: _edicao ? 'Editar avaliação' : 'Nova avaliação',
          subtitle:
              'Comece pelos detalhes. Depois, prepare o gabarito e as folhas de resposta.',
        ),
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
                      enabled: !_salvando,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Fundamentos de software',
                      ),
                      validator: obrigatorio,
                    ),
                    const FormLabel('Disciplina'),
                    TextFormField(
                      controller: _disciplina,
                      enabled: !_salvando,
                      decoration: const InputDecoration(
                        hintText: 'Ex.: Engenharia de Software',
                      ),
                      validator: obrigatorio,
                    ),
                    const FormLabel('Turma'),
                    DropdownButtonFormField<String>(
                      initialValue: _turma,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: 'Selecione uma turma',
                        helperText: _temCorrecoes
                            ? 'Turma preservada após a primeira correção.'
                            : null,
                      ),
                      items:
                          {
                                ...SessionScope.of(context).turmas,
                                if (_turma != null) _turma!,
                              }
                              .toList()
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: _temCorrecoes || _salvando
                          ? null
                          : (v) => setState(() => _turma = v),
                      validator: (v) =>
                          v == null ? 'Selecione uma turma.' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Eyebrow('Formato da folha'),
                    const FormLabel('Quantidade de questões'),
                    TextFormField(
                      controller: _quantidade,
                      enabled: !_edicao && !_salvando,
                      onChanged: (valor) {
                        final n = int.tryParse(valor);
                        if (n == null ||
                            n < 1 ||
                            n > 60 ||
                            n == _pesos.length) {
                          return;
                        }
                        setState(() {
                          final anteriores = _pesos;
                          _pesos = List.generate(
                            n,
                            (i) => i < anteriores.length ? anteriores[i] : null,
                          );
                        });
                      },
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'De 1 a 60',
                        suffixText: 'questões',
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 1 || n > 60
                            ? 'Informe de 1 a 60 questões.'
                            : null;
                      },
                    ),
                    const FormLabel('Alternativas por questão'),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final n in [2, 3, 4, 5])
                          ChoiceChip(
                            label: Text('$n'),
                            selected: _alternativas == n,
                            showCheckmark: false,
                            onSelected: _edicao || _salvando
                                ? null
                                : (_) => setState(() => _alternativas = n),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _edicao
                          ? 'O formato é preservado para manter o gabarito e as correções consistentes.'
                          : 'Todas as questões usam o mesmo número de alternativas.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _cartaoPontuacao(),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Eyebrow('Planejamento · opcional'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _salvando ? null : _selecionarData,
                      icon: const Icon(Icons.calendar_month_outlined, size: 20),
                      label: Text(
                        _data == null
                            ? 'Escolher data'
                            : '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}',
                      ),
                    ),
                    if (_data != null) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _salvando
                            ? null
                            : () async {
                                final hora = await showTimePicker(
                                  context: context,
                                  initialTime: _hora,
                                  builder: (c, child) => MediaQuery(
                                    data: MediaQuery.of(
                                      c,
                                    ).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  ),
                                );
                                if (mounted && hora != null) {
                                  setState(() => _hora = hora);
                                }
                              },
                        icon: const Icon(Icons.schedule_rounded, size: 20),
                        label: Text(
                          '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: _salvando
                            ? null
                            : () => setState(() => _data = null),
                        child: const Text('Remover data'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_edicao ? 'Salvar alterações' : 'Criar avaliação'),
              ),
              const SizedBox(height: 12),
              const InfoBanner(
                'As informações da avaliação são salvas com segurança no Firebase Firestore.',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SucessoAvaliacaoScreen extends StatelessWidget {
  final String avaliacaoId;
  const SucessoAvaliacaoScreen({super.key, required this.avaliacaoId});
  @override
  Widget build(BuildContext context) {
    final a = SessionScope.of(context).avaliacaoOuNull(avaliacaoId);
    if (a == null) {
      return const AppPage(
        title: 'Avaliação criada',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AppPage(
      title: 'Avaliação criada',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 20),
          const EmptyState(
            title: 'Avaliação criada',
            subtitle: 'Defina o gabarito de referência para a correção.',
            icon: Icons.check_rounded,
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Sua avaliação'),
                const SizedBox(height: 12),
                Text(a.nome, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('${a.disciplina}\n${a.turma} · ${a.numQuestoes} questões'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GabaritoScreen(
                  avaliacaoId: a.id,
                  abrirDetalhesAoSalvar: true,
                ),
              ),
            ),
            child: const Text('Preparar gabarito'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DetalhesAvaliacaoScreen(avaliacaoId: a.id),
              ),
            ),
            child: const Text('Ver avaliação'),
          ),
        ],
      ),
    );
  }
}
