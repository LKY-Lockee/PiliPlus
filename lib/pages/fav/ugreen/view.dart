import 'package:PiliPlus/common/skeleton/fav_pgc_item.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_ugreen/list.dart';
import 'package:PiliPlus/pages/fav/ugreen/controller.dart';
import 'package:PiliPlus/pages/fav/ugreen/widget/item.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavUgreenPage extends StatefulWidget {
  const FavUgreenPage({super.key});

  @override
  State<FavUgreenPage> createState() => _FavUgreenPageState();
}

class _FavUgreenPageState extends State<FavUgreenPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  final FavUgreenController _favUgreenController = Get.put(
    FavUgreenController(),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _favUgreenController.onRefresh,
      child: CustomScrollView(
        controller: _favUgreenController.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 7,
              bottom: 100 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            sliver: Obx(
              () => _buildBody(_favUgreenController.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FavUgreenItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => const FavPgcItemSkeleton(),
        itemCount: 10,
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _favUgreenController.onLoadMore();
                  }
                  final item = response[index];
                  return FavUgreenItem(
                    item: item,
                    cover: _favUgreenController.coverUrl(
                      categoryId: item.videoInfo.categoryId,
                      posterPath: item.videoInfo.posterPath,
                    ),
                    onDelete: () => _favUgreenController.removeFavorite(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _favUgreenController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favUgreenController.onReload,
      ),
    };
  }
}
