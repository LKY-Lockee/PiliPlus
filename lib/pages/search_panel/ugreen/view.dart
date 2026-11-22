import 'package:PiliPlus/common/skeleton/media_bangumi.dart';
import 'package:PiliPlus/common/sliver_single_child_delegate.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/models_new/ugreen/search.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/search_panel/ugreen/controller.dart';
import 'package:PiliPlus/pages/search_panel/ugreen/widgets/item.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class SearchUgreenPanel extends CommonSearchPanel {
  const SearchUgreenPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchUgreenPanel> createState() => _SearchUgreenPanelState();
}

class _SearchUgreenPanelState
    extends
        CommonSearchPanelState<
          SearchUgreenPanel,
          UgreenSearchGroup<UgreenSearchEntry>,
          UgreenSearchEntry
        > {
  @override
  late final SearchUgreenController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchUgreenController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: Grid.smallCardWidth * 2,
    mainAxisExtent: 160,
  );

  @override
  Widget buildHeader() {
    return SliverFloatingHeaderWidget(
      backgroundColor: colorScheme.surface,
      child: Padding(
        padding: const .fromLTRB(12, 0, 12, 4),
        child: Obx(
          () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: 8,
              children: [
                for (final type in UgreenSearchType.actives)
                  SearchText(
                    fontSize: 13,
                    text: type.label,
                    bgColor: Colors.transparent,
                    textColor: controller.selectedType.value == type
                        ? colorScheme.primary
                        : colorScheme.outline,
                    onTap: (_) => controller.onSelectType(type),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildList(List<UgreenSearchEntry> list) {
    if (controller.selectedType.value == UgreenSearchType.all) {
      final media = <UgreenSearchEntry>[];
      final people = <UgreenSearchEntry>[];
      final collection = <UgreenSearchEntry>[];
      final file = <UgreenSearchEntry>[];
      for (final entry in list) {
        switch (entry) {
          case UgreenSearchMediaEntry():
            media.add(entry);
          case UgreenSearchPeopleEntry():
            people.add(entry);
          case UgreenSearchCollectionEntry():
            collection.add(entry);
          case UgreenSearchFileEntry():
            file.add(entry);
        }
      }
      return SliverMainAxisGroup(
        slivers: [
          if (media.isNotEmpty) ...[
            _sectionHeader('影视', UgreenSearchType.media),
            _grid(media, loadMore: false),
          ],
          if (people.isNotEmpty) ...[
            _sectionHeader('演员', UgreenSearchType.people),
            _grid(people, loadMore: false),
          ],
          if (collection.isNotEmpty) ...[
            _sectionHeader('合集', UgreenSearchType.collection),
            _grid(collection, loadMore: false),
          ],
          if (file.isNotEmpty) ...[
            _sectionHeader('文件', UgreenSearchType.file),
            _grid(file, loadMore: false),
          ],
        ],
      );
    }
    return _grid(list);
  }

  Widget _grid(List<UgreenSearchEntry> list, {bool loadMore = true}) {
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (loadMore && index == list.length - 1) {
          controller.onLoadMore();
        }
        return _buildItem(list[index]);
      },
      itemCount: list.length,
    );
  }

  Widget _buildItem(UgreenSearchEntry entry) {
    return switch (entry) {
      UgreenSearchMediaEntry(:final item) => SearchUgreenItem(
        cover: controller.coverUrl(
          categoryId: item.categoryId,
          posterPath: item.posterPath.isNotEmpty
              ? item.posterPath
              : item.backdropPath,
        ),
        title: item.name,
        badge: item.type == 1
            ? '电影'
            : item.type == 2
            ? '剧集'
            : null,
        subtitle: item.score <= 0
            ? null
            : '评分:${item.score.toStringAsFixed(1)}',
        meta: _join([
          item.year > 0 ? '${item.year}' : null,
          item.localCount > 0 ? '共${item.localCount}集' : null,
        ]),
        onTap: () => PageUtils.toUgreenPage(
          ugVideoInfoId: item.ugVideoInfoId,
          mediaLibSetId: item.mediaLibSetId,
          type: item.type,
        ),
      ),
      UgreenSearchPeopleEntry(:final item) => SearchUgreenItem(
        cover: controller.coverUrl(posterPath: item.avatarUrl),
        title: item.name,
        meta: item.creditsCount > 0 ? '${item.creditsCount} 个作品' : null,
      ),
      UgreenSearchCollectionEntry(:final item) => SearchUgreenItem(
        cover: controller.coverUrl(
          posterPath: item.posterPath.isNotEmpty
              ? item.posterPath
              : item.backdropPath,
        ),
        title: item.name,
        badge: '合集',
        subtitle: item.score <= 0
            ? null
            : '评分:${item.score.toStringAsFixed(1)}',
        meta: item.localCount > 0 ? '共${item.localCount}项' : null,
      ),
      UgreenSearchFileEntry(:final item) => SearchUgreenItem(
        cover: controller.coverUrl(
          posterPath: item.backdropPath.isNotEmpty
              ? item.backdropPath
              : item.posterPath,
        ),
        title: item.videoName.isNotEmpty ? item.videoName : item.fileName,
        subtitle: item.clarityShow.isEmpty ? null : item.clarityShow,
        meta: item.folderPath.isNotEmpty ? item.folderPath : item.filePath,
        coverWidth: 148 * Style.aspectRatio,
        onTap: () => PageUtils.toUgreenPage(
          ugVideoInfoId: item.ugVideoInfoId,
          mediaLibSetId: item.mediaLibSetId,
          type: item.videoType,
          initialFilePath: item.filePath,
        ),
      ),
    };
  }

  String? _join(List<String?> values) {
    final result = values.whereType<String>().where((e) => e.isNotEmpty);
    return result.isEmpty ? null : result.join(' · ');
  }

  Widget _sectionHeader(String title, UgreenSearchType type) {
    final theme = Theme.of(Get.context!);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 10,
          bottom: 10,
          left: 16,
          right: 10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            moreTextButton(
              text: '查看全部',
              onTap: () => controller.onSelectType(type),
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget get buildLoading => SliverGrid(
    gridDelegate: gridDelegate,
    delegate: const SliverSingleChildDelegate(
      count: 10,
      child: MediaPgcSkeleton(),
    ),
  );
}
