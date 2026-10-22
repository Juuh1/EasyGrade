import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Acesso aos documentos privados do professor autenticado.
class FirestoreRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get usuarioId {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Entre na sua conta para acessar os dados.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _perfil =>
      _db.collection('usuarios').doc(usuarioId);

  CollectionReference<Map<String, dynamic>> colecao(String caminho) {
    final partes = caminho.split('/');
    const principais = {
      'avaliacoes',
      'turmas',
      'alunos',
      'questoes',
      'disciplinas'
    };
    const avaliacao = {'gabaritos', 'correcoes', 'variantes', 'materiais'};
    final principal = partes.length == 1 && principais.contains(partes[0]);
    final filha = partes.length == 3 &&
        ((partes[0] == 'avaliacoes' && avaliacao.contains(partes[2])) ||
            (partes[0] == 'turmas' && partes[2] == 'alunos'));
    if (!principal && !filha) throw ArgumentError('Coleção não reconhecida.');
    if (filha) _validarId(partes[1]);
    return _perfil.collection(caminho);
  }

  Stream<List<Map<String, dynamic>>> acompanhar(String caminho) =>
      colecao(caminho).snapshots().map((snapshot) => snapshot.docs
          .map((doc) => {...doc.data(), 'id': doc.id})
          .toList(growable: false));

  Future<List<Map<String, dynamic>>> listar(String caminho) async {
    final snapshot = await colecao(caminho).get();
    return snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList(growable: false);
  }

  Future<Map<String, dynamic>?> obter(String caminho, String id) async {
    _validarId(id);
    final snapshot = await colecao(caminho).doc(id).get();
    final dados = snapshot.data();
    return dados == null ? null : {...dados, 'id': snapshot.id};
  }

  Future<String> criar(String caminho, Map<String, dynamic> dados,
      {String? id}) async {
    if (id != null) _validarId(id);
    final ref = colecao(caminho).doc(id);
    await _db.runTransaction((transaction) async {
      final existente = await transaction.get(ref);
      if (existente.exists) throw StateError('Este registro já existe.');
      transaction.set(ref, _novoDocumento(dados));
    });
    return ref.id;
  }

  Future<void> salvar(String caminho, String id, Map<String, dynamic> dados,
      {bool mesclar = true}) async {
    _validarId(id);
    await _salvar(colecao(caminho).doc(id), dados, mesclar: mesclar);
  }

  Future<void> atualizar(
      String caminho, String id, Map<String, dynamic> dados) async {
    _validarId(id);
    await colecao(caminho).doc(id).update({
      ..._limpar(dados),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> excluir(String caminho, String id) async {
    _validarId(id);
    await colecao(caminho).doc(id).delete();
  }

  Future<Map<String, dynamic>?> obterPerfil() async =>
      (await _perfil.get()).data();

  Future<void> salvarPerfil(Map<String, dynamic> dados) =>
      _salvar(_perfil, dados);

  Future<void> _salvar(
      DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> dados,
      {bool mesclar = true}) async {
    await _db.runTransaction((transaction) async {
      final existente = await transaction.get(ref);
      transaction.set(
          ref,
          {
            ..._limpar(dados),
            'versaoEsquema': 1,
            'criadoEm':
                existente.data()?['criadoEm'] ?? FieldValue.serverTimestamp(),
            'atualizadoEm': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: mesclar));
    });
  }

  Map<String, dynamic> _novoDocumento(Map<String, dynamic> dados) => {
        ..._limpar(dados),
        'versaoEsquema': 1,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _limpar(Map<String, dynamic> dados) =>
      {...dados}..removeWhere((key, _) =>
          {'id', 'criadoEm', 'atualizadoEm', 'versaoEsquema'}.contains(key));

  void _validarId(String id) {
    if (id.isEmpty ||
        id.contains('/') ||
        id == '.' ||
        id == '..' ||
        RegExp(r'^__.*__$').hasMatch(id)) {
      throw ArgumentError('Identificador inválido.');
    }
  }
}
