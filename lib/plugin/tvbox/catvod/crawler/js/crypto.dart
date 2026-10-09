import 'dart:convert';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/rsa/rsa_encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' as pc;

/// com.github.catvod.crawler.js.Crypto
class Crypto {
  Crypto._();

  static List<int> _padKey(List<int> bytes, int length) {
    if (bytes.length >= length) return bytes;
    return [...bytes, ...List.filled(length - bytes.length, 0)];
  }

  /// com.github.catvod.crawler.js.Crypto.aes
  static String aes(
    String mode,
    bool isEncrypt,
    String input,
    bool inBase64,
    String key,
    String? iv,
    bool outBase64,
  ) {
    try {
      final parts = mode.split('/');
      if (parts.length != 3 || parts[0].toUpperCase() != 'AES') return '';
      final m = parts[1].toUpperCase();
      final p = parts[2].toUpperCase();
      if (p != 'NO' && p != 'PKCS5' && p != 'PKCS7') return '';
      final noPadding = p == 'NO';

      final keyBytes = _padKey(utf8.encode(key), 16);
      final ivBytes = iv == null ? null : _padKey(utf8.encode(iv), 16);
      if (ivBytes != null && m == 'ECB') return '';

      pc.BlockCipher base;
      switch (m) {
        case 'ECB':
          base = pc.ECBBlockCipher(pc.AESEngine());
          break;
        case 'CBC':
          base = pc.CBCBlockCipher(pc.AESEngine());
          break;
        case 'CFB':
          base = pc.CFBBlockCipher(pc.AESEngine(), 16);
          break;
        case 'OFB':
          base = pc.OFBBlockCipher(pc.AESEngine(), 16);
          break;
        case 'CTR':
          base = pc.SICBlockCipher(16, pc.SICStreamCipher(pc.AESEngine()));
          break;
        default:
          return '';
      }
      final isStream = m == 'CFB' || m == 'OFB' || m == 'CTR';
      if (isStream && !noPadding) return '';

      final Uint8List inBytes = inBase64
          ? base64.decode(input.replaceAll('_', '/').replaceAll('-', '+'))
          : Uint8List.fromList(utf8.encode(input));
      final keyParam = pc.KeyParameter(Uint8List.fromList(keyBytes));
      final pc.CipherParameters params = ivBytes == null
          ? keyParam
          : pc.ParametersWithIV<pc.KeyParameter>(
              keyParam,
              Uint8List.fromList(ivBytes),
            );

      Uint8List outBytes;
      if (noPadding) {
        final bs = base.blockSize;
        final rem = inBytes.length % bs;
        if (rem != 0 && !isStream) return '';
        final inputBuf = rem == 0
            ? inBytes
            : Uint8List.fromList([
                ...inBytes,
                ...List.filled(bs - rem, 0),
              ]);
        base.init(isEncrypt, params);
        final full = Uint8List(inputBuf.length);
        for (var off = 0; off < inputBuf.length; off += bs) {
          base.processBlock(inputBuf, off, full, off);
        }
        outBytes = inputBuf.length == inBytes.length
            ? full
            : Uint8List.sublistView(full, 0, inBytes.length);
      } else {
        outBytes =
            (pc.PaddedBlockCipherImpl(pc.PKCS7Padding(), base)..init(
                  isEncrypt,
                  pc.PaddedBlockCipherParameters(params, null),
                ))
                .process(inBytes);
      }
      return outBase64
          ? base64Encode(outBytes)
          : utf8.decode(outBytes, allowMalformed: true);
    } catch (e) {
      debugPrint('[tvbox-js] aesX error: $e');
      return '';
    }
  }

  /// com.github.catvod.crawler.js.Crypto.rsa
  static String rsa(
    bool pub,
    bool isEncrypt,
    String input,
    bool inBase64,
    String keyPem,
    bool outBase64,
  ) =>
      RSAEncrypt.process(
        pub,
        isEncrypt,
        input,
        inBase64,
        keyPem,
        outBase64,
        config: 'RSA/ECB/PKCS1Padding',
        long: 2,
        block: true,
      ) ??
      '';
}
