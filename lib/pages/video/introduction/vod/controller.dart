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
import 'package:PiliPlus/plugin/pl_player/models/play_repeat.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/api/api_config.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/parse_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_collect.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_record.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/server/control_manager.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/default_config.dart';
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
  late final String sourceKey;
  late final String vodId;

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
      detail.value = response;
      videoDetail.value.title = response.video.title;
      if (response.video.cover?.isNotEmpty == true) {
        videoDetailCtr.cover.value = response.video.cover!;
      }
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

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.play
  Future<bool> playEpisode(
    int flag,
    int index, {
    bool autoFullScreenFlag = false,
  }) async {
    final src = source;
    final cfg = tvboxService.config;
    final data = detail.value;
    if (src == null || cfg == null || data == null) {
      return false;
    }
    final group = data.playFlags[flag];
    final episode = group.episodes[index];

    SmartDialog.showLoading(msg: '获取播放地址');
    LoadingState<VodPlayInfo> res;
    try {
      final info = await SourceViewModel(
        config: cfg,
        sourceKey: sourceKey,
      ).getPlay(group.flag, episode.url);
      res = switch (info) {
        Success(:final response) => await _resolve(
          cfg,
          response,
          group.flag,
        ),
        _ => info,
      };
    } catch (e) {
      res = Error(e.toString());
    }
    SmartDialog.dismiss();

    VodPlayInfo? playInfo = res.dataOrNull;
    if (playInfo == null) {
      res.toast();
      return false;
    }
    var url = playInfo.url;
    if (url.isEmpty) {
      SmartDialog.showToast('获取播放地址失败');
      return false;
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
      if (result == null || result.isEmpty) {
        SmartDialog.showToast('嗅探失败');
        return false;
      }
      url = result;
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
      ..defaultST = null;
    final progress = VodRecord.getProgress(progressKeyOf);
    if (progress != null && progress > 5000) {
      videoDetailCtr.defaultST = Duration(milliseconds: progress);
    }
    await videoDetailCtr.playerInit(autoFullScreenFlag: autoFullScreenFlag);
    saveRecord();
    return true;
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
        final cfg = tvboxService.config;
        if (target == null || cfg == null) {
          return;
        }
        SmartDialog.showLoading(msg: '搜索换源');
        final results = await SearchHelper.searchSource(
          cfg,
          target.key,
          data.video.title,
        );
        SmartDialog.dismiss();
        if (isClosed || results.isEmpty) {
          SmartDialog.showToast('该源未找到此内容');
          return;
        }
        final item = results.first;
        PageUtils.toVodPage(
          sourceKey: item.sourceKey,
          vodId: item.id,
          title: data.video.title,
          cover: data.video.cover,
          off: true,
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
    videoDetailCtr.plPlayerController.removePositionListener(onPositionChanged);
    saveRecord();
    super.onClose();
  }

  /// com.github.tvbox.osc.ui.fragment.PlayFragment.initParse
  static Future<LoadingState<VodPlayInfo>> _resolve(
    ApiConfig? cfg,
    VodPlayInfo info,
    String flag,
  ) async {
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
        return _applyParse(parse, info, headers);
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
      return SuperParse.resolve(cfg, info, flag);
    }

    if (prefix.startsWith('json:')) {
      return _jsonParse(prefix.substring(5), info, headers);
    }
    if (prefix.startsWith('parse:')) {
      final name = prefix.substring(6);
      final parse = cfg?.parseBeanList
          .where((item) => item.name == name)
          .firstOrNull;
      if (parse == null) {
        return const Error('未找到指定解析');
      }
      return _applyParse(parse, info, headers);
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
    Map<String, String> headers,
  ) async {
    final merged = <String, String>{...headers, ...parse.headers};
    if (parse.type == 1) {
      return _jsonParse(parse.url, info, merged);
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
    Map<String, String> headers,
  ) async {
    final requestUrl = '$parseUrl${StringUtils.javaUrlEncode(info.url)}';
    final data = await Http.string(
      requestUrl,
      options: Options(
        responseType: ResponseType.plain,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
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
