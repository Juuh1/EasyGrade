import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/correcao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/avaliacao_card.dart';
import 'gabarito_screen.dart';
import 'preparacao_screens.dart';
import 'resultados_screen.dart';
import 'criar_avaliacao_screen.dart';

class SelecionarLeituraScreen extends StatelessWidget {
  const SelecionarLeituraScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    return AppPage(
        title: 'Leitura',
        root: true,
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const PageHeading(
              title: 'Leitura de provas',
              subtitle:
                  'Escolha a avaliação para identificar e ler as folhas de respostas da turma.'),
          SurfaceCard(
              color: AppColors.softPurple,
              child: Column(children: [
                for (final item in [
                  (
                    Icons.qr_code_2_rounded,
                    'Identifique',
                    'O QR Code vincula a folha à avaliação e ao aluno.'
                  ),
                  (
                    Icons.fact_check_outlined,
                    'Confira a referência',
                    'O gabarito define as respostas corretas.'
                  ),
                  (
                    Icons.document_scanner_outlined,
                    'Leia e revise',
                    'Uma folha por aluno; confirme as marcações incertas.'
                  )
                ])
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(item.$1, color: AppColors.primary, size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(item.$2,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(item.$3,
                                      style: const TextStyle(
                                          fontSize: 11, height: 1.7))
                                ]))
                          ]))
              ])),
          const SectionHeading('Qual avaliação vamos corrigir?'),
          if (store.avaliacoes.isEmpty)
            EmptyState(
                title: 'Comece por uma avaliação',
                subtitle:
                    'Crie a avaliação e seu gabarito para abrir a leitura.',
                action: ElevatedButton(
                    onPressed: () =>
                        abrir(context, const CriarAvaliacaoScreen()),
                    child: const Text('Criar avaliação')))
          else
            ...store.avaliacoes.map((a) => AvaliacaoCard(
                avaliacao: a,
                onTap: () => abrir(
                    context,
                    store.gabaritoPronto(a.id)
                        ? CapturaScreen(avaliacaoId: a.id)
                        : GabaritoScreen(
                            avaliacaoId: a.id, abrirDetalhesAoSalvar: true)))),
          const SizedBox(height: 12),
          const InfoBanner(
              'A câmera, a identificação por QR Code e o reconhecimento são simulados nesta versão.',
              icon: Icons.science_outlined),
        ]));
  }
}

class CapturaScreen extends StatefulWidget {
  final String avaliacaoId;
  final bool gabarito;
  const CapturaScreen(
      {super.key, required this.avaliacaoId, this.gabarito = false});
  @override
  State<CapturaScreen> createState() => _CapturaScreenState();
}

