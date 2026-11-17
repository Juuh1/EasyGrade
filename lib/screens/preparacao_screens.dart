import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../data/session_store.dart';
import '../services/arquivos_service.dart';
import '../widgets/app_ui.dart';
import 'layout_prova_screen.dart';

class MateriaisScreen extends StatefulWidget {
  final String avaliacaoId;
  const MateriaisScreen({super.key, required this.avaliacaoId});
  @override
  State<MateriaisScreen> createState() => _MateriaisScreenState();
}

class _MateriaisScreenState extends State<MateriaisScreen> {
  String? _alunoId;
  bool _ocupado = false;
  Future<void> _executar(Future<void> Function() acao) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    try {
      await acao();
    } catch (e) {
      if (mounted) {
        avisar(
          context,
          e is StateError
              ? e.message
              : 'Não foi possível gerar o arquivo. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _pdf({
    bool caderno = false,
    bool gabarito = false,
    bool completa = false,
  }) async {
    final store = SessionScope.of(context), id = widget.avaliacaoId;
    final alunos = _alunoId == null
        ? store.alunos(store.avaliacao(id).turma)
        : store
              .alunos(store.avaliacao(id).turma)
              .where((v) => v.id == _alunoId)
              .toList();
    final bytes = completa
        ? await ArquivosService.provaCompletaPDF(store, id, alunos: alunos)
        : caderno
        ? await ArquivosService.cadernoPDF(store, id, alunos: alunos)
        : await ArquivosService.folhasPDF(
            store,
            id,
            alunos: alunos,
            gabarito: gabarito,
          );
    if (!mounted) return;
    abrir(
      context,
      DocumentoPDFScreen(
        bytes: bytes,
        nome: completa
            ? 'prova-completa.pdf'
            : caderno
            ? 'cadernos.pdf'
            : gabarito
            ? 'gabarito.pdf'
            : 'folhas-respostas.pdf',
      ),
    );
  }

  Future<void> _configurarVersoes(SessionStore store) async {
    var questoes = store.avaliacao(widget.avaliacaoId).numQuestoes > 1;
    var alternativas = true;
    final podeEmbaralharQuestoes = questoes;
    final aplicar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => AlertDialog(
          title: const Text('Gerar versões A e B'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'A versão A usa a ordem original. Escolha o que muda na versão B. Depois de gerar, imprima os materiais atualizados.',
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Embaralhar questões'),
                  value: questoes,
                  onChanged: podeEmbaralharQuestoes
                      ? (v) => atualizar(() => questoes = v!)
                      : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Embaralhar alternativas'),
                  value: alternativas,
                  onChanged: (v) => atualizar(() => alternativas = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: questoes || alternativas
                  ? () => Navigator.pop(context, true)
                  : null,
              child: const Text('Gerar versões'),
            ),
          ],
        ),
      ),
    );
    if (aplicar != true || !mounted) return;
    await store.gerarVariantes(
      widget.avaliacaoId,
      embaralharQuestoes: questoes,
      embaralharAlternativas: alternativas,
    );
    if (mounted) {
      avisar(
        context,
        'Versões A e B prontas. O QR identifica a versão de cada aluno.',
      );
    }
  }

  @override
  Widget build(BuildContext _) {
    final store = SessionScope.of(context),
        a = store.avaliacaoOuNull(widget.avaliacaoId);
    if (a == null) {
      return const AppPage(
        title: 'Materiais',
        child: Center(child: Text('Avaliação indisponível.')),
      );
    }
    final alunos = store.alunos(a.turma);
    if (_alunoId != null && !alunos.any((v) => v.id == _alunoId)) {
      _alunoId = null;
    }
    return AppPage(
      title: 'Materiais da avaliação',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PageHeading(
            title: 'Materiais da avaliação',
            subtitle:
                '${a.nome}\nGere folhas identificadas e cadernos para a prova em papel.',
          ),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FormLabel('Alunos'),
                DropdownButtonFormField<String>(
                  initialValue: _alunoId,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Toda a turma'),
                    ),
                    ...alunos.map(
                      (v) => DropdownMenuItem(value: v.id, child: Text(v.nome)),
                    ),
                  ],
                  onChanged: _ocupado
                      ? null
                      : (v) => setState(() => _alunoId = v),
                ),
                const SizedBox(height: 16),
                Text(
                  '${alunos.length} alunos · ${a.numQuestoes} questões · ${a.numAlternativas} alternativas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_ocupado)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ActionTile(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Exportar prova completa',
            subtitle:
                'Caderno e folha de respostas com QR em páginas separadas do mesmo PDF.',
            onTap: _ocupado
                ? null
                : () => _executar(() => _pdf(completa: true)),
          ),
          ActionTile(
            icon: Icons.qr_code_2_rounded,
            title: 'Folhas de respostas em PDF',
            subtitle:
                'QR Code individual, identificação e marcas para leitura pela câmera.',
            onTap: _ocupado ? null : () => _executar(() => _pdf()),
          ),
          ActionTile(
            icon: Icons.description_outlined,
            title: 'Cadernos de prova em PDF',
            subtitle:
                'Questões e alternativas mantidas no mesmo bloco, com as versões dos alunos.',
            onTap: _ocupado ? null : () => _executar(() => _pdf(caderno: true)),
          ),
          ActionTile(
            icon: Icons.edit_document,
            title: 'Cadernos editáveis em Word',
            subtitle:
                'Arquivo .docx com nome, matrícula, questões e alternativas.',
            onTap: _ocupado
                ? null
                : () => _executar(() async {
                    final bytes = ArquivosService.cadernoWord(store, a.id);
                    await ArquivosService.compartilhar(
                      bytes,
                      'cadernos-easygrade.docx',
                      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                    );
                  }),
          ),
          ActionTile(
            icon: Icons.fact_check_outlined,
            title: 'Gabarito de referência em PDF',
            subtitle: 'Versão A preenchida com as respostas corretas.',
            onTap: _ocupado || !store.gabaritoPronto(a.id)
                ? null
                : () => _executar(() => _pdf(gabarito: true)),
          ),
          const SectionHeading('Organização'),
          ActionTile(
            icon: Icons.shuffle_rounded,
            title: 'Gerar versões A e B',
            subtitle: 'Distribua os modelos entre os alunos da turma.',
            onTap: _ocupado
                ? null
                : () => _executar(() => _configurarVersoes(store)),
          ),
          ActionTile(
            icon: Icons.view_agenda_outlined,
            title: 'Organizar páginas',
            subtitle: 'Escolha em qual página começa cada bloco de questão.',
            onTap: _ocupado
                ? null
                : () => abrir(context, LayoutProvaScreen(avaliacaoId: a.id)),
          ),
          const InfoBanner(
            'Imprima as folhas em A4, no tamanho original. Não recorte o QR nem as quatro marcas dos cantos. Use o PDF para a leitura automática; edite apenas os cadernos no Word.',
          ),
        ],
      ),
    );
  }
}

class DocumentoPDFScreen extends StatelessWidget {
  final Uint8List bytes;
  final String nome;
  const DocumentoPDFScreen({
    super.key,
    required this.bytes,
    required this.nome,
  });
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Visualizar e imprimir',
    child: PdfPreview(
      build: (_) async => bytes,
      pdfFileName: nome,
      canChangeOrientation: false,
      canChangePageFormat: false,
      allowSharing: true,
      allowPrinting: true,
    ),
  );
}
