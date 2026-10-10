import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/js_loader.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/crawler/spider.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/parse_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/ad_blocker.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/aes.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/http_helper.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/m3u8.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/video_parse_ruler.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive_ce/hive.dart';

/// com.github.tvbox.osc.api.ApiConfig
class ApiConfig {
  final String url;

  /// com.github.tvbox.osc.api.ApiConfig.spider
  final String spider;

  /// com.github.tvbox.osc.api.ApiConfig.sourceBeanList
  final List<SourceBean> sourceBeanList;

  /// com.github.tvbox.osc.api.ApiConfig.parseBeanList
  final List<ParseBean> parseBeanList;

  /// com.github.tvbox.osc.api.ApiConfig.vipParseFlags
  final List<String> vipParseFlags;

  /// com.github.tvbox.osc.api.ApiConfig.liveChannelGroupList
  final List<dynamic> lives;

  /// com.github.tvbox.osc.api.ApiConfig.myHosts
  final Map<String, String> myHosts;

  /// com.github.tvbox.osc.api.ApiConfig.wallpaper
  final String? wallpaper;

  /// com.github.tvbox.osc.api.ApiConfig.loadConfig+_cache
  static final Box _cache = GStorage.localCache;

  const ApiConfig({
    required this.url,
    this.spider = '',
    this.sourceBeanList = const [],
    this.parseBeanList = const [],
    this.vipParseFlags = const [],
    this.lives = const [],
    this.myHosts = const {},
    this.wallpaper,
  });

  /// com.github.tvbox.osc.api.ApiConfig.clanToAddress
  static String _clanToAddress(String clan) {
    final uri = Uri.tryParse(clan);
    if (uri == null) {
      return clan;
    }
    final host = uri.host.isEmpty || uri.host == 'localhost'
        ? '127.0.0.1:9978'
        : uri.authority;
    return 'http://$host/file${uri.path}';
  }

  /// com.github.tvbox.osc.api.ApiConfig.fixContentPath
  static String _fixContentPath(String content, String configUrl) {
    content = content.replaceAllMapped(
      RegExp(r'"\.\./([^"]*)"'),
      (m) => '"${Uri.parse(configUrl).resolve('../${m[1]}').toString()}"',
    );
    return content.replaceAllMapped(
      RegExp(r'"\./([^"]*)"'),
      (m) => '"${Uri.parse(configUrl).resolve(m[1]!).toString()}"',
    );
  }

  /// com.github.tvbox.osc.api.ApiConfig.fetchConfigAsync
  static Future<String?> _fetch(String configUrl) async {
    final res = await Http.get(
      configUrl,
      options: Options(responseType: ResponseType.plain),
    );
    return res.data;
  }

  /// com.github.tvbox.osc.api.ApiConfig.parseJson
  static ApiConfig? _parse(String body, String configUrl) {
    try {
      final jsonStr = _fixContentPath(body, configUrl);
      final json = AES.tryDecode(jsonStr);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final config = ApiConfig.fromJson(configUrl, json);
      if (config == null) {
        return null;
      }
      _parseRules(json['rules']);
      _parseAdHosts(json['ads']);
      TVBoxHttpHelper.setDnsList(config.myHosts);
      return config;
    } catch (_) {
      return null;
    }
  }

