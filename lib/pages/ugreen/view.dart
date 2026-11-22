import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/more_btn.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/fav_type.dart';
import 'package:PiliPlus/pages/ugreen/controller.dart';
import 'package:PiliPlus/pages/ugreen/widgets/ugreen_card_v.dart';
import 'package:PiliPlus/pages/ugreen/widgets/ugreen_card_wide.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class UgreenPage extends StatefulWidget {
  const UgreenPage({super.key});

  @override
  State<UgreenPage> createState() => _UgreenPageState();
}

class _UgreenPageState extends State<UgreenPage>
    with AutomaticKeepAliveClientMixin {
  late final UgreenController controller;

  @override
  void initState() {
    controller = Get.put(UgreenController());
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ThemeData theme = Theme.of(context);
    return Obx(
      () => refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: _buildSlivers(theme),
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(ThemeData theme) {
    final sections = _buildSections(theme);
    if (sections.isNotEmpty) {
      final padding = MediaQuery.viewPaddingOf(context);
      return [
        ...sections,
        SliverToBoxAdapter(
          child: SizedBox(height: padding.bottom + 100),
        ),
      ];
    }
    if (_anyLoading) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: m3eLoading,
        ),
      ];
    }
    return [
      HttpError(onReload: controller.onRefresh),
    ];
  }

  bool get _anyLoading {
    return [
      controller.homeState.value,
      controller.folderState.value,
      controller.mediaLibState.value,
      controller.movieState.value,
      controller.tvState.value,
      controller.otherState.value,
    ].any((state) => state is Loading);
  }

  List<Widget> _buildSections(ThemeData theme) {
    final sections = <Widget>[];
    void addRail<T, U>({
      required String title,
      required LoadingState<T> state,
      required double itemWidth,
      required double coverAspectRatio,
      required List<U> Function(T value) items,
      required Widget Function(U item) itemBuilder,
      VoidCallback? onMore,
    }) {
      if (state is! Success<T>) {
        return;
      }
      final list = items(state.response);
      if (list.isEmpty) {
        return;
      }
      sections
        ..add(
          SliverToBoxAdapter(
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
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (onMore != null)
                    moreTextButton(
                      text: '查看全部',
                      onTap: onMore,
                      color: theme.colorScheme.secondary,
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
                  itemWidth / coverAspectRatio +
                  MediaQuery.textScalerOf(context).scale(50),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  return Container(
                    width: itemWidth,
                    margin: EdgeInsets.only(
                      left: Style.safeSpace,
                      right: index == list.length - 1 ? Style.safeSpace : 0,
                    ),
                    child: itemBuilder(list[index]),
                  );
                },
              ),
            ),
          ),
        );
    }

    addRail(
      title: '最近播放',
      state: controller.homeState.value,
      itemWidth: Grid.smallCardWidth / 2,
      coverAspectRatio: 0.75,
      items: (data) => data.recentlyPlayedArr.videoArr,
      itemBuilder: (item) => _buildVideoCard(
        title: item.name,
        categoryId: item.categoryId,
        posterPath: item.posterPath,
        score: item.score,
        year: item.year,
        localCount: item.localCount,
        ugVideoInfoId: item.ugVideoInfoId,
        mediaLibSetId: item.mediaLibSetId,
        type: item.type,
        initialFilePath: item.recentlyPlayedFilePath,
        initialEpisode: item.episode,
      ),
    );
    addRail(
      title: '我的收藏',
      state: controller.homeState.value,
      itemWidth: Grid.smallCardWidth / 2,
      coverAspectRatio: 0.75,
      items: (data) => data.favoritesArr.videoArr,
      itemBuilder: (item) => _buildVideoCard(
        title: item.name,
        categoryId: item.categoryId,
        posterPath: item.posterPath,
        score: item.score,
        year: item.year,
        localCount: item.localCount,
        ugVideoInfoId: item.ugVideoInfoId,
        mediaLibSetId: item.mediaLibSetId,
        type: item.type,
      ),
      onMore: () => Get.toNamed(
        '/fav',
        arguments: FavTabType.ugreen.index,
      ),
    );
    addRail(
      title: '最近更新',
      state: controller.homeState.value,
      itemWidth: Grid.smallCardWidth / 2,
      coverAspectRatio: 0.75,
      items: (data) => data.recentlyUpdateArr.videoArr,
      itemBuilder: (item) => _buildVideoCard(
        title: item.name,
        categoryId: item.categoryId,
        posterPath: item.posterPath,
        score: item.score,
        year: item.year,
        localCount: item.localCount,
        ugVideoInfoId: item.ugVideoInfoId,
        mediaLibSetId: item.mediaLibSetId,
        type: item.type,
      ),
    );
    addRail(
      title: '文件夹',
      state: controller.folderState.value,
      itemWidth: Grid.smallCardWidth / 1.25,
      coverAspectRatio: Style.aspectRatio16x9,
      items: (data) => data.folderArr,
      itemBuilder: (item) => _buildWideCard(
        title: item.showPath.split('/').last,
        covers: item.covers,
        itemCount: item.count,
      ),
    );
    addRail(
      title: '媒体库',
      state: controller.mediaLibState.value,
      itemWidth: Grid.smallCardWidth / 1.25,
      coverAspectRatio: Style.aspectRatio16x9,
      items: (data) => data.mediaLibInfoList,
      itemBuilder: (item) => _buildWideCard(
        title: item.mediaName,
        covers: item.videoCount < 3 ? item.backdropPaths : item.posterPaths,
        itemCount: item.videoCount,
      ),
    );
    addRail(
      title: '电影',
      state: controller.movieState.value,
      itemWidth: Grid.smallCardWidth / 2,
      coverAspectRatio: 0.75,
      items: (data) => data.videoArr,
      itemBuilder: (item) => _buildVideoCard(
        title: item.name,
        categoryId: item.categoryId,
        posterPath: item.posterPath,
        score: item.score,
        year: item.year,
        localCount: item.localCount,
        ugVideoInfoId: item.ugVideoInfoId,
        mediaLibSetId: item.mediaLibSetId,
        type: item.type,
      ),
    );
    addRail(
      title: '电视剧',
      state: controller.tvState.value,
      itemWidth: Grid.smallCardWidth / 2,
      coverAspectRatio: 0.75,
      items: (data) => data.videoArr,
      itemBuilder: (item) => _buildVideoCard(
        title: item.name,
        categoryId: item.categoryId,
        posterPath: item.posterPath,
        score: item.score,
        year: item.year,
        localCount: item.localCount,
        ugVideoInfoId: item.ugVideoInfoId,
        mediaLibSetId: item.mediaLibSetId,
        type: item.type,
      ),
    );
    addRail(
      title: '其它',
      state: controller.otherState.value,
      itemWidth: Grid.smallCardWidth / 2,
      coverAspectRatio: 0.75,
      items: (data) => data.videoArr,
      itemBuilder: (item) => _buildVideoCard(
        title: item.name,
        categoryId: item.categoryId,
        posterPath: item.posterPath,
        score: item.score,
        year: item.year,
        localCount: item.localCount,
        ugVideoInfoId: item.ugVideoInfoId,
        mediaLibSetId: item.mediaLibSetId,
        type: item.type,
      ),
    );
    return sections;
  }

  Widget _buildVideoCard({
    required String title,
    required String categoryId,
    required String posterPath,
    required num score,
    required int year,
    required int localCount,
    required int ugVideoInfoId,
    required int mediaLibSetId,
    required int type,
    String? initialFilePath,
    int? initialEpisode,
  }) {
    return UgreenCardV(
      title: title,
      cover: controller.coverUrl(
        categoryId: categoryId,
        posterPath: posterPath,
      ),
      score: score <= 0 ? null : '${score.toStringAsFixed(1)} 分',
      badge: year <= 0 ? null : year.toString(),
      subtitle: localCount <= 0 ? null : '共$localCount集',
      onTap: () => PageUtils.toUgreenPage(
        ugVideoInfoId: ugVideoInfoId,
        mediaLibSetId: mediaLibSetId,
        type: type,
        initialFilePath: initialFilePath,
        initialEpisode: initialEpisode,
      ),
    );
  }

  Widget _buildWideCard({
    required String title,
    required List<String> covers,
    required int itemCount,
  }) {
    return UgreenCardWide(
      title: title,
      covers: covers.map((e) => controller.coverUrl(posterPath: e)).toList(),
      subtitle: '共$itemCount项',
    );
  }
}
