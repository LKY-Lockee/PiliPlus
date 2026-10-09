import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/fav_type.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/models_new/vod/video_data.dart';
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
          _buildFollow(theme),
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

  Widget _buildFollow(ThemeData theme) => SliverToBoxAdapter(
    child: Column(
      children: [
        _buildFollowTitle(theme),
        SizedBox(
          height:
              Grid.smallCardWidth / 2 / 0.75 +
              MediaQuery.textScalerOf(context).scale(50),
          child: Obx(
            () => _buildFollowBody(controller.followState.value),
          ),
        ),
      ],
    ),
  );

  Widget _buildFollowTitle(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Row(
      children: [
        Obx(
          () => Text(
            '最近点播 ${controller.followCount.value <= 0 ? '' : ' ${controller.followCount.value}'}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: '刷新',
          onPressed: controller.queryVodFollow,
          icon: const Icon(
            Icons.refresh,
            size: 20,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: moreTextButton(
            text: '查看全部',
            onTap: () => Get.toNamed(
              '/fav',
              arguments: FavTabType.vod.index,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: theme.colorScheme.secondary,
          ),
        ),
      ],
    ),
  );

  Widget _buildFollowBody(LoadingState<List<FavVodItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? ListView.builder(
                controller: controller.followController,
                scrollDirection: Axis.horizontal,
                itemCount: response.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  var resp = response[index];
                  return Container(
                    width: Grid.smallCardWidth / 2,
                    margin: EdgeInsets.only(
                      left: Style.safeSpace,
                      right: index == response.length - 1 ? Style.safeSpace : 0,
                    ),
                    child: VodCardV(
                      item: VodVideo(
                        id: resp.vodId,
                        title: resp.title ?? '',
                        cover: resp.cover,
                        remarks: resp.remarks,
                        type: "看到${resp.showTitle}",
                      )..sourceKey = resp.sourceKey,
                    ),
                  );
                },
              )
            : const Center(child: Text('还没有点播')),
      Error(:final errMsg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          errMsg ?? '',
          textAlign: TextAlign.center,
        ),
      ),
    };
  }
}
