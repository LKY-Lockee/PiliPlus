import 'dart:convert';

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/plugin/tvbox/catvod/net/http.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/cache/vod_collect.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart' show ScrollController;
import 'package:get/get.dart';

class VodController extends CommonListController<List<VodVideo>?, VodVideo> {
  final tvboxService = TVBoxService.to;
  final sources = <SourceBean>[].obs;
  SourceBean? currentSource;
  SourceViewModel? get _viewModel =>
      currentSource == null ? null : tvboxService.viewModel(currentSource!.key);
  String? _firstCategoryId;

  Worker? _sourceWorker;
  Worker? _recWorker;

  @override
  void onInit() {
    super.onInit();

    recType.value = tvboxService.homeRec.value;
    _sourceWorker = ever(tvboxService.homeSourceKey, (_) {
      if (!isClosed) {
        _setupVodSources();
      }
    });
    _recWorker = ever(tvboxService.homeRec, (value) {
      if (isClosed) return;
      recType.value = value;
      _loadRec();
    });

    queryVodFollow();
    tvboxService.getConfig().then((_) {
      if (!isClosed) {
        _setupVodSources();
      }
    });
  }

  @override
  Future<void> onRefresh() {
    queryVodFollow();
    return super.onRefresh();
  }

  void _setupVodSources() {
    final infoList = tvboxService.sources;
    sources.value = infoList;
    if (infoList.isNotEmpty) {
      final defaultSite = tvboxService.homeSourceKey.value;
      currentSource =
          infoList.where((item) => item.key == defaultSite).firstOrNull ??
          infoList.first;
    } else {
      currentSource = null;
    }
    if (recType.value != TVBoxService.homeRecDouban && infoList.isEmpty) {
      loadingState.value = tvboxService.sourcesState.value is Error
          ? tvboxService.sourcesState.value as Error
          : const Error('未配置点播源');
      return;
    }
    _loadRec();
  }

  // rec
  final RxInt recType = TVBoxService.homeRecSite.obs;

  void _loadRec() {
    if (recType.value != TVBoxService.homeRecDouban && sources.isEmpty) {
      loadingState.value = const Error('未配置点播源');
      return;
    }
    page = 1;
    isEnd = false;
    _firstCategoryId = null;
    loadingState.value = LoadingState.loading();
    isLoading = false;
    queryData();
  }

  // follow
  late RxInt followCount = (-1).obs;
  late Rx<LoadingState<List<FavVodItemModel>?>> followState =
      LoadingState<List<FavVodItemModel>?>.loading().obs;
  final followController = ScrollController();

  // douban
  static const int _doubanPageSize = 20;

  static const _defaultDoubanUA =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static const Map<String, String> doubanCoverHeaders = {
    'Referer': 'https://www.douban.com/',
    'User-Agent': _defaultDoubanUA,
  };

  String _doubanUrl(int start) {
    final year = DateTime.now().year;
    return 'https://movie.douban.com/j/new_search_subjects?sort=U&range=0,10&tags=&playable=1&start=$start&year_range=$year,$year';
  }

  /// com.github.tvbox.osc.ui.fragment.UserFragment.setDouBanData
  Future<LoadingState<List<VodVideo>?>> _getDoubanData(int pageIndex) async {
    final start = (pageIndex - 1) * _doubanPageSize;
    final ua = (Pref.vodUA.isNotEmpty && Pref.vodUA != 'okhttp/3.15')
        ? Pref.vodUA
        : _defaultDoubanUA;
    try {
      final res = await Http.get(
        _doubanUrl(start),
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': ua},
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      if (isClosed) {
        return const Error('');
      }
      final data = res.data;
      if (res.statusCode != 200 || data == null || data.isEmpty) {
        if (pageIndex == 1) {
          return Error('豆瓣热播加载失败(${res.statusCode})');
        }
        isEnd = true;
        return const Success(<VodVideo>[]);
      }
      final json = jsonDecode(data);
      final list = json is Map<String, dynamic> ? json['data'] : null;
      final cards = <VodVideo>[];
      if (list is List) {
        for (final item in list) {
          if (item is! Map) continue;
          final title = item['title']?.toString();
          if (title == null || title.isEmpty) continue;
          final rate = item['rate']?.toString() ?? '';
          var cover = item['cover']?.toString() ?? '';
          if (cover.startsWith('//')) {
            cover = 'https:$cover';
          }
          final type = <String>[
            ...?(item['directors'] as List?)?.whereType<String>(),
            ...?(item['casts'] as List?)?.whereType<String>(),
          ].join(',');
          cards.add(
            VodVideo(
              id: item['id']?.toString() ?? '',
              title: title,
              cover: cover.isEmpty ? null : cover,
              remarks: rate.isEmpty ? null : '$rate 分',
              type: type.isEmpty ? null : type,
              score: rate.isEmpty ? null : rate,
            ),
          );
        }
      }
      if (cards.length < _doubanPageSize) {
        isEnd = true;
      }
      return Success(cards);
    } catch (e) {
      if (pageIndex == 1) {
        return Error('豆瓣热播解析失败: $e');
      }
      isEnd = true;
      return const Success(<VodVideo>[]);
    }
  }

  // 我的订阅
  void queryVodFollow() {
    final list = VodCollect.getAll();
    followCount.value = list.length;
    followState.value = Success(list);
  }

  @override
  Future<LoadingState<List<VodVideo>?>> customGetData() async {
    if (recType.value == TVBoxService.homeRecDouban) {
      return _getDoubanData(page);
    }
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const Error('未配置点播源');
    }

    var tid = _firstCategoryId;
    if (page == 1) {
      _firstCategoryId = null;
      final res = await viewModel.getSort();
      if (res is! Success<VodHomeData>) {
        return res as Error;
      }
      final homeData = res.response;
      if (homeData.videoList.isNotEmpty) {
        isEnd = true;
        return Success(homeData.videoList);
      }
      if (homeData.categories.isEmpty) {
        return const Error('该源无内容');
      }
      tid = homeData.categories.first.id;
      _firstCategoryId = tid;
    }

    if (tid == null) {
      isEnd = true;
      return const Success(<VodVideo>[]);
    }

    final res = await viewModel.getList(tid, page);
    if (res is! Success<VodListData>) {
      return res as Error;
    }
    final listData = res.response;
    if (listData.videoList.isEmpty) {
      if (page == 1) {
        return const Error('该源无内容');
      }
      isEnd = true;
      return const Success(<VodVideo>[]);
    }
    isEnd = !listData.hasMore;
    return Success(listData.videoList);
  }

  @override
  bool customHandleResponse(bool isRefresh, Success<List<VodVideo>?> response) {
    if (recType.value != TVBoxService.homeRecDouban || isRefresh) {
      return false;
    }
    final existing = loadingState.value.dataOrNull;
    final cards = response.response;
    if (existing == null || cards == null || cards.isEmpty) {
      return false;
    }
    final seen = existing.map((e) => e.id).toSet();
    existing.addAll(cards.where((e) => seen.add(e.id)));
    loadingState.refresh();
    return true;
  }

  @override
  Future<void> onReload() async {
    loadingState.value = LoadingState.loading();
    await tvboxService.loadSources(useCache: true);
    if (!isClosed) {
      _setupVodSources();
    }
  }

  @override
  void onClose() {
    _sourceWorker?.dispose();
    _recWorker?.dispose();
    followController.dispose();
    super.onClose();
  }
}
