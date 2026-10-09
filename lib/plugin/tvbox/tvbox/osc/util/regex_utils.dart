/// com.github.tvbox.osc.util.RegexUtils
class RegexUtils {
  /// com.github.tvbox.osc.util.RegexUtils.patternCache
  static final Map<String, RegExp?> _patternCache = {};

  RegexUtils._();

  /// com.github.tvbox.osc.util.RegexUtils.getPattern
  static RegExp? getPattern(String pattern) {
    if (_patternCache.containsKey(pattern)) return _patternCache[pattern];
    RegExp? reg;
    try {
      reg = RegExp(pattern);
    } catch (_) {}
    return _patternCache[pattern] = reg;
  }
}
