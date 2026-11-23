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
    207 + (questao % 20) * 27.0,
  );
  static String codigo(
    String avaliacao,
    String aluno,
    String versao,
    int questoes,
    int alternativas,
  ) => jsonEncode({
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
  const LeituraFolha(
    this.avaliacaoId,
    this.alunoId,
    this.variante,
    this.respostas,
    this.alternativas,
  );
}

/// Usa a geometria da folha antes de tentar ler o QR e as respostas.
LeituraFolha analisarFoto(Map<String, Object?> entrada) {
  final original = img.decodeImage(entrada['bytes'] as Uint8List);
  if (original == null) {
    throw const FormatException('A imagem não pôde ser aberta.');
  }
  var imagem = img.bakeOrientation(original);
  final larguraOriginal = imagem.width, alturaOriginal = imagem.height;
  if (max(imagem.width, imagem.height) > 1800) {
    imagem = img.copyResize(
      imagem,
      width: imagem.width >= imagem.height ? 1800 : null,
      height: imagem.height > imagem.width ? 1800 : null,
    );
  }
  final pixels = _Cinza(imagem);
  final grupos = _gruposDeMarcas(pixels);
  final codigoNativo = entrada['codigo'] as String?;
  final pontosNativos = (entrada['pontosQr'] as List? ?? const [])
      .whereType<Map>()
      .where((p) => p['x'] is num && p['y'] is num)
      .map(
        (p) => Point<double>(
          (p['x'] as num).toDouble() * imagem.width / larguraOriginal,
          (p['y'] as num).toDouble() * imagem.height / alturaOriginal,
        ),
      )
      .toList();
  String? texto;
  _MapaFolha? mapa;
  for (final grupo in grupos.take(4)) {
    for (var giro = 0; giro < 4; giro++) {
      final tentativa = _MapaFolha(_girarMarcas(grupo.pontos, giro));
      if (codigoNativo != null &&
          pontosNativos.length >= 3 &&
          _referenciaQrValida(tentativa, pontosNativos, pixels)) {
        texto = codigoNativo;
        mapa = tentativa;
        break;
      }
      final lido = _lerQrDaFolha(pixels, tentativa);
      if (lido != null) {
        texto = lido;
        mapa = tentativa;
        break;
      }
    }
    if (mapa != null) break;
  }
  if (texto == null || mapa == null) {
    throw const FormatException(
      'Não consegui ler o QR da folha. Tente uma foto mais próxima, com foco, ou selecione o arquivo original.',
    );
  }
  Map<String, dynamic> dados;
  try {
    dados = Map<String, dynamic>.from(jsonDecode(texto) as Map);
  } catch (_) {
    throw const FormatException(
      'Use uma folha de respostas gerada pelo EasyGrade.',
    );
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
      'O QR Code da folha é inválido. Gere o material novamente.',
    );
  }
  final respostas = <int?>[];
  for (var q = 0; q < n; q++) {
    final ajuste = _ajustarLinha(pixels, mapa, q, m);
    if (ajuste.qualidade < .10) {
      respostas.add(-2);
      continue;
    }
    final niveis = <double>[];
    final suspeitos = <double>[];
    for (var a = 0; a < m; a++) {
      final c = FormatoFolha.bolha(q, a);
      final fundo = _fundoBolha(pixels, mapa, c.x + ajuste.dx, c.y + ajuste.dy);
      final limite = fundo - max(16.0, fundo * .22);
      final limiteFraco = fundo - max(8.0, fundo * .10);
      var escuros = 0, fracos = 0, total = 0, totalFraco = 0;
      for (var dx = -3; dx <= 3; dx++) {
        for (var dy = -3; dy <= 3; dy++) {
          if (dx * dx + dy * dy > 9) continue;
          final ponto = mapa.ponto(c.x + ajuste.dx + dx, c.y + ajuste.dy + dy);
          if (!pixels.contem(ponto.x, ponto.y)) {
            throw const FormatException(
              'Parte da folha ficou fora da foto. Tente novamente.',
            );
          }
          final valor = pixels.amostra(ponto.x, ponto.y);
          if (valor < limite) escuros++;
          // Para traços fracos, usa o núcleo para não confundir a borda impressa com tinta.
          if (dx * dx + dy * dy <= 4) {
            if (valor < limiteFraco) fracos++;
            totalFraco++;
          }
          total++;
        }
      }
      niveis.add(escuros / total);
      suspeitos.add(fracos / totalFraco);
    }
    final marcadas = niveis.indexed
        .where((e) => e.$2 >= .50)
        .map((e) => e.$1)
        .toList();
    respostas.add(
      marcadas.length > 1
          ? -1
          : marcadas.length == 1
          ? (suspeitos.indexed.any((e) => e.$1 != marcadas.first && e.$2 > .20)
                ? -2
                : marcadas.first)
          : suspeitos.any((v) => v > .15)
          ? -2
          : null,
    );
  }
  return LeituraFolha(dados['a'], dados['s'], dados['v'], respostas, m);
}

