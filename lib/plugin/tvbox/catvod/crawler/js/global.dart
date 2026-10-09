import 'dart:async';
import 'dart:convert';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/crypto.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_worker.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/html_parser.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/js_spider.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/rsa/rsa_encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_js/flutter_js.dart';

/// com.github.catvod.crawler.js.Global
class Global {
  Global._();

  static Future<void> install(
    JsSpider engine,
    WorkerHost host,
  ) async {
    final rt = engine.requireRuntime();
    final set = engine.setGlobalFn;
    if (set == null) {
      throw StateError('bridge install failed: no setGlobal');
    }
    void reg(String name, Function fn) => set.invoke([name, fn]);

    reg(
      '__dartLog',
      (a, [b, c, d, e, f, g, h]) {
        final buf = StringBuffer();
        for (final v in [a, b, c, d, e, f, g, h]) {
          if (v == null) continue;
          if (buf.isNotEmpty) buf.write(' ');
          buf.write(v is Map || v is List ? jsonEncode(v) : v.toString());
        }
        debugPrint('[tvbox-js] $buf');
      },
    );
    rt.evaluate('''
globalThis.console = {
  log: __dartLog, info: __dartLog, warn: __dartLog, error: __dartLog, debug: __dartLog,
};
globalThis.print = __dartLog;
''');

    /// com.github.catvod.crawler.js.Global._http
    reg('_http', (dynamic url, [dynamic options]) {
      final opts = options is Map
          ? options.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final complete = opts['complete'];
      final sendOpts = Map<String, dynamic>.from(opts)..remove('complete');
      if (complete is JSInvokable) {
        try {
          host.httpAsync(url?.toString() ?? '', sendOpts, (res) {
            try {
              complete.invoke([res]);
            } catch (e) {
              debugPrint('[tvbox-js] _http complete error: $e');
            }
            engine.kick();
          });
          return null;
        } catch (e) {
          debugPrint('[tvbox-js] _http async error: $e');
          return null;
        }
      }
      try {
        return host.httpSync(url?.toString() ?? '', sendOpts);
      } catch (e) {
        debugPrint('[tvbox-js] _http sync error: $e');
        return <String, dynamic>{'headers': <String, String>{}, 'content': ''};
      }
    });

    /// com.github.catvod.crawler.js.Global.pdfh
    reg(
      'pdfh',
      (a, [b]) =>
          HtmlParser.parseDomForUrl(a?.toString() ?? '', b?.toString() ?? ''),
    );

    /// com.github.catvod.crawler.js.Global.pd
    reg('pd', (a, [b, c]) {
      return HtmlParser.parseDomForUrl(
        a?.toString() ?? '',
        b?.toString() ?? '',
        c?.toString() ?? '',
      );
    });

    /// com.github.catvod.crawler.js.Global.pdfa
    reg(
      'pdfa',
      (a, [b]) =>
          HtmlParser.parseDomForArray(a?.toString() ?? '', b?.toString() ?? ''),
    );

    /// com.github.catvod.crawler.js.Global.pdfla
    reg('pdfla', (a, [b, c, d, e]) {
      return HtmlParser.parseDomForList(
        a?.toString() ?? '',
        b?.toString() ?? '',
        c?.toString() ?? '',
        d?.toString() ?? '',
        e?.toString() ?? '',
      );
    });

    /// com.github.catvod.crawler.js.Global.joinUrl
    reg('joinUrl', (a, [b]) {
      return HtmlParser.joinUrl(a?.toString() ?? '', b?.toString() ?? '');
    });

    /// com.github.catvod.crawler.js.Global.s2t
    reg('s2t', (a, [_]) => host.s2t(a?.toString() ?? '', true));

    /// com.github.catvod.crawler.js.Global.t2s
    reg('t2s', (a, [_]) => host.s2t(a?.toString() ?? '', false));

    /// com.github.catvod.crawler.js.Global.aesX
    reg(
      'aesX',
      (mode, enc, input, inBase64, key, iv, [outBase64]) {
        return Crypto.aes(
          mode?.toString() ?? '',
          enc == true || enc == 1,
          input?.toString() ?? '',
          inBase64 == true || inBase64 == 1,
          key?.toString() ?? '',
          iv?.toString(),
          outBase64 == true || outBase64 == 1,
        );
      },
    );

    /// com.github.catvod.crawler.js.Global.rsaX
    reg(
      'rsaX',
      (mode, pub, enc, input, inBase64, key, [outBase64]) {
        return Crypto.rsa(
          pub == true || pub == 1,
          enc == true || enc == 1,
          input?.toString() ?? '',
          inBase64 == true || inBase64 == 1,
          key?.toString() ?? '',
          outBase64 == true || outBase64 == 1,
        );
      },
    );

    /// com.github.catvod.crawler.js.Global.rsaEncrypt
    reg(
      'rsaEncrypt',
      (data, key, [options]) {
        final o = options is Map ? options : const {};
        final type = o['type'] is num ? (o['type'] as num).toInt() : 1;
        final long = o['long'] is num ? (o['long'] as num).toInt() : 1;
        final block = o['block'] is bool ? o['block'] as bool : true;
        return RSAEncrypt.process(
          type != 2,
          true,
          data?.toString() ?? '',
          false,
          key?.toString() ?? '',
          true,
          config: o['config']?.toString(),
          long: long,
          block: block,
        );
      },
    );

    /// com.github.catvod.crawler.js.Global.rsaDecrypt
    reg(
      'rsaDecrypt',
      (data, key, [options]) {
        final o = options is Map ? options : const {};
        final type = o['type'] is num ? (o['type'] as num).toInt() : 1;
        final long = o['long'] is num ? (o['long'] as num).toInt() : 1;
        final block = o['block'] is bool ? o['block'] as bool : true;
        return RSAEncrypt.process(
          type == 2,
          false,
          data?.toString() ?? '',
          true,
          key?.toString() ?? '',
          false,
          config: o['config']?.toString(),
          long: long,
          block: block,
        );
      },
    );

    /// com.github.catvod.crawler.js.Global.getProxy
    reg('getProxy', ([_]) => host.proxyBaseUrl);

    /// com.github.catvod.crawler.js.Global.js2Proxy
    reg('js2Proxy', (
      dynamic_,
      siteType,
      siteKey,
      url, [
      headers,
    ]) {
      final headerMap = headers is Map
          ? headers.map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{};
      final parts = <String>[
        host.proxyBaseUrl,
        'from=catvod',
        'siteType=${siteType ?? ''}',
        'siteKey=${Uri.encodeComponent(siteKey?.toString() ?? '')}',
        'header=${Uri.encodeComponent(jsonEncode(headerMap))}',
        'url=${Uri.encodeComponent(url?.toString() ?? '')}',
      ];
      return parts.join('&');
    });

    /// com.github.catvod.crawler.js.Global.setTimeout
    reg('setTimeout', (fn, [delay]) {
      if (fn is! JSInvokable) return 0;
      Timer(Duration(milliseconds: delay is num ? delay.toInt() : 0), () {
        try {
          fn.invoke([]);
        } catch (e) {
          debugPrint('[tvbox-js] setTimeout error: $e');
        }
        engine.kick();
      });
      return 0;
    });

    reg(
      '__localGet',
      (ns, key, [d]) =>
          host.localGet(ns?.toString() ?? '', key?.toString() ?? '') ?? d,
    );
    reg('__localSet', (ns, key, v) {
      host.localSet(ns?.toString() ?? '', key?.toString() ?? '', v);
      engine.kick();
    });
    reg('__localDelete', (ns, key) {
      host.localDelete(ns?.toString() ?? '', key?.toString() ?? '');
      engine.kick();
    });
    rt
      ..evaluate('''
globalThis.local = { get: __localGet, set: __localSet, delete: __localDelete };
''')
      ..evaluate(host.builtin['net.js']!, name: 'net.js');
  }
}
