import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> _arquivo(String uid) async {
  final pasta = await getApplicationSupportDirectory();
  return File('${pasta.path}/pontuacao-${Uri.encodeComponent(uid)}.txt');
}

Future<int?> lerPontuacaoPadrao(String uid) async {
  final arquivo = await _arquivo(uid);
  return await arquivo.exists()
      ? int.tryParse(await arquivo.readAsString())
      : null;
}

Future<void> gravarPontuacaoPadrao(String uid, int valor) async {
  final arquivo = await _arquivo(uid);
  final temporario = File('${arquivo.path}.novo');
  await temporario.writeAsString('$valor', flush: true);
  await temporario.rename(arquivo.path);
}
