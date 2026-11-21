import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../data/session_store.dart';
import '../models/avaliacao.dart';
import '../models/correcao.dart';
import 'leitura_folha.dart';

class ArquivosService {
  static Future<void> compartilhar(
    Uint8List bytes,
    String nome,
    String tipo,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: tipo)],
        fileNameOverrides: [nome],
      ),
    );
  }

  static const _roxo = PdfColor.fromInt(0xff7952b9);
  static const _escuro = PdfColor.fromInt(0xff342047);
  static const _lavanda = PdfColor.fromInt(0xfff1ebf7);
  static const _linha = PdfColor.fromInt(0xffded5e7);

  static String versaoAluno(SessionStore store, String id, String aluno) =>
      store
              .variantes(id)
              .where(
                (v) =>
                    v['alunoId'] == aluno ||
                    (v['alunos'] is List &&
                        (v['alunos'] as List).contains(aluno)),
              )
              .firstOrNull?['id']
          as String? ??
      'A';

  static List<int> ordem(SessionStore store, String id, String versao) =>
      (store.variante(id, versao)?['ordemQuestoes'] as List?)
          ?.map((v) => (v as num).toInt())
          .toList() ??
      List.generate(store.avaliacao(id).numQuestoes, (i) => i);

  static List<List<int>> alternativas(
    SessionStore store,
    String id,
    String versao,
  ) {
    final a = store.avaliacao(id);
    final salvo = store.variante(id, versao)?['ordemAlternativas'];
    return salvo == null
        ? List.generate(
            a.numQuestoes,
            (_) => List.generate(a.numAlternativas, (i) => i),
          )
        : Correcao.lerOrdens(salvo);
  }

  static Future<Uint8List> folhasPDF(
    SessionStore store,
    String id, {
    List<Aluno>? alunos,
    bool gabarito = false,
  }) =>
      _materialPDF(store, id, alunos: alunos, folhas: true, gabarito: gabarito);

  static Future<Uint8List> cadernoPDF(
    SessionStore store,
    String id, {
    List<Aluno>? alunos,
  }) => _materialPDF(store, id, alunos: alunos, cadernos: true);

  static Future<Uint8List> provaCompletaPDF(
    SessionStore store,
    String id, {
    List<Aluno>? alunos,
  }) => _materialPDF(store, id, alunos: alunos, cadernos: true, folhas: true);

  static Future<Uint8List> _materialPDF(
    SessionStore store,
    String id, {
    List<Aluno>? alunos,
    bool cadernos = false,
    bool folhas = false,
    bool gabarito = false,
  }) async {
    final a = store.avaliacao(id), questoes = store.questoes(id);
    if (cadernos && questoes.length != a.numQuestoes) {
      throw StateError('Selecione todas as questões antes de gerar o caderno.');
    }
    final lista = gabarito
        ? [const Aluno('@gabarito', 'Gabarito de referência')]
        : alunos ?? store.alunos(a.turma);
    if (lista.isEmpty) {
      throw StateError('Cadastre pelo menos um aluno para gerar os materiais.');
    }
    final fonte = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Manrope.ttf'),
    );
    final logo = (await rootBundle.loadString(
      'SVG/easygradesimbolo.svg',
    )).replaceAll('#000000', '#7952B9');
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: fonte, bold: fonte),
    );

    for (final aluno in lista) {
      final versao = gabarito ? 'A' : versaoAluno(store, id, aluno.id);
      final rotulo = store.rotuloVersao(id, versao);
      if (cadernos) {
        _adicionarCaderno(doc, store, a, aluno, versao, rotulo, logo);
      }
      if (folhas) {
        _adicionarFolha(doc, store, a, aluno, versao, rotulo, logo, gabarito);
      }
    }
    return doc.save();
  }

  static pw.Widget _cabecalho(
    SessionStore store,
    Avaliacao a,
    Aluno aluno,
    String rotulo,
    String logo,
    String titulo, {
    bool compacto = false,
  }) {
    pw.Widget texto(String valor, double tamanho, {PdfColor cor = _escuro}) =>
        pw.Text(
          valor,
          maxLines: compacto ? 1 : null,
          overflow: compacto ? pw.TextOverflow.clip : pw.TextOverflow.visible,
          style: pw.TextStyle(fontSize: tamanho, color: cor),
        );
    final instituicao = store.instituicao.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.SvgImage(svg: logo, width: 18, height: 17),
            pw.SizedBox(width: 6),
            texto('EasyGrade', 11, cor: _roxo),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: texto(
                instituicao.isEmpty
                    ? 'Instituição: ____________________'
                    : instituicao,
                10,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 7),
        pw.Container(height: 1, color: _roxo),
        pw.SizedBox(height: 7),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  texto('$titulo  ·  Versão $rotulo', 9, cor: _roxo),
                  pw.SizedBox(height: 3),
                  texto(a.nome, compacto ? 13 : 17),
                  pw.SizedBox(height: 4),
                  if (compacto) ...[
                    texto('Disciplina: ${a.disciplina}', 9),
                    texto('Turma: ${a.turma}', 9),
                  ] else
                    texto(
                      'Disciplina: ${a.disciplina}   |   Turma: ${a.turma}',
                      9,
                    ),
                  texto('Professor(a): ${store.nome}', 9),
                  texto(
                    aluno.id == '@gabarito'
                        ? 'Uso do professor'
                        : 'Aluno(a): ${aluno.nome}   |   Matrícula: ${aluno.id}',
                    9,
                  ),
                  if (a.data != null) texto('Data: ${a.dataLabelCurta}', 9),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(
              width: 74,
              padding: const pw.EdgeInsets.all(7),
              decoration: pw.BoxDecoration(
                color: _lavanda,
                border: pw.Border.all(color: _linha),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                children: [
                  texto('NOTA', 8, cor: _roxo),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    width: 44,
                    height: 14,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: _roxo)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static void _adicionarFolha(
    pw.Document doc,
    SessionStore store,
    Avaliacao a,
    Aluno aluno,
    String versao,
    String rotulo,
    String logo,
    bool gabarito,
  ) {
    final codigo = FormatoFolha.codigo(
      a.id,
      aluno.id,
      versao,
      a.numQuestoes,
      a.numAlternativas,
    );
    final respostas = gabarito ? store.gabarito(a.id) : const <int?>[];
    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(595, 842),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.SizedBox(
          width: 595,
          height: 842,
          child: pw.Stack(
            children: [
              for (final x in [28.0, 567.0])
                for (final y in [28.0, 814.0])
                  pw.Positioned(
                    left: x - 6,
                    top: y - 6,
                    child: pw.Container(
                      width: 12,
                      height: 12,
                      color: PdfColors.black,
                    ),
                  ),
              pw.Positioned(
                left: 46,
                right: 163,
                top: 48,
                child: _cabecalho(
                  store,
                  a,
                  aluno,
                  rotulo,
                  logo,
                  gabarito ? 'Gabarito de referência' : 'Folha de respostas',
                  compacto: true,
                ),
              ),
              pw.Positioned(
                left: 454,
                top: 66,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: codigo,
                  width: 96,
                  height: 96,
                ),
              ),
              for (var col = 0; col < (a.numQuestoes + 19) ~/ 20; col++)
                for (var alt = 0; alt < a.numAlternativas; alt++)
                  pw.Positioned(
                    left: 78 + col * 174 + alt * 23.0,
                    top: 179,
                    child: pw.Text(
                      String.fromCharCode(65 + alt),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
              for (var q = 0; q < a.numQuestoes; q++) ...[
                pw.Positioned(
                  left: 47 + (q ~/ 20) * 174.0,
                  top: FormatoFolha.bolha(q, 0).y - 5,
                  child: pw.Text(
                    '${q + 1}'.padLeft(2, '0'),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                for (var alt = 0; alt < a.numAlternativas; alt++)
                  pw.Positioned(
                    left: FormatoFolha.bolha(q, alt).x - 6,
                    top: FormatoFolha.bolha(q, alt).y - 6,
                    child: pw.Container(
                      width: 12,
                      height: 12,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(width: .7),
                        color: gabarito && respostas[q] == alt
                            ? PdfColors.black
                            : PdfColors.white,
                      ),
                    ),
                  ),
              ],
              pw.Positioned(
                left: 46,
                right: 49,
                top: 764,
                child: pw.Text(
                  'Preencha uma bolha por questão com caneta preta ou azul.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _adicionarCaderno(
    pw.Document doc,
    SessionStore store,
    Avaliacao a,
    Aluno aluno,
    String versao,
    String rotulo,
    String logo,
  ) {
    final questoes = store.questoes(a.id), paginas = store.paginas(a.id);
    final oq = ordem(store, a.id, versao),
        oa = alternativas(store, a.id, versao);
    final pontos = a.pontos;
    for (final pagina in paginas.toSet().toList()..sort()) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
          header: (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 15),
            child: _cabecalho(
              store,
              a,
              aluno,
              rotulo,
              logo,
              'Caderno de questões',
            ),
          ),
          footer: (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'EasyGrade  ·  ${a.codigo}  ·  ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 8, color: _roxo),
            ),
          ),
          build: (_) => [
            for (var i = 0; i < a.numQuestoes; i++)
              if (paginas[i] == pagina)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'QUESTÃO ${i + 1}  ·  ${formatarPontos(pontos[oq[i]])} pt',
                        style: const pw.TextStyle(fontSize: 9, color: _roxo),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        questoes[oq[i]].enunciado,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                      pw.SizedBox(height: 5),
                      for (var alt = 0; alt < a.numAlternativas; alt++)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Text(
                            '${String.fromCharCode(65 + alt)}) ${questoes[oq[i]].alternativas[oa[i][alt]]}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      );
    }
  }

  static Uint8List cadernoWord(SessionStore store, String id) {
    final a = store.avaliacao(id), questoes = store.questoes(id);
    if (questoes.length != a.numQuestoes) {
      throw StateError('Selecione todas as questões antes de gerar o Word.');
    }
    final b = StringBuffer();
    String xml(String v) => const HtmlEscape(HtmlEscapeMode.element).convert(v);
    void par(
      String texto, {
      bool manter = false,
      bool quebra = false,
    }) => b.write(
      '<w:p><w:pPr><w:keepLines/>${manter ? '<w:keepNext/>' : ''}${quebra ? '<w:pageBreakBefore/>' : ''}</w:pPr><w:r><w:t xml:space="preserve">${xml(texto)}</w:t></w:r></w:p>',
    );
    final alunos = store.alunos(a.turma);
    if (alunos.isEmpty) {
      throw StateError('Cadastre os alunos antes de gerar os cadernos.');
    }
    for (var s = 0; s < alunos.length; s++) {
      final aluno = alunos[s], v = versaoAluno(store, id, aluno.id);
      final oq = ordem(store, id, v),
          oa = alternativas(store, id, v),
          paginas = store.paginas(id);
      par('EasyGrade · ${store.instituicao}', manter: true, quebra: s > 0);
      par(a.nome, manter: true);
      par(
        '${a.disciplina} · ${a.turma} · Professor(a): ${store.nome}',
        manter: true,
      );
      par(
        '${aluno.nome} · ${aluno.id} · Versão ${store.rotuloVersao(id, v)} · Nota: _____',
        manter: true,
      );
      for (var i = 0; i < a.numQuestoes; i++) {
        par(
          '${i + 1}. [${formatarPontos(a.pontos[oq[i]])} pt] ${questoes[oq[i]].enunciado}',
          manter: true,
          quebra: i > 0 && paginas[i] != paginas[i - 1],
        );
        for (var alt = 0; alt < a.numAlternativas; alt++) {
          par(
            '${String.fromCharCode(65 + alt)}) ${questoes[oq[i]].alternativas[oa[i][alt]]}',
            manter: alt < a.numAlternativas - 1,
          );
        }
        par('');
      }
    }
    final arquivo = Archive();
    void adicionar(String nome, String conteudo) {
      final bytes = utf8.encode(conteudo);
      arquivo.addFile(ArchiveFile(nome, bytes.length, bytes));
    }

    adicionar(
      '[Content_Types].xml',
      '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>',
    );
    adicionar(
      '_rels/.rels',
      '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>',
    );
    adicionar(
      'word/document.xml',
      '<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$b<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="850" w:bottom="850" w:left="850" w:right="850"/></w:sectPr></w:body></w:document>',
    );
    return Uint8List.fromList(ZipEncoder().encode(arquivo)!);
  }

  static Uint8List relatorioExcel(
    SessionStore store,
    String id, {
    bool respostas = true,
  }) {
    final a = store.avaliacao(id), key = store.gabarito(id);
    final livro = Excel.createExcel(), notas = livro['Notas'];
    final detalhes = respostas ? livro['Respostas'] : null;
    livro.delete('Sheet1');
    notas.appendRow(
      [
        'Aluno',
        'Matrícula',
        'Turma',
        'Avaliação',
        'Versão',
        'Nota',
        'Acertos',
        if (respostas)
          ...List.generate(a.numQuestoes, (i) => 'Q${i + 1} na folha'),
      ].map(TextCellValue.new).toList(),
    );
    detalhes?.appendRow(
      [
        'Aluno',
        'Matrícula',
        'Versão',
        'Questão na folha',
        'Questão original',
        'Marcada na folha',
        'Marcada original',
        'Correta na folha',
        'Acertou',
      ].map(TextCellValue.new).toList(),
    );
    String letra(int? v) => v == null
        ? 'Em branco'
        : v < 0
        ? 'Revisar'
        : String.fromCharCode(65 + v);
    final lista = [...store.correcoes(id)]
      ..sort((a, b) => a.alunoNome.compareTo(b.alunoNome));
    for (final r in lista) {
      notas.appendRow([
        TextCellValue(r.alunoNome),
        TextCellValue(r.alunoId),
        TextCellValue(a.turma),
        TextCellValue(a.nome),
        TextCellValue(store.rotuloVersao(id, r.variante)),
        DoubleCellValue(r.nota(key, a)),
        IntCellValue(r.acertos(key)),
        if (respostas) ...r.respostas.map((v) => TextCellValue(letra(v))),
      ]);
      if (detalhes == null) continue;
      final gab = r.gabaritoNaFolha(key), base = r.respostasBase;
      for (var i = 0; i < r.respostas.length; i++) {
        final q = r.ordemQuestoes.isEmpty ? i : r.ordemQuestoes[i];
        detalhes.appendRow([
          TextCellValue(r.alunoNome),
          TextCellValue(r.alunoId),
          TextCellValue(store.rotuloVersao(id, r.variante)),
          IntCellValue(i + 1),
          IntCellValue(q + 1),
          TextCellValue(letra(r.respostas[i])),
          TextCellValue(letra(base[q])),
          TextCellValue(letra(gab[i])),
          TextCellValue(
            r.respostas[i] != null && r.respostas[i] == gab[i] ? 'Sim' : 'Não',
          ),
        ]);
      }
    }
    livro.setDefaultSheet('Notas');
    return Uint8List.fromList(livro.encode()!);
  }
}
