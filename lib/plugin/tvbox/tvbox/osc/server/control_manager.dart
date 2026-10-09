import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/plugin/tvbox/catvod/proxy.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/parser/super_parse.dart';

typedef ProxyInvoker = Future<Object?> Function(Map<String, String> params);

/// com.github.tvbox.osc.server.ControlManager
class ControlManager {
  /// com.github.tvbox.osc.server.ControlManager.mServer
  HttpServer? _server;

  ProxyInvoker? _proxyInvoker;

  /// com.github.tvbox.osc.server.ControlManager.get
  static final ControlManager instance = ControlManager._();

  ControlManager._();

  Future<void> _handleSuperParse(HttpRequest req) async {
    try {
      final params = req.uri.queryParameters;
      List<String> jxs;
      try {
        jxs = (jsonDecode(params['jxs'] ?? '[]') as List)
            .map((e) => e.toString())
            .toList();
      } catch (_) {
        jxs = const [];
      }
      final url = params['url'] ?? '';
      req.response.statusCode = 200;
      req.response.headers.set(
        HttpHeaders.contentTypeHeader,
        'text/html; charset=utf-8',
      );
      req.response.write(SuperParse.loadHtml(jxs, url));
      await req.response.close();
    } catch (e) {
      try {
        req.response.statusCode = 500;
        req.response.write('$e');
        await req.response.close();
      } catch (_) {}
    }
  }

  Future<void> _onRequest(HttpRequest req) async {
    try {
      final uri = req.uri;
      if (uri.path == '/superparse') {
        await _handleSuperParse(req);
        return;
      }
      if (uri.path != '/proxy') {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      final params = uri.queryParameters;
      if (params['do'] != 'js') {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      final siteKey = params['siteKey'] ?? '';
      if (siteKey.isEmpty || siteKey == 'undefined') {
        req.response.statusCode = 400;
        req.response.write('missing siteKey');
        await req.response.close();
        return;
      }
      final invoker = _proxyInvoker;
      final result = invoker == null ? null : await invoker(params);
      if (result is! List || result.isEmpty) {
        req.response.statusCode = 502;
        req.response.write('proxy failed');
        await req.response.close();
        return;
      }
      final code = (result[0] is num) ? (result[0] as num).toInt() : 200;
      final contentType = result.length > 1
          ? result[1]?.toString() ?? 'text/plain; charset=utf-8'
          : 'text/plain; charset=utf-8';
      final rawContent = result.length > 2 ? result[2] : null;
      final flag = result.length > 4 && result[4] == 1;
      req.response.statusCode = code < 200 || code > 599 ? 200 : code;
      req.response.headers.set(
        HttpHeaders.contentTypeHeader,
        contentType,
      );
      final headers = result.length > 3 && result[3] is Map
          ? result[3] as Map
          : null;
      if (headers != null) {
        headers.forEach((k, v) {
          try {
            req.response.headers.set(k.toString(), v.toString());
          } catch (_) {}
        });
      }
      if (rawContent is List<int>) {
        req.response.add(rawContent);
      } else if (flag) {
        req.response.add(base64Decode(rawContent?.toString() ?? ''));
      } else {
        req.response.write(rawContent?.toString() ?? '');
      }
      await req.response.close();
    } catch (e) {
      try {
        req.response.statusCode = 500;
        req.response.write('proxy error: $e');
        await req.response.close();
      } catch (_) {}
    }
  }

  /// com.github.tvbox.osc.server.ControlManager.startServer
  Future<int> ensureServer({ProxyInvoker? onProxy}) async {
    if (onProxy != null) _proxyInvoker = onProxy;
    final server = _server;
    if (server != null) return server.port;
    final bound = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = bound;
    Proxy.set(bound.port);
    bound.listen(_onRequest, onError: (_) {});
    return bound.port;
  }

  Future<void> dispose() async {
    final server = _server;
    _server = null;
    try {
      await server?.close();
    } catch (_) {}
  }
}
