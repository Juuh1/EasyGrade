import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../services/leitura_folha.dart';
import 'package:flutter/material.dart';
import '../data/session_store.dart';
import '../models/correcao.dart';
import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/avaliacao_card.dart';
import 'gabarito_screen.dart';
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
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            title: 'Leitura de provas',
            subtitle:
                'Escolha a avaliação para identificar e ler as folhas de respostas da turma.',
          ),
          SurfaceCard(
            color: AppColors.softPurple,
            child: Column(
              children: [
                for (final item in [
                  (
                    Icons.qr_code_2_rounded,
                    'Identifique',
                    'O QR Code vincula a folha à avaliação e ao aluno.',
                  ),
                  (
                    Icons.fact_check_outlined,
                    'Confira a referência',
                    'O gabarito define as respostas corretas.',
                  ),
                  (
                    Icons.document_scanner_outlined,
                    'Leia e revise',
                    'Uma folha por aluno; confirme as marcações incertas.',
                  ),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.$2,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.$3,
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeading('Qual avaliação vamos corrigir?'),
          if (store.avaliacoes.isEmpty)
            EmptyState(
              title: 'Comece por uma avaliação',
              subtitle: 'Crie a avaliação e seu gabarito para abrir a leitura.',
              action: ElevatedButton(
                onPressed: () => abrir(context, const CriarAvaliacaoScreen()),
                child: const Text('Criar avaliação'),
              ),
            )
          else
            ...store.avaliacoes.map(
              (a) => AvaliacaoCard(
                avaliacao: a,
                onTap: () => abrir(
                  context,
                  store.gabaritoPronto(a.id)
                      ? CapturaScreen(avaliacaoId: a.id)
                      : GabaritoScreen(
                          avaliacaoId: a.id,
                          abrirDetalhesAoSalvar: true,
                        ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const InfoBanner(
            'Fotografe a folha gerada pelo EasyGrade e revise as marcações antes de confirmar.',
            icon: Icons.science_outlined,
          ),
        ],
      ),
    );
  }
}

class CapturaScreen extends StatefulWidget {
  final String avaliacaoId;
  final bool gabarito;
  const CapturaScreen({
    super.key,
    required this.avaliacaoId,
    this.gabarito = false,
  });
  @override
  State<CapturaScreen> createState() => _CapturaScreenState();
}

class _CapturaScreenState extends State<CapturaScreen> {
  bool _processando = false;
  String? _erro;
  Uint8List? _foto;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final recuperada = await ImagePicker().retrieveLostData();
        if (!mounted) return;
        if (recuperada.files?.isNotEmpty == true) {
          await _processar(recuperada.files!.first);
        }
        if (recuperada.exception != null && mounted) {
          setState(
            () => _erro = 'Não foi possível recuperar a foto. Tente novamente.',
          );
        }
      });
    }
  }

  Future<void> _capturar(ImageSource origem) async {
    if (_processando) return;
    try {
      final arquivo = await ImagePicker().pickImage(
        source: origem,
        imageQuality: 95,
        maxWidth: 2400,
        maxHeight: 3200,
      );
      if (!mounted || arquivo == null) return;
      await _processar(arquivo);
    } catch (e) {
      if (mounted) {
        setState(() {
          _processando = false;
          _erro =
              'Não foi possível abrir a câmera ou a imagem. Confira a permissão e tente novamente.';
        });
      }
    }
  }

  Future<void> _processar(XFile arquivo) async {
    setState(() {
      _processando = true;
      _erro = null;
    });
    final store = SessionScope.of(context);
    try {
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      setState(() => _foto = bytes);
      String? codigo;
      List<Map<String, int>>? pontosQr;
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
        try {
          final encontrados = await scanner.processImage(
            InputImage.fromFilePath(arquivo.path),
          );
          final encontrado = encontrados
              .where((v) => v.rawValue?.contains('"eg"') ?? false)
              .firstOrNull;
          codigo = encontrado?.rawValue;
          pontosQr = encontrado?.cornerPoints
              .map((p) => <String, int>{'x': p.x, 'y': p.y})
              .toList();
        } catch (_) {
          // O leitor local ainda pode reconhecer a imagem se o detector nativo falhar.
        } finally {
          try {
            await scanner.close();
          } catch (_) {
            // A limpeza do detector não deve impedir a leitura local da foto.
          }
        }
      }
      final leitura = await compute(analisarFoto, <String, Object?>{
        'bytes': bytes,
        'codigo': codigo,
        'pontosQr': pontosQr,
      });
      if (!mounted) return;
      final a = store.avaliacao(widget.avaliacaoId);
      if (leitura.avaliacaoId != a.id ||
          leitura.alternativas != a.numAlternativas ||
          leitura.respostas.length != a.numQuestoes) {
        throw const FormatException(
          'Esta folha pertence a outra avaliação. Abra a avaliação indicada na folha.',
        );
      }
      if (widget.gabarito) {
        if (leitura.variante != 'A') {
          throw const FormatException(
            'Use o gabarito de referência da versão A.',
          );
        }
        Navigator.pop(context, leitura.respostas);
        return;
      }
      final aluno = store
          .alunos(a.turma)
          .where((v) => v.id == leitura.alunoId)
          .firstOrNull;
      if (aluno == null) {
        throw const FormatException(
          'A matrícula do QR não está cadastrada nesta turma. Confira os alunos.',
        );
      }
      final versao = await store.carregarVariante(a.id, leitura.variante);
      if (leitura.variante != 'A' &&
          (versao == null ||
              (versao['alunos'] is List
                  ? !(versao['alunos'] as List).contains(aluno.id)
                  : versao['alunoId'] != aluno.id))) {
        throw const FormatException(
          'A versão da folha não corresponde ao aluno. Gere o material novamente.',
        );
      }
      if (!mounted) return;
      if (store.correcoes(a.id).any((r) => r.alunoId == aluno.id)) {
        if (!await confirmar(
          context,
          'Este aluno já tem resultado',
          'Substituir o resultado anterior depois de revisar esta leitura?',
          action: 'Revisar',
        )) {
          return;
        }
      }
      if (!mounted) return;
      final r = Correcao(
        alunoId: aluno.id,
        alunoNome: aluno.nome,
        variante: leitura.variante,
        respostas: leitura.respostas,
        ordemQuestoes: (versao?['ordemQuestoes'] as List? ?? [])
            .map((v) => (v as num).toInt())
            .toList(),
        ordemAlternativas: Correcao.lerOrdens(versao?['ordemAlternativas']),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RevisaoScreen(avaliacaoId: a.id, correcao: r, foto: bytes),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => _erro = e is FormatException
              ? e.message
              : 'Não foi possível ler a folha. Confira a conexão e fotografe novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext _) => AppPage(
    title: widget.gabarito ? 'Ler gabarito' : 'Ler folha de respostas',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          title: widget.gabarito
              ? 'Fotografar o gabarito'
              : 'Fotografar a folha',
          subtitle: 'Use a folha gerada pelo EasyGrade.',
        ),
        if (_foto != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.memory(_foto!, height: 300, fit: BoxFit.contain),
          )
        else
          const SurfaceCard(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 88,
                color: AppColors.primary,
              ),
            ),
          ),
        const SizedBox(height: 20),
        if (_erro != null) InfoBanner(_erro!, warning: true),
        if (_processando)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: () =>
                _capturar(kIsWeb ? ImageSource.gallery : ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text(
              kIsWeb ? 'Escolher foto da folha' : 'Fotografar folha',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _capturar(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Selecionar da galeria'),
          ),
        ],
        const SizedBox(height: 20),
        const InfoBanner(
          'Use boa iluminação, papel plano e bolhas preenchidas. Confira todas as respostas na revisão antes de confirmar a nota.',
        ),
      ],
    ),
  );
}

