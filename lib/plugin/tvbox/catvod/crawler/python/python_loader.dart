import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:PiliPlus/plugin/tvbox/tvbox/osc/server/control_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:serious_python/serious_python.dart';

/// com.undcover.freedom.pyramid.PythonLoader
class PythonLoader {
  PythonLoader._();

  static final PythonLoader instance = PythonLoader._();

  Future<void>? _startFuture;
  HttpClient? _client;
  int? _port;
  String _token = '';

  bool get started => _port != null;

  Future<void> ensureStarted() {
    if (_startFuture != null) return _startFuture!;
    final future = _start();
    _startFuture = future;
    return future.then(
      (_) {},
      onError: (Object e) {
        if (identical(_startFuture, future)) _startFuture = null;
        throw e;
      },
    );
  }

  Future<void> _start() async {
    final watch = Stopwatch()..start();
    final proxyPort = await ControlManager.instance.ensureServer();
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory(
      p.join(dir.path, 'py_plugin'),
    )..createSync(recursive: true);
    final hostFile = File(p.join(dir.path, 'pili_py_host.json'));
    try {
      if (hostFile.existsSync()) hostFile.deleteSync();
    } catch (_) {}
    final appDir = await SeriousPython.prepareApp();
    debugPrint(
      'PythonLoader: launching python runtime (app=$appDir, proxyPort=$proxyPort)',
    );
    await SeriousPython.run(
      appFileName: 'main.py',
      environmentVariables: {
        'PILI_PY_APP_DIR': appDir,
        'PILI_PROXY_BASE': 'http://127.0.0.1:$proxyPort/proxy',
        'PILI_PY_HOST_FILE': hostFile.path,
        'PILI_PY_CACHE': cacheDir.path,
      },
    );
    debugPrint(
      'PythonLoader: runtime dispatched in ${watch.elapsedMilliseconds}ms, '
      'waiting for handshake',
    );
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      try {
        final decoded =
            jsonDecode(hostFile.readAsStringSync()) as Map<String, dynamic>;
        final port = decoded['port'];
        if (port is int) {
          _port = port;
          _token = decoded['token']?.toString() ?? '';
          break;
        }
      } catch (_) {}
    }
    if (_port == null) {
      throw Exception('Python 引擎启动超时');
    }
    debugPrint(
      'PythonLoader: handshake ok in ${watch.elapsedMilliseconds}ms, '
      'port=$_port',
    );
    final client = _client ??= HttpClient();
    final request = await client
        .getUrl(Uri.parse('http://127.0.0.1:$_port/health'))
        .timeout(const Duration(seconds: 5));
    final response = await request.close().timeout(const Duration(seconds: 5));
    await response.drain<void>().timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw Exception('python host health: http ${response.statusCode}');
    }
    debugPrint(
      'PythonLoader: engine ready in ${watch.elapsedMilliseconds}ms',
    );
  }

  Future<Map<String, dynamic>> command(
    String op,
    Map<String, dynamic> body, {
    Duration? timeout = const Duration(seconds: 30),
  }) async {
    if (_port == null) {
      await ensureStarted();
    }
    final client = _client ??= HttpClient();
    final watch = Stopwatch()..start();
    try {
      final url = Uri.parse('http://127.0.0.1:$_port/$op');
      final requestFuture = client.postUrl(url);
      final request = timeout == null
          ? await requestFuture
          : await requestFuture.timeout(timeout);
      final data = utf8.encode(
        jsonEncode(<String, dynamic>{
          'token': _token,
          ...body,
        }),
      );
      request
        ..headers.contentType = ContentType.json
        ..contentLength = data.length
        ..add(data);
      final responseFuture = request.close();
      final response = timeout == null
          ? await responseFuture
          : await responseFuture.timeout(timeout);
      final textFuture = utf8.decoder.bind(response).join();
      final text = timeout == null
          ? await textFuture
          : await textFuture.timeout(timeout);
      final elapsed = watch.elapsedMilliseconds;
      if (response.statusCode != 200) {
        debugPrint(
          'PythonLoader: $op failed http=${response.statusCode} in ${elapsed}ms',
        );
        throw Exception('python host $op: http ${response.statusCode}');
      }
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('python host $op: bad response');
      }
      if (decoded['ok'] != true || elapsed > 3000) {
        debugPrint(
          'PythonLoader: $op ok=${decoded['ok']} in ${elapsed}ms',
        );
      }
      return decoded;
    } catch (e) {
      debugPrint(
        'PythonLoader: $op error after ${watch.elapsedMilliseconds}ms: $e',
      );
      rethrow;
    }
  }
}