class _Cinza {
  final int w, h;
  late final Uint8List valores;
  late final Uint32List integral;
  _Cinza(img.Image image) : w = image.width, h = image.height {
    valores = Uint8List(w * h);
    integral = Uint32List((w + 1) * (h + 1));
    for (var y = 0; y < h; y++) {
      var soma = 0;
      for (var x = 0; x < w; x++) {
        final valor = img.getLuminance(image.getPixel(x, y)).round();
        valores[y * w + x] = valor;
        soma += valor;
        integral[(y + 1) * (w + 1) + x + 1] =
            integral[y * (w + 1) + x + 1] + soma;
      }
    }
  }
  bool contem(double x, double y) => x >= 0 && y >= 0 && x < w - 1 && y < h - 1;
  double amostra(double x, double y) {
    x = x.clamp(0, w - 1.001);
    y = y.clamp(0, h - 1.001);
    final ix = x.floor(), iy = y.floor();
    final fx = x - ix, fy = y - iy;
    final linha = iy * w + ix;
    return (valores[linha] * (1 - fx) + valores[linha + 1] * fx) * (1 - fy) +
        (valores[linha + w] * (1 - fx) + valores[linha + w + 1] * fx) * fy;
  }

  double media(int x, int y, int raio) {
    final l = max(0, x - raio), r = min(w, x + raio + 1);
    final t = max(0, y - raio), b = min(h, y + raio + 1);
    return (integral[b * (w + 1) + r] -
            integral[t * (w + 1) + r] -
            integral[b * (w + 1) + l] +
            integral[t * (w + 1) + l]) /
        ((r - l) * (b - t));
  }
}

class _Marca {
  final Point<double> centro;
  final int largura, altura;
  final double ocupacao;
  const _Marca(this.centro, this.largura, this.altura, this.ocupacao);
  double get area => (largura * altura).toDouble();
}

class _Grupo {
  final List<Point<double>> pontos;
  final double nota;
  const _Grupo(this.pontos, this.nota);
}

List<Point<double>> localizarMarcas(img.Image imagem) =>
    _gruposDeMarcas(_Cinza(imagem)).first.pontos;

