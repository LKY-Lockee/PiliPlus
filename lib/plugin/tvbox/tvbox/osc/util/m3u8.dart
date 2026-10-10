import 'dart:math' as math;

import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/regex_utils.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/video_parse_ruler.dart';
import 'package:flutter/foundation.dart';

/// com.github.tvbox.osc.util.M3u8
class M3u8 {
  M3u8._();

  static const String _tagDiscontinuity = '#EXT-X-DISCONTINUITY';
  static const String _tagMediaDuration = '#EXTINF';
  static const String _tagEndlist = '#EXT-X-ENDLIST';
  static const String _tagKey = '#EXT-X-KEY';
  static const String _tagMap = '#EXT-X-MAP';
  static const String _tagCueOut = '#EXT-X-CUE-OUT';
  static const String _tagCueIn = '#EXT-X-CUE-IN';
  static const String _tagDaterange = '#EXT-X-DATERANGE';

  static final RegExp _regexXDiscontinuity = RegExp(
    '#EXT-X-DISCONTINUITY[\\s\\S]*?(?=#EXT-X-DISCONTINUITY|\$)',
  );
  static final RegExp _regexMediaDuration = RegExp(
    '$_tagMediaDuration:([\\d\\.]+)\\b',
  );
  static final RegExp _regexUri = RegExp('URI="(.+?)"');

  static final RegExp _regexAdSegmentUri = RegExp(
    '(^|[/?&=_.-])(ads?|adv|advert(ise(ment)?)?|commercial|preroll|pre-roll|midroll|mid-roll|postroll|post-roll|sponsor|scte|vast|vmap|interstitial|bumper)([/?&=_.-]|\$)',
    caseSensitive: false,
  );

  static const List<String> _adDomainKeywords = [
    'adservice',
    'adserver',
    'adsystem',
    'doubleclick',
    'googlesyndication',
    'advertising',
    '2mdn.net',
    'moatads',
    'scorecardresearch',
    'quantserve',
  ];

  static const int _maxFrameRateAdBlockSize = 12;
  static const int _timesNoAd = 15;

  static final Map<int, Set<String>> _frameRateFeatures =
      _prepareFrameRateFeatures();

  /// com.github.tvbox.osc.util.M3u8.currentAdCount
  static int currentAdCount = 0;

  /// com.github.tvbox.osc.util.M3u8.isAd
  static bool isAd(String regex) {
    return regex.contains(_tagDiscontinuity) ||
        regex.contains(_tagMediaDuration) ||
        regex.contains(_tagEndlist) ||
        regex.contains(_tagKey) ||
        regex.contains(_tagCueOut) ||
        regex.contains(_tagCueIn) ||
        regex.contains(_tagDaterange) ||
        isDouble(regex);
  }

  /// com.github.tvbox.osc.util.M3u8.isDouble
  static bool isDouble(String ad) {
    final value = double.tryParse(ad);
    return value != null && value != 0;
  }

  /// com.github.tvbox.osc.util.M3u8.purify
  static String? purify(String tsUrlPre, String? m3u8content) {
    currentAdCount = 0;
    if (m3u8content == null || m3u8content.isEmpty) return null;
    if (m3u8content.startsWith('\uFEFF')) {
      m3u8content = m3u8content.substring(1);
    }
    if (!m3u8content.startsWith('#EXTM3U')) return null;

    var totalSegments = 0;
    final lines = m3u8content.split(
      m3u8content.contains('\r\n') ? '\r\n' : '\n',
    );
    for (final line in lines) {
      if (line.isNotEmpty && line[0] != '#') totalSegments++;
    }

    var result = _removeMinorityUrl(tsUrlPre, m3u8content);
    if (result != null && currentAdCount > 0) {
      result = _get(tsUrlPre, result);
    } else {
      result = _get(tsUrlPre, m3u8content);
    }
    result = _keepVodEndList(m3u8content, result);

    if (totalSegments > 0 && currentAdCount > totalSegments * 0.5) {
      debugPrint(
        '[tvbox-m3u8] removed too many segments '
        '$currentAdCount/$totalSegments, using original content',
      );
      currentAdCount = 0;
      result = m3u8content;
    }
    if (currentAdCount > 0 && !_isPlayableMediaPlaylist(result)) {
      debugPrint(
        '[tvbox-m3u8] invalid playlist after ad removal, '
        'using original content',
      );
      currentAdCount = 0;
      result = m3u8content;
    }
    debugPrint('[tvbox-m3u8] removed $currentAdCount segments');
    return result;
  }

  /// com.github.tvbox.osc.util.M3u8.maxPercent
  static double _maxPercent(Map<String, int> preUrlMap) {
    var maxTimes = 0;
    var totalTimes = 0;
    for (final entry in preUrlMap.entries) {
      if (entry.value > maxTimes) maxTimes = entry.value;
      totalTimes += entry.value;
    }
    return maxTimes / totalTimes;
  }

