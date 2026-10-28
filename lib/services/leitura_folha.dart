import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

class FormatoFolha {
  static const largura = 595.0, altura = 842.0;
  static const margem = 28.0;
  static Point<double> bolha(int questao, int alternativa) => Point(
      82 + (questao ~/ 20) * 174 + alternativa * 23.0,
      207 + (questao % 20) * 27.0);
  static String codigo(String avaliacao, String aluno, String versao,
          int questoes, int alternativas) =>
      jsonEncode({
        'eg': 1,
        'a': avaliacao,
        's': aluno,
        'v': versao,
        'n': questoes,
        'm': alternativas,
      });
}

class LeituraFolha {
  final String avaliacaoId, alunoId, variante;
  final List<int?> respostas;
  final int alternativas;
  const LeituraFolha(this.avaliacaoId, this.alunoId, this.variante,
      this.respostas, this.alternativas);
}

LeituraFolha analisarFoto(Map<String, Object?> entrada) {
  var imagem = img.decodeImage(entrada['bytes'] as Uint8List);
  if (imagem == null) {
    throw const FormatException('A imagem não pôde ser aberta.');
  }
  imagem = img.bakeOrientation(imagem);
  if (imagem.height > 1800 || imagem.width > 1800) {
    imagem = img.copyResize(imagem,
        width: imagem.width >= imagem.height ? 1800 : null,
        height: imagem.height > imagem.width ? 1800 : null);
  }
  String? texto = entrada['codigo'] as String?;
  var alinhado = false;
  for (var tentativa = 0; tentativa < 4; tentativa++) {
    try {
      final pixels = imagem!
          .convert(numChannels: 4)
          .getBytes(order: img.ChannelOrder.abgr)
          .buffer
          .asInt32List();
      final qr = QRCodeReader().decode(BinaryBitmap(HybridBinarizer(
          RGBLuminanceSource(imagem.width, imagem.height, pixels))));
      texto = qr.text;
      final pontos = qr.resultPoints;
      if (pontos.isEmpty) {
        throw const FormatException('QR sem referência de orientação.');
      }
      if (pontos.isNotEmpty) {
        final x =
            pontos.map((p) => p.x).reduce((a, b) => a + b) / pontos.length;
        final y =
            pontos.map((p) => p.y).reduce((a, b) => a + b) / pontos.length;
        if (x < imagem.width * .50 || y > imagem.height * .5) {
          if (tentativa == 3) {
            throw const FormatException('Folha desalinhada.');
          }
          imagem = img.copyRotate(imagem, angle: 90);
          continue;
        }
      }
      alinhado = true;
      break;
    } catch (_) {
      if (tentativa == 3) break;
      imagem = img.copyRotate(imagem!, angle: 90);
    }
  }
  if (texto == null || !alinhado) {
    throw const FormatException(
        'Não encontrei o QR Code. Fotografe a folha inteira com boa iluminação.');
  }
  Map<String, dynamic> dados;
  try {
    dados = Map<String, dynamic>.from(jsonDecode(texto) as Map);
  } catch (_) {
    throw const FormatException(
        'Use uma folha de respostas gerada pelo EasyGrade.');
  }
  final n = dados['n'], m = dados['m'];
  if (dados['eg'] != 1 ||
      n is! int ||
      m is! int ||
      n < 1 ||
      n > 60 ||
      m < 2 ||
      m > 5 ||
      dados['a'] is! String ||
      dados['s'] is! String ||
      dados['v'] is! String) {
    throw const FormatException(
        'O QR Code da folha é inválido. Gere o material novamente.');
  }
  final pontos = localizarMarcas(imagem!);
  final matriz = _projecao(pontos);
  Point<double> projetar(double x, double y) {
    final u = (x - 28) / (595 - 56), v = (y - 28) / (842 - 56);
    final d = matriz[6] * u + matriz[7] * v + 1;
    return Point((matriz[0] * u + matriz[1] * v + matriz[2]) / d,
        (matriz[3] * u + matriz[4] * v + matriz[5]) / d);
  }

  final respostas = <int?>[];
  for (var q = 0; q < n; q++) {
    final niveis = <double>[];
    for (var a = 0; a < m; a++) {
      final c = FormatoFolha.bolha(q, a);
      var escuros = 0, total = 0;
      for (var dx = -3; dx <= 3; dx++) {
        for (var dy = -3; dy <= 3; dy++) {
          if (dx * dx + dy * dy > 9) continue;
          final p = projetar(c.x + dx, c.y + dy);
          final x = p.x.round(), y = p.y.round();
          if (x < 0 || y < 0 || x >= imagem.width || y >= imagem.height) {
            throw const FormatException(
                'Parte da folha ficou fora da foto. Tente novamente.');
          }
          final pixel = imagem.getPixel(x, y);
          if (img.getLuminance(pixel) < 135) escuros++;
          total++;
        }
      }
      niveis.add(escuros / total);
    }
    final marcadas =
        niveis.indexed.where((e) => e.$2 >= .50).map((e) => e.$1).toList();
    respostas.add(marcadas.length > 1
        ? -1
        : marcadas.length == 1
            ? (niveis.indexed.any((e) => e.$1 != marcadas.first && e.$2 > .20)
                ? -2
                : marcadas.first)
            : niveis.any((v) => v > .15)
                ? -2
                : null);
  }
  return LeituraFolha(dados['a'], dados['s'], dados['v'], respostas, m);
}

