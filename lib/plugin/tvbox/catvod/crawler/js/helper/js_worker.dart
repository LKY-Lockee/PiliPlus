import 'dart:convert';
import 'dart:isolate';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_sync_slot.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/js_spider.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';

void tvboxJsWorker(Map<String, dynamic> init) {
  final toHost = init['toHost'] as SendPort;
  final host = WorkerHost(
    toHost,
    (init['builtin'] as Map?)?.cast<String, String>() ?? const {},
    init['proxyBase'] as String? ?? '',
    init['openccDataDir'] as String?,
  );
  final engine = JsSpider(host);
  final cmdPort = ReceivePort();
  toHost.send(<String, Object?>{'t': 'workerPort', 'port': cmdPort.sendPort});
  cmdPort.listen((msg) async {
    if (msg is! Map) return;
    final id = msg['id'];
    try {
      switch (msg['t']) {
        case 'ensure':
          await engine.ensureSpider(
            siteKey: msg['siteKey'] as String,
            api: msg['api'] as String,
            ext: msg['ext'] as String?,
          );
          toHost.send({'t': 'reply', 'id': id, 'ok': true});
          break;
        case 'call':
          final data = await engine.callMethod(
            msg['siteKey'] as String,
            msg['method'] as String,
            List<dynamic>.from(msg['args'] as List? ?? const []),
          );
          toHost.send({'t': 'reply', 'id': id, 'ok': true, 'data': data});
          break;
        case 'proxy':
          final data = await engine.callProxy(
            msg['siteKey'] as String,
            Map<String, String>.from(msg['params'] as Map? ?? const {}),
          );
          toHost.send({'t': 'reply', 'id': id, 'ok': true, 'data': data});
          break;
      }
    } catch (e) {
      if (id != null) {
        toHost.send({'t': 'reply', 'id': id, 'ok': false, 'error': '$e'});
      }
    }
  });
}

class WorkerHost {
  final Map<String, String> builtin;

  /// com.github.catvod.crawler.js.Global.getProxy+proxyBaseUrl
  final String proxyBaseUrl;

  final SendPort _toHost;
  final String? _openccDataDir;
  ZhConverter? _s2tConverter;
  ZhConverter? _t2sConverter;

  WorkerHost(
    this._toHost,
    this.builtin,
    this.proxyBaseUrl,
    this._openccDataDir,
  );

  String _sync(
    String op,
    Map<String, dynamic> p, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final slot = JsSyncSlot();
    try {
      slot.markRequested();
      _toHost.send(<String, Object?>{
        't': 'sync',
        'op': op,
        'slot': slot.address,
        'p': p,
      });
      if (!slot.wait(timeout: timeout)) {
        throw StateError('host sync timeout: $op');
      }
      final status = slot.status;
      final body = slot.readAndFree();
      if (status != 0) {
        throw StateError(body.isEmpty ? 'host sync failed: $op' : body);
      }
      return body;
    } finally {
      slot.dispose();
    }
  }

  /// com.github.catvod.crawler.js.Trans.s2t
  String s2t(String text, bool toTraditional) {
    if (text.isEmpty) return text;
    try {
      final converter = toTraditional
          ? (_s2tConverter ??= ZhConverter(
              OpenCCConfig.s2t,
              dataDir: _openccDataDir,
            ))
          : (_t2sConverter ??= ZhConverter(
              OpenCCConfig.t2s,
              dataDir: _openccDataDir,
            ));
      return converter.convert(text);
    } catch (_) {
      return text;
    }
  }

  String? fetchModuleSync(String url) {
    try {
      final body = _sync('module', {'url': url});
      final j = jsonDecode(body);
      if (j is Map && j['ok'] == true) return j['content'] as String?;
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> httpSync(String url, Map<String, dynamic> options) {
    final timeoutMs = options['timeout'] is num
        ? (options['timeout'] as num).toInt()
        : 10000;
    final body = _sync(
      'http',
      {'url': url, 'options': options},
      timeout: Duration(milliseconds: timeoutMs + 10000),
    );
    final j = jsonDecode(body);
    return j is Map<String, dynamic>
        ? j
        : <String, dynamic>{'headers': <String, String>{}, 'content': ''};
  }

  void httpAsync(
    String url,
    Map<String, dynamic> options,
    void Function(Map<String, dynamic> result) onDone,
  ) {
    final port = ReceivePort();
    port.first.then((msg) {
      port.close();
      if (msg is Map) {
        onDone(msg.cast<String, dynamic>());
      }
    });
    _toHost.send(<String, Object?>{
      't': 'async',
      'op': 'http',
      'port': port.sendPort,
      'p': {'url': url, 'options': options},
    });
  }

  Object? localGet(String ns, String key) {
    final body = _sync('localGet', {'ns': ns, 'key': key});
    return jsonDecode(body);
  }

  void localSet(String ns, String key, Object? value) {
    _sync('localSet', {'ns': ns, 'key': key, 'value': value});
  }

  void localDelete(String ns, String key) {
    _sync('localDelete', {'ns': ns, 'key': key});
  }
}
