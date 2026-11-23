import 'dart:io';
import 'package:easy_grade/services/leitura_folha.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const mateus = [2, 3, 1, 3, 1, 0, 3, 1, 3, 0, 3, 3, 2, 0, 2, 1, 2, 2, 1, 3];
  const isabela = [1, 3, 0, 2, 2, 0, 3, 1, 2, 3, 0, 1, 3, 2, 0, 1, 3, 2, 0, 0];
  for (var i = 1; i <= 7; i++) {
    test('foto real $i: identifica a folha e as 20 marcações sob sombra', () {
      final arquivo =
          'test/fixtures/leitura/fotos_reais/foto-${i.toString().padLeft(2, '0')}.jpeg';
      final leitura = analisarFoto({'bytes': File(arquivo).readAsBytesSync()});
      final modeloB = [1, 2, 4, 7].contains(i);
      expect(leitura.avaliacaoId, 'simulado-engenharia');
      expect(leitura.alunoId, modeloB ? 'DEMO009' : 'DEMO008');
      expect(leitura.variante, 'ogeysuoiwpahrh-${modeloB ? 'B' : 'A'}');
      expect(leitura.alternativas, 4);
      expect(leitura.respostas, modeloB ? mateus : isabela);
    });
  }

  for (final angulo in [90, 180, 270]) {
    test(
      'foto real girada $angulo graus preserva aluno, modelo e respostas',
      () {
        final original = img.decodeJpg(
          File(
            'test/fixtures/leitura/fotos_reais/foto-06.jpeg',
          ).readAsBytesSync(),
        )!;
        final girada = img.copyRotate(original, angle: angulo);
        final leitura = analisarFoto({
          'bytes': img.encodeJpg(girada, quality: 90),
        });
        expect(leitura.alunoId, 'DEMO008');
        expect(leitura.respostas, isabela);
      },
    );
  }

  img.Image referencia() => img.decodePng(
    File('test/fixtures/leitura/gabarito.png').readAsBytesSync(),
  )!;
  void preencher(img.Image imagem, int questao, int alternativa, int tom) {
    final centro = FormatoFolha.bolha(questao, alternativa);
    img.fillCircle(
      imagem,
      x: (centro.x * imagem.width / FormatoFolha.largura).round(),
      y: (centro.y * imagem.height / FormatoFolha.altura).round(),
      radius: (4 * imagem.width / FormatoFolha.largura).round(),
      color: img.ColorRgb8(tom, tom, tom),
    );
  }

  test('resposta dupla continua marcada para revisão', () {
    final imagem = referencia();
    preencher(imagem, 0, 1, 0);
    final leitura = analisarFoto({'bytes': img.encodePng(imagem)});
    expect(leitura.respostas, [-1, 1, 2]);
  });
  test('marca fraca em alternativa concorrente exige revisão', () {
    final imagem = referencia();
    preencher(imagem, 0, 1, 205);
    final leitura = analisarFoto({'bytes': img.encodePng(imagem)});
    expect(leitura.respostas, [-2, 1, 2]);
  });
  test('marca fraca sozinha não é convertida em resposta em branco', () {
    final imagem = img.decodePng(
      File('test/fixtures/leitura/folhas.png').readAsBytesSync(),
    )!;
    preencher(imagem, 0, 1, 205);
    final leitura = analisarFoto({'bytes': img.encodePng(imagem)});
    expect(leitura.respostas, [-2, null, null]);
  });

  test(
    'QR nativo com referência válida dispensa uma segunda decodificação',
    () {
      final imagem = referencia();
      final sx = imagem.width / FormatoFolha.largura;
      final sy = imagem.height / FormatoFolha.altura;
      img.fillRect(
        imagem,
        x1: (450 * sx).round(),
        y1: (62 * sy).round(),
        x2: (554 * sx).round(),
        y2: (166 * sy).round(),
        color: img.ColorRgb8(255, 255, 255),
      );
      final leitura = analisarFoto({
        'bytes': img.encodePng(imagem),
        'codigo': FormatoFolha.codigo('av1', '@gabarito', 'A', 3, 4),
        'pontosQr': [
          for (final ponto in [(454, 66), (550, 66), (550, 162), (454, 162)])
            {'x': ponto.$1 * sx, 'y': ponto.$2 * sy},
        ],
      });
      expect(leitura.alunoId, '@gabarito');
      expect(leitura.respostas, [0, 1, 2]);
    },
  );

  test('referência nativa fora da posição do QR não libera a leitura', () {
    final imagem = referencia();
    final sx = imagem.width / FormatoFolha.largura;
    final sy = imagem.height / FormatoFolha.altura;
    img.fillRect(
      imagem,
      x1: (450 * sx).round(),
      y1: (62 * sy).round(),
      x2: (554 * sx).round(),
      y2: (166 * sy).round(),
      color: img.ColorRgb8(255, 255, 255),
    );
    expect(
      () => analisarFoto({
        'bytes': img.encodePng(imagem),
        'codigo': FormatoFolha.codigo('av1', '@gabarito', 'A', 3, 4),
        'pontosQr': [
          {'x': 20, 'y': 20},
          {'x': 40, 'y': 20},
          {'x': 40, 'y': 40},
          {'x': 20, 'y': 40},
        ],
      }),
      throwsFormatException,
    );
  });
}
