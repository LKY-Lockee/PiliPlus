import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/connect.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/local.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/module_loader.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_sync_slot.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js/helper/js_worker.dart';
import 'package:flutter_opencc_plus/flutter_opencc_plus.dart';

class JsIsolate {
  ReceivePort? _hostPort;
  SendPort? _worker;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  int _seq = 0;
  Future<void>? _startFuture;

  static final JsIsolate instance = JsIsolate._();

  JsIsolate._();

  Future<void> _start(String proxyBase) async {
    final builtin = await JsModules.loadBuiltin();
    String? openccDataDir;
    try {
      openccDataDir = await resolveOpenCCDataDir();
    } catch (_) {}
    _hostPort = ReceivePort();
    final hostPort = _hostPort!;
    final ready = Completer<void>();
    hostPort.listen((msg) => _onMessage(msg, ready));
    await Isolate.spawn(tvboxJsWorker, <String, Object?>{
      'toHost': hostPort.sendPort,
      'builtin': builtin,
      'proxyBase': proxyBase,
      'openccDataDir': openccDataDir,
    });
    await ready.future.timeout(const Duration(seconds: 30));
  }

  void _onMessage(dynamic msg, Completer<void> ready) {
    if (msg is! Map) return;
    switch (msg['t']) {
      case 'workerPort':
        _worker = msg['port'] as SendPort;
        if (!ready.isCompleted) ready.complete();
        break;
      case 'reply':
        final c = _pending.remove(msg['id']);
        if (c != null && !c.isCompleted) {
          c.complete(msg.cast<String, dynamic>());
        }
        break;
      case 'sync':
        _handleSync(msg);
        break;
      case 'async':
        _handleAsync(msg);
        break;
    }
  }

  void _handleSync(Map msg) {
    final slot = JsSyncSlot.fromAddress(msg['slot'] as int);
    final op = msg['op'] as String;
    final p = (msg['p'] as Map).cast<String, dynamic>();
    Future(() async {
      try {
        slot.respond(await _op(op, p));
      } catch (e) {
        slot.respond('$e', status: 1);
      }
    });
  }

  void _handleAsync(Map msg) {
    final port = msg['port'] as SendPort;
    final p = (msg['p'] as Map).cast<String, dynamic>();
    Future(() async {
      try {
        final res = await Connect.to(
          p['url'] as String,
          Map<String, dynamic>.from(p['options'] as Map? ?? const {}),
        );
        port.send(res);
      } catch (_) {
        port.send(<String, dynamic>{
          'headers': <String, String>{},
          'content': '',
        });
      }
    });
  }

  Future<String> _op(String op, Map<String, dynamic> p) async {
    switch (op) {
      case 'http':
        final res = await Connect.to(
          p['url'] as String,
          Map<String, dynamic>.from(p['options'] as Map? ?? const {}),
        );
        return jsonEncode(res);
      case 'module':
        final data = await Http.string(p['url'] as String);
        if (data == null) return jsonEncode({'ok': false});
        return jsonEncode({'ok': true, 'content': data});
      case 'localGet':
        return jsonEncode(
          await Local.get(
            p['ns']?.toString() ?? '',
            p['key']?.toString() ?? '',
          ),
        );
      case 'localSet':
        await Local.set(
          p['ns']?.toString() ?? '',
          p['key']?.toString() ?? '',
          p['value'],
        );
        return 'null';
      case 'localDelete':
        await Local.delete(
          p['ns']?.toString() ?? '',
          p['key']?.toString() ?? '',
        );
        return 'null';
      default:
        return jsonEncode({'ok': false});
    }
  }

  Future<void> ensureStarted({required String proxyBase}) {
    return _startFuture ??= _start(proxyBase).catchError((Object e) {
      _startFuture = null;
      throw e;
    });
  }

  Future<Map<String, dynamic>> command(
    String t,
    Map<String, dynamic> p, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    final id = _seq++;
    final c = Completer<Map<String, dynamic>>();
    _pending[id] = c;
    _worker!.send(<String, Object?>{'t': t, 'id': id, ...p});
    return c.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('tvbox js $t timeout');
      },
    );
  }
}
