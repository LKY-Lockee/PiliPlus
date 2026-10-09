import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/animated_height.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/self_sized_horizontal_list.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/models_new/vod/category.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/vod/widgets/vod_card_v.dart';
import 'package:PiliPlus/pages/vod_index/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodIndexPage extends StatefulWidget {
  const VodIndexPage({super.key});

  @override
  State<VodIndexPage> createState() => _VodIndexPageState();
}

class _VodIndexPageState extends State<VodIndexPage> {
  late final VodIndexController _ctr;

  @override
  void initState() {
    super.initState();
    _ctr = Get.put(VodIndexController());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleScaffold(
      appBar: AppBar(title: const Text('索引')),
      body: Obx(() => _buildBody(theme, _ctr.conditionState.value)),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<VodHomeData> loadingState,
  ) {
    final padding = MediaQuery.viewPaddingOf(context);
    return Padding(
      padding: EdgeInsets.only(left: padding.left, right: padding.right),
      child: CustomScrollView(
        controller: _ctr.scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildSourceWidget(theme)),
          ...switch (loadingState) {
            Loading() => const [
              SliverFillRemaining(hasScrollBody: false, child: m3eLoading),
            ],
            Success(:final response) => _buildConditionSlivers(
              theme,
              response,
              padding,
            ),
            Error(:final errMsg) => [
              HttpError(
                errMsg: errMsg,
                onReload: () => _ctr
                  ..conditionState.value = LoadingState.loading()
                  ..getVodIndexCondition(),
              ),
            ],
          },
        ],
      ),
    );
  }

  Widget _buildChoice({
    required ThemeData theme,
    required String text,
    required bool isCurr,
    required VoidCallback onTap,
  }) => SearchText(
    bgColor: isCurr ? theme.colorScheme.secondaryContainer : Colors.transparent,
    textColor: isCurr
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant,
    text: text,
    padding: const .symmetric(horizontal: 6, vertical: 3),
    onTap: (_) => onTap(),
  );

  Widget _buildSourceWidget(ThemeData theme) {
    final sources = _ctr.sources;
    if (sources.isEmpty) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      // ignore: invalid_use_of_protected_member
      final indexParams = _ctr.indexParams.value;
      return SelfSizedHorizontalList(
        padding: const .symmetric(horizontal: 12),
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = sources[index];
          return _buildChoice(
            theme: theme,
            text: item.name,
            isCurr: indexParams['source'] == item.key,
            onTap: () => _ctr.selectSource(item),
          );
        },
        itemCount: sources.length,
      );
    });
  }

  Widget _buildSortWidget(
    ThemeData theme,
    int index,
    VodHomeData data,
    Object item,
    Map<String, dynamic> indexParams,
  ) {
    final String text;
    final bool isCurr;
    final VoidCallback onTap;

    if (item is VodCategory) {
      text = item.name;
      isCurr = indexParams['category'] == item.id;
      onTap = () => _ctr.selectCategory(item);
    } else if (item is VodFilterOption) {
      final leading = data.categories.isNotEmpty ? 1 : 0;
      final filter = _ctr.currentFilters[index - leading];
      text = item.label.isEmpty ? '全部' : item.label;
      isCurr = item.value.isEmpty
          ? !indexParams.containsKey(filter.key)
          : indexParams[filter.key] == item.value;
      onTap = () => _ctr.setFilter(filter.key, item.value);
    } else {
      throw UnsupportedError(item.toString());
    }

    return _buildChoice(
      theme: theme,
      text: text,
      isCurr: isCurr,
      onTap: onTap,
    );
  }

  List<Widget> _buildConditionSlivers(
    ThemeData theme,
    VodHomeData data,
    EdgeInsets padding,
  ) {
    final int count =
        (data.categories.isNotEmpty ? 1 : 0) + _ctr.currentFilters.length;
    final bool expandable = count + 1 > 5;
    return [
      SliverToBoxAdapter(
        child: expandable
            ? Obx(
                () => AnimatedHeightWidget(
                  curve: Curves.easeInOut,
                  expand: _ctr.isExpand.value,
                  duration: const Duration(milliseconds: 200),
                  child: _buildSortsWidget(theme, count, data, expandable),
                ),
              )
            : _buildSortsWidget(theme, count, data, expandable),
      ),
      SliverPadding(
        padding: EdgeInsets.only(
          left: Style.safeSpace,
          right: Style.safeSpace,
          top: 12,
          bottom: padding.bottom + 100,
        ),
        sliver: Obx(() => _buildList(_ctr.loadingState.value)),
      ),
    ];
  }

  Widget _buildSortsWidget(
    ThemeData theme,
    int count,
    VodHomeData data,
    bool expandable,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...List.generate(
        expandable
            ? _ctr.isExpand.value
                  ? count
                  : (count - 1) ~/ 2
            : count,
        (index) {
          final item = data.categories.isNotEmpty
              ? index == 0
                    ? data.categories
                    : _ctr.currentFilters[index - 1].options
              : _ctr.currentFilters[index].options;
          if (item.isNotEmpty) {
            return Obx(() {
              // ignore: invalid_use_of_protected_member
              final indexParams = _ctr.indexParams.value;
              return SelfSizedHorizontalList(
                padding: const .fromLTRB(12, 10, 12, 0),
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, childIndex) => _buildSortWidget(
                  theme,
                  index,
                  data,
                  item[childIndex],
                  indexParams,
                ),
                itemCount: item.length,
              );
            });
          }
          return const SizedBox.shrink();
        },
      ),
      if (expandable) ...[
        const SizedBox(height: 8),
        GestureDetector(
          behavior: .opaque,
          onTap: _ctr.isExpand.toggle,
          child: Center(
            child: Row(
              mainAxisSize: .min,
              children: [
                Text(
                  _ctr.isExpand.value ? '收起' : '展开',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
                Icon(
                  _ctr.isExpand.value
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
  );

  Widget _buildList(LoadingState<List<VodVideo>?> loadingState) {
    return switch (loadingState) {
      Loading() => linearLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _ctr.onLoadMore();
                  }
                  return VodCardV(item: response[index]);
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _ctr.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _ctr.onReload,
      ),
    };
  }
}
