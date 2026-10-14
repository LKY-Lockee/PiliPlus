import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class Doh {
  Doh._();

  /// com.github.tvbox.osc.util.OkGoHelper.dnsConfigJson
  static const String _defaultList =
      '[{"name": "腾讯", "url": "https://doh.pub/dns-query"},'
      '{"name": "阿里", "url": "https://dns.alidns.com/dns-query"},'
      '{"name": "360", "url": "https://doh.360.cn/dns-query"}]';

  static final Random _random = Random();
  static final Map<String, ({List<String> ips, int expire})> _cache = {};

  static List<({String name, String url})> _servers = const [];
  static int _index = 0;

  /// com.github.tvbox.osc.util.OkGoHelper.dnsHttpsList
  static List<String> get names => [
    '关闭',
    for (final server in _servers) server.name,
  ];

  static bool get enabled => url.isNotEmpty;

  /// com.github.tvbox.osc.util.OkGoHelper.getDohUrl
  static String get url =>
      _index >= 1 && _index <= _servers.length ? _servers[_index - 1].url : '';

  /// com.github.tvbox.osc.util.OkGoHelper.setDnsList
  static void setList(String json) {
    final text = json.isEmpty ? _defaultList : json;
    try {
      final list = _decode(text);
      if (list != null) {
        _servers = list;
      }
    } catch (_) {}
  }

  static List<({String name, String url})>? _decode(String text) {
    final dynamic parsed = jsonDecode(text);
    if (parsed is! List) {
      return null;
    }
    final servers = <({String name, String url})>[];
    for (final item in parsed) {
      if (item is Map) {
        servers.add((
          name: item['name']?.toString() ?? 'Unknown Name',
          url: item['url']?.toString() ?? '',
        ));
      }
    }
    return servers;
  }

  static void select(int index) {
    _index = index >= 0 && index <= _servers.length ? index : 0;
    _cache.clear();
  }

  /// com.github.tvbox.osc.util.OkGoHelper.CustomDns.lookup
  static Future<List<String>?> resolve(String host) async {
    if (!enabled) {
      return null;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final cached = _cache[host];
    if (cached != null && cached.expire > now) {
      return cached.ips;
    }
    try {
      final result = await _query(host);
      if (result == null || result.ips.isEmpty) {
        return null;
      }
      _cache[host] = (ips: result.ips, expire: now + result.ttl * 1000);
      return result.ips;
    } catch (_) {
      return null;
    }
  }

  static Future<({List<String> ips, int ttl})?> _query(String host) async {
    final request = _buildQuery(host);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 5);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.contentType = ContentType('application', 'dns-message');
      req.headers.set(HttpHeaders.acceptHeader, 'application/dns-message');
      req.headers.set(HttpHeaders.userAgentHeader, 'okhttp/3.15');
      req.add(request);
      final res = await req.close().timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        return null;
      }
      final builder = BytesBuilder(copy: false);
      await for (final chunk in res.timeout(const Duration(seconds: 5))) {
        builder.add(chunk);
      }
      return _parseResponse(builder.toBytes());
    } finally {
      client.close(force: true);
    }
  }

  static Uint8List _buildQuery(String host) {
    final labels = host.split('.').where((e) => e.isNotEmpty).toList();
    final builder = BytesBuilder(copy: false);
    final id = _random.nextInt(0x10000);
    builder
      ..addByte((id >> 8) & 0xff)
      ..addByte(id & 0xff)
      ..addByte(0x01)
      ..addByte(0x00)
      ..addByte(0x00)
      ..addByte(0x01);
    for (var i = 0; i < 6; i++) {
      builder.addByte(0);
    }
    for (final label in labels) {
      final bytes = label.codeUnits;
      builder
        ..addByte(bytes.length & 0x3f)
        ..add(bytes);
    }
    builder
      ..addByte(0)
      ..addByte(0x00)
      ..addByte(0x01)
      ..addByte(0x00)
      ..addByte(0x01);
    return builder.toBytes();
  }

  static ({List<String> ips, int ttl})? _parseResponse(Uint8List data) {
    if (data.length < 12) {
      return null;
    }
    int read16(int o) => (data[o] << 8) | data[o + 1];
    int read32(int o) =>
        (data[o] << 24) |
        (data[o + 1] << 16) |
        (data[o + 2] << 8) |
        data[o + 3];
    final questionCount = read16(4);
    final answerCount = read16(6);
    var offset = 12;
    for (var i = 0; i < questionCount; i++) {
      offset = _skipName(data, offset) + 4;
      if (offset > data.length) {
        return null;
      }
    }
    final ips = <String>[];
    var minTtl = 3600;
    for (var i = 0; i < answerCount; i++) {
      offset = _skipName(data, offset);
      if (offset + 10 > data.length) {
        break;
      }
      final type = read16(offset);
      final ttl = read32(offset + 4);
      final length = read16(offset + 8);
      final rdata = offset + 10;
      if (type == 1 && length == 4 && rdata + 4 <= data.length) {
        ips.add(
          '${data[rdata]}.${data[rdata + 1]}.${data[rdata + 2]}.${data[rdata + 3]}',
        );
        if (ttl < minTtl) {
          minTtl = ttl;
        }
      }
      offset = rdata + length;
    }
    if (ips.isEmpty) {
      return null;
    }
    return (ips: ips, ttl: minTtl < 30 ? 30 : (minTtl > 3600 ? 3600 : minTtl));
  }

  static int _skipName(Uint8List data, int offset) {
    while (offset < data.length) {
      final len = data[offset];
      if (len == 0) {
        return offset + 1;
      }
      if ((len & 0xc0) == 0xc0) {
        return offset + 2;
      }
      offset += 1 + len;
    }
    return offset;
  }
}
