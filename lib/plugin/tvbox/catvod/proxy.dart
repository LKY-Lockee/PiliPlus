import 'dart:convert';

/// com.github.catvod.Proxy
class Proxy {
  /// com.github.catvod.Proxy.port
  static int? _port;

  Proxy._();

  /// com.github.catvod.Proxy.set
  static void set(int port) => _port = port;

  /// com.github.catvod.Proxy.getPort
  static int getPort() => _port ?? 0;

  /// com.github.catvod.Proxy.getUrl
  static String getUrl({bool local = true}) =>
      'http://127.0.0.1:${_port ?? 0}/proxy?do=js';

  /// com.github.tvbox.osc.util.parser.SuperParse.parse
  static String superParseUrl(List<String> jxs, String url) {
    final query = <String>[
      'jxs=${Uri.encodeComponent(jsonEncode(jxs))}',
      'url=${Uri.encodeComponent(url)}',
    ];
    return 'http://127.0.0.1:${_port ?? 0}/superparse?${query.join('&')}';
  }
}