class RevisaoScreen extends StatefulWidget {
  final String avaliacaoId;
  final Correcao correcao;
  final Uint8List? foto;
  const RevisaoScreen({
    super.key,
    required this.avaliacaoId,
    required this.correcao,
    this.foto,
  });
  @override
  State<RevisaoScreen> createState() => _RevisaoScreenState();
}

class _RevisaoScreenState extends State<RevisaoScreen> {
  late final List<int?> _respostas = [...widget.correcao.respostas];
  bool _soPendentes = false;
  int get _pendentes => _respostas.where((r) => r != null && r < 0).length;
  bool _salvando = false;
  Future<void> _salvar() async {
    if (_salvando) return;
    if (_pendentes > 0) {
      avisar(
        context,
        'Revise $_pendentes ${_pendentes == 1 ? 'marcação sinalizada' : 'marcações sinalizadas'} antes de confirmar.',
      );
      return;
    }
    final store = SessionScope.of(context);
    setState(() => _salvando = true);
    try {
      await store.salvarCorrecao(
        widget.avaliacaoId,
        widget.correcao.copyWith(respostas: _respostas),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoAlunoScreen(
            avaliacaoId: widget.avaliacaoId,
            alunoId: widget.correcao.alunoId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        avisar(
          context,
          'Não foi possível salvar a correção. Confira a conexão e tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext _) {
    final store = SessionScope.of(context);
    final a = store.avaliacao(widget.avaliacaoId);
    final indices = List.generate(a.numQuestoes, (q) => q)
        .where(
          (q) => !_soPendentes || (_respostas[q] != null && _respostas[q]! < 0),
        )
        .toList();
    return AppPage(
      title: 'Revisar leitura',
      bottom: ElevatedButton(
        onPressed: _salvando ? null : _salvar,
        child: Text(
          _salvando
              ? 'Salvando correção…'
              : _pendentes > 0
              ? 'Revisar $_pendentes ${_pendentes == 1 ? 'marcação' : 'marcações'} para confirmar'
              : 'Confirmar correção',
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageHeading(
            title: 'Revisar marcações',
            subtitle:
                '${widget.correcao.alunoNome}\n${widget.correcao.alunoId} · Versão ${store.rotuloVersao(a.id, widget.correcao.variante)} · ${a.nome}',
          ),
          InfoBanner(
            _pendentes > 0
                ? '$_pendentes ${_pendentes == 1 ? 'marcação precisa' : 'marcações precisam'} de revisão. Confira a folha física e escolha a resposta; você também pode registrar em branco.'
                : 'Todas as marcações estão prontas para confirmação. Respostas em branco valem zero.',
            icon: _pendentes > 0
                ? Icons.visibility_outlined
                : Icons.check_circle_outline_rounded,
            warning: _pendentes > 0,
          ),
          if (widget.foto != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  widget.foto!,
                  height: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Mostrar apenas marcações para revisar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            value: _soPendentes,
            onChanged: (v) => setState(() => _soPendentes = v),
          ),
          const SizedBox(height: 10),
          if (indices.isEmpty)
            const EmptyState(
              title: 'Tudo revisado',
              subtitle:
                  'Confirme a correção ou desative o filtro para conferir todas as respostas.',
              icon: Icons.task_alt_rounded,
            ),
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
                    Row(
                      children: [
                        Text(
                          'Questão ${(q + 1).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (pending)
                          const Icon(
                            Icons.flag_outlined,
                            size: 17,
                            color: AppColors.agendadaFg,
                          ),
                      ],
                    ),
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
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: [
                        for (var alt = 0; alt < a.numAlternativas; alt++)
                          AnswerBubble(
                            index: alt,
                            selected: answer == alt,
                            onTap: () => setState(() => _respostas[q] = alt),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: () => setState(() => _respostas[q] = null),
                      icon: Icon(
                        answer == null
                            ? Icons.check_rounded
                            : Icons.remove_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Registrar em branco',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CapturaScreen(avaliacaoId: a.id),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Descartar esta leitura e tentar novamente'),
          ),
        ],
      ),
    );
  }
}
