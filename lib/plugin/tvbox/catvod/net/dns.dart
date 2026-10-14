import 'dart:io';

import 'package:PiliPlus/plugin/tvbox/catvod/net/doh.dart';

/// com.github.catvod.net.OkDns
class Dns {
  /// com.github.tvbox.osc.util.OkGoHelper.myHosts
  static Map<String, String> _hosts = const {};

  static bool get isEmpty => _hosts.isEmpty;

  Dns._();

  static void addAll(Map<String, String> hosts) {
    _hosts = hosts.isEmpty ? const {} : Map<String, String>.from(hosts);
  }

  /// com.github.tvbox.osc.util.OkGoHelper.reloadDns
  static void clear() {
    _hosts = const {};
  }

  static (String, int) parseTarget(String target, int defaultPort) {
    var host = target;
    var port = defaultPort;
    if (target.startsWith('[')) {
      final end = target.indexOf(']');
      if (end > 0) {
        host = target.substring(1, end);
        final rest = target.substring(end + 1);
        if (rest.startsWith(':') && rest.length > 1) {
          port = int.tryParse(rest.substring(1)) ?? port;
        }
      }
    } else {
      final idx = target.indexOf(':');
      if (idx > 0) {
        host = target.substring(0, idx);
        port = int.tryParse(target.substring(idx + 1)) ?? port;
      }
    }
    return (host, port);
  }

  /// com.github.tvbox.osc.util.OkGoHelper.CustomDns.lookup
  static Future<ConnectionTask<Socket>> connect(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    final target = _hosts[uri.host];
    if (target != null && target.isNotEmpty) {
      final (host, port) = parseTarget(target, uri.port);
      return _connectMapped(uri, host, port);
    }
    final ips = await Doh.resolve(uri.host);
    if (ips != null) {
      for (final ip in ips) {
        try {
          return await _connectMapped(uri, ip, uri.port);
        } catch (_) {}
      }
    }
    return uri.scheme == 'https'
        ? SecureSocket.startConnect(
            uri.host,
            uri.port,
            onBadCertificate: (_) => true,
          )
        : Socket.startConnect(uri.host, uri.port);
  }

  static Future<ConnectionTask<Socket>> _connectMapped(
    Uri uri,
    String host,
    int port,
  ) async {
    if (uri.scheme != 'https') {
      return Socket.startConnect(host, port);
    }
    final rawTask = await Socket.startConnect(host, port);
    final rawSocket = await rawTask.socket;
    final secure = await SecureSocket.secure(
      rawSocket,
      host: uri.host,
      onBadCertificate: (_) => true,
    );
    return ConnectionTask.fromSocket(Future.value(secure), rawTask.cancel);
  }
}
