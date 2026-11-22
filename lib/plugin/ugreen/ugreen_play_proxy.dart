import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:PiliPlus/plugin/ugreen/http/ugreen_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UgreenPlayProxy {
  UgreenPlayProxy._();

  static final UgreenPlayProxy instance = UgreenPlayProxy._();

  final _random = Random.secure();
  final Map<String, String> _playlists = {};

  HttpServer? _server;
  Future<void>? _starting;
  int _port = 0;

  late final String _secret = List.generate(
    16,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  static const _maxPlaylists = 32;

  String get _base => 'http://127.0.0.1:$_port/$_secret';

  Future<void> _ensureStarted() async {
    if (_server != null) {
      return;
    }
    final starting = _starting;
    if (starting != null) {
      return starting;
    }
    final completer = Completer<void>();
    _starting = completer.future;
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      _port = server.port;
      server.listen(
        _handle,
        onError: (Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            debugPrint('[ugreen] play proxy error: $error');
          }
        },
      );
      completer.complete();
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
      _starting = null;
      rethrow;
    }
  }

  Future<String> prepare({
    required String upstreamUrl,
    required String token,
    required String clientId,
    required String taskId,
  }) async {
    final uri = Uri.parse(upstreamUrl);
    if (!_isAllowed(uri, uri.host)) {
      throw StateError('不允许的播放地址');
    }
    final text = await _fetchPlaylist(uri, clientId);
    await _ensureStarted();
    final rewritten = _rewrite(
      text,
      uri,
      token: token,
      clientId: clientId,
      taskId: taskId,
      allowedHost: uri.host,
    );
    final id = _nextId();
    _playlists[id] = rewritten;
    while (_playlists.length > _maxPlaylists) {
      _playlists.remove(_playlists.keys.first);
    }
    return '$_base/hls/$id.m3u8';
  }

  Future<void> dispose() async {
    final server = _server;
    _server = null;
    _starting = null;
    _port = 0;
    _playlists.clear();
    if (server != null) {
      await server.close(force: true);
    }
  }

  String _nextId() {
    final ms = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final random = _random.nextInt(1 << 30).toRadixString(16);
    return '$ms$random';
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      if (segments.isEmpty || segments.first != _secret) {
        await _reply(request, HttpStatus.notFound, 'not found');
        return;
      }
      if (segments.length == 3 && segments[1] == 'hls') {
        var id = segments[2];
        if (id.endsWith('.m3u8')) {
          id = id.substring(0, id.length - 5);
        }
        final playlist = _playlists[id];
        if (playlist == null) {
          await _reply(request, HttpStatus.notFound, 'not found');
          return;
        }
        _replyPlaylist(request, playlist);
        return;
      }
      if (segments.length == 2 &&
          (segments[1] == 'hls' || segments[1] == 'hls.m3u8')) {
        await _dynamicPlaylist(request);
        return;
      }
      if (segments.length == 2 && segments[1] == 'seg') {
        await _proxySegment(request);
        return;
      }
      await _reply(request, HttpStatus.notFound, 'not found');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ugreen] play proxy request failed: $error');
      }
      await _reply(request, HttpStatus.badGateway, '$error');
    }
  }

  Future<void> _dynamicPlaylist(HttpRequest request) async {
    final query = request.uri.queryParameters;
    final upstream = _unb64(query['u']);
    if (upstream == null) {
      await _reply(request, HttpStatus.badRequest, 'missing url');
      return;
    }
    final uri = Uri.parse(upstream);
    final expectedHost = query['h'] ?? uri.host;
    if (!_isAllowed(uri, expectedHost)) {
      await _reply(request, HttpStatus.forbidden, 'forbidden');
      return;
    }
    final token = uri.queryParameters['token'] ?? '';
    final clientId = query['cid'] ?? '';
    final taskId = _unb64(query['t']) ?? '';
    final text = await _fetchPlaylist(uri, clientId);
    final rewritten = _rewrite(
      text,
      uri,
      token: token,
      clientId: clientId,
      taskId: taskId,
      allowedHost: expectedHost,
    );
    _replyPlaylist(request, rewritten);
  }

  Future<void> _proxySegment(HttpRequest request) async {
    final query = request.uri.queryParameters;
    final upstream = _unb64(query['u']);
    if (upstream == null) {
      await _reply(request, HttpStatus.badRequest, 'missing url');
      return;
    }
    final uri = Uri.parse(upstream);
    final expectedHost = query['h'] ?? uri.host;
    if (!_isAllowed(uri, expectedHost)) {
      await _reply(request, HttpStatus.forbidden, 'forbidden');
      return;
    }
    final clientId = query['cid'] ?? '';
    final range = request.headers.value(HttpHeaders.rangeHeader);
    final headers = <String, dynamic>{
      ..._headers(clientId),
      HttpHeaders.rangeHeader: ?range,
    };
    final res = await UgreenClient.dio.get<ResponseBody>(
      upstream,
      options: Options(
        responseType: ResponseType.stream,
        headers: headers,
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final response = request.response
      ..statusCode = res.statusCode ?? HttpStatus.badGateway;
    for (final name in [
      Headers.contentTypeHeader,
      Headers.contentLengthHeader,
      'content-range',
      'accept-ranges',
      'etag',
      'last-modified',
    ]) {
      final value = res.headers.value(name);
      if (value != null) {
        response.headers.set(name, value);
      }
    }
    final data = res.data;
    if (data != null) {
      await response.addStream(data.stream);
    }
    await response.close();
  }

  Future<String> _fetchPlaylist(Uri uri, String clientId) async {
    final res = await UgreenClient.dio.get<String>(
      uri.toString(),
      options: Options(
        responseType: ResponseType.plain,
        headers: _headers(clientId),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    var body = res.data;
    if (body == null ||
        res.statusCode != HttpStatus.ok ||
        !body.trimLeft().startsWith('#EXTM3U')) {
      throw StateError('获取播放列表失败(${res.statusCode ?? '未知'})');
    }
    if (body.startsWith('\uFEFF')) {
      body = body.substring(1);
    }
    return body.trimLeft();
  }

  String _rewrite(
    String text,
    Uri base, {
    required String token,
    required String clientId,
    required String taskId,
    required String allowedHost,
  }) {
    final buffer = StringBuffer();
    for (final rawLine in const LineSplitter().convert(text)) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        buffer.write('\n');
        continue;
      }
      if (line.startsWith('#')) {
        buffer.writeln(
          line.replaceAllMapped(RegExp('URI="([^"]+)"'), (match) {
            final uri = _localUri(
              match.group(1)!,
              base,
              token: token,
              clientId: clientId,
              taskId: taskId,
              allowedHost: allowedHost,
            );
            return 'URI="$uri"';
          }),
        );
        continue;
      }
      buffer.writeln(
        _localUri(
          line,
          base,
          token: token,
          clientId: clientId,
          taskId: taskId,
          allowedHost: allowedHost,
        ),
      );
    }
    return buffer.toString();
  }

  String _localUri(
    String raw,
    Uri base, {
    required String token,
    required String clientId,
    required String taskId,
    required String allowedHost,
  }) {
    var uri = Uri.parse(raw);
    if (!uri.isAbsolute) {
      uri = base.resolveUri(uri);
    }
    var url = uri.toString();
    if (taskId.isNotEmpty) {
      url = url.replaceFirst(
        'task_id=$taskId',
        'task_id=${Uri.encodeComponent(taskId)}',
      );
    }
    if (!RegExp(r'[?&]token=').hasMatch(url) && token.isNotEmpty) {
      url =
          '$url${url.contains('?') ? '&' : '?'}'
          'token=${Uri.encodeComponent(token)}';
    }
    final kind = uri.path.endsWith('.m3u8') ? 'hls.m3u8' : 'seg';
    final taskQuery = taskId.isEmpty ? '' : '&t=${_b64(taskId)}';
    return '$_base/$kind'
        '?u=${_b64(url)}'
        '&cid=${Uri.encodeComponent(clientId)}'
        '&h=${Uri.encodeComponent(allowedHost)}'
        '$taskQuery';
  }

  Map<String, String> _headers(String clientId) {
    return {
      ...UgreenClient.headers(clientId),
      'Accept': '*/*',
    };
  }

  bool _isAllowed(Uri uri, String expectedHost) {
    if (uri.host.isEmpty || uri.host != expectedHost) {
      return false;
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return false;
    }
    return uri.path.startsWith('/ugreen/');
  }

  void _replyPlaylist(HttpRequest request, String text) {
    final response = request.response..statusCode = HttpStatus.ok;
    response.headers.contentType = ContentType(
      'application',
      'vnd.apple.mpegurl',
      charset: 'utf-8',
    );
    response
      ..write(text)
      ..close();
  }

  Future<void> _reply(HttpRequest request, int status, String text) async {
    try {
      final response = request.response..statusCode = status;
      response.headers.contentType = ContentType.text;
      response.write(text);
      await response.close();
    } catch (_) {}
  }

  String _b64(String value) {
    return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
  }

  String? _unb64(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    try {
      final normalized = value.padRight((value.length + 3) ~/ 4 * 4, '=');
      return utf8.decode(base64Url.decode(normalized));
    } catch (_) {
      return null;
    }
  }
}
