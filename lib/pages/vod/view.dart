import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/fav_type.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/models_new/history/history_vod/list.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
import 'package:PiliPlus/pages/history/vod/view.dart';
import 'package:PiliPlus/pages/vod/controller.dart';
import 'package:PiliPlus/pages/vod/widgets/vod_card_v.dart';
import 'package:PiliPlus/pages/vod_index/view.dart';
import 'package:PiliPlus/plugin/tvbox/tvbox_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class VodPage extends StatefulWidget {
  const VodPage({super.key});

  @override
  State<VodPage> createState() => _VodPageState();
}

class _VodPageState extends State<VodPage> with AutomaticKeepAliveClientMixin {
  late final VodController controller;

  @override
  void initState() {
    controller = Get.put(VodController());
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    return refreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ..._buildSections(theme),
          ..._buildRcmd(theme),
        ],
      ),
    );
  }

  List<Widget> _buildRcmd(ThemeData theme) => [
    _buildRcmdTitle(theme),
    SliverPadding(
      padding: const EdgeInsets.only(
        left: Style.safeSpace,
        right: Style.safeSpace,
        bottom: 100,
      ),
      sliver: Obx(
        () => controller.recType.value == TVBoxService.homeRecDouban
            ? _buildDoubanBody(controller.loadingState.value)
            : _buildRcmdBody(controller.loadingState.value),
      ),
    ),
  ];

  Widget _buildRcmdTitle(ThemeData theme) => SliverToBoxAdapter(
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
          Text(
            '推荐',
            style: theme.textTheme.titleMedium,
          ),
          moreTextButton(
            padding: const EdgeInsets.symmetric(vertical: 2),
            onTap: () => Get.to(const VodIndexPage()),
            color: theme.colorScheme.secondary,
          ),
        ],
      ),
    ),
  );

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: Style.cardSpace,
    crossAxisSpacing: Style.cardSpace,
    maxCrossAxisExtent: Grid.smallCardWidth * 0.6,
    childAspectRatio: 0.75,
    mainAxisExtent: MediaQuery.textScalerOf(context).scale(50),
  );

  Widget _buildRcmdBody(LoadingState<List<VodVideo>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return VodCardV(item: response[index]);
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildDoubanBody(LoadingState<List<VodVideo>?> loadingState) {
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(child: SizedBox.shrink()),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  final card = response[index];
                  return VodCardV(
                    item: card,
                    coverHeaders: VodController.doubanCoverHeaders,
                    onTap: () => Get.toNamed(
                      '/searchResult',
                      parameters: {'keyword': card.title},
                      arguments: {'initIndex': SearchType.vod.index},
                    ),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  List<Widget> _buildSections(ThemeData theme) {
    final sections = <Widget>[];
    void addRail<T>({
      required String title,
      required List<T> list,
      required String emptyText,
      required VoidCallback onRefresh,
      required VoidCallback onMore,
      required Widget Function(T item) cardBuilder,
    }) {
      sections
        ..add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Text(
                    title + (list.isEmpty ? '' : ' ${list.length}'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '刷新',
                    onPressed: onRefresh,
                    icon: const Icon(
                      Icons.refresh,
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: moreTextButton(
                      text: '查看全部',
                      onTap: onMore,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        ..add(
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  Grid.smallCardWidth / 2 / 0.75 +
                  MediaQuery.textScalerOf(context).scale(50),
              child: list.isEmpty
                  ? Center(child: Text(emptyText))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return Container(
                          width: Grid.smallCardWidth / 2,
                          margin: EdgeInsets.only(
                            left: Style.safeSpace,
                            right: index == list.length - 1
                                ? Style.safeSpace
                                : 0,
                          ),
                          child: cardBuilder(list[index]),
                        );
                      },
                    ),
            ),
          ),
        );
    }

    addRail<HistoryVodItemModel>(
      title: '最近播放',
      list: controller.historyList,
      emptyText: '还没有播放记录',
      onRefresh: controller.refreshHistory,
      onMore: () => Get.toNamed('/history', arguments: HistoryVodPage),
      cardBuilder: (item) => _buildVodCard(
        sourceKey: item.sourceKey,
        vodId: item.vodId,
        title: item.title,
        cover: item.cover,
        remarks: item.remarks,
        showTitle: item.showTitle,
      ),
    );
    addRail<FavVodItemModel>(
      title: '我的收藏',
      list: controller.favoriteList,
      emptyText: '还没有收藏',
      onRefresh: controller.refreshFavorites,
      onMore: () => Get.toNamed('/fav', arguments: FavTabType.vod.index),
      cardBuilder: (item) => _buildVodCard(
        sourceKey: item.sourceKey,
        vodId: item.vodId,
        title: item.title,
        cover: item.cover,
        remarks: item.remarks,
        showTitle: item.showTitle,
      ),
    );
    return sections;
  }

  Widget _buildVodCard({
    required String sourceKey,
    required String vodId,
    required String? title,
    required String? cover,
    required String? remarks,
    required String? showTitle,
  }) {
    return VodCardV(
      item: VodVideo(
        id: vodId,
        title: title ?? '',
        cover: cover,
        remarks: remarks,
        type: showTitle == null || showTitle.isEmpty ? null : '看到$showTitle',
      )..sourceKey = sourceKey,
    );
  }
}
