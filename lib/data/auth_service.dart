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

  AuthService({FirebaseAuth? firebaseAuth, FirestoreRepository? repository})
      : auth = firebaseAuth ?? FirebaseAuth.instance,
        dados = repository ?? FirestoreRepository(auth: firebaseAuth);

  Future<void> entrar(String email, String senha) async {
    await auth.signInWithEmailAndPassword(email: email.trim(), password: senha);
  }

  Future<void> entrarComGoogle() async {
    if (kIsWeb) {
      await auth.signInWithPopup(GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'}));
      return;
    }
    _googleInicializado ??= GoogleSignIn.instance
        .initialize(serverClientId: DefaultFirebaseOptions.googleWebClientId);
    await _googleInicializado;
    final conta = await GoogleSignIn.instance.authenticate();
    final token = conta.authentication.idToken;
    if (token == null) {
      throw StateError('Não foi possível confirmar a conta Google.');
    }
    await auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: token));
  }

  Future<void> cadastrar(
      String nome, String email, String senha, String instituicao) async {
    final cadastro = _cadastroConcluido = Completer<void>();
    try {
      final credencial = await auth.createUserWithEmailAndPassword(
          email: email.trim(), password: senha);
      await credencial.user!.updateDisplayName(nome.trim());
      await dados.salvarPerfil({
        'nome': nome.trim(),
        'email': credencial.user!.email,
        'instituicao': instituicao.trim(),
        'reduzirMovimento': false,
      });
    } finally {
      cadastro.complete();
      _cadastroConcluido = null;
    }
  }

  Future<Map<String, dynamic>> carregarPerfil(User user) async {
    await _cadastroConcluido?.future;
    final perfil = await dados.obterPerfil();
    if (perfil != null) return perfil;
    final novo = {
      'nome': user.displayName ?? user.email?.split('@').first ?? 'Professor',
      'email': user.email ?? '',
      'instituicao': '',
      'reduzirMovimento': false,
    };
    await dados.salvarPerfil(novo);
    return novo;
  }

  Future<void> recuperarSenha(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (erro) {
      if (erro.code != 'user-not-found') rethrow;
    }
  }

  bool get usaSenha =>
      auth.currentUser?.providerData.any((v) => v.providerId == 'password') ==
      true;

  Future<void> alterarSenha(String atual, String nova) async {
    final user = auth.currentUser;
    if (user?.email == null) {
      throw StateError('Entre novamente para alterar sua senha.');
    }
    if (nova.length < 6) throw ArgumentError('Use pelo menos 6 caracteres.');
    await user!.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: atual));
    await user.updatePassword(nova);
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
      'wrong-password' =>
        'Confira o e-mail e a senha.',
      'email-already-in-use' =>
        'Este e-mail já tem uma conta. Entre ou recupere sua senha.',
      'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
      'network-request-failed' => 'Confira sua conexão e tente novamente.',
      'too-many-requests' => 'Aguarde um pouco antes de tentar novamente.',
      'user-disabled' => 'Esta conta está desativada.',
      'popup-closed-by-user' || 'cancelled-popup-request' => 'Login cancelado.',
      'popup-blocked' => 'Permita a janela de login do Google no navegador.',
      'account-exists-with-different-credential' =>
        'Entre pelo método já associado a este e-mail.',
      'operation-not-allowed' =>
        'Este método de acesso ainda não está habilitado.',
      _ => 'Não foi possível concluir o acesso. Tente novamente.',
    };
  }
  if (erro is GoogleSignInException &&
      erro.code == GoogleSignInExceptionCode.canceled) {
    return 'Login cancelado.';
  }
  return 'Não foi possível concluir o acesso. Tente novamente.';
}