class _CapturaScreenState extends State<CapturaScreen> {
  String? _alunoId;
  bool _identificado = false, _processando = false;
  Future<void> _ler() async {
    final store = SessionScope.of(context);
    final a = store.avaliacao(widget.avaliacaoId);
    setState(() => _processando = true);
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    if (widget.gabarito) {
      Navigator.pop(context,
          List<int?>.generate(a.numQuestoes, (q) => q % a.numAlternativas));
      return;
    }
    final aluno = store.alunos(a.turma).firstWhere((s) => s.id == _alunoId);
    if (store.correcoes(a.id).any((r) => r.alunoId == aluno.id)) {
      setState(() => _processando = false);
      if (!await confirmar(context, 'Este aluno já tem resultado',
          'A nova leitura substituirá a anterior somente depois de você revisar e confirmar.',
          action: 'Revisar nova leitura')) {
        return;
      }
      if (!mounted) return;
    }
    final answers = store.leituraExemplo(a.id);
    final r =
        Correcao(alunoId: aluno.id, alunoNome: aluno.nome, respostas: answers);
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => RevisaoScreen(avaliacaoId: a.id, correcao: r)));
  }

  @override
  Widget build(BuildContext context) {
    final store = SessionScope.of(context);
    final a = store.avaliacao(widget.avaliacaoId);
    final alunos = store.alunos(a.turma);
    _alunoId ??= alunos
            .where((s) => !store.correcoes(a.id).any((r) => r.alunoId == s.id))
            .firstOrNull
            ?.id ??
        alunos.firstOrNull?.id;
    final aluno = alunos.where((s) => s.id == _alunoId).firstOrNull;
    final enabled = widget.gabarito || aluno != null;
    return AppPage(
        title: widget.gabarito ? 'Ler gabarito' : 'Ler folha de respostas',
        bottom: ElevatedButton.icon(
            onPressed: !enabled || _processando
                ? null
                : () {
                    if (!_identificado) {
                      setState(() => _identificado = true);
                    } else {
                      _ler();
                    }
                  },
            icon: _processando
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    _identificado
                        ? Icons.document_scanner_outlined
                        : Icons.qr_code_scanner_rounded,
                    size: 20),
            label: Text(_processando
                ? 'Lendo marcações…'
                : _identificado
                    ? 'Ler folha de demonstração'
                    : 'Identificar QR de demonstração')),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          PageHeading(
              eyebrow: 'Leitura demonstrativa',
              title: _identificado ? 'Ler as marcações' : 'Identificar a folha',
              subtitle: _identificado
                  ? 'Mantenha a folha inteira visível e evite sombras sobre as marcações.'
                  : 'O QR Code informa a avaliação, a versão da prova e a identificação do aluno.'),
          if (!widget.gabarito && alunos.isNotEmpty) ...[
            DropdownButtonFormField<String>(
                initialValue: _alunoId,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Aluno da folha de demonstração',
                    prefixIcon: Icon(Icons.person_outline_rounded)),
                items: alunos
                    .map((s) => DropdownMenuItem(
                        value: s.id,
                        child:
                            Text(s.nome, style: const TextStyle(fontSize: 12))))
                    .toList(),
                onChanged: _processando
                    ? null
                    : (v) => setState(() {
                          _alunoId = v;
                          _identificado = false;
                        })),
            const SizedBox(height: 18)
          ],
          if (!enabled)
            const InfoBanner('Adicione alunos à turma antes de ler as folhas.',
                warning: true),
          Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(26)),
              child: Column(children: [
                Row(children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.lavender, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Expanded(
                      child: Text('PRÉVIA SIMULADA',
                          style: TextStyle(
                              color: AppColors.lavender,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.4))),
                  const Icon(Icons.crop_free_rounded,
                      color: AppColors.lavender, size: 19)
                ]),
                const SizedBox(height: 20),
                Stack(children: [
                  FolhaRespostas(
                      avaliacao: a,
                      aluno: widget.gabarito ? null : aluno,
                      respostas: widget.gabarito
                          ? List<int?>.generate(
                              a.numQuestoes, (q) => q % a.numAlternativas)
                          : store.leituraExemplo(a.id),
                      compact: true),
                  if (!_identificado)
                    Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.primary, width: 2),
                                borderRadius: BorderRadius.circular(12))))
                ]),
                const SizedBox(height: 18),
                Text(
                    _identificado
                        ? '${a.codigo} · Versão A · ${widget.gabarito ? 'Gabarito' : aluno?.id ?? 'Sem aluno'}'
                        : 'Encontre o QR Code no canto superior da folha.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.onDarkSecondary))
              ])),
          const SizedBox(height: 18),
          if (_identificado)
            const InfoBanner(
                'Folha identificada. Confira os dados antes de continuar.',
                icon: Icons.check_circle_outline_rounded)
          else
            const InfoBanner(
                'Esta prévia não usa a câmera do aparelho. A leitura demonstra a experiência prevista para o professor.',
                icon: Icons.science_outlined),
          const SizedBox(height: 18),
          const Row(children: [
            Icon(Icons.light_mode_outlined,
                size: 17, color: AppColors.textMuted),
            SizedBox(width: 8),
            Expanded(
                child: Text(
                    'Boa iluminação · folha plana · todas as bordas visíveis',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted)))
          ]),
        ]));
  }
}

class RevisaoScreen extends StatefulWidget {
  final String avaliacaoId;
  final Correcao correcao;
  const RevisaoScreen(
      {super.key, required this.avaliacaoId, required this.correcao});
  @override
  State<RevisaoScreen> createState() => _RevisaoScreenState();
}