List<_Grupo> _gruposDeMarcas(_Cinza pixels) {
  final w = pixels.w, h = pixels.h;
  final mascara = Uint8List(w * h);
  final raio = (min(w, h) / 40).round().clamp(12, 35);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final fundo = pixels.media(x, y, raio);
      if (pixels.valores[y * w + x] < fundo - max(14.0, fundo * .25)) {
        mascara[y * w + x] = 1;
      }
    }
  }
  final fila = Uint32List(w * h);
  final candidatos = <_Marca>[];
  final maximo = min(w, h) * .055;
  for (var inicio = 0; inicio < mascara.length; inicio++) {
    if (mascara[inicio] != 1) continue;
    var tamanho = 1;
    fila[0] = inicio;
    mascara[inicio] = 2;
    var xmin = inicio % w, xmax = xmin, ymin = inicio ~/ w, ymax = ymin;
    for (var i = 0; i < tamanho; i++) {
      final atual = fila[i], x = atual % w, y = atual ~/ w;
      xmin = min(xmin, x);
      xmax = max(xmax, x);
      ymin = min(ymin, y);
      ymax = max(ymax, y);
      for (final proximo in [
        if (x > 0) atual - 1,
        if (x < w - 1) atual + 1,
        if (y > 0) atual - w,
        if (y < h - 1) atual + w,
      ]) {
        if (mascara[proximo] == 1) {
          mascara[proximo] = 2;
          fila[tamanho++] = proximo;
        }
      }
    }
    final bw = xmax - xmin + 1, bh = ymax - ymin + 1;
    final ocupacao = tamanho / (bw * bh);
    if (bw >= 5 &&
        bh >= 5 &&
        bw < maximo &&
        bh < maximo &&
        bw / bh > .60 &&
        bw / bh < 1.65 &&
        ocupacao > .64) {
      candidatos.add(
        _Marca(Point((xmin + xmax) / 2, (ymin + ymax) / 2), bw, bh, ocupacao),
      );
    }
  }
  final cantos = [
    const Point(0.0, 0.0),
    Point(w.toDouble(), 0.0),
    Point(0.0, h.toDouble()),
    Point(w.toDouble(), h.toDouble()),
  ];
  final opcoes = <List<_Marca>>[];
  for (var i = 0; i < 4; i++) {
    final direita = i % 2 == 1, inferior = i >= 2;
    final lista =
        candidatos
            .where(
              (m) =>
                  (direita ? m.centro.x > w * .30 : m.centro.x < w * .70) &&
                  (inferior ? m.centro.y > h * .30 : m.centro.y < h * .70),
            )
            .toList()
          ..sort(
            (a, b) => a.centro
                .distanceTo(cantos[i])
                .compareTo(b.centro.distanceTo(cantos[i])),
          );
    opcoes.add(lista.take(12).toList());
  }
  final grupos = <_Grupo>[];
  for (final tl in opcoes[0]) {
    for (final tr in opcoes[1]) {
      if (tr.centro.x - tl.centro.x < w * .25) continue;
      for (final bl in opcoes[2]) {
        if (bl.centro.y - tl.centro.y < h * .25) continue;
        for (final br in opcoes[3]) {
          final marcas = [tl, tr, bl, br];
          if (marcas.toSet().length != 4) continue;
          final p = marcas.map((m) => m.centro).toList();
          final topo = p[0].distanceTo(p[1]), base = p[2].distanceTo(p[3]);
          final esquerda = p[0].distanceTo(p[2]),
              direita = p[1].distanceTo(p[3]);
          if (p[3].x <= p[2].x ||
              p[3].y <= p[1].y ||
              max(topo, base) / min(topo, base) > 1.6 ||
              max(esquerda, direita) / min(esquerda, direita) > 1.6) {
            continue;
          }
          final horizontal = (topo + base) / 2,
              vertical = (esquerda + direita) / 2;
          if (horizontal / vertical < .43 || horizontal / vertical > 2.3) {
            continue;
          }
          final prevista = Point(
            p[1].x + p[2].x - p[0].x,
            p[1].y + p[2].y - p[0].y,
          );
          if (prevista.distanceTo(p[3]) > min(horizontal, vertical) * .25) {
            continue;
          }
          final area = _areaPoligono([p[0], p[1], p[3], p[2]]);
          if (area < w * h * .10) continue;
          final esperada = area * 144 / (539 * 786);
          final areas = marcas.map((m) => m.area).toList();
          if (areas.reduce(max) / areas.reduce(min) > 3.0 ||
              areas.any((a) => a / esperada < .40 || a / esperada > 2.1)) {
            continue;
          }
          final erroTamanho =
              areas
                  .map((a) => (log(a / esperada)).abs())
                  .reduce((a, b) => a + b) /
              4;
          final nota =
              area / (w * h) -
              erroTamanho * .15 +
              marcas.map((m) => m.ocupacao).reduce((a, b) => a + b) * .025;
          grupos.add(_Grupo(p, nota));
        }
      }
    }
  }
  grupos.sort((a, b) => b.nota.compareTo(a.nota));
  if (grupos.isEmpty) {
    throw const FormatException(
      'Não consegui localizar as marcas da folha com segurança. Inclua a folha inteira e tente uma foto com mais foco ou iluminação.',
    );
  }
  return grupos;
}

double _areaPoligono(List<Point<double>> p) {
  var soma = 0.0;
  for (var i = 0; i < p.length; i++) {
    final b = p[(i + 1) % p.length];
    soma += p[i].x * b.y - b.x * p[i].y;
  }
  return soma.abs() / 2;
}

List<Point<double>> _girarMarcas(List<Point<double>> p, int giro) {
  final perimetro = [p[0], p[1], p[3], p[2]];
  return [
    perimetro[giro % 4],
    perimetro[(giro + 1) % 4],
    perimetro[(giro + 3) % 4],
    perimetro[(giro + 2) % 4],
  ];
}

