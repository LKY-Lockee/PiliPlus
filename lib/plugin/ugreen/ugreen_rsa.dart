import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/asn1.dart' as asn1;
import 'package:pointycastle/export.dart' as pc;

class UgreenRsa {
  UgreenRsa._();

  static String? encryptPassword(String password, String publicKey) {
    final pem = _normalizePem(publicKey);
    if (pem == null) {
      return null;
    }
    try {
      final key = enc.RSAKeyParser().parse(pem);
      if (key is! pc.RSAPublicKey) {
        return null;
      }
      final engine = pc.PKCS1Encoding(pc.RSAEngine())
        ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(key));
      final encrypted = engine.process(
        Uint8List.fromList(utf8.encode(password)),
      );
      return base64.encode(encrypted);
    } catch (_) {
      return null;
    }
  }

  static pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>
  generateKeyPair() {
    final random = pc.FortunaRandom()..seed(pc.KeyParameter(_secureSeed()));
    final generator = pc.RSAKeyGenerator()
      ..init(
        pc.ParametersWithRandom(
          pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
          random,
        ),
      );
    final pair = generator.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
      pair.publicKey as pc.RSAPublicKey,
      pair.privateKey as pc.RSAPrivateKey,
    );
  }

  static String publicKeyPem(pc.RSAPublicKey key) {
    final der = asn1.ASN1SubjectPublicKeyInfo(
      asn1.ASN1AlgorithmIdentifier.fromIdentifier('1.2.840.113549.1.1.1'),
      asn1.ASN1BitString(
        stringValues: asn1.ASN1Sequence(
          elements: [
            asn1.ASN1Integer(key.modulus),
            asn1.ASN1Integer(key.publicExponent),
          ],
        ).encode(),
      ),
    ).encode();
    final body = _wrapBase64(base64.encode(der));
    return '-----BEGIN RSA PUBLIC KEY-----\n'
        '$body\n'
        '-----END RSA PUBLIC KEY-----\n';
  }

  static String? decryptToken(
    String token,
    pc.RSAPrivateKey privateKey,
  ) {
    try {
      final engine = pc.PKCS1Encoding(pc.RSAEngine())
        ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
      final decrypted = engine.process(base64.decode(token));
      return utf8.decode(decrypted);
    } catch (_) {
      return null;
    }
  }

  static Uint8List _secureSeed() {
    final random = Random.secure();
    final seed = Uint8List(32);
    for (var i = 0; i < seed.length; i++) {
      seed[i] = random.nextInt(256);
    }
    return seed;
  }

  static String _wrapBase64(String value) {
    final buffer = StringBuffer();
    for (var i = 0; i < value.length; i += 64) {
      if (i > 0) buffer.write('\n');
      buffer.write(
        value.substring(i, min(i + 64, value.length)),
      );
    }
    return buffer.toString();
  }

  static String? _normalizePem(String publicKey) {
    var pem = publicKey.trim();
    if (pem.isEmpty) {
      return null;
    }
    if (!pem.contains('-----BEGIN')) {
      try {
        pem = utf8.decode(base64.decode(pem));
      } catch (_) {
        return null;
      }
    }
    pem = pem
        .replaceFirst('BEGIN RSA PUBLIC KEY', 'BEGIN PUBLIC KEY')
        .replaceFirst('END RSA PUBLIC KEY', 'END PUBLIC KEY')
        .trim();
    if (!pem.contains('-----BEGIN')) {
      pem = '-----BEGIN PUBLIC KEY-----\n$pem\n-----END PUBLIC KEY-----';
    }
    return pem;
  }
}
