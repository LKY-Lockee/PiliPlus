import 'package:PiliPlus/common/skeleton/fav_pgc_item.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/fav/fav_vod/list.dart';
import 'package:PiliPlus/pages/fav/vod/controller.dart';
import 'package:PiliPlus/pages/fav/vod/widget/item.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FavVodPage extends StatefulWidget {
  const FavVodPage({super.key});

  @override
  State<FavVodPage> createState() => _FavVodPageState();
}

class _FavVodPageState extends State<FavVodPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  final FavVodController _favVodController = Get.put(FavVodController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _favVodController.onRefresh,
      child: CustomScrollView(
        controller: _favVodController.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: 7,
              bottom: 100 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            sliver: Obx(
              () => _buildBody(_favVodController.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<FavVodItemModel>?> loadingState) {
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
                    _favVodController.onLoadMore();
                  }
                  final item = response[index];
                  return FavVodItem(
                    item: item,
                    onDelete: () => _favVodController.vodDel(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _favVodController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _favVodController.onReload,
      ),
    };
  }
}
