import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/session.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_client.dart';

abstract final class UgreenEndpoint {
  static String? _cachedToken;
  static String? _cachedBase;

  static List<String> candidates(UgreenSession session) {
    final result = <String>[];
    final seen = <String>{};
    for (final base in session.endpointCandidates) {
      if (seen.add(base)) {
        result.add(base);
      }
    }
    return result;
  }

  static Future<String?> resolve(UgreenSession session) async {
    if (_cachedToken == session.token && _cachedBase != null) {
      return _cachedBase;
    }
    for (final base in candidates(session)) {
      if (await UgreenClient.probe(base, clientId: session.clientId)) {
        _cachedToken = session.token;
        _cachedBase = base;
        return base;
      }
    }
    _cachedToken = null;
    _cachedBase = null;
    return null;
  }

  static String displayUrl(UgreenSession session) {
    if (_cachedToken == session.token && _cachedBase != null) {
      return _cachedBase!;
    }
    final relay = session.relayBaseUrl;
    if (relay != null) {
      return relay;
    }
    final local = session.localBaseUrls;
    return local.isEmpty ? '' : local.first;
  }

  static void invalidate() {
    _cachedToken = null;
    _cachedBase = null;
  }

  static Future<LoadingState<Map<String, dynamic>>> request(
    UgreenSession session,
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
    Map<String, dynamic>? data,
  }) async {
    final base = await resolve(session);
    if (base == null) {
      return const Error('无法连接设备');
    }
    final res = await UgreenClient.request(
      base,
      path,
      method: method,
      query: query,
      data: data,
      token: session.token,
      clientId: session.clientId,
    );
    if (res is Error) {
      invalidate();
    }
    return res;
  }
}
