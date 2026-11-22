import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/node.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_api.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_client.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_constants.dart';
import 'package:dio/dio.dart';

abstract final class UgreenAddressHttp {
  static Future<LoadingState<UgreenResolvedNode>> resolveAddress(
    String input, {
    required String clientId,
  }) async {
    final value = input.trim();
    if (value.isEmpty) {
      return const Error('请输入设备地址或 UGLink ID');
    }

    String? alias;
    int? directPort;
    final candidates = <String>[];
    final hosts = <String>[];
    final seen = <String>{};

    void add(String? base) {
      if (base == null || base.isEmpty) return;
      var normalized = base;
      while (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      if (seen.add(normalized)) {
        candidates.add(normalized);
      }
    }

    void addHost(String host) {
      final value = _bareHost(host);
      if (value.isNotEmpty && !hosts.contains(value)) {
        hosts.add(value);
      }
    }

    if (value.contains('://')) {
      final uri = _tryUri(value);
      if (uri == null) {
        return const Error('设备地址格式无效');
      }
      if (uri.host == 'ug.link' && uri.pathSegments.isNotEmpty) {
        alias = uri.pathSegments.first;
      } else if (uri.host == 'ug.link' && uri.pathSegments.isEmpty) {
        return const Error('请输入 UGLink ID');
      } else {
        addHost(uri.host);
        if (uri.hasPort) directPort = uri.port;
        add(_baseFromUri(uri));
      }
    } else if (value.contains('/')) {
      final parts = value.split('/');
      if (parts.first == 'ug.link' && parts.length > 1 && parts[1].isNotEmpty) {
        alias = parts[1];
      } else {
        final uri = _tryUri(value);
        if (uri == null) {
          return const Error('设备地址格式无效');
        }
        addHost(uri.host);
        if (uri.hasPort) directPort = uri.port;
        add(_baseFromUri(uri));
      }
    } else if (_looksLikeHost(value)) {
      final uri = _tryUri(value);
      if (uri == null) {
        return const Error('设备地址格式无效');
      }
      addHost(uri.host);
      if (uri.hasPort) directPort = uri.port;
      add(_baseFromUri(uri));
    } else {
      alias = value;
    }

    UgreenResolvedNode? node;
    if (alias != null && alias.isNotEmpty) {
      final nodeRes = await _resolveByAlias(alias);
      if (nodeRes is Error) {
        return nodeRes;
      }
      if (nodeRes is Success<UgreenResolvedNode>) {
        node = nodeRes.response;
        for (final candidate in node.candidates) {
          add(candidate);
        }
      }
    }

    if (candidates.isEmpty) {
      return const Error('未找到可用的设备地址');
    }

    for (final candidate in candidates) {
      if (await UgreenClient.probe(candidate, clientId: clientId)) {
        return Success(
          node?.copyWith(baseUrl: candidate) ??
              UgreenResolvedNode(
                baseUrl: candidate,
                alias: alias ?? '',
                uglinkId: alias ?? '',
                hosts: hosts,
                httpsPort: directPort,
              ),
        );
      }
    }
    return const Error('无法连接设备，请检查地址或网络');
  }

  static Future<LoadingState<UgreenResolvedNode>> _resolveByAlias(
    String alias,
  ) async {
    try {
      final response = await UgreenClient.dio.post<dynamic>(
        UgreenApi.nodeInfoByAlias,
        data: {'alias': alias},
        options: Options(
          headers: {
            'Content-Type': Headers.jsonContentType,
            'lang': UgreenHttpString.language,
          },
        ),
      );
      final json = UgreenClient.asJson(response.data);
      if (json == null) {
        return const Error('解析设备地址失败');
      }
      final code = UgreenClient.toInt(json['code']);
      if (code != null && code != 200) {
        return Error(
          json['msg']?.toString() ?? '解析设备地址失败',
          code: code,
        );
      }
      final map = json['data'];
      if (map is! Map) {
        return const Error('解析设备地址失败');
      }
      final data = map.cast<String, dynamic>();
      final resolvedAlias = data['alias']?.toString() ?? alias;
      final relayDomain = data['relayDomain']?.toString() ?? '';
      final net = data['netInfo'] is Map
          ? (data['netInfo'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final smartdns = net['smartdns'] is Map
          ? (net['smartdns'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final httpPort = UgreenClient.toInt(net['httpPort']);
      final httpsPort = UgreenClient.toInt(net['httpsPort']) ?? 9443;
      final ipv4 = _unique(
        UgreenClient.toStringList(net['ipv4'] ?? net['ipv_4']),
      );
      final ipv6 = _unique(
        UgreenClient.toStringList(net['ipv6'] ?? net['ipv_6']),
      );
      final ddns = _unique(UgreenClient.toStringList(net['ddns']));
      final lan = _unique(UgreenClient.toStringList(smartdns['lan']));
      final hosts = _unique([...lan, ...ddns]);
      final relayUrl = relayDomain.isEmpty
          ? null
          : 'https://$resolvedAlias.$relayDomain';
      final candidates = _unique(<String>[
        for (final ip in ipv4) 'https://$ip:$httpsPort',
        for (final ip in ipv6) 'https://[$ip]:$httpsPort',
        for (final host in lan) 'https://$host:$httpsPort',
        for (final host in ddns) 'https://$host:$httpsPort',
        ?relayUrl,
      ]);
      return Success(
        UgreenResolvedNode(
          baseUrl: candidates.isEmpty ? '' : candidates.first,
          relayUrl: relayUrl,
          alias: resolvedAlias,
          uglinkId:
              data['uglink_id']?.toString() ??
              data['uglinkId']?.toString() ??
              resolvedAlias,
          candidates: candidates,
          ipv4: ipv4,
          ipv6: ipv6,
          hosts: hosts,
          httpPort: httpPort,
          httpsPort: httpsPort,
        ),
      );
    } on DioException catch (e) {
      return Error(UgreenClient.dioError(e));
    }
  }

  static Uri? _tryUri(String value) {
    try {
      var target = value;
      if (!target.contains('://')) {
        var authority = target.split('/').first;
        if (!authority.startsWith('[') &&
            ':'.allMatches(authority).length >= 2) {
          authority = '[$authority]';
        }
        target = 'https://$authority';
      }
      final uri = Uri.parse(target);
      return uri.host.isEmpty ? null : uri;
    } catch (_) {
      return null;
    }
  }

  static bool _looksLikeHost(String value) {
    final authority = value.split('/').first;
    if (authority == 'localhost' || authority.startsWith('localhost:')) {
      return true;
    }
    if (authority.startsWith('[')) {
      return true;
    }
    if (':'.allMatches(authority).length >= 2) {
      return true;
    }
    if (authority.contains('.')) {
      return true;
    }
    final colon = authority.lastIndexOf(':');
    if (colon > 0) {
      final port = authority.substring(colon + 1);
      if (port.isNotEmpty && int.tryParse(port) != null) {
        return true;
      }
    }
    return false;
  }

  static String _bareHost(String host) {
    return host.startsWith('[') && host.endsWith(']')
        ? host.substring(1, host.length - 1)
        : host;
  }

  static List<String> _unique(Iterable<String> values) {
    final result = <String>{};
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        result.add(trimmed);
      }
    }
    return result.toList();
  }

  static String _baseFromUri(Uri uri) {
    final host = _bareHost(uri.host);
    final isRelay = host == 'ug.link' || host.endsWith('.ug.link');
    final port = uri.hasPort ? uri.port : (isRelay ? 443 : 9443);
    final hostPart = host.contains(':') ? '[$host]' : host;
    final scheme = uri.scheme.isEmpty ? 'https' : uri.scheme;
    var value = '$scheme://$hostPart:$port';
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
