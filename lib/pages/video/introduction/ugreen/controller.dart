import 'dart:async';
import 'dart:math';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/detail.dart';
import 'package:PiliPlus/models_new/ugreen/play.dart';
import 'package:PiliPlus/models_new/ugreen/transcode.dart';
import 'package:PiliPlus/models_new/video/video_detail/stat_detail.dart';
import 'package:PiliPlus/pages/common/common_intro_controller.dart';
import 'package:PiliPlus/pages/episode_panel/ugreen/view.dart';
import 'package:PiliPlus/pages/video/introduction/ugreen/widgets/intro_detail.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_endpoint.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_media.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_video.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_play_proxy.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class UgreenIntroController extends CommonIntroController {
  final service = UgreenService.to;

  final Rxn<UgreenVideoSummary> video = Rxn<UgreenVideoSummary>();
  final RxList<UgreenPlayEpisode> episodes = <UgreenPlayEpisode>[].obs;
  final RxList<UgreenSeasonInfo> seasons = <UgreenSeasonInfo>[].obs;
  final RxInt episodeIndex = (-1).obs;
  final RxInt fileIndex = (-1).obs;
  final RxList<UgreenTranscodableResolution> qualities =
      <UgreenTranscodableResolution>[].obs;
  final RxInt qualityIndex = (-1).obs;
  final Rxn<UgreenTranscodeInfo> transcode = Rxn<UgreenTranscodeInfo>();
  final RxInt audioIndex = (-1).obs;
  final RxBool isDetailLoading = false.obs;
  final RxnString detailError = RxnString();

  late int _ugVideoInfoId;
  late final int _mediaLibSetId;
  late final int _ugType;
  late String _initialFilePath;
  late int? _initialEpisodeId;
  late int? _initialEpisode;

  static const int _srcType = 2;

  Future<void>? _loading;
  final _random = Random.secure();
  int _runId = 0;
  bool _isLoadingShown = false;
  bool _changingSeason = false;
  ScrollController? _seasonController;

  String _taskId = '';
  String _timestamp = '';
  int _lastReportedSeconds = -1;
  bool _reporting = false;
  bool _forceReportQueued = false;

  bool get isTv => (video.value?.type ?? _ugType) == 2;

  bool get hasSelectableMedia => episodes.length > 1;

  bool get hasSeasons => seasons.length > 1;

  bool get changingSeason => _changingSeason;

  int get currentSeasonIndex {
    final data = video.value;
    if (data == null || seasons.isEmpty) {
      return -1;
    }
    final index = seasons.indexWhere(
      (item) => item.ugVideoInfoId == data.ugVideoInfoId,
    );
    if (index != -1) {
      return index;
    }
    return seasons.indexWhere((item) => item.seasonNum == data.season);
  }

  ScrollController seasonController(int index) {
    if (_seasonController != null) {
      return _seasonController!;
    }
    return _seasonController = ScrollController(
      initialScrollOffset: index * 150,
    );
  }

  UgreenPlayEpisode? get currentEpisode {
    final index = episodeIndex.value;
    if (index >= 0 && index < episodes.length) {
      return episodes[index];
    }
    return null;
  }

  UgreenPlayFile? get currentFile {
    final episode = currentEpisode;
    if (episode == null) {
      return null;
    }
    final index = fileIndex.value;
    if (index >= 0 && index < episode.files.length) {
      return episode.files[index];
    }
    return episode.firstFile;
  }

  UgreenTranscodableResolution? get currentQuality {
    final index = qualityIndex.value;
    if (index >= 0 && index < qualities.length) {
      return qualities[index];
    }
    return null;
  }

  UgreenAudioTrack? get currentAudio {
    final info = transcode.value;
    final index = audioIndex.value;
    if (info != null && index >= 0 && index < info.audios.length) {
      return info.audios[index];
    }
    return null;
  }

  String get coverUrl {
    final current = service.session.value;
    final data = video.value;
    if (current == null || data == null) {
      return '';
    }
    return UgreenMediaHttp.coverUrl(
      current,
      categoryId: data.categoryId,
      posterPath: data.posterPath,
    );
  }

  Duration get _duration {
    final info = transcode.value;
    if (info != null && info.duration > 0) {
      return Duration(milliseconds: info.duration);
    }
    final file = currentFile;
    if (file != null && file.duration > 0) {
      return Duration(milliseconds: file.duration);
    }
    return Duration(
      seconds: videoDetailCtr.plPlayerController.duration.value,
    );
  }

  Duration get _position =>
      Duration(seconds: videoDetailCtr.plPlayerController.position.value);

  @override
  void onInit() {
    final args = Get.arguments;
    _ugVideoInfoId = args['ugVideoInfoId'] as int;
    _mediaLibSetId = args['mediaLibSetId'] as int;
    _ugType = args['ugType'] as int;
    _initialFilePath = args['initialFilePath'] as String? ?? '';
    _initialEpisodeId = args['initialEpisodeId'] as int?;
    _initialEpisode = args['initialEpisode'] as int?;
    super.onInit();
    videoDetailCtr.plPlayerController.addPositionListener(
      onPositionChanged,
    );
    loadDetail();
  }

  Future<void> loadDetail({bool force = false}) {
    if (force) {
      _loading = null;
    }
    return _loading ??= _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (isDetailLoading.value) {
      return;
    }
    isDetailLoading.value = true;
    detailError.value = null;
    try {
      final current = service.session.value;
      if (current == null) {
        _setDetailError('请先登录绿联云');
        _toast('请先登录绿联云');
        return;
      }
      if (_ugVideoInfoId <= 0) {
        _setDetailError('缺少视频 ID');
        _toast('缺少视频 ID');
        return;
      }
      if (_ugType == 2) {
        final result = await UgreenVideoHttp.tvDetail(
          current,
          ugVideoInfoId: _ugVideoInfoId,
        );
        if (isClosed) {
          return;
        }
        if (result case Success(:final response)) {
          _applyTv(response);
        } else if (result is Error) {
          _setDetailError(result.errMsg ?? '加载失败');
          _handleError(result);
        }
      } else {
        final result = await UgreenVideoHttp.movieDetail(
          current,
          id: _ugVideoInfoId,
          mediaLibSetId: _mediaLibSetId,
        );
        if (isClosed) {
          return;
        }
        if (result case Success(:final response)) {
          _applyMovie(response);
        } else if (result is Error) {
          _setDetailError(result.errMsg ?? '加载失败');
          _handleError(result);
        }
      }
    } catch (error) {
      if (!isClosed) {
        detailError.value = '加载失败: $error';
        videoDetailCtr.autoPlay = false;
        videoDetailCtr.videoState.value = false;
        _toast('加载失败: $error');
      }
    } finally {
      if (!isClosed) {
        isDetailLoading.value = false;
      }
    }
  }

  void _applyMovie(UgreenMovieDetail detail) {
    seasons.clear();
    video.value = detail.videoInfo;
    final episode = UgreenPlayEpisode.fromMovie(detail, 0);
    if (episode.files.isEmpty) {
      detailError.value = '没有可用播放文件';
      videoDetailCtr.autoPlay = false;
      videoDetailCtr.videoState.value = false;
      _toast('没有可用播放文件');
      return;
    }
    episodes.assignAll([episode]);
    _afterDetailLoaded();
  }

  void _applyTv(UgreenTvDetail detail, {int? preferredEpisodeIndex}) {
    seasons.assignAll(
      [...detail.seasonInfo]
        ..sort((a, b) => a.seasonNum.compareTo(b.seasonNum)),
    );
    video.value = detail.videoInfo;
    episodes.assignAll([
      for (var i = 0; i < detail.tvInfo.length; i++)
        UgreenPlayEpisode.fromTvEpisode(detail.tvInfo[i], i),
    ]);
    if (episodes.isEmpty) {
      detailError.value = '没有可用播放文件';
      videoDetailCtr.autoPlay = false;
      videoDetailCtr.videoState.value = false;
      _toast('没有可用播放文件');
      return;
    }
    _afterDetailLoaded(preferredEpisodeIndex: preferredEpisodeIndex);
  }

  void _afterDetailLoaded({int? preferredEpisodeIndex}) {
    final data = video.value;
    if (data == null) {
      return;
    }
    videoDetailCtr.cover.value = coverUrl;
    videoDetail.value.title = data.name;
    videoDetail.refresh();
    transcode.value = null;
    qualities.clear();
    qualityIndex.value = -1;
    audioIndex.value = -1;
    if (preferredEpisodeIndex != null &&
        preferredEpisodeIndex >= 0 &&
        preferredEpisodeIndex < episodes.length) {
      episodeIndex.value = preferredEpisodeIndex;
    } else {
      episodeIndex.value = _initialEpisodeIndex();
    }
    fileIndex.value = _initialFileIndex(currentEpisode);
  }

  int _initialEpisodeIndex() {
    final initialId = _initialEpisodeId;
    if (initialId != null && initialId > 0) {
      final index = episodes.indexWhere(
        (item) => item.ugTelevisionEpisodeId == initialId,
      );
      if (index != -1) {
        return index;
      }
    }
    var path = _initialFilePath;
    if (path.isEmpty) {
      path = video.value?.lastPlayFilePath ?? '';
    }
    if (path.isNotEmpty) {
      final index = episodes.indexWhere(
        (item) => item.files.any((file) => file.path == path),
      );
      if (index != -1) {
        return index;
      }
    }
    final episode = _initialEpisode;
    if (episode != null && episode > 0) {
      final index = episodes.indexWhere((item) => item.episode == episode);
      if (index != -1) {
        return index;
      }
    }
    return episodes.isEmpty ? -1 : 0;
  }

  int _initialFileIndex(UgreenPlayEpisode? episode) {
    if (episode == null || episode.files.isEmpty) {
      return -1;
    }
    var path = _initialFilePath;
    if (path.isEmpty) {
      path = video.value?.lastPlayFilePath ?? '';
    }
    if (path.isNotEmpty) {
      final index = episode.files.indexWhere((file) => file.path == path);
      if (index != -1) {
        return index;
      }
    }
    var bestIndex = 0;
    var bestClarity = -1;
    var bestTime = -1;
    for (var i = 0; i < episode.files.length; i++) {
      final file = episode.files[i];
      if (file.clarity > bestClarity ||
          (file.clarity == bestClarity && file.currentPlayTime > bestTime)) {
        bestClarity = file.clarity;
        bestTime = file.currentPlayTime;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  Future<bool> changeSeason(int index) async {
    if (_changingSeason || isClosed) {
      return false;
    }
    if (index < 0 || index >= seasons.length) {
      return false;
    }
    final target = seasons[index];
    final data = video.value;
    if (data == null || target.ugVideoInfoId == data.ugVideoInfoId) {
      return false;
    }
    final current = service.session.value;
    if (current == null) {
      _toast('请先登录绿联云');
      return false;
    }
    _changingSeason = true;
    final runId = ++_runId;
    _showLoading('切换季');
    try {
      final result = await UgreenVideoHttp.tvDetail(
        current,
        ugVideoInfoId: target.ugVideoInfoId,
      );
      if (_stale(runId)) {
        return false;
      }
      if (result is! Success<UgreenTvDetail>) {
        if (result is Error) {
          _handleError(result);
        }
        return false;
      }
      final detail = result.response;
      if (detail.tvInfo.isEmpty) {
        _toast('该季暂无剧集');
        return false;
      }
      _ugVideoInfoId = target.ugVideoInfoId;
      _initialEpisodeId = null;
      _initialEpisode = null;
      _initialFilePath = '';
      _applyTv(detail, preferredEpisodeIndex: 0);
      final episode = episodes.first;
      return await playEpisode(
        0,
        fileIndex: _initialFileIndex(episode),
        autoplay: true,
      );
    } catch (error) {
      if (!isClosed) {
        _toast('切换季失败: $error');
      }
      return false;
    } finally {
      _dismissLoading();
      _changingSeason = false;
    }
  }

  Future<bool> playCurrent({
    bool autoFullScreenFlag = false,
    bool autoplay = false,
  }) async {
    if (autoplay) {
      videoDetailCtr.autoPlay = true;
    }
    if (episodes.isEmpty) {
      await loadDetail();
    }
    if (episodes.isEmpty) {
      return false;
    }
    final index = episodeIndex.value;
    final validIndex = index >= 0 && index < episodes.length ? index : 0;
    final currentFileIndex = fileIndex.value;
    return playEpisode(
      validIndex,
      fileIndex: validIndex == episodeIndex.value && currentFileIndex >= 0
          ? currentFileIndex
          : null,
      autoFullScreenFlag: autoFullScreenFlag,
      autoplay: autoplay,
    );
  }

  Future<bool> playEpisode(
    int index, {
    int? fileIndex,
    bool autoFullScreenFlag = false,
    bool autoplay = false,
    Duration? inheritPosition,
  }) async {
    if (index < 0 || index >= episodes.length) {
      return false;
    }
    if (autoplay) {
      videoDetailCtr.autoPlay = true;
    }
    final episode = episodes[index];
    var targetFileIndex =
        fileIndex ??
        (index == episodeIndex.value
            ? this.fileIndex.value
            : _initialFileIndex(episode));
    if (targetFileIndex < 0 || targetFileIndex >= episode.files.length) {
      targetFileIndex = 0;
    }
    if (episode.files.isEmpty) {
      return false;
    }
    final file = episode.files[targetFileIndex];
    final current = service.session.value;
    if (current == null) {
      _toast('请先登录绿联云');
      return false;
    }
    final runId = ++_runId;
    episodeIndex.value = index;
    this.fileIndex.value = targetFileIndex;
    _lastReportedSeconds = -1;
    _showLoading('获取播放地址');
    try {
      final taskId = _nextTaskId();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final infoRes = await UgreenVideoHttp.transcodeInfo(
        current,
        videoPath: file.path,
        taskId: taskId,
        timestamp: timestamp,
        srcType: _srcType,
      );
      if (_stale(runId)) {
        return false;
      }
      if (infoRes is Error) {
        _handleError(infoRes);
        videoDetailCtr.autoPlay = false;
        videoDetailCtr.videoState.value = false;
        return false;
      }
      if (infoRes is! Success<UgreenTranscodeInfo>) {
        _toast('获取播放信息失败');
        return false;
      }
      _taskId = taskId;
      _timestamp = timestamp;
      transcode.value = infoRes.response;
      _buildQualities(infoRes.response);
      final audios = infoRes.response.audios;
      if (audios.isEmpty) {
        audioIndex.value = -1;
      } else {
        final defaultIndex = audios.indexWhere((item) => item.isDefault);
        audioIndex.value = defaultIndex == -1 ? 0 : defaultIndex;
      }
      final seek = inheritPosition ?? _resumePosition(file);
      return await _startPlayback(
        runId,
        seek: seek,
        autoFullScreenFlag: autoFullScreenFlag,
      );
    } catch (error) {
      if (!isClosed) {
        _toast('播放失败: $error');
        videoDetailCtr.autoPlay = false;
        videoDetailCtr.videoState.value = false;
      }
      return false;
    } finally {
      _dismissLoading();
    }
  }

  void _buildQualities(UgreenTranscodeInfo info) {
    final list = <UgreenTranscodableResolution>[];
    final seen = <String>{};
    for (final item in info.transcodeable) {
      if (item.resolution.isEmpty || !seen.add(item.resolution)) {
        continue;
      }
      list.add(item);
    }
    qualities.assignAll(list);
    qualityIndex.value = -1;
  }

  Future<bool> _startPlayback(
    int runId, {
    Duration? seek,
    required bool autoFullScreenFlag,
  }) async {
    final info = transcode.value;
    final file = currentFile;
    final current = service.session.value;
    if (info == null || file == null || current == null) {
      return false;
    }
    if (qualities.isEmpty) {
      videoDetailCtr.autoPlay = false;
      videoDetailCtr.videoState.value = false;
      _toast('没有可用清晰度');
      return false;
    }
    final base = await UgreenEndpoint.resolve(current);
    if (base == null) {
      _toast('无法连接绿联设备');
      return false;
    }
    final index =
        qualityIndex.value >= 0 && qualityIndex.value < qualities.length
        ? qualityIndex.value
        : 0;
    final prepared = await _preparePlayback(
      info,
      file,
      qualities[index],
      base,
      current.token,
      current.clientId,
    );
    if (_stale(runId)) {
      return false;
    }
    if (prepared == null) {
      videoDetailCtr.autoPlay = false;
      videoDetailCtr.videoState.value = false;
      _toast('无法播放该视频');
      return false;
    }
    qualityIndex.value = index;
    await _applyPrepared(
      prepared,
      seek: seek,
      autoFullScreenFlag: autoFullScreenFlag,
    );
    return !_stale(runId);
  }

  Future<String?> _preparePlayback(
    UgreenTranscodeInfo info,
    UgreenPlayFile file,
    UgreenTranscodableResolution quality,
    String base,
    String token,
    String clientId, {
    int? audioId,
  }) async {
    final current = service.session.value;
    if (current == null) {
      return null;
    }
    final hash = info.hash;
    if (hash.isEmpty) {
      return null;
    }
    final m3u8File = '${hash}_${quality.resolution}.m3u8';
    final playRes = await UgreenVideoHttp.play(
      current,
      m3u8File: m3u8File,
      taskId: _taskId,
      timestamp: _timestamp,
      srcType: _srcType,
      subtitleIndex: -1,
      audioIndex: audioId ?? _currentAudioId(info),
    );
    if (playRes is Error) {
      return null;
    }
    final upstream = UgreenVideoHttp.m3u8Url(
      base,
      m3u8File: m3u8File,
      taskId: _taskId,
      timestamp: _timestamp,
      srcType: _srcType,
      token: token,
    );
    try {
      return await UgreenPlayProxy.instance.prepare(
        upstreamUrl: upstream,
        token: token,
        clientId: clientId,
        taskId: _taskId,
      );
    } catch (_) {
      return null;
    }
  }

  int? _currentAudioId(UgreenTranscodeInfo info) {
    final index = audioIndex.value;
    if (index >= 0 && index < info.audios.length) {
      return info.audios[index].id;
    }
    return null;
  }

  Future<void> _applyPrepared(
    String url, {
    Duration? seek,
    required bool autoFullScreenFlag,
  }) async {
    final position = seek ?? Duration.zero;
    videoDetailCtr
      ..onReset()
      ..playHeaders = const {}
      ..videoUrl = url
      ..audioUrl = ''
      ..cid.value = episodeIndex.value
      ..defaultST = position;
    final data = video.value;
    final episode = currentEpisode;
    if (data != null) {
      videoDetail.value.title = isTv && episode != null
          ? '${data.name} · ${episode.displayTitle}'
          : data.name;
      videoDetail.refresh();
    }
    await videoDetailCtr.playerInit(
      autoFullScreenFlag: autoFullScreenFlag,
    );
  }

  Future<void> switchQuality(int index) async {
    if (index < 0 || index >= qualities.length) {
      return;
    }
    if (index == qualityIndex.value) {
      return;
    }
    final info = transcode.value;
    final file = currentFile;
    final current = service.session.value;
    if (info == null || file == null || current == null) {
      return;
    }
    final base = await UgreenEndpoint.resolve(current);
    if (base == null) {
      _toast('无法连接绿联设备');
      return;
    }
    final runId = ++_runId;
    final seek = _position;
    _showLoading('切换清晰度');
    try {
      final prepared = await _preparePlayback(
        info,
        file,
        qualities[index],
        base,
        current.token,
        current.clientId,
      );
      if (_stale(runId)) {
        return;
      }
      if (prepared == null) {
        _toast('该清晰度不可用');
        return;
      }
      qualityIndex.value = index;
      await _applyPrepared(
        prepared,
        seek: seek,
        autoFullScreenFlag: false,
      );
    } finally {
      _dismissLoading();
    }
  }

  Future<void> switchAudio(int index) async {
    if (index == audioIndex.value) {
      return;
    }
    await _reloadTracks(audio: index);
  }

  Future<void> _reloadTracks({required int audio}) async {
    final info = transcode.value;
    final file = currentFile;
    final quality = currentQuality;
    final current = service.session.value;
    if (info == null || file == null || quality == null || current == null) {
      return;
    }
    final base = await UgreenEndpoint.resolve(current);
    if (base == null) {
      _toast('无法连接绿联设备');
      return;
    }
    final runId = ++_runId;
    final seek = _position;
    _showLoading('切换音轨');
    try {
      final prepared = await _preparePlayback(
        info,
        file,
        quality,
        base,
        current.token,
        current.clientId,
        audioId: audio >= 0 && audio < info.audios.length
            ? info.audios[audio].id
            : null,
      );
      if (_stale(runId)) {
        return;
      }
      if (prepared == null) {
        _toast('切换音轨失败');
        return;
      }
      audioIndex.value = audio;
      await _applyPrepared(
        prepared,
        seek: seek,
        autoFullScreenFlag: false,
      );
    } finally {
      _dismissLoading();
    }
  }

  Duration? _resumePosition(UgreenPlayFile file) {
    final seconds = file.currentPlayTime;
    if (seconds <= 5 || file.isCompleted) {
      return null;
    }
    final duration = _duration.inMilliseconds;
    if (duration > 0 && seconds * 1000 >= duration - 3000) {
      return null;
    }
    return Duration(seconds: seconds);
  }

  void onPositionChanged(Duration position) {
    final seconds = position.inSeconds;
    if (seconds < 1) {
      return;
    }
    if (_lastReportedSeconds == -1) {
      _lastReportedSeconds = seconds;
      return;
    }
    if ((seconds - _lastReportedSeconds).abs() < 10) {
      return;
    }
    unawaited(saveProgress());
  }

  Future<void> saveProgress({bool force = false}) async {
    if (_reporting) {
      if (force) {
        _forceReportQueued = true;
      }
      return;
    }
    final current = service.session.value;
    final data = video.value;
    final episode = currentEpisode;
    final file = currentFile;
    if (current == null || data == null || episode == null || file == null) {
      return;
    }
    final categoryId = data.categoryId.isNotEmpty
        ? data.categoryId
        : (episode.categoryId ?? '');
    if (data.ugVideoInfoId <= 0 ||
        data.mediaLibSetId <= 0 ||
        categoryId.isEmpty) {
      return;
    }
    var seconds = _position.inSeconds;
    final durationMs = _duration.inMilliseconds;
    if (seconds < 1) {
      return;
    }
    if (!force &&
        _lastReportedSeconds != -1 &&
        (seconds - _lastReportedSeconds).abs() < 10) {
      return;
    }
    var progress = 0.0;
    if (durationMs > 0) {
      final durationSeconds = durationMs ~/ 1000;
      if (seconds >= durationSeconds - 2) {
        seconds = durationSeconds;
        progress = 1;
      } else {
        progress = (seconds * 1000 / durationMs).clamp(0.0, 1.0);
      }
    }
    final recentlyPlayed = <String, dynamic>{
      if (data.type == 2) 'season': data.season,
      if (data.type == 2) 'episode': episode.episode,
      'media_lib_set_id': data.mediaLibSetId,
      'category_id': categoryId,
      if ((episode.ugTelevisionEpisodeId ?? 0) > 0)
        'ug_television_episode_id': episode.ugTelevisionEpisodeId,
      'current_play_time': seconds,
      'recently_played_file_path': file.path,
      'type': data.type,
      'play_folder_path': '',
      'progress': double.parse(progress.toStringAsFixed(4)),
    };
    _reporting = true;
    try {
      final res = await UgreenVideoHttp.reportProgress(
        current,
        recentlyPlayed: recentlyPlayed,
      );
      if (res is Success) {
        _lastReportedSeconds = seconds;
      } else if (res is Error && res.code == 1024) {
        service.logout();
        _toast('绿联云登录已过期');
      }
    } finally {
      _reporting = false;
      if (_forceReportQueued && !isClosed) {
        _forceReportQueued = false;
        unawaited(saveProgress(force: true));
      }
    }
  }

  @override
  bool prevPlay() {
    final previous = episodeIndex.value - 1;
    if (previous >= 0) {
      playEpisode(previous, autoplay: true);
      return true;
    }
    return false;
  }

  @override
  bool nextPlay() {
    final next = episodeIndex.value + 1;
    if (next < episodes.length) {
      playEpisode(next, autoplay: true);
      return true;
    }
    final player = videoDetailCtr.plPlayerController;
    if (player.playRepeat == PlayRepeat.listCycle && episodes.isNotEmpty) {
      if (episodes.length == 1) {
        final controller = player.videoPlayerController;
        if (controller != null) {
          controller.seek(Duration.zero).whenComplete(controller.play);
        }
      } else {
        playEpisode(0, autoplay: true);
      }
      return true;
    }
    return false;
  }

  void showEpisodePanel() {
    if (!hasSelectableMedia) {
      return;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }
    final isFullScreen = videoDetailCtr.plPlayerController.isFullScreen.value;
    final child = EpisodeUgreenPanel(
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
    final data = video.value;
    if (data == null) {
      return;
    }
    final context = Get.context;
    if (context == null || !context.mounted) {
      return;
    }
    videoDetailCtr.childKey.currentState?.showBottomSheet(
      constraints: const BoxConstraints(),
      (context) => UgreenIntroPanel(item: data),
    );
  }

  Future<void> onRefresh() async {
    _loading = null;
    await loadDetail(force: true);
  }

  String _nextTaskId() {
    final random = _random.nextInt(1 << 30).toRadixString(16);
    return 'PC&$random&${DateTime.now().millisecondsSinceEpoch}';
  }

  bool _stale(int runId) => isClosed || runId != _runId;

  void _showLoading(String msg) {
    if (_isLoadingShown) {
      return;
    }
    _isLoadingShown = true;
    SmartDialog.showLoading(msg: msg);
  }

  void _dismissLoading() {
    if (_isLoadingShown) {
      _isLoadingShown = false;
      SmartDialog.dismiss();
    }
  }

  void _toast(String msg) {
    if (!isClosed) {
      SmartDialog.showToast(msg);
    }
  }

  void _setDetailError(String message) {
    detailError.value = message;
    videoDetailCtr.autoPlay = false;
    videoDetailCtr.videoState.value = false;
  }

  void _handleError(LoadingState state) {
    if (state is Error) {
      if (state.code == 1024) {
        service.logout();
        _toast('绿联云登录已过期');
      } else {
        _toast(state.errMsg ?? '操作失败');
      }
    }
  }

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

  @override
  void onClose() {
    _runId++;
    videoDetailCtr.plPlayerController.removePositionListener(
      onPositionChanged,
    );
    _seasonController?.dispose();
    _seasonController = null;
    unawaited(saveProgress(force: true));
    super.onClose();
  }
}
