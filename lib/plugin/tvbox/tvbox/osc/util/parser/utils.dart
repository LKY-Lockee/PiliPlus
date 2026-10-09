import 'dart:convert';

class JsonParseResult {
  /// com.github.tvbox.osc.util.parser.Utils.jsonParse+url
  final String url;

  /// com.github.tvbox.osc.util.parser.Utils.jsonParse+headers
  final Map<String, String> headers;

  const JsonParseResult(this.url, this.headers);
}

/// com.github.tvbox.osc.util.parser.Utils
class Utils {
  /// com.github.tvbox.osc.util.parser.Utils.RULE
  static final RegExp _videoRule = RegExp(
    r'http((?!http).){12,}?\.(m3u8|mp4|flv|avi|mkv|rm|wmv|mpg|m4a|mp3)\?.*|'
    r'http((?!http).){12,}\.(m3u8|mp4|flv|avi|mkv|rm|wmv|mpg|m4a|mp3)|'
    r'http((?!http).)*?video/tos*',
  );

  /// com.github.tvbox.osc.util.parser.Utils.isVip+_vipHosts
  static const _vipHosts = [
    'iqiyi.com',
    'v.qq.com',
    'youku.com',
    'le.com',
    'tudou.com',
    'mgtv.com',
    'sohu.com',
    'acfun.cn',
    'bilibili.com',
    'baofeng.com',
    'pptv.com',
  ];

  /// com.github.tvbox.osc.util.parser.Utils.UaWinChrome
  static const _uaWinChrome =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/94.0.4606.54 Safari/537.36';

  static String get uaWinChrome => _uaWinChrome;

  Utils._();

  /// com.github.tvbox.osc.util.parser.Utils.fixJsonVodHeader
  static Map<String, String> _fixJsonVodHeader(
    Map<String, String> headers,
    String input,
    String url,
  ) {
    if (input.contains('www.mgtv.com')) {
      headers['Referer'] = ' ';
      headers['User-Agent'] = ' Mozilla/5.0';
    } else if (url.contains('titan.mgtv')) {
      headers['Referer'] = ' ';
      headers['User-Agent'] = ' Mozilla/5.0';
    } else if (input.contains('bilibili')) {
      headers['Referer'] = ' https://www.bilibili.com/';
      headers['User-Agent'] = ' $_uaWinChrome';
    }
    return headers;
  }

  /// com.github.tvbox.osc.util.parser.Utils.isVip
  static bool isVip(String url) {
    for (final host in _vipHosts) {
      if (url.contains(host)) return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.util.parser.Utils.isVideoFormat
  static bool isVideoFormat(String url) {
    if (url.contains('url=http') ||
        url.contains('.js') ||
        url.contains('.css') ||
        url.contains('.html')) {
      return false;
    }
    return _videoRule.hasMatch(url);
  }

  /// com.github.tvbox.osc.util.parser.Utils.isBlackVodUrl
  static bool isBlackVodUrl(String url) {
    return url.contains('973973.xyz') || url.contains('.fit:');
  }

  /// com.github.tvbox.osc.util.parser.Utils.jsonParse
  static JsonParseResult? jsonParse(String input, String jsonStr) {
    try {
      final json = jsonDecode(jsonStr);
      if (json is! Map) return null;
      final data = json['data'];
      var url =
          (data is Map ? data['url'] : null)?.toString() ??
          json['url']?.toString() ??
          '';
      if (url.startsWith('//')) {
        url = 'https:$url';
      }
      if (!url.startsWith('http')) return null;
      if (url == input) {
        if (isVip(url) || !isVideoFormat(url)) return null;
      }
      if (isBlackVodUrl(url)) return null;

      final headers = <String, String>{};
      final ua = json['user-agent']?.toString().trim() ?? '';
      if (ua.isNotEmpty) headers['User-Agent'] = ' $ua';
      final referer = json['referer']?.toString().trim() ?? '';
      if (referer.isNotEmpty) headers['Referer'] = ' $referer';
      _fixJsonVodHeader(headers, input, url);
      return JsonParseResult(url, headers);
    } catch (_) {
      return null;
    }
  }
}
