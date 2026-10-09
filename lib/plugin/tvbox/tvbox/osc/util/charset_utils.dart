import 'dart:convert';

import 'package:gbk_codec/gbk_codec.dart';

/// com.github.tvbox.osc.util.CharsetUtils
class CharsetUtils {
  CharsetUtils._();

  /// com.github.tvbox.osc.util.CharsetUtils.detect
  static String decodeBytes(List<int> bytes, String? contentType) {
    final cs = RegExp(
      r'charset\s*=\s*"?([\w-]+)"?',
      caseSensitive: false,
    ).firstMatch(contentType ?? '')?.group(1)?.toLowerCase();
    if (cs == 'gbk' || cs == 'gb2312' || cs == 'gb18030') {
      return gbk_bytes.decode(bytes);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
