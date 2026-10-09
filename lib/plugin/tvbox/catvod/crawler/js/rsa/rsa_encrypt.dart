import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;

/// com.github.catvod.crawler.js.rsa.RSAEncrypt
class RSAEncrypt {
  RSAEncrypt._();

  static String _normalizePem(bool pub, String key) {
    if (key.contains('-----BEGIN')) return key;
    final begin = pub
        ? '-----BEGIN PUBLIC KEY-----'
        : '-----BEGIN PRIVATE KEY-----';
    final end = pub ? '-----END PUBLIC KEY-----' : '-----END PRIVATE KEY-----';
    return '$begin\n$key\n$end';
  }

  /// com.github.catvod.crawler.js.rsa.RSAEncrypt.encryptByPublicKey
  /// com.github.catvod.crawler.js.rsa.RSAEncrypt.decryptByPrivateKey
  /// com.github.catvod.crawler.js.rsa.RSAEncrypt.encryptByPrivateKey
  /// com.github.catvod.crawler.js.rsa.RSAEncrypt.decryptByPublicKey
  static String? process(
    bool pub,
    bool encrypt,
    String input,
    bool inBase64,
    String keyPem,
    bool outBase64, {
    String? config,
    int long = 1,
    bool block = true,
  }) {
    try {
      final rsaKey = enc.RSAKeyParser().parse(_normalizePem(pub, keyPem));
      if (pub && rsaKey is! pc.RSAPublicKey) return null;
      if (!pub && rsaKey is! pc.RSAPrivateKey) return null;

      final cfg = (config ?? 'RSA/ECB/PKCS1Padding').toLowerCase();
      pc.AsymmetricBlockCipher engine;
      if (cfg.contains('nopadding')) {
        engine = pc.RSAEngine();
      } else if (cfg.contains('oaep')) {
        engine = cfg.contains('sha-256')
            ? pc.OAEPEncoding.withSHA256(pc.RSAEngine())
            : pc.OAEPEncoding.withSHA1(pc.RSAEngine());
      } else if (cfg.contains('pkcs1')) {
        engine = pc.PKCS1Encoding(pc.RSAEngine());
      } else {
        return null;
      }
      engine.init(
        encrypt,
        pub
            ? pc.PublicKeyParameter<pc.RSAPublicKey>(rsaKey as pc.RSAPublicKey)
            : pc.PrivateKeyParameter<pc.RSAPrivateKey>(
                rsaKey as pc.RSAPrivateKey,
              ),
      );

      final Uint8List inBytes = inBase64
          ? base64.decode(input.replaceAll('_', '/').replaceAll('-', '+'))
          : Uint8List.fromList(utf8.encode(input));
      if (inBytes.isEmpty) return '';

      final out = BytesBuilder();
      if (long == 1) {
        out.add(engine.process(inBytes));
      } else {
        final modulusBytes =
            (pub
                ? (rsaKey as pc.RSAPublicKey).modulus!.bitLength
                : (rsaKey as pc.RSAPrivateKey).modulus!.bitLength) ~/
            8;
        final blockLen = encrypt
            ? (block ? modulusBytes - 11 : 117)
            : (block ? modulusBytes : 128);
        for (var i = 0; i < inBytes.length; i += blockLen) {
          final end = min(i + blockLen, inBytes.length);
          out.add(engine.process(Uint8List.fromList(inBytes.sublist(i, end))));
        }
      }
      final outBytes = out.takeBytes();
      if (outBase64) {
        return base64Encode(outBytes);
      }
      return utf8.decode(outBytes, allowMalformed: true);
    } catch (e) {
      debugPrint('[tvbox-js] rsa error: $e');
      return null;
    }
  }
}
