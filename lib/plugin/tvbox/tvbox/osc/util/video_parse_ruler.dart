import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/default_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/regex_utils.dart';

/// com.github.tvbox.osc.util.VideoParseRuler
class VideoParseRuler {
  /// com.github.tvbox.osc.util.VideoParseRuler.HOSTS_RULE
  static final Map<String, List<List<String>>> _hostsRule = {};

  /// com.github.tvbox.osc.util.VideoParseRuler.HOSTS_FILTER
  static final Map<String, List<List<String>>> _hostsFilter = {};

  /// com.github.tvbox.osc.util.VideoParseRuler.HOSTS_REGEX
  static final Map<String, List<String>> _hostsRegex = {};

  /// com.github.tvbox.osc.util.VideoParseRuler.HOSTS_SCRIPT
  static final Map<String, List<String>> _hostsScript = {};

  VideoParseRuler._();

  /// com.github.tvbox.osc.util.VideoParseRuler.checkVideoForOneHostRules
  static bool _checkForOneHost(List<List<String>>? groups, String url) {
    if (groups == null || groups.isEmpty) return false;
    for (final group in groups) {
      if (group.isEmpty) continue;
      var checkIsVideo = true;
      for (final pattern in group) {
        final onePattern = RegexUtils.getPattern(pattern);
        if (onePattern == null || !onePattern.hasMatch(url)) {
          checkIsVideo = false;
          break;
        }
      }
      if (checkIsVideo) return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.clearRule
  static void clearRule() {
    _hostsRule.clear();
    _hostsFilter.clear();
    _hostsRegex.clear();
    _hostsScript.clear();
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.addHostRule
  static void addHostRule(String host, List<String> rule) {
    if (rule.isEmpty) return;
    (_hostsRule[host] ??= <List<String>>[]).add(List.of(rule));
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.getHostRules
  static List<List<String>>? getHostRules(String host) => _hostsRule[host];

  /// com.github.tvbox.osc.util.VideoParseRuler.addHostFilter
  static void addHostFilter(String host, List<String> filter) {
    if (filter.isEmpty) return;
    (_hostsFilter[host] ??= <List<String>>[]).add(List.of(filter));
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.getHostFilters
  static List<List<String>>? getHostFilters(String host) => _hostsFilter[host];

  /// com.github.tvbox.osc.util.VideoParseRuler.addHostRegex
  static void addHostRegex(String host, List<String> regex) {
    if (regex.isEmpty) return;
    (_hostsRegex[host] ??= <String>[]).addAll(regex);
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.getHostsRegex
  static Map<String, List<String>> getHostsRegex() => _hostsRegex;

  /// com.github.tvbox.osc.util.VideoParseRuler.addHostScript
  static void addHostScript(String host, List<String> script) {
    if (script.isEmpty) return;
    (_hostsScript[host] ??= <String>[]).addAll(script);
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.getHostScript
  static String getHostScript(String url) {
    for (final entry in _hostsScript.entries) {
      if (url.contains(entry.key)) {
        final list = entry.value;
        if (list.isNotEmpty) {
          return list.first;
        }
      }
    }
    return '';
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.checkIsVideoForParse
  static bool checkIsVideoForParse(String? webUrl, String url) {
    var isVideo = DefaultConfig.isVideoFormat(url);
    if (_hostsRule.isNotEmpty && !isVideo && webUrl != null) {
      final host = Uri.tryParse(webUrl)?.host;
      final rules = host == null ? null : getHostRules(host);
      if (rules != null) {
        isVideo = _checkForOneHost(rules, url);
      } else {
        isVideo = _checkForOneHost(getHostRules('*'), url);
      }
    }
    return isVideo;
  }

  /// com.github.tvbox.osc.util.VideoParseRuler.isFilter
  static bool isFilter(String? webUrl, String url) {
    if (_hostsFilter.isEmpty || webUrl == null) return false;
    final host = Uri.tryParse(webUrl)?.host;
    final filters = host == null ? null : getHostFilters(host);
    if (filters == null) return false;
    return _checkForOneHost(filters, url);
  }

  static bool checkVideoForOneHostRules(String host, String url) =>
      _checkForOneHost(getHostRules(host), url);
}