  /// com.github.tvbox.osc.util.M3u8.removeMinorityUrl
  static String? _removeMinorityUrl(String tsUrlPre, String m3u8content) {
    final linesplit = m3u8content.contains('\r\n') ? '\r\n' : '\n';
    final lines = _splitBy(m3u8content, linesplit);

    var totalSegments = 0;
    for (final line in lines) {
      if (line.isNotEmpty && line[0] != '#') totalSegments++;
    }

    final preUrlMap = <String, int>{};
    for (final line in lines) {
      if (line.isEmpty || line[0] == '#') continue;
      final absoluteUrl = _toAbsoluteUrl(tsUrlPre, line);
      final ilast = absoluteUrl.lastIndexOf('.');
      if (ilast <= 4) continue;
      final preUrl = absoluteUrl.substring(0, ilast - 4);
      preUrlMap[preUrl] = (preUrlMap[preUrl] ?? 0) + 1;
    }
    if (preUrlMap.length <= 1) return null;

    var domainFiltering = false;
    if (_maxPercent(preUrlMap) < 0.8) {
      preUrlMap.clear();
      for (final line in lines) {
        if (line.isEmpty || line[0] == '#') continue;
        final absoluteUrl = _toAbsoluteUrl(tsUrlPre, line);
        if (!absoluteUrl.startsWith('http://') &&
            !absoluteUrl.startsWith('https://')) {
          return null;
        }
        final ifirst = absoluteUrl.indexOf('/', 9);
        if (ifirst <= 0) continue;
        final preUrl = absoluteUrl.substring(0, ifirst);
        preUrlMap[preUrl] = (preUrlMap[preUrl] ?? 0) + 1;
      }
      if (preUrlMap.length <= 1) return null;
      if (_maxPercent(preUrlMap) < 0.8) return null;
      var allDomainsExceedThreshold = true;
      for (final count in preUrlMap.values) {
        if (count <= _timesNoAd) {
          allDomainsExceedThreshold = false;
          break;
        }
      }
      if (allDomainsExceedThreshold) return null;
      domainFiltering = true;
    }

    var maxTimes = 0;
    var maxTimesPreUrl = '';
    for (final entry in preUrlMap.entries) {
      if (entry.value > maxTimes) {
        maxTimesPreUrl = entry.key;
        maxTimes = entry.value;
      }
    }
    if (maxTimes == 0) return null;

    debugPrint(
      '[tvbox-m3u8] URL pattern count: ${preUrlMap.length}, '
      'maxTimes: $maxTimes, total: $totalSegments',
    );

    final filtered = StringBuffer();
    final pendingSegmentTags = <String>[];
    for (final raw in lines) {
      final item = raw.trim();
      if (item.isEmpty) {
        if (pendingSegmentTags.isEmpty) {
          _appendLine(filtered, raw, linesplit);
        } else {
          pendingSegmentTags.add(raw);
        }
        continue;
      }
      if (item[0] == '#') {
        final output = _hasUriAttribute(item)
            ? _resolveUriLine(tsUrlPre, raw)
            : raw;
        if (_isSegmentTag(item)) {
          pendingSegmentTags.add(output);
        } else {
          _flushLines(filtered, pendingSegmentTags, linesplit);
          _appendLine(filtered, output, linesplit);
        }
        continue;
      }

      final absoluteUrl = _toAbsoluteUrl(tsUrlPre, raw);
      if (_shouldKeepMediaUrl(
        absoluteUrl,
        domainFiltering,
        maxTimesPreUrl,
        preUrlMap,
      )) {
        _flushLines(filtered, pendingSegmentTags, linesplit);
        _appendLine(filtered, absoluteUrl, linesplit);
      } else {
        pendingSegmentTags.clear();
        currentAdCount++;
      }
    }

    if (totalSegments > 0 && currentAdCount > totalSegments * 0.3) {
      debugPrint(
        '[tvbox-m3u8] suspicious ad count: $currentAdCount/$totalSegments, '
        'skipping URL filtering',
      );
      currentAdCount = 0;
      return null;
    }

    return _normalizeMediaPlaylist(filtered.toString());
  }

  /// com.github.tvbox.osc.util.M3u8.get
  static String _get(String tsUrlPre, String m3u8Content) {
    var line = _resolveContent(tsUrlPre, m3u8Content);
    final ads = _getRegex(tsUrlPre);
    if (ads != null && ads.isNotEmpty) line = _clean(line, ads);
    line = _cleanCommonAdMarkers(line);
    if (_hasEndList(line) && line.contains(_tagDiscontinuity)) {
      line = _cleanDecimalPrecisionGroups(line);
      line = _cleanFrameRateGroups(line);
    }
    return _cleanDiscontinuityGroups(line);
  }