class _RevisaoScreenState extends State<RevisaoScreen> {
  late final List<int?> _respostas = [...widget.correcao.respostas];
  bool _soPendentes = false;
  int get _pendentes => _respostas.where((r) => r != null && r < 0).length;
  void _salvar() {
    if (_pendentes > 0) {
      avisar(context,
          'Revise $_pendentes ${_pendentes == 1 ? 'marcação sinalizada' : 'marcações sinalizadas'} antes de confirmar.');
      return;
    }
    SessionScope.of(context).salvarCorrecao(
        widget.avaliacaoId, widget.correcao.copyWith(respostas: _respostas));
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ResultadoAlunoScreen(
                avaliacaoId: widget.avaliacaoId,
                alunoId: widget.correcao.alunoId)));
  }

  @override
  Widget build(BuildContext context) {
    final a = SessionScope.of(context).avaliacao(widget.avaliacaoId);
    final indices = List.generate(a.numQuestoes, (q) => q)
        .where((q) =>
            !_soPendentes || (_respostas[q] != null && _respostas[q]! < 0))
        .toList();
    return AppPage(
        title: 'Revisar leitura',
        bottom: ElevatedButton(
            onPressed: _salvar,
            child: Text(_pendentes > 0
                ? 'Revisar $_pendentes ${_pendentes == 1 ? 'marcação' : 'marcações'} para confirmar'
                : 'Confirmar correção')),
        child: ListView(padding: const EdgeInsets.all(24), children: [
          PageHeading(
              title: 'Revisar marcações',
              subtitle:
                  '${widget.correcao.alunoNome}\n${widget.correcao.alunoId} · ${a.nome}'),
          InfoBanner(
              _pendentes > 0
                  ? '$_pendentes ${_pendentes == 1 ? 'marcação precisa' : 'marcações precisam'} de revisão. Confira a folha física e escolha a resposta; você também pode registrar em branco.'
                  : 'Todas as marcações estão prontas para confirmação. Respostas em branco valem zero.',
              icon: _pendentes > 0
                  ? Icons.visibility_outlined
                  : Icons.check_circle_outline_rounded,
              warning: _pendentes > 0),
          const SizedBox(height: 16),
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mostrar apenas marcações para revisar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              value: _soPendentes,
              onChanged: (v) => setState(() => _soPendentes = v)),
          const SizedBox(height: 10),
          if (indices.isEmpty)
            const EmptyState(
                title: 'Tudo revisado',
                subtitle:
                    'Confirme a correção ou desative o filtro para conferir todas as respostas.',
                icon: Icons.task_alt_rounded),
          ...indices.map((q) {
            final answer = _respostas[q],
                pending = answer != null && answer < 0;
            return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SurfaceCard(
                    color: pending ? AppColors.agendadaBg : Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(
                                'Questão ${(q + 1).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            if (pending)
                              const Icon(Icons.flag_outlined,
                                  size: 17, color: AppColors.agendadaFg)
                          ]),
                          const SizedBox(height: 6),
                          Text(
                              pending
                                  ? answer == -1
                                      ? 'Mais de uma alternativa identificada.'
                                      : 'Marcação pouco nítida.'
                                  : answer == null
                                      ? 'Nenhuma alternativa marcada.'
                                      : 'Alternativa ${respostaLabel(answer)} identificada.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: pending
                                      ? AppColors.agendadaFg
                                      : AppColors.textSecondary)),
                          const SizedBox(height: 12),
                          Wrap(children: [
                            for (var alt = 0; alt < a.numAlternativas; alt++)
                              AnswerBubble(
                                  index: alt,
                                  selected: answer == alt,
                                  onTap: () =>
                                      setState(() => _respostas[q] = alt))
                          ]),
                          const SizedBox(height: 4),
                          TextButton.icon(
                              onPressed: () =>
                                  setState(() => _respostas[q] = null),
                              icon: Icon(
                                  answer == null
                                      ? Icons.check_rounded
                                      : Icons.remove_rounded,
                                  size: 16),
                              label: const Text('Registrar em branco',
                                  style: TextStyle(fontSize: 11)))
                        ])));
          }),
          const SizedBox(height: 12),
          TextButton.icon(
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CapturaScreen(avaliacaoId: a.id))),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Descartar esta leitura e tentar novamente')),
        ]));
  }
}
