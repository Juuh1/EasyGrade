import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:easy_grade/services/leitura_folha.dart';

void main() {
  for (final nome in [
    'gabarito.png',
    'gabarito-foto.jpg',
    'gabarito-invertido.jpg',
    'gabarito-perspectiva.jpg'
  ]) {
    test('lê QR e marcações do PDF renderizado: $nome', () {
      final r = analisarFoto(
          {'bytes': File('test/fixtures/leitura/$nome').readAsBytesSync()});
      expect(r.avaliacaoId, 'av1');
      expect(r.alunoId, '@gabarito');
      expect(r.respostas, [0, 1, 2]);
    });
  }
  test('folha do aluno não preenchida retorna respostas em branco', () {
    final r = analisarFoto(
        {'bytes': File('test/fixtures/leitura/folhas.png').readAsBytesSync()});
    expect(r.alunoId, '001');
    expect(r.respostas, [null, null, null]);
  });
  test('imagem sem folha é recusada em vez de inventar respostas', () {
    expect(
        () =>
            analisarFoto({'bytes': File('web/favicon.png').readAsBytesSync()}),
        throwsFormatException);
  });
  test('lê 60 questões nas três colunas', () {
    final r = analisarFoto({
      'bytes': File('test/fixtures/leitura/gabarito60.png').readAsBytesSync()
    });
    expect(r.respostas, List.generate(60, (q) => q % 5));
  });
  test('recusa foto sem QR alinhável mesmo com identificação fornecida', () {
    final imagem = img
        .decodePng(File('test/fixtures/leitura/gabarito.png').readAsBytesSync())!;
    img.fillRect(imagem,
        x1: 900,
        y1: 125,
        x2: 1110,
        y2: 330,
        color: img.ColorRgb8(255, 255, 255));
    expect(
        () => analisarFoto({
              'bytes': img.encodePng(imagem),
              'codigo': FormatoFolha.codigo('av1', '@gabarito', 'A', 3, 4)
            }),
        throwsFormatException);
  });
}
