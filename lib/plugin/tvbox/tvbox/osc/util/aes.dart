import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

/// com.github.tvbox.osc.util.AES
class AES {
  AES._();

  static List<int> _decrypt(List<int> data, List<int> key, List<int>? iv) {
    final keyStr = utf8.decode(key, allowMalformed: true);
    final encrypter = enc.Encrypter(
      enc.AES(
        enc.Key.fromUtf8(keyStr),
        mode: iv == null ? enc.AESMode.ecb : enc.AESMode.cbc,
        padding: 'PKCS7',
      ),
    );
    return encrypter.decryptBytes(
      enc.Encrypted(Uint8List.fromList(data)),
      iv: iv == null
          ? null
          : enc.IV.fromUtf8(utf8.decode(iv, allowMalformed: true)),
    );
  }

  /// com.github.tvbox.osc.util.AES.rightPadding
  static String rightPadding(String key, String replace, int length) {
    final trimmed = key.trim();
    if (trimmed.length >= length) {
      return trimmed.substring(0, length);
    }
    return trimmed + replace * (length - trimmed.length);
  }

  /// com.github.tvbox.osc.util.AES.toBytes
  static List<int> toBytes(String src) {
    final l = src.length ~/ 2;
    return List<int>.generate(
      l,
      (i) => int.parse(src.substring(i * 2, i * 2 + 2), radix: 16) & 0xFF,
    );
  }

  /// com.github.tvbox.osc.util.AES.isJson
  static bool isJson(String content) => tryDecode(content) != null;

  static dynamic tryDecode(String content) {
    try {
      return jsonDecode(content);
    } catch (_) {}
    try {
      var fixed = content;
      if (fixed.startsWith('\uFEFF')) {
        fixed = fixed.substring(1);
      }
      fixed = fixed.replaceAllMapped(RegExp(r',(\s*[}\]])'), (m) => m[1]!);
      return jsonDecode(fixed);
    } catch (_) {
      return null;
    }
  }

  /// com.github.tvbox.osc.util.AES.ECB
  static List<int> ecb(List<int> data, List<int> key) =>
      _decrypt(data, key, null);

  /// com.github.tvbox.osc.util.AES.CBC
  static List<int> cbc(List<int> data, List<int> key, List<int> iv) =>
      _decrypt(data, key, iv);
}
