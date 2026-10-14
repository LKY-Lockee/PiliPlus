import 'dart:async';
import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/history_vod/list.dart';
import 'package:PiliPlus/models_new/video/video_detail/stat_detail.dart';
import 'package:PiliPlus/models_new/vod/detail.dart';
import 'package:PiliPlus/models_new/vod/play.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/episode_panel/vod/view.dart';
import 'package:PiliPlus/pages/video/introduction/vod/widgets/intro_detail.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_status.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/proxy.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/parse_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_collect.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_record.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/server/control_manager.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/default_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/m3u8.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/parser/super_parse.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/search_helper.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/string_utils.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:PiliPlus/plugin/tvbox/widgets/vod_parse_panel.dart';
import 'package:PiliPlus/plugin/tvbox/widgets/vod_source_panel.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodIntroController extends CommonIntroController {
  late String sourceKey;
  late String vodId;

  @override
  void queryVideoIntro() {}

  @override
  int get copyright => 1;

  @override
  void actionLikeVideo() {}

  @override
  void actionShareVideo(context) {}

  @override
  void actionTriple() {}

  @override
  Future<void> actionFavVideo({bool isQuick = false}) async {}

  @override
  (Object, int) get getFavRidType => throw UnimplementedError();

  @override
  StatDetail? getStat() => null;

  @override
  bool get isShowOnlineTotal => false;

  bool isSniffing = false;

  TVBoxService get tvboxService => TVBoxService.to;

  SourceBean? get source => tvboxService.sourceByKey(sourceKey);

  final Rxn<VodInfoModel> detail = Rxn<VodInfoModel>();
  final RxInt flagIndex = 0.obs;
  final RxInt episodeIndex = (-1).obs;
  final RxBool isFav = false.obs;
  final RxBool isDetailLoading = false.obs;

  List<VodPlayGroup> get playFlags => detail.value?.playFlags ?? const [];

  List<VodEpisode> get episodes =>
      playFlags.isNotEmpty ? playFlags[flagIndex.value].episodes : const [];

  VodEpisode? get currentEpisode {
    final i = episodeIndex.value;
    if (i >= 0 && i < episodes.length) {
      return episodes[i];
    }
    return null;
  }

  String get progressKeyOf {
    final data = detail.value;
    if (data == null || playFlags.isEmpty) {
      return '$sourceKey-$vodId';
    }
    final i = episodeIndex.value >= 0 ? episodeIndex.value : 0;
    final iClamped = i < episodes.length ? i : episodes.length - 1;
    final group = playFlags[flagIndex.value];
    return VodRecord.progressKey(
      sourceKey,
      vodId,
      group.flag,
      iClamped,
      group.episodes[iClamped].name,
    );
  }

  @override
  void onInit() {
    final args = Get.arguments;
    sourceKey = args['sourceKey'] as String? ?? '';
    vodId = args['vodId'] as String? ?? '';
    super.onInit();
    isFav.value = VodCollect.isFav(sourceKey, vodId);
    videoDetailCtr.plPlayerController.addPositionListener(onPositionChanged);
    loadDetail();
  }

  Future<void>? _loading;
  Future<void> loadDetail() => _loading ??= _loadDetail();

  /// com.github.tvbox.osc.ui.activity.DetailActivity.loadDetail
  Future<void> _loadDetail() async {
    final cfg = await tvboxService.getConfig();
    if (cfg == null) {
      SmartDialog.showToast('点播源不可用');
      return;
    }
    isDetailLoading.value = true;
    final res = await SourceViewModel(
      config: cfg,
      sourceKey: sourceKey,
    ).getDetail(vodId);
    isDetailLoading.value = false;
    if (isClosed) return;
    if (res case Success(:final response)) {
      _applyDetail(response);
      if (response.playFlags.isEmpty) {
        SmartDialog.showToast('暂无播放资源');
        return;
      }
      final history = VodRecord.get(sourceKey, vodId);
      var fi = 0;
      if (history != null) {
        for (final (i, group) in response.playFlags.indexed) {
          if (group.flag == history.playFlag) {
            fi = i;
            break;
          }
        }
      }
      flagIndex.value = fi;
      final group = response.playFlags[fi];
      var ei = 0;
      if (history != null &&
          history.playIndex! >= 0 &&
          history.playIndex! < group.episodes.length) {
        ei = history.playIndex!;
      }
      episodeIndex.value = ei;
      detail.refresh();
    } else {
      res.toast();
      videoDetailCtr.autoPlay = false;
      videoDetailCtr.videoState.value = false;
    }
  }

  void _applyDetail(VodInfoModel response) {
    detail.value = response;
    videoDetail.value.title = response.video.title;
    if (response.video.cover?.isNotEmpty == true) {
      videoDetailCtr.cover.value = response.video.cover!;
    }
  }

  Future<void> playCurrent({bool autoFullScreenFlag = false}) async {
    if (playFlags.isEmpty || episodeIndex.value < 0) {
      return;
    }
    await playEpisode(
      flagIndex.value,
      episodeIndex.value,
      autoFullScreenFlag: autoFullScreenFlag,
    );
  }

  static const int _autoRetryIdleMs = 60 * 1000;
  static const Duration _playStartTimeout = Duration(seconds: 20);

  final Set<String> _triedLineFlags = {};
  int _lastAutoRetryMs = 0;
  int _lineCycleCount = 0;

  final Set<String> _triedSourceKeys = {};
  int _sourceSwitchCount = 0;
  CancelToken? _resolveCancelToken;
  Completer<bool>? _playStartCompleter;
  int _playRunId = 0;

  bool get _autoChangeSourceEnabled =>
      Pref.vodAutoChangeSource && !videoDetailCtr.isFullScreen;

  bool _stale(int runId) => isClosed || runId != _playRunId;

  int _startPlayRun() {
    final runId = ++_playRunId;
    _resolveCancelToken?.cancel('superseded');
    final completer = _playStartCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(false);
    }
    _playStartCompleter = null;
    return runId;
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.play
  Future<bool> playEpisode(
    int flag,
    int index, {
    bool autoFullScreenFlag = false,
    Duration? inheritPosition,
  }) async {
    final runId = _startPlayRun();
    _resetLineState();
    _triedSourceKeys
      ..clear()
      ..add(sourceKey);
    _sourceSwitchCount = 0;
    var sourceFlag = flag;
    var sourceIndex = index;
    var fullScreen = autoFullScreenFlag;
    Duration? inherit = inheritPosition;
    String? lastError;
    while (true) {
      if (_stale(runId)) {
        return false;
      }
      final r = await _playSourceLines(
        runId,
        sourceFlag,
        sourceIndex,
        autoFullScreenFlag: fullScreen,
        inheritPosition: inherit,
      );
      if (r.ok) {
        return true;
      }
      if (_stale(runId)) {
        return false;
      }
      lastError = r.error;
      inherit ??= _currentPosition();
      if (!_autoChangeSourceEnabled) {
        break;
      }
      final switched = await _tryNextSource(runId, r.lastEpisode);
      if (!switched) {
        break;
      }
      _resetLineState();
      sourceFlag = flagIndex.value;
      sourceIndex = episodeIndex.value;
      fullScreen = false;
    }
    if (!_stale(runId) && lastError != null && lastError.isNotEmpty) {
      SmartDialog.showToast(lastError);
    }
    return false;
  }

  Future<({bool ok, String? error, VodEpisode? lastEpisode})> _playSourceLines(
    int runId,
    int flag,
    int index, {
    required bool autoFullScreenFlag,
    Duration? inheritPosition,
  }) async {
    var attemptFlag = flag;
    var attemptIndex = index;
    var fullScreen = autoFullScreenFlag;
    Duration? inherit = inheritPosition;
    String? lastError;
    VodEpisode? lastEpisode;
    while (true) {
      if (_stale(runId)) {
        return (ok: false, error: null, lastEpisode: lastEpisode);
      }
      lastEpisode = _episodeOf(attemptFlag, attemptIndex) ?? lastEpisode;
      final err = await _playAttempt(
        runId,
        attemptFlag,
        attemptIndex,
        autoFullScreenFlag: fullScreen,
        inheritPosition: inherit,
      );
      if (err == null) {
        return (ok: true, error: null, lastEpisode: lastEpisode);
      }
      if (_stale(runId)) {
        return (ok: false, error: null, lastEpisode: lastEpisode);
      }
      lastError = err;
      inherit ??= _currentPosition();
      final next = _prepareNextLine(attemptFlag, attemptIndex);
      if (next == null) {
        break;
      }
      fullScreen = false;
      SmartDialog.showToast('自动切换线路: ${playFlags[next.$1].flag}');
      attemptFlag = next.$1;
      attemptIndex = next.$2;
    }
    return (ok: false, error: lastError, lastEpisode: lastEpisode);
  }

  /// com.github.tvbox.osc.ui.activity.DetailActivity.scheduleDetailFallbackSearch
  Future<bool> _switchToSource(
    int runId,
    String key, {
    VodEpisode? target,
  }) async {
    if (_stale(runId)) {
      return false;
    }
    final cfg = tvboxService.config;
    final title = detail.value?.video.title;
    if (cfg == null || title == null || title.trim().isEmpty) {
      return false;
    }
    final keyword = title.trim();
    SmartDialog.showLoading(msg: '搜索换源');
    final results = await SearchHelper.searchSource(cfg, key, keyword);
    if (isClosed || !_stale(runId)) {
      SmartDialog.dismiss();
    }
    if (_stale(runId)) {
      return false;
    }
    final match = results
        .where((video) => video.title.trim() == keyword)
        .firstOrNull;
    if (match == null) {
      return false;
    }
    return _switchSource(runId, key, match.id, target);
  }

  /// com.github.tvbox.osc.ui.activity.DetailActivity.startDetailFallback
  Future<bool> _tryNextSource(int runId, VodEpisode? target) async {
    if (_stale(runId)) {
      return false;
    }
    final limit = Pref.vodAutoChangeSourceRetry;
    if (limit != 0 && _sourceSwitchCount >= limit) {
      return false;
    }
    for (final bean in tvboxService.sources) {
      if (_stale(runId)) {
        return false;
      }
      if (!bean.changeable || !bean.searchable) {
        continue;
      }
      if (bean.key == sourceKey || _triedSourceKeys.contains(bean.key)) {
        continue;
      }
      _triedSourceKeys.add(bean.key);
      final switched = await _switchToSource(runId, bean.key, target: target);
      if (switched) {
        _sourceSwitchCount++;
        SmartDialog.showToast('自动切换源: ${bean.name}');
        return true;
      }
      if (_stale(runId)) {
        return false;
      }
    }
    return false;
  }

  /// com.github.tvbox.osc.ui.activity.DetailActivity.loadNextDetailFallbackSource
  Future<bool> _switchSource(
    int runId,
    String key,
    String id,
    VodEpisode? target,
  ) async {
    if (_stale(runId)) {
      return false;
    }
    final cfg = tvboxService.config;
    if (cfg == null) {
      return false;
    }
    final res = await SourceViewModel(
      config: cfg,
      sourceKey: key,
    ).getDetail(id);
    if (_stale(runId)) {
      return false;
    }
    if (res case Success(:final response)) {
      if (response.playFlags.isEmpty) {
        return false;
      }
      sourceKey = key;
      vodId = id;
      isFav.value = VodCollect.isFav(key, id);
      _applyDetail(response);
      final (fi, ei) = _findEpisodeInDetail(target);
      flagIndex.value = fi;
      episodeIndex.value = ei;
      detail.refresh();
      return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.ui.activity.DetailActivity.restoreDetailFallbackEpisode
  (int, int) _findEpisodeInDetail(VodEpisode? target) {
    if (target != null) {
      for (var i = 0; i < playFlags.length; i++) {
        final idx = _findMatchingEpisodeIndex(target, playFlags[i].episodes);
        if (idx >= 0) {
          return (i, idx);
        }
      }
    }
    return (0, 0);
  }

  /// com.github.tvbox.osc.ui.activity.DetailActivity.findMatchingEpisodeIndex
  int _findMatchingEpisodeIndex(VodEpisode? current, List<VodEpisode> target) {
    if (target.isEmpty) {
      return -1;
    }
    if (target.length == 1) {
      return 0;
    }
    final currentName = current?.name ?? '';
    if (currentName.isEmpty) {
      return -1;
    }
    final currentEpisode = _extractEpisodeNumber(currentName);
    var matchedIndex = -1;
    var bestScore = 0;
    for (var i = 0; i < target.length; i++) {
      final score = _getEpisodeMatchScore(
        currentName,
        currentEpisode,
        target[i].name,
      );
      if (score > bestScore) {
        bestScore = score;
        matchedIndex = i;
      }
    }
    return matchedIndex;
  }

  Future<String?> _playAttempt(
    int runId,
    int flag,
    int index, {
    required bool autoFullScreenFlag,
    Duration? inheritPosition,
  }) async {
    final src = source;
    final cfg = tvboxService.config;
    final data = detail.value;
    if (src == null || cfg == null || data == null) {
      return '点播源不可用';
    }
    if (flag < 0 || flag >= data.playFlags.length) {
      return '线路不可用';
    }
    final group = data.playFlags[flag];
    if (index < 0 || index >= group.episodes.length) {
      return '剧集不可用';
    }
    final episode = group.episodes[index];

    SmartDialog.showLoading(msg: '获取播放地址');
    LoadingState<VodPlayInfo> res;
    final cancelToken = CancelToken();
    _resolveCancelToken = cancelToken;
    try {
      res = await () async {
        final info = await SourceViewModel(
          config: cfg,
          sourceKey: sourceKey,
        ).getPlay(group.flag, episode.url, cancelToken: cancelToken);
        return switch (info) {
          Success(:final response) => await _resolve(
            cfg,
            response,
            group.flag,
            cancelToken: cancelToken,
          ),
          _ => info,
        };
      }().timeout(_resolveTimeoutOf(src));
    } on TimeoutException {
      cancelToken.cancel('resolve timeout');
      if (isClosed || !_stale(runId)) {
        SmartDialog.dismiss();
      }
      return _stale(runId) ? null : '获取播放地址超时';
    } catch (e) {
      cancelToken.cancel('resolve failed');
      res = Error(e.toString());
    }
    if (isClosed || !_stale(runId)) {
      SmartDialog.dismiss();
    }
    if (_stale(runId)) {
      return null;
    }

    final playInfo = res.dataOrNull;
    if (playInfo == null) {
      if (!Pref.vodAutoSwitchLine) {
        res.toast();
        return '';
      }
      return '获取播放地址失败';
    }
    var url = playInfo.url;
    if (url.isEmpty) {
      return '获取播放地址失败';
    }
    if (playInfo.sniffUrl case final sniffUrl?) {
      isSniffing = true;
      String? result;
      try {
        result = await Get.toNamed(
          '/vodSniffer',
          arguments: {
            'url': sniffUrl,
            'headers': playInfo.headers,
            'sourceKey': sourceKey,
          },
        ) as String?;
      } finally {
        isSniffing = false;
      }
      if (_stale(runId)) {
        return null;
      }
      if (result == null || result.isEmpty) {
        return '嗅探失败';
      }
      url = result;
    }

    url = await _purifyIfNeeded(url, playInfo.headers, group.flag);
    if (_stale(runId)) {
      return null;
    }

    flagIndex.value = flag;
    episodeIndex.value = index;
    detail.refresh();
    videoDetail
      ..value.title = '${data.video.title} · ${episode.name}'
      ..refresh();

    videoDetailCtr
      ..onReset()
      ..playHeaders = playInfo.headers
      ..videoUrl = url
      ..audioUrl = ''
      ..cid.value = index
      ..defaultST = inheritPosition ?? _savedSeek();
    await videoDetailCtr.playerInit(autoFullScreenFlag: autoFullScreenFlag);
    saveRecord();
    if (_stale(runId)) {
      return null;
    }
    final player = videoDetailCtr.plPlayerController;
    if (player.dataStatus.value == DataStatus.error) {
      return '播放失败';
    }
    if (!videoDetailCtr.autoPlay) {
      return null;
    }
    final started = await _waitPlaybackStarted(runId);
    if (_stale(runId)) {
      return null;
    }
    return started ? null : '播放超时';
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.getResolvePlayUrlTimeoutMs
  Duration _resolveTimeoutOf(SourceBean src) {
    final seconds = src.playTimeoutSeconds + 1;
    return Duration(seconds: seconds < 15 ? 15 : seconds);
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.tryNextLine
  (int, int)? _prepareNextLine(int attemptFlag, int attemptIndex) {
    if (!Pref.vodAutoSwitchLine || videoDetailCtr.isFullScreen) {
      _resetLineState();
      return null;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastAutoRetryMs > _autoRetryIdleMs) {
      _triedLineFlags.clear();
      _lineCycleCount = 0;
    }
    _lastAutoRetryMs = now;

    final n = playFlags.length;
    if (n == 0) {
      _resetLineState();
      return null;
    }
    final currentFlag = attemptFlag >= 0 && attemptFlag < n
        ? playFlags[attemptFlag].flag
        : (flagIndex.value >= 0 && flagIndex.value < n
              ? playFlags[flagIndex.value].flag
              : '');
    final currentEpisode = _episodeOf(attemptFlag, attemptIndex);
    if (currentFlag.isNotEmpty) {
      _triedLineFlags.add(currentFlag);
    }
    final start = attemptFlag >= 0 && attemptFlag < n ? attemptFlag : -1;
    for (var step = 1; step <= n; step++) {
      final i = (start + step) % n;
      if (!_triedLineFlags.contains(playFlags[i].flag) &&
          playFlags[i].episodes.isNotEmpty) {
        return (
          i,
          _findSameEpisodeIndex(
            currentEpisode,
            playFlags[i].episodes,
            attemptIndex,
          ),
        );
      }
    }
    _triedLineFlags.clear();
    _lineCycleCount++;
    final limit = Pref.vodAutoSwitchLineRetry;
    if (limit != 0 && _lineCycleCount >= limit) {
      _resetLineState();
      return null;
    }
    for (var i = 0; i < n; i++) {
      if (playFlags[i].episodes.isNotEmpty) {
        return (
          i,
          _findSameEpisodeIndex(
            currentEpisode,
            playFlags[i].episodes,
            attemptIndex,
          ),
        );
      }
    }
    _resetLineState();
    return null;
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.findSameEpisodeIndex
  int _findSameEpisodeIndex(
    VodEpisode? current,
    List<VodEpisode> target,
    int fallback,
  ) {
    if (target.isEmpty) {
      return 0;
    }
    if (target.length == 1) {
      return 0;
    }
    final currentName = current?.name ?? '';
    if (currentName.isEmpty) {
      return fallback.clamp(0, target.length - 1);
    }
    final currentEpisode = _extractEpisodeNumber(currentName);
    var matchedIndex = -1;
    var bestScore = 0;
    for (var i = 0; i < target.length; i++) {
      final score = _getEpisodeMatchScore(
        currentName,
        currentEpisode,
        target[i].name,
      );
      if (score > bestScore) {
        bestScore = score;
        matchedIndex = i;
      }
    }
    if (matchedIndex >= 0) {
      return matchedIndex;
    }
    return fallback.clamp(0, target.length - 1);
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.getEpisodeMatchScore
  int _getEpisodeMatchScore(
    String currentName,
    int currentEpisode,
    String targetName,
  ) {
    if (currentName.isEmpty || targetName.isEmpty) {
      return 0;
    }
    if (targetName.toLowerCase() == currentName.toLowerCase()) {
      return 100;
    }
    if (currentEpisode >= 0 &&
        _extractEpisodeNumber(targetName) == currentEpisode) {
      return 80;
    }
    final currentLower = currentName.toLowerCase();
    final targetLower = targetName.toLowerCase();
    if (currentEpisode < 0 &&
        currentName.length >= 2 &&
        targetLower.contains(currentLower)) {
      return 70;
    }
    if (currentEpisode < 0 &&
        targetName.length >= 2 &&
        currentLower.contains(targetLower)) {
      return 60;
    }
    return 0;
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.extractEpisodeNumber
  int _extractEpisodeNumber(String name) {
    if (name.isEmpty) {
      return -1;
    }
    try {
      var text = name.replaceAll(RegExp(r'\[.*?\]|\(.*?\)'), '');
      text = text.replaceAll(RegExp(r'\b(19|20)\d{2}\b'), '');
      text = text.toLowerCase().replaceAll(
        RegExp(r'2160p|1080p|720p|480p|4k|h26[45]|x26[45]|mp4'),
        '',
      );
      final matcher = RegExp(
        r'(?:ep|第|e|[-.\s])\s?(\d{1,4})',
        caseSensitive: false,
      ).firstMatch(text);
      if (matcher != null) {
        return int.parse(matcher.group(1)!);
      }
      final number = text.replaceAll(RegExp(r'\D+'), '');
      if (number.isNotEmpty) {
        return int.parse(number);
      }
    } catch (_) {}
    return -1;
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.isPlaybackStarted
  Future<bool> _waitPlaybackStarted(int runId) async {
    if (_stale(runId)) {
      return false;
    }
    final player = videoDetailCtr.plPlayerController;
    if (player.dataStatus.value == DataStatus.error) {
      return false;
    }
    final base = player.position.value;
    bool started() => player.position.value > base + 1;
    if (started()) {
      return true;
    }
    final completer = Completer<bool>();
    _playStartCompleter = completer;
    void onStatus(PlayerStatus _) {
      if (!completer.isCompleted && started()) {
        completer.complete(true);
      }
    }

    void onPosition(Duration _) {
      if (!completer.isCompleted && started()) {
        completer.complete(true);
      }
    }

    player
      ..addStatusLister(onStatus)
      ..addPositionListener(onPosition);
    final timer = Timer(_playStartTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    final result = await completer.future;
    _playStartCompleter = null;
    timer.cancel();
    player
      ..removeStatusLister(onStatus)
      ..removePositionListener(onPosition);
    return result;
  }

  VodEpisode? _episodeOf(int flag, int index) {
    if (flag < 0 || flag >= playFlags.length) {
      return null;
    }
    final list = playFlags[flag].episodes;
    if (index < 0 || index >= list.length) {
      return null;
    }
    return list[index];
  }

  Duration? _savedSeek() {
    final progress = VodRecord.getProgress(progressKeyOf);
    if (progress != null && progress > 5000) {
      return Duration(milliseconds: progress);
    }
    return null;
  }

  Duration _currentPosition() {
    final state =
        videoDetailCtr.plPlayerController.videoPlayerController?.state.position;
    final ms = state != null && state.inMilliseconds > _lastSavedMs
        ? state.inMilliseconds
        : _lastSavedMs;
    return Duration(milliseconds: ms);
  }

  void _resetLineState() {
    _triedLineFlags.clear();
    _lineCycleCount = 0;
    _lastAutoRetryMs = 0;
  }

  /// com.github.tvbox.osc.player.controller.VodController.processM3u8Content
  Future<String> _purifyIfNeeded(
    String url,
    Map<String, String> headers,
    String flag,
  ) async {
    if (!Pref.vodM3u8Purify) return url;
    if (url.startsWith('http://127.0.0.1') || !url.contains('.m3u8')) {
      return url;
    }
    if (DefaultConfig.noAd(flag)) return url;
    try {
      var content = await _fetchM3u8(url, headers);
      if (content == null || !content.startsWith('#EXTM3U')) return url;
      var baseUrl = url;
      final forwardUrl = _extractForwardUrl(url, content);
      if (forwardUrl.isNotEmpty) {
        final forwardContent = await _fetchM3u8(forwardUrl, headers);
        if (forwardContent == null || !forwardContent.startsWith('#EXTM3U')) {
          return url;
        }
        content = forwardContent;
        baseUrl = forwardUrl;
      }
      final basePath = baseUrl.substring(0, baseUrl.lastIndexOf('/') + 1);
      final purified = M3u8.purify(basePath, content);
      if (purified == null || M3u8.currentAdCount == 0) return url;
      await ControlManager.instance.ensureServer();
      ControlManager.instance.m3u8Content = purified;
      if (Pref.vodAdRemoveToast) {
        SmartDialog.showToast('已移除视频广告 ${M3u8.currentAdCount} 条');
      }
      return 'http://127.0.0.1:${Proxy.getPort()}/proxyM3u8';
    } catch (e) {
      debugPrint('[tvbox] m3u8 purify failed: $e');
      return url;
    }
  }

  Future<String?> _fetchM3u8(
    String url,
    Map<String, String> headers,
  ) {
    return Http.string(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers.isEmpty ? null : headers,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
  }

  /// com.github.tvbox.osc.player.controller.VodController.extractForwardUrl
  String _extractForwardUrl(String baseUrl, String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('#EXT-X-STREAM-INF')) {
        for (var j = i + 1; j < lines.length; j++) {
          final target = lines[j].trim();
          if (target.isEmpty) continue;
          if (_isValidM3u8Line(target)) {
            return _resolveForwardUrl(baseUrl, target);
          }
        }
      }
    }
    return '';
  }

  /// com.github.tvbox.osc.player.controller.VodController.isValidM3u8Line
  bool _isValidM3u8Line(String line) {
    return !line.startsWith('#') &&
        (line.endsWith('.m3u8') || line.contains('.m3u8?'));
  }

  /// com.github.tvbox.osc.player.controller.VodController.resolveForwardUrl
  String _resolveForwardUrl(String baseUrl, String line) {
    try {
      return Uri.parse(baseUrl).resolve(line).toString();
    } catch (_) {
      return '';
    }
  }

  @override
  bool prevPlay() {
    final prev = episodeIndex.value - 1;
    if (prev >= 0) {
      playEpisode(flagIndex.value, prev);
      return true;
    }
    return false;
  }

  @override
  bool nextPlay() {
    final next = episodeIndex.value + 1;
    if (next < episodes.length) {
      playEpisode(flagIndex.value, next);
      return true;
    }
    final playCtr = videoDetailCtr.plPlayerController;
    if (playCtr.playRepeat == PlayRepeat.listCycle && episodes.isNotEmpty) {
      if (episodes.length == 1) {
        if (playCtr.videoPlayerController case final ctr?) {
          ctr.seek(Duration.zero).whenComplete(ctr.play);
        }
      } else {
        playEpisode(flagIndex.value, 0);
      }
      return true;
    }
    return false;
  }

  /// com.github.tvbox.osc.cache.RoomDataManger.insertVodCollect
  void toggleFav() {
    final data = detail.value;
    if (data == null) {
      return;
    }
    VodCollect.toggle(
      sourceKey,
      vodId,
      data.video.title,
      data.video.cover,
      data.video.remarks,
      data.video.type,
    );
    isFav.value = VodCollect.isFav(sourceKey, vodId);
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.showEpisodeDialog
  void showEpisodePanel() {
    if (playFlags.isEmpty) {
      return;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }
    final isFullScreen = videoDetailCtr.plPlayerController.isFullScreen.value;
    final child = EpisodeVodPanel(
      introController: this,
      enableSlide: !isFullScreen,
    );
    if (isFullScreen) {
      PageUtils.showVideoBottomSheet(context, child: child);
    } else {
      videoDetailCtr.childKey.currentState?.showBottomSheet(
        constraints: const BoxConstraints(),
        (context) => child,
      );
    }
  }

  void showIntroDetail() {
    final data = detail.value;
    if (data == null) {
      return;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }
    videoDetailCtr.childKey.currentState?.showBottomSheet(
      constraints: const BoxConstraints(),
      (context) => VodIntroPanel(item: data.video),
    );
  }

  void onChangeSource() {
    final data = detail.value;
    if (data == null) {
      return;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }
    final candidates = tvboxService.sources
        .where((e) => e.changeable || e.key == sourceKey)
        .toList();
    if (!candidates.any((e) => e.key != sourceKey)) {
      SmartDialog.showToast('无其它可用源');
      return;
    }
    VodSourcePanel.show(
      context,
      sources: candidates,
      currentKey: sourceKey,
      onSelected: (selected) async {
        if (isClosed || selected == sourceKey) {
          return;
        }
        final target = tvboxService.sourceByKey(selected);
        if (target == null) {
          return;
        }
        final runId = _startPlayRun();
        final inherit = _currentPosition();
        final episode = currentEpisode;
        final switched = await _switchToSource(
          runId,
          selected,
          target: episode,
        );
        if (_stale(runId)) {
          return;
        }
        if (!switched) {
          SmartDialog.showToast('该源未找到此内容');
          return;
        }
        SmartDialog.showToast('已切换源: ${target.name}');
        await playEpisode(
          flagIndex.value,
          episodeIndex.value,
          inheritPosition: inherit,
        );
      },
    );
  }

  void onChangeParse() {
    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }
    final parses = TVBoxService.to.config?.parseBeanList ?? const [];
    if (parses.isEmpty) {
      SmartDialog.showToast('当前订阅无解析配置');
      return;
    }
    VodParsePanel.show(
      context,
      parses: parses,
      onChanged: (_) => playCurrent(),
    );
  }

  int _lastSavedMs = 0;

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.saveProgress
  void onPositionChanged(Duration position) {
    final ms = position.inMilliseconds;
    if ((ms - _lastSavedMs).abs() < 3000) {
      return;
    }
    _lastSavedMs = ms;
    VodRecord.saveProgress(progressKeyOf, ms);
  }

  /// com.github.tvbox.osc.cache.RoomDataManger.insertVodRecord
  void saveRecord() {
    final data = detail.value;
    if (data == null || episodeIndex.value < 0) {
      return;
    }
    final duration = videoDetailCtr.plPlayerController.duration.value;
    final progress = Duration(
      milliseconds: videoDetailCtr.playedTime?.inMilliseconds ?? _lastSavedMs,
    ).inSeconds;
    VodRecord.save(
      HistoryVodItemModel(
        sourceKey: sourceKey,
        vodId: vodId,
        title: data.video.title,
        cover: data.video.cover,
        remarks: data.video.remarks,
        playFlag: playFlags.isNotEmpty ? playFlags[flagIndex.value].flag : '',
        playIndex: episodeIndex.value,
        showTitle: currentEpisode?.name,
        viewAt:
            DateTime.now().millisecondsSinceEpoch ~/
            Duration.millisecondsPerSecond,
        duration: duration,
        progress: duration > 0 && progress >= duration ? -1 : progress,
      ),
    );
  }

  @override
  void onClose() {
    _startPlayRun();
    videoDetailCtr.plPlayerController.removePositionListener(onPositionChanged);
    saveRecord();
    super.onClose();
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.initParse
  static Future<LoadingState<VodPlayInfo>> _resolve(
    ApiConfig? cfg,
    VodPlayInfo info,
    String flag, {
    CancelToken? cancelToken,
  }) async {
    final prefix = info.parsePrefix?.trim() ?? '';

    if (!info.parse) {
      return Success(info);
    }

    final headers = Map<String, String>.from(info.headers);

    final defaultParse = Pref.vodDefaultParse;
    if (defaultParse.isNotEmpty && cfg != null) {
      final parse = cfg.parseBeanList
          .where((item) => item.name == defaultParse)
          .firstOrNull;
      if (parse != null) {
        return _applyParse(parse, info, headers, cancelToken: cancelToken);
      }
    }

    final useParse =
        info.jx ||
        (prefix.isEmpty && (cfg?.vipParseFlags.contains(flag) ?? false));
    if (useParse) {
      if (cfg == null) {
        return const Error('未配置可用解析');
      }
      await ControlManager.instance.ensureServer();
      return SuperParse.resolve(cfg, info, flag, cancelToken: cancelToken);
    }

    if (prefix.startsWith('json:')) {
      return _jsonParse(
        prefix.substring(5),
        info,
        headers,
        cancelToken: cancelToken,
      );
    }
    if (prefix.startsWith('parse:')) {
      final name = prefix.substring(6);
      final parse = cfg?.parseBeanList
          .where((item) => item.name == name)
          .firstOrNull;
      if (parse == null) {
        return const Error('未找到指定解析');
      }
      return _applyParse(parse, info, headers, cancelToken: cancelToken);
    }
    if (prefix.isNotEmpty) {
      return Success(
        info.copyWith(
          headers: headers,
          sniffUrl: '$prefix${StringUtils.javaUrlEncode(info.url)}',
        ),
      );
    }

    return Success(
      info.copyWith(parse: false, sniffUrl: info.url),
    );
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.doParse
  static Future<LoadingState<VodPlayInfo>> _applyParse(
    ParseBean parse,
    VodPlayInfo info,
    Map<String, String> headers, {
    CancelToken? cancelToken,
  }) async {
    final merged = <String, String>{...headers, ...parse.headers};
    if (parse.type == 1) {
      return _jsonParse(parse.url, info, merged, cancelToken: cancelToken);
    }
    return Success(
      info.copyWith(
        headers: merged,
        sniffUrl: '${parse.url}${StringUtils.javaUrlEncode(info.url)}',
      ),
    );
  }

  /// com.github.tvbox.osc.util.parser.SuperParse.doJsonJx
  static Future<LoadingState<VodPlayInfo>> _jsonParse(
    String parseUrl,
    VodPlayInfo info,
    Map<String, String> headers, {
    CancelToken? cancelToken,
  }) async {
    final requestUrl = '$parseUrl${StringUtils.javaUrlEncode(info.url)}';
    final data = await Http.string(
      requestUrl,
      options: Options(
        responseType: ResponseType.plain,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
      cancelToken: cancelToken,
    );
    if (data == null) {
      debugPrint('[tvbox] jsonParse failed url=$requestUrl');
      return const Error('解析请求失败');
    }
    try {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) {
        return const Error('解析数据异常');
      }
      final dataJson = json['data'];
      var url =
          (dataJson is Map<String, dynamic>
              ? dataJson['url']?.toString()
              : null) ??
          json['url']?.toString() ??
          '';
      if (url.isEmpty) {
        return const Error('解析失败');
      }
      if (url.startsWith('//')) {
        url = 'https:$url';
      }
      final resultHeaders = Map<String, String>.from(headers);
      for (final source in [
        if (dataJson is Map<String, dynamic>) dataJson['header'],
        json['header'],
        json['headers'],
      ]) {
        if (source is Map<String, dynamic>) {
          source.forEach((key, value) {
            if (value != null) {
              resultHeaders[key] = value.toString();
            }
          });
        }
      }
      if (url.startsWith('video://')) {
        url = url.substring(8);
        return Success(info.copyWith(headers: resultHeaders, sniffUrl: url));
      }
      return Success(
        info.copyWith(
          url: url,
          headers: resultHeaders,
          sniffUrl: DefaultConfig.isVideoFormat(url) ? null : url,
        ),
      );
    } catch (_) {
      return const Error('解析数据异常');
    }
  }
}
