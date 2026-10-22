import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const googleWebClientId =
      '332904949091-4hifr3e9ek4bnituf3ks8ahjt668kbcj.apps.googleusercontent.com';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('O Firebase está configurado para Android e Web.');
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCdGmMgYOXFjYXUm8e_KmFj2c0iP3UvnUM',
    appId: '1:332904949091:web:fe9ef9bd4c8a38383f9f56',
    messagingSenderId: '332904949091',
    projectId: 'easygrade-dc9be',
    authDomain: 'easygrade-dc9be.firebaseapp.com',
    storageBucket: 'easygrade-dc9be.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCdGmMgYOXFjYXUm8e_KmFj2c0iP3UvnUM',
    appId: '1:332904949091:android:e15ba8c6bc1505583f9f56',
    messagingSenderId: '332904949091',
    projectId: 'easygrade-dc9be',
    storageBucket: 'easygrade-dc9be.firebasestorage.app',
  );
}
