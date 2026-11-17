import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';
import 'firestore_repository.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirestoreRepository dados;
  Future<void>? _googleInicializado;
  Completer<void>? _cadastroConcluido;
  ({String uid, String nome, String instituicao})? _perfilPendente;

  AuthService({FirebaseAuth? firebaseAuth, FirestoreRepository? repository})
    : auth = firebaseAuth ?? FirebaseAuth.instance,
      dados = repository ?? FirestoreRepository(auth: firebaseAuth);

  Future<void> entrar(String email, String senha) async {
    await auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
  }

  Future<void> cadastrar({
    required String email,
    required String senha,
    required String usuario,
    required String nome,
    required String instituicao,
  }) async {
    if (_cadastroConcluido != null) return;
    final cadastro = _cadastroConcluido = Completer<void>();
    try {
      final credencial = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final user = credencial.user!;
      _perfilPendente = (
        uid: user.uid,
        nome: nome.trim(),
        instituicao: instituicao.trim(),
      );
      await user.updateDisplayName(usuario.trim());
    } finally {
      cadastro.complete();
      _cadastroConcluido = null;
    }
  }

  Future<void> entrarComGoogle() async {
    if (kIsWeb) {
      await auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      );
      return;
    }
    _googleInicializado ??= GoogleSignIn.instance.initialize(
      serverClientId: DefaultFirebaseOptions.googleWebClientId,
    );
    await _googleInicializado;
    final conta = await GoogleSignIn.instance.authenticate();
    final token = conta.authentication.idToken;
    if (token == null) {
      throw StateError('Não foi possível confirmar a conta Google.');
    }
    await auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: token),
    );
  }

  Future<Map<String, dynamic>> carregarPerfil(User user) async {
    await _cadastroConcluido?.future;
    final perfil = await dados.obterPerfil();
    if (perfil != null) return perfil;
    final pendente = _perfilPendente?.uid == user.uid ? _perfilPendente : null;
    final novo = {
      'nome':
          pendente?.nome ??
          user.displayName ??
          user.email?.split('@').first ??
          'Professor',
      'email': user.email ?? '',
      'instituicao': pendente?.instituicao ?? '',
      'reduzirMovimento': false,
    };
    await dados.salvarPerfil(novo);
    if (pendente != null) _perfilPendente = null;
    return novo;
  }

  Future<void> sair() async {
    await auth.signOut();
    if (!kIsWeb && _googleInicializado != null) {
      await GoogleSignIn.instance.signOut();
    }
  }
}

String mensagemAutenticacao(Object erro) {
  if (erro is FirebaseAuthException) {
    return switch (erro.code) {
      'invalid-email' => 'Informe um e-mail válido.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'Confira o e-mail e a senha.',
      'email-already-in-use' => 'Este e-mail já tem uma conta.',
      'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
      'password-does-not-meet-requirements' =>
        'A senha não atende aos requisitos da conta.',
      'network-request-failed' => 'Confira sua conexão e tente novamente.',
      'too-many-requests' => 'Aguarde um pouco antes de tentar novamente.',
      'user-disabled' => 'Esta conta está desativada.',
      'popup-closed-by-user' || 'cancelled-popup-request' => 'Login cancelado.',
      'popup-blocked' => 'Permita a janela de login do Google no navegador.',
      'account-exists-with-different-credential' =>
        'Já existe uma conta com este e-mail. Use outra conta Google ou contate o suporte.',
      'operation-not-allowed' => 'Este método de acesso está indisponível.',
      _ => 'Não foi possível concluir o acesso. Tente novamente.',
    };
  }
  if (erro is GoogleSignInException &&
      erro.code == GoogleSignInExceptionCode.canceled) {
    return 'Login cancelado.';
  }
  return 'Não foi possível concluir o acesso. Tente novamente.';
}