  /// com.github.tvbox.osc.api.ApiConfig.parseApiCollection
  static String? _parseCollection(String body) {
    try {
      final json = AES.tryDecode(body);
      if (json is! Map<String, dynamic> ||
          json['sites'] != null ||
          json['urls'] is! List) {
        return null;
      }
      for (final item in json['urls']) {
        if (item is Map<String, dynamic>) {
          final url = item['url'] ?? item['api'];
          if (url is String && url.isNotEmpty) {
            return url;
          }
        } else if (item is String && item.isNotEmpty) {
          return item;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// com.github.tvbox.osc.api.ApiConfig.parseJson
  static void _parseRules(dynamic rulesJson) {
    VideoParseRuler.clearRule();
    if (rulesJson is! List) return;
    for (final item in rulesJson) {
      if (item is! Map<String, dynamic>) continue;
      final host = item['host'];
      if (host is String && host.isNotEmpty) {
        final rule = _strList(item['rule']);
        final filter = _strList(item['filter']);
        if (rule.isNotEmpty) VideoParseRuler.addHostRule(host, rule);
        if (filter.isNotEmpty) VideoParseRuler.addHostFilter(host, filter);
      }
      final hosts = _strList(item['hosts']);
      if (hosts.isNotEmpty) {
        final regex = _strList(item['regex']);
        if (regex.isNotEmpty) {
          final ads = <String>[];
          final normal = <String>[];
          for (final one in regex) {
            if (M3u8.isAd(one)) {
              ads.add(one);
            } else {
              normal.add(one);
            }
          }
          for (final one in hosts) {
            VideoParseRuler.addHostRule(one, normal);
            VideoParseRuler.addHostRegex(one, ads);
          }
        }
        final script = _strList(item['script']);
        if (script.isNotEmpty) {
          for (final one in hosts) {
            VideoParseRuler.addHostScript(one, script);
          }
        }
      }
    }
  }

  static List<String> _strList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// com.github.tvbox.osc.api.ApiConfig.parseJson
  static void _parseAdHosts(dynamic adsJson) {
    AdBlocker.reset();
    if (adsJson is List) {
      for (final host in adsJson.whereType<String>()) {
        AdBlocker.addAdHost(host);
      }
    }
  }

  static void _clearRuntimeConfig() {
    VideoParseRuler.clearRule();
    AdBlocker.reset();
    TVBoxHttpHelper.setDnsList(const {});
  }

  static String cacheKey(String url) =>
      'vodConfigCache_${md5.convert(utf8.encode(url)).toString()}';

  /// com.github.tvbox.osc.api.ApiConfig.configUrl
  static (String, String?) resolveConfigUrl(String apiUrl) {
    String? pkKey;
    var url = apiUrl.replaceAll('file://', 'clan://localhost/');
    const pk = ';pk;';
    if (url.contains(pk)) {
      final parts = url.split(pk);
      pkKey = parts.length > 1 ? parts[1] : null;
      url = parts[0];
    }
    if (url.startsWith('clan')) {
      url = _clanToAddress(url);
    } else if (!url.startsWith('http')) {
      url = 'http://$url';
    }
    return (url, pkKey);
  }

  /// com.github.tvbox.osc.api.ApiConfig.FindResult
  static String decrypt(String body, String? pkKey) {
    var content = body.startsWith('\uFEFF') ? body.substring(1) : body;
    try {
      if (AES.isJson(content)) {
        return content;
      }
      final marker = RegExp('[A-Za-z0-9]{8}\\*\\*').firstMatch(content);
      if (marker != null) {
        content = content.substring(content.indexOf(marker.group(0)!) + 10);
        content = utf8.decode(base64.decode(content), allowMalformed: true);
      }
      content = content.trim();
      if (content.startsWith('2423')) {
        final stripped = content.replaceAll(RegExp(r'\s+'), '');
        final data = stripped.substring(
          stripped.indexOf('2324') + 4,
          stripped.length - 26,
        );
        final decoded = utf8
            .decode(AES.toBytes(stripped), allowMalformed: true)
            .toLowerCase();
        final keyStart = decoded.indexOf(r'$#');
        final keyEnd = decoded.indexOf('#\$');
        if (keyStart < 0 || keyEnd <= keyStart + 1) {
          return content;
        }
        final key = utf8.encode(
          AES.rightPadding(decoded.substring(keyStart + 2, keyEnd), '0', 16),
        );
        final iv = utf8.encode(
          AES.rightPadding(decoded.substring(decoded.length - 13), '0', 16),
        );
        return utf8.decode(
          AES.cbc(AES.toBytes(data), key, iv),
          allowMalformed: true,
        );
      } else if (pkKey != null && !AES.isJson(content)) {
        return utf8.decode(
          AES.ecb(
            AES.toBytes(content),
            utf8.encode(AES.rightPadding(pkKey, '0', 16)),
          ),
          allowMalformed: true,
        );
      }
      return content;
    } catch (_) {
      return body;
    }
  }

  /// com.github.tvbox.osc.api.ApiConfig.loadConfig
  static Future<LoadingState<ApiConfig>> load({bool useCache = false}) async {
    var url = Pref.vodConfigUrl;
    if (url.isEmpty) {
      _clearRuntimeConfig();
      return const Error('未配置点播订阅');
    }
    for (var attempt = 0; attempt < 3; attempt++) {
      final (configUrl, pkKey) = resolveConfigUrl(url);
      final key = cacheKey(url);

      String? jsonStr;
      if (useCache) {
        final cached = _cache.get(key);
        if (cached is String) {
          jsonStr = cached;
        }
      }
      jsonStr ??= await _fetch(configUrl);

      if (jsonStr == null) {
        final cached = _cache.get(key);
        if (cached is String) {
          jsonStr = cached;
        }
      }
      if (jsonStr == null) {
        _clearRuntimeConfig();
        return const Error('拉取配置失败');
      }

      final body = decrypt(jsonStr, pkKey);
      final config = _parse(body, configUrl);
      if (config != null) {
        _cache.put(key, body);
        return Success(config);
      }

      final redirect = _parseCollection(body);
      if (redirect != null && redirect != url) {
        url = redirect;
        Pref.setVodConfigUrl = url;
        continue;
      }
      _clearRuntimeConfig();
      return const Error('配置解析失败');
    }
    _clearRuntimeConfig();
    return const Error('配置解析失败');
  }

  /// com.github.tvbox.osc.api.ApiConfig.parseJson
  static ApiConfig? fromJson(String url, Map<String, dynamic> json) {
    final sitesJson = json['sites'];
    final sites = <SourceBean>[];
    if (sitesJson is List) {
      for (final site in sitesJson) {
        if (site is Map<String, dynamic>) {
          final bean = SourceBean.fromJson(site);
          if (bean != null) {
            sites.add(bean);
          }
        }
      }
    }
    if (sites.isEmpty) {
      return null;
    }

    final parses = <ParseBean>[];
    final parsesJson = json['parses'];
    if (parsesJson is List) {
      for (final parse in parsesJson) {
        final bean = ParseBean.fromJson(parse);
        if (bean != null) {
          parses.add(bean);
        }
      }
    }

    final hosts = <String, String>{};
    final hostsJson = json['hosts'];
    if (hostsJson is List) {
      for (final host in hostsJson.whereType<String>()) {
        final idx = host.indexOf('=');
        if (idx > 0) {
          hosts[host.substring(0, idx)] = host.substring(idx + 1);
        }
      }
    }

    return ApiConfig(
      url: url,
      spider: json['spider'] is String ? json['spider'] as String : '',
      sourceBeanList: sites,
      parseBeanList: parses,
      vipParseFlags: json['flags'] is List
          ? (json['flags'] as List).whereType<String>().toList()
          : const [],
      lives: json['lives'] is List ? json['lives'] as List : const [],
      myHosts: hosts,
      wallpaper: json['wallpaper'] is String
          ? json['wallpaper'] as String
          : null,
    );
  }

  /// com.github.tvbox.osc.api.ApiConfig.getSource
  SourceBean? getSource(String key) =>
      sourceBeanList.where((e) => e.key == key).firstOrNull;

  /// com.github.tvbox.osc.api.ApiConfig.getSourceBeanList
  List<SourceBean> getSourceBeanList() => sourceBeanList;

  /// com.github.tvbox.osc.api.ApiConfig.getCSP
  Future<Spider> getCSP(SourceBean bean) => JsLoader.instance.getSpider(
    bean.key,
    bean.api,
    bean.ext,
    timeoutSeconds: bean.playTimeoutSeconds,
  );
}
