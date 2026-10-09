import 'package:PiliPlus/common/skeleton/media_bangumi.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/pages/search_panel/vod/controller.dart';
import 'package:PiliPlus/pages/search_panel/vod/widgets/item.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class SearchVodPanel extends CommonSearchPanel {
  const SearchVodPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchVodPanel> createState() => _SearchVodPanelState();
}

class _SearchVodPanelState
    extends CommonSearchPanelState<SearchVodPanel, SearchVodData, VodVideo> {
  @override
  late final SearchVodController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchVodController(
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
            child: Row(
              children: [
                _sourceItem(null, '全部'),
                for (final source in controller.filterSources)
                  _sourceItem(source.key, source.name),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceItem(String? key, String name) => SearchText(
    fontSize: 13,
    text: name,
    bgColor: Colors.transparent,
    textColor: controller.selectedSourceKey.value == key
        ? colorScheme.primary
        : colorScheme.outline,
    onTap: (_) => controller.onSelectSource(key),
  );

  @override
  Widget buildList(List<VodVideo> list) {
    final filtered = controller.filtered(list);
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (BuildContext context, int index) =>
          SearchVodItem(item: filtered[index]),
      itemCount: filtered.length,
    );
  }

  @override
  Widget get buildLoading => SliverGrid.builder(
    gridDelegate: SliverGridDelegateWithExtentAndRatio(
      mainAxisSpacing: 2,
      maxCrossAxisExtent: Grid.smallCardWidth * 2,
      childAspectRatio: Style.aspectRatio * 1.5,
    ),
    itemBuilder: (context, index) => const MediaPgcSkeleton(),
    itemCount: 10,
  );
}
