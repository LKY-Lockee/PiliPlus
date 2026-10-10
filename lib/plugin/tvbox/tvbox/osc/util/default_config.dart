/// com.github.tvbox.osc.util.DefaultConfig
class DefaultConfig {
  /// com.github.tvbox.osc.util.DefaultConfig.snifferMatch
  static final RegExp _videoFmtExp = RegExp(
    r'http((?!http).){12,}?\.(m3u8|mp4|flv|avi|mkv|rm|wmv|mpg|m4a)\?.*|'
    r'http((?!http).){12,}\.(m3u8|mp4|flv|avi|mkv|rm|wmv|mpg|m4a)|'
    r'http((?!http).)*?video/tos*|'
    r'http((?!http).){20,}?/m3u8\?pt=m3u8.*|'
    r'http((?!http).)*?default\.ixigua\.com/.*|'
    r'http((?!http).)*?dycdn-tos\.pstatp[^\?]*|'
    r'http.*?/player/m3u8play\.php\?url=.*|'
    r'http.*?/player/.*?[pP]lay\.php\?url=.*|'
    r'http.*?/playlist/m3u8/\?vid=.*|'
    r'http.*?\.php\?type=m3u8&.*|'
    r'http.*?/download\.aspx\?.*|'
    r'http.*?/api/up_api\.php\?.*|'
    r'https.*?\.66yk\.cn.*|'
    r'http((?!http).)*?netease\.com/file/.*',
  );

  DefaultConfig._();

  /// com.github.tvbox.osc.util.DefaultConfig.isVideoFormat
  static bool isVideoFormat(String url) {
    final path = Uri.tryParse(url)?.path;
    if (path == null || path.isEmpty) {
      return false;
    }
    return _videoFmtExp.hasMatch(url);
  }

  /// com.github.tvbox.osc.util.DefaultConfig.NO_AD_KEYWORDS
  static const List<String> noAdKeywords = [
    'tx',
    'youku',
    'qq',
    'qiyi',
    'letv',
    'leshi',
    'sohu',
    'mgtv',
    'bilibili',
    'imgo',
    '优酷',
    '芒果',
    '腾讯',
    '奇艺',
  ];

  /// com.github.tvbox.osc.util.DefaultConfig.noAd
  static bool noAd(String? flag) {
    if (flag == null || flag.isEmpty) return false;
    for (final keyword in noAdKeywords) {
      if (flag == keyword || flag.contains(keyword)) return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.util.DefaultConfig.safeJsonInt
  static int safeJsonInt(dynamic v, int def) {
    if (v is int) {
      return v;
    }
    if (v is String) {
      return int.tryParse(v) ?? def;
    }
    return def;
  }
}