  /// com.github.tvbox.osc.util.M3u8.cleanDecimalPrecisionGroups
  static String _cleanDecimalPrecisionGroups(String m3u8Content) {
    final groups = _buildDiscontinuityGroups(_splitBy(m3u8Content, '\n'));
    if (groups.length < 2) return m3u8Content;

    final precisionCounts = <int, int>{};
    var totalSegments = 0;
    for (final group in groups) {
      for (final raw in group.lines) {
        final precision = _getDecimalPrecision(raw);
        if (precision < 0) continue;
        totalSegments++;
        precisionCounts[precision] = (precisionCounts[precision] ?? 0) + 1;
      }
    }
    if (totalSegments < 8 || precisionCounts.length < 2) return m3u8Content;

    var majorPrecision = -1;
    var majorCount = 0;
    for (final entry in precisionCounts.entries) {
      if (entry.value > majorCount) {
        majorPrecision = entry.key;
        majorCount = entry.value;
      }
    }
    if (majorPrecision < 0 || majorCount / totalSegments < 0.7) {
      return m3u8Content;
    }

    final removeGroups = List<bool>.filled(groups.length, false);
    var removableSegments = 0;
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (i == groups.length - 1 ||
          group.segmentCount == 0 ||
          group.segmentCount > _maxFrameRateAdBlockSize) {
        continue;
      }
      final stats = _getDecimalPrecisionStats(group, majorPrecision);
      if (stats.total > 0 && stats.mismatched == stats.total) {
        removeGroups[i] = true;
        removableSegments += group.segmentCount;
      }
    }

    if (removableSegments == 0 ||
        removableSegments > _getAdSegmentLimit(m3u8Content) ||
        removableSegments > totalSegments * 0.3) {
      return m3u8Content;
    }

