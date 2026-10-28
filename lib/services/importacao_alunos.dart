import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import '../models/correcao.dart';

class ImportacaoAlunos {
  static List<Aluno> texto(String conteudo) =>
      linhas(Csv().decode(conteudo.replaceFirst('\ufeff', '')));

  static List<Aluno> arquivo(Uint8List bytes, String nome) {
    if (bytes.length > 8 * 1024 * 1024) {
      throw const FormatException('Use uma planilha de até 8 MB.');
    }
    if (!nome.toLowerCase().endsWith('.xlsx')) {
      String conteudo;
      try {
        conteudo = utf8.decode(bytes);
      } on FormatException {
        conteudo = latin1.decode(bytes);
      }
      return texto(conteudo);
    }
    final planilha = Excel.decodeBytes(bytes);
    if (planilha.tables.isEmpty) return [];
    final tabela = planilha.tables.values.first;
    return linhas(tabela.rows
        .map((linha) => linha.map((v) => v?.value?.toString() ?? '').toList())
        .toList());
  }

  static List<Aluno> linhas(List<List<dynamic>> linhas) {
    final resultado = <Aluno>[];
    final ids = <String>{};
    var colunaId = 0, colunaNome = 1;
    for (var i = 0; i < linhas.length; i++) {
      final linha = linhas[i].map((v) => v?.toString().trim() ?? '').toList();
      if (linha.every((v) => v.isEmpty)) continue;
      if (i == 0) {
        final campos =
            linha.map((v) => v.toLowerCase().replaceAll('í', 'i')).toList();
        final id = campos.indexOf('matricula'), n = campos.indexOf('nome');
        if (id >= 0 && n >= 0) {
          colunaId = id;
          colunaNome = n;
          continue;
        }
      }
      if (linha.length <= colunaId || linha.length <= colunaNome) {
        throw FormatException('Linha ${i + 1}: informe matrícula e nome.');
      }
      final id = linha[colunaId], nome = linha[colunaNome];
      if (id.isEmpty ||
          nome.isEmpty ||
          id.length > 200 ||
          nome.length > 200 ||
          id.contains('/') ||
          id == '.' ||
          id == '..' ||
          RegExp(r'^__.*__$').hasMatch(id)) {
        throw FormatException('Linha ${i + 1}: confira o nome e a matrícula.');
      }
      if (!ids.add(id)) throw FormatException('Matrícula repetida: $id.');
      resultado.add(Aluno(id, nome));
      if (resultado.length > 1000) {
        throw const FormatException('Importe até 1.000 alunos por vez.');
      }
    }
    return resultado;
  }
}
