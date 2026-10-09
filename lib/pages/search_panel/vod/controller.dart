import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/pages/search_panel/controller.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox/osc/util/search_helper.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:get/get.dart';

class SearchVodController
    extends SearchPanelController<SearchVodData, VodVideo> {
  SearchVodController({
    required super.keyword,
    required super.searchType,
    required super.tag,
  });

  final RxnString selectedSourceKey = RxnString();

  void onSelectSource(String? key) => selectedSourceKey.value = key;

  List<VodVideo> filtered(List<VodVideo> list) {
    final key = selectedSourceKey.value;
    if (key == null) {
      return list;
    }
    return list.where((e) => e.sourceKey == key).toList();
  }

  List<({String key, String name})> get filterSources {
    final list = loadingState.value.dataOrNull;
    if (list == null || list.isEmpty) {
      return const [];
    }
    final config = TVBoxService.to.config;
    final seen = <String>{};
    final sources = <({String key, String name})>[];
    for (final e in list) {
      if (seen.add(e.sourceKey)) {
        sources.add((
          key: e.sourceKey,
          name: config?.getSource(e.sourceKey)?.name ?? e.sourceKey,
        ));
      }
    }
    return sources;
  }

  @override
  Future<LoadingState<SearchVodData>> customGetData() async {
    final tvboxService = TVBoxService.to;
    if (tvboxService.sourcesState.value is Loading) {
      await tvboxService.loadSources(useCache: true);
      if (isClosed) {
        return const Error('');
      }
    }
    final sources = tvboxService.searchableSources;
    final config = tvboxService.config;
    if (sources.isEmpty || config == null) {
      final state = tvboxService.sourcesState.value;
      return state is Error
          ? state
          : const Error('无可用点播源，请先在 设置-第三方平台设置-点播设置 中配置订阅');
    }
    selectedSourceKey.value = null;
    final results = <VodVideo>[];
    await Future.wait(
      sources.map((source) async {
        final items = await SearchHelper.searchSource(
          config,
          source.key,
          keyword,
        );
        if (isClosed) {
          return;
        }
        results.addAll(items);
        if (results.isNotEmpty) {
          loadingState.value = Success(List.of(results));
          searchResultController?.count[searchType.index] = results.length;
        }
      }),
    );
    if (results.isEmpty) {
      return const Error('搜索结果为空');
    }
    return Success(SearchVodData(list: results, numResults: results.length));
  }

  @override
  Future<void> onLoadMore() async {}
}