List<Point<double>> localizarMarcas(img.Image imagem) {
  final w = imagem.width, h = imagem.height;
  final vistos = Uint8List(w * h);
  final candidatos = <Point<double>>[];
  bool preto(int x, int y) => img.getLuminance(imagem.getPixel(x, y)) < 85;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final inicio = y * w + x;
      if (vistos[inicio] != 0) continue;
      vistos[inicio] = 1;
      if (!preto(x, y)) continue;
      final fila = <int>[inicio];
      var xmin = x, xmax = x, ymin = y, ymax = y;
      for (var i = 0; i < fila.length; i++) {
        final px = fila[i] % w, py = fila[i] ~/ w;
        xmin = min(xmin, px);
        xmax = max(xmax, px);
        ymin = min(ymin, py);
        ymax = max(ymax, py);
        for (final d in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
          final nx = px + d.$1, ny = py + d.$2;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final index = ny * w + nx;
          if (vistos[index] != 0) continue;
          vistos[index] = 1;
          if (preto(nx, ny)) fila.add(index);
        }
      }
      final bw = xmax - xmin + 1, bh = ymax - ymin + 1;
      if (bw >= 7 &&
          bh >= 7 &&
          bw / bh > .60 &&
          bw / bh < 1.7 &&
          fila.length / (bw * bh) > .73 &&
          bw * bh < w * h * .012) {
        candidatos.add(Point((xmin + xmax) / 2, (ymin + ymax) / 2));
      }
    }
  }
  final cantos = [
    const Point(0.0, 0.0),
    Point(w.toDouble(), 0.0),
    Point(0.0, h.toDouble()),
    Point(w.toDouble(), h.toDouble())
  ];
  final pontos = <Point<double>>[];
  for (final canto in cantos) {
    final opcoes = candidatos
        .where((p) =>
            (p.x < w / 2) == (canto.x == 0) && (p.y < h / 2) == (canto.y == 0))
        .toList()
      ..sort((a, b) => a.distanceTo(canto).compareTo(b.distanceTo(canto)));
    if (opcoes.isEmpty) {
      throw const FormatException(
          'As quatro marcas dos cantos precisam aparecer. Fotografe a folha inteira.');
    }
    pontos.add(opcoes.first);
  }
  if (pontos[0].distanceTo(pontos[1]) < w * .35 ||
      pontos[0].distanceTo(pontos[2]) < h * .35) {
    throw const FormatException(
        'A folha está pequena ou inclinada demais. Aproxime a câmera.');
  }
  return pontos;
}

List<double> _projecao(List<Point<double>> p) {
  final matriz = <List<double>>[];
  for (var i = 0; i < 4; i++) {
    final u = (i % 2).toDouble(),
        v = (i ~/ 2).toDouble(),
        x = p[i].x,
        y = p[i].y;
    matriz.add([u, v, 1, 0, 0, 0, -u * x, -v * x, x]);
    matriz.add([0, 0, 0, u, v, 1, -u * y, -v * y, y]);
  }
  for (var i = 0; i < 8; i++) {
    var melhor = i;
    for (var r = i + 1; r < 8; r++) {
      if (matriz[r][i].abs() > matriz[melhor][i].abs()) melhor = r;
    }
    final troca = matriz[i];
    matriz[i] = matriz[melhor];
    matriz[melhor] = troca;
    final divisor = matriz[i][i];
    if (divisor.abs() < 1e-10) {
      throw const FormatException('Não foi possível alinhar a folha.');
    }
    for (var c = i; c <= 8; c++) {
      matriz[i][c] /= divisor;
    }
    for (var r = 0; r < 8; r++) {
      if (r == i) continue;
      final fator = matriz[r][i];
      for (var c = i; c <= 8; c++) {
        matriz[r][c] -= fator * matriz[i][c];
      }
    }
  }
  return matriz.map((r) => r[8]).toList();
}
