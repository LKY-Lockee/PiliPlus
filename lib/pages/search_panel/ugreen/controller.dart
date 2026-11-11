import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/ugreen/search.dart';
import 'package:PiliPlus/pages/search_panel/controller.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_media.dart';
import 'package:PiliPlus/plugin/ugreen/http/ugreen_search.dart';
import 'package:PiliPlus/plugin/ugreen/ugreen_service.dart';
import 'package:get/get.dart';

class SearchUgreenController
    extends
        SearchPanelController<
          UgreenSearchGroup<UgreenSearchEntry>,
          UgreenSearchEntry
        > {
  SearchUgreenController({
    required super.keyword,
    required super.searchType,
    required super.tag,
  });

  final UgreenService service = UgreenService.to;
  final Rx<UgreenSearchType> selectedType = UgreenSearchType.all.obs;

  int _cursor = 0;
  int _total = 0;

  void onSelectType(UgreenSearchType type) {
    if (selectedType.value == type) {
      return;
    }
    selectedType.value = type;
    supersedePendingRequests();
    onReload();
  }

  @override
  Future<LoadingState<UgreenSearchGroup<UgreenSearchEntry>>>
  customGetData() async {
    final current = service.session.value;
    if (current == null || !service.isLogin) {
      return const Error('请先登录绿联云');
    }
    final type = selectedType.value;
    final res = await UgreenSearchHttp.search(
      current,
      keyword: keyword,
      type: type,
      cursor: _cursor,
    );
    if (res is Error) {
      return Error(res.errMsg, code: res.code);
    }
    if (res is! Success<UgreenSearchData>) {
      return const Error('搜索失败');
    }
    final group = switch (type) {
      UgreenSearchType.all => _allGroup(res.response),
      UgreenSearchType.media => _entryGroup(
        res.response.media,
        UgreenSearchMediaEntry.new,
      ),
      UgreenSearchType.people => _entryGroup(
        res.response.people,
        UgreenSearchPeopleEntry.new,
      ),
      UgreenSearchType.collection => _entryGroup(
        res.response.collection,
        UgreenSearchCollectionEntry.new,
      ),
      UgreenSearchType.file => _entryGroup(
        res.response.file,
        UgreenSearchFileEntry.new,
      ),
    };
    _cursor = group.cursor;
    _total = group.numResults ?? 0;
    return Success(group);
  }

  UgreenSearchGroup<UgreenSearchEntry> _allGroup(UgreenSearchData data) {
    final list = <UgreenSearchEntry>[
      for (final item in data.media.list ?? const <UgreenSearchMedia>[])
        UgreenSearchMediaEntry(item),
      for (final item in data.people.list ?? const <UgreenSearchPeople>[])
        UgreenSearchPeopleEntry(item),
      for (final item
          in data.collection.list ?? const <UgreenSearchCollection>[])
        UgreenSearchCollectionEntry(item),
      for (final item in data.file.list ?? const <UgreenSearchFile>[])
        UgreenSearchFileEntry(item),
    ];
    return UgreenSearchGroup<UgreenSearchEntry>(
      numResults: list.length,
      cursor: 0,
      list: list,
    );
  }

  UgreenSearchGroup<UgreenSearchEntry> _entryGroup<T>(
    UgreenSearchGroup<T> group,
    UgreenSearchEntry Function(T item) entryOf,
  ) {
    return UgreenSearchGroup<UgreenSearchEntry>(
      numResults: group.numResults,
      cursor: group.cursor,
      list: [for (final item in group.list ?? const []) entryOf(item)],
    );
  }

  @override
  void checkIsEnd(int length) {
    isEnd = selectedType.value == UgreenSearchType.all || length >= _total;
  }

  @override
  Future<void> onRefresh() {
    _cursor = 0;
    _total = 0;
    return super.onRefresh();
  }

  String coverUrl({String? categoryId, String? posterPath}) {
    final current = service.session.value;
    if (current == null) {
      return '';
    }
    return UgreenMediaHttp.coverUrl(
      current,
      categoryId: categoryId,
      posterPath: posterPath,
    );
  }
}
