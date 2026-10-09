import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/category.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/bean/source_bean.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/viewmodel/source_view_model.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:get/get.dart';

class VodIndexController extends CommonListController<VodListData, VodVideo> {
  final tvboxService = TVBoxService.to;

  Rx<LoadingState<VodHomeData>> conditionState =
      LoadingState<VodHomeData>.loading().obs;

  late final RxBool isExpand = false.obs;

  RxMap<String, dynamic> indexParams = <String, dynamic>{}.obs;

  List<SourceBean> get sources => tvboxService.sources;

  VodHomeData? get _home => conditionState.value.dataOrNull;

  List<VodCategory> get categories => _home?.categories ?? const [];

  SourceBean? get currentSource =>
      sources.where((e) => e.key == indexParams['source']).firstOrNull;

  VodCategory? get currentCategory =>
      categories.where((e) => e.id == indexParams['category']).firstOrNull;

  List<VodFilter> get currentFilters {
    final category = currentCategory;
    if (category == null) {
      return const [];
    }
    return _home?.filters[category.id] ?? const [];
  }

  @override
  void onInit() {
    super.onInit();
    getVodIndexCondition();
  }

  Future<void> getVodIndexCondition() async {
    await tvboxService.getConfig();
    if (isClosed) return;
    final allSources = sources;
    if (allSources.isEmpty) {
      conditionState.value = const Error('无可用点播源');
      return;
    }
    final defaultSite = tvboxService.homeSourceKey.value;
    final source =
        allSources.where((e) => e.key == indexParams['source']).firstOrNull ??
        allSources.where((e) => e.key == defaultSite).firstOrNull ??
        allSources.first;
    indexParams['source'] = source.key;

    final res = await SourceViewModel(
      config: tvboxService.config!,
      sourceKey: source.key,
    ).getSort();
    if (isClosed) return;
    if (res case Success(:final response)) {
      if (response.categories.isEmpty) {
        conditionState.value = const Error('该源无分类');
        return;
      }
      indexParams['category'] = response.categories.first.id;
      for (final key in indexParams.keys.toList()) {
        if (key != 'source' && key != 'category') {
          indexParams.remove(key);
        }
      }
      onReload();
    }
    conditionState.value = res;
  }

  Future<void> selectSource(SourceBean source) {
    if (indexParams['source'] == source.key) {
      return Future.value();
    }
    indexParams['source'] = source.key;
    tvboxService.setHomeSource(source.key);
    scrollController.jumpToTop();
    conditionState.value = LoadingState.loading();
    return getVodIndexCondition();
  }

  Future<void> selectCategory(VodCategory category) {
    indexParams['category'] = category.id;
    for (final key in indexParams.keys.toList()) {
      if (key != 'source' && key != 'category') {
        indexParams.remove(key);
      }
    }
    return super.onReload();
  }

  Future<void> setFilter(String key, String value) {
    if (value.isEmpty) {
      indexParams.remove(key);
    } else {
      indexParams[key] = value;
    }
    return super.onReload();
  }

  @override
  Future<LoadingState<VodListData>> customGetData() {
    final source = currentSource;
    final String? categoryId = indexParams['category'];
    if (source == null || categoryId == null) {
      return Future.value(const Error('无可用分类'));
    }
    return SourceViewModel(
      config: tvboxService.config!,
      sourceKey: source.key,
    ).getList(categoryId, page, {
      for (final e in indexParams.entries)
        if (e.key != 'source' && e.key != 'category' && e.value != null)
          e.key: '${e.value}',
    });
  }

  @override
  List<VodVideo>? getDataList(VodListData response) {
    isEnd = !response.hasMore;
    return response.videoList;
  }
}
