import 'dart:convert';

/// com.github.tvbox.osc.util.StringUtils
class StringUtils {
  static const _safe =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-*_';

  StringUtils._();

  static String javaUrlEncode(String value) {
    final bytes = utf8.encode(value);
    final buf = StringBuffer();
    for (final b in bytes) {
      if (b == 0x20) {
        buf.write('+');
      } else if (b < 0x80 && _safe.contains(String.fromCharCode(b))) {
        buf.writeCharCode(b);
      } else {
        buf
          ..write('%')
          ..write(b.toRadixString(16).toUpperCase().padLeft(2, '0'));
      }
    }
    return buf.toString();
  }
}
