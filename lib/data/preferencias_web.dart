import 'package:web/web.dart' as web;

Future<int?> lerPontuacaoPadrao(String uid) async => int.tryParse(
  web.window.localStorage.getItem('easygrade.pontuacao.$uid') ?? '',
);

Future<void> gravarPontuacaoPadrao(String uid, int valor) async =>
    web.window.localStorage.setItem('easygrade.pontuacao.$uid', '$valor');