    final sb = StringBuffer();
    var removedBlocks = 0;
    for (var i = 0; i < groups.length; i++) {
      if (removeGroups[i]) {
        currentAdCount += groups[i].segmentCount;
        removedBlocks++;
      } else {
        groups[i].appendTo(sb);
      }
    }
    debugPrint(
      '[tvbox-m3u8] decimal precision detected: major=$majorPrecision, '
      'blocks=$removedBlocks, removed=$removableSegments',
    );
    return _normalizeMediaPlaylist(sb.toString());
  }

  /// com.github.tvbox.osc.util.M3u8.getDecimalPrecisionStats
  static _DecimalPrecisionStats _getDecimalPrecisionStats(
    _Group group,
    int majorPrecision,
  ) {
    final stats = _DecimalPrecisionStats();
    for (final raw in group.lines) {
      final precision = _getDecimalPrecision(raw);
      if (precision < 0) continue;
      stats.total++;
      if (precision != majorPrecision) stats.mismatched++;
    }
    return stats;
  }

  /// com.github.tvbox.osc.util.M3u8.getDecimalPrecision
  static int _getDecimalPrecision(String line) {
    final start = _getExtInfValueStart(line);
    if (start < 0) return -1;
    final end = _getExtInfValueEnd(line, start);
    final dot = line.indexOf('.', start);
    return dot < 0 || dot >= end ? 0 : end - dot - 1;
  }

  /// com.github.tvbox.osc.util.M3u8.cleanFrameRateGroups
  static String _cleanFrameRateGroups(String m3u8Content) {
    final groups = _buildDiscontinuityGroups(_splitBy(m3u8Content, '\n'));
    if (groups.length < 2) return m3u8Content;

    final masterFrameRate = _findDominantFrameRate(groups);
    if (masterFrameRate == 0) return m3u8Content;

    var removableSegments = 0;
    final removeGroups = List<bool>.filled(groups.length, false);
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (i == groups.length - 1 ||
          group.segmentCount == 0 ||
          group.segmentCount > _maxFrameRateAdBlockSize) {
        continue;
      }
      final stats = _getFrameRateStats(group, masterFrameRate);
      if (stats.mismatched > 0 && stats.mismatched >= stats.matched) {
        removeGroups[i] = true;
        removableSegments += group.segmentCount;
      }
    }

    final segmentLimit = _getAdSegmentLimit(m3u8Content);
    if (removableSegments == 0 || removableSegments > segmentLimit) {
      return m3u8Content;
    }

    final sb = StringBuffer();
    var removedBlocks = 0;
    for (var i = 0; i < groups.length; i++) {
      if (removeGroups[i]) {
        currentAdCount += groups[i].segmentCount;
        removedBlocks++;
      } else {
        groups[i].appendTo(sb);
      }
    }
    debugPrint(
      '[tvbox-m3u8] frame rate detected: master=$masterFrameRate, '
      'blocks=$removedBlocks, removed=$removableSegments',
    );
    return _normalizeMediaPlaylist(sb.toString());
  }

  /// com.github.tvbox.osc.util.M3u8.findDominantFrameRate
  static int _findDominantFrameRate(List<_Group> groups) {
    var count30 = 0;
    var count25 = 0;
    var count24 = 0;
    for (final group in groups) {
      for (final raw in group.lines) {
        if (_getExtInfValueStart(raw) < 0) continue;
        final frameRate = _getExclusiveFrameRate(_parseExtInfDuration(raw));
        if (frameRate == 30) {
          count30++;
        } else if (frameRate == 25) {
          count25++;
        } else if (frameRate == 24) {
          count24++;
        }
      }
    }

    final max = math.max(count30, math.max(count25, count24));
    if (max < 2) return 0;
    final maxCount =
        (count30 == max ? 1 : 0) +
        (count25 == max ? 1 : 0) +
        (count24 == max ? 1 : 0);
    if (maxCount != 1) return 0;
    return count30 == max ? 30 : (count25 == max ? 25 : 24);
  }

  /// com.github.tvbox.osc.util.M3u8.getFrameRateStats
  static _FrameRateStats _getFrameRateStats(_Group group, int masterFrameRate) {
    final stats = _FrameRateStats();
    for (final raw in group.lines) {
      if (_getExtInfValueStart(raw) < 0) continue;
      final frameRate = _getExclusiveFrameRate(_parseExtInfDuration(raw));
      if (frameRate == masterFrameRate) {
        stats.matched++;
      } else if (frameRate != 0) {
        stats.mismatched++;
      }
    }
    return stats;
  }

  /// com.github.tvbox.osc.util.M3u8.getExclusiveFrameRate
  static int _getExclusiveFrameRate(String duration) {
    final is30 = _isFrameAligned(duration, 30);
    final is25 = _isFrameAligned(duration, 25);
    final is24 = _isFrameAligned(duration, 24);
    if (is30 && !is25 && !is24) return 30;
    if (is25 && !is30 && !is24) return 25;
    if (is24 && !is30 && !is25) return 24;
    return 0;
  }

  /// com.github.tvbox.osc.util.M3u8.isFrameAligned
  static bool _isFrameAligned(String duration, int frameRate) {
    final features = _frameRateFeatures[frameRate];
    if (features == null) return false;
    return features.contains(_fractionString(duration));
  }

  /// com.github.tvbox.osc.util.M3u8.prepareFrameRateFeatures
  static Map<int, Set<String>> _prepareFrameRateFeatures() {
    return {
      30: _createFrameRateFeatures(30, true),
      25: _createFrameRateFeatures(25, false),
      24: _createFrameRateFeatures(24, true),
    };
  }

  /// com.github.tvbox.osc.util.M3u8.createFrameRateFeatures
  static Set<String> _createFrameRateFeatures(int frameRate, bool includeNtsc) {
    final features = <String>{};
    _addFrameRateFeatures(features, frameRate.toDouble(), frameRate);
    if (includeNtsc) {
      _addFrameRateFeatures(features, frameRate / 1.001, frameRate * 10);
    }
    return features;
  }

  /// com.github.tvbox.osc.util.M3u8.addFrameRateFeatures
  static void _addFrameRateFeatures(
    Set<String> features,
    double rate,
    int maxFrames,
  ) {
    for (var frame = 1; frame <= maxFrames; frame++) {
      final q = frame / rate;
      final fraction = q - q.floorToDouble();
      for (var scale = 3; scale <= 6; scale++) {
        final value = _stripTrailingZeros(fraction.toStringAsFixed(scale));
        if (value != '0') features.add(value);
      }
    }
  }

  /// com.github.tvbox.osc.util.M3u8.parseExtInfDuration
  static String _parseExtInfDuration(String line) {
    final start = _getExtInfValueStart(line);
    if (start < 0) return '0';
    final end = _getExtInfValueEnd(line, start);
    final value = line.substring(start, end).trim();
    if (double.tryParse(value) == null) return '0';
    return _stripTrailingZeros(value);
  }

  /// com.github.tvbox.osc.util.M3u8.getExtInfValueStart
  static int _getExtInfValueStart(String line) {
    final length = line.length;
    var start = 0;
    while (start < length && line.codeUnitAt(start) <= 0x20) {
      start++;
    }
    if (!line.startsWith(_tagMediaDuration, start)) return -1;
    start += _tagMediaDuration.length;
    if (start >= length || line[start] != ':') return -1;
    start++;
    while (start < length && line.codeUnitAt(start) <= 0x20) {
      start++;
    }
    return start < length ? start : -1;
  }

  /// com.github.tvbox.osc.util.M3u8.getExtInfValueEnd
  static int _getExtInfValueEnd(String line, int start) {
    var end = line.indexOf(',', start);
    if (end < 0) end = line.length;
    while (end > start && line.codeUnitAt(end - 1) <= 0x20) {
      end--;
    }
    return end;
  }

  /// com.github.tvbox.osc.util.M3u8.getAdSegmentLimit
  static int _getAdSegmentLimit(String m3u8Content) {
    var totalDuration = 0.0;
    for (final raw in _splitBy(m3u8Content, '\n')) {
      totalDuration += double.tryParse(_parseExtInfDuration(raw)) ?? 0;
    }
    final totalMinutes = totalDuration / 60;
    if (totalMinutes <= 30) return 18;
    if (totalMinutes <= 60) return 24;
    if (totalMinutes <= 90) return 30;
    return 36;
  }

  /// com.github.tvbox.osc.util.M3u8.resolveContent
  static String _resolveContent(String tsUrlPre, String m3u8Content) {
    m3u8Content = m3u8Content.replaceAll('\r\n', '\n');
    final sb = StringBuffer();
    for (final line in m3u8Content.split('\n')) {
      sb
        ..write(_shouldResolve(line) ? _resolve(tsUrlPre, line.trim()) : line)
        ..write('\n');
    }
    return sb.toString();
  }

  /// com.github.tvbox.osc.util.M3u8.getRegex
  static List<String>? _getRegex(String tsUrlPre) {
    final hostsRegex = VideoParseRuler.getHostsRegex();
    List<String> list = const [];
    for (final host in hostsRegex.keys) {
      if (!tsUrlPre.contains(host)) continue;
      final value = hostsRegex[host];
      if (value == null) continue;
      list = value;
      break;
    }
    return list;
  }

  /// com.github.tvbox.osc.util.M3u8.clean
  static String _clean(String line, List<String> ads) {
    var scan = false;
    for (final ad in ads) {
      if (ad.contains(_tagDiscontinuity) || ad.contains(_tagMediaDuration)) {
        line = _scanAd(line, ad);
      } else if (isDouble(ad)) {
        scan = true;
      }
    }
    return scan ? _scan(line, ads) : line;
  }

  /// com.github.tvbox.osc.util.M3u8.cleanCommonAdMarkers
  static String _cleanCommonAdMarkers(String line) {
    final sb = StringBuffer();
    final pending = <String>[];
    var inAdBreak = false;
    var changed = false;

    for (final raw in line.split('\n')) {
      final item = raw.trim();
      if (item.isEmpty) {
        if (pending.isEmpty) {
          sb
            ..write(raw)
            ..write('\n');
        } else {
          pending.add(raw);
        }
        continue;
      }
      if (item.startsWith('#')) {
        if (item.startsWith(_tagCueIn)) {
          if (inAdBreak || _hasAdSignal(pending)) {
            inAdBreak = false;
            pending.clear();
            changed = true;
            continue;
          }
        }
        if (_isAdBreakStart(item)) {
          _flush(sb, pending);
          inAdBreak = true;
          pending.add(raw);
          changed = true;
          continue;
        }
        if (inAdBreak) {
          pending.add(raw);
          changed = true;
          continue;
        }
        if (_isStandaloneAdTag(item)) {
          _flush(sb, pending);
          currentAdCount++;
          changed = true;
          continue;
        }
        if (_isSegmentTag(item) || _isAdSignalTag(item)) {
          pending.add(raw);
        } else {
          _flush(sb, pending);
          sb
            ..write(raw)
            ..write('\n');
        }
        continue;
      }

      if (inAdBreak ||
          _hasAdSignal(pending) ||
          _isAdSegmentUri(item) ||
          _hasAdDomain(item)) {
        pending.clear();
        currentAdCount++;
        changed = true;
        continue;
      }
      _flush(sb, pending);
      sb
        ..write(raw)
        ..write('\n');
    }

    if (!inAdBreak) _flush(sb, pending);
    return changed ? sb.toString() : line;
  }

  /// com.github.tvbox.osc.util.M3u8.flush
  static void _flush(StringBuffer sb, List<String> pending) {
    for (final line in pending) {
      sb
        ..write(line)
        ..write('\n');
    }
    pending.clear();
  }

  /// com.github.tvbox.osc.util.M3u8.flush
  static void _flushLines(
    StringBuffer sb,
    List<String> pending,
    String linesplit,
  ) {
    for (final line in pending) {
      _appendLine(sb, line, linesplit);
    }
    pending.clear();
  }

  /// com.github.tvbox.osc.util.M3u8.appendLine
  static void _appendLine(StringBuffer sb, String line, String linesplit) {
    sb
      ..write(line)
      ..write(linesplit);
  }

  /// com.github.tvbox.osc.util.M3u8.hasAdSignal
  static bool _hasAdSignal(List<String> pending) {
    for (final line in pending) {
      final item = line.trim();
      if (_isAdBreakStart(item) || _isAdSignalTag(item)) return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.util.M3u8.isAdBreakStart
  static bool _isAdBreakStart(String line) => line.startsWith(_tagCueOut);

  /// com.github.tvbox.osc.util.M3u8.isAdSignalTag
  static bool _isAdSignalTag(String line) {
    if (line.startsWith('#EXT-OATCLS-SCTE35')) return true;
    if (line.startsWith('#EXT-X-SCTE35')) return true;
    if (line.startsWith('#EXT-X-SPLICEPOINT-SCTE35')) return true;
    if (line.startsWith('#EXT-X-CUE')) return true;
    if (line.startsWith('#EXT-X-ASSET')) return true;
    if (line.startsWith('#EXT-X-VMAP-AD-BREAK')) return true;
    if (line.startsWith('#EXT-X-AD')) return true;
    if (line.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE')) return false;
    return false;
  }

  /// com.github.tvbox.osc.util.M3u8.isSegmentTag
  static bool _isSegmentTag(String line) {
    if (line.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE')) return false;
    return line.startsWith(_tagMediaDuration) ||
        line.startsWith('#EXT-X-BYTERANGE') ||
        line.startsWith('#EXT-X-PROGRAM-DATE-TIME') ||
        line.startsWith(_tagDiscontinuity) ||
        line.startsWith('#EXT-X-PART') ||
        line.startsWith('#EXT-X-PRELOAD-HINT');
  }

  /// com.github.tvbox.osc.util.M3u8.isStandaloneAdTag
  static bool _isStandaloneAdTag(String line) {
    if (!line.startsWith(_tagDaterange)) return false;
    return _isAdLikeText(line) ||
        line.contains('X-ASSET-URI') ||
        line.contains('X-ASSET-LIST');
  }

  /// com.github.tvbox.osc.util.M3u8.isAdLikeText
  static bool _isAdLikeText(String line) {
    final lower = line.toLowerCase();
    return lower.contains('scte') ||
        lower.contains('cue') ||
        lower.contains('interstitial') ||
        lower.contains('vmap') ||
        lower.contains('vast') ||
        lower.contains('advert') ||
        lower.contains('commercial') ||
        lower.contains('ad-') ||
        lower.contains('ad_') ||
        lower.contains('ad.') ||
        lower.contains('preroll') ||
        lower.contains('midroll') ||
        lower.contains('postroll') ||
        lower.contains('bumper');
  }

  /// com.github.tvbox.osc.util.M3u8.isAdSegmentUri
  static bool _isAdSegmentUri(String line) => _regexAdSegmentUri.hasMatch(line);

  /// com.github.tvbox.osc.util.M3u8.hasAdDomain
  static bool _hasAdDomain(String url) {
    final lower = url.toLowerCase();
    for (final keyword in _adDomainKeywords) {
      if (lower.contains(keyword)) return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.util.M3u8.cleanDiscontinuityGroups
  static String _cleanDiscontinuityGroups(String m3u8Content) {
    final groups = _buildDiscontinuityGroups(_splitBy(m3u8Content, '\n'));
    if (groups.length < 3) return m3u8Content;
    final main = _findMainGroup(groups);
    if (main == null || main.segmentCount < 3) return m3u8Content;

    final sb = StringBuffer();
    var changed = false;
    for (final group in groups) {
      if (_shouldDropGroup(group, main)) {
        currentAdCount += group.segmentCount;
        changed = true;
        continue;
      }
      group.appendTo(sb);
    }
    return changed ? sb.toString() : m3u8Content;
  }

  /// com.github.tvbox.osc.util.M3u8.buildDiscontinuityGroups
  static List<_Group> _buildDiscontinuityGroups(List<String> lines) {
    final groups = <_Group>[];
    var group = _Group();
    for (final raw in lines) {
      final line = raw.trim();
      if (line.startsWith(_tagDiscontinuity) && group.hasMedia) {
        groups.add(group);
        group = _Group();
      }
      group.add(raw);
    }
    if (group.hasMedia || group.lines.isNotEmpty) groups.add(group);
    return groups;
  }

  /// com.github.tvbox.osc.util.M3u8.findMainGroup
  static _Group? _findMainGroup(List<_Group> groups) {
    _Group? main;
    for (final group in groups) {
      if (group.segmentCount == 0) continue;
      if (main == null || group.score > main.score) main = group;
    }
    return main;
  }

  /// com.github.tvbox.osc.util.M3u8.shouldDropGroup
  static bool _shouldDropGroup(_Group group, _Group main) {
    if (identical(group, main) || group.segmentCount == 0) return false;

    final shortGroup =
        group.segmentCount <= 2 ||
        (main.totalDuration > 0 &&
            group.totalDuration > 0 &&
            group.totalDuration < main.totalDuration * 0.18);

    final differentHost =
        main.host.isNotEmpty &&
        group.host.isNotEmpty &&
        main.host != group.host;

    final differentPath =
        main.pathPrefix.isNotEmpty &&
        group.pathPrefix.isNotEmpty &&
        main.pathPrefix != group.pathPrefix;

    final hasAdFeature =
        group.adLikeCount > 0 ||
        _hasAdDomain(group.host) ||
        _isAdSegmentUri(group.pathPrefix);

    final adLike =
        hasAdFeature ||
        differentHost ||
        (group.segmentCount <= 2 && differentPath);

    return shortGroup && adLike;
  }

  /// com.github.tvbox.osc.util.M3u8.hostOf
  static String _hostOf(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) return '';
    final start = url.indexOf('://') + 3;
    final end = url.indexOf('/', start);
    return end > start ? url.substring(start, end) : url.substring(start);
  }

  /// com.github.tvbox.osc.util.M3u8.pathPrefixOf
  static String _pathPrefixOf(String url) {
    var clean = url;
    final query = clean.indexOf('?');
    if (query >= 0) clean = clean.substring(0, query);
    final slash = clean.lastIndexOf('/');
    return slash > 0 ? clean.substring(0, slash + 1) : '';
  }

  /// com.github.tvbox.osc.util.M3u8.toAbsoluteUrl
  static String _toAbsoluteUrl(String base, String url) {
    final line = url.trim();
    if (line.isEmpty ||
        line.startsWith('http://') ||
        line.startsWith('https://')) {
      return line;
    }
    return _resolve(base, line);
  }

  /// com.github.tvbox.osc.util.M3u8.shouldKeepMediaUrl
  static bool _shouldKeepMediaUrl(
    String absoluteUrl,
    bool domainFiltering,
    String maxTimesPreUrl,
    Map<String, int> preUrlMap,
  ) {
    if (!domainFiltering) return absoluteUrl.startsWith(maxTimesPreUrl);
    final ifirst = absoluteUrl.indexOf('/', 9);
    final domain = ifirst > 0 ? absoluteUrl.substring(0, ifirst) : absoluteUrl;
    final cnt = preUrlMap[domain];
    return domain == maxTimesPreUrl || (cnt != null && cnt > _timesNoAd);
  }

  /// com.github.tvbox.osc.util.M3u8.hasUriAttribute
  static bool _hasUriAttribute(String line) =>
      line.startsWith(_tagKey) || line.startsWith(_tagMap);

  /// com.github.tvbox.osc.util.M3u8.resolveUriLine
  static String _resolveUriLine(String base, String line) {
    final match = _regexUri.firstMatch(line);
    final value = match?.group(1);
    if (value == null) return line;
    return line.replaceAll(value, _resolve(base, value));
  }

  /// com.github.tvbox.osc.util.M3u8.normalizeMediaPlaylist
  static String _normalizeMediaPlaylist(String content) {
    final sb = StringBuffer();
    var seenMedia = false;
    var hasPendingDiscontinuity = false;
    var pendingDiscontinuity = '';
    for (final raw in content.replaceAll('\r\n', '\n').split('\n')) {
      final item = raw.trim();
      if (_isDiscontinuityTag(item)) {
        if (seenMedia && !hasPendingDiscontinuity) {
          pendingDiscontinuity = raw;
          hasPendingDiscontinuity = true;
        }
        continue;
      }
      if (hasPendingDiscontinuity) {
        if (item.isEmpty) continue;
        if (!item.startsWith(_tagEndlist)) {
          sb
            ..write(pendingDiscontinuity)
            ..write('\n');
        }
        hasPendingDiscontinuity = false;
      }
      if (item.isEmpty && sb.isEmpty) continue;
      sb
        ..write(raw)
        ..write('\n');
      if (_isMediaUriLine(item)) seenMedia = true;
    }
    return sb.toString();
  }

  /// com.github.tvbox.osc.util.M3u8.isPlayableMediaPlaylist
  static bool _isPlayableMediaPlaylist(String? content) {
    if (content == null || !content.startsWith('#EXTM3U')) return false;
    var mediaCount = 0;
    var pendingExtInf = false;
    for (final raw in content.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith(_tagMediaDuration)) {
        if (pendingExtInf) return false;
        pendingExtInf = true;
      } else if (_isMediaUriLine(line)) {
        mediaCount++;
        pendingExtInf = false;
      } else if (line.startsWith(_tagEndlist) && pendingExtInf) {
        return false;
      }
    }
    return mediaCount > 0 && !pendingExtInf;
  }

  /// com.github.tvbox.osc.util.M3u8.keepVodEndList
  static String? _keepVodEndList(String original, String? result) {
    if (result == null) return null;
    if (!_hasEndList(original) || _hasEndList(result)) return result;
    final separator = result.endsWith('\n') ? '' : '\n';
    return '$result$separator$_tagEndlist\n';
  }

  /// com.github.tvbox.osc.util.M3u8.hasEndList
  static bool _hasEndList(String? content) {
    if (content == null) return false;
    for (final raw in content.replaceAll('\r\n', '\n').split('\n')) {
      if (raw.trim().startsWith(_tagEndlist)) return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.util.M3u8.isMediaUriLine
  static bool _isMediaUriLine(String line) =>
      line.isNotEmpty && !line.startsWith('#');

  /// com.github.tvbox.osc.util.M3u8.isDiscontinuityTag
  static bool _isDiscontinuityTag(String line) =>
      line.startsWith(_tagDiscontinuity) &&
      !line.startsWith('#EXT-X-DISCONTINUITY-SEQUENCE');

  /// com.github.tvbox.osc.util.M3u8.scanAd
  static String _scanAd(String line, String tagAd) {
    final pattern = RegexUtils.getPattern(tagAd);
    if (pattern == null) return line;
    final needRemoveAd = <String>[];
    for (final match in pattern.allMatches(line)) {
      final group = match.group(0)!;
      final groupCleaned = group.replaceAll(_tagEndlist, '');
      final tCount = _regexMediaDuration.allMatches(group).length;
      needRemoveAd.add(groupCleaned);
      currentAdCount += tCount;
    }
    for (final rem in needRemoveAd) {
      line = line.replaceAll(rem, '');
    }
    return line;
  }

  /// com.github.tvbox.osc.util.M3u8.scan
  static String _scan(String line, List<String> ads) {
    final needRemoveAd = <String>[];
    for (final match in _regexXDiscontinuity.allMatches(line)) {
      final group = match.group(0)!;
      final groupCleaned = group.replaceAll(_tagEndlist, '');
      var ft = '';
      var lt = '';
      var t = 0.0;
      var tCount = 0;
      for (final m2 in _regexMediaDuration.allMatches(group)) {
        final parsed = double.tryParse(m2.group(1)!) ?? 0;
        if (ft.isEmpty) ft = m2.group(1)!;
        lt = m2.group(1)!;
        t += parsed;
        tCount++;
      }
      final tStr = _formatDouble(t);
      for (final ad in ads) {
        if (ad.startsWith('-')) {
          final adClean = ad.substring(1);
          if (lt.startsWith(adClean)) {
            needRemoveAd.add(groupCleaned);
            currentAdCount += tCount;
            break;
          }
        } else {
          if (ft.startsWith(ad) || tStr.startsWith(ad)) {
            needRemoveAd.add(groupCleaned);
            currentAdCount += tCount;
            break;
          }
        }
      }
    }
    for (final rem in needRemoveAd) {
      line = line.replaceAll(rem, '');
    }
    return line;
  }

  /// com.github.tvbox.osc.util.M3u8.shouldResolve
  static bool _shouldResolve(String line) {
    final item = line.trim();
    if (item.isEmpty) return false;
    return (!item.startsWith('#') && !item.startsWith('http')) ||
        _hasUriAttribute(item);
  }

  /// com.github.tvbox.osc.util.M3u8.resolve
  static String _resolve(String base, String line) {
    try {
      if (_hasUriAttribute(line)) return _resolveUriLine(base, line);
      return Uri.parse(base).resolve(line).toString();
    } catch (_) {
      return line;
    }
  }

  static String _formatDouble(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }

  static String _fractionString(String duration) {
    final dot = duration.indexOf('.');
    if (dot < 0) return '0';
    return _stripTrailingZeros('0.${duration.substring(dot + 1)}');
  }

  static String _stripTrailingZeros(String value) {
    if (!value.contains('.')) {
      return value == '-0' ? '0' : value;
    }
    var result = value;
    while (result.endsWith('0')) {
      result = result.substring(0, result.length - 1);
    }
    if (result.endsWith('.')) {
      result = result.substring(0, result.length - 1);
    }
    if (result == '-0') result = '0';
    return result.isEmpty ? '0' : result;
  }

  static List<String> _splitBy(String source, String delimiter) {
    final parts = source.split(delimiter);
    var end = parts.length;
    while (end > 0 && parts[end - 1].isEmpty) {
      end--;
    }
    return end == parts.length ? parts : parts.sublist(0, end);
  }
}

/// com.github.tvbox.osc.util.M3u8.FrameRateStats
class _FrameRateStats {
  int matched = 0;
  int mismatched = 0;
}

/// com.github.tvbox.osc.util.M3u8.DecimalPrecisionStats
class _DecimalPrecisionStats {
  int total = 0;
  int mismatched = 0;
}

/// com.github.tvbox.osc.util.M3u8.Group
class _Group {
  final List<String> lines = [];
  int segmentCount = 0;
  int adLikeCount = 0;
  double totalDuration = 0;
  String host = '';
  String pathPrefix = '';

  /// com.github.tvbox.osc.util.M3u8.Group.hasMedia
  bool get hasMedia => segmentCount > 0;

  /// com.github.tvbox.osc.util.M3u8.Group.score
  double get score =>
      totalDuration > 0 ? totalDuration : segmentCount.toDouble();

  /// com.github.tvbox.osc.util.M3u8.Group.add
  void add(String raw) {
    lines.add(raw);
    final line = raw.trim();
    final durationStart = M3u8._getExtInfValueStart(line);
    if (durationStart >= 0) {
      final durationEnd = M3u8._getExtInfValueEnd(line, durationStart);
      totalDuration +=
          double.tryParse(line.substring(durationStart, durationEnd)) ?? 0;
    }
    if (line.isEmpty || line.startsWith('#')) {
      if (M3u8._isAdSignalTag(line) || M3u8._isStandaloneAdTag(line)) {
        adLikeCount++;
      }
      return;
    }
    segmentCount++;
    if (M3u8._isAdSegmentUri(line) || M3u8._hasAdDomain(line)) {
      adLikeCount++;
    }
    if (host.isEmpty) host = M3u8._hostOf(line);
    if (pathPrefix.isEmpty) pathPrefix = M3u8._pathPrefixOf(line);
  }

  /// com.github.tvbox.osc.util.M3u8.Group.appendTo
  void appendTo(StringBuffer sb) {
    for (final line in lines) {
      sb
        ..write(line)
        ..write('\n');
    }
  }
}
