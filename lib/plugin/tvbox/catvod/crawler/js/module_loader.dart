import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;

class JsModules {
  static String? Function(String url)? onFetchSync;

  static Map<String, String>? _builtin;

  static final _importRe = RegExp(
    r'''(?:from\s*['"`]([^'"`]+)['"`])|'''
    r'''(?:import\s*\(\s*['"`]([^'"`]+)['"`])|'''
    r'''(?:import\s*['"`]([^'"`]+)['"`])|'''
    r'''(?:require\s*\(\s*['"`]([^'"`]+)['"`])''',
  );

  static final _urlLiteralRe = RegExp(
    r'''https?://[^\s'"`)\]}<>\\]+?\.js(?:\?[^\s'"`)\]}<>\\]*)?''',
    caseSensitive: false,
  );

  static final _moduleCache = <String, ({DateTime expires, String src})>{};

  static const builtinNames = [
    'net.js',
    'cheerio.min.js',
    'crypto-js.js',
    'gbk.js',
    'similarity.js',
    'cat.js',
    '模板.js',
  ];

  /// com.github.catvod.crawler.js.JsSpider.EMPTY_MODULE_CODE
  static const String emptyModuleSource =
      'const empty = null;\n'
      'export default empty;\n'
      'export const JSEncrypt = empty;\n'
      'export const NodeRSA = empty;\n'
      'export const pako = empty;\n'
      'export const JSON5 = empty;\n'
      'export const mb = empty;\n'
      'export const parse = empty;\n'
      'export const stringify = empty;\n'
      'export const inflate = empty;\n'
      'export const deflate = empty;\n'
      'export const gzip = empty;\n'
      'export const ungzip = empty;\n'
      'export const encrypt = empty;\n'
      'export const decrypt = empty;\n';

  JsModules._();

  static Future<Map<String, String>> loadBuiltin() async {
    if (_builtin != null) return _builtin!;
    final map = <String, String>{};
    for (final name in builtinNames) {
      map[name] = await rootBundle.loadString('assets/js/lib/$name');
    }
    return _builtin = map;
  }

  static String wrapCryptoJs(String source) {
    return 'var module = {exports:{}}; var exports = module.exports;\n'
        '$source\n'
        'export default module.exports;\n';
  }

  /// com.github.catvod.crawler.js.JsSpider.isInvalidModuleContent
  static bool isInvalidModuleContent(String? content) {
    if (content == null || content.isEmpty) return true;
    var trim = content.trim();
    if (trim.startsWith('\uFEFF')) trim = trim.substring(1).trim();
    final lower = trim.toLowerCase();
    return lower.startsWith('<') ||
        lower.startsWith('{"code":404') ||
        lower.startsWith('404') ||
        lower.startsWith('not found');
  }

  static String? lookup(Map<String, String> modules, String name) {
    final direct = modules[name];
    if (direct != null) return direct;
    final trimmed = name.startsWith('./') ? name.substring(2) : name;
    final byTrimmed = modules[trimmed];
    if (byTrimmed != null) return byTrimmed;
    final base = trimmed.split('/').last;
    return modules[base];
  }

  static String normalizeKey(String name) {
    if (name.startsWith('./')) return name.substring(2);
    return name;
  }

  static Iterable<String> extractImports(String source) sync* {
    for (final m in _importRe.allMatches(source)) {
      final name = m.group(1) ?? m.group(2) ?? m.group(3) ?? m.group(4);
      if (name != null) yield name;
    }
  }

  static Iterable<String> extractUrlLiterals(String source) sync* {
    for (final m in _urlLiteralRe.allMatches(source)) {
      yield m.group(0)!;
    }
  }

  static void register(
    Map<String, String> into,
    String name,
    String source,
  ) {
    into[name] = source;
    final base = name.split('/').last.split('?').first;
    if (base.isNotEmpty) {
      into.putIfAbsent(base, () => source);
    }
  }

  static Future<void> prefetchImports(
    String source, {
    required String baseUrl,
    required Map<String, String> into,
    Iterable<String> extra = const [],
  }) async {
    final names = <String>{...extractImports(source), ...extra};
    for (final name in names) {
      if (lookup(into, name) != null) continue;
      await prefetchModule(name, baseUrl: baseUrl, into: into);
    }
  }

  static Future<void> prefetchModule(
    String name, {
    required String baseUrl,
    required Map<String, String> into,
  }) async {
    Uri? uri;
    try {
      uri = name.startsWith('http')
          ? Uri.parse(name)
          : Uri.parse(baseUrl).resolve(name);
    } catch (_) {}
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return;
    }
    final url = uri.toString();
    if (into.containsKey(url)) return;
    String? src;
    try {
      src = await fetchModule(url);
    } catch (_) {
      src = null;
    }
    if (src == null) return;
    register(into, url, src);
    await prefetchImports(src, baseUrl: url, into: into);
  }

  @visibleForTesting
  static void preseedModule(String url, String src) {
    _moduleCache[url] = (
      expires: DateTime.now().add(const Duration(hours: 1)),
      src: src,
    );
  }

  /// com.github.catvod.crawler.JsLoader.loadJarInternal
  static Future<String?> fetchModule(String url) async {
    final cached = _moduleCache[url];
    if (cached != null && cached.expires.isAfter(DateTime.now())) {
      return cached.src;
    }
    final resp = await Http.get(url);
    final src = resp.data;
    if (src == null || src.isEmpty) return null;
    if (src.startsWith('//DRPY') || src.startsWith('//bb')) {
      throw UnsupportedError('不支持字节码模块: $url');
    }
    _moduleCache[url] = (
      expires: DateTime.now().add(const Duration(days: 7)),
      src: src,
    );
    return src;
  }
}
