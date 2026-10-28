import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../data/session_store.dart';
import '../models/correcao.dart';
import 'leitura_folha.dart';

class ArquivosService {
  static Future<void> compartilhar(
      Uint8List bytes, String nome, String tipo) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(bytes, mimeType: tipo)],
      fileNameOverrides: [nome],
    ));
  }

  static String versaoAluno(SessionStore store, String id, String aluno) =>
      store.variantes(id).where((v) => v['alunoId'] == aluno).firstOrNull?['id']
          as String? ??
      'A';

  static List<int> ordem(SessionStore store, String id, String versao) =>
      (store.variante(id, versao)?['ordemQuestoes'] as List?)
          ?.map((v) => (v as num).toInt())
          .toList() ??
      List.generate(store.avaliacao(id).numQuestoes, (i) => i);

  static List<List<int>> alternativas(
      SessionStore store, String id, String versao) {
    final a = store.avaliacao(id);
    final salvo = store.variante(id, versao)?['ordemAlternativas'];
    return salvo == null
        ? List.generate(
            a.numQuestoes, (_) => List.generate(a.numAlternativas, (i) => i))
        : Correcao.lerOrdens(salvo);
  }

  static Future<Uint8List> folhasPDF(SessionStore store, String id,
      {List<Aluno>? alunos, bool gabarito = false}) async {
    final a = store.avaliacao(id);
    final fonte =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Manrope.ttf'));
    final doc =
        pw.Document(theme: pw.ThemeData.withFont(base: fonte, bold: fonte));
    final lista = gabarito
        ? [const Aluno('@gabarito', 'Gabarito de referência')]
        : alunos ?? store.alunos(a.turma);
    if (lista.isEmpty) {
      throw StateError(
          'Cadastre pelo menos um aluno para gerar as folhas identificadas.');
    }
    for (final aluno in lista) {
      final versao = gabarito ? 'A' : versaoAluno(store, id, aluno.id);
      final codigo = FormatoFolha.codigo(
          id, aluno.id, versao, a.numQuestoes, a.numAlternativas);
      doc.addPage(pw.Page(
          pageFormat: const PdfPageFormat(595, 842),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.SizedBox(
              width: 595,
              height: 842,
              child: pw.Stack(children: [
                for (final x in [28.0, 567.0])
                  for (final y in [28.0, 814.0])
                    pw.Positioned(
                        left: x - 6,
                        top: y - 6,
                        child: pw.Container(
                            width: 12, height: 12, color: PdfColors.black)),
                pw.Positioned(
                    left: 46,
                    top: 55,
                    child: pw.Text('easygrade',
                        style: const pw.TextStyle(
                            fontSize: 24,
                            color: PdfColor.fromInt(0xff51369a)))),
                pw.Positioned(
                    left: 46,
                    top: 96,
                    child: pw.SizedBox(
                        width: 380,
                        child: pw.Text(a.nome,
                            style: const pw.TextStyle(fontSize: 14)))),
                pw.Positioned(
                    left: 46,
                    top: 128,
                    child: pw.SizedBox(
                        width: 380,
                        child: pw.Text(
                            '${aluno.nome}\nMatrícula: ${aluno.id}   |   ${a.turma}   |   Versão $versao',
                            style: const pw.TextStyle(fontSize: 10)))),
                pw.Positioned(
                    left: 454,
                    top: 66,
                    child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: codigo,
                        width: 96,
                        height: 96)),
                for (var col = 0; col < (a.numQuestoes + 19) ~/ 20; col++)
                  for (var alt = 0; alt < a.numAlternativas; alt++)
                    pw.Positioned(
                        left: 78 + col * 174 + alt * 23.0,
                        top: 179,
                        child: pw.Text(String.fromCharCode(65 + alt),
                            style: const pw.TextStyle(fontSize: 9))),
                for (var q = 0; q < a.numQuestoes; q++) ...[
                  pw.Positioned(
                      left: 47 + (q ~/ 20) * 174.0,
                      top: FormatoFolha.bolha(q, 0).y - 5,
                      child: pw.Text('${q + 1}'.padLeft(2, '0'),
                          style: const pw.TextStyle(fontSize: 9))),
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
                                color: gabarito && store.gabarito(id)[q] == alt
                                    ? PdfColors.black
                                    : PdfColors.white))),
                ],
                pw.Positioned(
                    left: 46,
                    top: 764,
                    child: pw.SizedBox(
                        width: 500,
                        child: pw.Text(
                            'Preencha uma única bolha por questão com caneta preta ou azul. Não dobre nem cubra as quatro marcas dos cantos. Fotografe a folha inteira.',
                            style: const pw.TextStyle(fontSize: 9)))),
              ]))));
    }
    return doc.save();
  }

  static Future<Uint8List> cadernoPDF(SessionStore store, String id,
      {List<Aluno>? alunos}) async {
    final a = store.avaliacao(id), questoes = store.questoes(id);
    if (questoes.length != a.numQuestoes) {
      throw StateError('Selecione todas as questões antes de gerar o caderno.');
    }
    final fonte =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Manrope.ttf'));
    final doc =
        pw.Document(theme: pw.ThemeData.withFont(base: fonte, bold: fonte));
    final lista = alunos ?? store.alunos(a.turma);
    if (lista.isEmpty) {
      throw StateError('Cadastre os alunos para gerar os cadernos.');
    }
    for (final aluno in lista) {
      final v = versaoAluno(store, id, aluno.id),
          oq = ordem(store, id, v),
          oa = alternativas(store, id, v);
      final paginas = store.paginas(id);
      for (final pagina in paginas.toSet().toList()..sort()) {
        doc.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          header: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(a.nome, style: const pw.TextStyle(fontSize: 18)),
                pw.Text('${aluno.nome} · ${aluno.id}\n${a.turma} · Versão $v',
                    style: const pw.TextStyle(fontSize: 10)),
                pw.Divider(),
                pw.SizedBox(height: 12),
              ]),
          footer: (context) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('EasyGrade · ${context.pageNumber}',
                  style: const pw.TextStyle(fontSize: 9))),
          build: (_) => [
            for (var i = 0; i < a.numQuestoes; i++)
              if (paginas[i] == pagina)
                pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 22),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${i + 1}. ${questoes[oq[i]].enunciado}',
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.SizedBox(height: 8),
                          for (var alt = 0; alt < a.numAlternativas; alt++)
                            pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 5),
                                child: pw.Text(
                                    '${String.fromCharCode(65 + alt)}) ${questoes[oq[i]].alternativas[oa[i][alt]]}',
                                    style: const pw.TextStyle(fontSize: 10))),
                        ]))
          ],
        ));
      }
    }
    return doc.save();
  }

  static Uint8List cadernoWord(SessionStore store, String id) {
    final a = store.avaliacao(id), questoes = store.questoes(id);
    if (questoes.length != a.numQuestoes) {
      throw StateError('Selecione todas as questões antes de gerar o Word.');
    }
    final b = StringBuffer();
    String xml(String v) => const HtmlEscape(HtmlEscapeMode.element).convert(v);
    void par(String texto, {bool manter = false, bool quebra = false}) => b.write(
        '<w:p><w:pPr><w:keepLines/>${manter ? '<w:keepNext/>' : ''}${quebra ? '<w:pageBreakBefore/>' : ''}</w:pPr><w:r><w:t xml:space="preserve">${xml(texto)}</w:t></w:r></w:p>');
    final alunos = store.alunos(a.turma);
    if (alunos.isEmpty) {
      throw StateError('Cadastre os alunos antes de gerar os cadernos.');
    }
    for (var s = 0; s < alunos.length; s++) {
      final aluno = alunos[s], v = versaoAluno(store, id, aluno.id);
      final oq = ordem(store, id, v),
          oa = alternativas(store, id, v),
          paginas = store.paginas(id);
      par(a.nome, manter: true, quebra: s > 0);
      par('${aluno.nome} · ${aluno.id} · ${a.turma} · Versão $v', manter: true);
      for (var i = 0; i < a.numQuestoes; i++) {
        par('${i + 1}. ${questoes[oq[i]].enunciado}',
            manter: true, quebra: i > 0 && paginas[i] != paginas[i - 1]);
        for (var alt = 0; alt < a.numAlternativas; alt++) {
          par('${String.fromCharCode(65 + alt)}) ${questoes[oq[i]].alternativas[oa[i][alt]]}',
              manter: alt < a.numAlternativas - 1);
        }
        par('');
      }
    }
    final arquivo = Archive();
    void adicionar(String nome, String conteudo) {
      final bytes = utf8.encode(conteudo);
      arquivo.addFile(ArchiveFile(nome, bytes.length, bytes));
    }

    adicionar('[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>');
    adicionar('_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>');
    adicionar('word/document.xml',
        '<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$b<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="850" w:bottom="850" w:left="850" w:right="850"/></w:sectPr></w:body></w:document>');
    return Uint8List.fromList(ZipEncoder().encode(arquivo)!);
  }

  static Uint8List relatorioExcel(SessionStore store, String id,
      {bool respostas = true}) {
    final a = store.avaliacao(id), key = store.gabarito(id);
    final livro = Excel.createExcel(),
        notas = livro['Notas'],
        detalhes = livro['Respostas'];
    livro.delete('Sheet1');
    notas.appendRow([
      'Aluno',
      'Matrícula',
      'Turma',
      'Avaliação',
      'Versão',
      'Nota',
      'Acertos',
      if (respostas)
        ...List.generate(a.numQuestoes, (i) => 'Q${i + 1} na folha')
    ].map(TextCellValue.new).toList());
    detalhes.appendRow([
      'Aluno',
      'Matrícula',
      'Versão',
      'Questão na folha',
      'Questão original',
      'Marcada na folha',
      'Marcada original',
      'Correta na folha',
      'Acertou'
    ].map(TextCellValue.new).toList());
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
        TextCellValue(r.variante),
        DoubleCellValue(r.nota(key)),
        IntCellValue(r.acertos(key)),
        if (respostas) ...r.respostas.map((v) => TextCellValue(letra(v)))
      ]);
      final gab = r.gabaritoNaFolha(key), base = r.respostasBase;
      for (var i = 0; i < r.respostas.length; i++) {
        final q = r.ordemQuestoes.isEmpty ? i : r.ordemQuestoes[i];
        detalhes.appendRow([
          TextCellValue(r.alunoNome),
          TextCellValue(r.alunoId),
          TextCellValue(r.variante),
          IntCellValue(i + 1),
          IntCellValue(q + 1),
          TextCellValue(letra(r.respostas[i])),
          TextCellValue(letra(base[q])),
          TextCellValue(letra(gab[i])),
          TextCellValue(r.respostas[i] != null && r.respostas[i] == gab[i]
              ? 'Sim'
              : 'Não')
        ]);
      }
    }
    livro.setDefaultSheet('Notas');
    return Uint8List.fromList(livro.encode()!);
  }
}