class _MapaFolha {
  final List<double> matriz;
  _MapaFolha(List<Point<double>> pontos) : matriz = _projecao(pontos);
  Point<double> ponto(double x, double y) {
    final u = (x - 28) / 539, v = (y - 28) / 786;
    final d = matriz[6] * u + matriz[7] * v + 1;
    return Point(
      (matriz[0] * u + matriz[1] * v + matriz[2]) / d,
      (matriz[3] * u + matriz[4] * v + matriz[5]) / d,
    );
  }
}

bool _referenciaQrValida(
  _MapaFolha mapa,
  List<Point<double>> pontos,
  _Cinza pixels,
) {
  if (pontos.any((p) => !pixels.contem(p.x, p.y))) return false;
  final minx = pontos.map((p) => p.x).reduce(min),
      maxx = pontos.map((p) => p.x).reduce(max);
  final miny = pontos.map((p) => p.y).reduce(min),
      maxy = pontos.map((p) => p.y).reduce(max);
  if (maxx - minx < 8 || maxy - miny < 8) return false;
  final centro = Point((minx + maxx) / 2, (miny + maxy) / 2);
  final esperado = mapa.ponto(502, 114);
  final raio = mapa.ponto(442, 54).distanceTo(mapa.ponto(562, 174)) * .45;
  return centro.distanceTo(esperado) < raio;
}

String? _lerQrDaFolha(_Cinza pixels, _MapaFolha mapa) {
  final hints = DecodeHints()..put(DecodeHintType.tryHarder);
  for (final lado in [360, 540]) {
    final rgb = Int32List(lado * lado);
    for (var y = 0; y < lado; y++) {
      for (var x = 0; x < lado; x++) {
        final p = mapa.ponto(
          442 + (x + .5) * 120 / lado,
          54 + (y + .5) * 120 / lado,
        );
        final l = pixels.amostra(p.x, p.y).round();
        rgb[y * lado + x] = 0xff000000 | l << 16 | l << 8 | l;
      }
    }
    try {
      final r = QRCodeReader().decode(
        BinaryBitmap(HybridBinarizer(RGBLuminanceSource(lado, lado, rgb))),
        hints: hints,
      );
      if (r.text.contains('"eg"')) return r.text;
    } catch (_) {
      /* Tenta a próxima escala sem alterar o arquivo original. */
    }
  }
  return null;
}

double _fundoBolha(_Cinza pixels, _MapaFolha mapa, double x, double y) {
  final amostras = <double>[];
  for (var i = 0; i < 16; i++) {
    final angulo = i * pi / 8;
    final p = mapa.ponto(x + cos(angulo) * 9.5, y + sin(angulo) * 9.5);
    amostras.add(pixels.amostra(p.x, p.y));
  }
  amostras.sort();
  return (amostras[7] + amostras[8]) / 2;
}

({double dx, double dy, double qualidade}) _ajustarLinha(
  _Cinza pixels,
  _MapaFolha mapa,
  int q,
  int alternativas,
) {
  var melhor = (dx: 0.0, dy: 0.0, qualidade: -1.0);
  final fundos = [
    for (var a = 0; a < alternativas; a++)
      _fundoBolha(
        pixels,
        mapa,
        FormatoFolha.bolha(q, a).x,
        FormatoFolha.bolha(q, a).y,
      ),
  ];
  for (final dx in [0.0, -1.5, 1.5, -3.0, 3.0]) {
    for (final dy in [0.0, -1.5, 1.5, -3.0, 3.0]) {
      var qualidade = 0.0;
      for (var a = 0; a < alternativas; a++) {
        final centro = FormatoFolha.bolha(q, a), fundo = fundos[a];
        for (var i = 0; i < 16; i++) {
          final angulo = i * pi / 8;
          var minimo = 255.0;
          for (final raio in [5.4, 6.0, 6.6]) {
            final p = mapa.ponto(
              centro.x + dx + cos(angulo) * raio,
              centro.y + dy + sin(angulo) * raio,
            );
            minimo = min(minimo, pixels.amostra(p.x, p.y));
          }
          qualidade += max(0.0, (fundo - minimo) / max(30.0, fundo));
        }
      }
      qualidade /= alternativas * 16;
      qualidade -= (dx.abs() + dy.abs()) * .002;
      if (qualidade > melhor.qualidade) {
        melhor = (dx: dx, dy: dy, qualidade: qualidade);
      }
    }
  }
  return melhor;
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
